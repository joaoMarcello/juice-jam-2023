local Pack = _G.Pack
local Font = Pack.Font
local Physics = Pack.Physics

local Player = require "/scripts/player"
local Timer = require "/scripts/timer"
local DisplayHP = require "/scripts/displayHP"
local ModeChanger = require "scripts.ModeChanger"


---@class GameState.Game: JM.Scene
local Game = Pack.Scene:new(nil, nil, nil, nil, 32 * 20, 32 * 13)
Game.camera:toggle_debug()
Game.camera:toggle_grid()
Game.camera:toggle_world_bounds()
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

---@type Game.GUI.DisplayHP
local displayHP

---@type Game.GUI.DisplayPill
local displayPill

local sort_update = function(a, b) return a.update_order > b.update_order end
local sort_draw = function(a, b) return a.draw_order < b.draw_order end
--=========================================================================

---@param gc GameComponent
function Game:game_add_component(gc)
    table.insert(components, gc)
end

function Game:game_remove_component(index)
    ---@type JM.Physics.Body
    local body = components[index].body
    if body then
        body.__remove = true
    end
    table.remove(components, index)
end

function Game:game_get_timer()
    return timer
end

function Game:get_player()
    return player
end

function Game:game_get_displayHP()
    return displayHP
end

--=========================================================================

Game:implements({
    load = function()
        rects = {
            { 0, 32 * 12, 32 * 40, 32 * 2 },
            { 0, -32 * 10, 1, 32 * 40 },
            { 32 * 20, 32 * 4, 32 * 2, 32 * 10 },
            { 32 * 10, 32 * 7, 32 * 5, 32 }
        }

        world = Physics:newWorld()

        Player:load()
        DisplayHP:load()

        player = Player:new(Game, world, {})

        for _, r in ipairs(rects) do
            local x, y, w, h = unpack(r)
            Physics:newBody(world, x, y, w, h, "static")
        end

    end,

    init = function()
        timer = Timer:new(Game)
        displayHP = DisplayHP:new(Game, {})
        displayHP:load()

        components = {}
        components_gui = {}

        Game:game_add_component(player)
        Game:game_add_component(ModeChanger:new(Game, world, {}))
        Game:game_add_component(ModeChanger:new(Game, world, {
            x = 32 * 2,
            mode_type = Player.Modes.jump
        }))

        Game:game_add_component(ModeChanger:new(Game, world, {
            x = 32 * 18,
            mode_type = Player.Modes.jump_ex
        }))

        Game:game_add_component(ModeChanger:new(Game, world, {
            x = 32 * 24,
            mode_type = Player.Modes.dash_ex
        }))

        Game:game_add_component(ModeChanger:new(Game, world, {
            x = 32 * 26,
            mode_type = Player.Modes.extreme
        }))

        table.insert(components_gui, timer)
        table.insert(components_gui, displayHP)
        table.insert(components_gui, displayPill)
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

        table.sort(components, sort_update)
        for i = #components, 1, -1 do
            ---@type GameComponent
            local gc = components[i]

            local r = gc.update and gc.is_enable
                and not gc.__remove and gc:update(dt)

            if gc.__remove then
                Game:game_remove_component(i)
            end
        end

        Game.camera:follow(player:get_cx(), player:get_cy(), "player")
    end,

    layers = {
        --================================================================
        --================================================================
        {
            name = "main",

            draw = function(self, camera)
                world:draw()

                table.sort(components, sort_draw)
                for i = 1, #components do
                    local r = components[i].draw and components[i]:draw()
                end

                -- Font:print(tostring(world.bodies_number), 32 * 3, 32 * 3)
            end
        },
        --================================================================
        --================================================================
        {
            name = "GUI",
            factor_x = -1,
            factor_y = -1,

            draw = function(self, camera)
                local left, top, right, bottom =
                Game.camera:get_viewport_in_world_coord()

                local width = right - left - Game.camera.x
                local height = bottom - top - Game.camera.y

                for i = 1, #components_gui do
                    local r = components_gui[i].draw
                        and components_gui[i]:draw()
                end

                local font = Font.current
                -- font:print("HP: " .. player.attr_hp .. "\nDEF: " .. player.attr_def .. "\nATK: " .. player.attr_atk,
                --     left - Game.camera.x + 45,
                --     top + height * 0.3 - Game.camera.y)

                -- Showing the Time End message
                if timer:get_time() <= 0 then
                    Font.current:push()
                    Font.current:set_font_size(32)
                    local obj = Font:get_phrase("<color, 1, 1, 0><effect=scream>TIME iS UP!", 0, 0, "left",
                        math.huge)

                    local obj_w = obj:width()
                    obj:draw(left + width / 2 - obj_w / 2, top + height * 0.3, "left")

                    Font.current:pop()

                elseif player:is_dead() then
                    Font.current:push()
                    Font.current:set_font_size(32)
                    local obj = Font:get_phrase("<color, 1, 0, 0><effect=scream>YOU ARE DEAD!", 0, 0, "left",
                        math.huge)

                    local obj_w = obj:width()
                    obj:draw(left + width / 2 - obj_w / 2, top + height * 0.3, "left")

                    Font.current:pop()
                end
            end
        }
        --================================================================
        --================================================================

    }
})

return Game
