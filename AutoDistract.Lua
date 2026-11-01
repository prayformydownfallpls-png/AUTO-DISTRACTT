
-- AUTO DISTRACT GUI
-- Roblox Studio game you control
-- Tag NPC models with "Twisted"

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

local function makeButton(text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.8, 0, 0, 40)
    button.Position = UDim2.new(0.1, 0, 0, y)
    button.BackgroundColor3 = Color3.fromRGB(150, 35, 55)
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.Parent = frame

    Instance.new("UICorner", button).CornerRadius =
        UDim.new(0, 8)

    return button
end

local distractButton = makeButton("AUTO DISTRACT: OFF", 55)
local espButton = makeButton("TWISTED ESP: OFF", 105)
local aggroButton = makeButton("AUTO AGGRO: OFF", 155)
local runButton = makeButton("AUTO RUN AWAY: OFF", 205)

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

local distractEnabled = false
local espEnabled = false
local aggroEnabled = false
local runEnabled = false

local tracked = {}
local currentTarget = nil
local currentMode = "Idle"

local function toggle(button, value, name)
    button.Text = name .. ": " ..
        (value and "ON" or "OFF")
end

distractButton.MouseButton1Click:Connect(function()
    distractEnabled = not distractEnabled
    toggle(distractButton, distractEnabled, "AUTO DISTRACT")
end)

espButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    toggle(espButton, espEnabled, "TWISTED ESP")
end)

aggroButton.MouseButton1Click:Connect(function()
    aggroEnabled = not aggroEnabled
    toggle(aggroButton, aggroEnabled, "AUTO AGGRO")
end)

runButton.MouseButton1Click:Connect(function()
    runEnabled = not runEnabled
    toggle(runButton, runEnabled, "AUTO RUN AWAY")
end)

local function removeESP(model)
    if tracked[model] then
        tracked[model].highlight:Destroy()
        tracked[model].billboard:Destroy()
        tracked[model] = nil
    end
end

local function addESP(model)
    if not espEnabled or tracked[model] then return end
    if not model:IsA("Model") then return end

    local part = model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart", true)

    if not part then return end

    local highlight = Instance.new("Highlight")
    highlight.Adornee = model
    highlight.FillColor = Color3.fromRGB(255, 45, 65)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = model

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = part
    billboard.Size = UDim2.fromOffset(150, 35)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = gui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = model.Name
    label.TextColor3 = Color3.fromRGB(255, 75, 90)
    label.TextStrokeTransparency = 0
    label.TextSize = 15
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard

    tracked[model] = {
        highlight = highlight,
        billboard = billboard
    }
end

local function getRoot(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
end

local function getClosestTwisted(root)
    local closest = nil
    local distance = math.huge

    for _, model in ipairs(
        CollectionService:GetTagged("Twisted")
    ) do
        local enemyRoot = getRoot(model)
        local humanoid = model:FindFirstChildOfClass("Humanoid")

        if enemyRoot and humanoid and humanoid.Health > 0 then
            local d = (root.Position - enemyRoot.Position).Magnitude

            if d < distance then
                closest = model
                distance = d
            end
        end
    end

    return closest, distance
end

local function moveSafely(humanoid, root, destination)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true
    })

    local success = pcall(function()
        path:ComputeAsync(root.Position, destination)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        return false
    end

    for _, waypoint in ipairs(path:GetWaypoints()) do
        if not gui.Parent then return false end

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end

        humanoid:MoveTo(waypoint.Position)

        local reached = humanoid.MoveToFinished:Wait()
        if not reached then return false end
    end

    return true
end

local function refreshESP()
    for _, model in ipairs(
        CollectionService:GetTagged("Twisted")
    ) do
        addESP(model)
    end

    for model in pairs(tracked) do
        if not model.Parent or
            not CollectionService:HasTag(model, "Twisted") then
            removeESP(model)
        end
    end
end

task.spawn(function()
    while gui.Parent do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        local count = #CollectionService:GetTagged("Twisted")

        if espEnabled then
            refreshESP()
        else
            for model in pairs(tracked) do
                removeESP(model)
            end
        end

        if root and humanoid and humanoid.Health > 0 then
            currentTarget = getClosestTwisted(root)

            if aggroEnabled and currentTarget then
                local enemyRoot = getRoot(currentTarget)

                if enemyRoot then
                    currentMode = "Approaching"
                    moveSafely(
                        humanoid,
                        root,
                        enemyRoot.Position
                    )
                end

            elseif runEnabled and currentTarget then
                local enemyRoot = getRoot(currentTarget)

                if enemyRoot then
                    currentMode = "Retreating"

                    local away = root.Position - enemyRoot.Position

                    if away.Magnitude > 0 then
                        local destination =
                            root.Position + away.Unit * 35

                        moveSafely(
                            humanoid,
                            root,
                            destination
                        )
                    end
                end
            else
                currentMode = "Idle"
            end
        end

        status.Text =
            "Twisteds: " .. count ..
            "\nTarget: " ..
            (currentTarget and currentTarget.Name or "None") ..
            "\nMovement: " .. currentMode

        task.wait(0.5)
    end
end)
