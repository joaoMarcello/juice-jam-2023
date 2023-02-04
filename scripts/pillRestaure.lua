local Utils = Pack.Utils
local Affectable = Pack.Affectable
local GC = require "scripts.bodyComponent"

---@type love.Image|nil
local img

local Type = {
    pill_atk = 1,
    pill_def = 2,
    pill_hp = 3,
    pill_time = 4,
    all = 5
}

local TypeString = {
    [Type.pill_atk] = "pill_atk",
    [Type.pill_def] = "pill_def",
    [Type.pill_hp] = "pill_hp",
    [Type.pill_time] = "pill_time"
}

---@class Game.Component.PillRestaure: BodyComponent
local Refill = setmetatable({}, GC)
Refill.__index = Refill
Refill.Types = Type
Refill.TypesString = TypeString

function Refill:new(game, world, args)
    args = args or {}
    args.x = args.x or (32 * 10)
    args.y = args.y or (32 * 9)
    args.w = 70
    args.h = 18
    args.type = "static"
    args.y = args.bottom and (args.bottom - args.h) or args.y
    args.mode = args.mode or args.refill_type or Type.pill_time

    local obj = GC:new(game, world, args)
    setmetatable(obj, self)
    Refill.__constructor__(obj, game, args)
    return obj
end

function Refill:__constructor__(game, args)
    self.x = args.x
    self.y = args.y
    self.w = args.w
    self.h = args.h
    self.refill_type = args.mode
    self.value = 20

    self.__colors = {
        { 1, 0, 0 },
        { 0, 0, 1 },
        { 0, 1, 0 },
        { 1, 1, 0 },
        { 1, 1, 1 }
    }

    self:set_draw_order(15)

    self.time_catch = 1.0

    self.anima = Pack.Anima:new { img = img or '' }
end

function Refill:load()
    img = img or love.graphics.newImage('/data/animations/pill-restaure.png')
end

function Refill:init()

end

function Refill:finish()
    local r
    r = img and img:release()
    img = nil
end

function Refill:update(dt)
    GC.update(self, dt)

    if not self.__remove and self.time_catch <= 0 then
        local player = self.game:get_player()
        local body = player.body

        if body:check_collision(self.body:rect()) then
            self.__remove = true

            if self.refill_type == Type.all then
                player:set_attribute("pill_atk", "add",
                    player.attr_pill_atk_max)

                player:set_attribute("pill_def", "add",
                    player.attr_pill_def_max)

                player:set_attribute("pill_hp", "add",
                    player.attr_pill_hp_max)

                player:set_attribute("pill_time", "add",
                    player.attr_pill_time_max)

            else
                player:set_attribute(TypeString[self.refill_type],
                    "add",
                    self.value
                )
            end
        end
    end

    self.time_catch = self.time_catch - dt
end

function Refill:my_draw()
    -- love.graphics.setColor(self.__colors[self.refill_type])
    -- love.graphics.rectangle("fill", self.body:rect())
    self.anima:draw_rec(self.body:rect())
end

function Refill:draw()
    GC.draw(self, self.my_draw)
end

return Refill
