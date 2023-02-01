local Affectable = Pack.Affectable
local Utils = Pack.Utils

---@type love.Image|nil
local img

---@type love.Image|nil
local img2

---@class Game.GUI.DisplayAttr: JM.Template.Affectable
local Display = setmetatable({}, Affectable)
Display.__index = Display

---@return Game.GUI.DisplayAttr
function Display:new(game, args)
    local obj = Affectable:new()
    setmetatable(obj, self)
    Display.__constructor__(obj, game, args)
    return obj
end

function Display:load()
    img = img or love.graphics.newImage('/data/aseprite/attribute.png')
    local r = img and img:setFilter("linear", "linear")

    img2 = img2 or love.graphics.newImage('/data/aseprite/attribute_white.png')
    r = img2 and img2:setFilter("linear", "linear")
end

function Display:finish()
    local r = img and img:release()
    img = nil
    r = img2 and img2:release()
    img2 = nil
end

function Display:init()

end

---@param game GameState.Game
function Display:__constructor__(game, args)
    self.game = game
    self.x = args.x or (32 * 6)
    self.y = args.y or (32 * 5)

    ---@type Game.Component.Player.Attributes
    self.track = args.attr or "def"

    if img then
        self.w, self.h = img:getDimensions()
    end

    self.icon = Pack.Anima:new({ img = img or '' })
    self.icon_dark = Pack.Anima:new({ img = img or '' })
    self.icon_dark:set_color2(0.4, 0.4, 0.4, 1)

    self.icon_eff = Pack.Anima:new({ img = img2 or '' })
    self.icon_eff:set_color2(1, 1, 0.7, 1)

    self.__color = {
        ["attr_atk"] = Utils:get_rgba(1, 0.3, 0.3),
        ["attr_def"] = Utils:get_rgba(0.3, 0.3, 1)
    }

    self.key = 'attr_' .. self.track
    self.key_max = self.key .. "_max"

    if self.track == "atk" then
        self.icon:set_color(self.__color[self.key])
    elseif self.track == "def" then
        self.icon:set_color(self.__color[self.key])
    end

    self.last_attr = self.game:get_player()[self.key]
end

function Display:flash(duration, speed)
    self.eff_flash = self.icon_eff:apply_effect("ghost",
        { speed = speed or 0.17, duration = duration })
end

function Display:update(dt)
    self.icon:update(dt)
    self.icon_eff:update(dt)

    local player = self.game:get_player()
    local player_attr = player[self.key]
    local max = player[self.key_max]

    if self.last_attr ~= player_attr
    -- and (not self.eff_flash or self.eff_flash.__remove)
    then
        if self.eff_flash then self.eff_flash.__remove = true end

        if player_attr > self.last_attr then
            local is_max = player_attr >= max
            self:flash(not is_max and (0.17 * 3), is_max and 0.3)
        end

        self.last_attr = player_attr
    end
end

function Display:draw()
    local player = self.game:get_player()

    love.graphics.setColor(0.3, 0.3, 0.3, 0.9)
    love.graphics.rectangle("fill", self.x, self.y - 3, self.w * 3 + 25, self.h + 3)

    local font = Pack.Font.current
    font:push()
    font:set_font_size(5)
    font:printx(
        string.format("<color, 0, 0, 0> <bold> %s", self.track:upper()),
        self.x + 11,
        self.y + self.h - 5 - 1,
        self.x + 100,
        "left"
    )

    font:printx(
        string.format("<color, 1, 1, 1> <bold> %s", self.track:upper()), self.x + 10,
        self.y + self.h - 5 - 2,
        self.x + 100,
        "left"
    )
    font:pop()

    for i = 1, player[self.key .. "_max"] do
        local px, py, pw, ph = self.x + (self.w - 3) * (i - 1) + 25, self.y, self.w, self.h - 1

        if i > player[self.key] then
            self.icon_dark:draw_rec(px, py, pw, ph)
        else
            self.icon:draw_rec(px, py, pw, ph)
            if self.eff_flash and not self.eff_flash.__remove then
                self.icon_eff:draw_rec(px, py, pw, ph)
            end
        end
    end

    -- font:print('' .. self.last_attr, self.x + self.w * 3 + 30, self.y)
end

return Display
