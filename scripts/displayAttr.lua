local Affectable = Pack.Affectable
local Utils = Pack.Utils

---@type love.Image|nil
local img

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
end

function Display:finish()
    local r = img and img:release()
    img = nil
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

    if self.track == "atk" then
        self.icon:set_color(args.color or Utils:get_rgba(1, 0.3, 0.3))
    elseif self.track == "def" then
        self.icon:set_color(args.color or Utils:get_rgba(0.3, 0.3, 1))
    end

    self.key = 'attr_' .. self.track
end

function Display:update(dt)
    self.icon:update(dt)
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

    for i = 1, player[self.key] do
        self.icon:draw_rec(self.x + (self.w - 3) * (i - 1) + 25, self.y, self.w, self.h - 1)
    end
end

return Display
