local Affectable = Pack.Affectable
local Utils = Pack.Utils
local DisplayMode = require "scripts.displayMode"
local DisplayAttr = require "scripts.displayAttr"
local DisplayPill = require "scripts.displayPill"

---@param self Game.GUI.DisplayHP
local function width(self, hp)
    local player = self.game:get_player()
    local hp = hp or player.attr_hp
    -- hp = math.ceil(hp)
    local hp_max = player.attr_hp_max

    return self.w * (hp / hp_max)
end

---@class Game.GUI.DisplayHP: JM.Template.Affectable
local Display = setmetatable({}, Affectable)
Display.__index = Display

---@return Game.GUI.DisplayHP
function Display:new(game, args)
    local obj = Affectable:new()
    setmetatable(obj, self)
    Display.__constructor__(obj, game, args)
    return obj
end

---@param game GameState.Game
function Display:__constructor__(game, args)
    self.game = game
    local l, t, r, b = game.camera:get_viewport_in_world_coord()

    self.x = Utils:round(32 * 2.3)
    self.y = Utils:round(32 * 0.9)
    self.w = Utils:round(32 * 4)
    self.h = 16

    self.color_bar = Utils:get_rgba(42 / 255, 199 / 255, 57 / 255, 1)
    self.color_outline = Utils:get_rgba(34 / 255, 28 / 255, 26 / 255, 1)
    self.color_nule = Utils:get_rgba(93 / 255, 93 / 255, 102 / 255, 1)

    self.eff_flash = nil
    self.eff_fadeout = nil

    ---@type JM.Template.Affectable
    self.vanish = Affectable:new(
    ---@param arg JM.Template.Affectable
        function(arg)
            love.graphics.setColor(arg.color)
            love.graphics.rectangle("fill", self.x, self.y, self.last_width, self.h)
        end)
    self.color_vanish_normal = Utils:get_rgba(199 / 255, 26 / 255, 26 / 255, 1)
    self.color_vanish_dying = Utils:get_rgba(199 / 255, 108 / 255, 53 / 255, 1)
    self.vanish:set_color(self.color_vanish_normal)

    self.last_width = width(self)
    self.player_last_hp = self.game:get_player().attr_hp

    self.displayMode = DisplayMode:new(game, {})
    self.displayMode.x = self.x - self.displayMode.radius + 6
    self.displayMode.y = self.y + self.h / 2 + self.displayMode.radius * 0.35
    self.displayMode.x = Utils:round(self.displayMode.x)
    self.displayMode.y = Utils:round(self.displayMode.y)

    self.display_atk = DisplayAttr:new(game, {
        attr = "atk",
        x = self.x + 8,
        y = self.y + self.h + 6
    })

    self.display_def = DisplayAttr:new(game, {
        attr = "def",
        x = self.x + 8,
        y = self.display_atk.y + self.display_atk.h + 5
    })

    self.display_pill = DisplayPill:new(game, {
        -- x = self.displayMode.x - self.displayMode.radius,
        y = self.y - 15,
        x = self.x + self.w + 32 * 6.5 - (28 + 4) * 4
    })
end

function Display:load()
    DisplayMode:load()
    DisplayAttr:load()
    DisplayPill:load()
end

function Display:init()
    self.eff_flash = nil
    self.eff_fadeout = nil
    self.last_width = width(self)
    self.player_last_hp = self.game:get_player().attr_hp
    self.__effect_manager:clear()

    DisplayMode:init()
    DisplayAttr:init()
    DisplayPill:init()
end

function Display:finish()
    DisplayMode:finish()
    DisplayAttr:finish()
    DisplayPill:finish()
end

function Display:player_is_dying()
    return self.game:get_player().attr_hp <= 1
end

function Display:rect()
    local x, y, w, h = self.x, self.y, self.w, self.h

    return x, y, width(self), h
end

function Display:rect2()
    return self.x - 2, self.y - 2, self.w + 4, self.h + 4
end

function Display:flash(cycles, white)
    if self.eff_flash then self.eff_flash.__remove = true end

    if white then
        self:set_color2(141 / 255, 255 / 255, 99 / 255, 1)
    else
        self:set_color2(1, 1, 0, 1)
    end

    self.eff_flash = self:apply_effect("ghost", {
        speed = 0.2, min = 0.2, max = 1, max_sequence = cycles
    })

    self.eff_flash:set_final_action(function()
        self.eff_flash = nil
    end)
end

function Display:update(dt)
    Affectable.update(self, dt)
    self.vanish:update(dt)
    self.displayMode:update(dt)
    self.display_atk:update(dt)
    self.display_def:update(dt)
    self.display_pill:update(dt)

    local player = self.game:get_player()

    if self:player_is_dying() and not self.eff_flash then

        self:flash()

        self.vanish:set_color(self.color_vanish_dying)
    end

    if player.attr_hp < self.player_last_hp then
        local lost = self.player_last_hp - player.attr_hp

        if self.eff_fadeout then
            self.eff_fadeout.__remove = true
        end

        self.eff_fadeout = self.vanish:apply_effect("fadeout", {
            delay = 0.8
        })

        self.last_width = width(self, self.player_last_hp)

        self.player_last_hp = player.attr_hp

        self:apply_effect("earthquake", {
            duration = lost <= 1 and 0.3 or 0.5,
            random = true,
            range_x = 5,
            range_y = 5
        })

        if not self:player_is_dying() then
            self:flash(4)
        end

    elseif player.attr_hp > self.player_last_hp then
        self.last_width = width(self)
        self.player_last_hp = player.attr_hp
        self.vanish:set_color(self.color_vanish_normal)

        if self.eff_flash then
            self.eff_flash.__remove = true
            self.eff_flash = nil
        end
        self:flash(4, true)
    end

end

---@param self Game.GUI.DisplayHP
local function draw_bar(self)
    local is_dying = self:player_is_dying()

    love.graphics.setColor(is_dying and Utils:get_rgba(1, 0, 0, 1) or self.color_bar)
    love.graphics.rectangle("fill", self:rect())

    if self.eff_flash then
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", self:rect())
    end
end

function Display:my_draw()
    local player = self.game:get_player()

    love.graphics.setColor(self.color_outline)
    love.graphics.rectangle("fill", self:rect2())

    love.graphics.setColor(self.color_nule)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    if not player:is_dead() or true then
        self.vanish:draw()
    end

    draw_bar(self)

    self.displayMode:draw()

    self.display_atk:draw()
    self.display_def:draw()

    -- font:print('' .. self.player_last_hp .. '\n' .. self.last_width, self.x + self.w + 10, self.y)
end

function Display:draw()
    Affectable.draw(self, self.my_draw)

    self.display_pill:draw()
end

return Display
