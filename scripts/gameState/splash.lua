local Pack = _G.Pack
local Font = Pack.Font
local Utils = Pack.Utils

---@class GameState.Splash: GameState
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT)
State.camera:toggle_debug()
State.camera:toggle_grid()
State.camera:toggle_world_bounds()
--===========================================================================
local shader_code = [[   
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
    vec4 pix = Texel(texture, texture_coords);
    if(pix.a == 0.0){
        return vec4(0.0, 0.0, 0.0, 1.0);
    }
    return vec4(0.0, 0.0, 0.0, 0.0);
}
]]

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

local w, w_max

---@type love.Shader
local shader

local img = love.graphics.newImage('/data/mask_splash.png')
---@type JM.Anima
local anima
local function draw_rects()
    love.graphics.setColor(132 / 255, 155 / 255, 228 / 255)
    love.graphics.polygon("fill",
        px1 + 64, SCREEN_HEIGHT / 2,
        (px1 + 64 + SCREEN_WIDTH * 1.3), SCREEN_HEIGHT / 2,
        (px1 + SCREEN_WIDTH * 1.3), SCREEN_HEIGHT * 1.5,
        (px1), SCREEN_HEIGHT * 1.5
    )

    love.graphics.setColor(188 / 255, 74 / 255, 155 / 255)
    love.graphics.polygon("fill",
        px2 + 64, -SCREEN_HEIGHT / 2,
        (px2 + 64 + SCREEN_WIDTH * 1.3), -SCREEN_HEIGHT / 2,
        (px2 + SCREEN_WIDTH * 1.3), SCREEN_HEIGHT * 0.5,
        (px2), SCREEN_HEIGHT * 0.5
    )
end

State:implements({
    init = function()
        affect = Pack.Affectable:new()
        affect.ox = SCREEN_WIDTH / 2 - 28
        affect.oy = SCREEN_HEIGHT / 2
        --eff = affect:apply_effect("clockWise", { speed = 20 })
        px1 = SCREEN_WIDTH
        px2 = -SCREEN_WIDTH

        rad = 0
        speed = 32 * 15
        acc = (32 * 20)
        speed_rad = 1.2
        radius_max = SCREEN_WIDTH / 2 * 1.4
        radius = radius_max

        shader = love.graphics.newShader(shader_code)

        w = SCREEN_WIDTH * 1.5
        anima = Pack.Anima:new { img = img }
        anima:set_scale(10, 10)
        anima.ox = 288
        anima.py = 150
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
        speed = speed + acc * dt

        if px1 <= SCREEN_WIDTH / 2 then
            -- speed_rad = Utils:clamp(speed_rad - 7 * dt, 1, 100)
            rad = rad + (total_spin) / speed_rad * dt
        end


        rad = Utils:clamp(rad, -10, total_spin)

        if rad >= total_spin * 0.6 then
            radius = radius - radius_max / 0.6 * dt
            radius = Utils:clamp(radius, 64, math.huge)

            local sx, sy = anima.scale_x, anima.scale_y
            anima:set_scale(
                Utils:clamp(sx - 10 / 0.4 * dt, 1, math.huge),
                Utils:clamp(sy - 10 / 0.4 * dt, 1, math.huge)
            )
        end

        px1 = Utils:clamp(px1 - speed * dt, -64 * 3, SCREEN_WIDTH)
        px2 = Utils:clamp(px2 + speed * dt, -SCREEN_WIDTH, -64 * 2)

        if affect then
            affect:set_effect_transform("rot", rad)
            affect:update(dt)
        end

    end,

    draw = function(camera)

        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
        local r = affect and affect:draw(draw_rects)

        if rad >= total_spin * 0.6 then
            love.graphics.setShader(shader)

            love.graphics.setColor(1, 0, 0)
            love.graphics.circle("fill", SCREEN_WIDTH / 2,
                SCREEN_HEIGHT * 0.4, radius)

            -- anima:draw(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
        end
        love.graphics.setShader()
    end
})

return State
