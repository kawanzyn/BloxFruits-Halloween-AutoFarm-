local UI = {}

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function formatDistance(distance)
    if distance == nil then return "distância indisponível" end
    return tostring(distance) .. " m"
end

function UI.Mount(player, config)
    local playerGui = player:WaitForChild("PlayerGui", 15)
    if not playerGui then
        warn("[Halloween Scanner] PlayerGui não encontrado.")
        return nil
    end

    local previous = playerGui:FindFirstChild("HalloweenEventScanner")
    if previous then previous:Destroy() end

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
    corner(panel, 12)
    make("UIStroke", {
        Color = Color3.fromRGB(111, 76, 164),
        Thickness = 1.5,
        Transparency = 0.15,
    }, panel)

    local header = make("Frame", {
        Name = "Header",
        Active = true,
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Color3.fromRGB(43, 31, 61),
        BorderSizePixel = 0,
    }, panel)
    corner(header, 12)

    make("TextLabel", {
        Name = "Title",
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
        Name = "Version",
        Position = UDim2.fromOffset(13, 27),
        Size = UDim2.new(1, -60, 0, 14),
        BackgroundTransparency = 1,
        Text = "Blox Fruits • v" .. config.VERSION .. " • somente leitura",
        TextColor3 = Color3.fromRGB(190, 176, 205),
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)

    local close = make("TextButton", {
        Name = "Close",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 8),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = Color3.fromRGB(87, 49, 74),
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        AutoButtonColor = true,
    }, header)
    corner(close, 8)

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
    corner(clockLabel, 7)

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
    corner(list, 7)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
    }, list)
    local layout = make("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, list)

    local message = make("TextLabel", {
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
    corner(scanButton, 7)

    local monitorButton = make("TextButton", {
        Position = UDim2.new(0.34, 0, 0, 318),
        Size = UDim2.new(0.32, -4, 0, 34),
        BackgroundColor3 = Color3.fromRGB(46, 112, 91),
        Text = "MONITOR: ON",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 9,
    }, panel)
    corner(monitorButton, 7)

    local copyButton = make("TextButton", {
        Position = UDim2.new(0.68, 0, 0, 318),
        Size = UDim2.new(0.32, -4, 0, 34),
        BackgroundColor3 = Color3.fromRGB(63, 76, 104),
        Text = "COPIAR",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
    }, panel)
    corner(copyButton, 7)

    local state = {
        callbacks = {},
        latestData = nil,
        monitoring = true,
        destroyed = false,
    }

    local api = {}

    function api:SetCallbacks(callbacks)
        state.callbacks = callbacks or {}
    end

    function api:SetMessage(text)
        message.Text = tostring(text or "")
    end

    function api:Update(clockState, data, monitoring)
        if state.destroyed then return end
        if clockState then
            clockLabel.Text = clockState.display .. " (UTC)"
            clockLabel.TextColor3 = clockState.active
                and Color3.fromRGB(255, 166, 100)
                or Color3.fromRGB(255, 211, 135)
        end

        if data then
            state.latestData = data
            local c = data.counts
            statsLabel.Text = string.format(
                "Achados: %d • Pumpkins: %d • Bosses: %d • Portas: %d\nWitch: %d • Zioles: %d • Itens lidos: %d",
                c.total,
                c.pumpkin,
                c.hellfire + c.greatPumpkin + c.werewolf,
                c.doors,
                c.witch,
                c.zioles,
                data.scannedInstances
            )

            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("TextLabel") then child:Destroy() end
            end

            if #data.results == 0 then
                local empty = make("TextLabel", {
                    Size = UDim2.new(1, -4, 0, 38),
                    BackgroundTransparency = 1,
                    Text = "Nenhum objeto com nome reconhecido. Isso é útil: precisamos comparar com a estrutura real do servidor.",
                    TextColor3 = Color3.fromRGB(190, 190, 202),
                    Font = Enum.Font.Gotham,
                    TextSize = 10,
                    TextWrapped = true,
                }, list)
            else
                for index, item in ipairs(data.results) do
                    local distanceText = formatDistance(item.distance)
                    local row = make("TextLabel", {
                        LayoutOrder = index,
                        Size = UDim2.new(1, -4, 0, 34),
                        BackgroundColor3 = Color3.fromRGB(43, 43, 58),
                        Text = item.category .. " • " .. item.name .. " • " .. distanceText,
                        TextColor3 = Color3.fromRGB(235, 231, 241),
                        Font = Enum.Font.Gotham,
                        TextSize = 9,
                        TextWrapped = true,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, list)
                    corner(row, 5)
                end
            end

            message.Text = "Última leitura: " .. tostring(data.timestamp)
        end

        state.monitoring = monitoring == true
        monitorButton.Text = state.monitoring and "MONITOR: ON" or "MONITOR: OFF"
        monitorButton.BackgroundColor3 = state.monitoring
            and Color3.fromRGB(46, 112, 91)
            or Color3.fromRGB(105, 73, 73)
    end

    function api:BuildReport()
        local data = state.latestData
        if not data then return "Nenhuma varredura concluída." end

        local c = data.counts
        local lines = {
            "HALLOWEEN EVENT SCANNER v" .. config.VERSION,
            "Leitura: " .. tostring(data.timestamp),
            "Instâncias analisadas: " .. tostring(data.scannedInstances),
            "Objetos reconhecidos: " .. tostring(c.total),
            "Pumpkins: " .. tostring(c.pumpkin),
            "Hellfire Gas: " .. tostring(c.hellfire),
            "Great Pumpkin: " .. tostring(c.greatPumpkin),
            "Werewolf: " .. tostring(c.werewolf),
            "Witch: " .. tostring(c.witch),
            "Zioles: " .. tostring(c.zioles),
            "Portas interativas: " .. tostring(c.doors),
            "",
            "OBJETOS:"
        }

        for _, item in ipairs(data.results) do
            table.insert(lines, item.category .. " | " .. item.name .. " | "
                .. formatDistance(item.distance) .. " | " .. item.path)
        end

        return table.concat(lines, "\n")
    end

    function api:Destroy()
        state.destroyed = true
        if gui and gui.Parent then gui:Destroy() end
    end

    scanButton.Activated:Connect(function()
        if state.callbacks.scan then state.callbacks.scan() end
    end)
    monitorButton.Activated:Connect(function()
        if state.callbacks.toggle then state.callbacks.toggle() end
    end)
    copyButton.Activated:Connect(function()
        if state.callbacks.copy then state.callbacks.copy(api:BuildReport()) end
    end)
    close.Activated:Connect(function()
        if state.callbacks.close then state.callbacks.close() end
        api:Destroy()
    end)

    -- Touch-friendly dragging: drag the top bar rather than a tiny handle.
    local UserInputService = game:GetService("UserInputService")
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
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    return api
end

return UI
