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
            State.camera.x = State.prev_state.camera.x
        end
    end,

    layers = {
        {
            draw = function(self, camera)
                if State.prev_state then
                    State.prev_state:draw(camera)
                end
            end
        }
    },

    ---@param camera JM.Camera.Camera
    draw = function(camera)
        local l, t, r, b = camera:get_viewport_in_world_coord()
        r, b = camera:world_to_screen(r, b)

        -- love.graphics.setColor(1, 1, 1, 0.6)
        -- love.graphics.rectangle("fill", 0, 0, r, b)

    end
}

return State