local Font = Pack.Font
local Affectable = Pack.Affectable
local Utils = Pack.Utils

---@class Game.GUI.Timer: JM.Template.Affectable
local Timer = setmetatable({}, Affectable)
Timer.__index = Timer

---@param Game GameState.Game
---@param args any
function Timer:new(Game, args)
    args = args or {}
    local obj = Affectable:new()
    setmetatable(obj, self)
    Timer.__constructor__(obj, Game, args)
    return obj
end

---@param Game GameState.Game
function Timer:__constructor__(Game, args)
    self.game = Game
    self.time = args.init_time or 60
    self.speed = 0.5
    self.acumulator = 0.0
    self.time_warning = 50

    self.radius = args.radius or (32)
    local l, t, r, b = Game.camera:get_viewport_in_world_coord()
    self.x = args.x or (r - self.radius - 20)
    self.y = args.y or (t + self.radius + 20)
    self:set_color2(0.2, 0.2, 0.2, 0.8)
    self.actives_eff = {}
end

function Timer:update(dt)
    Affectable.update(self, dt)

    self.acumulator = self.acumulator + dt
    if self.acumulator >= self.speed then
        self.acumulator = self.acumulator - self.speed
        self.time = Utils:clamp(self.time - 1, 0, math.huge)
    end

    if self.time == self.time_warning
        and not self.actives_eff["pulse"]
    then
        self.actives_eff['pulse'] = self:apply_effect("pulse", { max_sequence = 5, speed = 0.5 })
        self.actives_eff['pulse']:set_final_action(function() self.actives_eff['pulse'] = false end)
    end
end

function Timer:draw_number(color, offset)
    color = color or "<color, 1, 1, 1>"
    offset = offset or 0

    Font.current:push()
    Font.current:set_font_size(22)

    local obj = Font:get_phrase(color .. self.time,
        self.x, self.y, "left",
        math.huge
    )
    local w = obj:width()
    obj:draw(self.x - w * 0.5 + offset - 1, self.y - 12 + offset, "left")
    Font.current:pop()
end

function Timer:draw()
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.radius)

    Affectable.draw(self, self.draw_number, "<color, 0.6, 0.6, 0.6>", 1)
    Affectable.draw(self, self.draw_number)

    Font:print(self.actives_eff['pulse'], 300, 100)
end

return Timer
