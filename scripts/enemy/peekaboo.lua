local Enemy = require "scripts.enemy.enemy"
local Affectable = Pack.Affectable

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

    local obj = Enemy:new(game, world, args)
    setmetatable(obj, Boo)
    Boo.__constructor__(obj, args)
    return obj
end

function Boo:__constructor__(args)
    self:apply_effect("pulse", { speed = 0.6 })
    self.ox = self.w / 2
    self.oy = self.h / 2
end

function Boo:update(dt, camera)
    Enemy.update(self, dt, camera)
end

function Boo:my_draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.body:rect())
end

function Boo:draw()
    Enemy.draw(self, self.my_draw)
end

return Boo
