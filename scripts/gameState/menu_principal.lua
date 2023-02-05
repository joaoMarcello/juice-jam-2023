local Pack = _G.Pack
local Font = Pack.Font

local Button = require "scripts.menu_principal_button"

---@class GameState.MenuPrincipal: JM.Scene, GameState
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT)
State.camera:toggle_debug()
State.camera:toggle_grid()
State.camera:toggle_world_bounds()
--=========================================================================
local buttons
local current
--=========================================================================
State:implements {
    load = function()

    end,

    init = function()
        buttons = {
            Button:new(State, {}),
            Button:new(State, { is_quit = true, text = "QUIT", y = 285 }),
        }

        current = 1

        buttons[current]:set_focus(true)
    end,

    finish = function()

    end,

    keypressed = function(key)
        if key == "o" then
            State.camera:toggle_grid()
            State.camera:toggle_debug()
            State.camera:toggle_world_bounds()
        end

        if key == "up" or key == "down" then
            buttons[current]:set_focus(false)
            current = current == 1 and 2 or 1
            buttons[current]:set_focus(true)

        else
            buttons[current]:key_pressed(key)
        end
    end,

    update = function(dt, camera)
        buttons[current]:update(dt)
    end,

    ---@param camera JM.Camera.Camera
    draw = function(camera)
        local l, t, r, b = camera:get_viewport_in_world_coord()
        r, b = camera:world_to_screen(r, b)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, r, b)

        buttons[1]:draw()
        buttons[2]:draw()
    end
}

return State
