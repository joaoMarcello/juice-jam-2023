local Enemy = require "scripts.enemy.enemy"

local img

---@class Game.Enemy.WeightBoo: Game.Enemy
local Boo = setmetatable({}, Enemy)
Boo.__index = Boo

function Boo:new(game, world, args)
    args = args or {}
    args.type = "dynamic"
    args.x = args.x or (32 * 10)
    args.y = args.y or (32 * 4)
    args.w = 56
    args.h = 70
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

    -- self:apply_effect("jelly", { speed = 0.6 })

    self.jump_time_max = 3.0
    self.jump_time = self.jump_time_max

    self.acc = 32 * 6
    self.body.max_speed_x = 32 * 4
    self.body.dacc_x = self.world.meter * 8
    self.body.mass = self.body.mass * 1.4

    self.body:on_event("ground_touch", function()
        local camera = self.game.camera
        if camera:rect_is_on_view(self.body:rect()) then
            camera:shake_in_y(0.3, 2, nil, 0.1)
        end

        local player = self.game:get_player()
        local x, y, w, h = self.body:rect()

        if player.body:check_collision(x - 32 * 3, y + h - 20, w + 32 * 6, 30)
            and not player:is_dead()
            and self.invicible_time == 0
        then
            player:receive_damage(self.attr_atk, self)
        end
    end)
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

    local Anima = Pack.Anima
    self.anima = {
        ["idle"] = Anima:new { img = img['idle'], frames = 2 }
    }
    self.cur_anima = self.anima['idle']
    self.cur_anima:apply_effect("jelly", { speed = 0.6, range = 0.02 })
end

function Boo:load()
    img = img or {
        ["idle"] = love.graphics.newImage("/data/animations/weightboo-idle-sheet.png")
    }
    img['idle']:setFilter("linear", "nearest")
end

function Boo:finish()

end

function Boo:update(dt, camera)
    local is_active = Enemy.update(self, dt)
    if not is_active then return end

    local body = self.body
    camera = self.game.camera

    self.jump_time = self.jump_time - dt
    if self.jump_time <= 0 then
        self.jump_time = self.jump_time_max
        if body.speed_y == 0 then
            body:jump(32, -1)
        end
    end

    if not self:is_dead() then
        self.cur_anima:set_flip_x(self.game:get_player().body.x > self.x)
        self.cur_anima:update(dt)
    end
    -- self.cur_anima:set_flip_y(self:is_dead() and body.speed_y > 0)
end

function Boo:my_draw()
    -- love.graphics.setColor(64 / 255, 51 / 255, 83 / 255, 1)
    -- love.graphics.rectangle("fill", self.body:rect())

    self.cur_anima:draw_rec(self.body:rect())
end

function Boo:draw()
    Enemy.draw(self, self.my_draw)
end

return Boo
