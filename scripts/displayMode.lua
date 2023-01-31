local Affectable = Pack.Affectable
local Utils = Pack.Utils

---@type love.Image|nil
local img_seta


---@class Game.GUI.DisplayMode: JM.Template.Affectable
local Display = setmetatable({}, Affectable)
Display.__index = Display

---@return Game.GUI.DisplayMode
function Display:new(game, args)
    local obj = Affectable:new()
    setmetatable(obj, self)
    Display.__constructor__(obj, game, args)
    return obj
end

---@param game GameState.Game
function Display:__constructor__(game, args)
    self.radius = 28
    self.x = args.x or 32
    self.y = args.x or 32
    self.game = game

    local modes = game:get_player().Modes

    self.__colors = {
        [modes.normal] = Utils:get_rgba(89 / 255, 89 / 255, 89 / 255, 1),
        [modes.jump] = Utils:get_rgba(212 / 255, 108 / 255, 129 / 255, 1),
        [modes.jump_ex] = Utils:get_rgba(212 / 255, 108 / 255, 129 / 255, 1),
        [modes.dash] = Utils:get_rgba(130 / 255, 108 / 255, 212 / 255, 1),
        [modes.dash_ex] = Utils:get_rgba(130 / 255, 108 / 255, 212 / 255, 1),
        [modes.extreme] = Utils:get_rgba(212 / 255, 111 / 255, 68 / 255, 1),
    }

    self.color_outline = Utils:get_rgba(34 / 255, 28 / 255, 26 / 255, 1)

    self.arrow = JM_Anima:new({ img = img_seta or '' })
    self.arrow:set_size((self.radius - 12) * 2, (self.radius - 12) * 2)
    -- self.arrow:apply_effect('clockWise')

    ---@type JM.Template.Affectable
    self.affect = Affectable:new()

    self.affect.ox = self.radius
    self.affect.oy = self.radius
    self.affect:set_color2(1, 1, 0.5, 1)
    self.affect:apply_effect("pulse", { range = 0.09, speed = 0.5 })

    ---@type JM.Effect
    self.eff_rot = self.affect:apply_effect('clockWise', { speed = 1.2 })
    self.eff_rot.__is_enabled = false

    self:set_mode()
end

function Display:load()
    img_seta = img_seta or love.graphics.newImage('/data/aseprite/seta_mode.png')
    img_seta:setFilter("linear", "linear")
end

function Display:init()

end

function Display:finish()
    local r = img_seta and img_seta:release()
    img_seta = nil
end

---@param mode Game.Player.Modes|nil
function Display:set_mode(mode, use_flash)
    local player = self.game:get_player()
    mode = mode or player.mode

    if self.mode == mode then return false end

    local function rotate(rad)
        self.eff_rot.__rad = rad
        self.affect:set_effect_transform("rot", rad)
    end

    local modes = player.Modes

    self.eff_rot.__is_enabled = false

    if mode == modes.dash or mode == modes.dash_ex then
        rotate(math.pi / 2)
    elseif mode == modes.jump or mode == modes.jump_ex then
        rotate(0)
    elseif mode == modes.extreme then
        self.eff_rot.__is_enabled = true
    end

    self.mode = mode

    local r = use_flash and self:flash()

    return true
end

function Display:get_mode_string()
    for mode, _ in pairs(self.game:get_player().Modes) do
        if _ == self.mode then
            return mode
        end
    end
end

function Display:flash()
    if self.eff_flash then self.eff_flash.__remove = true end

    self.eff_flash = self.affect:apply_effect("ghost",
        { speed = 0.2, max_sequence = self.mode ~= self.game:get_player().Modes.extreme and 4 or nil })

    self.eff_flash:set_final_action(function()
        if self.mode ~= self.game:get_player().Modes.extreme then
            self.eff_flash = nil
        end
    end)
end

function Display:update(dt)
    Affectable.update(self, dt)
    self.arrow:update(dt)
    self.affect:update(dt)

    self:set_mode(nil, true)
end

---@param self Game.GUI.DisplayMode
local function draw_arrow(self)
    self.arrow:draw(self.x, self.y + 4)
    self.arrow:draw(self.x, self.y - 12 + 4)
end

function Display:my_draw()
    local mode = self.game:get_player().mode

    love.graphics.setColor(self.color_outline)
    love.graphics.circle("fill", self.x, self.y, self.radius)

    love.graphics.setColor(self.__colors[mode])
    love.graphics.circle("fill", self.x, self.y, self.radius - 2)

    if self.eff_flash and not self.eff_flash.__remove then
        love.graphics.setColor(self.affect.color)
        love.graphics.circle("fill", self.x, self.y, self.radius - 2)
    end

    local x, y = self.x - self.radius, self.y - self.radius

    self.affect.x = x
    self.affect.y = y

    local player = self.game:get_player()
    local modes = player.Modes

    self.affect:draw(function()
        self.arrow:set_color2(0.2, 0.2, 0.2, 0.7)
        self.arrow:draw(self.x + 1, self.y + 4 + 1)
        self.arrow:draw(self.x + 1, self.y - 12 + 4 + 1)

        if self.mode == modes.normal then
            self.arrow:set_color2(0.5, 0.5, 0.5, 1)
        else
            self.arrow:set_color2(1, 1, 1, 1)
        end
        self.arrow:draw(self.x, self.y + 4)
        self.arrow:draw(self.x, self.y - 12 + 4)
    end)

    local font = Pack.Font.current
    font:push()
    font:set_font_size(6)
    font:set_line_space(2)
    local s = self:get_mode_string():upper():gsub("_", " ")
    local py = self.y + self.radius - 10
    local pw = x + self.radius * 2

    font:printx(string.format("<color, 0.3, 0.3, 0.3, 1> <bold> %s\nMODE", s), x - 1, py, pw - 1, "center")

    font:printx(string.format("<color, 0.3, 0.3, 0.3, 1> <bold> %s\nMODE", s), x, py + 1, pw, "center")

    font:printx(string.format("<color, 0, 0, 0, 1> <bold> %s\nMODE", s), x + 1, py + 1, pw + 1, "center")

    if self.mode == modes.normal then
        font:printx(
            string.format("<color, 0.8, 0.8, 0.8, 1> <bold> %s\nMODE", s),
            x, py,
            pw, "center")
    else
        font:printx(
            string.format("<color, 1, 1, 1, 1> <bold> %s\nMODE", s),
            x, py,
            pw, "center")
    end
    font:pop()

end

function Display:draw()
    --self:my_draw()
    Affectable.draw(self, self.my_draw)
end

return Display
