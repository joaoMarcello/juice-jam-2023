local GC = require "scripts.bodyComponent"

---@enum Game.Component.Spike.Type
local Types = {
    ground = 1,
    ceil = 2
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
    args.w = args.len * 32
    args.h = 20
    args.bottom = args.bottom or (args.y + 32)
    if not args.on_ceil then
        args.y = args.bottom and (args.bottom - args.h) or args.y
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
    self.on_ceil = args.on_ceil

    self.body.allowed_gravity = false

    self.spike = Pack.Anima:new({ img = img or '' })
    self.spike:set_flip_y(self.on_ceil)
    self.draw_order = -1

    local Phys = _G.Pack.Physics
    if not self.on_ceil then
        Phys:newBody(world, self.x + 3, self.y + self.h - 10, self.w - 3, 9, "static")
    else
        Phys:newBody(world, self.x + 3, self.y, self.w - 3, 9, "static")
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

function Spike:update(dt)
    self.spike:update(dt)

    local player = self.game:get_player()
    local x, y, w, h = self.body:rect()

    if self.on_ceil then
        h = h + 5
    else
        y = y - 5
    end

    if player.body:check_collision(x + 7, y, w - 7, h)
        and ((self.on_ceil and player.body.speed_y <= 0)
            or (not self.on_ceil and player.body.speed_y >= 0))
        and not player:is_dead()
    then
        player:kill(true)
    end
end

function Spike:draw()
    for i = 1, self.len do
        local x = self.x + 32 * (i - 1)
        self.spike:draw_rec(x, self.y, 32, self.h)
    end
end

return Spike
