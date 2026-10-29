function touch:worldSpace(entity, cam)
    cam = cam or entity.scene.camera:get(camera)
    local x, y, z = cam:screenToWorld(self.x, self.y)
    return vec3(x, y, z)
end

function touch:localSpace(entity, cam)
    cam = cam or entity.scene.camera:get(camera)
    local x, y, z = cam:screenToWorld(self.x, self.y)
    return entity:inverseTransformPoint(vec3(x, y, z))
end

function touch:hitTest(entity, cam)
    cam = cam or entity.scene.camera:get(camera)
    local body = entity:get(physics2d.body)
    if body then
        local x, y = cam:screenToWorld(self.x, self.y)
        local hit = body.world:query(x, y, 0, 0)
        return hit and hit.body == body or false
    end
    return false
end
