--[[
BLOX FRUITS • HALLOWEEN EVENT COLLECTOR
Version: 0.2.0
Client-side movement + standard ProximityPrompt interaction.
No remote firing, no teleport, no executor-specific prompt bypass.
Only tries pumpkin-named objects with an enabled ProximityPrompt.
]]

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local player = Players.LocalPlayer
if not player then return end

local VERSION = "0.2.0"
local SCAN_INTERVAL = 20
local MAX_PATH_RETRIES = 1
local running = false
local attempted = {}
local collected = 0
local skipped = 0
local currentTarget = "Aguardando"

local function isPumpkinName(name)
    name = string.lower(name or "")
    return string.find(name, "pumpkin", 1, true) ~= nil
        or string.find(name, "jack-o-lantern", 1, true) ~= nil
        or string.find(name, "jack o lantern", 1, true) ~= nil
        or string.find(name, "jackolantern", 1, true) ~= nil
end

local function getRoot()
    local character = player.Character
    if not character then return nil, nil end
    return character:FindFirstChild("HumanoidRootPart"), character:FindFirstChildOfClass("Humanoid")
end

local function getPosition(object)
    if object:IsA("BasePart") then return object.Position end
    if object:IsA("Model") then
        if object.PrimaryPart then return object.PrimaryPart.Position end
        local part = object:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position end
    end
    return nil
end

local function findPrompt(object)
    if object:IsA("ProximityPrompt") then return object end
    for _, item in ipairs(object:GetDescendants()) do
        if item:IsA("ProximityPrompt") and item.Enabled then
            return item
        end
    end
    return nil
end

local function safePath(object)
    local ok, result = pcall(function() return object:GetFullName() end)
    return ok and result or object.Name
end

local function scanAllPumpkins()
    local found, seen = {}, {}
    for _, instance in ipairs(workspace:GetDescendants()) do
        if (instance:IsA("Model") or instance:IsA("BasePart")) and isPumpkinName(instance.Name) then
            local target = instance:IsA("Model") and instance
                or (instance:FindFirstAncestorOfClass("Model") or instance)
            if not seen[target] then
                seen[target] = true
                local prompt = findPrompt(target)
                local position = getPosition(target)
                if prompt and position then
                    local path = safePath(target)
                    if not attempted[path] then
                        table.insert(found, {
                            object = target,
                            prompt = prompt,
                            position = position,
                            path = path,
                            name = target.Name,
                        })
                    end
                end
            end
        end
    end

    local root = getRoot()
    if root then
        table.sort(found, function(a, b)
            return (a.position - root.Position).Magnitude < (b.position - root.Position).Magnitude
        end)
    end
    return found
end

local function moveToPosition(humanoid, destination)
    local root = getRoot()
    if not root or not humanoid then return false end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 6,
    })

    local ok = pcall(function()
        path:ComputeAsync(root.Position, destination)
    end)
    if not ok or path.Status ~= Enum.PathStatus.Success then
        return false
    end

    for _, waypoint in ipairs(path:GetWaypoints()) do
        if not running then return false end
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end

        local finished = false
        local reached = false
        local connection = humanoid.MoveToFinished:Connect(function(success)
            reached = success
            finished = true
        end)

        humanoid:MoveTo(waypoint.Position)
        local started = os.clock()
        while running and not finished and os.clock() - started < 8 do
            task.wait(0.15)
        end
        connection:Disconnect()

        if not finished or not reached then
            return false
        end
    end

    return true
end

local function attemptTarget(target)
    if not target.object or not target.object.Parent then
        return "gone"
    end

    local root, humanoid = getRoot()
    if not root or not humanoid then
        return "no-character"
    end

    local prompt = target.prompt
    if not prompt or not prompt.Parent or not prompt.Enabled then
        return "no-prompt"
    end

    local activationDistance = math.max(6, prompt.MaxActivationDistance - 1)
    local approachPosition = target.position
    local offset = root.Position - target.position
    if offset.Magnitude > 0 then
        approachPosition = target.position + offset.Unit * math.min(activationDistance * 0.65, 5)
    end

    local arrived = false
    for _ = 1, MAX_PATH_RETRIES do
        if moveToPosition(humanoid, approachPosition) then
            arrived = true
            break
        end
    end
    if not arrived then return "unreachable" end

    root = getRoot()
    if not root or (root.Position - target.position).Magnitude > prompt.MaxActivationDistance then
        return "out-of-range"
    end

    if not prompt.Parent or not prompt.Enabled then return "gone" end

    local hold = math.max(0, prompt.HoldDuration or 0)
    local ok = pcall(function()
        prompt:InputHoldBegin()
        if hold > 0 then task.wait(hold + 0.2) end
        prompt:InputHoldEnd()
    end)
    if not ok then return "interaction-error" end

    task.wait(1.25)

    -- Conservative confirmation: only count success if the target/prompt disappears
    -- or the prompt becomes disabled. If it remains, skip rather than loop forever.
    if not target.object.Parent or not prompt.Parent or not prompt.Enabled then
        return "collected"
    end
    return "not-confirmed"
end

-- Compact mobile HUD
local guiParent = player:WaitForChild("PlayerGui", 15)
if not guiParent then return end
local old = guiParent:FindFirstChild("HalloweenCollectorV020")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "HalloweenCollectorV020"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10001
gui.Parent = guiParent

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(280, 142)
panel.Position = UDim2.new(0.5, -140, 0.72, -71)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 34)
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 27)
title.Position = UDim2.fromOffset(8, 6)
title.BackgroundTransparency = 1
title.Text = "🎃 HALLOWEEN COLLECTOR v" .. VERSION
title.TextColor3 = Color3.fromRGB(255, 235, 210)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.Parent = panel

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -16, 0, 44)
status.Position = UDim2.fromOffset(8, 35)
status.BackgroundTransparency = 1
status.Text = "Pronto. Só tenta alvos com ProximityPrompt."
status.TextColor3 = Color3.fromRGB(220, 220, 230)
status.Font = Enum.Font.Gotham
status.TextSize = 10
status.TextWrapped = true
status.TextYAlignment = Enum.TextYAlignment.Top
status.Parent = panel

local start = Instance.new("TextButton")
start.Size = UDim2.new(0.48, -6, 0, 34)
start.Position = UDim2.fromOffset(8, 96)
start.BackgroundColor3 = Color3.fromRGB(73, 128, 91)
start.Text = "INICIAR"
start.TextColor3 = Color3.new(1, 1, 1)
start.Font = Enum.Font.GothamBold
start.TextSize = 11
start.Parent = panel
Instance.new("UICorner", start).CornerRadius = UDim.new(0, 7)

local stop = Instance.new("TextButton")
stop.Size = UDim2.new(0.48, -6, 0, 34)
stop.Position = UDim2.new(0.52, -2, 0, 96)
stop.BackgroundColor3 = Color3.fromRGB(130, 67, 67)
stop.Text = "PARAR"
stop.TextColor3 = Color3.new(1, 1, 1)
stop.Font = Enum.Font.GothamBold
stop.TextSize = 11
stop.Parent = panel
Instance.new("UICorner", stop).CornerRadius = UDim.new(0, 7)

local function updateStatus(extra)
    status.Text = string.format(
        "%s\nColetadas confirmadas: %d • Ignoradas: %d",
        extra or currentTarget, collected, skipped
    )
end

stop.Activated:Connect(function()
    running = false
    start.Text = "INICIAR"
    updateStatus("Parado pelo jogador.")
end)

start.Activated:Connect(function()
    if running then return end
    running = true
    start.Text = "RODANDO"
    task.spawn(function()
        while running do
            local targets = scanAllPumpkins()
            updateStatus("Varredura global: " .. #targets .. " alvos com prompt.")
            if #targets == 0 then
                task.wait(SCAN_INTERVAL)
            else
                for index, target in ipairs(targets) do
                    if not running then break end
                    currentTarget = string.format("Tentando %d/%d: %s", index, #targets, target.name)
                    updateStatus(currentTarget)
                    local result = attemptTarget(target)
                    attempted[target.path] = true

                    if result == "collected" then
                        collected = collected + 1
                        updateStatus("Coleta confirmada: " .. target.name)
                    else
                        skipped = skipped + 1
                        updateStatus("Ignorada (" .. result .. "): " .. target.name)
                    end
                    task.wait(0.35)
                end
            end
            if running then task.wait(SCAN_INTERVAL) end
        end
        start.Text = "INICIAR"
    end)
end)

print("[Halloween Collector] v" .. VERSION .. " carregado. Clique INICIAR.")
