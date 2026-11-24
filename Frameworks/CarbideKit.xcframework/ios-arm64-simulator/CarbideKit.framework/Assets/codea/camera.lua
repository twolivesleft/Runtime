-- Camera class extensions

local class = require('codea.middleclass')

camera.rigs = {}

-- Orbits the camera around a target point. One finger (or a trackpad
-- scroll) rotates, a pinch zooms, and moving a pinch pans the target.
-- Released swipes keep turning and slow down, and zooming past the distance
-- limits stretches, easing back on release. A host that handles gestures
-- itself sets `gestures` false and calls grab, rotate, moveTarget, zoom and
-- release instead.
local orbit = class("camera.rigs.orbit", component)

orbit:property { "target", vec3 }
orbit:property { "distance", "number" }
orbit:property { "angles", vec2 }
orbit:property { "minDistance", "number" }
orbit:property { "maxDistance", "number" }
orbit:property { "minPitch", "number" }
orbit:property { "maxPitch", "number" }
orbit:property { "sensitivity", "number", description = "Degrees turned per point dragged" }
orbit:property { "inertia", "boolean", default = true }

local function enableGestures(self)
    if self.pan then
        local on = self._enabled and self._gestures
        self.pan.enabled = on
        self.pinch.enabled = on
    end
end

orbit:property { "enabled", "boolean", default = true, set = function(self, value)
    self._enabled = value
    enableGestures(self)
end }

orbit:property { "gestures", "boolean", default = true, set = function(self, value)
    self._gestures = value
    enableGestures(self)
end }

-- Swipes slower than this (degrees per second) stop when released
local MIN_FLING_SPEED = 70
-- Momentum and stretched zoom decay at this rate per second
local DRAG = 5
-- How far a zoom stretches past its limits
local STRETCH = 10

function orbit:created()
    self.target = vec3(0, 0, 0)
    self.angles = vec2(0, 0)
    self.distance = 10
    self.minDistance = 0
    self.maxDistance = math.huge
    self.minPitch = -90
    self.maxPitch = 90
    self.sensitivity = 0.5
    self.velocity = vec2(0, 0)

    self.pan = gesture.pan(function(gesture)
        if gesture.state == BEGAN then
            self:grab()
        elseif gesture.state == CHANGED then
            self:rotate(gesture.delta)
            self._lastDelta = gesture.delta
        else
            local delta = self._lastDelta or vec2(0, 0)
            self._lastDelta = nil
            self:release(delta * (1 / math.max(time.delta, 1 / 120)))
        end
    end, 1, 1, true)
    self.pan.group = 1

    self.pinch = gesture.pinch(function(gesture)
        if gesture.state == BEGAN then
            self:grab()
            self._pinchLocation = gesture.location
        elseif gesture.state == CHANGED then
            self:moveTarget(self._pinchLocation, gesture.location)
            self._pinchLocation = gesture.location
            self:zoom(gesture.pinchDelta)
        else
            self:release()
        end
    end)
    self.pinch.group = 1

    enableGestures(self)
end

-- A gesture has started: momentum stops and the zoom can stretch.
function orbit:grab()
    self.grabbed = true
    self.velocity = vec2(0, 0)
    self._zoomDistance = self.distance
end

-- A gesture has ended. `velocity` (points per second) keeps the camera
-- turning when inertia is on.
function orbit:release(velocity)
    self.grabbed = false
    self._zoomDistance = nil
    if velocity and self.inertia then
        local v = vec2(-velocity.y, velocity.x) * self.sensitivity
        self.velocity = vec2(math.abs(v.x) < MIN_FLING_SPEED and 0 or v.x,
                             math.abs(v.y) < MIN_FLING_SPEED and 0 or v.y)
    end
end

-- Turns the camera by a drag of `delta` points.
function orbit:rotate(delta)
    self.angles = vec2(self.angles.x - delta.y * self.sensitivity,
                       self.angles.y + delta.x * self.sensitivity)
    self:apply()
end

-- How far past a limit the stretched zoom goes, for an overshoot of `x`.
local function stretch(x)
    return STRETCH * math.log(x + STRETCH) - STRETCH * math.log(STRETCH)
end

-- Zooms in by `scale` (a pinch's change in size). Past the distance limits
-- the zoom stretches while grabbed.
function orbit:zoom(scale)
    local raw = (self._zoomDistance or self.distance) / scale
    if self.grabbed then
        self._zoomDistance = raw
        if raw > self.maxDistance then
            raw = self.maxDistance + stretch(raw - self.maxDistance)
        elseif raw < self.minDistance then
            raw = self.minDistance - stretch(self.minDistance - raw)
        end
    else
        raw = math.max(self.minDistance, math.min(self.maxDistance, raw))
    end
    self.distance = math.max(raw, 0.001)
    self:apply()
end

-- Where the screen point `p` meets the plane through the target facing
-- the camera.
function orbit:pointOnTargetPlane(p)
    local cam = self.entity:get(camera)
    if not cam then return self.target end
    local origin, dir = cam:screenToRay(p.x, p.y)
    local normal = -self.entity.forward
    local denom = normal:dot(dir)
    if math.abs(denom) < 1e-6 then return self.target end
    return origin + dir * ((self.target - origin):dot(normal) / denom)
end

-- Pans the target so the point under screen point `from` moves to `to`.
function orbit:moveTarget(from, to)
    self.target = self.target + self:pointOnTargetPlane(from) - self:pointOnTargetPlane(to)
    self:apply()
end

-- Places the camera from the target, angles and distance.
function orbit:apply()
    local pitch = math.max(self.minPitch, math.min(self.maxPitch, self.angles.x))
    if pitch ~= self.angles.x then self.angles = vec2(pitch, self.angles.y) end
    self.entity.rotation = quat.eulerAngles(pitch, self.angles.y, 0)
    self.entity.position = self.target - self.entity.forward * self.distance
end

function orbit:update(dt)
    if not self.grabbed then
        if self.velocity.x ~= 0 or self.velocity.y ~= 0 then
            self.angles = self.angles + self.velocity * dt
            self.velocity = self.velocity * math.max(0, 1 - DRAG * dt)
            if self.velocity.length < 1 then self.velocity = vec2(0, 0) end
        end

        -- Ease a stretched zoom back inside the limits
        local limit = math.max(self.minDistance, math.min(self.maxDistance, self.distance))
        if limit ~= self.distance then
            local overshoot = (self.distance - limit) * math.max(0, 1 - DRAG * dt)
            self.distance = math.abs(overshoot) < 1e-4 and limit or limit + overshoot
        end
    end
    self:apply()
end

function orbit:destroyed()
    self.pan.enabled = false
    self.pinch.enabled = false
end

camera.rigs.orbit = orbit

local canvas = class("camera.rigs.canvas", component)
    
canvas:property { "zoom", "number" }
    
canvas:property { "enabled", "boolean", default = true, set = function(self, value)  
    self._enabled = value
    if self.pan then
        self.pan.enabled = value
        self.pinch.enabled = value
    end
end }

function canvas:created(zoom)
    self.camera = self.entity:get(camera)
    assert(self.camera, "canvas rig only works with camera components")
    
    self.zoom = zoom or self.camera.orthoSize

    local entity = self.entity
    local camera = self.camera

    self.pan = gesture.pan(function(gesture)
        local x1, y1 = camera:screenToWorld(gesture.location:unpack())
        local x2, y2 = camera:screenToWorld((gesture.location + gesture.delta):unpack())
        entity.x = entity.x + (x1 - x2)
        entity.y = entity.y + (y1 - y2)
    end, 2, 2, true)
    self.pan.group = 1
        
    self.pinch = gesture.pinch(function(gesture)
        self.zoom = self.zoom / gesture.pinchDelta
    end)
    self.pinch.group = 1
end

function canvas:update(dt)    
    self.camera.orthoSize = self.zoom
end

function canvas:destroyed()
    self.pan.enabled = false
    self.pinch.enabled = false
end

camera.rigs.canvas = canvas
