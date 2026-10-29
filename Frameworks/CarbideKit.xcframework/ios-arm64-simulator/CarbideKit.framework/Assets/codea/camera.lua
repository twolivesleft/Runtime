-- Camera class extensions

local class = require('codea.middleclass')

camera.rigs = {}

local orbit = class("camera.rigs.orbit", component)
    
orbit:property { "distance", "number" }
orbit:property { "angles", vec2 }

orbit:property { "enabled", "boolean", default = true, set = function(self, value)  
    self._enabled = value
    if self.pan then
        self.pan.enabled = value
        self.pinch.enabled = value
    end
end }

function orbit:created()
    self.angles = vec2(0, 0)
    self.distance = 10
            
    self.pan = gesture.pan(function(gesture)
        self.angles.x = self.angles.x - gesture.delta.y
        self.angles.y = self.angles.y + gesture.delta.x
    end, 1, 1, true)
    self.pan.group = 1
        
    self.pinch = gesture.pinch(function(gesture)
        self.distance = self.distance / gesture.pinchDelta
    end)
    self.pinch.group = 1
end

function orbit:update(dt)
    self.entity.rotation = quat.eulerAngles(self.angles.x, self.angles.y, 0)
    self.entity.position = self.entity.forward * -self.distance
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
