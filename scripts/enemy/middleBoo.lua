local Enemy = require "scripts.enemy.enemy"

---@class Game.Enemy.MiddleBoo: Game.Enemy
local Boo = setmetatable({}, Enemy)
Boo.__index = Boo

function Boo:new(game, world, args)
    args = args or {}
    args.type = "dynamic"
    args.x = args.x or (32 * 10)
    args.y = args.y or (32 * 4)
    args.w = 28
    args.h = 48
    args.atk = 2
    args.def = 0
    args.bottom = args.bottom or (args.y + 32)
    args.y = args.bottom and (args.bottom - args.h) or args.y

    local obj = Enemy:new(game, world, args)
    setmetatable(obj, Boo)
    Boo.__constructor__(obj, args)
    return obj
end

function Boo:__constructor__(args)
    self.args = args
    self.x = args.x
    self.y = args.y
    self.w = args.w
    self.h = args.h
    self.ox = self.w / 2
    self.oy = self.h / 2

    self:apply_effect("jelly", { speed = 0.6 })

    self.acc = 32 * 6
    self.body.max_speed_x = 32 * 4
    self.body.dacc_x = self.world.meter * 8

    self.body:on_event("wall_right_touch", function()
        self.body.speed_x = -self.body.max_speed_x * 0.5
    end)

    self.body:on_event("wall_left_touch", function()
        self.body.speed_x = self.body.max_speed_x * 0.5
    end)

    self:on_event("damaged", function()
        self.body:jump(16, -1)
        self.body.speed_x = -self.body.speed_x
    end)
end

function Boo:load()

end

function Boo:finish()

end

function Boo:update(dt, camera)
    local is_active = Enemy.update(self, dt)
    if not is_active then return end

    local body = self.body
    local direction = self.game:get_player().x < body.x and -1 or 1
    body:apply_force(self.acc * direction)
end

function Boo:my_draw()
    love.graphics.setColor(250 / 255, 106 / 255, 10 / 255, 1)
    love.graphics.rectangle("fill", self.body:rect())
end

function Boo:draw()
    Enemy.draw(self, self.my_draw)
end

return Boo
