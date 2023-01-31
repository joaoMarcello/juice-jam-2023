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
        [modes.jump_ex] = Utils:get_rgba(),
        [modes.dash] = Utils:get_rgba(130 / 255, 108 / 255, 212 / 255, 1),
        [modes.dash_ex] = Utils:get_rgba(),
        [modes.extreme] = Utils:get_rgba(212 / 255, 111 / 255, 68 / 255, 1),
    }

    self.color_outline = Utils:get_rgba(34 / 255, 28 / 255, 26 / 255, 1)

    self.arrow = JM_Anima:new({ img = img_seta or '' })
    self.arrow:set_size((self.radius - 12) * 2, (self.radius - 12) * 2)
    -- self.arrow:apply_effect('clockWise')

    ---@type JM.Template.Affectable
    self.aff = Affectable:new()

    self.aff.ox = self.radius
    self.aff.oy = self.radius
    self.aff:apply_effect('clockWise')
    -- self.arrow:set_rotation(math.pi / 2)
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

function Display:update(dt)
    Affectable.update(self, dt)
    self.arrow:update(dt)
    self.aff:update(dt)
end

function Display:my_draw()
    local mode = self.game:get_player().mode

    love.graphics.setColor(self.color_outline)
    love.graphics.circle("fill", self.x, self.y, self.radius)

    love.graphics.setColor(self.__colors[mode])
    love.graphics.circle("fill", self.x, self.y, self.radius - 2)

    local x, y, w, h = self.x - self.radius, self.y - self.radius, self.radius * 2, self.radius * 2


    self.aff.x = x
    self.aff.y = y
    self.aff:draw(function()
        self.arrow:draw(self.x, self.y + 4)
        self.arrow:draw(self.x, self.y - 12 + 4)
    end)
end

function Display:draw()
    self:my_draw()
end

return Display
