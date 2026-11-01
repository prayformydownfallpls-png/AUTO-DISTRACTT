
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
