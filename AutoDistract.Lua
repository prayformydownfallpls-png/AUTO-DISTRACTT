-- SAFE DISTANCE SETTINGS
local SAFE_DISTANCE = 30
local RETREAT_DISTANCE = 45
local CHECK_INTERVAL = 0.5

-- AUTO DISTRACT GUI
-- Roblox Studio version

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "AutoDistractGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(290, 390)
frame.Position = UDim2.new(0.5, -145, 0.5, -195)
frame.BackgroundColor3 = Color3.fromRGB(28, 20, 38)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius =
    UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundTransparency = 1
title.Text = "AUTO DISTRACT"
title.TextColor3 = Color3.fromRGB(255, 90, 110)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.Parent = frame

local function makeButton(name, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.8, 0, 0, 40)
    button.Position = UDim2.new(0.1, 0, 0, y)
    button.BackgroundColor3 = Color3.fromRGB(150, 35, 55)
    button.Text = name .. ": OFF"
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.Parent = frame

    Instance.new("UICorner", button).CornerRadius =
        UDim.new(0, 8)

    return button
end

local distractButton = makeButton("AUTO DISTRACT", 55)
local espButton = makeButton("TWISTED ESP", 105)
local aggroButton = makeButton("AUTO AGGRO", 155)
local runButton = makeButton("AUTO RUN AWAY", 205)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 65)
status.Position = UDim2.new(0, 10, 0, 265)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1, 1, 1)
status.TextSize = 12
status.TextWrapped = true
status.Font = Enum.Font.Gotham
status.Text = "Twisteds: 0\nTarget: None"
status.Parent = frame

local settings = {
    distract = false,
    esp = false,
    aggro = false,
    run = false
}

local tracked = {}
local currentTarget = nil

local function connectToggle(button, key, name)
    button.MouseButton1Click:Connect(function()
        settings[key] = not settings[key]
        button.Text = name .. ": " ..
            (settings[key] and "ON" or "OFF")
    end)
end

connectToggle(distractButton, "distract", "AUTO DISTRACT")
connectToggle(espButton, "esp", "TWISTED ESP")
connectToggle(aggroButton, "aggro", "AUTO AGGRO")
connectToggle(runButton, "run", "AUTO RUN AWAY")

local function getRoot(model)
