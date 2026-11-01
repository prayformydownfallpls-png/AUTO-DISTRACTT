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
    return model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
end

local function removeESP(model)
    if tracked[model] then
        tracked[model].highlight:Destroy()
        tracked[model].billboard:Destroy()
        tracked[model] = nil
    end
end

local function addESP(model)
    if not settings.esp or tracked[model] then return end
    if not model:IsA("Model") then return end

    local part = getRoot(model)
    if not part then return end

    local highlight = Instance.new("Highlight")
    highlight.Adornee = model
    highlight.FillColor = Color3.fromRGB(255, 45, 65)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.55
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

local function closestTwisted(root)
    local closest, distance = nil, math.huge

    for _, model in ipairs(
        CollectionService:GetTagged("Twisted")
    ) do
        local enemyRoot = getRoot(model)
        local enemyHumanoid =
            model:FindFirstChildOfClass("Humanoid")

        if enemyRoot and enemyHumanoid
            and enemyHumanoid.Health > 0 then

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
        return
    end

    local waypoints = path:GetWaypoints()

    for _, waypoint in ipairs(waypoints) do
        if not gui.Parent then return end

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end

        humanoid:MoveTo(waypoint.Position)

        local reached = humanoid.MoveToFinished:Wait()
        if not reached then return end
    end
end

task.spawn(function()
    while gui.Parent do
        local character = player.Character
        local root = character and
            character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and
            character:FindFirstChildOfClass("Humanoid")

        local twisteds = CollectionService:GetTagged("Twisted")

        if settings.esp then
            for _, model in ipairs(twisteds) do
                addESP(model)
            end
        else
            for model in pairs(tracked) do
                removeESP(model)
            end
        end

        for model in pairs(tracked) do
            if not model.Parent or
                not CollectionService:HasTag(model, "Twisted") then
                removeESP(model)
            end
        end

        if root and humanoid and humanoid.Health > 0 then
            currentTarget = closestTwisted(root)

            if currentTarget then
                local enemyRoot = getRoot(currentTarget)

                if enemyRoot and settings.aggro then
                    moveSafely(
                        humanoid,
                        root,
                        enemyRoot.Position
                    )

                elseif enemyRoot and settings.run then
                    local distance =
                        (root.Position - enemyRoot.Position).Magnitude

                    -- Only retreat when the closest Twisted is within 30 studs.
                    if distance < SAFE_DISTANCE then
                        local away = root.Position - enemyRoot.Position

                        if away.Magnitude > 0 then
                            local destination =
                                root.Position + away.Unit * RETREAT_DISTANCE

                            moveSafely(
                                humanoid,
                                root,
                                destination
                            )
                        end
                    end
                end
            end
        end

        status.Text =
            "Twisteds: " .. #twisteds ..
            "\nTarget: " ..
            (currentTarget and currentTarget.Name or "None")

        task.wait(CHECK_INTERVAL)
    end
end)
