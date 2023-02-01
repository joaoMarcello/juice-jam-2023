local Font = Pack.Font
local Affectable = Pack.Affectable
local Utils = Pack.Utils

---@enum Game.GUI.Timer.Events
local Events = {
    timeEnd = 1,
    timeWarning = 2,
    redTimeWarning = 3,
    timeDown = 4
}
---@alias Game.GUI.Timer.EventNames "timeEnd"|"timeWarning"|"redTimeWarning"|"timeDown"

---@param self Game.GUI.Timer
---@param type_ Game.GUI.Timer.EventNames
local function dispatch_event(self, type_)
    local evt = self.events and self.events[type_]
    local r = evt and evt.action(evt.args)
end

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
    self.time = args.init_time or 161
    self.time_init = self.time
    self.speed = 0.5
    self.acumulator = 0.0
    self.time_warning = 50

    self.radius = args.radius or (36)
    local l, t, r, b = Game.camera:get_viewport_in_world_coord()
    self.x = args.x or (r - self.radius - 32)
    self.y = args.y or (t + self.radius + 20)

    self:set_color2(0.2, 0.2, 0.2, 1)
    self.actives_eff = {}
end

function Timer:get_time()
    return self.time
end

function Timer:on_evt(name, action, args)
    local evt_type = Events[name]
    if not evt_type then return end

    self.events = self.events or {}

    self.events[evt_type] = {
        type = evt_type,
        action = action,
        args = args
    }
end

function Timer:pulse(cycles, reset)
    if self.time <= 0 then return end

    self.time_capture = self.time

    if self.actives_eff['pulse'] then
        if reset then
            self.actives_eff['pulse'].cycle_count = 0
        end
        return
    end
    -- self.actives_eff['pulse'] = self:apply_effect("pulse", { max_sequence = cycles, speed = 0.5, range = 0.1 })

    self.actives_eff['pulse'] = self:apply_effect("pulse", { max_sequence = cycles, speed = 0.5, range = 0.1 })

    self.actives_eff['pulse']:set_final_action(function()
        self.time_capture = nil
        self.actives_eff['pulse'] = false
    end)
end

function Timer:increment(value, reset_cycle)
    self.time = self.time + value
    self:pulse(3, reset_cycle)
    if self.time > self.time_warning then
        self.time_capture = self.time
    end
end

function Timer:decrement(value, reset_cycle)
    value = -math.abs(value)
    self:increment(value, reset_cycle)
    self.time = Utils:clamp(self.time, 0, math.huge)
    if self.time == 0 then self:kill_player() end
end

function Timer:kill_player()
    dispatch_event(self, "timeEnd")

    if self.actives_eff["pulse"] then
        self.actives_eff["pulse"].__remove = true
    end

    self.game:get_player():kill()
end

function Timer:update(dt)
    Affectable.update(self, dt)

    if self.game:get_player():is_dead() then return end

    self.acumulator = self.acumulator + dt
    if self.acumulator >= self.speed and self.time > 0 then
        self.acumulator = self.acumulator - self.speed

        self.time = Utils:clamp(self.time - 1, 0, math.huge)

        if self.time == 0 then
            self:kill_player()
        else
            dispatch_event(self, "timeDown")
        end
    end

    local risk_time = 15

    if (self.time % 50 == 0 or self.time == self.time_warning
        or self.time == risk_time)
        and not self.actives_eff["pulse"]
        and self.time ~= self.time_init
    then

        if self.time == self.time_warning then
            dispatch_event(self, "redTimeWarning")
        elseif self.time > risk_time then
            dispatch_event(self, "timeWarning")
        end

        self:pulse(self.time > risk_time and 5 or 2)
        if self.time <= risk_time then self.time_capture = nil end
    end

    -- if self.time_capture and self.time_capture > risk_time then
    --     --self.time_capture = nil
    -- end
end

function Timer:draw_number(color, offset)
    color = color or "<color, 1, 1, 1>"
    offset = offset or 0

    Font.current:push()
    Font.current:set_font_size(25)

    local time = self.time_capture or self.time

    local obj = Font:get_phrase(color .. time,
        self.x, self.y, "left",
        math.huge
    )
    local w = obj:width()
    obj:draw(self.x - w * 0.5 + offset - 1, self.y - Font.current.__font_size * 0.5 + offset - 1, "left")
    Font.current:pop()
end

function Timer:draw_circle()
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.radius)
end

function Timer:draw()
    self:draw_circle()

    if self.time > self.time_warning then
        Affectable.draw(self, self.draw_number, "<color, 0, 0, 0>", 1)
        Affectable.draw(self, self.draw_number, "<color, 1, 1, 0>")
    else
        Affectable.draw(self, self.draw_number, "<color, 0, 0, 0>", 1)
        Affectable.draw(self, self.draw_number, "<color, 1, 0.1, 0.1>")
    end
end

return Timer
