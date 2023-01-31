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

    ---@type JM.Effect
    self.eff_rot = self.affect:apply_effect('clockWise')
    --self.affect:set_effect_transform("rot", math.pi / 2)
    self.eff_rot.__is_enabled = false

    self:set_mode()
end

function Display:load()
    img_seta = img_seta or love.graphics.newImage('/data/aseprite/seta_mode.png')
    img_seta:setFilter("linear", "linear")
end

function Display:init()

end

---@param mode Game.Player.Modes|nil
function Display:set_mode(mode)
    local player = self.game:get_player()
    mode = mode or player.mode

    if self.mode == mode then return false end

    local function rotate(rad)
        self.eff_rot.__rad = rad
        self.affect:set_effect_transform("rot", rad)
    end

    local modes = player.Modes

    if mode == modes.dash then
        rotate(math.pi / 2)
    elseif mode == modes.jump then
        rotate(0)
    end

    self.mode = mode

    self:flash()

    return true
end

function Display:flash()
    if self.eff_flash then self.eff_flash.__remove = true end

    self.eff_flash = self.affect:apply_effect("ghost", { speed = 0.2, max_sequence = 4 })

    self.eff_flash:set_final_action(function()
        self.eff_flash = nil
    end)
end

function Display:finish()
    local r = img_seta and img_seta:release()
    img_seta = nil
end

function Display:update(dt)
    Affectable.update(self, dt)
    self.arrow:update(dt)
    self.affect:update(dt)

    self:set_mode()
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

    if self.eff_flash then
        love.graphics.setColor(self.affect.color)
        love.graphics.circle("fill", self.x, self.y, self.radius - 2)
    end

    local x, y = self.x - self.radius, self.y - self.radius

    self.affect.x = x
    self.affect.y = y

    self.affect:draw(function()
        self.arrow:set_color2(0.2, 0.2, 0.2, 0.7)
        self.arrow:draw(self.x + 1, self.y + 4 + 1)
        self.arrow:draw(self.x + 1, self.y - 12 + 4 + 1)

        self.arrow:set_color2(1, 1, 1, 1)
        self.arrow:draw(self.x, self.y + 4)
        self.arrow:draw(self.x, self.y - 12 + 4)
    end)
end

function Display:draw()
    --self:my_draw()
    Affectable.draw(self, self.my_draw)

end

return Display
