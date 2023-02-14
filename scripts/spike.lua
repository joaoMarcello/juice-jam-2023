local GC = require "scripts.bodyComponent"

---@enum Game.Component.Spike.Type
local Types = {
    ground = 1,
    ceil = 2,
    wallRight = 3,
    wallLeft = 4
}

---@type love.Image|nil
local img

---@class Game.Component.Spike : BodyComponent
local Spike = setmetatable({}, GC)
Spike.__index = Spike
Spike.Type = Types

---@return Game.Component.Spike
function Spike:new(game, world, args)
    args = args or {}
    args.x = args.x or (32 * 3)
    args.y = args.y or (32 * 3)
    args.len = args.len or 4
    args.w = 32
    args.h = 20
    args.bottom = args.bottom or (args.y + 32)
    args.position = args.position or "ground"

    if args.position == "ceil" then
        args.w = args.len * 32
        -- args.y = args.bottom and (args.bottom - args.h) or args.y
    elseif args.position == "ground" then
        args.w = args.len * 32
        args.y = args.y + 32 - args.h
    elseif args.position == "wallRight" or args.position == "wallLeft" then
        args.h = 32 * args.len
    end
    args.type = "ghost"

    local obj = GC:new(game, world, args)
    setmetatable(obj, self)

    Spike.__constructor__(obj, game, world, args)
    return obj
end

---@param game GameState.Game
---@param world JM.Physics.World
function Spike:__constructor__(game, world, args)
    self.type = Types.ground
    self.len = args.len
    self.x = args.x
    self.y = args.y
    self.w = args.w
    self.h = args.h

    ---@type Game.Component.Spike.Type
    self.position = Types[args.position] or Types["ground"]

    self.body.allowed_gravity = false

    self.spike = Pack.Anima:new({ img = img or '' })
    self.spike:set_flip_y(self:is_on_ceil())
    self:set_draw_order(0)

    local Phys = _G.Pack.Physics

    ---@type JM.Physics.Body|nil
    local body
    if self:is_on_ground() then
        body = Phys:newBody(world, self.x + 3, self.y + self.h - 10, self.w - 3, 9, "static")
    elseif self:is_on_ceil() then
        body = Phys:newBody(world, self.x + 3, self.y, self.w - 3, 9, "static")
    elseif self:is_on_wall_right() then
        body = Phys:newBody(world, self.body:right() - 9, self.y, 9, self.h, "static")
        self.spike:set_rotation(math.pi * 1.5)
    else
        body = Phys:newBody(world, self.x, self.y, 9, self.h, "static")
        self.spike:set_rotation(math.pi / 2)
    end

    if body then
        body.id = "spike"
    end
end

function Spike:load()
    img = img or love.graphics.newImage('/data/aseprite/spike.png')
    img:setFilter("linear", "linear")
end

function Spike:init()

end

function Spike:finish()
    local r = img and img:release()
    img = nil
end

function Spike:rect()
    return self.x, self.y, self.w, self.h
end

function Spike:is_on_ceil()
    return self.position == Types.ceil
end

function Spike:is_on_ground()
    return self.position == Types.ground
end

function Spike:is_on_wall_right()
    return self.position == Types.wallRight
end

function Spike:is_on_wall_left()
    return self.position == Types.wallLeft
end

function Spike:update(dt)
    self.spike:update(dt)

    local player = self.game:get_player()
    local x, y, w, h = self.body:rect()

    if self:is_on_ceil() then
        h = h + 5
    elseif self:is_on_ground() then
        y = y - 5
    elseif self:is_on_wall_left() then
        x = x + 5
        w = w - 10
        y = y + 5
        h = h - 10
    else
        x = x + 5
        w = w - 10
        y = y + 5
        h = h - 10
    end

    if player.body:check_collision(x + 7, y, w - 7, h)
        and ((self:is_on_ceil() and player.body.speed_y <= 0)
        or (self:is_on_ground() and player.body.speed_y >= 0))
        and not player:is_dead()
    then
        player:kill(true)
    end

    if player.body:check_collision(x, y, w, h)
        and ((self:is_on_wall_left() and player.body.speed_x <= 0)
        or (self:is_on_wall_right() and player.body.speed_y >= 0))
        and not player:is_dead()
    then
        player:kill(true)
    end
end

function Spike:draw()
    if not self.game.camera:rect_is_on_view(self.body:rect()) then
        return
    end

    if self:is_on_wall_right() or self:is_on_wall_left() then
        for i = 1, self.len do
            local y = self.y + 32 * (i - 1)
            self.spike:draw_rec(self.x, y, 32, 32)
        end
    else
        for i = 1, self.len do
            local x = self.x + 32 * (i - 1)
            self.spike:draw_rec(x, self.y, 32, self.h)
        end
    end
end

return Spike
