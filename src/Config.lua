local Config = {}

Config.VERSION = "0.1.0"
Config.SCAN_INTERVAL = 30
Config.MAX_RESULTS = 12

-- The scanner is intentionally read-only. These are name hints, not guaranteed
-- internal identifiers; the live server scan will tell us what actually exists.
Config.KEYWORDS = {
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

return Config
