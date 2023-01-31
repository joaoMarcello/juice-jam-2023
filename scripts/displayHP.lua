local Affectable = Pack.Affectable
local Utils = Pack.Utils

---@param self Game.GUI.DisplayHP
local function width(self, hp)
    local player = self.game:get_player()
    local hp = hp or player.attr_hp
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

    self.x = 32 * 1
    self.y = 32
    self.w = 32 * 3.5
    self.h = 16

    self.color_bar = Utils:get_rgba(42 / 255, 199 / 255, 57 / 255, 1)
    self.color_outline = Utils:get_rgba(34 / 255, 28 / 255, 26 / 255, 1)
    self.color_nule = Utils:get_rgba(75 / 255, 62 / 255, 58 / 255, 1)

    self.eff_flash = nil
    self.eff_fadeout = nil

    ---@type JM.Template.Affectable
    self.vanish = Affectable:new(
    ---@param arg JM.Template.Affectable
        function(arg)
            love.graphics.setColor(arg.color)
            love.graphics.rectangle("fill", self.x, self.y, self.last_width, self.h)
        end)
    self.vanish:set_color2(166 / 255, 22 / 255, 12 / 255, 1)

    self.last_width = width(self)
    self.player_last_hp = self.game:get_player().attr_hp
end

function Display:load()

end

function Display:init()

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

function Display:update(dt)
    Affectable.update(self, dt)
    self.vanish:update(dt)

    local player = self.game:get_player()

    if self:player_is_dying() and not self.eff_flash then
        self:set_color2(1, 1, 0, 1)

        self.eff_flash = self:apply_effect("ghost", {
            speed = 0.3, min = 0.2, max = 0.9
        })

    end

    if player.attr_hp < self.player_last_hp
    -- and player.attr_hp ~= self.player_last_hp
    then
        if self.eff_fadeout then
            self.eff_fadeout.__remove = true
        end

        self.eff_fadeout = self.vanish:apply_effect("fadeout", {
            delay = 0.7
        })

        self.last_width = width(self, self.player_last_hp)
        self.player_last_hp = player.attr_hp

    elseif player.attr_hp > self.player_last_hp then
        self.last_width = width(self)
        self.player_last_hp = player.attr_hp
    end
end

---@param self Game.GUI.DisplayHP
local function draw_bar(self)
    local is_dying = self:player_is_dying()

    love.graphics.setColor(is_dying and Utils:get_rgba(1, 0, 0, 1) or self.color_bar)
    love.graphics.rectangle("fill", self:rect())

    if is_dying then
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", self:rect())
    end
end

function Display:draw()
    local font = Pack.Font
    local player = self.game:get_player()

    love.graphics.setColor(self.color_outline)
    love.graphics.rectangle("fill", self:rect2())

    love.graphics.setColor(self.color_nule)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    local is_dead = player:is_dead()
    if not is_dead then
        self.vanish:draw()
    end

    Affectable.draw(self, draw_bar)

    font:print('' .. self.player_last_hp .. '\n' .. self.last_width, self.x + self.w + 10, self.y)
end

return Display
