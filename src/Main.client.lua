local Players = game:GetService("Players")

local player = Players.LocalPlayer
if not player then
    warn("[Halloween Scanner] LocalPlayer indisponível.")
    return
end

local Config = require(script.Parent.Config)
local HarvestMoonClock = require(script.Parent.Modules.HarvestMoonClock)
local EventScanner = require(script.Parent.Modules.EventScanner)
local UI = require(script.Parent.UI)

local ui = UI.Mount(player, Config)
if not ui then return end

local running = true
local monitoring = true
local latestData = nil
local nextScanAt = 0

local function scanNow()
    local ok, result = pcall(function()
        return EventScanner.Scan(workspace, player, Config)
    end)

    if ok then
        latestData = result
        ui:Update(HarvestMoonClock.GetState(), latestData, monitoring)
        ui:SetMessage("Varredura concluída • " .. tostring(result.scannedInstances) .. " instâncias.")
    else
        warn("[Halloween Scanner] Falha na varredura: " .. tostring(result))
        ui:SetMessage("Erro na varredura. Veja o console.")
    end

    nextScanAt = os.clock() + Config.SCAN_INTERVAL
end

ui:SetCallbacks({
    scan = scanNow,
    toggle = function()
        monitoring = not monitoring
        ui:Update(HarvestMoonClock.GetState(), latestData, monitoring)
        ui:SetMessage(monitoring and "Monitoramento automático ativado." or "Monitoramento pausado.")
    end,
    copy = function(report)
        if type(setclipboard) == "function" then
            local ok = pcall(setclipboard, report)
            ui:SetMessage(ok and "Relatório copiado." or "Não foi possível copiar neste executor.")
        else
            ui:SetMessage("Clipboard não disponível; consulte o console.")
            print(report)
        end
    end,
    close = function()
        running = false
    end,
})

scanNow()

task.spawn(function()
    while running do
        ui:Update(HarvestMoonClock.GetState(), latestData, monitoring)

        if monitoring and os.clock() >= nextScanAt then
            scanNow()
        end

        task.wait(1)
    end
end)
