--[[
BLOX FRUITS • HALLOWEEN EVENT SCANNER
Version: 0.1.0
Target: Roblox client / Delta iOS (single-file release)
Mode: READ-ONLY DIAGNOSTICS

This build only reads visible Workspace instance names/positions and draws a HUD.
It does NOT attack, move the character, trigger prompts, call game remotes, teleport,
or request data from external servers.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

if not player then
    warn("[Halloween Scanner] LocalPlayer indisponível.")
    return
end

local VERSION = "0.1.0"
local SCAN_INTERVAL = 30
local MAX_RESULTS = 12

local KEYWORDS = {
    HellfireGas = { "hellfire gas", "hellfire" },
    GreatPumpkin = { "the great pumpkin", "great pumpkin" },
    Werewolf = { "unbound werewolf", "werewolf" },
    Pumpkin = {
        "jack-o-lantern",
        "jack o lantern",
        "jackolantern",
        "pumpkin snowman",
        "pumpkin",
    },
    Witch = { "witch" },
    Zioles = { "zioles" },
    Door = { "door" },
}

local function formatTime(totalSeconds)
    totalSeconds = math.max(0, math.floor(totalSeconds))
    return string.format("%02d:%02d", math.floor(totalSeconds / 60), totalSeconds % 60)
end

local function getHarvestMoonState()
    -- Published schedule: first 10 minutes of each UTC hour.
    -- This is a prediction from the device clock, not a server-side confirmation.
    local utc = os.date("!*t", os.time())
    local secondsIntoHour = (utc.min * 60) + utc.sec
    local active = utc.min < 10

    if active then
        local left = (10 * 60) - secondsIntoHour
        return {
            active = true,
            display = "Harvest Moon prevista: ATIVA • " .. formatTime(left),
        }
    end

    local untilNext = (60 * 60) - secondsIntoHour
    return {
        active = false,
        display = "Próxima janela prevista em " .. formatTime(untilNext),
    }
end

local function containsAny(value, terms)
    value = string.lower(value or "")
    for _, term in ipairs(terms) do
        if string.find(value, term, 1, true) then return true end
    end
    return false
end

local function getCategory(name)
    if containsAny(name, KEYWORDS.HellfireGas) then return "Hellfire Gas" end
    if containsAny(name, KEYWORDS.GreatPumpkin) then return "Great Pumpkin" end
    if containsAny(name, KEYWORDS.Werewolf) then return "Werewolf" end
    if containsAny(name, KEYWORDS.Pumpkin) then return "Abóbora / Jack-o'-lantern" end
    if containsAny(name, KEYWORDS.Witch) then return "Witch" end
    if containsAny(name, KEYWORDS.Zioles) then return "Zioles / Gacha" end
    return nil
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

local function hasInteraction(object)
    for _, child in ipairs(object:GetDescendants()) do
        if child:IsA("ProximityPrompt") or child:IsA("ClickDetector") then
            return true
        end
    end
    return false
end

local function safeFullName(object)
    local ok, result = pcall(function() return object:GetFullName() end)
    return ok and result or object.Name
end

local function scanEventObjects()
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local origin = rootPart and rootPart.Position or nil

    local results = {}
    local counts = {
        total = 0,
        hellfire = 0,
        greatPumpkin = 0,
        werewolf = 0,
        pumpkin = 0,
        witch = 0,
        zioles = 0,
        doors = 0,
    }
    local seen = {}
    local descendants = workspace:GetDescendants()

    for _, instance in ipairs(descendants) do
        if instance:IsA("Model") or instance:IsA("BasePart") then
            local candidate
            if instance:IsA("Model") then
                candidate = instance
            else
                candidate = instance:FindFirstAncestorOfClass("Model") or instance
            end
            local combinedName = string.lower(candidate.Name .. " " .. instance.Name)
            local category = getCategory(combinedName)
            local isDoor = containsAny(combinedName, KEYWORDS.Door)

            if category or (isDoor and hasInteraction(candidate)) then
                if not seen[candidate] then
                    seen[candidate] = true
                    local position = getPosition(candidate) or getPosition(instance)
                    local distance = nil

                    if origin and position then
                        distance = math.floor((position - origin).Magnitude + 0.5)
                    end

                    table.insert(results, {
                        name = candidate.Name,
                        category = category or "Porta interativa",
                        path = safeFullName(candidate),
                        distance = distance,
                    })

                    counts.total = counts.total + 1
                    if category == "Hellfire Gas" then counts.hellfire = counts.hellfire + 1 end
                    if category == "Great Pumpkin" then counts.greatPumpkin = counts.greatPumpkin + 1 end
                    if category == "Werewolf" then counts.werewolf = counts.werewolf + 1 end
                    if category == "Abóbora / Jack-o'-lantern" then counts.pumpkin = counts.pumpkin + 1 end
                    if category == "Witch" then counts.witch = counts.witch + 1 end
                    if category == "Zioles / Gacha" then counts.zioles = counts.zioles + 1 end
                    if not category then counts.doors = counts.doors + 1 end
                end
            end
        end
    end

    table.sort(results, function(a, b)
        if a.distance == nil then return false end
        if b.distance == nil then return true end
        return a.distance < b.distance
    end)

    while #results > MAX_RESULTS do table.remove(results) end

    return {
        results = results,
        counts = counts,
        scannedInstances = #descendants,
        timestamp = os.date("!%H:%M:%S UTC"),
    }
end

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end

local function addCorner(parent, radius)
    make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function distanceText(distance)
    return distance == nil and "distância indisponível" or (tostring(distance) .. " m")
end

local playerGui = player:WaitForChild("PlayerGui", 15)
if not playerGui then
    warn("[Halloween Scanner] PlayerGui não encontrado.")
    return
end

local oldGui = playerGui:FindFirstChild("HalloweenEventScanner")
if oldGui then oldGui:Destroy() end

local gui = make("ScreenGui", {
    Name = "HalloweenEventScanner",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 10000,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local panel = make("Frame", {
    Name = "Panel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.48),
    Size = UDim2.fromOffset(305, 365),
    BackgroundColor3 = Color3.fromRGB(22, 23, 31),
    BorderSizePixel = 0,
}, gui)
addCorner(panel, 12)
make("UIStroke", {
    Color = Color3.fromRGB(111, 76, 164),
    Thickness = 1.5,
    Transparency = 0.15,
}, panel)

local header = make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = Color3.fromRGB(43, 31, 61),
    BorderSizePixel = 0,
}, panel)
addCorner(header, 12)

make("TextLabel", {
    Position = UDim2.fromOffset(12, 5),
    Size = UDim2.new(1, -55, 0, 23),
    BackgroundTransparency = 1,
    Text = "🎃 HALLOWEEN SCANNER",
    TextColor3 = Color3.fromRGB(255, 244, 229),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

make("TextLabel", {
    Position = UDim2.fromOffset(13, 27),
    Size = UDim2.new(1, -60, 0, 14),
    BackgroundTransparency = 1,
    Text = "Blox Fruits • v" .. VERSION .. " • somente leitura",
    TextColor3 = Color3.fromRGB(190, 176, 205),
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local closeButton = make("TextButton", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -8, 0, 8),
    Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = Color3.fromRGB(87, 49, 74),
    Text = "×",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 20,
}, header)
addCorner(closeButton, 8)

local clockLabel = make("TextLabel", {
    Position = UDim2.fromOffset(12, 58),
    Size = UDim2.new(1, -24, 0, 34),
    BackgroundColor3 = Color3.fromRGB(37, 38, 50),
    Text = "Calculando janela UTC...",
    TextColor3 = Color3.fromRGB(255, 211, 135),
    Font = Enum.Font.GothamSemibold,
    TextSize = 11,
    TextWrapped = true,
}, panel)
addCorner(clockLabel, 7)

local statsLabel = make("TextLabel", {
    Position = UDim2.fromOffset(12, 99),
    Size = UDim2.new(1, -24, 0, 39),
    BackgroundTransparency = 1,
    Text = "Objetos: aguardando primeira varredura",
    TextColor3 = Color3.fromRGB(221, 221, 230),
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local list = make("ScrollingFrame", {
    Name = "Results",
    Position = UDim2.fromOffset(12, 141),
    Size = UDim2.new(1, -24, 0, 146),
    BackgroundColor3 = Color3.fromRGB(31, 32, 43),
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel)
addCorner(list, 7)
make("UIPadding", {
    PaddingTop = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, 6),
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
}, list)
make("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, list)

local messageLabel = make("TextLabel", {
    Name = "Message",
    Position = UDim2.fromOffset(12, 292),
    Size = UDim2.new(1, -24, 0, 20),
    BackgroundTransparency = 1,
    Text = "Pronto para escanear.",
    TextColor3 = Color3.fromRGB(173, 193, 173),
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, panel)

local scanButton = make("TextButton", {
    Position = UDim2.fromOffset(12, 318),
    Size = UDim2.new(0.32, -4, 0, 34),
    BackgroundColor3 = Color3.fromRGB(102, 62, 144),
    Text = "SCANEAR",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 10,
}, panel)
addCorner(scanButton, 7)

local monitorButton = make("TextButton", {
    Position = UDim2.new(0.34, 0, 0, 318),
    Size = UDim2.new(0.32, -4, 0, 34),
    BackgroundColor3 = Color3.fromRGB(46, 112, 91),
    Text = "MONITOR: ON",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 9,
}, panel)
addCorner(monitorButton, 7)

local copyButton = make("TextButton", {
    Position = UDim2.new(0.68, 0, 0, 318),
    Size = UDim2.new(0.32, -4, 0, 34),
    BackgroundColor3 = Color3.fromRGB(63, 76, 104),
    Text = "COPIAR",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 10,
}, panel)
addCorner(copyButton, 7)

local latestData = nil
local monitoring = true
local running = true
local nextScanAt = 0

local function setMessage(value)
    messageLabel.Text = tostring(value or "")
end

local function updateHud()
    local clock = getHarvestMoonState()
    clockLabel.Text = clock.display .. " (UTC)"
    clockLabel.TextColor3 = clock.active
        and Color3.fromRGB(255, 166, 100)
        or Color3.fromRGB(255, 211, 135)

    monitorButton.Text = monitoring and "MONITOR: ON" or "MONITOR: OFF"
    monitorButton.BackgroundColor3 = monitoring
        and Color3.fromRGB(46, 112, 91)
        or Color3.fromRGB(105, 73, 73)
end

local function showResults(data)
    local c = data.counts
    statsLabel.Text = string.format(
        "Achados: %d • Pumpkins: %d • Bosses: %d • Portas: %d\nWitch: %d • Zioles: %d • Itens lidos: %d",
        c.total, c.pumpkin, c.hellfire + c.greatPumpkin + c.werewolf,
        c.doors, c.witch, c.zioles, data.scannedInstances
    )

    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end

    if #data.results == 0 then
        local empty = make("TextLabel", {
            Size = UDim2.new(1, -4, 0, 38),
            BackgroundTransparency = 1,
            Text = "Nenhum objeto com nome reconhecido. Precisamos comparar a estrutura real do servidor.",
            TextColor3 = Color3.fromRGB(190, 190, 202),
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextWrapped = true,
        }, list)
    else
        for index, item in ipairs(data.results) do
            local row = make("TextLabel", {
                LayoutOrder = index,
                Size = UDim2.new(1, -4, 0, 34),
                BackgroundColor3 = Color3.fromRGB(43, 43, 58),
                Text = item.category .. " • " .. item.name .. " • " .. distanceText(item.distance),
                TextColor3 = Color3.fromRGB(235, 231, 241),
                Font = Enum.Font.Gotham,
                TextSize = 9,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, list)
            addCorner(row, 5)
        end
    end

    setMessage("Última leitura: " .. tostring(data.timestamp))
end

local function buildReport()
    if not latestData then return "Nenhuma varredura concluída." end
    local c = latestData.counts
    local lines = {
        "HALLOWEEN EVENT SCANNER v" .. VERSION,
        "Leitura: " .. tostring(latestData.timestamp),
        "Instâncias analisadas: " .. tostring(latestData.scannedInstances),
        "Objetos reconhecidos: " .. tostring(c.total),
        "Pumpkins: " .. tostring(c.pumpkin),
        "Hellfire Gas: " .. tostring(c.hellfire),
        "Great Pumpkin: " .. tostring(c.greatPumpkin),
        "Werewolf: " .. tostring(c.werewolf),
        "Witch: " .. tostring(c.witch),
        "Zioles: " .. tostring(c.zioles),
        "Portas interativas: " .. tostring(c.doors),
        "",
        "OBJETOS:",
    }

    for _, item in ipairs(latestData.results) do
        table.insert(lines, item.category .. " | " .. item.name .. " | "
            .. distanceText(item.distance) .. " | " .. item.path)
    end

    return table.concat(lines, "\n")
end

local function scanNow()
    local ok, result = pcall(scanEventObjects)
    if ok then
        latestData = result
        showResults(result)
        setMessage("Varredura concluída • " .. tostring(result.scannedInstances) .. " instâncias.")
    else
        warn("[Halloween Scanner] Erro: " .. tostring(result))
        setMessage("Erro na varredura. Veja o console.")
    end
    nextScanAt = os.clock() + SCAN_INTERVAL
end

scanButton.Activated:Connect(scanNow)

monitorButton.Activated:Connect(function()
    monitoring = not monitoring
    updateHud()
    setMessage(monitoring and "Monitoramento automático ativado." or "Monitoramento pausado.")
end)

copyButton.Activated:Connect(function()
    local report = buildReport()
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, report)
        setMessage(ok and "Relatório copiado." or "Clipboard não disponível.")
    else
        setMessage("Clipboard não disponível; relatório enviado ao console.")
        print(report)
    end
end)

closeButton.Activated:Connect(function()
    running = false
    gui:Destroy()
end)

-- Touch-friendly drag handle on the header.
local dragging = false
local dragInput = nil
local dragStart = nil
local startPosition = nil

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput and dragStart and startPosition then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end)

updateHud()
scanNow()

task.spawn(function()
    while running and gui.Parent do
        updateHud()
        if monitoring and os.clock() >= nextScanAt then
            scanNow()
        end
        task.wait(1)
    end
end)

print("[Halloween Scanner] v" .. VERSION .. " carregado. Modo somente leitura.")
