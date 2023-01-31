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

    love.graphics.setColor(34 / 255, 28 / 255, 26 / 255, 1)
    love.graphics.rectangle("fill", self:rect())

    font:push()
    font:set_font_size(8)
    for i = 1, 4 do
        local px = self.x + (self.space * i)
            + 28 * (i - 1)
        local py = self.y + self.space_y

        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle("fill", px, py, 28, 28)

        local value = self.game:get_player()[self.attr[i]]

        font:print(string.format("<color, 0, 0, 0><bold>%d", value), px + 2, py + 1)
        font:print(string.format("<color, 1, 1, 1><bold>%d", value), px + 1, py)
    end
    font:pop()
end

function Display:draw()
    Affectable.draw(self, self.my_draw)
end

return Display
