local Players = game:GetService("Players")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "AutoDistractGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(280, 220)
frame.Position = UDim2.new(0.5, -140, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(28, 20, 38)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 45)
title.BackgroundTransparency = 1
title.Text = "AUTO DISTRACT"
title.TextColor3 = Color3.fromRGB(255, 90, 110)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(0.8, 0, 0, 45)
button.Position = UDim2.new(0.1, 0, 0.35, 0)
button.BackgroundColor3 = Color3.fromRGB(150, 35, 55)
button.Text = "AUTO DISTRACT: OFF"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 14
button.Font = Enum.Font.GothamBold
button.Parent = frame

local enabled = false

button.MouseButton1Click:Connect(function()
    enabled = not enabled
    button.Text = enabled and "AUTO DISTRACT: ON" or "AUTO DISTRACT: OFF"
end)
