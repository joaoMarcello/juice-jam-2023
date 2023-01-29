---@type GameComponent
local GC = require "/scripts/gameComponent"

local Utils = Pack.Utils

local Affectable = Pack.Affectable

---@enum Game.Component.Pill.TypeMove
local TypeMove = {
    dynamic = 1,
    fixed = 2
}

---@enum Game.Component.Pill.Type
local TypePill = {
    atk = 1,
    def = 2,
    hp = 3,
    time = 4
}

---@class Game.Component.Pill: GameComponent
local Pill = setmetatable({}, GC)
Pill.__index = Pill

function Pill:new(Game, world, player, args)
    args.w = 16
    args.h = 32
    args.type = "dynamic"
    args.pill_type = args.pill_type or TypePill.hp
    args.pill_type_move = args.pill_type_move or TypeMove.dynamic

    local obj = GC:new(world, args)
    setmetatable(obj, self)
    Pill.__constructor__(obj, Game, player, args)
    return obj
end

---@param Game GameState.Game
---@param player Game.Player
function Pill:__constructor__(Game, player, args)
    self.game = Game
    self.player = player

    self.type = args.type
    self.type_move = args.pill_type_move

    self.color_top = Utils:get_rgba(1, 0, 0)
    self.color_bottom = Utils:get_rgba(0, 0, 1)

    self.ox = self.w / 2
    self.oy = self.h / 2

    self.eff_swing = self:apply_effect("swing", { speed = 0.25, range = 0.05 })

    self.body.mass = self.body.world.default_mass * 1.6
    self.body:jump(32 * 3, -1)
    self.body.bouncing_y = 0.3

    self.follow_player = true

    self.body:on_event("start_falling", function()
        self.body.mass = self.body.world.default_mass * 0.8
    end)

    self.body:on_event("ground_touch", function()
        self.eff_swing.__speed = 1.2
        self.follow_player = false
    end)
end

function Pill:update(dt)
    Affectable.update(self, dt)

    if self.type_move == TypeMove.dynamic then
        local on_view = self.game.camera:rect_is_on_view(self.body:rect())
        self.__remove = not on_view and self.body.y > self.game.camera.y
    end

    if self.body:check_collision(self.player.body:rect()) then
        self.__remove = true
        self.player:set_attribute("atk", "add", 1)
        self.game:game_get_timer():increment(20, true)
    end

    if self.follow_player then
        self.body.speed_x = self.player.body.speed_x
    end

    self.x, self.y = Utils:round(self.body.x), Utils:round(self.body.y)
end

function Pill:my_draw()
    local x, y, w, h = self.body:rect()
    local half_h = h / 2

    love.graphics.setColor(self.color_top)
    love.graphics.rectangle("fill", x, y, w, half_h)

    love.graphics.setColor(self.color_bottom)
    love.graphics.rectangle("fill", x, y + half_h, w, half_h)
end

function Pill:draw()
    Affectable.draw(self, self.my_draw)
end

return Pill
