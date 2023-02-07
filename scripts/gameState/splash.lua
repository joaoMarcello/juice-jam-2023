local Pack = _G.Pack
local Font = Pack.Font
local Utils = Pack.Utils

---@class GameState.Splash: GameState
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT)
State.camera:toggle_debug()
State.camera:toggle_grid()
State.camera:toggle_world_bounds()
--===========================================================================

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
        affect.ox = SCREEN_WIDTH / 2
        affect.oy = SCREEN_HEIGHT / 2
        --eff = affect:apply_effect("clockWise", { speed = 20 })
        px1 = SCREEN_WIDTH
        px2 = -SCREEN_WIDTH

        rad = 0
        speed = 32 * 10
        acc = (32 * 20)
        speed_rad = 1.7
    end,

    keypressed = function(key)
        if key == "space" then
            CHANGE_GAME_STATE(State, false, false, false, false, true, false)
        end
    end,

    finish = function()
        affect = nil
    end,

    update = function(dt)
        speed = speed + acc * dt

        if px1 <= SCREEN_WIDTH / 2 then
            -- speed_rad = Utils:clamp(speed_rad - 7 * dt, 1, 100)
            rad = rad + (total_spin) / speed_rad * dt
        end

        rad = Utils:clamp(rad, -10, total_spin)

        px1 = Utils:clamp(px1 - speed * dt, -64 * 2, SCREEN_WIDTH)
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


    end
})

return State
