local Enemy = require "scripts.enemy.enemy"

---@class Game.Enemy.PeekaBoo: Game.Enemy
local Boo = setmetatable({}, Enemy)
Boo.__index = Boo

function Boo:new(game, world, args)
    args = args or {}
    args.type = "dynamic"
    args.x = args.x or (32 * 10)
    args.y = args.y or (32 * 4)
    args.w = 28
    args.h = 32
    args.bottom = args.bottom or (args.y + 32)
    args.y = args.bottom and (args.bottom - args.h) or args.y

    local obj = Enemy:new(game, world, { type = "dynamic" })
    setmetatable(obj, Boo)

    return obj
end

function Boo:__constructor__()

end

function Boo:update(dt, camera)
    Enemy.update(self, dt, camera)
end

function Boo:draw()
    Pack.Font:print(self.body, self.x, self.y + self.h + 3)
end

return Boo
