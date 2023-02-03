local GC = require "scripts.bodyComponent"

---@type love.Image|nil
local img

---@class Game.Component.AdviceBox: BodyComponent
local Box = setmetatable({}, GC)
Box.__index = Box

function Box:new(game, world, args)
    args = args or {}
    args.type = "static"
    args.x = args.x or (32 * 15)
    args.y = args.y or (32 * 8)
    args.w = 32
    args.h = 32

    local obj = GC:new(game, world, args)
    setmetatable(obj, self)
    Box.__constructor__(obj, args)
    return obj
end

function Box:__constructor__(args)
    self.text = args.text or
        [[Aquele que habita
no esconderijo
do altíssimo
à sombra do onipotente
descansará]]

    self.body.allowed_gravity = false

    self.box = Pack.Anima:new({ img = img or '' })

    self:set_draw_order(0)
    self:set_update_order(2)

    self.text_box = "<color, 0.2, 0.2, 0.3, 0.7>!"

    -- self:apply_effect("earthquake",
    --     {
    --         range_y = 5,
    --         speed = 0.3,
    --         duration_y = 1,
    --         range_x = 0,
    --         duration = 1
    --     })
end

function Box:load()
    img = img or love.graphics.newImage('/data/aseprite/mode_changer.png')
    img:setFilter("linear", "linear")
end

function Box:finish()
    local r = img and img:release()
    img = nil
end

function Box:update(dt)
    GC.update(self, dt)
    self.box:update(dt)

    local player = self.game:get_player()
    local body = player.body
    local x, y, w, h = self.body:rect()

    if body:check_collision(x, y, w, h + 7)
        and not player:is_dead() and self.game:game_is_not_advicing()
        and body.speed_y <= 0
    then
        self.game:game_add_advice(self.text, function(dt)
            GC.update(self, dt)
        end)
        body.speed_y = 0.1
        self:apply_effect("earthquake", {
            range_y = 5,
            speed = 0.2,
            duration_y = 0.4,
            rad_y = math.pi,
            range_x = 0,
            duration = 1
        })

        -- self.game:pause(0.2, function(dt)
        --     GC.update(self, dt)
        -- end)
    end
end

local Font = Pack.Font.current
function Box:my_draw()

    self.box:draw(self.body.x + self.body.w / 2, self.body.y + self.body.h / 2)

    Font:push()
    Font:set_font_size(16)
    Font:printf(self.text_box, self.x, self.y + 8, "center", self.x + self.w)
    Font:pop()
end

function Box:draw()
    GC.draw(self, self.my_draw)
end

return Box
