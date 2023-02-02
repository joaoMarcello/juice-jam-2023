local love = _G.love
Pack = require "JM_love2d_package.init"

math.randomseed(os.time())
love.graphics.setBackgroundColor(0, 0, 0, 1)
love.mouse.setVisible(false)

---@class GameState: JM.Scene
---@field load function
---@field init function
---@field finish function
---@field update function
---@field draw function
---@field keypressed function
---@field prev_state GameState|nil

--==================================================================

SCREEN_WIDTH = 32 * 20
SCREEN_HEIGHT = 32 * 13

--==================================================================

---@type GameState
local scene

---@param new_state GameState
function CHANGE_GAME_STATE(new_state, skip_finish, skip_load, save_prev, skip_collect)
    local r = scene and not skip_finish and scene:finish()
    r = not skip_load and new_state:load()
    new_state:init()
    new_state.prev_state = save_prev and scene or nil
    r = not skip_collect and collectgarbage()
    scene = new_state
    scene:fadein(nil, nil, nil)
end

function RESTART(state)
    CHANGE_GAME_STATE(state, true, true, false, false)
end

function love.load()
    CHANGE_GAME_STATE(require 'scripts.gameState.menu_principal', true)
end

function love.keypressed(key)
    local r = scene and scene:keypressed(key)
end

function love.keyreleased(key)
    local r = scene and scene:keyreleased(key)
end

function love.mousepressed(x, y, button, istouch, presses)
    scene:mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    scene:mousereleased(x, y, button, istouch, presses)
end

local km = nil

function love.update(dt)
    km = collectgarbage("count") / 1024.0

    if love.keyboard.isDown("escape")
        or (love.keyboard.isDown("lalt") and love.keyboard.isDown('f4'))
        or (love.keyboard.isDown("ralt") and love.keyboard.isDown('f4'))
    then
        scene:finish()
        collectgarbage("collect")
        love.event.quit()
    end

    scene:update(dt)
end

function love.draw()
    scene:draw()

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 80, 120)
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print(string.format("Memory:\n\t%.2f Mb", km), 5, 10)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 5, 50)
    local maj, min, rev, code = love.getVersion()
    love.graphics.print(string.format("Version:\n\t%d.%d.%d", maj, min, rev), 5, 75)
end
