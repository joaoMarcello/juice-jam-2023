local Pack = _G.Pack
local Font = Pack.Font

local Button = require "scripts.menu_principal_button"

---@class GameState.Advice: JM.Scene, GameState
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT)
State.camera:toggle_debug()
State.camera:toggle_grid()
State.camera:toggle_world_bounds()
--=========================================================================


--=========================================================================
State:implements {
    load = function()
        -- State.camera.scale = State.camera.scale / 2
        -- State.camera.desired_scale = 1
        local camera = State.prev_state.camera

        -- State.camera.x = 32 * 3 --camera:x_world_to_screen(-State.prev_state.camera.x)

        -- State.camera.y = State.prev_state.camera.y

        State.prev_state.camera.desired_scale = 1
    end,

    init = function()

    end,

    finish = function()

    end,

    keypressed = function(key)
        if key == "o" then
            State.camera:toggle_grid()
            State.camera:toggle_debug()
            State.camera:toggle_world_bounds()
        end

        if key == "return" then
            UNPAUSE(State)
        end
    end,

    update = function(dt, camera)
        if State.prev_state then
            -- State.camera.x = State.prev_state.camera.x
            -- State.camera.y = State.prev_state.camera.y
        end
    end,

    layers = {
        {
            draw = function(self, camera)
                if State.prev_state then
                    love.graphics.push()
                    love.graphics.translate(
                        (State.prev_state.camera.x * 0 - State.offset_x), State.prev_state.camera.y)
                    State.prev_state:draw(camera)
                    love.graphics.pop()
                end

                love.graphics.setColor(0, 0, 0, 0.8)
                love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH,
                    SCREEN_HEIGHT)
            end
        }
    },

    ---@param camera JM.Camera.Camera
    draw = function(camera)
        -- local l, t, r, b = camera:get_viewport_in_world_coord()
        -- r, b = camera:world_to_screen(r, b)

        -- local Font = Font.current
        -- Font:push()
        -- Font:set_font_size(32)
        -- Font:printx("<color, 1, 1, 0>PAUSED", 0, 32 * 3, SCREEN_WIDTH, "center")
        -- Font:set_font_size(12)
        -- Font:printx("<color, 1, 1, 1>Press ESC if you want to quit", 0, 32 * 5, SCREEN_WIDTH, "center")
        -- Font:pop()
    end
}

return State
