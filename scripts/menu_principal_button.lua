local Component = require "JM_love2d_package.modules.gui.component"
local GC = require "scripts.component"
local Font = Pack.Font

---@class GameState.MenuPrincipal.Button: JM.GUI.Component, GameComponent
local Button = Pack.Utils:create_class(Component, GC)
Button.__index = Button

---@return GameState.MenuPrincipal.Button
function Button:new(game, args)
    args   = args or {}
    args.x = 200
    args.y = 200
    args.w = 32 * 6
    args.h = (32 * 2) - 16

    local obj = Component:new(args)
    GC.__constructor__(obj, game, args)
    Button.__constructor__(obj, args)

    setmetatable(obj, self)
    return obj
end

function Button:__constructor__(args)
    self.text = args.text or "START"
    self.text = "<color, 1, 1, 1> <bold>" .. self.text

    self.print_obj = Font:get_phrase(self.text, self.x, self.y, "center", self.x + self.w)
    self.text_h = self.print_obj:text_height(self.print_obj:get_lines(self.x))

    self.ox = self.w / 2
    self.oy = self.h / 2

    ---@type JM.Effect|nil
    self.eff_pulse = nil

    self:on_event("gained_focus", function()
        if self.eff_pulse then self.eff_pulse.__remove = true end
        self.eff_pulse = self:apply_effect("pulse", { speed = 0.7, range = 0.04 })
    end)

    self:on_event("lose_focus", function()
        if self.eff_pulse then self.eff_pulse.__remove = true end
        self.eff_pulse = nil
    end)

    self.pressed = false

    self:on_event("key_pressed", function(key)
        if not self.pressed and (key == "space" or key == "return") then
            self.pressed = true

            self.eff_flash = self:apply_effect("flash", {
                speed = 0.3,
                -- color = { 0.2, 0.2, 0.2, 1 }
            })

            self.game:fadeout(1, nil, nil,
                function(dt)
                    self:update(dt)
                end,

                function()
                    Change_gamestate(require "scripts.gameState.game", nil, true)
                end)

            if self.eff_pulse then
                self.eff_pulse.__speed = self.eff_pulse.__speed / 2.0
            end

            -- self.game:pause(0.6, function(dt)
            --     self:update(dt)
            -- end)
        end
    end)

    self:set_focus(true)
end

function Button:update(dt)
    Component.update(self, dt)
    GC.update(self, dt)
end

function Button:__custom_draw__()
    love.graphics.setColor(1, 1, 0)
    -- love.graphics.push()
    -- love.graphics.shear(-0.1, 0)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    -- love.graphics.pop()

    self.print_obj:draw(self.x, self.y + self.h / 2 - self.text_h / 2, "center")

    Font:print(self.pressed, self.x, self.y)
end

return Button
