local GC = require "scripts.bodyComponent"

---@enum Game.Enemy.States
local States = {
    active = 1,
    dead = 2,
    unactive = 3
}

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

    self.state = States.active

    self.allow_respawn = true
end

function Enemy:respawn()
    self:__constructor__(self.args)
end

---@param state "active"|"dead"|"unactive"
function Enemy:set_state(state)
    local r = States[state]
    if r then
        self.state = r
        return true
    end
end

function Enemy:kill()
    if not self.state == States.dead then
        self.state = States.dead
        self.attr_hp = 0
        local body = self.body
        body.allowed_gravity = true
        body.acc_x = 0
        body.speed_y = 0

        local direction = body:direction_x()
        direction = direction ~= 0 and 1 or direction
        body.speed_x = 32 * 3 * direction
        body:jump(32 * 1.5, -1)
        return true
    end
end

---@param dt number
---@param camera JM.Camera.Camera
---@return boolean enemy_is_active
function Enemy:update(dt, camera)

    GC.update(self, dt)

    local body = self.body

    if camera and self.state == States.unactive
        and camera:rect_is_on_view(body.x - 16, body.y, body.w + 32, body.h)
    then
        self:set_state("active")
    end

    if self.state == States.dead then
        body.speed_x = 32 * 3 * body:direction_x()

        if camera and self.allow_respawn
            and not camera:rect_is_on_view(body.x, body.y, body.w, body.h)
        then
            self:respawn()
        end
    end

    self.x, self.y = body.x, body.y
    return self.state == States.active
end

local font = _G.Pack.Font
function Enemy:draw(custom_draw)
    GC.draw(self, custom_draw)

    font:print('<color, 0,1,0>' .. self.attr_hp .. '\n<color>' .. self.attr_atk .. '\n<color, 0, 0, 1>' .. self.attr_def
        ,
        self.x + self.w + 3,
        self.y - 16)
end

return Enemy
