local Affectable = Pack.Affectable
local Utils = Pack.Utils
local GC = require "/scripts/bodyComponent"

---@enum Game.Component.Reset.Types
local Types = {
    jump = 1,
    dash = 2,
    both = 3
}

---@type love.Image|nil
local img

---@class Game.Component.Reseter: BodyComponent
local Reset = {}
Reset.__index = Reset
Reset.Types = Types

function Reset:new(game, world, args)
    args = args or {}
    args.x = args.x or (32 * 3)
    args.y = args.y or (32 * 9)
    args.w = 32
    args.h = 32

    local obj = GC:new(game, world, args)
    setmetatable(obj, self)
    Reset.__constructor__(obj, game, args)
    return obj
end

function Reset:__constructor__(game, args)

end

function Reset:load()
    img = img or love.graphics.newImage('/data/aseprite/reseter_icon.png')
    img:setFilter("linear", "linear")
end

function Reset:init()

end

function Reset:finish()
    local r = img and img:release()
    img = nil
end

function Reset:update(dt)

end

function Reset:draw()

end

return Reset
