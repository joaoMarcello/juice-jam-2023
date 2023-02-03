local GC = require "scripts.bodyComponent"

---@type love.Image|nil
local img

local format = string.format

local color = {
    ["pink"] = { 212 / 255, 108 / 255, 129 / 255 }
}
local text = {
    ["mode_jump_ex"] = format([[<bold>Tip</bold no-space>:
    If you touch the  <effect=spooky><color, %.2f, %.2f, %.2f> flashing pink box</color no-space></effect>,
your mode will change to <bold>JUMP EX</bold no-space>.


In JUMP EX mode, you can
do <color>two jumps</color> in air!]], unpack(color['pink']))
}
---@class Game.Component.AdviceBox: BodyComponent
local Box = setmetatable({}, GC)
Box.__index = Box

Box.Texts = text

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
    self.text = args.text or text["mode_jump_ex"]

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

function Box:dispatch_advice()
    if self.game:game_is_not_advicing() then
        self.game:game_add_advice(self.text, function(dt)
            GC.update(self, dt)
        end)

        self:apply_effect("earthquake", {
            range_y = 5,
            speed = 0.2,
            duration_y = 0.4,
            rad_y = math.pi,
            range_x = 0,
            duration = 0.3
        })
    end
end

function Box:update(dt)
    GC.update(self, dt)
    self.box:update(dt)

    local player = self.game:get_player()
    local body = player.body
    local x, y, w, h = self.body:rect()

    if body:check_collision(x, y, w, h + 7)
        and not player:is_dead() and self.game:game_is_not_advicing()
        and body.speed_y <= 0 and player.state ~= player.States.dash
    then

        self:dispatch_advice()

        body.speed_y = 0.1
        body.speed_x = body.speed_x * 0.2
    end
end

local Font = Pack.Font.current
function Box:my_draw()

    self.box:draw(self.body.x + self.body.w / 2, self.body.y + self.body.h / 2)

    Font:push()
    Font:set_font_size(16)
    Font:printx(self.text_box, self.x, self.y + 8, self.x + self.w, "center")
    Font:pop()
end

function Box:draw()
    GC.draw(self, self.my_draw)
end

return Box
