local Phys = _G.Pack.Physics
local Affectable = Pack.Affectable

---@class GameComponent: JM.Template.Affectable
local Component = setmetatable({}, Affectable)
Component.__index = Component

---@param world JM.Physics.World
---@param args any
function Component:new(world, args)
    local obj = Affectable:new()
    setmetatable(obj, self)
    Component.__constructor__(obj, world, args)
    return obj
end

function Component:__constructor__(world, args)
    args.x = args.x or 0
    args.y = args.y or 0
    args.w = args.w or 32
    args.h = args.h or 32

    self.x = args.x
    self.y = args.y
    self.w = args.w
    self.h = args.h

    self.is_enable = true
    self.__remove = false

    self.body = Phys:newBody(world, args.x, args.y, args.w, args.h, args.type or "static")

    if self.body.type ~= 2 then
        self.max_speed = args.max_speed or (64 * 5)
        self.acc = args.acc or (64 * 4)
        self.dacc = args.dacc or (64 * 10)
    end
end

function Component:get_cx()
    return self.body.x + self.body.w * 0.5
end

function Component:get_cy()
    return self.body.y + self.body.h * 0.5
end

function Component:update(dt)
    Affectable.update(self, dt)
end

function Component:draw()
    return false
end

return Component
