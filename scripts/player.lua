---@type BodyComponent
local bodyGC = require "scripts.bodyComponent"

local Pill = require "scripts.pill"

local Utils = _G.Pack.Utils

local Font = _G.Pack.Font

---@enum Game.Player.States
local States = {
    default = 1,
    groundPound = 2,
    dash = 3,
    dead = 4
}

---@enum Game.Player.Modes
local Modes = {
    normal = 0,
    jump = 1,
    dash = 2,
    jump_ex = 3,
    dash_ex = 4,
    extreme = 5
}

local debbug = {}

local keyboard_is_down = love.keyboard.isDown
local math_abs = math.abs

local function collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 + w1 > x2
        and x1 < x2 + w2
        and y1 + h1 > y2
        and y1 < y2 + h2
end

---@param self Game.Player
local function get_state_string(self)
    for _, s in pairs(States) do
        if s == self.state then
            return _
        end
    end
end

local function pressing(self, key)
    key = "key_" .. key
    local field = self[key]
    if not field then return nil end

    if type(field) == "string" then
        return keyboard_is_down(field)
    else
        return keyboard_is_down(field[1])
            or (field[2] and keyboard_is_down(field[2]))
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
        if not collision(self.x, self.y, self.w, self.h,
            wall.x - 1, wall.y, wall.w + 2, wall.h)
        then
            self.wall = nil

        elseif pressing(self, 'left') or pressing(self, 'right') then
            body.speed_y = math.sqrt(2 * body.acc_y * 3)

            self:set_state(States.default)

            self.jump_count = 0
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

    if body.speed_y > 0 and self.jump_count == 0
        and not self.wall_jump_ready
        and self.mode ~= Modes.jump and self.mode ~= Modes.jump_ex
        and self.mode ~= Modes.extreme
    then
        self.jump_count = 1
    else
        if body.ground then
            self.dash_count = 0
            self.jump_count = 0
        end
    end
end

---@param self Game.Player
local function ground_pound(self, dt)
    local body = self.body
    body.speed_x = 0
    body.mass = body.world.default_mass * 1.4
    return false
end

---@param self Game.Player
local function dashing(self, dt)
    local body = self.body

    self.dash_time = self.dash_time + dt

    if self.dash_direction > 0 and pressing(self, 'left')
        or (self.dash_direction < 0 and pressing(self, 'right'))
    then
        self.dash_time = self.dash_time + dt * 7
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
        self:set_state(States.default)

        if body.speed_y == 0 and body.ground then
            self:set_state(States.default)
        end
    end
end

---@class Game.Player: BodyComponent
local Player = setmetatable({}, bodyGC)
Player.__index = Player
Player.Modes = Modes
Player.States = States

---@return Game.Player
function Player:new(Game, world, args)
    args = args or {}
    args.type = "dynamic"
    args.x = args.x or (32 * 3)
    args.y = args.y or (32 * 4)
    args.w = 28
    args.h = 58
    args.y = args.bottom and (args.bottom - self.h) or args.y

    local obj = bodyGC:new(Game, world, args)
    setmetatable(obj, self)

    Player.__constructor__(obj, Game, args)
    return obj
end

---@param Game GameState.Game
function Player:__constructor__(Game, args)
    self.Game = Game

    self.key_left = { 'left' }
    self.key_right = { 'right' }
    self.key_down = { 'down' }
    self.key_up = 'w'
    self.key_jump = { 'space', 'up' }
    self.key_attack = 'u'
    self.key_dash = { 'f' }

    self.key_pill_atk = { 'a' }
    self.key_pill_def = { 's' }
    self.key_pill_hp = { 'd' }
    self.key_pill_time = { 'v' }


    self.body.max_speed_x = self.max_speed
    self.body.allowed_air_dacc = true

    self.dash_instant_stop = false
    self.dash_distance = 32 * 5
    self.dash_duration = 0.5
    self.dash_max = 3
    self.dash_count = 0
    self.dash_lock = false

    self.jump_count = 0
    self.jump_max = 2

    self.wall_jump_ready = false
    self.wall = nil

    -- ========   ATRIBUTES  ===============================
    self.attr_hp = 3
    self.attr_hp_max = 6
    self.attr_def = 1
    self.attr_def_max = 3
    self.attr_atk = 1
    self.attr_atk_max = 3

    self.attr_pill_hp = 5
    self.attr_pill_hp_max = 10
    self.attr_pill_atk = 5
    self.attr_pill_atk_max = 5
    self.attr_pill_def = 5
    self.attr_pill_def_max = 5
    self.attr_pill_time = 10
    self.attr_pill_time_max = 15
    --=======================================================

    self.current_movement = move_default
    ---@type Game.Player.States
    self.state = States.default

    ---@type Game.Player.Modes
    self.mode = nil

    self:set_mode(Modes.normal)

    self.ox = self.w / 2
    self.oy = self.h / 2
end

---@param eff_type JM.Effect.id_string
---@param eff_args any
---@return JM.Effect|nil
function Player:apply_effect(eff_type, eff_args)
    if not self.eff_actives then self.eff_actives = {} end
    if self.eff_actives[eff_type] then return self.eff_actives[eff_type] end

    self.eff_actives[eff_type] = bodyGC.apply_effect(self, eff_type, eff_args)
    return self.eff_actives[eff_type]
end

---@alias Game.Component.Player.Attributes "hp"|"def"|"atk"|"pill_hp"|"pill_atk"|"pill_def"|"pill_time"

---@param attr Game.Component.Player.Attributes
---@param mode "add"|"sub"
---@param value number
function Player:set_attribute(attr, mode, value)
    if self:is_dead() then return false end
    if not attr or self.state == States.dead then return false end

    local key = "attr_" .. attr
    local field = self[key]
    if not field then return false end

    local max = self["attr_" .. attr .. "_max"]

    if mode == "add" then
        if self.mode == Modes.extreme
            and (attr == "def" or attr == "hp" or attr == "atk")
        then
            if attr ~= "hp" then
                self:kill(true)
            end
            return false
        end

        self[key] = Utils:clamp(field + value, 0, max)
        debbug['gain'] = "+ " .. value .. ' ' .. key
        debbug['lost'] = ''
    else
        if attr == "atk" and self.mode == Modes.extreme then
            return false
        end

        value = math.abs(value)
        self[key] = Utils:clamp(field - value, 0, max)
        debbug['lost'] = "- " .. value .. ' ' .. key

        if self:is_dead() then
            self:kill()
        end

        if attr == "hp" then

            self.Game:pause(((self:is_dead() or value > 1) and 0.55) or 0.3,
                function(dt)
                    self.Game:game_get_displayHP():update(dt)
                    self.Game.camera:update(dt)
                end)
        end
    end

    return true
end

---@param mode Game.Player.Modes
function Player:set_mode(mode)
    mode = mode or Modes.normal
    if self.mode == mode then return false end

    local last_mode = self.mode
    self.mode = mode

    if mode == Modes.jump then
        self.jump_max = 2
        self.dash_max = 0
        self.dash_count = 0

    elseif mode == Modes.jump_ex then
        self.jump_max = 3
        self.dash_max = 0
        self.dash_count = 0

    elseif mode == Modes.dash then
        self.dash_max = 1
        self.jump_max = 1
        self.jump_count = 0

    elseif mode == Modes.dash_ex then
        self.dash_max = 2
        self.jump_max = 1
        self.jump_count = 0

    elseif mode == Modes.extreme then
        self.dash_max = 2
        self.jump_max = 3
        self.attr_atk = self.attr_atk_max
        self.attr_def = 0
        local value = self.attr_hp - 1
        value = value <= 0 and 1 or value
        self:set_attribute("hp", "sub", value)

    else
        self.dash_max = 0
        self.jump_max = 1
    end

    if last_mode == Modes.extreme then
        self.attr_atk = 0
        self.attr_def = 0
    end

    return true
end

function Player:load()
    Pill:load()
end

local stop_vibrate = false
function Player:kill(no_vibration)
    stop_vibrate = no_vibration or false
    self:set_state(States.dead)
end

function Player:is_dead()
    return self.state == States.dead or self.attr_hp <= 0
end

function Player:finish_state(next_state)
    local body = self.body

    if self.state == States.groundPound then
        body:on_event("ground_touch", function() end)
        body.mass = body.world.default_mass

    elseif self.state == States.dash then
        body:on_event("axis_x_collision", function() end)
        body:on_event("ground_touch", function() end)

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

    elseif state == States.dash then
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

        local h = math.floor(self.h * 0.5)
        body:refresh(nil, body.y + body.h - h, nil, h)

        body:on_event("axis_x_collision", function()
            self.dash_time = self.dash_duration + 1
        end)

        body:on_event("ground_touch", function()
            self.dash_lock = false
            self:set_state(States.default)
        end)


    elseif state == States.dead then

        self.attr_hp = 0
        self.attr_atk = 0
        self.attr_def = 0

        self.current_movement =
        ---@param self Game.Player
        function(self, dt)
            self.body.speed_x = 0
            self.body.acc_x = 0
            if not self.Game.camera:rect_is_on_view(self.x, self.y - 64,
                self.w, self.h + 64 * 2)
                and self.body.y > (32 * 26)
            then
                self.body.speed_y = 0
                self.body.acc_y = 0
                self.body.allowed_gravity = false
            end
        end

        if self.game:game_get_timer().time > 0 and not stop_vibrate then
            self.Game.camera:shake_in_x(0.3, 2, nil, 0.1)
            self.Game.camera:shake_in_y(0.3, 5, nil, 0.15)
            self.Game.camera.shake_rad_y = math.pi
        end

        body.speed_x = 0
        body.speed_y = 0
        body.mass = body.world.default_mass * 0.5
        body.type = Pack.Physics.BodyTypes.ghost
        body:jump(32 * 3, -1)
        body:on_event("start_falling", function()
            body.mass = body.mass * 0.8
        end)

        self.game:pause(0.5, function(dt)
            self.Game:game_get_displayHP():update(dt)
            self.game.camera:update(dt)
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

    local col = body:check(nil, body.y - 1,
        ---@param item JM.Physics.Body
        function(obj, item)
            return item.type == 2
        end)

    if col.n > 0 then
        body:resolve_collisions_y(col)
    end
end

function Player:jump()

    local body = self.body

    local h = (math_abs(body.speed_x) >= self.max_speed
        or self.state == States.dash)
        and 4.5 or 3.5

    if self.jump_count >= 1 then h = 2.5 end

    self.jump_count = self.jump_count + 1

    body:jump(32 * h)
end

---@param type  "atk"|"def"|"hp"|"time"
function Player:throw_pill(type)
    type = type or "atk"

    local key = "attr_pill_" .. type
    local amount = self[key]
    if amount and amount <= 0 then return end

    local pill = Pill:new(self.Game, self.body.world, self,
        {
            x = self.x + self.w / 2,
            y = self.y - 32,
            pill_type = Pill.TypeAttr[type]
        })

    pill.x = self.x + self.w / 2 - pill.w / 2
    pill.body:refresh(pill.x)
    self.Game:game_add_component(pill)

    self[key] = self[key] - 1

    return pill
end

function Player:try_throw_pill(key)
    local throw
    local press = false
    if pressed(self, 'pill_atk', key) then
        throw = self:throw_pill("atk")
        press = true

    elseif pressed(self, 'pill_def', key) then
        throw = self:throw_pill("def")
        press = true

    elseif pressed(self, 'pill_hp', key) then
        throw = self:throw_pill("hp")
        press = true

    elseif pressed(self, 'pill_time', key) then
        throw = self:throw_pill("time")
        press = true
    end

    if not throw and press then
        self.Game:game_get_displayHP().display_pill:shake()
    end
end

function Player:key_pressed(key)
    local body = self.body

    if self.state == States.default then

        if pressed(self, 'jump', key) then
            if not self.wall_jump_ready and self.jump_count < self.jump_max then
                self:jump()
                if self.mode == Modes.jump
                    or self.mode == Modes.jump_ex
                    or self.mode == Modes.extreme
                then
                    if pressing(self, 'right') and body.speed_x < 0 then
                        body.speed_x = -(body.speed_x * 1.1)
                    elseif pressing(self, 'left') and body.speed_x > 0 then
                        body.speed_x = body.speed_x * 1.1
                    end
                end

            elseif self.wall_jump_ready and self.wall then
                self:jump()
                body.speed_x = body.max_speed_x * 0.5
                if body.x < self.wall.x then
                    body.speed_x = -body.speed_x
                end
                --body.allowed_air_dacc = false
                self.wall_jump_ready = false
            end

        elseif pressed(self, 'down', key) and body.speed_y ~= 0 then
            local temp = self.dash_count
            self:set_state(States.groundPound)
            self.dash_count = temp

        elseif pressed(self, 'dash', key)
            and not self.dash_lock
            and self.dash_count < self.dash_max
            and not self.wall_jump_ready
            and body.speed_x ~= 0
            and (pressing(self, 'right') or pressing(self, 'left'))
        then
            self:set_state(States.dash)

        else
            self:try_throw_pill(key)
        end

    elseif self.state == States.dash then
        if pressed(self, 'jump', key)
            and self.jump_count < self.jump_max
        then
            self:restaure_height()
            self:jump()

        elseif pressed(self, 'dash', key)
            and not self.dash_lock
            and self.dash_count < self.dash_max
            and not body.ground and self.dash_time > self.dash_duration
        then
            self.state = nil
            self:set_state(States.dash)

        elseif pressed(self, 'down', key) and body.speed_y ~= 0 then
            local temp = self.dash_count
            self:set_state(States.groundPound)
            self.dash_count = temp

        else
            self:try_throw_pill(key)
        end

    elseif self.state == States.groundPound then
        if pressed(self, 'dash', key)
            and not self.dash_lock
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

        elseif pressed(self, 'jump', key)
            and self.jump_count < self.jump_max
            and (self.mode == Modes.jump or self.mode == Modes.jump_ex
                or self.mode == Modes.extreme)
        then
            self:jump()
            self:set_state(States.default)
        end

    end
end

function Player:key_released(key)
    local body = self.body
    if self.state == States.default then
        if pressed(self, 'jump', key) then
            if self.body.speed_y < 0 then
                self.body.speed_y = self.body.speed_y * 0.6
            end
        end
    end

end

function Player:set_debbug(index, value)
    debbug[index] = value
end

function Player:update(dt)
    local body = self.body

    bodyGC.update(self, dt)

    self.current_movement(self, dt)

    self.x, self.y = Utils:round(body.x), Utils:round(body.y)
end

function Player:my_draw()
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

    Font:print('<color, 1, 1,0>' .. self.jump_count, self.x + self.w, self.y - Font.current.__font_size * 2 - 30)

    if debbug['gain'] and debbug['lost'] then
        Font:print('<color, 0.1, 1, 0.1>' ..
            debbug['gain'] .. "\n<color>" .. debbug['lost'],
            self.x + self.w + 10,
            self.y + 10
        -- , "left", math.huge
        )
    end

    -- Font:print(self.draw_order, self.x - 100, self.y)
end

function Player:draw()
    bodyGC.draw(self, self.my_draw)
end

return Player
