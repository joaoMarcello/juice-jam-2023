local Utils = Pack.Utils
local GC = require "/scripts/bodyComponent"

---@enum Game.Component.ModeChanger.Modes
local Modes = {
    fixed = 1,
    dynamic = 2
}

---@class Game.Component.ModeChanger: BodyComponent
local Changer = setmetatable({}, GC)
Changer.__index = Changer
Changer.Modes = Modes

---@return Game.Component.ModeChanger
function Changer:new(game, world, args)
    args = args or {}
    args.type = "dynamic"
    args.x = args.x or (32 * 8)
    args.y = args.y or (32 * 6)
    args.w = 32
    args.h = 32
    args.mode = (args.mode and Modes[args.mode]) or Modes.fixed

    local obj = GC:new(game, world, args)
    setmetatable(obj, self)
    Changer.__constructor__(obj, game, args)
    return obj
end

---@param game GameState.Game
function Changer:__constructor__(game, args)
    self.game = game

    local modes = game:get_player().Modes

    self.mode_type = modes.jump

    self.__colors = {
        [modes.normal] = Utils:get_rgba(89 / 255, 89 / 255, 89 / 255, 1),
        [modes.jump] = Utils:get_rgba(212 / 255, 108 / 255, 129 / 255, 1),
        [modes.jump_ex] = Utils:get_rgba(212 / 255, 108 / 255, 129 / 255, 1),
        [modes.dash] = Utils:get_rgba(130 / 255, 108 / 255, 212 / 255, 1),
        [modes.dash_ex] = Utils:get_rgba(130 / 255, 108 / 255, 212 / 255, 1),
        [modes.extreme] = Utils:get_rgba(212 / 255, 111 / 255, 68 / 255, 1),
    }

    self.draw_order = -1

    self:set_mode(args.mode)
end

function Changer:load()

end

function Changer:init()

end

function Changer:finish()

end

function Changer:set_mode(mode)
    mode = mode or Modes.fixed
    if mode == Modes.fixed then
        self.body.allowed_gravity = false
    else
        self.body.allowed_gravity = true
    end
    self.mode = mode
end

function Changer:update(dt)

end

function Changer:draw()
    love.graphics.setColor(self.__colors[self.mode_type])
    love.graphics.rectangle("fill", self.body:rect())
end

return Changer
