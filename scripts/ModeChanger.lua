local Utils = Pack.Utils
local Affectable = Pack.Affectable
local GC = require "/scripts/bodyComponent"

---@type love.Image|nil
local img

---@type love.Image|nil
local img_arrow

---@enum Game.Component.ModeChanger.Modes
local Modes = {
    fixed = 1,
    dynamic = 2
}

---@class Game.Component.ModeChanger: BodyComponent
local Changer = setmetatable({}, GC)
Changer.__index = Changer
Changer.Modes = Modes

---@param game GameState.Game
---@return Game.Component.ModeChanger
function Changer:new(game, world, args)
    args = args or {}
    args.type = "dynamic"
    args.x = args.x or (32 * 8)
    args.y = args.y or (32 * 6)
    args.w = 32
    args.h = 32
    args.mode = (args.mode and Modes[args.mode]) or Modes.fixed
    args.mode_type = args.mode_type or (game:get_player().Modes.dash)

    local obj = GC:new(game, world, args)
    setmetatable(obj, self)
    Changer.__constructor__(obj, game, args)
    return obj
end

---@param game GameState.Game
function Changer:__constructor__(game, args)
    self.game = game

    local modes = game:get_player().Modes

    ---@type Game.Player.Modes
    self.mode_type = args.mode_type or modes.normal

    self.__colors = {
        [modes.normal] = Utils:get_rgba(89 / 255, 89 / 255, 89 / 255, 1),
        [modes.jump] = Utils:get_rgba(212 / 255, 108 / 255, 129 / 255, 1),
        [modes.jump_ex] = Utils:get_rgba(212 / 255, 108 / 255, 129 / 255, 1),
        [modes.dash] = Utils:get_rgba(130 / 255, 108 / 255, 212 / 255, 1),
        [modes.dash_ex] = Utils:get_rgba(130 / 255, 108 / 255, 212 / 255, 1),
        [modes.extreme] = Utils:get_rgba(212 / 255, 111 / 255, 68 / 255, 1),
    }

    self.draw_order = -1

    self:set_mode(args.mode)

    self.ox = self.w / 2
    self.oy = self.h / 2

    self.time_respawn = 0.0

    self.icon = Pack.Anima:new({ img = img or '' })
    self.icon:set_color(self.__colors[self.mode_type])
    self.icon:apply_effect("pulse", { speed = 0.6, range = 0.07 })
    if self.mode_type == modes.dash_ex
        or self.mode_type == modes.jump_ex
    then
        self.icon:apply_effect("flash", { speed = 0.3,
            color = Utils:get_rgba(1, 1, 0, 1),
            max = 0.5
        })
    end

    self.arrow = Pack.Anima:new { img = img_arrow or '' }
    self.arrow:apply_effect("pulse", { speed = 0.6, range = 0.07 })
    self.arrow:set_color2(nil, nil, nil, 0.6)
end

function Changer:load()
    img = img or love.graphics.newImage('/data/aseprite/mode_changer.png')
    img:setFilter("linear", "linear")

    img_arrow = img_arrow or love.graphics.newImage('/data/aseprite/mode_changer_arrow.png')
    img_arrow:setFilter("nearest", "nearest")
end

function Changer:init()
    self.time_respawn = 0.0

    if self.eff_popout then
        self.eff_popout:restaure_object()
        self.eff_popout.__remove = true
        self.eff_popout = nil
    end

    self.__effect_manager:clear()
    self:set_visible(true)
    local popin = self:apply_effect("popin", { speed = 0.3, duration = 0.3 })
    popin:set_final_action(function()
        popin.__remove = true
    end)
end

function Changer:finish()
    local r = img and img:release()
    img = nil
end

function Changer:set_mode(mode)
    mode = mode or Modes.fixed
    if mode == Modes.fixed then
        self.body.allowed_gravity = false
    else
        self.body.allowed_gravity = true
    end
    self.mode = mode
end

function Changer:update(dt)
    Affectable.update(self, dt)
    self.icon:update(dt)
    self.arrow:update(dt)

    local player = self.game:get_player()

    if self.time_respawn > 0 then
        self.time_respawn = self.time_respawn - dt
        if self.time_respawn <= 0
        -- and player.mode ~= self.mode_type
        then
            self.time_respawn = 0.0
            self:init()
        end
    end


    if self.body:check_collision(player.body:rect())
        and self.mode_type ~= player.mode
        and self.time_respawn == 0.0
        and not player:is_dead()
    then
        if self.eff_popout then self.eff_popout.__remove = true end
        self.eff_popout = self:apply_effect("popout", { speed = 0.3 })

        self.time_respawn = 1.5

        player:set_mode(self.mode_type)
        if player.body.speed_y > 0 then
            player.body.speed_y = player.body.speed_y * 0.3
        end
        self.game:pause(0.3, function(dt)
            self.game:game_get_displayHP().displayMode:update(dt)
        end)
    end
end

function Changer:my_draw()
    self.icon:draw(self.x + self.ox, self.y + self.oy)
    self.arrow:draw(self.x + self.ox, self.y + self.oy)
end

function Changer:draw()
    Affectable.draw(self, self.my_draw)
    love.graphics.setShader()
end

return Changer
