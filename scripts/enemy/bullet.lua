local Enemy = require "scripts.enemy.enemy"

---@class Game.Enemy.Bullet: Game.Enemy
local Bullet = setmetatable({}, Enemy)
Bullet.__index = Bullet

function Bullet:new(game, world, args)
    args = args or {}
    args.type = "ghost"
    args.x = args.x or (32 * 10)
    args.y = args.y or (32 * 4)
    args.w = 20
    args.h = 20
    args.atk = 2
    args.def = 0
    args.hp = 1
    args.bottom = args.bottom or (args.y + 32)
    args.y = args.bottom and (args.bottom - args.h) or args.y

    local obj = Enemy:new(game, world, args)
    setmetatable(obj, Bullet)
    Bullet.__constructor__(obj, args)
    return obj
end

function Bullet:__constructor__(args)
    self.args = args
    self.x = args.x
    self.y = args.y
    self.w = args.w
    self.h = args.h
    self.ox = self.w / 2
    self.oy = self.h / 2

    self:apply_effect("pulse", { speed = 0.3 })

    self.body.allowed_gravity = false

    -- self.collider = Pack.Physics:newBody(self.world, self.x, self.y, self.w, self.h, "ghost")
    -- self.collider.allowed_gravity = false

    self.body:extra_collisor_filter(function()
        return false
    end)

    self.is_projectile = true
    self.allow_respawn = true

    local final_action = function()
        -- self.__remove = true
        local player = self.game:get_player()
        if player:is_dead() then return end

        local body = player.body
        if body.speed_y < 0 then
            body.speed_y = body.speed_y * 0.3
        end
        body.speed_x = body.speed_x * 0.2
        player:set_state(player.States.default)
    end
    self:on_event("pushPlayer", final_action)
    self:on_event("damagePlayer", final_action)
end

function Bullet:load()

end

function Bullet:finish()

end

function Bullet:update(dt, camera)
    local is_active = Enemy.update(self, dt)
    if not is_active then return end
    
    self.body.speed_x = 32 * 2
end

function Bullet:my_draw()
    love.graphics.setColor(64 / 255, 51 / 255, 83 / 255, 1)
    love.graphics.circle("fill", self:get_cx(), self:get_cy(), self.w / 2)
end

function Bullet:draw()
    Enemy.draw(self, self.my_draw)
end

return Bullet
