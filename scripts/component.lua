---@class GameComponent
local GC = {}
GC.__index = GC

---@param game GameState.Game
---@return table
function GC:new(game, args)
    args = args or {}
    local obj = setmetatable({}, GC)
    GC.__constructor__(obj, game, args)
    return obj
end

---@param game GameState.Game|GameState.MenuPrincipal
function GC:__constructor__(game, args)
    self.game = game

    self.x = args.x or 0
    self.y = args.y or 0
    self.w = args.w or 0
    self.h = args.h or 0

    self.is_visible = true
    self.is_enable = true

    self.__remove = false

    self.draw_order = args.update_order or 0
    self.update_order = args.draw_order or 0
    self.draw_order = self.draw_order + math.random()
    self.update_order = self.update_order + math.random()
end

function GC:set_draw_order(value)
    value = math.abs(value)
    self.draw_order = value + math.random()
end

function GC:set_update_order(value)
    value = math.abs(value)
    self.update_order = value + math.random()
end

function GC:load()

end

function GC:init()

end

function GC:finish()

end

function GC:update(dt)
    return false
end

function GC:draw()
    return false
end

return GC
