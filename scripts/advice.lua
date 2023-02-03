local TextBox = require "JM_love2d_package.modules.gui.textBox"

---@type love.Image|nil
local img

---@type love.Image|nil
local img_arrow

---@class Game.Component.Advice
local Advice = {}
Advice.__index = Advice

-- Width = 12 * 32 = 384
--Height = 32*5 = 160

function Advice:new(game, text, extra_update)
    text = text or
        "um dois tres testando. um dois tres\n estou com fome\nestou cansado\n eu quero dormir\neu quero vencer."
    local obj = setmetatable({}, self)
    Advice.__constructor__(obj, game, text, extra_update)
    return obj
end

---@param game GameState.Game
function Advice:__constructor__(game, text, extra_update)
    self.game = game
    self.extra_update = extra_update

    self.textbox = TextBox:new(text, Pack.Font.current, 32 * 4, 32 * 3, 32 * 10)

    self.is_locked = true

    self.w = 384
    self.h = 160
    self.x = self.textbox.x + self.textbox.w / 2 - self.w / 2
    self.y = self.textbox.y + self.textbox.h / 2 - self.h / 2

    self.icon = Pack.Anima:new({ img = img or '' })

    self.eff_popin = self.icon:apply_effect("popin", { speed = 0.3, delay = 0.5 })
    -- self.eff_popin.__scale.x = 0.5

    self.time_delay = 0.2

    self.eff_popin:set_final_action(function()
        self.is_locked = false
    end)

    self.arrow = Pack.Anima:new({ img = img_arrow or '' })
    self.arrow:set_color({ 0.2, 0.2, 0.3, 1 })
    self.arrow:set_rotation(math.pi)
    self.arrow:apply_effect("float", { speed = 0.6, range = 3 })

    self.arrow_w = img_arrow and img_arrow:getWidth()
end

function Advice:load()
    img = img or love.graphics.newImage('/data/aseprite/advice.png')
    img:setFilter("linear", "linear")

    img_arrow = img_arrow or love.graphics.newImage('/data/aseprite/mode_changer_arrow.png')
    img_arrow:setFilter("linear", "linear")
end

function Advice:finish()
    local r = img and img:release()
    img = nil

    r = img_arrow and img_arrow:release()
    img = nil
end

function Advice:key_pressed(key)
    if self.is_locked or self.time_delay > 0 then return end

    if key == "space" then
        local r = self.textbox:go_to_next_screen()

        if not r and self.textbox:screen_is_finished() then
            self.game:game_add_advice()
        end
    end
end

function Advice:update(dt)
    self.icon:update(dt)
    self.arrow:update(dt)
    local r = self.extra_update and self.extra_update(dt)

    if self.is_locked then return end

    if self.time_delay > 0 then
        self.time_delay = self.time_delay - dt
        return
    end

    self.textbox:update(dt)
end

function Advice:draw()
    self.icon:draw(self.textbox.x + self.textbox.w / 2, self.textbox.y + self.textbox.h / 2)

    if self.is_locked then return end
    self.textbox:draw()

    if self.textbox:screen_is_finished() then
        self.arrow:draw(self.x + self.w - self.arrow_w / 2 - 5, self.y + self.h - self.arrow_w / 2 - 5)
    end
end

return Advice
