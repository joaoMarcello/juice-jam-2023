local GC = require "scripts.bodyComponent"

---@type love.Image|nil
local img

local format = string.format

local color = {
    ["pink"] = { 212 / 255, 108 / 255, 129 / 255 },
    ["orange"] = { 250 / 255, 136 / 255, 15 / 255 },
    ["blue"] = { 130 / 255, 108 / 255, 212 / 255 },
    ["green"] = { 20 / 255, 160 / 255, 46 / 255 },
}
local text = {
    ["mode_jump_ex"] = format("If you touch the  <effect=spooky><color, %.2f, %.2f, %.2f> flashing pink box</color no-space></effect>, your mode will change to JUMP EX.\n \n  \n \n In JUMP EX mode, you can \n do <color>three jumps</color> in total!"
        , unpack(color['pink'])),
    --
    --
    ["commands"] = format("Move <effect=scream><color, %.3f, %.3f, %.3f>Dimitri</color></effect> using\n the ARROW keys.\n \n \n \n You can <bold>jump</bold> using\n SPACE or UP."
        , unpack(color["orange"])),
    --
    --
    ["mode_jump"] = format(
        "Touch the <color, %.3f, %.3f, %.3f>pink box</color> and change\n to JUMP MODE.\n \n \n \n In JUMP MODE, you can do\n an <color>extra jump</effect></color no-space>!"
        ,
        unpack(color["pink"])
    ),
    --
    --
    ["checkpoint"] = format("Stand in the flashing pod to save state. Depending on the <color> color of the light</color no-space>, your pills will also be restored!"),
    --
    --
    ["mode_normal"] = format("If you touch the <effect=spooky>black box</effect no-space>, you will return to NORMAL state and \n will no longer be able to use\n extra jumps or dash."),
    ['dash_mode'] = format("Touch the <color, %.3f, %.3f, %.3f>blue box</color> and change\n to DASH MODE.\n \n \n \n In DASH MODE, you can do\n an <color>dash </effect></color> by pressing the F key! \n \n Use dash to <bold>fly long distances</bold> or \n even <bold>hit enemies</bold no-space>. \n \n "
        ,
        unpack(color["blue"])),
    ["dash_ex_mode"] = format("Touch the <color, %.3f, %.3f, %.3f> <effect=spooky> flashing blue box</color></effect> and change\n to DASH EX MODE.\n \n \n \n In DASH EX MODE, you can \n do an <color>extra dash</color no-space>. \n It's perfect to fly even further. \n Also, if you touch a <color, %.2f, %.2f, %.2f>blue diamond</color no-space>, you dash will be restored."
        , color["blue"][1], color["blue"][2], color["blue"][3], unpack(color["blue"])),
    ["ground_pound"] = format("Execute a <color>ground pound </color> by pressing the DOWN key while in the air. \n \n \n Cancel the ground pound using an dash."),
    ["pills"] = format("Press the A, S, D or V keys to\n use a pill. Each pill <color, %.2f, %.2f, %.2f>increase</color> one atribute, but <color>decreases</color> another. \n \n \n If you not use it carefully, you can ending <effect=spooky>paying the price</effect no-space>. \n \n <color>Red</color> pills: increase ATK.\n <color, 0, 0, 1>Blue</color> pills: increase DEF.\n <color, 0, 1, 0>Green</color> pills: increase HP. \n <color, 1, 1, 0>Yellow</color> pills: increase time. \n The yellow pills DON'T decreases you HP, so use it if you need some time."
        ,
        color["green"][1], color["green"][2], color["green"][3]),
    ["dash_push"] = "Use dash against a wall to push enemies. \n \n \n",
    ["extreme"] = format("Touch the <color, %.3f, %.3f, %.3f> <effect=spooky> orange box</color></effect> and change\n to EXTREME MODE.\n \n \n \n In EXTREME MODE, your HP will drop to 1 and your ATK will be maximized. \n \n If your HP already is 1, then you die; so use a <color, 0, 1, 0>green</color> pill before touch it. \n \n \n  <color>Watch out</color no-space>: you will no longer be able to use pills, except the yellow ones. \n \n \n \n Finally, now you will be able to \n perform a double dash AND three jumps in total!!!"
        , unpack(color["orange"])),
    ["final"] = format("You won! \n Thanks for playing! \n \n \n Go forward to go back to title screen.")
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
    self.text = (args.text and text[args.text]) or text["mode_jump_ex"]

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
