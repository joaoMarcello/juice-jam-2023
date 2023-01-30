---@type BodyComponent
local GC = require "/scripts/gameComponent"

local Utils = Pack.Utils

local Affectable = Pack.Affectable

local img = {}

---@enum Game.Component.Pill.TypeMove
local TypeMove = {
    dynamic = 1,
    fixed = 2
}

local img = {}

---@enum Game.Component.Pill.Type
local TypePill = {
    atk = 1,
    def = 2,
    hp = 3,
    time = 4,
    dash = 5,
    jump = 6
}

---@param self Game.Component.Pill
local function get_type_string(self)
    for _, t in pairs(TypePill) do
        if t == self.type then return tostring(_) end
    end
end

---@class Game.Component.Pill: BodyComponent
local Pill = setmetatable({}, GC)
Pill.__index = Pill
Pill.TypeMove = TypeMove
Pill.TypeAttr = TypePill

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

    local obj = GC:new(Game, world, args)
    setmetatable(obj, self)
    Pill.__constructor__(obj, Game, player, args)
    return obj
end

function Pill:load()
    img[TypePill.atk] = img[TypePill.atk]
        or love.graphics.newImage('/data/aseprite/pill_atk.png')

    img[TypePill.def] = img[TypePill.def]
        or love.graphics.newImage('/data/aseprite/pill_def.png')

    img[TypePill.hp] = img[TypePill.hp]
        or love.graphics.newImage('/data/aseprite/pill_hp.png')

    img[TypePill.time] = img[TypePill.time]
        or love.graphics.newImage('/data/aseprite/pill_time.png')
end

function Pill:finish()
    -- img = {}
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

    self.__gain = math.random() >= 0.3333 and 1 or 2

    self.eff_swing = self:apply_effect("swing", { speed = 0.25, range = 0.05 })

    if self.type_move == TypeMove.dynamic then
        self.eff_popin = self:apply_effect("popin", { speed = 0.5, min = 0.6 })
    end

    self.body.mass = self.body.world.default_mass * 1.5
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

    self.anima = Pack.Anima:new({ img = img[self.type] })
    if self.__gain > 1 then
        self.anima:apply_effect("flash", { color = { 0.6, 0.6, 0.2 }, speed = 0.4 })
    end
end

function Pill:reward()
    local gain = self.__gain
    self.player:set_attribute(get_type_string(self), "add", gain)
    return gain
end

function Pill:punish(gain, except)
    local player = self.player

    local type_pill = get_type_string(self)
    local len_type_punish = 3
    local attr
    local types_punish = {
        ["hp"] = true,
        ["atk"] = true,
        ["def"] = true,
        ["time"] = true
    }
    types_punish[type_pill] = nil

    if except and types_punish[except] then
        types_punish[except] = nil
        len_type_punish = len_type_punish - 1
    end

    local count = 1
    for field, _ in pairs(types_punish) do
        local key = "attr_" .. field

        if (player[key] and math.random() >= 0.5)
            or count == len_type_punish
        then
            if player[key] and player[key] <= 0 then goto continue end
            attr = field
            break
        end

        ::continue::
        count = count + 1
    end

    local function extra_punish(prob, except)
        prob = prob or 0.5
        if math.random() >= (1.0 - prob) then
            local temp = math.random() >= 0.5 and "def" or "atk"

            if temp ~= type_pill then
                if not except or (except and not except:match(type_pill)) then
                    player:set_attribute(temp, "sub", 1)
                    return temp
                end
            end
        end
    end

    if attr == "time" or (not attr and type_pill ~= "time") then
        self.game:game_get_timer():decrement(15 * self.__gain, true)

        player:set_debbug('lost', string.format('- %d s TIME', 15 * self.__gain))

        local result = extra_punish(0.4)
        if result then
            player:set_debbug('lost', string.format('- %d s TIME and -1 ' .. result, self.__gain * 15))
        end

    elseif attr then
        if gain >= 2 and attr:match("hp") and player.attr_hp <= 2 then
            gain = 1
        end

        player:set_attribute(attr, "sub", gain)

        local r = type_pill ~= "hp" and extra_punish(0.75, attr)
        if r then
            player:set_debbug('lost', string.format('- %d %s and - 1 %s', gain, attr, r))
        end
    end
end

function Pill:update(dt)
    Affectable.update(self, dt)

    self.anima:update(dt)

    local body = self.body

    if self.type_move == TypeMove.dynamic then
        local on_view = self.game.camera:rect_is_on_view(body:rect())
        self.__remove = not on_view and body.y > self.game.camera.y
    end

    if body:check_collision(self.player.body:rect()) then
        self.__remove = true

        if self.type == TypePill.time then
            self.game:game_get_timer():increment(25 * self.__gain, true)
            self:punish(1, "hp")
        else
            local gain = self:reward()
            self:punish(gain)
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
