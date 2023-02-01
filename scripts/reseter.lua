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
    args.type = "dynamic"
    args.mode = args.mode or Types.dash

    local obj = GC:new(game, world, args)
    setmetatable(obj, self)
    Reset.__constructor__(obj, game, args)
    return obj
end

---@param game GameState.Game
function Reset:__constructor__(game, args)
    self.__colors = {
        [Types.jump] = Utils:get_rgba2(212, 108, 129),
        ["jump_used"] = Utils:get_rgba2(212 - 35, 108 - 35, 129 - 35),
        [Types.dash] = Utils:get_rgba2(130, 108, 212),
        ["dash_used"] = Utils:get_rgba2(130 - 35, 108 - 35, 212 - 35)
    }

    self.icon = Pack.Anima:new({ img = img or '' })
    self.icon:apply_effect("pulse", { speed = 0.5, range = 0.07 })

    self.ox = self.w / 2
    self.oy = self.h / 2

    self.time_reset = 1.0
    self.time = 0.0

    self.body.allowed_gravity = false
    self.draw_order = -1

    self.mode = args.mode
    self.used_color = self.mode == Types.jump and self.__colors['jump_used'] or
        self.__colors['dash_used']
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
    self.icon:update(dt)

    local player = self.game:get_player()

    if self.time == 0.0 then
        if self.body:check_collision(player.body:rect()) then
            self.icon:set_color(self.used_color)
            self.time = self.time_reset
        else
            self.icon:set_color2(self.__colors[self.mode])
        end

    else
        self.time = Utils:clamp(self.time - dt, 0, self.time_reset)
        -- if self.time <= 0 then self.time = 0.0 end
    end
end

function Reset:draw()
    self.icon:draw(self.x + self.ox, self.y + self.oy)
end

return Reset
