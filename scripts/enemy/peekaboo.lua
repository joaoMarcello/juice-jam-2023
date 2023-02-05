local Enemy = require "scripts.enemy.enemy"

local img

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
    self:apply_effect("jelly", { speed = 0.6, range = 0.05 })

    self.x = args.x
    self.y = args.y
    self.w = args.w
    self.h = args.h
    self.ox = self.w / 2
    self.oy = self.h / 2
    self.args = args

    self.acc = 32 * 4
    self.body:on_event("wall_right_touch", function()
        self.acc = -self.acc
        self.body.speed_x = self.body.max_speed_x
    end)

    self.body:on_event("wall_left_touch", function()
        self.acc = -self.acc
        self.body.speed_x = -self.body.max_speed_x
    end)

    self:on_event("damaged", function()
        self.body:jump(16, -1)
        self.body.speed_x = 0
    end)

    self.body.max_speed_x = 32 * 2

    local Anima = Pack.Anima
    self.anima = {
        ["walk"] = Anima:new { img = img["walk"] }
    }

    self.cur_anima = self.anima["walk"]

    if self.game:get_player().body.x > self.x then self.acc = -self.acc end
end

function Boo:load()
    img = img or {
        ["walk"] = love.graphics.newImage('/data/animations/peekaboo-walk.png')
    }

    img["walk"]:setFilter("nearest", "nearest")
end

function Boo:finish()
    local r
    r = img["walk"] and img["walk"]:release()
    img = nil
end

function Boo:update(dt, camera)
    camera = self.game.camera
    local is_active = Enemy.update(self, dt, camera)

    if not is_active then return end

    if love.keyboard.isDown('t') then
        self:kill()
    end

    local body = self.body
    -- body.speed_x = -self.speed
    self.body:apply_force(-self.acc)

    self.cur_anima:set_flip_x(self.body.speed_x > 0)
    self.cur_anima:set_flip_y(self:is_dead())
end

function Boo:my_draw()
    -- love.graphics.setColor(1, 0, 0)
    -- love.graphics.rectangle("fill", self.body:rect())

    self.cur_anima:draw_rec(self.body:rect())
end

function Boo:draw()
    Enemy.draw(self, self.my_draw)
    -- _G.Pack.Font:print('' ..
    --     self.y .. '\n' .. self:get_state_string() .. '\n' .. (self.out_of_bounds and 'OUT' or 'in field'), 32 * 25,
    --     32 * 3)
end

return Boo
