---@type GameComponent
local GC = require "/scripts/gameComponent"

local Utils = Pack.Utils

local Affectable = Pack.Affectable

---@type love.Image
local pill_img

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

---@param self Game.Component.Pill
local function get_type_string(self)
    for _, t in pairs(TypePill) do
        if t == self.type then return tostring(_) end
    end
end

---@class Game.Component.Pill: GameComponent
local Pill = setmetatable({}, GC)
Pill.__index = Pill

---comment
---@param Game any
---@param world any
---@param player any
---@param args any
---@return Game.Component.Pill
function Pill:new(Game, world, player, args)
    args.w = 16
    args.h = 32
    args.type = "dynamic"
    args.pill_type = args.pill_type or TypePill.time
    args.pill_type_move = args.pill_type_move or TypeMove.dynamic

    local obj = GC:new(world, args)
    setmetatable(obj, self)
    Pill.__constructor__(obj, Game, player, args)
    return obj
end

function Pill:load()
    pill_img = pill_img or love.graphics.newImage('/data/aseprite/pill.png')
end

function Pill:finish()
    pill_img:release()
end

---@param Game GameState.Game
---@param player Game.Player
function Pill:__constructor__(Game, player, args)
    self.game = Game
    self.player = player

    ---@type Game.Component.Pill.Type
    self.type = args.pill_type
    ---@type Game.Component.Pill.TypeMove
    self.type_move = args.pill_type_move

    self.ox = self.w / 2
    self.oy = self.h / 2

    self.eff_swing = self:apply_effect("swing", { speed = 0.25, range = 0.05 })

    if self.type_move == TypeMove.dynamic then
        self.eff_popin = self:apply_effect("popin", { speed = 0.5 })
    end

    self.body.mass = self.body.world.default_mass * 1.6
    self.body:jump(32 * 3, -1)
    self.body.bouncing_y = 0.3
    self.body.bouncing_x = 0.3

    self.follow_player = true

    self.jump_time = 0.0

    self.body:on_event("start_falling", function()
        self.body.mass = self.body.world.default_mass * 0.8
    end)

    self.body:on_event("ground_touch", function()
        self.eff_swing.__speed = 1.2
        self.eff_swing.__range = 0.02
        self.body.bouncing_y = 0.6
        self.follow_player = false
        self:apply_effect("jelly")
    end)

    self.body:on_event("axis_x_collision", function()
        self.follow_player = false
    end)

    self.body:on_event("ceil_touch", function()
        if self.eff_popin then self.eff_popin.__remove = true end
    end)

    self.anima = Pack.Anima:new({ img = pill_img })
end

function Pill:update(dt)
    Affectable.update(self, dt)

    local body = self.body

    if self.type_move == TypeMove.dynamic then
        local on_view = self.game.camera:rect_is_on_view(body:rect())
        self.__remove = not on_view and body.y > self.game.camera.y
    end

    if body:check_collision(self.player.body:rect()) then
        self.__remove = true

        if self.type == TypePill.time then
            self.game:game_get_timer():increment(20, true)
        else
            self.player:set_attribute(get_type_string(self), "add", 1)
        end
    end

    if self.follow_player then
        self.body.speed_x = self.player.body.speed_x
    else
        self.jump_time = self.jump_time + dt
        if self.jump_time >= 3.5 then
            self.jump_time = 1.5 * math.random()
            if body.speed_y == 0 then
                body:jump(32 / 2, -1)
            end
        end
    end

    self.x, self.y = Utils:round(body.x), Utils:round(body.y)
end

function Pill:my_draw()
    self.anima:draw_rec(self.x, self.y, self.w, self.h)
end

function Pill:draw()
    Affectable.draw(self, self.my_draw)
end

return Pill
