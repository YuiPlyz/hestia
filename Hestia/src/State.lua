return function()
    return {
        StartedAt = os.clock(),
        Running = false,
        FPS = 0,
        Registry = {
            Enemies = {},
            Items = {},
            Scrap = {},
            Fuel = {},
            Structures = {},
            Players = {},
            Generator = {},
            Chest = {},
        },
        Stats = { Scrap = 0, Pickups = 0, Stored = 0, Repairs = 0, Attacks = 0 },
        Status = {},
        Errors = {},
    }
end
