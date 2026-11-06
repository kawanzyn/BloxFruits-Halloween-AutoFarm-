local HarvestMoonClock = {}

local function formatTime(totalSeconds)
    totalSeconds = math.max(0, math.floor(totalSeconds))
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format("%02d:%02d", minutes, seconds)
end

function HarvestMoonClock.GetState()
    -- os.time() is an epoch timestamp; os.date("!*t") explicitly reads UTC.
    -- This predicts the published hourly window and does not prove that a
    -- particular game server has enabled the event.
    local now = os.time()
    local utc = os.date("!*t", now)
    local secondsIntoHour = (utc.min * 60) + utc.sec
    local active = utc.min < 10
    local secondsRemaining
    local secondsUntilNext

    if active then
        secondsRemaining = (10 * 60) - secondsIntoHour
        secondsUntilNext = 0
    else
        secondsRemaining = 0
        secondsUntilNext = (60 * 60) - secondsIntoHour
    end

    return {
        active = active,
        hour = utc.hour,
        minute = utc.min,
        second = utc.sec,
        secondsRemaining = secondsRemaining,
        secondsUntilNext = secondsUntilNext,
        display = active
            and ("Harvest Moon prevista: ATIVA • " .. formatTime(secondsRemaining))
            or ("Próxima janela prevista em " .. formatTime(secondsUntilNext)),
        source = "Relógio UTC do dispositivo",
    }
end

return HarvestMoonClock
