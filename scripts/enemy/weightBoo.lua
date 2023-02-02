local Enemy = require "scripts.enemy.enemy"

---@class Game.Enemy.WeightBoo: Game.Enemy
local Boo = setmetatable({}, Enemy)
Boo.__index = Boo

function Boo:new(game, world, args)
    args = args or {}
    args.type = "dynamic"
    args.x = args.x or (32 * 10)
    args.y = args.y or (32 * 4)
    args.w = 56
    args.h = 58
    args.atk = 2
    args.def = 1
    args.hp = 2
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
    self.body.mass = self.body.mass * 1.4

    self:on_event("damaged", function()
        self.body:jump(16, -1)
        local direction = self.game:get_player().body.x < self.body.x and 1 or -1
        self.body.speed_x = (32 * 4) * direction
    end)

    self:on_event("pushPlayer", function()
        if self.body.speed_y <= 0 then
            self.body:jump(16, -1)
        end
    end)

    self:on_event("killed", function()
        self.body.mass = self.world.default_mass
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
    -- local direction = self.game:get_player().x < body.x and -1 or 1
    -- body:apply_force(self.acc * direction)
end

function Boo:my_draw()
    love.graphics.setColor(64 / 255, 51 / 255, 83 / 255, 1)
    love.graphics.rectangle("fill", self.body:rect())
end

function Boo:draw()
    Enemy.draw(self, self.my_draw)
end

return Boo
