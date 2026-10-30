local grabber3d = class('grabber')

function grabber3d:created(spring, damper)
    self.spring = spring or 100
    self.damper = damper or 10
    self.world = self.scene.world3d
    self.cam = self.entity:get(camera)
    self.rig = self.entity:get(camera.rigs.orbit)
end

function grabber3d:touched(touch)
    local origin, dir = self.cam:screenToRay(touch.x, touch.y)
    
    if touch.began then
        local hit = self.world:raycast(origin, dir, 100)
        if hit and hit.body.type == DYNAMIC then
            self.body = hit.body
            self.anchor = self.body:localPoint(hit.point)
            self.dist = hit.fraction * 100
            if self.rig then
                self.rig.pan.enabled = false
                self.rig.pinch.enabled = false
            end
            return true
        end
    elseif touch.moving then
        self.target = origin + dir * self.dist
    elseif touch.ended or touch.cancelled then
        self.anchor = nil
        self.target = nil
        self.body = nil
        if self.rig then
            self.rig.pan.enabled = true
            self.rig.pinch.enabled = true
        end
    end
end

function grabber3d:draw()
    if self.anchor and self.target then
        matrix.push().reset()
        style.push().noFill().stroke(255).strokeWidth(5)
        local wp = self.body:worldPoint(self.anchor)
        gizmos.line(wp, self.target)
        style.pop()
        matrix.pop()
    end
end

function grabber3d:fixedUpdate(dt)
    if self.anchor and self.target then
        local wp = self.body:worldPoint(self.anchor)
        local v = self.target - wp
        --
        self.body:applyForce(v * self.spring - self.body:velocityAtWorldPoint(wp) * self.damper, wp)
    end
end

local grabber2d = class('grabber')

function grabber2d:created(spring, damper)
    self.spring = spring or 100
    self.damper = damper or 10
    self.world = self.scene.world2d
    self.cam = self.entity:get(camera)
    self.rig = self.entity:get(camera.rigs.canvas)
end

function grabber2d:touched(touch)
    local x, y = self.cam:screenToWorld(touch.x, touch.y, 0)
    
    if touch.began then
        local hit = self.world:queryBox(x, y, 0, 0)
        if hit and hit.body.type == DYNAMIC then
            self.body = hit.body
            self.anchor = self.body:localPoint(vec2(x, y))

            if self.rig then
                self.rig.pan.enabled = false
                self.rig.pinch.enabled = false
            end
            return true
        end
    elseif touch.moving then
        self.target = vec2(x, y)
    elseif touch.ended or touch.cancelled then
        self.anchor = nil
        self.target = nil
        self.body = nil
        if self.rig then
            self.rig.pan.enabled = true
            self.rig.pinch.enabled = true
        end
    end
end

function grabber2d:draw()
    if self.anchor and self.target then
        matrix.push().reset()
        style.push().noFill().stroke(255).strokeWidth(5)
        local wp = self.body:worldPoint(self.anchor)
        line(wp, self.target)
        style.pop()
        matrix.pop()
    end
end

function grabber2d:fixedUpdate(dt)
    if self.anchor and self.target then
        local wp = self.body:worldPoint(self.anchor)
        local v = self.target - wp
        --
        self.body:applyForce(v * self.spring - self.body:velocityAtWorldPoint(wp) * self.damper, wp)
    end
end


physics2d.grabber = grabber2d
physics3d.grabber = grabber3d
