local Utils = Pack.Utils
local Affectable = Pack.Affectable
local GC = require "scripts.bodyComponent"

---@type love.Image|nil
local img

---@type love.Image|nil
local img_flash

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
    [Type.pill_time] = "pill_time",
    [Type.all] = ""
}

---@class Game.Component.PillRestaure: BodyComponent
local Restaure = setmetatable({}, GC)
Restaure.__index = Restaure
Restaure.Types = Type
Restaure.TypesString = TypeString

function Restaure:new(game, world, args)
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
    Restaure.__constructor__(obj, game, args)
    return obj
end

function Restaure:__constructor__(game, args)
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

    self.anima = Pack.Anima:new { img = img or '' }
    self.flash = Pack.Anima:new { img = img_flash or '' }

    local r, g, b = unpack(self.__colors[self.refill_type])
    local a = 0.2
    self.flash:set_color2(r, g, b, 0.3)
end

function Restaure:load()
    img = img or love.graphics.newImage('/data/animations/pill-restaure.png')
    img_flash = img_flash or love.graphics.newImage('/data/animations/pill-restaure-flash.png')
end

function Restaure:init()

end

function Restaure:finish()
    local r
    r = img and img:release()
    img = nil
end

function Restaure:update(dt)
    GC.update(self, dt)
    local player = self.game:get_player()

    local attr
    attr = player["attr_" .. TypeString[self.refill_type]]
    local attr_max = player["attr_" .. TypeString[self.refill_type] .. "_max"]
    local x, y, w, h = self.body:rect()

    if (attr and attr_max and attr < attr_max) or
        (not attr and self.refill_type == Type.all)
    then
        local body = player.body

        if player.body:check_collision(x + 2, y - 1, w - 4, h) then


            if self.refill_type == Type.all then
                player:set_attribute("pill_atk", "add",
                    player.attr_pill_atk_max)

                player:set_attribute("pill_def", "add",
                    player.attr_pill_def_max)

                player:set_attribute("pill_hp", "add",
                    player.attr_pill_hp_max)

                -- player:set_attribute("pill_time", "add",
                --     player.attr_pill_time_max)

                player:pulse()
            else
                player:set_attribute(TypeString[self.refill_type],
                    "add",
                    self.value
                )

                player:pulse()
            end
        end
    end

    if player.body:check_collision(x, y - 3, w, h)
        and not player:is_dead()
    then
        self.game:game_checkpoint(self.body.x + self.body.w / 2 - player.w / 2, self.body.y, self.body.y)
    end

end

function Restaure:my_draw()
    -- love.graphics.setColor(self.__colors[self.refill_type])
    -- love.graphics.rectangle("fill", self.body:rect())

    self.flash:draw_rec(self.body:rect())
    self.anima:draw_rec(self.body:rect())

    local player = self.game:get_player()
    local x, y, w, h = self.body:rect()
    if player.body:check_collision(x - 32 * 2, y + h - 32 * 5, w + 32 * 4, 32 * 5) then
        player:draw()
    end
end

function Restaure:draw()
    GC.draw(self, self.my_draw)
end

return Restaure
