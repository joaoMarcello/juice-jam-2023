local GC = require "scripts.bodyComponent"
local Utils = Pack.Utils

---@enum Game.Enemy.States
local States = {
    active = 1,
    dead = 2,
    unactive = 3
}

---@enum Game.Enemy.Events
local Events = {
    activated = 1,
    killed = 2,
    damaged = 3
}
---@alias Game.Enemy.EventNames "activated"|"killed"

---@param self Game.Enemy
local function get_state_string(self)
    for state, value in pairs(States) do
        if value == self.state then
            return state
        end
    end
end

---@param self Game.Enemy
---@param type_ Game.Enemy.Events
local function dispatch_event(self, type_)
    local evt = self.events and self.events[type_]
    local r = evt and evt.action(evt.args)
end

---@class Game.Enemy: BodyComponent
local Enemy = setmetatable({}, GC)
Enemy.__index = Enemy
Enemy.States = States

---@param game GameState.Game
---@param world JM.Physics.World
---@param args table
---@return table
function Enemy:new(game, world, args)
    local obj = GC:new(game, world, args)
    setmetatable(obj, self)

    Enemy.__constructor__(obj, args)
    return obj
end

function Enemy:__constructor__(args)
    self.attr_hp = args.hp or 3
    self.attr_hp_max = args.hp_max or 5

    self.attr_atk = args.atk or 2
    self.attr_def = args.def or 1

    self.ox = self.w / 2
    self.oy = self.h / 2

    self.args = args

    self.state = States.unactive
    self.body.is_enabled = false

    self.allow_respawn = true
    self.out_of_bounds = false

    self.is_trying_kill_player = true

    self.invicible_time = 0.0
    self.invicible_duration = 0.15

    self.body.id = "enemy"
end

---@param name Game.Enemy.EventNames
---@param action function
---@param args any
function Enemy:on_event(name, action, args)
    local evt_type = Events[name]
    if not evt_type or not action then return end

    self.events = self.events or {}

    self.events[evt_type] = {
        type = evt_type,
        action = action,
        args = args
    }
end

---@param atk number
---@param player Game.Player|nil
function Enemy:receive_damage(atk, player)
    if self.invicible_time > 0 then
        return false
    end

    local value = atk - self.attr_def
    value = value == 0 and 0.5 or value

    if value > 0 then
        self.attr_hp = Utils:clamp(self.attr_hp - value, 0, self.attr_hp_max)
        if self.attr_hp <= 0 then
            self:kill()
        else
            self.invicible_time = self.invicible_duration
            dispatch_event(self, Events.damaged)
        end
    elseif player then
        local body = self.body
        local player_bd = player.body

        if player_bd:check_collision(body.x, body.y, body.w, body.h) then
            player_bd.speed_x = -player_bd.speed_x * 1.2
            player_bd:jump(32, -1)
        end
    end
end

function Enemy:get_state_string()
    return get_state_string(self)
end

function Enemy:respawn()
    if self.game.camera:rect_is_on_view(self.args.x - 17, self.args.y - 17, self.args.w + 17 * 2, self.args.h + 17 * 2) then return end

    self.__remove = true
    ---@diagnostic disable-next-line: param-type-mismatch
    self.game:game_add_component(self:new(self.game, self.world, self.args))
end

---@param state "active"|"dead"|"unactive"
function Enemy:set_state(state)
    local r = States[state]
    if r then
        self.state = r

        if r == States.active then
            self.body.is_enabled = true
            self.is_visible = true
            dispatch_event(self, Events.activated)
            self.body.id = "enemy_active"
        end

        return true
    end
end

function Enemy:is_active()
    return self.state ~= States.unactive
end

function Enemy:kill()
    if self.state ~= States.dead then
        self.state = States.dead
        self.attr_hp = 0
        local body = self.body
        body.allowed_gravity = true
        body.acc_x = 0
        body.speed_y = 0
        body.type = _G.Pack.Physics.BodyTypes.ghost

        local direction = body:direction_x()
        direction = direction ~= 0 and 1 or direction
        body.speed_x = 32 * 3 * direction
        body:jump(32 * 1.2, -1)
        body.mass = body.mass * 1.2
        dispatch_event(self, Events.killed)
        return true
    end
end

function Enemy:inutilize_body()
    self.body.acc_y = 0
    self.body.allowed_gravity = false
    self.body.acc_x = 0
    self.body.speed_y = 0
    self.body.speed_x = 0
end

--- Only collide id is active and enemy is out of bounds
function Enemy:check_collision(x, y, w, h)
    if self.state == States.active and not self.out_of_bounds then
        return self.body:check_collision(x, y, w, h)
    end
end

function Enemy:is_dead()
    return self.States == States.dead or self.attr_hp <= 0
end

---@param dt number
---@param camera JM.Camera.Camera|nil
---@return boolean enemy_is_active
function Enemy:update(dt, camera)
    camera = camera or self.game.camera

    GC.update(self, dt)

    local body = self.body
    local player = self.game:get_player()
    local player_bd = player.body

    if camera and self.state == States.unactive
        and camera:rect_is_on_view(body.x - 16, body.y - 16, body.w + 32, body.h + 32)
    then
        self:set_state("active")
    end

    if self.state == States.active and not self.out_of_bounds then
        local x, y, w, h = body:rect()
        local len = 32 * 8
        local twice = len * 2
        x = x - len
        y = y - len
        w = w + twice
        h = h + twice
        if not camera:rect_is_on_view(x, y, w, h) then
            self.out_of_bounds = true
            self.body.__remove = true
            self.body.id = "enemy"
        end

        if self.is_trying_kill_player and not player:is_dead()
            and self.invicible_time == 0
            and player_bd:check_collision(body.x, body.y - 1, body.w, body.h + 2)
        then
            player:receive_damage(self.attr_atk, self)
        end
    end

    if self.invicible_time > 0.0 then
        self.invicible_time = Utils:clamp(self.invicible_time - dt, 0, self.invicible_duration)
    end

    if self.out_of_bounds then
        self:set_visible(false)
        -- self:inutilize_body()
        self.body.is_enabled = false
        self:respawn()
    end

    if self.state == States.dead then
        body.speed_x = 32 * 3

        if self.allow_respawn then

            if not camera:rect_is_on_view(body.x - 16, body.y - 16, body.w + 32, body.h + 32)
                or not self.is_visible
            then
                self:set_visible(false)
                self.body.is_enabled = false
                self.body.id = "enemy"
                self:respawn()
            end

            if not self.is_visible then
                self.body.is_enabled = false
            end
        end
    end

    self.x, self.y = body.x, body.y
    return self.state ~= States.unactive and not self.out_of_bounds
end

local font = _G.Pack.Font
function Enemy:draw(custom_draw)
    if not self.is_visible then return end
    GC.draw(self, custom_draw)

    font:print('<color, 0,1,0>' .. self.attr_hp .. '\n<color>' .. self.attr_atk .. '\n<color, 0, 0, 1>' .. self.attr_def
        ,
        self.x + self.w + 3,
        self.y - 16)

    font:print(self.out_of_bounds and 'out_of_bounds' or self:get_state_string(), self.x - self.ox, self.y - 22)
end

return Enemy
