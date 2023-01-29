local Pack = _G.Pack
local Font = Pack.Font
local Physics = Pack.Physics

local Player = require "/scripts/player"
local Timer = require "/scripts/timer"

---@class GameState.Game: JM.Scene
local Game = Pack.Scene:new(nil, nil, nil, nil, 32 * 24, 32 * 14)

--=========================================================================
---@type Game.Player
local player

---@type JM.Physics.World
local world

---@type table
local rects

---@type table
local components

local components_gui

---@type Game.GUI.Timer
local timer
--=========================================================================

Game:implements({
    load = function()
        rects = {
            { 0, 32 * 12, 32 * 40, 32 * 2 },
            { 0, -32 * 10, 1, 32 * 40 },
            { 32 * 20, 32 * 4, 32 * 2, 32 * 20 }
        }

        world = Physics:newWorld()

        player = Player:new(Game, world, {
            x = 32 * 3,
            y = 32 * 4,
            w = 28,
            h = 58
        })

        for _, r in ipairs(rects) do
            local x, y, w, h = unpack(r)
            Physics:newBody(world, x, y, w, h, "static")
        end
    end,

    init = function()
        timer = Timer:new(Game)
        components = {}
        components_gui = {}

        table.insert(components, player)
        table.insert(components_gui, timer)
    end,

    keypressed = function(key)
        if key == "o" then
            Game.camera:toggle_grid()
            Game.camera:toggle_debug()
            Game.camera:toggle_world_bounds()
        end
        player:key_pressed(key)
    end,

    update = function(dt)
        world:update(dt)

        for i = 1, #components_gui do
            local r = components_gui[i].update and components_gui[i]:update(dt)
        end

        for i = 1, #components do
            local r = components[i].update and components[i]:update(dt)
        end

        Game.camera:follow(player:get_cx(), player:get_cy(), "player")
    end,

    layers = {
        {
            name = "main",

            draw = function(self, camera)
                world:draw()

                for i = 1, #components do
                    local r = components[i].draw and components[i]:draw()
                end

                Font:print(tostring(world.bodies_number), 32 * 3, 32 * 3)
            end
        },

        {
            draw = function(self, camera)
                for i = 1, #components_gui do
                    local r = components_gui[i].draw
                        and components_gui[i]:draw()
                end

                -- Showing the Time End message
                if timer:get_time() <= 0 then
                    Font.current:push()
                    Font.current:set_font_size(32)

                    local obj = Font:get_phrase("<effect=scream>RUN OUT\nOF TIME!", 0, 0, "left", math.huge)
                    local l, t, r, b =
                    Game.camera:get_viewport_in_world_coord()

                    local w, h = r - l - Game.camera.x, b - t - Game.camera.y

                    local obj_w = obj:width()
                    obj:draw(l + w / 2 - obj_w / 2, t + h * 0.3, "left")

                    Font.current:pop()
                end
            end,
            factor_x = -1,
            factor_y = -1,
            name = "GUI"
        }
    }
})

return Game
