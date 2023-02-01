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
    args.type = "static"

    local obj = GC:new(game, world, args)
    setmetatable(obj, self)

    Spike.__constructor__(obj, game, args)
    return obj
end

---@param game GameState.Game
function Spike:__constructor__(game, args)
    self.type = Types.ground
    self.len = args.len
    self.x = args.x
    self.y = args.y
    self.w = args.w
    self.h = args.h
    self.on_ceil = args.on_ceil

    self.spike = Pack.Anima:new({ img = img or '' })
    self.spike:set_flip_y(self.on_ceil)
    self.draw_order = -1
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
end

function Spike:draw()
    for i = 1, self.len do
        local x = self.x + 32 * (i - 1)
        self.spike:draw_rec(x, self.y, 32, self.h)
    end
end

return Spike
