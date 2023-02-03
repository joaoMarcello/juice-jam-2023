---@type BodyComponent
local bodyGC = require "scripts.bodyComponent"

local Pill = require "scripts.pill"

local Utils = _G.Pack.Utils

local Font = _G.Pack.Font

local img

local shader_code = [[
extern vec3 hair_color;    
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
    vec4 pix = Texel(texture, texture_coords);
    if (pix.r == 1.0 && pix.g == 0.0 && pix.b == 1.0){
        return vec4(hair_color.r, hair_color.g, hair_color.b, 1.0);
    }
    else{
        return pix;
    }
}
]]

---@type love.Shader
local shader

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
        self.direction = -1

    elseif pressing(self, "right") and body.speed_x >= 0.0 then
        body:apply_force(self.acc)
        self.direction = 1

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

        local col = body:check(nil, body.y + 1,
            ---@param item JM.Physics.Body
            function(obj, item)
                ---@type Game.Enemy|nil
                local enemy = item.id:match("enemy") and item:get_holder()

                return enemy and not enemy.is_projectile and enemy:is_active()
            end)

        if col and col.n > 0 then
            body:jump(32 * 1.1, -1)
        end
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
            body.allowed_air_dacc = true
        end
    end
end

---@param self Game.Player
local function dash_destroy_enemy(self)
    local body = self.body
    local pound = self.pound_collider
    local width = self.dash_width
    local height = self.dash_height
    local px = body.speed_x < 0 and (body.x - width) or (body:right())
    local py = body.y + body.h / 2 - height / 2
    pound:refresh(px, py, width, height)

    local col = pound:check(nil, nil,
        ---@param item JM.Physics.Body
        function(obj, item)
            ---@type Game.Enemy|nil
            local enemy = item.id:match("enemy") and item:get_holder()
            return enemy and enemy:is_active() and not enemy.is_projectile
        end)

    if col.n > 0 then
        for i = 1, col.n do
            ---@type JM.Physics.Body
            local col_body = col.items[i]
            ---@type Game.Enemy|nil
            local enemy = col_body:get_holder()

            if enemy then
                enemy:receive_damage(self.attr_atk, self)

                if not enemy:is_dead() then
                    body.speed_x = body.speed_x * (-1)
                    self:set_state(States.default)
                end
            end
        end
    end
end

---@param self Game.Player
local function dash_collide_wall(self)
    local body = self.body
    local pound = self.pound_collider
    local width = self.dash_width
    local height = self.dash_height
    local px = body.speed_x < 0 and (body.x - width) or (body:right())
    local py = body.y + body.h / 2 - height / 2
    pound:refresh(px, py, width, height)


    local filter =
    ---@param item JM.Physics.Body
    function(obj, item)
        local types = _G.Pack.Physics.BodyTypes
        return item.type == types.static or item.type == types.kinematic
    end


    local col = body:check(body.x - 2, nil, filter)
    col = col.n <= 0 and body:check(body.x + 2, nil, filter) or col

    if col.n > 0 then
        ---@type JM.Physics.Body
        local first = col.items[1]
        local dash_direction = first.x > body.x and 1 or -1

        local x = col.most_left.x
        local y = col.most_up.y
        local r = col.most_right:right()
        local b = col.most_bottom:bottom()
        local w = r - x
        local h = b - y

        w = 32 * 4
        if dash_direction > 0 then
            w = Utils:clamp(w, 0, col.most_right:right() - col.most_left.x + 16)
            x = col.most_left.x
        else
            w = Utils:clamp(w, 0, col.most_right:right() - col.most_left.x + 16)
            x = col.most_right:right() - w
        end
        y = col.most_up.y - 32
        h = h + 32 + 10
        h = Utils:clamp(h, 0, col.most_bottom:bottom() - col.most_up.y + 32 + 10)


        local pound = self.pound_collider
        pound:refresh(x, y, w, h)


        if self.attr_atk > 0 then
            local col2 = pound:check(nil, nil,
                ---@param item JM.Physics.Body
                function(obj, item)
                    ---@type Game.Enemy|nil
                    local enemy = item.id:match("enemy") and item:get_holder()
                    return enemy and enemy:is_active() and not enemy.is_projectile
                end)

            if self.attr_atk > 0 and col2.n > 0 then
                for i = 1, col2.n do
                    ---@type Game.Enemy
                    local enemy = col2.items[i]:get_holder()

                    enemy:receive_damage(self.attr_atk, nil)
                end

                self.game:pause(0.3, function(dt)
                    self.game.camera:update(dt)
                end)

                self.Game.camera:shake_in_x(0.2, 2, nil, 0.1)
                self.Game.camera:shake_in_y(0.2, 3, nil, 0.15)
                self.Game.camera.shake_rad_y = math.pi

                self:set_state(States.default)
                body:jump(32 * 0.5, -1)
                body.speed_x = (32 * 5) * (-dash_direction)
                body.allowed_air_dacc = false

                self.dash_count = self.dash_count - 1
            end -- END Collide with Enemy
        end
    end
end

---@param self Game.Player
local function pound_destroy_enemy(self, only_on_target)
    local body = self.body
    local pound = self.pound_collider
    local mult = self.attr_atk / self.attr_atk_max
    mult = mult == 0 and 1 or mult
    local width = self.pound_width * mult
    local height = self.pound_height * mult

    pound:refresh(
        body.x + body.w / 2 - width / 2,
        body.y + body.h - height + body.speed_y * (1 / 60) + 10,
        width,
        height
    )

    local col = pound:check(nil, nil,
        ---@param item JM.Physics.Body
        function(obj, item)
            ---@type Game.Enemy|nil
            local enemy = item.id:match("enemy") and item:get_holder()
            return enemy and not enemy.is_projectile and enemy:is_active()
        end)

    if col.n > 0 then
        for i = 1, col.n do
            ---@type Game.Enemy
            local enemy = col.items[i]:get_holder()

            if enemy then
                if only_on_target and enemy:check_collision(
                    body.x - 20, body.y, body.w + 40, body.h + body.speed_y * (1 / 60) + 10
                )
                    or not only_on_target
                then
                    enemy:receive_damage(self.attr_atk, self)

                    if only_on_target and not enemy:is_dead() then
                        self:set_state(States.default)
                        self.body:jump(32 * (1 + self.attr_atk / self.attr_atk_max), -1)
                        body:refresh(nil, enemy.body.y - body.h)
                    end
                end
            end
        end
    end -- END had collisions (col.n > 0)
end

---@param self Game.Player
local function ground_pound(self, dt)
    local body = self.body
    body.speed_x = 0
    body.mass = body.world.default_mass * 1.4

    pound_destroy_enemy(self, true)

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

        dash_destroy_enemy(self)
        -- dash_collide_wall(self)
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

    self.invicible_time = 0.0
    self.invicible_duration = 1.3

    self:set_update_order(10)
    self:set_draw_order(10)

    self.direction = 1

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

    self.dash_width = self.w
    self.dash_height = self.h

    self.pound_width = self.w * 6.5
    self.pound_height = self.h * 2
    self.pound_collider = Pack.Physics:newBody(self.world, self.x, self.y + 64, self.dash_width, self.dash_height,
        "ghost")
    self.pound_collider.allowed_gravity = false

    self.current_movement = move_default
    ---@type Game.Player.States
    self.state = States.default

    ---@type Game.Player.Modes
    self.mode = nil

    self:set_mode(Modes.normal)

    self.ox = self.w / 2
    self.oy = self.h / 2

    local Anima = Pack.Anima
    self.anima = {
        ["idle"] = Anima:new { img = img["idle"], frames = 2 },
        ["jump"] = Anima:new { img = img["jump"], frames = 1 },
        ["fall"] = Anima:new { img = img["fall"], frames = 1 },
    }

    self.hair_colors = {
        [Modes.normal] = { 66 / 255, 57 / 255, 62 / 255 },
        [Modes.dash] = { 130 / 255, 108 / 255, 212 / 255 },
        [Modes.dash_ex] = { 76 / 255, 90 / 255, 212 / 255 },
        [Modes.jump] = { 212 / 255, 138 / 255, 154 / 255 },
        [Modes.jump_ex] = { 209 / 255, 98 / 255, 187 / 255 },
        [Modes.extreme] = { 250 / 255, 137 / 255, 62 / 255 },
    }
    self.cur_anima = self.anima["idle"]
end

function Player:load()
    local loadImage = love.graphics.newImage
    img = img or {
        ["idle"] = loadImage('/data/animations/player-idle-sheet.png'),

        ["jump"] = loadImage("/data/animations/player-jump-sheet.png"),

        ["fall"] = loadImage("/data/animations/player-falling-sheet.png"),
    }

    for _, data in pairs(img) do
        data:setFilter("nearest", "nearest")
    end

    shader = shader or love.graphics.newShader(shader_code)

    Pill:load()
end

function Player:init()

end

function Player:finish()
    if img then
        local r
        r = img["idle"] and img["idle"]:release()
        r = img["jump"] and img["jump"]:release()
        r = img["fall"] and img["fall"]:release()
    end
    img = nil

    local r = shader and shader:release()

    Pill:finish()
end

function Player:select_anima()
    local body = self.body
    local mode = self.mode
    local state = self.state

    local new_anima = self.anima["idle"]
    if body.speed_y ~= 0 and (body.speed_y < 0.3 or body.speed_y < 32 * 3) then
        new_anima = self.anima["jump"]
    elseif body.speed_y > 0 then
        new_anima = self.anima["fall"]
    end
    self.cur_anima = Pack.Anima.change_animation(self.cur_anima, new_anima)
end

---@param atk number
---@param enemy Game.Enemy|nil
function Player:receive_damage(atk, enemy)
    if self.invicible_time > 0 then
        return false
    end

    local value = atk - self.attr_def
    value = value == 0 and 0.5 or value

    if value > 0 then
        self:set_attribute("hp", "sub", value)
        self.invicible_time = self.invicible_duration
        return true

    elseif enemy then
        local enemy_bd = enemy.body
        local body = self.body

        local direction = (body.x + body.w / 2) < (enemy_bd.x + enemy_bd.w / 2) and -1 or 1
        body.speed_x = 32 * 2 * direction
        body.allowed_air_dacc = false

        if body.speed_y >= 0 then
            body:jump(32 * 1.5, -1)
        else
            body.speed_y = body.speed_y * 0.3
        end

        if direction < 0 then
            body.speed_x = body.speed_x - enemy_bd.speed_x
            body:refresh(enemy_bd.x - body.w - 1)
            local col = body:check(body.x - 1, nil,
                ---@param item JM.Physics.Body
                function(obj, item)
                    return item.type == Pack.Physics.BodyTypes.static
                end)
            if col.n > 0 then
                body:resolve_collisions_x(col)
            end
        else
            body.speed_x = body.speed_x + enemy_bd.speed_x
            body:refresh(enemy_bd:right() + 1)
            local col = body:check(body.x + 1, nil,
                ---@param item JM.Physics.Body
                function(obj, item)
                    return item.type == Pack.Physics.BodyTypes.static
                end)
            if col.n > 0 then
                body:resolve_collisions_x(col)
            end
        end

        return true
    end
end

---@param eff_type JM.Effect.id_string
---@param eff_args any
---@return JM.Effect|nil
function Player:apply_effect(eff_type, eff_args)
    if not self.eff_actives then self.eff_actives = {} end
    if self.eff_actives[eff_type] then
        self.eff_actives[eff_type].__remove = true
    end

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

            if not self:is_dead() then
                self:apply_effect("flickering", {
                    speed = 0.07,
                    duration = self.invicible_duration
                })
            end -- END ATTR is HP
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
            pound_destroy_enemy(self)
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
            dash_collide_wall(self)
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
            -- self.Game.camera:shake_in_x(0.3, 2, nil, 0.1)
            -- self.Game.camera:shake_in_y(0.3, 5, nil, 0.15)
            -- self.Game.camera.shake_rad_y = math.pi
        end

        body.speed_x = 0
        body.speed_y = 0
        body.mass = body.world.default_mass * 0.9
        body.type = Pack.Physics.BodyTypes.ghost
        body:jump(32 * 3, -1)
        body:on_event("start_falling", function()
            body.mass = body.mass * 0.8
        end)

        self.game:pause(0.5, function(dt)
            self.Game:game_get_displayHP():update(dt)
            self.game.camera:update(dt)
        end)

        local r = self.eff_actives and self.eff_actives['flickering']
        if r then self.eff_actives['flickering'].__remove = true end

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

    if self.invicible_time > 0 then
        self.invicible_time = Utils:clamp(
            self.invicible_time - dt,
            0, self.invicible_duration
        )
    end

    self:select_anima()
    self.cur_anima:set_flip_x(self.direction < 0 and true)
    self.cur_anima:update(dt)

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

    love.graphics.setShader(shader)
    shader:sendColor("hair_color", self.hair_colors[self.mode])
    self.cur_anima:draw_rec(self.x, self.y, self.body.w, self.body.h)
    love.graphics.setShader()

    -- Font:print(self.draw_order, self.x - 100, self.y)
end

function Player:draw()
    bodyGC.draw(self, self.my_draw)
end

return Player
