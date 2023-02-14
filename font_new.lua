local package = require("JM_love2d_package.init")
local Font = package.Font
local TextBox = package.GUI.TextBox
local Game = package.Scene:new(0, 0, 1366, 768, 32 * 24, 32 * 14,
    {
        left = -32 * 10,
        top = -32 * 10,
        right = 32 * 200,
        bottom = 32 * 200
    }
)
Game.camera:toggle_debug()
Game.camera:toggle_grid()

-- Font.current:set_format_mode(Font.current.format_options.italic)

local button = Font.current:add_nickname_animated("--a--", {
    img = "/data/xbox.png",
    frames_list = {
        { 407, 525, 831,  948 },
        { 407, 525, 831,  948 },
        { 401, 517, 1016, 1133 }
    },
    duration = 1
})

local text =
"Hello <freaky>aqui quem fala \teh o seu<italic>capitão</italic>.astha nao sei mais oque escrever paraastasatsagstasga este texto ficar longo então vou ficar enrolando <bold>World <italic><color, 0, 0, 1, 1>Iupi <bold> World</color>test <color>Wo"

local text2 =
"\t--trav-- inJ <italic>Não</italic> se vá ^ & <font-size=9>qçÇ</font-size> <effect=spooky>estou</effect> in<pause=0, no-space>-te<pause=0, no-space>-res<pause=0, no-space>-sa<pause=0, no-space>-do <pause=1><text-box, action=set_mode, value=normal><text-box, action=update_mode, value=1><text-box, action=max_time_glyph, value=0.05> Tam <font-size=16> Oi</font-size> Cara Oi<color, 1, 1, 1>Thanos</color no-space>. eu <pause= 2>nem<pause=1> gosto,<pause=0.3> ouviu?<pause=1> sas vefe \n sajs <effect=ghost, speed=0.5, min=0.2>asasahs</effect> wtwrfaghsas\n   asd asss df \n\tiIíÍìÌîÎïÏ \n\toOóÓòòôÔ öÖõÕ uU úÚùÙûüÜ <effect=flash, speed=1.2><color, 1, 1, 0>bBcCçÇdDfF</color></effect> gGhHjJk KlLm <effect=spooky>tTvVwW xXyYzZ</effect> 01234 56789¬ AsthaYuno * ¨¬¬ ~ $ ~ --heart-- --dots--<pause=1><effect=wave, speed=1>\nPress --a-- to <bold><color>charge your laser</color no-space> .  alfa</bold></effect><pause=2><effect=scream><text-box, action=update_mode, value=2><text-box, action=max_time_glyph, value=0.6> \n \nPARA DE GRITAAAA AAAR<sep>!!!!"

local text3 = [[
senhores do júri,
gostaria de informá-los que felizmente
estou bem.
Avise à mama.
assim
como
respirar
é fácil
]]

local rad = 0
Font.current:push()
Font.current:set_font_size(16)
local box = TextBox:new(text2, Font.current, 32 * 10, 32 * 5, 32 * 6)
Font.current:pop()

box:apply_effect("float", { range = 2, speed = 2 })

-- box:set_mode("popin")
local sound --= love.audio.newSource("/data/letter.wav", "static")
local pause

box:on_event("glyphChange", function()
    local g = box:get_current_glyph()
    if g then
        -- sound:play()
        -- g:apply_effect("float", { speed = 0.2 })
        -- g:set_color2(math.random(), math.random(), math.random())
    end
end)

box:on_event("wordChange", function()
    local g, w, endw = box:get_current_glyph()
    if w then
        --w:apply_effect(nil, nil, "fadein", nil, { speed = 1 })
        -- sound:play()
    end
end)

box:on_event("finishScreen", function()
    --pause:play()
end)

-- local A = Font.current:__get_char_equals("A"):copy()
-- A:apply_effect("clockWise")

local button = package.GUI.Button:new({ text = "Button 1", x = 32 * 17, y = 32, w = 32 * 2, h = 32 })
button:apply_effect("swing")
local function update(dt)
    Font:update(dt)

    -- A:update(dt)

    button:update(dt)

    box:update(dt)
    -- Game.camera:update(dt)
    local mx, my = Game:get_mouse_position()
    -- Game.camera:follow(mx, my)
    --rad = rad + math.pi * 2 / 0.7 * dt
end

-- local text3 = "aAàÀ <italic>çÇé fada <bold>dDeEfFgGhHiIjJkKlL</bold> mNoOpPqQrRsStT\n\t<freaky>uUvVwWxXyYzZ</freaky> <italic>0123456789</italic> +-=/*#§@ (){}[]\n|_'!?\n,.:;ªº°\n¹²³£¢\n <> ¨¬~$&\nEste é o mundo de Greg Uooôô ôô"
--     .. [["/]]

-- local text4 = "< effect=flickering, speed = 1 >oi eu sou o goku"
local temp
local function draw(camera)
    -- A:set_scale()
    -- A:draw(32 * 15, 32 * 2)
    -- button:draw()

    Font:printx(text2
        ,
        32 * 3,
        32 * 1
        , "left",
        32 * 3 + 32 * 6
    -- Game:get_mouse_position()
    )

    Font.current:push()
    Font.current:set_font_size(9)
    Font:printx("<effect=scream><font-size=16>PARA</effect> DE <font-size=6>GRITAAAR!</font-size>A"
        ,
        32 * 13,
        32 * 3
        , "left",
        32 * 13 + 32 * 3)
    Font.current:pop()

    box.x = Game.screen_w - box.w
    box:draw()

    Font:print("Ai --dots-- --heart-- --dots--", 500, 100)
    local mx, my = Game:get_mouse_position()
    love.graphics.setColor(0, 0, 1, 1)
    love.graphics.circle('fill', mx, my, 5)
end

Game:implements({
    load = function()
        sound = love.audio.newSource("data/letter.wav", "static")
        pause = love.audio.newSource("data/pause.wav", "static")
    end,
    --
    --
    update = update,
    --
    --
    keypressed = function(key)
        if key == "g" then
            Game.camera:toggle_grid()
            Game.camera:toggle_world_bounds()
        end

        if key == "d" then
            Game.camera:toggle_debug()
        end

        box:key_pressed(key)
    end,
    --
    --
    layers = {
        {
            draw = draw
        }
    }
    --draw = draw
})

return Game
