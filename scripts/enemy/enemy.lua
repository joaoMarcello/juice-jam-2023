local GC = require "scripts.bodyComponent"

---@enum Game.Enemy.States
local States = {
    active = 1,
    dead = 2,
    unactive = 3
}

---@param self Game.Enemy
local function get_state_string(self)
    for state, value in pairs(States) do
        if value == self.state then
            return state
        end
    end
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
    self.attr_atk = args.atk or 2
    self.attr_def = args.def or 1

    self.ox = self.w / 2
    self.oy = self.h / 2

    self.args = args

    self.state = States.unactive

    self.allow_respawn = true
end

function Enemy:get_state_string()
    return get_state_string(self)
end

function Enemy:respawn()
    if self.game.camera:rect_is_on_view(self.args.x, self.args.y, self.args.w, self.args.h) then return end

    self.__remove = true
    ---@diagnostic disable-next-line: param-type-mismatch
    self.game:game_add_component(self:new(self.game, self.world, self.args))
end

---@param state "active"|"dead"|"unactive"
function Enemy:set_state(state)
    local r = States[state]
    if r then
        self.state = r
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
        return true
    end
end

---@param dt number
---@param camera JM.Camera.Camera|nil
---@return boolean enemy_is_active
function Enemy:update(dt, camera)
    camera = camera or self.game.camera

    GC.update(self, dt)

    local body = self.body

    if camera and self.state == States.unactive
        and camera:rect_is_on_view(body.x - 16, body.y - 16, body.w + 32, body.h + 32)
    then
        self:set_state("active")
    end

    if self.state == States.dead then
        body.speed_x = 32 * 3

        if self.allow_respawn then
            if not camera:rect_is_on_view(body.x - 16, body.y + 32, body.w + 32, body.h + 32) or not self.is_visible then
                self:set_visible(false)
                self:respawn()
            end
            if not self.is_visible then
                self.body.acc_y = 0
                self.body.allowed_gravity = false
                self.body.acc_x = 0
                self.body.speed_y = 0
                self.body.speed_x = 0
            end
        end
    end

    self.x, self.y = body.x, body.y
    return self.state ~= States.unactive
end

local font = _G.Pack.Font
function Enemy:draw(custom_draw)
    if not self.is_visible then return end
    GC.draw(self, custom_draw)

    font:print('<color, 0,1,0>' .. self.attr_hp .. '\n<color>' .. self.attr_atk .. '\n<color, 0, 0, 1>' .. self.attr_def
        ,
        self.x + self.w + 3,
        self.y - 16)

    font:print(self:get_state_string(), self.x, self.y - 22)
end

return Enemy
