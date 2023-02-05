local Pack = _G.Pack
local Font = Pack.Font
local Physics = Pack.Physics

local TileMap = require "JM_love2d_package.modules.tile.tile_map"

local Advice = require "scripts.advice"

local Player = require "scripts.player"
local Timer = require "scripts.timer"
local DisplayHP = require "scripts.displayHP"
local ModeChanger = require "scripts.modeChanger"
local Reseter = require "scripts.reseter"
local Spike = require "scripts.spike"
local AdviceBox = require "scripts.adviceBox"
local Refill = require "scripts.refill"
local PillRestaure = require "scripts.pillRestaure"

local PeekaBoo = require "scripts.enemy.peekaboo"
local MiddleBoo = require "scripts.enemy.middleBoo"
local WeightBoo = require "scripts.enemy.weightBoo"
local Bullet = require "scripts.enemy.bullet"

---@class GameState.Game: JM.Scene, GameState
local Game = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT,
    {
        top = 0,
        left = 0,
        right = 32 * 80 * 4,
        bottom = 32 * 12
    })
Game.camera:toggle_debug()
Game.camera:toggle_grid()
Game.camera:toggle_world_bounds()
Game.camera.border_color = { 0, 0, 0, 0 }
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

---@type JM.TileMap
local map

---@type Game.Component.Advice|nil
local advice

local sort_update = function(a, b) return a.update_order > b.update_order end
local sort_draw = function(a, b) return a.draw_order < b.draw_order end
--=========================================================================

-- -@param gc GameComponent|BodyComponent
function Game:game_add_component(gc)
    table.insert(components, gc)
    return gc
end

function Game:game_remove_component(index)
    ---@type JM.Physics.Body
    local body = components[index].body
    if body then
        body.__remove = true
    end
    return table.remove(components, index)
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

function Game:game_is_not_advicing()
    return not advice
end

function Game:game_add_advice(text, extra_update)
    if text then
        advice = Advice:new(Game, text, extra_update)
    else
        advice = nil
    end
end

local checkpoint
function Game:game_checkpoint(x, y, bottom)
    if checkpoint and checkpoint.x == x
        and checkpoint.y == y and checkpoint.bottom == bottom
    then
        return false
    end

    checkpoint = { x = x, y = y, bottom = bottom }
    return true
end

Game:game_checkpoint(32 * 2, 32 * 11, 32 * 11 + 32)
--=========================================================================


local player_pos = 0

Game:implements({
    load = function()
        rects = {
            -- { 0, 32 * 11, 32 * 40, 32 * 2 },
            { 0, -32 * 10, 1, 32 * 40 },
            { 0, -64, 32 * 80 * 4, 32 },
            { 32 * 4 * 80, 0, 32, 32 * 12 },
            -- { 32 * 20, 32 * 4, 32 * 2, 32 * 10 },
            -- { 32 * 10, 32 * 7, 32 * 5, 32 }
        }

        local x, y = 0, 32 * 11
        local w = 32 * 4
        local h = 32 * 2
        for i = 0, 80 do
            if i ~= 23 and i ~= 24 and i ~= 25 and i ~= 26 and i ~= 29 and i ~= 30 and i ~= 31 and i ~= 32 and i ~= 33
                and i ~= 34
                and i ~= 38 and i ~= 52 and i ~= 53 and i ~= 54 and i ~= 55 and i ~= 56
            then
                table.insert(rects, { i * w, y, w, h })
            end
        end

        local one = 32
        local two = 32 * 2
        local three = 32 * 3
        local four = 32 * 4
        local five = 32 * 5
        local six = 32 * 6
        local seven = 32 * 7
        local eight = 32 * 8

        table.insert(rects, { 2 * w + two, y - one, two, one })
        table.insert(rects, { (5 * w) + two, (y - four), two, four })
        table.insert(rects, { (9 * w) + two, (y - four), two, four })

        table.insert(rects, { (13 * w) + two, (y - four), two, four })
        table.insert(rects, { (19 * w), (y - three * 4), four, four * 2 })

        table.insert(rects, { (27 * w) - three, (y - three), four, four })
        table.insert(rects, { (35 * w), (y - three), three, four })

        table.insert(rects, { (38 * w) - one, (y - 32 * 7), one, 32 * 7 })
        table.insert(rects, { (39 * w), (y - 32 * 11), one, 32 * 8 })

        table.insert(rects, { (45 * w), (y - four), four, 32 })
        table.insert(rects, { (48 * w) - one, (y - six), two, six })
        table.insert(rects, { (48 * w) - one, (y - 32 * 11), six, two })

        table.insert(rects, { (51 * w) + two, (y - six), two, six })
        table.insert(rects, { (53 * w), (y - six), six, three })
        -- table.insert(rects, { (54 * w) + six, (y - six), one, one })
        table.insert(rects, { (56 * w) + two, (y - three), four, four })

        table.insert(rects, { (61 * w) - one, (y - five), six, one })



        player_pos = 77 * w
        -- table.insert(rects, { 0, y, w, h })
        -- table.insert(rects, { 3 * w, y, w, h })


        Player:load()
        DisplayHP:load()
        ModeChanger:load()
        Reseter:load()
        Spike:load()
        PeekaBoo:load()
        MiddleBoo:load()
        WeightBoo:load()
        Bullet:load()

        Advice:load()
        AdviceBox:load()
        Refill:load()
        PillRestaure:load()

        Game:game_checkpoint(32 * 2, 32 * 11, 32 * 11 + 32)

        -- map = TileMap:new('data/my_map_data.lua', '/data/tileset_01.png', 32)
    end,

    finish = function()
        Player:finish()
        DisplayHP:finish()
        ModeChanger:finish()
        Reseter:finish()
        Spike:finish()
        PeekaBoo:finish()
        MiddleBoo:finish()
        WeightBoo:finish()
        Bullet:finish()

        Advice:finish()
        Refill:finish()
        PillRestaure:finish()

        checkpoint = nil
    end,

    init = function()

        world = Physics:newWorld()
        player = Player:new(Game, world, {
            x = checkpoint.x,
            -- x = player_pos,
            y = checkpoint.y,
            bottom = checkpoint.bottom
        })

        -- player:set_mode(Player.Modes.extreme)

        Game.camera.x = checkpoint.x + player.w / 2 - Game.offset_x / Game.camera.desired_scale -
            Game.camera.focus_x / Game.camera.desired_scale

        -- Game.camera.x = player_pos + player.w / 2 - Game.offset_x / Game.camera.desired_scale -
        --     Game.camera.focus_x / Game.camera.desired_scale

        for _, r in ipairs(rects) do
            local x, y, w, h = unpack(r)
            Physics:newBody(world, x, y, w, h, "static")
        end

        timer = Timer:new(Game)
        displayHP = DisplayHP:new(Game, {})

        components = {}
        components_gui = {}

        Game:game_add_component(player)

        -- do
        --     Game:game_add_component(ModeChanger:new(Game, world, {}))
        --     Game:game_add_component(ModeChanger:new(Game, world, {
        --         x = 32 * 2,
        --         mode_type = Player.Modes.jump
        --     }))

        --     Game:game_add_component(ModeChanger:new(Game, world, {
        --         x = 32 * 18,
        --         mode_type = Player.Modes.jump_ex
        --     }))

        --     Game:game_add_component(ModeChanger:new(Game, world, {
        --         x = 32 * 24,
        --         mode_type = Player.Modes.dash_ex
        --     }))

        --     Game:game_add_component(ModeChanger:new(Game, world, {
        --         x = 32 * 50,
        --         mode_type = Player.Modes.extreme
        --     }))

        --     Game:game_add_component(ModeChanger:new(Game, world, {
        --         x = 32 * 30,
        --         mode_type = Player.Modes.normal
        --     }))

        --     Game:game_add_component(Reseter:new(Game, world, {
        --         x = 32 * 5,
        --         y = 32 * 6
        --     }))

        --     Game:game_add_component(Reseter:new(Game, world, {
        --         x = 32 * 16,
        --         y = 32 * 10,
        --         mode = Reseter.Types.dash
        --     }))
        -- end
        --=======================================================
        local x, y = 0, 32 * 11
        local w = 32 * 4
        local h = 32 * 2

        local one = 32
        local two = 32 * 2
        local three = 32 * 3
        local four = 32 * 4
        local five = 32 * 5
        local six = 32 * 6
        local seven = 32 * 7
        local eight = 32 * 8

        do
            Game:game_add_component(Spike:new(Game, world, {
                x = (9 * w) + one,
                y = y - four,
                len = 4,
                position = "wallRight"
            }))

            Game:game_add_component(Spike:new(Game, world, {
                x = (13 * w) + one,
                y = y - four,
                len = 4,
                position = "wallRight"
            }))

            Game:game_add_component(Spike:new(Game, world, {
                x = (13 * w) + two,
                y = y - five,
                len = 2,
                position = "ground"
            }))

            Game:game_add_component(Spike:new(Game, world, {
                x = (19 * w),
                y = y - four,
                len = 4,
                position = "ceil"
            }))

            Game:game_add_component(Spike:new(Game, world, {
                x = (38 * w),
                y = y - 32 * 6,
                len = 7,
                position = "wallLeft"
            }))

            Game:game_add_component(Spike:new(Game, world, {
                x = (39 * w) - one,
                y = y - 32 * 11,
                len = 4,
                position = "wallRight"
            }))

            Game:game_add_component(Spike:new(Game, world, {
                x = (39 * w) - one,
                y = y - 32 * 6,
                len = 3,
                position = "wallRight"
            }))

            Game:game_add_component(Spike:new(Game, world, {
                x = (53 * w) - one,
                y = y - six,
                len = 3,
                position = "wallRight"
            }))

            Game:game_add_component(Spike:new(Game, world, {
                x = (53 * w),
                y = 32 * 4,
                len = 6,
                position = "ground"
            }))

            Game:game_add_component(Spike:new(Game, world, {
                x = (53 * w),
                y = 32 * 8,
                len = 6,
                position = "ceil"
            }))

            Game:game_add_component(Spike:new(Game, world, {
                x = (56 * w) + one,
                y = 32 * 8,
                len = 4,
                position = "wallRight"
            }))

            Game:game_add_component(Spike:new(Game, world, {
                x = (63 * w),
                y = 32 * 10,
                len = 32 + 5,
                position = "ground"
            }))

        end
        --==========================================================
        do
            Game:game_add_component(AdviceBox:new(Game, world, {
                x = 32 * 5,
                y = y - four
            }))

            Game:game_add_component(AdviceBox:new(Game, world, {
                x = (6 * w) + three,
                y = y - four
            }))

            Game:game_add_component(AdviceBox:new(Game, world, {
                x = (10 * w) + three,
                y = y - four
            }))

            Game:game_add_component(AdviceBox:new(Game, world, {
                x = (14 * w) + three,
                y = y - four
            }))

            Game:game_add_component(AdviceBox:new(Game, world, {
                x = (18 * w),
                y = y - four
            }))

            Game:game_add_component(AdviceBox:new(Game, world, {
                x = (21 * w) - one,
                y = y - four
            }))

            Game:game_add_component(AdviceBox:new(Game, world, {
                x = (28 * w) - one,
                y = y - four
            }))

            Game:game_add_component(AdviceBox:new(Game, world, {
                x = (38 * w) - two,
                y = y - four
            }))

            Game:game_add_component(AdviceBox:new(Game, world, {
                x = (40 * w),
                y = y - four
            }))

            Game:game_add_component(AdviceBox:new(Game, world, {
                x = (47 * w) - two,
                y = y - four
            }))

            Game:game_add_component(AdviceBox:new(Game, world, {
                x = (57 * w) + five,
                y = y - four
            }))

            Game:game_add_component(AdviceBox:new(Game, world, {
                x = (78 * w) - two,
                y = y - four
            }))
        end
        --=========================================================
        do
            Game:game_add_component(PillRestaure:new(Game, world, {
                refill_type = PillRestaure.Types.pill_hp,
                bottom = 32 * 11,
                x = (16 * w)
            }))

            Game:game_add_component(PillRestaure:new(Game, world, {
                refill_type = PillRestaure.Types.pill_hp,
                bottom = 32 * 11,
                x = (36 * w) + two
            }))

            Game:game_add_component(PillRestaure:new(Game, world, {
                refill_type = PillRestaure.Types.pill_hp,
                bottom = 32 * 8,
                x = (56 * w) + three
            }))

            Game:game_add_component(PillRestaure:new(Game, world, {
                refill_type = PillRestaure.Types.none,
                bottom = 32 * 11,
                x = (49 * w) + three
            }))

            --===========================================================

            Game:game_add_component(PeekaBoo:new(Game, world, {
                x = (41 * w) + two,
                y = 32 * 11
            }))

            Game:game_add_component(WeightBoo:new(Game, world, {
                x = (48 * w) - one,
                bottom = 32 * 5
            }))

            Game:game_add_component(MiddleBoo:new(Game, world, {
                x = (51 * w),
                bottom = 32 * 11
            }))

            Game:game_add_component(MiddleBoo:new(Game, world, {
                x = (61 * w),
                bottom = 32 * 11
            }))

            Game:game_add_component(MiddleBoo:new(Game, world, {
                x = (62 * w) + three,
                bottom = 32 * 11
            }))

            -- Game:game_add_component(MiddleBoo:new(Game, world, {
            --     x = (63 * w) + three,
            --     bottom = 32 * 11
            -- }))

            Game:game_add_component(PeekaBoo:new(Game, world, {
                x = (62 * w),
                y = 32 * 10
            }))

            Game:game_add_component(WeightBoo:new(Game, world, {
                x = (61 * w) + two,
                bottom = 32 * 7
            }))
        end
        --================================================================

        Game:game_add_component(ModeChanger:new(Game, world, {
            x = (7 * w) + two,
            y = y - four,
            mode_type = Player.Modes.jump
        }))

        Game:game_add_component(ModeChanger:new(Game, world, {
            x = (11 * w) + two,
            y = y - four,
            mode_type = Player.Modes.jump_ex
        }))

        Game:game_add_component(ModeChanger:new(Game, world, {
            x = (19 * w) + two,
            y = y - two,
            mode_type = Player.Modes.normal
        }))

        Game:game_add_component(ModeChanger:new(Game, world, {
            x = (22 * w),
            y = y - four,
            mode_type = Player.Modes.dash
        }))

        Game:game_add_component(ModeChanger:new(Game, world, {
            x = (28 * w) + two,
            y = y - four,
            mode_type = Player.Modes.dash_ex
        }))

        Game:game_add_component(ModeChanger:new(Game, world, {
            x = (38 * w) - one,
            y = y - 32 * 9,
            mode_type = Player.Modes.dash
        }))

        Game:game_add_component(ModeChanger:new(Game, world, {
            x = (43 * w) - one,
            y = y - four,
            mode_type = Player.Modes.dash
        }))

        Game:game_add_component(ModeChanger:new(Game, world, {
            x = (52 * w) + one,
            y = y - four,
            mode_type = Player.Modes.dash
        }))

        Game:game_add_component(ModeChanger:new(Game, world, {
            x = (55 * w),
            y = y,
            mode_type = Player.Modes.jump_ex
        }))

        Game:game_add_component(ModeChanger:new(Game, world, {
            x = (58 * w) + four,
            y = y - four,
            mode_type = Player.Modes.extreme
        }))

        --===========================================================

        Game:game_add_component(Reseter:new(Game, world, {
            x = (32 * w),
            y = y - four,
            mode = Reseter.Types.dash
        }))

        Game:game_add_component(Reseter:new(Game, world, {
            x = (53 * w) + two,
            y = y - one,
            mode = Reseter.Types.dash
        }))

        Game:game_add_component(Reseter:new(Game, world, {
            x = (55 * w) + two,
            y = y - four,
            mode = Reseter.Types.jump
        }))

        table.insert(components_gui, timer)
        table.insert(components_gui, displayHP)
        table.insert(components_gui, displayPill)
    end,

    keypressed = function(key)
        if advice then
            advice:key_pressed(key)
            return
        end

        if key == "o" then
            Game.camera:toggle_grid()
            Game.camera:toggle_debug()
            Game.camera:toggle_world_bounds()
        end

        if key == "return" and not player:is_dead() then
            CHANGE_GAME_STATE(require 'scripts.gameState.pause', true, false, true, true, true)
        else
            player:key_pressed(key)
        end

    end,

    keyreleased = function(key)
        player:key_released(key)
    end,

    update = function(dt)
        if advice then
            advice:update(dt)
            return
        end

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

        if not player:is_dead() then
            if player.y > (32 * 12 + 20) then
                player:kill(true)
            end

            if player.body:check_collision(32 * 4 * 80 - 32, 0, 32, 32 * 12)
                and not Game.fadeout_time
            then
                Game:game_checkpoint(32 * 2, 32 * 11, 32 * 11 + 32)
                -- CHANGE_GAME_STATE(require 'scripts.gameState.menu_principal', true, false, false, false, false, false)
                Game:fadeout(nil, nil, nil,
                    nil,
                    function()
                        Game:init()
                        Game:game_checkpoint(32 * 2, 32 * 11, 32 * 11 + 32)

                        CHANGE_GAME_STATE(require 'scripts.gameState.menu_principal', true, false, false, false, false,
                            false)
                    end)
                return
            end
        end

        Game.camera:follow(player:get_cx(), player:get_cy(), "player")

        if player:is_dead() and player.body.speed_y == 0
            and not Game.fadeout_time
        then
            Game:fadeout(nil, nil, nil,
                nil,

                function()
                    RESTART(Game)
                end)
        end
    end,

    layers = {
        --================================================================
        --================================================================
        {
            name = "main",

            ---@param camera JM.Camera.Camera
            draw = function(self, camera)
                -- map:draw(camera)

                for i = 1, world.bodies_number do
                    ---@type JM.Physics.Body|JM.Physics.Slope
                    local obj = world.bodies[i]

                    if obj and camera:rect_is_on_view(obj:rect()) then
                        local r = obj.type == 2 and obj.draw and obj:draw()
                    end
                end

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
                    if advice then
                        break
                    end
                    local r = components_gui[i].draw
                        and components_gui[i]:draw()
                end

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

                if advice then advice:draw() end
            end
        }
        --================================================================
        --================================================================

    }
})

return Game
