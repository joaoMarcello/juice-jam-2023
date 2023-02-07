local Pack = _G.Pack
local Font = Pack.Font

local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT)
State.camera:toggle_debug()
State.camera:toggle_grid()
State.camera:toggle_world_bounds()
--===========================================================================

local px1, px2
local speed = 32 * 3

---@type JM.Template.Affectable|nil
local affect

State:implements({
    init = function()
        affect = Pack.Affectable:new()
        px1 = SCREEN_WIDTH
        px2 = 0
    end,

    finish = function()
        affect = nil
    end,

    update = function(dt)
        px1 = px1 - speed * dt
        px2 = px2 + speed * dt
    end,

    draw = function(camera)
        
    end
})

return State
