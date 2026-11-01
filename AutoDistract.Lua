-- AUTO DISTRACT GUI - Roblox Studio LocalScript
-- Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- Tag each NPC MODEL with the CollectionService tag "Twisted".

local SAFE_DISTANCE = 30
local RETREAT_DISTANCE = 45
local CHECK_INTERVAL = 0.5
local PATH_RETRY_INTERVAL = 1

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Avoid creating duplicate GUIs if the LocalScript restarts.
local oldGui = playerGui:FindFirstChild("AutoDistractGUI")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "AutoDistractGUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(290, 390)
frame.Position = UDim2.new(0.5, -145, 0.5, -195)
frame.BackgroundColor3 = Color3.fromRGB(28, 20, 38)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

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
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
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
status.Text = "Twisteds tagged: 0\nValid targets: 0\nTarget: None"
status.Parent = frame

local settings = {
    distract = false,
    esp = false,
    aggro = false,
    run = false
}

local tracked = {}
local currentTarget = nil
local movementToken = 0
local lastPathTime = 0

local function connectToggle(button, key, name)
    button.MouseButton1Click:Connect(function()
        settings[key] = not settings[key]
        button.Text = name .. ": " .. (settings[key] and "ON" or "OFF")
    end)
end

connectToggle(distractButton, "distract", "AUTO DISTRACT")
connectToggle(espButton, "esp", "TWISTED ESP")
connectToggle(aggroButton, "aggro", "AUTO AGGRO")
connectToggle(runButton, "run", "AUTO RUN AWAY")

local function getRoot(model)
    if not model or not model:IsA("Model") then
        return nil
    end

    local root = model:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end

    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end

    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function removeESP(model)
    local info = tracked[model]
    if info then
        if info.highlight then info.highlight:Destroy() end
        if info.billboard then info.billboard:Destroy() end
        tracked[model] = nil
    end
end

local function addESP(model)
    if not settings.esp or tracked[model] then return end
    if not model:IsA("Model") then return end

    local part = getRoot(model)
    if not part then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "AutoDistractHighlight"
    highlight.Adornee = model
    highlight.FillColor = Color3.fromRGB(255, 45, 65)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.55
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = gui

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "AutoDistractLabel"
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

local function getValidTwisteds()
    local valid = {}

    for _, model in ipairs(CollectionService:GetTagged("Twisted")) do
        if model:IsA("Model") and model:IsDescendantOf(workspace) then
            local root = getRoot(model)
            local humanoid = model:FindFirstChildOfClass("Humanoid")

            -- If an NPC has no Humanoid, it can still be shown by ESP,
            -- but it cannot be selected as a living movement target.
            if root and humanoid and humanoid.Health > 0 then
                table.insert(valid, model)
            end
        end
    end

    return valid
end

local function closestTwisted(playerRoot, candidates)
    local closest = nil
    local closestDistance = math.huge

    for _, model in ipairs(candidates) do
        local enemyRoot = getRoot(model)
        if enemyRoot then
            local distance = (playerRoot.Position - enemyRoot.Position).Magnitude
            if distance < closestDistance then
                closest = model
                closestDistance = distance
            end
        end
    end

    return closest, closestDistance
end

local function stopMovement()
    movementToken += 1
end

local function moveAlongPath(character, humanoid, root, destination, token)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true
    })

    local ok, err = pcall(function()
        path:ComputeAsync(root.Position, destination)
    end)

    if not ok then
        warn("AutoDistract path calculation failed:", err)
        return
    end

    if path.Status ~= Enum.PathStatus.Success then
        -- Fallback: attempt a direct MoveTo if no path can be computed.
        humanoid:MoveTo(destination)
        return
    end

    for _, waypoint in ipairs(path:GetWaypoints()) do
        if token ~= movementToken or not gui.Parent then return end
        if player.Character ~= character or humanoid.Health <= 0 then return end

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end

        humanoid:MoveTo(waypoint.Position)
        local reached = humanoid.MoveToFinished:Wait()
        if not reached then return end
    end
end

local function requestMove(character, humanoid, root, destination)
    local now = os.clock()
    if now - lastPathTime < PATH_RETRY_INTERVAL then
        return
    end

    lastPathTime = now
    movementToken += 1
    local token = movementToken

    task.spawn(function()
        moveAlongPath(character, humanoid, root, destination, token)
    end)
end

task.spawn(function()
    while gui.Parent do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        local taggedTwisteds = CollectionService:GetTagged("Twisted")
        local validTwisteds = {}

        -- ESP can display tagged models even if they are not Humanoid NPCs.
        if settings.esp then
            for _, model in ipairs(taggedTwisteds) do
                if model:IsA("Model") and model:IsDescendantOf(workspace) then
                    addESP(model)
                end
            end
        else
            for model in pairs(tracked) do
                removeESP(model)
            end
        end

        for model in pairs(tracked) do
            if not model.Parent or not CollectionService:HasTag(model, "Twisted") then
                removeESP(model)
            end
        end

        validTwisteds = getValidTwisteds()

        if root and humanoid and humanoid.Health > 0 then
            currentTarget = closestTwisted(root, validTwisteds)

            if settings.aggro and currentTarget then
                local enemyRoot = getRoot(currentTarget)
                if enemyRoot then
                    requestMove(character, humanoid, root, enemyRoot.Position)
                end
            elseif settings.run and currentTarget then
                local enemyRoot = getRoot(currentTarget)
                if enemyRoot then
                    local distance = (root.Position - enemyRoot.Position).Magnitude

                    if distance < SAFE_DISTANCE then
                        local away = root.Position - enemyRoot.Position
                        if away.Magnitude > 0 then
                            local destination = root.Position + away.Unit * RETREAT_DISTANCE
                            requestMove(character, humanoid, root, destination)
                        end
                    end
                end
            else
                stopMovement()
            end
        else
            currentTarget = nil
            stopMovement()
        end

        status.Text =
            "Twisteds tagged: " .. #taggedTwisteds ..
            "\nValid targets: " .. #validTwisteds ..
            "\nTarget: " .. (currentTarget and currentTarget.Name or "None")

        task.wait(CHECK_INTERVAL)
    end
end)

gui.Destroying:Connect(stopMovement)
