local Pack = _G.Pack
local Player = require "/scripts/player"
local Font = Pack.Font
local Game = Pack.Scene:new(nil, nil, nil, nil, 32 * 24, 32 * 14)

--=========================================================================
---@type Game.Player
local player

---@type JM.Physics.World
local world

local rects = {
    { 0, 32 * 12, 32 * 40, 32 * 2 },
    { 0, -32 * 10, 1, 32 * 40 }
}
--=========================================================================

Game:implements({
    load = function()
        world = Pack.Physics:newWorld()

        player = Player:new(Game, world, {
            x = 32 * 3,
            y = 32 * 4,
            w = 28,
            h = 58
        })

        for _, r in ipairs(rects) do
            local x, y, w, h = unpack(r)
            Pack.Physics:newBody(world, x, y, w, h, "static")
        end
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
        player:update(dt)
        Game.camera:follow(player:get_cx(), player:get_cy(), "player")
    end,

    draw = function(camera)
        world:draw()

        player:draw()

        Font:print(tostring(world.bodies_number), 32 * 3, 32 * 3)
    end
})

return Game
