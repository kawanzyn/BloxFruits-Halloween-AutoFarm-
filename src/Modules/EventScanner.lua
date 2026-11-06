local EventScanner = {}

local function containsAny(value, terms)
    value = string.lower(value or "")
    for _, term in ipairs(terms) do
        if string.find(value, term, 1, true) then
            return true
        end
    end
    return false
end

local function getCategory(name, config)
    local keys = config.KEYWORDS
    -- Specific bosses are checked before the broad word "pumpkin".
    if containsAny(name, keys.HellfireGas) then return "Hellfire Gas" end
    if containsAny(name, keys.GreatPumpkin) then return "Great Pumpkin" end
    if containsAny(name, keys.Werewolf) then return "Werewolf" end
    if containsAny(name, keys.Pumpkin) then return "Abóbora / Jack-o'-lantern" end
    if containsAny(name, keys.Witch) then return "Witch" end
    if containsAny(name, keys.Zioles) then return "Zioles / Gacha" end
    return nil
end

local function getPosition(object)
    if object:IsA("BasePart") then
        return object.Position
    end

    if object:IsA("Model") then
        if object.PrimaryPart then
            return object.PrimaryPart.Position
        end
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
    local ok, result = pcall(function()
        return object:GetFullName()
    end)
    return ok and result or object.Name
end

function EventScanner.Scan(world, player, config)
    local character = player and player.Character
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

    local descendants = world:GetDescendants()
    for _, instance in ipairs(descendants) do
        if instance:IsA("Model") or instance:IsA("BasePart") then
            local candidate
            if instance:IsA("Model") then
                candidate = instance
            else
                candidate = instance:FindFirstAncestorOfClass("Model") or instance
            end
            local combinedName = string.lower(candidate.Name .. " " .. instance.Name)

            local category = getCategory(combinedName, config)
            local isDoor = containsAny(combinedName, config.KEYWORDS.Door)

            if category or (isDoor and hasInteraction(candidate)) then
                if not seen[candidate] then
                    seen[candidate] = true

                    local position = getPosition(candidate) or getPosition(instance)
                    local distance = nil
                    if origin and position then
                        distance = math.floor((position - origin).Magnitude + 0.5)
                    end

                    local item = {
                        name = candidate.Name,
                        category = category or "Porta interativa",
                        path = safeFullName(candidate),
                        distance = distance,
                    }

                    table.insert(results, item)
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

    while #results > config.MAX_RESULTS do
        table.remove(results)
    end

    return {
        results = results,
        counts = counts,
        scannedInstances = #descendants,
        timestamp = os.date("!%H:%M:%S UTC"),
    }
end

return EventScanner
