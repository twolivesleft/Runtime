-- Entity class extensions

function entity:placementWobble(duration, spinCount, tiltAngle, height)
    local scn = self.scene
    local y = self.y
    self.y = y + height
    scn:tween(self):to{y = y}:time(duration * 0.75):ease(tween.bounceOut):unscaled()
    
    local up = vec3(0,1,0)
    local right = vec3(1,0,0)
    scn:tween{t = 0}:to{t = 1}:time(duration):ease(tween.circularIn):unscaled():onStep(function(tween, t)
        local t2 = 1.0 - t
        local dir = quat.angleAxis(tiltAngle * t2, right) * up
        local dir2 = quat.angleAxis(t * spinCount * 360.0, up) * dir
        self.rotation = quat.fromToRotation(vec3(0,1,0), dir2.normalized)
    end)
end

-- function entity:dispatch(name, ...)
--     local func = self[name]
--     if func and type(func) == 'function' then
--         func(self, ...)
--     end
-- end

function entity:tintColorFlash(target, time1, time2)
    local scn = self.scene
    local mat = self.material
    time2 = time2 or time1

    if mat then
        if mat.tintColor then
            return scn:tween(mat)
                :to{tintColor = target}
                :time(time1)
                :ease(tween.cubicIn)
                :to{tintColor = sh.tintColor}
                :time(time2)
                :ease(tween.cubicOut)
        end
    end
    warn("No material found with property 'tintColor'")
    return nil
end

function entity:colorTo(target, time)
    local scn = self.scene
    local mat = self.material
    if mat then
        if mat.color then
            return scn:tween(mat):to{color = target}:time(time)
        end
    end
    warn("No material found with property 'mat'")
    return nil
end
