local Affectable = Pack.Affectable
local Utils = Pack.Utils

---@class Game.GUI.DisplayPill: JM.Template.Affectable
local Display = setmetatable({}, Affectable)
Display.__index = Display

---@return Game.GUI.DisplayPill
function Display:new(game, args)
    local obj = Affectable:new()
    setmetatable(obj, self)
    Display.__constructor__(obj, game, args)
    return obj
end

---@param game GameState.Game
function Display:__constructor__(game, args)
    local l, t, r, b = game.camera:get_viewport_in_world_coord()

    self.game = game
    self.x = args.x or (32)
    self.w = (28 + 4) * 4
    self.space = (self.w - (28 * 4)) / 5
    self.h = 28 + self.space * 2
    self.y = args.y or (b - self.h)
    self.space_y = (self.h - 28) / 2

    self.attr = {
        "attr_pill_atk",
        "attr_pill_def",
        "attr_pill_hp",
        "attr_pill_time"
    }
    local player = game:get_player()

    self.keyboard = {
        player.key_pill_atk[1]:upper(),
        player.key_pill_def[1]:upper(),
        player.key_pill_hp[1]:upper(),
        player.key_pill_time[1]:upper()
    }

    self.icons = {
        {
            draw = function(self, x, y, w, h)
                love.graphics.setColor(0.7, 0.2, 0.2, 1)
                love.graphics.rectangle("fill", x, y, w, h)
            end
        },

        {
            draw = function(self, x, y, w, h)
                love.graphics.setColor(0.2, 0.2, 0.7, 1)
                love.graphics.rectangle("fill", x, y, w, h)
            end
        },

        {
            draw = function(self, x, y, w, h)
                love.graphics.setColor(0.2, 0.7, 0.2, 1)
                love.graphics.rectangle("fill", x, y, w, h)
            end
        },

        {
            draw = function(self, x, y, w, h)
                love.graphics.setColor(0.8, 0.8, 0.2, 1)
                love.graphics.rectangle("fill", x, y, w, h)
            end
        }
    }
end

function Display:load()

end

function Display:init()

end

function Display:finish()

end

function Display:rect()
    return self.x, self.y, self.w, self.h
end

function Display:shake()
    self:apply_effect("earthquake", { random = true, range_x = 3, range_y = 3, duration = 0.25 })
end

function Display:update(dt)
    Affectable.update(self, dt)
end

function Display:my_draw()
    local font = Pack.Font.current

    love.graphics.setColor((34 + 20) / 255, (28 + 20) / 255, (26 + 20) / 255, 1)
    love.graphics.rectangle("fill", self:rect())

    font:push()
    for i = 1, 4 do
        font:set_font_size(8)

        local px = self.x + (self.space * i)
            + 28 * (i - 1)
        local py = self.y + self.space_y

        -- love.graphics.setColor(1, 0, 0, 1)
        -- love.graphics.rectangle("fill", px, py, 28, 28)
        self.icons[i]:draw(px, py, 28, 28)

        local value = self.game:get_player()[self.attr[i]]

        font:print(string.format("<color, 0, 0, 0><bold>%d", value), px + 2, py + 1)
        font:print(string.format("<color, 1, 1, 1><bold>%d", value), px + 1, py)

        font:set_font_size(6)
        local key = self.keyboard[i]
        font:printx(string.format("<bold> <color, 0, 0, 0>%s", key), px, py + 28 - 1, px + 29, "center")
        font:printx(string.format("<bold> <color, 1, 1, 0.5>%s", key), px, py + 28 - 2, px + 28, "center")
    end
    font:pop()
end

function Display:draw()
    Affectable.draw(self, self.my_draw)
end

return Display
