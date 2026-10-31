local legacy = {}

-- Style functions
function legacy.pushStyle()
    style.push()
end

function legacy.popStyle()
    style.pop()
end

function legacy.resetStyle()
    style.reset()
end

function legacy.strokeWidth(...)
    return style.strokeWidth(...)
end

function legacy.stroke(...)
    return style.stroke(...)
end

function legacy.noStroke()
    style.strokeWidth(0)
end

function legacy.fill(...)
    return style.fill(...)
end

function legacy.blendMode(...)
    warn("blendMode is deprecated. Use style.blend instead")
    return style.blend(...)
end

function legacy.tint(...)
    return style.tint(...)
end

function legacy.noTint(...)
    return style.tint(255,255,255,255)
end

function legacy.spriteMode(...)
    return style.spriteMode(...)
end

function legacy.spriteSize(first, ...)
    warn("spriteSize is deprecated. Use image.read(...).width/.height instead")
    if first == nil then return 0, 0 end
    -- If already an Image (e.g. CAMERA global), use directly
    if type(first) == "userdata" then
        local ok, w = pcall(function() return first.width end)
        if ok and w then
            return first.width, first.height
        end
    end
    local img = image.read(first, ...)
    if img == nil then return 0, 0 end
    return img.width, img.height
end

function legacy.rectMode(...)
    return style.rectMode(...)
end

function legacy.ellipseMode(...)
    return style.ellipseMode(...)
end

function legacy.lineCapMode(...)
    warn("lineCapMode is deprecated. Use lineCap or style.lineCap instead")
    return style.lineCap(...)
end

function legacy.lineCap(...)
    return style.lineCap(...)
end

function legacy.lineJoin(...)
    return style.lineJoin(...)
end

function legacy.noSmooth(...)
    -- Legacy noSmooth() turned off both shape antialiasing and texture
    -- filtering. Replicate by also forcing point-filter on newly-loaded
    -- images. Wrap is left alone (Codea Legacy didn't expose wrap).
    style.filter(image.filter.point)
    return style.noSmooth(...)
end

function legacy.smooth(...)
    style.filter(image.filter.linear)
    return style.smooth(...)
end

function legacy.noFill(...)
    return style.noFill(...)
end

-- Matrix functions
function legacy.pushMatrix()
    matrix.push()
end

function legacy.popMatrix()
    matrix.pop()
end

function legacy.resetMatrix()
    matrix.reset()
end

function legacy.modelMatrix(...)
    warn("modelMatrix is deprecated. Use matrix.model instead")
    return matrix.model(...)
end

function legacy.translate(...)
    matrix.translate(...)
end

function legacy.rotate(...)
    matrix.rotate(...)
end

function legacy.scale(...)
    matrix.scale(...)
end

-- Text functions
function legacy.textMode(...)
    return style.textMode(...)
end

function legacy.fontSize(...)
    return style.fontSize(...)
end

legacy.font = font

function legacy.fontMetrics(...)
    return font.metrics(...)
end

function legacy.textWrapWidth(...)
    return style.textWrapWidth(...)
end

function legacy.textAlign(...)
    return style._legacyTextAlign(...)
end

-- image:set() → image:setPixel() migration
image.set = image.setPixel

-- mesh:setColors(color) → set all vertices to a single color
function mesh:setColors(c)
    local colors = {}
    for i = 1, (self.count or 0) do
        colors[i] = c
    end
    self.colors = colors
end

-- Asset functions
function legacy.readImage(...)
    warn("readImage is deprecated. Use image.read instead")
    return image.read(...)
end

function legacy.saveImage(...)
    warn("saveImage is deprecated. Use image.save instead")
    return image.save(...)
end

-- Audio not implemented
function legacy.soundBufferSize(...)
    warn("soundBufferSize is deprecated and not supported")
    return 0, 0
end

-- Mesh utilities (Carbide has mesh.triangulate, legacy uses a global)
legacy.triangulate = mesh.triangulate

-- Legacy Storage wrappers -> Carbide storage.lua
-- Drop this in your legacy migration layer (similar to legacy.readImage -> image.read).
--
-- Assumes:
--   - `storage` module is available (either global `storage` or require("storage"))
--   - storage.project / storage.global are stores
--   - store implements: get/set/keys/clear
--
-- Notes:
-- - Legacy save*Data(key, value) deleted when value == nil (matches Legacy behavior)
-- - list*Data() returns an array of keys (sorted if your storage.lua sorts keys)
-- - For "project info" we use a dedicated project store namespace to avoid collisions with project data.

-- ----------------------------
-- Local Storage (Legacy)
-- ----------------------------
local function legacy_local_store()
    return storage.global:namespace("__legacy.local." .. asset.name)
end

function legacy.readLocalData(key, defaultValue)
    local store = legacy_local_store()
    return store:get(tostring(key), defaultValue)
end

function legacy.saveLocalData(key, value)
    local store = legacy_local_store()
    return store:set(tostring(key), value)
end

function legacy.listLocalData()
    local store = legacy_local_store()
    return store:keys()
end

function legacy.clearLocalData()
    local store = legacy_local_store()
    return store:clear()
end

-- ----------------------------
-- Project Storage (Legacy)
-- ----------------------------
function legacy.readProjectData(key, defaultValue)
    return storage.project:get("__legacy.project." .. tostring(key), defaultValue)
end

function legacy.saveProjectData(key, value)
    return storage.project:set("__legacy.project." .. tostring(key), value)
end

function legacy.listProjectData()
    local prefix = "__legacy.project."
    local out = {}
    for _, k in ipairs(storage.project:keys()) do
        if k:sub(1, #prefix) == prefix then
            out[#out + 1] = k:sub(#prefix + 1)
        end
    end
    table.sort(out)
    return out
end

function legacy.clearProjectData()
    local prefix = "__legacy.project."
    local keys = storage.project:keys()
    for i = 1, #keys do
        local k = keys[i]
        if k:sub(1, #prefix) == prefix then
            storage.project:set(k, nil)
        end
    end
end

-- ----------------------------
-- Global Storage (Legacy)
-- ----------------------------
function legacy.readGlobalData(key, defaultValue)
    return storage.global:get("__legacy.global." .. tostring(key), defaultValue)
end

function legacy.saveGlobalData(key, value)
    return storage.global:set("__legacy.global." .. tostring(key), value)
end

function legacy.listGlobalData()
    local prefix = "__legacy.global."
    local out = {}
    for _, k in ipairs(storage.global:keys()) do
        if k:sub(1, #prefix) == prefix then
            out[#out + 1] = k:sub(#prefix + 1)
        end
    end
    table.sort(out)
    return out
end

-- Physics (legacy singleton)
local physics_impl = {}

legacy.CIRCLE = 0
legacy.EDGE = 1
legacy.POLYGON = 2
legacy.CHAIN = 3
legacy.REVOLUTE = 1
legacy.PRISMATIC = 2
legacy.DISTANCE = 3
legacy.WELD = 8
legacy.ROPE = 10
legacy.BEGAN = 0
legacy.CHANGED = 1
legacy.ENDED = 2
legacy.MOVING = legacy.CHANGED

physics_impl.pixelToMeterRatio = 32
physics_impl._bodyMap = setmetatable({}, {__mode = "v"})
physics_impl._nextBodyId = 1
physics_impl._contactIds = {}
physics_impl._nextContactId = 1
physics_impl._contactData = {}
physics_impl._suppressedColliders = {}

local function end_contacts_for_collider(collider_id)
    if collider_id == nil then
        return
    end
    local handler = rawget(_G, "collide")
    for key, _ in pairs(physics_impl._contactIds) do
        local a, b = key:match("([^:]+):([^:]+)")
        if a ~= nil and b ~= nil then
            if tonumber(a) == collider_id or tonumber(b) == collider_id then
                local contactId = physics_impl._contactIds[key]
                if type(handler) == "function" then
                    local cached = physics_impl._contactData[contactId]
                    if cached then
                        local legacy_contact = {
                            id = contactId,
                            state = legacy.ENDED,
                            touching = false,
                            position = cached.position,
                            normal = cached.normal,
                            pointCount = cached.pointCount or (#cached.points or 0),
                            points = cached.points or { cached.position },
                            bodyA = cached.bodyA,
                            bodyB = cached.bodyB,
                        }
                        handler(legacy_contact)
                    end
                end
                physics_impl._contactIds[key] = nil
                if contactId ~= nil then
                    physics_impl._contactData[contactId] = nil
                end
            end
        end
    end
end

local function is_contact_suppressed(collider_id_a, collider_id_b)
    if collider_id_a ~= nil and physics_impl._suppressedColliders[collider_id_a] then
        return true
    end
    if collider_id_b ~= nil and physics_impl._suppressedColliders[collider_id_b] then
        return true
    end
    return false
end

local function clear_contact_by_ids(collider_id_a, collider_id_b)
    if collider_id_a == nil or collider_id_b == nil then
        return
    end
    if collider_id_a > collider_id_b then
        collider_id_a, collider_id_b = collider_id_b, collider_id_a
    end
    local key = tostring(collider_id_a) .. ":" .. tostring(collider_id_b)
    local contactId = physics_impl._contactIds[key]
    physics_impl._contactIds[key] = nil
    if contactId ~= nil then
        physics_impl._contactData[contactId] = nil
    end
end

local function pixel_to_meter_ratio()
    local ratio = physics_impl.pixelToMeterRatio or 32
    if ratio == 0 then
        return 1
    end
    return ratio
end

local function meters_to_pixels(value)
    return value * pixel_to_meter_ratio()
end

local function pixels_to_meters(value)
    return value / pixel_to_meter_ratio()
end

local function to_vec2(value)
    if value == nil then
        return nil
    end
    if value.x ~= nil and value.y ~= nil then
        return vec2(value.x, value.y)
    end
    return nil
end

local function category_mask_from_list(list)
    local mask = 0
    if type(list) ~= "table" then
        return mask
    end
    for _, v in ipairs(list) do
        local idx = tonumber(v)
        if idx ~= nil and idx >= 1 and idx <= 16 then
            mask = mask | (1 << (idx - 1))
        end
    end
    return mask
end

local function category_list_from_mask(mask)
    local list = {}
    for i = 1, 16 do
        local bit = 1 << (i - 1)
        if (mask & bit) ~= 0 then
            list[#list + 1] = i
        end
    end
    return list
end

local function has_z(value)
    if value == nil then
        return false
    end
    if typeof ~= nil then
        return typeof(value) == "vec3"
    end
    local ok, z = pcall(function() return value.z end)
    return ok and z ~= nil
end

local legacy_joint_mt

local function wrap_joint(joint, kind)
    if joint == nil then
        return nil
    end
    local wrapper = {
        _joint = joint,
    }
    wrapper.destroy = function(self)
        if self._joint then
            self._joint:destroy()
        end
    end
    return setmetatable(wrapper, legacy_joint_mt)
end

local function legacy_body_set_position_meters(body, x_meters, y_meters)
    body._body.position = vec2(x_meters, y_meters)
end

local legacy_body_mt = {
    __index = function(self, key)
        if key == "x" then
            return meters_to_pixels(self._body.position.x)
        elseif key == "y" then
            return meters_to_pixels(self._body.position.y)
        elseif key == "position" then
            local pos = self._body.position
            return vec2(meters_to_pixels(pos.x), meters_to_pixels(pos.y))
        elseif key == "angle" then
            return self._body.rotation
        elseif key == "type" then
            return self._body.type
        elseif key == "shapeType" then
            return self._shapeType
        elseif key == "points" then
            return self._points
        elseif key == "radius" then
            if self._collider and self._collider.radius ~= nil then
                return meters_to_pixels(self._collider.radius)
            end
        elseif key == "friction" then
            if self._collider and self._collider.friction ~= nil then
                return self._collider.friction
            end
        elseif key == "restitution" then
            if self._collider and self._collider.restitution ~= nil then
                return self._collider.restitution
            end
        elseif key == "density" then
            if self._collider and self._collider.density ~= nil then
                return self._collider.density
            end
        elseif key == "linearVelocity" then
            local vel = self._body.linearVelocity
            return vec2(meters_to_pixels(vel.x), meters_to_pixels(vel.y))
        elseif key == "angularVelocity" then
            return self._body.angularVelocity
        elseif key == "linearDamping" then
            return self._body.linearDamping
        elseif key == "angularDamping" then
            return self._body.angularDamping
        elseif key == "gravityScale" then
            return self._body.gravityScale
        elseif key == "bullet" then
            return self._body.bullet
        elseif key == "sleepingAllowed" then
            return self._body.sleepingAllowed
        elseif key == "awake" then
            return self._body.awake
        elseif key == "fixedRotation" then
            return self._body.fixedRotation
        elseif key == "sensor" then
            if self._collider and self._collider.sensor ~= nil then
                return self._collider.sensor
            end
        elseif key == "categories" then
            if self._collider and self._collider.category ~= nil then
                return category_list_from_mask(self._collider.category)
            end
        elseif key == "mask" then
            if self._collider and self._collider.mask ~= nil then
                return category_list_from_mask(self._collider.mask)
            end
        elseif key == "active" then
            return self._body.enabled
        elseif key == "mass" then
            return self._body.mass
        elseif key == "inertia" then
            return self._body.inertia
        elseif key == "localCenter" then
            local center = self._body.localCenter
            return vec2(meters_to_pixels(center.x), meters_to_pixels(center.y))
        elseif key == "worldCenter" then
            local center = self._body.worldCenter
            return vec2(meters_to_pixels(center.x), meters_to_pixels(center.y))
        elseif key == "joints" then
            local joints = self._body.joints
            if type(joints) ~= "table" then
                return joints
            end
            local results = {}
            for i, joint in ipairs(joints) do
                results[i] = wrap_joint(joint)
            end
            return results
        elseif key == "interpolate" then
            return self._interpolate
        end
        return rawget(self, key)
    end,
    __newindex = function(self, key, value)
        if key == "x" then
            legacy_body_set_position_meters(self, pixels_to_meters(value), self._body.position.y)
        elseif key == "y" then
            legacy_body_set_position_meters(self, self._body.position.x, pixels_to_meters(value))
        elseif key == "position" then
            self._body.position = vec2(pixels_to_meters(value.x), pixels_to_meters(value.y))
        elseif key == "angle" then
            self._body.rotation = value
        elseif key == "type" then
            self._body.type = value
        elseif key == "radius" then
            if self._collider and self._collider.radius ~= nil then
                self._collider.radius = pixels_to_meters(value)
            else
                rawset(self, key, value)
            end
        elseif key == "friction" then
            if self._collider and self._collider.friction ~= nil then
                self._collider.friction = value
            else
                rawset(self, key, value)
            end
        elseif key == "restitution" then
            if self._collider and self._collider.restitution ~= nil then
                self._collider.restitution = value
            else
                rawset(self, key, value)
            end
        elseif key == "density" then
            if self._collider and self._collider.density ~= nil then
                self._collider.density = value
            else
                rawset(self, key, value)
            end
        elseif key == "linearVelocity" then
            self._body.linearVelocity = vec2(pixels_to_meters(value.x), pixels_to_meters(value.y))
        elseif key == "angularVelocity" then
            self._body.angularVelocity = value
        elseif key == "linearDamping" then
            self._body.linearDamping = value
        elseif key == "angularDamping" then
            self._body.angularDamping = value
        elseif key == "gravityScale" then
            self._body.gravityScale = value
        elseif key == "bullet" then
            self._body.bullet = value
        elseif key == "sleepingAllowed" then
            self._body.sleepingAllowed = value
        elseif key == "awake" then
            self._body.awake = value
        elseif key == "fixedRotation" then
            self._body.fixedRotation = value
        elseif key == "sensor" then
            if self._collider and self._collider.sensor ~= nil then
                self._collider.sensor = value
            else
                rawset(self, key, value)
            end
        elseif key == "categories" then
            if self._collider and self._collider.category ~= nil then
                self._collider.category = category_mask_from_list(value)
            else
                rawset(self, key, value)
            end
        elseif key == "mask" then
            if self._collider and self._collider.mask ~= nil then
                self._collider.mask = category_mask_from_list(value)
            else
                rawset(self, key, value)
            end
        elseif key == "active" then
            self._body.enabled = value
        elseif key == "mass" then
            self._body.mass = value
        elseif key == "inertia" then
            rawset(self, key, value)
        elseif key == "interpolate" then
            self._interpolate = value
        else
            rawset(self, key, value)
        end
    end
}

legacy_joint_mt = {
    __index = function(self, key)
        local joint = self._joint
        local kind = joint and joint.type or nil
        if key == "frequency" then
            return self._joint.frequency
        elseif key == "dampingRatio" then
            return self._joint.dampingRatio
        elseif key == "anchorA" then
            local a = joint.anchorA
            return vec2(meters_to_pixels(a.x), meters_to_pixels(a.y))
        elseif key == "anchorB" then
            local b = joint.anchorB
            return vec2(meters_to_pixels(b.x), meters_to_pixels(b.y))
        elseif key == "enableLimit" then
            return joint.useLimit
        elseif key == "enableMotor" then
            return joint.useMotor
        elseif key == "lowerLimit" then
            if kind == legacy.PRISMATIC then
                return meters_to_pixels(joint.lowerLimit)
            end
            return joint.lowerLimit
        elseif key == "upperLimit" then
            if kind == legacy.PRISMATIC then
                return meters_to_pixels(joint.upperLimit)
            end
            return joint.upperLimit
        elseif key == "motorSpeed" then
            if kind == legacy.REVOLUTE then
                return math.deg(joint.motorSpeed)
            elseif kind == legacy.PRISMATIC then
                return meters_to_pixels(joint.motorSpeed)
            end
            return joint.motorSpeed
        elseif key == "maxMotorTorque" then
            return joint.maxTorque
        elseif key == "maxMotorForce" then
            return joint.maxForce
        elseif key == "length" then
            return meters_to_pixels(joint.length)
        end
        if joint and joint[key] ~= nil then
            return joint[key]
        end
        return rawget(self, key)
    end,
    __newindex = function(self, key, value)
        local joint = self._joint
        local kind = joint and joint.type or nil
        if key == "frequency" then
            joint.frequency = value
        elseif key == "dampingRatio" then
            joint.dampingRatio = value
        elseif key == "anchorA" then
            joint.anchorA = vec2(pixels_to_meters(value.x), pixels_to_meters(value.y))
        elseif key == "anchorB" then
            joint.anchorB = vec2(pixels_to_meters(value.x), pixels_to_meters(value.y))
        elseif key == "enableLimit" then
            joint.useLimit = value
        elseif key == "enableMotor" then
            joint.useMotor = value
        elseif key == "lowerLimit" then
            if kind == legacy.PRISMATIC then
                joint.lowerLimit = pixels_to_meters(value)
            else
                joint.lowerLimit = value
            end
        elseif key == "upperLimit" then
            if kind == legacy.PRISMATIC then
                joint.upperLimit = pixels_to_meters(value)
            else
                joint.upperLimit = value
            end
        elseif key == "motorSpeed" then
            if kind == legacy.REVOLUTE then
                joint.motorSpeed = math.rad(value)
            elseif kind == legacy.PRISMATIC then
                joint.motorSpeed = pixels_to_meters(value)
            else
                joint.motorSpeed = value
            end
        elseif key == "maxMotorTorque" then
            joint.maxTorque = value
        elseif key == "maxMotorForce" then
            joint.maxForce = value
        elseif key == "length" then
            joint.length = pixels_to_meters(value)
        else
            if joint and joint[key] ~= nil then
                joint[key] = value
            else
                rawset(self, key, value)
            end
        end
    end
}

local function ensure_legacy_physics_world()
    if physics_impl._world_cache == nil then
        if physics2d == nil or physics2d._legacyWorld == nil then
            error("physics2d._legacyWorld is not available")
        end
        physics_impl._world_cache = physics2d._legacyWorld()
    end
    return physics_impl._world_cache
end

local physics = setmetatable({}, {
    __index = function(_, key)
        ensure_legacy_physics_world()
        if key == "continuous" then
            return physics_impl._world_cache.continuous
        end
        return physics_impl[key]
    end,
    __newindex = function(_, key, value)
        ensure_legacy_physics_world()
        if key == "continuous" then
            physics_impl._world_cache.continuous = value
        elseif key == "pixelToMeterRatio" then
            physics_impl.pixelToMeterRatio = value
        else
            physics_impl[key] = value
        end
    end,
})

function physics_impl._world()
    return ensure_legacy_physics_world()
end

function physics_impl.body(shapeType, ...)
    local world = ensure_legacy_physics_world()
    local body = world:body(DYNAMIC, 0, 0)
    local collider = nil
    local points = nil

    if shapeType == legacy.CIRCLE then
        local radius = ...
        collider = body:circle(pixels_to_meters(radius or 1), 0, 0)
    elseif shapeType == legacy.POLYGON then
        points = {...}
        local poly_points = {table.unpack(points)}
        for i = 1, math.floor(#poly_points / 2) do
            local j = #poly_points - i + 1
            poly_points[i], poly_points[j] = poly_points[j], poly_points[i]
        end
        for i = 1, #poly_points do
            local p = poly_points[i]
            poly_points[i] = vec2(pixels_to_meters(p.x), pixels_to_meters(p.y))
        end
        collider = body:polygon(poly_points)
    elseif shapeType == legacy.CHAIN or shapeType == legacy.EDGE then
        local args = {...}
        body.type = STATIC
        if shapeType == legacy.CHAIN then
            local loop = false
            if type(args[1]) == "boolean" then
                loop = args[1]
                table.remove(args, 1)
            end
            points = args
            local chain_points = {}
            for i = 1, #points do
                local p = points[i]
                chain_points[i] = vec2(pixels_to_meters(p.x), pixels_to_meters(p.y))
            end
            collider = body:chain(chain_points, loop)
        else
            local pointA = args[1]
            local pointB = args[2]
            if pointA == nil or pointB == nil then
                error("physics.body EDGE requires two points")
            end
            points = {pointA, pointB}
            local a = vec2(pixels_to_meters(pointA.x), pixels_to_meters(pointA.y))
            local b = vec2(pixels_to_meters(pointB.x), pixels_to_meters(pointB.y))
            collider = body:edge(a, b)
        end
    else
        error("physics.body unsupported shape type")
    end

    local wrapper = {
        _body = body,
        _collider = collider,
        _shapeType = shapeType,
        _points = points,
    }

    wrapper.testPoint = function(self, point)
        return self._body:testPoint(vec2(pixels_to_meters(point.x), pixels_to_meters(point.y)))
    end

    wrapper.getLocalPoint = function(self, point)
        local p = self._body:localPoint(vec2(pixels_to_meters(point.x), pixels_to_meters(point.y)))
        return vec2(meters_to_pixels(p.x), meters_to_pixels(p.y))
    end

    wrapper.getWorldPoint = function(self, point)
        local p = self._body:worldPoint(vec2(pixels_to_meters(point.x), pixels_to_meters(point.y)))
        return vec2(meters_to_pixels(p.x), meters_to_pixels(p.y))
    end

    wrapper.getLinearVelocityFromWorldPoint = function(self, point)
        local v = self._body:velocityAtWorldPoint(vec2(pixels_to_meters(point.x), pixels_to_meters(point.y)))
        return vec2(meters_to_pixels(v.x), meters_to_pixels(v.y))
    end

    wrapper.applyForce = function(self, force, worldPoint)
        local f = vec2(force.x, force.y)
        if worldPoint ~= nil then
            local p = vec2(pixels_to_meters(worldPoint.x), pixels_to_meters(worldPoint.y))
            self._body:applyForce(f, p)
        else
            self._body:applyForce(f)
        end
    end

    wrapper.applyTorque = function(self, torque)
        self._body:applyTorque(torque)
    end

    wrapper.applyLinearImpulse = function(self, impulse, worldPoint)
        local i = vec2(impulse.x, impulse.y)
        if worldPoint ~= nil then
            local p = vec2(pixels_to_meters(worldPoint.x), pixels_to_meters(worldPoint.y))
            self._body:applyLinearImpulse(i, p)
        else
            self._body:applyLinearImpulse(i)
        end
    end

    wrapper.applyAngularImpulse = function(self, impulse)
        self._body:applyAngularImpulse(impulse)
    end

    wrapper.testOverlap = function(self, other)
        if self._collider == nil then
            return false
        end
        local otherCollider = other and other._collider or other
        if otherCollider == nil then
            return false
        end
        return self._collider:overlap(otherCollider)
    end

    wrapper.destroy = function(self)
        if self._body then
            local legacyId = self._body._legacyId
            local colliderId = self._collider and self._collider._legacyId or nil
            self._body:destroy()
            if legacyId ~= nil then
                physics_impl._bodyMap[legacyId] = nil
            end
            if colliderId ~= nil then
                physics_impl._suppressedColliders[colliderId] = true
                end_contacts_for_collider(colliderId)
            end
        end
    end

    wrapper._id = physics_impl._nextBodyId
    physics_impl._nextBodyId = physics_impl._nextBodyId + 1
    if body._legacyId ~= nil then
        physics_impl._bodyMap[body._legacyId] = wrapper
    end

    local function handle_contact(state, contact)
        local handler = rawget(_G, "collide")
        if type(handler) ~= "function" then
            return
        end

        local function build_contact_points()
            local points = {}
            local raw_points = contact.points
            if type(raw_points) == "table" then
                for i, p in ipairs(raw_points) do
                    points[i] = vec2(meters_to_pixels(p.x), meters_to_pixels(p.y))
                end
            end
            if #points == 0 then
                local point = contact.worldPoint
                if point then
                    points[1] = vec2(meters_to_pixels(point.x), meters_to_pixels(point.y))
                end
            end
            return points, #points
        end

        local bodyA = contact.body and physics_impl._bodyMap[contact.body._legacyId] or nil
        local bodyB = contact.otherBody and physics_impl._bodyMap[contact.otherBody._legacyId] or nil
        if bodyA == nil then
            return
        end
        local colliderA = contact.collider
        local colliderB = contact.otherCollider
        local colliderIdA = colliderA and colliderA._legacyId or 0
        local colliderIdB = colliderB and colliderB._legacyId or 0
        if is_contact_suppressed(colliderIdA, colliderIdB) then
            clear_contact_by_ids(colliderIdA, colliderIdB)
            return
        end
        if colliderIdA ~= 0 and colliderIdB ~= 0 and colliderIdA > colliderIdB then
            return
        end

        local key = tostring(colliderIdA) .. ":" .. tostring(colliderIdB)
        local contactId = physics_impl._contactIds[key]
        if contactId == nil then
            contactId = physics_impl._nextContactId
            physics_impl._nextContactId = physics_impl._nextContactId + 1
            physics_impl._contactIds[key] = contactId
        end

        local point = contact.worldPoint
        local position = vec2(meters_to_pixels(point.x), meters_to_pixels(point.y))
        local points, pointCount = build_contact_points()
        if pointCount == 0 then
            points = { position }
            pointCount = 1
        end
        local legacy_contact = {
            id = contactId,
            state = state,
            touching = contact.touching,
            position = position,
            normal = contact.worldNormal,
            pointCount = pointCount,
            points = points,
            bodyA = bodyA,
            bodyB = bodyB or contact.otherBody,
        }
        physics_impl._contactData[contactId] = {
            position = legacy_contact.position,
            normal = legacy_contact.normal,
            pointCount = legacy_contact.pointCount,
            points = legacy_contact.points,
            bodyA = legacy_contact.bodyA,
            bodyB = legacy_contact.bodyB,
        }
        handler(legacy_contact)
    end

    body.onCollisionBegan = function(contact)
        handle_contact(legacy.BEGAN, contact)
    end

    body.onCollisionMoving = function(contact)
        handle_contact(legacy.MOVING, contact)
    end

    body.onCollisionEnded = function(contact)
        local handler = rawget(_G, "collide")
        if type(handler) ~= "function" then
            return
        end

        local bodyA = contact.body and physics_impl._bodyMap[contact.body._legacyId] or nil
        local bodyB = contact.otherBody and physics_impl._bodyMap[contact.otherBody._legacyId] or nil
        if bodyA == nil then
            return
        end
        local colliderA = contact.collider
        local colliderB = contact.otherCollider
        local colliderIdA = colliderA and colliderA._legacyId or 0
        local colliderIdB = colliderB and colliderB._legacyId or 0
        if is_contact_suppressed(colliderIdA, colliderIdB) then
            clear_contact_by_ids(colliderIdA, colliderIdB)
            return
        end
        if colliderIdA ~= 0 and colliderIdB ~= 0 and colliderIdA > colliderIdB then
            return
        end

        local key = tostring(colliderIdA) .. ":" .. tostring(colliderIdB)
        local contactId = physics_impl._contactIds[key]
        if contactId == nil then
            contactId = physics_impl._nextContactId
            physics_impl._nextContactId = physics_impl._nextContactId + 1
        end
        physics_impl._contactIds[key] = nil
        if contactId ~= nil then
            physics_impl._contactData[contactId] = nil
        end

        local point = contact.worldPoint
        local position = vec2(meters_to_pixels(point.x), meters_to_pixels(point.y))
        local points = {}
        local pointCount = 0
        local raw_points = contact.points
        if type(raw_points) == "table" then
            for i, p in ipairs(raw_points) do
                points[i] = vec2(meters_to_pixels(p.x), meters_to_pixels(p.y))
            end
        end
        if #points == 0 then
            points = { position }
            pointCount = 1
        else
            pointCount = #points
        end
        local legacy_contact = {
            id = contactId,
            state = legacy.ENDED,
            touching = contact.touching,
            position = position,
            normal = contact.worldNormal,
            pointCount = pointCount,
            points = points,
            bodyA = bodyA,
            bodyB = bodyB or contact.otherBody,
        }
        handler(legacy_contact)
    end

    return setmetatable(wrapper, legacy_body_mt)
end

function physics_impl.joint(type, bodyA, bodyB, anchorA, anchorB, maxLength)
    if type == legacy.WELD then
        if bodyA == nil or bodyB == nil or anchorA == nil then
            return nil
        end
        local anchor = vec2(pixels_to_meters(anchorA.x), pixels_to_meters(anchorA.y))
        local bodyA_native = bodyA._body or bodyA
        local bodyB_native = bodyB._body or bodyB
        local joint = bodyA_native:weld(bodyB_native, anchor)
        return wrap_joint(joint)
    elseif type == legacy.REVOLUTE then
        if bodyA == nil or bodyB == nil or anchorA == nil then
            return nil
        end
        local anchor = vec2(pixels_to_meters(anchorA.x), pixels_to_meters(anchorA.y))
        local bodyA_native = bodyA._body or bodyA
        local bodyB_native = bodyB._body or bodyB
        local joint = bodyA_native:hinge(bodyB_native, anchor)
        return wrap_joint(joint)
    elseif type == legacy.PRISMATIC then
        if bodyA == nil or bodyB == nil or anchorA == nil or anchorB == nil then
            return nil
        end
        local anchor = vec2(pixels_to_meters(anchorA.x), pixels_to_meters(anchorA.y))
        local axis = vec2(anchorB.x, anchorB.y)
        local bodyA_native = bodyA._body or bodyA
        local bodyB_native = bodyB._body or bodyB
        local joint = bodyA_native:slider(bodyB_native, anchor, axis)
        return wrap_joint(joint)
    elseif type == legacy.DISTANCE then
        if bodyA == nil or bodyB == nil or anchorA == nil or anchorB == nil then
            return nil
        end
        local anchorA_m = vec2(pixels_to_meters(anchorA.x), pixels_to_meters(anchorA.y))
        local anchorB_m = vec2(pixels_to_meters(anchorB.x), pixels_to_meters(anchorB.y))
        local bodyA_native = bodyA._body or bodyA
        local bodyB_native = bodyB._body or bodyB
        local joint = bodyA_native:distance(bodyB_native, anchorA_m, anchorB_m)
        return wrap_joint(joint)
    end

    error("physics.joint type not implemented yet")
end

function physics_impl.gravity(...)
    local world = ensure_legacy_physics_world()
    local arg_count = select("#", ...)

    if arg_count == 0 then
        local g = world.gravity
        return vec2(meters_to_pixels(g.x), meters_to_pixels(g.y))
    elseif arg_count == 1 then
        local v = ...
        if v == nil then
            return nil
        end
        if has_z(v) then
            world.gravity = vec2(v.x, v.y) * 9.8
        else
            local g = to_vec2(v)
            if g then
                world.gravity = vec2(pixels_to_meters(g.x), pixels_to_meters(g.y))
            end
        end
    else
        local x, y = ...
        world.gravity = vec2(pixels_to_meters(x), pixels_to_meters(y))
    end
end

local function raycast_mask_from_categories(categories)
    if categories == nil or #categories == 0 then
        return 0xFFFF
    end
    return category_mask_from_list(categories)
end

function physics_impl.raycast(startPoint, endPoint, ...)
    local world = ensure_legacy_physics_world()
    if startPoint == nil or endPoint == nil then
        return nil
    end
    local args = {...}
    local mask = raycast_mask_from_categories(args)
    local s = vec2(pixels_to_meters(startPoint.x), pixels_to_meters(startPoint.y))
    local e = vec2(pixels_to_meters(endPoint.x), pixels_to_meters(endPoint.y))
    local dir = e - s
    local distance = dir:len()
    if distance <= 0 then
        return nil
    end
    dir = dir / distance

    local hit = world:raycast(s, dir, distance, mask)
    if hit == nil then
        return nil
    end

    local bodyWrapper = nil
    if hit.collider and hit.collider.body and hit.collider.body._legacyId ~= nil then
        bodyWrapper = physics_impl._bodyMap[hit.collider.body._legacyId]
    end
    if bodyWrapper == nil then
        bodyWrapper = hit.collider and hit.collider.body or nil
    end

    return {
        body = bodyWrapper,
        point = vec2(meters_to_pixels(hit.point.x), meters_to_pixels(hit.point.y)),
        normal = hit.normal,
        fraction = hit.fraction,
    }
end

function physics_impl.raycastAll(startPoint, endPoint, ...)
    local world = ensure_legacy_physics_world()
    if startPoint == nil or endPoint == nil then
        return {}
    end
    local args = {...}
    local mask = raycast_mask_from_categories(args)
    local s = vec2(pixels_to_meters(startPoint.x), pixels_to_meters(startPoint.y))
    local e = vec2(pixels_to_meters(endPoint.x), pixels_to_meters(endPoint.y))
    local dir = e - s
    local distance = dir:len()
    if distance <= 0 then
        return {}
    end
    dir = dir / distance

    local hits = world:raycastAll(s, dir, distance, mask)
    local results = {}
    for _, hit in ipairs(hits or {}) do
        local bodyWrapper = nil
        if hit.collider and hit.collider.body and hit.collider.body._legacyId ~= nil then
            bodyWrapper = physics_impl._bodyMap[hit.collider.body._legacyId]
        end
        if bodyWrapper == nil then
            bodyWrapper = hit.collider and hit.collider.body or nil
        end
        results[#results + 1] = {
            body = bodyWrapper,
            point = vec2(meters_to_pixels(hit.point.x), meters_to_pixels(hit.point.y)),
            normal = hit.normal,
            fraction = hit.fraction,
        }
    end
    return results
end

function physics_impl.queryAABB(lowerLeft, upperRight, ...)
    local world = ensure_legacy_physics_world()
    if lowerLeft == nil or upperRight == nil then
        return {}
    end
    local args = {...}
    local mask = raycast_mask_from_categories(args)
    local minPoint = vec2(pixels_to_meters(lowerLeft.x), pixels_to_meters(lowerLeft.y))
    local maxPoint = vec2(pixels_to_meters(upperRight.x), pixels_to_meters(upperRight.y))
    local size = vec2(math.abs(maxPoint.x - minPoint.x), math.abs(maxPoint.y - minPoint.y))

    local results = {}
    local hits = world:queryBoxAll(minPoint, size, mask)
    for _, collider in ipairs(hits or {}) do
        local bodyWrapper = nil
        if collider and collider.body and collider.body._legacyId ~= nil then
            bodyWrapper = physics_impl._bodyMap[collider.body._legacyId]
        end
        if bodyWrapper == nil then
            bodyWrapper = collider and collider.body or nil
        end
        if bodyWrapper then
            results[#results + 1] = bodyWrapper
        end
    end
    return results
end

function physics_impl.pause()
    if physics2d and physics2d._legacyPause then
        physics2d._legacyPause(true)
    end
end

function physics_impl.resume()
    if physics2d and physics2d._legacyPause then
        physics2d._legacyPause(false)
    end
end

function physics_impl.iterations(velocityIterations, positionIterations)
    local world = ensure_legacy_physics_world()
    if velocityIterations == nil and positionIterations == nil then
        return
    end
    if velocityIterations ~= nil then
        world.velocityIterations = velocityIterations
    end
    if positionIterations ~= nil then
        world.positionIterations = positionIterations
    end
end

function physics_impl.timeStep(timeStep)
    if physics2d and physics2d._legacyTimeStep then
        if timeStep == nil then
            return physics2d._legacyTimeStep()
        end
        physics2d._legacyTimeStep(timeStep)
    end
end

legacy.physics = physics

local _cameraPlaceholder = nil
local function _ensureCameraPlaceholder()
    if not _cameraPlaceholder then
        _cameraPlaceholder = image(1, 1)
    end
    return _cameraPlaceholder
end

-- Camera source (getter/setter)
function legacy.cameraSource(source)
    if source == nil then
        return sensor.cameraSource
    end
    _ensureCameraPlaceholder()
    sensor.cameraSource = source
end

-- Called once after sandbox loads. Sets up legacy globals that alias Carbide APIs.
function legacy.init()
    CurrentTouch = touch.current
    DeltaTime = 0
    ElapsedTime = 0
    if not getmetatable(_G) then
        setmetatable(_G, {
            __index = function(t, k)
                if k == "CAMERA" or k == "CAMERA_DEPTH" then
                    local img = _ensureCameraPlaceholder()
                    rawset(t, k, img)
                    return img
                end
                return nil
            end
        })
    end
end

-- Called before each fixedUpdate() in the fixed timestep loop.
function legacy.fixedUpdate()
    DeltaTime = time.fixedDelta
    ElapsedTime = time.elapsed
end

-- Called each frame before draw(). Updates legacy globals that track live state.
function legacy.willDraw()
    CurrentTouch = touch.current
    DeltaTime = time.delta
    ElapsedTime = time.elapsed
    if _cameraPlaceholder or sensor.cameraColor then
        CAMERA = sensor.cameraColor or _ensureCameraPlaceholder()
        CAMERA_DEPTH = sensor.cameraDepth or _ensureCameraPlaceholder()
    end
end

-- Context functions
function legacy.setContext(...)
    local args = {...}
    if #args == 0 then
        context.pop()
    else
        context.push(...)
    end
end

local _noExport = {
    export = true, disable = true,
    init = true, willDraw = true, fixedUpdate = true,
}

function legacy:export()
    for k,v in pairs(legacy) do
        if not _noExport[k] then
            _G[k] = v
        end
    end

    return self
end

function legacy:disable()
    -- Remove all legacy globals
    for k,v in pairs(legacy) do
        if not _noExport[k] then
            _G[k] = nil
        end
    end

    return self
end

return legacy
