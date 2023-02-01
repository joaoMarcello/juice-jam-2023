local Pack = _G.Pack
local Font = Pack.Font

local Button = require "scripts.menu_principal_button"

---@class GameState.MenuPrincipal: JM.Scene, GameState
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT)
State.camera:toggle_debug()
State.camera:toggle_grid()
State.camera:toggle_world_bounds()
--=========================================================================
local buttons = {
    Button:new(State, {})
}
--=========================================================================
State:implements {
    load = function()

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

        buttons[1]:key_pressed(key)
    end,

    update = function(dt, camera)
        buttons[1]:update(dt)
    end,

    ---@param camera JM.Camera.Camera
    draw = function(camera)
        local l, t, r, b = camera:get_viewport_in_world_coord()
        r, b = camera:world_to_screen(r, b)

        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.rectangle("fill", 0, 0, r, b)

        buttons[1]:draw()
    end
}

return State
