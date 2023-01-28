---@type string
local path = ...
path = path:gsub("jm_gui", "")

---@type JM.GUI.Button
local Button = require(path .. "gui.button")

---@type JM.GUI.Container
local Container = require(path .. "gui.container")

---@type JM.GUI.TextBox
local TextBox = require(path .. "gui.textBox")

---@class JM.GUI
local GUI = {}

GUI.Button = Button
GUI.Container = Container
GUI.TextBox = TextBox

return GUI
