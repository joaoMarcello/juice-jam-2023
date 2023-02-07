local Pack = _G.Pack
local Utils = _G.JM_Utils
local Anima = _G.JM_Anima

---@class GameState.Splash: GameState
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT)
State.camera:toggle_debug()
State.camera:toggle_grid()
State.camera:toggle_world_bounds()
State.camera.border_color = { 0, 0, 0, 0 }
--===========================================================================
local shader_code = [[
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){vec4 pix = Texel(texture, texture_coords);if(pix.a < 1.0){return vec4(0.0, 0.0 ,0.0, 1.0);}return vec4(0.0, 0.0, 0.0, 0.0);}]]

local px1, px2
local speed = 32 * 10

---@type JM.Template.Affectable|nil
local affect

---@type JM.Effect.Rotate
local eff

local rad

local speed_rad = 20

local acc

local total_spin = (math.pi) + math.pi * 0.7

local radius, radius_max

local w, h, w_max, max_sx, max_sy

local delay

---@type love.Shader
local shader

local img = love.graphics.newImage('/data/mask_splash_02.png')
img:setFilter("linear", "linear")

---@type love.Image
local heart = love.graphics.newImage("/data/love-heart-logo.png")
img:setFilter("linear", 'linear')

local love_img = love.graphics.newImage("/data/love-logo.png")

---@type JM.Anima
local anima

---@type JM.Anima
local heart_anima

---@type JM.Anima
local love_anima

local pulse

local show_love

local function draw_rects()
    --  BLUE
    love.graphics.setColor(39 / 255, 170 / 255, 255 / 255)
    love.graphics.polygon("fill",
        px1 + 64, SCREEN_HEIGHT / 2,
        (px1 + 64 + SCREEN_WIDTH * 1.5), SCREEN_HEIGHT / 2,
        (px1 + SCREEN_WIDTH * 1.5), SCREEN_HEIGHT * 1.5,
        (px1), SCREEN_HEIGHT * 1.5
    )

    -- PINK
    love.graphics.setColor(231 / 255, 74 / 255, 153 / 255)
    love.graphics.polygon("fill",
        px2 + 64, -SCREEN_HEIGHT / 2,
        (px2 + 64 + SCREEN_WIDTH * 1.3), -SCREEN_HEIGHT / 2,
        (px2 + SCREEN_WIDTH * 1.3), SCREEN_HEIGHT * 0.5,
        (px2), SCREEN_HEIGHT * 0.5
    )
end

State:implements({
    init = function()
        delay = 0.5

        show_love = false

        affect = _G.JM_Affectable:new()
        affect.ox = SCREEN_WIDTH / 2 - 32
        affect.oy = SCREEN_HEIGHT / 2
        --eff = affect:apply_effect("clockWise", { speed = 20 })

        -- BLUE -- BOTTOM
        px1 = SCREEN_WIDTH + 64
        -- PINK -- UP
        px2 = -SCREEN_WIDTH * 1.3 - 64

        rad = 0
        speed = 32 * 15
        acc = (32 * 40)
        speed_rad = 0.8
        radius_max = SCREEN_WIDTH / 2 * 1.4
        radius = radius_max

        shader = love.graphics.newShader(shader_code)

        w = SCREEN_WIDTH * 30
        h = SCREEN_HEIGHT * 30
        anima = Anima:new { img = img }
        -- anima:set_scale(10, 10)
        anima:set_size(w, h)
        max_sx = anima.scale_x
        max_sy = anima.scale_y
        -- anima.ox = 288
        anima.oy = 144

        heart_anima = Anima:new { img = heart }
        local eff = heart_anima:apply_effect("pulse", { speed = 0.3, duration = 0.3 })
        eff:set_final_action(function()
            show_love = true
        end)


        love_anima = Anima:new { img = love_img }
        local ww, hh = love_img:getDimensions()
        love_anima:set_size(nil, 32 * 1.3)
        love_anima:apply_effect('fadein', { speed = 0.8 })

        pulse = false
    end,
    keypressed = function(key)
        if key == "space" then
            CHANGE_GAME_STATE(State, false, false, false, false, true, false)
        end
    end,
    finish = function()
        affect = nil
        shader:release()
    end,
    update = function(dt)
        delay = delay - dt
        if delay > 0 then return end

        speed = speed + acc * dt

        if px1 <= SCREEN_WIDTH * 0.4 then
            -- speed_rad = Utils:clamp(speed_rad - 7 * dt, 1, 100)
            rad = rad + (total_spin) / speed_rad * dt

            if rad < total_spin * 0.6 then
                affect.ox = SCREEN_WIDTH / 2
            end
        end


        rad = Utils:clamp(rad, -10, total_spin)

        if rad >= total_spin * 0.6 then
            radius = radius - radius_max / 0.6 * dt
            radius = Utils:clamp(radius, 64, math.huge)

            local sx, sy = anima.scale_x, anima.scale_y

            anima:set_scale(
                Utils:clamp(sx - max_sx / 0.3 * dt, 1, math.huge),
                Utils:clamp(sy - max_sy / 0.3 * dt, 1, math.huge)
            )

            if rad >= total_spin * 0.95 and affect then
                affect.ox = Utils:clamp(affect.ox - 32 * 9 * dt, SCREEN_WIDTH / 2 - 30, 30000)
            end

            if rad == total_spin then
                heart_anima:update(dt)
            end

            if show_love then
                love_anima:update(dt)
            end
        end

        px1 = Utils:clamp(px1 - speed * dt, -64 * 3, SCREEN_WIDTH * 1.3)
        px2 = Utils:clamp(px2 + speed * dt, -SCREEN_WIDTH * 1.3 - 64, -64)

        if affect then
            affect:set_effect_transform("rot", rad)
            affect:update(dt)
        end
    end,
    draw = function(camera)
        love.graphics.setColor(233 / 255, 245 / 255, 255 / 255)
        love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

        local r = affect and affect:draw(draw_rects)

        if rad >= total_spin * 0.6 then
            --love.graphics.setShader(shader)

            -- love.graphics.setColor(1, 0, 0)
            -- love.graphics.circle("fill", SCREEN_WIDTH / 2,
            --     SCREEN_HEIGHT * 0.4, radius)

            anima:draw(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
        end
        love.graphics.setShader()

        if rad == total_spin then
            heart_anima:draw(SCREEN_WIDTH / 2, SCREEN_HEIGHT * 0.38)
        end

        if show_love then
            love_anima:draw(SCREEN_WIDTH / 2, SCREEN_HEIGHT * 0.7)
        end
    end
})

return State
