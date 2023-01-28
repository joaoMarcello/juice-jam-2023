---@diagnostic disable: param-type-mismatch
---@type GameComponent
local GC = require "/scripts/gameComponent"

local Utils = _G.Pack.Utils

local Font = _G.Pack.Font

---@enum Game.Player.States
local States = {
    default = 1,
    groundPound = 2,
    dash = 3
}

---@param self Game.Player
local function get_state_string(self)
    for _, s in pairs(States) do
        if s == self.state then
            return _
        end
    end
end

local keyboard_is_down = love.keyboard.isDown
local math_abs = math.abs


local function pressing(self, key)
    key = "key_" .. key
    local field = self[key]
    if not field then return nil end

    if type(field) == "string" then
        return keyboard_is_down(field)
    else
        return keyboard_is_down(field[1]) or keyboard_is_down(field[2])
    end
end

local function pressed(self, key, key_pressed)
    local index = "key_" .. key
    local field = self[index]
    if not field then return nil end

    if type(field) == "string" then
        return key_pressed == field
    else
        return key_pressed == field[1] or key_pressed == field[2]
    end
end

---@param self Game.Player
local function move_default(self, dt)
    local body = self.body
    if pressing(self, 'left') and body.speed_x <= 0.0 then
        body:apply_force(-self.acc)

    elseif pressing(self, "right") and body.speed_x >= 0.0 then
        body:apply_force(self.acc)

    elseif math_abs(body.speed_x) ~= 0.0 then

        local dacc = self.dacc * ((pressing(self, 'left')
            or pressing(self, 'right'))
            and 1.5 or 1.0)

        body.dacc_x = dacc
    end


    self.wall = self.wall or (body.wall_left or body.wall_right)
    local wall = self.wall

    if wall and not body.ground and body.speed_y >= 0 then
        if self.x > wall.x + wall.w then
            self.wall = nil

        elseif pressing(self, 'left') or pressing(self, 'right') then
            body.speed_y = math.sqrt(2 * body.acc_y * 3)

            self:set_state(States.default)

            self.wall_jump_ready = true
        else
            self.wall = nil
        end
    else
        self.wall_jump_ready = false
        self.wall = nil
    end

    if body.speed_y > 0 then
        body.allowed_air_dacc = true
    end

    if body.ground then
        self.dash_lock = false
        self.dash_count = 0
    end
end

local function ground_pound(self, dt)
    return false
end

---@param self Game.Player
local function dashing(self, dt)
    local body = self.body

    self.dash_time = self.dash_time + dt

    if self.dash_direction > 0 and pressing(self, 'left')
        or (self.dash_direction < 0 and pressing(self, 'right'))
    then
        self.dash_time = self.dash_time + dt * 1.5
        if self.dash_instant_stop then
            self.dash_time = self.dash_duration + 1
        end
    end


    if self.dash_time < self.dash_duration then
        if body.speed_y >= 0 then
            body.speed_y = 0.0
            body:apply_force(self.acc * self.dash_direction, -body:weight())
        else
            body:apply_force(self.acc * self.dash_direction)
        end

    else
        if body.h ~= self.h then
            self:restaure_height()
        end

        move_default(self, dt)

        if body.speed_y == 0 and body.ground then
            self:set_state(States.default)
        end
    end
end

---@class Game.Player: GameComponent
local Player = setmetatable({}, GC)
Player.__index = Player


---@return Game.Player
function Player:new(Game, world, args)
    args.type = "dynamic"
    local obj = GC:new(world, args)
    setmetatable(obj, self)

    Player.__constructor__(obj, Game, args)
    return obj
end

---@param Game JM.Scene
function Player:__constructor__(Game, args)
    self.Game = Game

    self.key_left = { 'a', 'left' }
    self.key_right = { 'd', 'right' }
    self.key_down = { 's', 'down' }
    self.key_up = 'w'
    self.key_jump = { 'space', 'z' }
    self.key_attack = 'u'
    self.key_dash = { 'f', 'j' }

    self.body.max_speed_x = self.max_speed
    self.body.allowed_air_dacc = true

    self.dash_instant_stop = false
    self.dash_distance = 32 * 5
    self.dash_duration = 0.5
    self.dash_max = 3
    self.dash_count = 0

    self.wall_jump_ready = false
    self.wall = nil

    self.current_movement = move_default
    self.state = States.default
end

function Player:finish_state(next_state)
    local body = self.body

    if self.state == States.groundPound then
        body:on_event("ground_touch", function() end)
        self.dash_lock = false

    elseif self.state == States.dash then
        body:on_event("axis_x_collision", function() end)
        body:on_event("ground_touch", function() end)

        if next_state == States.groundPound then
            -- self.dash_lock = true
        else
            --self.dash_lock = false
        end

        -- self.dash_count = 0
        self:restaure_height()
    end
end

function Player:set_state(state)
    if self.state == state then return false end

    self:finish_state(state)

    self.state = state
    local body = self.body

    if state == States.groundPound then
        self.current_movement = ground_pound
        body.speed_x = 0
        body.speed_y = math.sqrt(2 * body:weight() * 32 * 0.5)

        body:on_event("ground_touch", function()
            self.Game.camera:shake_in_y(0.1, 3, 0.2, 0.1)
            self:set_state(States.default)
        end)

    elseif state == States.dash and not self.dash_lock then
        self.current_movement = dashing
        body.speed_y = 0.0

        self.dash_time = 0.0
        self.dash_count = self.dash_count + 1

        if pressing(self, 'right') then
            self.dash_direction = 1
        elseif pressing(self, 'left') then
            self.dash_direction = -1
        else
            self.dash_direction = body:direction_x()
        end

        body:dash(self.dash_distance, self.dash_direction)

        --self.dash_lock = self.dash_count >= self.dash_max

        local h = math.floor(self.h * 0.5)
        body:refresh(nil, body.y + body.h - h, nil, h)

        body:on_event("axis_x_collision", function()
            self.dash_time = self.dash_duration + 1
        end)

        body:on_event("ground_touch", function()
            self.dash_lock = false
            self:set_state(States.default)
        end)
    else

        self.current_movement = move_default
    end
end

function Player:restaure_height()
    local body = self.body
    local h = self.h

    if body.h ~= h then
        body:refresh(nil, body.y + body.h - h, nil, h)
    end
end

function Player:jump()
    local body = self.body

    local h = (math_abs(body.speed_x) >= self.max_speed
        or self.state == States.dash)
        and 4.5 or 3.5

    body:jump(32 * h)
end

function Player:key_pressed(key)
    local body = self.body

    if self.state == States.default then

        if pressed(self, 'jump', key) then
            if body.speed_y == 0 then
                self:jump()

            elseif self.wall_jump_ready then
                self:jump()
                body.speed_x = body.max_speed_x * 0.5
                body.allowed_air_dacc = false
                self.wall_jump_ready = false
            end

        elseif pressed(self, 'down', key) and body.speed_y ~= 0 then
            local temp = self.dash_count
            self:set_state(States.groundPound)
            self.dash_count = temp

        elseif pressed(self, 'dash', key) and not self.dash_lock
            and self.dash_count < self.dash_max
            and body.speed_x ~= 0 and (pressing(self, 'right')
                or pressing(self, 'left'))
        then

            self:set_state(States.dash)

        end

    elseif self.state == States.dash then
        if pressed(self, 'jump', key) and body.ground and body.speed_y >= 0 then
            self:restaure_height()
            self:jump()

        elseif pressed(self, 'dash', key) and self.dash_count < self.dash_max
            and not body.ground
        then
            self.state = nil
            self:set_state(States.dash)

        elseif pressed(self, 'down', key) and body.speed_y ~= 0 then
            local temp = self.dash_count
            self:set_state(States.groundPound)
            self.dash_count = temp
        end

    elseif self.state == States.groundPound then
        if pressed(self, 'dash', key) and not self.dash_lock
            and self.dash_count < self.dash_max
        then
            if pressing(self, 'right') then
                body:apply_force(self.acc)
                body.speed_x = 1
                self:set_state(States.dash)

            elseif pressing(self, 'left') then
                body:apply_force(-self.acc)
                body.speed_x = -1
                self:set_state(States.dash)

            end
        end

    end
end

function Player:update(dt)
    local body = self.body

    self.current_movement(self, dt)

    self.x, self.y = Utils:round(body.x), Utils:round(body.y)
end

function Player:draw()
    love.graphics.setColor(121 / 255, 58 / 255, 128 / 255, 1)
    love.graphics.rectangle("fill", self.body:rect())

    Font:printf(get_state_string(self), self.x,
        self.y - Font.current.__font_size - 20
        , "center"
        , self.x + self.w
    )

    if self.dash_count < self.dash_max then
        Font:print('<color, 0, 0, 1>' .. self.dash_count, self.x, self.y - Font.current.__font_size * 2 - 30)
    else
        Font:print('<color, 1, 0, 0>' .. self.dash_count, self.x, self.y - Font.current.__font_size * 2 - 30)
    end
end

return Player
