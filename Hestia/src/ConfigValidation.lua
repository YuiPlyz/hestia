local Validation = {}
local function finite(n)
    return type(n) == "number" and n == n and math.abs(n) < math.huge
end
local function validate(source, schema, path, depth)
    assert(depth < 12 and type(source) == "table", "HESTIA invalid configuration tree")
    local result, count = {}, 0
    local map = path:match("Whitelist%.$")
        or path:match("Blacklist%.$")
        or path == "Farming.ItemCategories."
        or path == "Farming.PickupCategories."
        or path == "Storage.Categories."
        or path == "Storage.Keep."
    for key, value in pairs(source) do
        count = count + 1
        assert(count <= 500, "HESTIA too many config entries")
        assert(type(key) == "string" or type(key) == "number", "HESTIA invalid config key")
        assert(type(key) ~= "string" or #key <= 128, "HESTIA config key too long")
        local expected = schema[key]
        if map then
            assert(type(key) == "string" and type(value) == "boolean", "HESTIA filters require name: boolean")
            result[key] = value
        elseif path == "Storage.Minimum." then
            assert(
                type(key) == "string" and finite(value) and value >= 0 and value <= 100000,
                "HESTIA minimum quantities must be nonnegative numbers"
            )
            result[key] = value
        elseif expected ~= nil then
            assert(type(value) == type(expected), "HESTIA invalid type at " .. path .. tostring(key))
            if type(value) == "table" then
                result[key] = validate(value, expected, path .. tostring(key) .. ".", depth + 1)
            elseif type(value) == "number" then
                local minimum = path:match("^Teleports%.Saved%.") and -1000000 or 0
                assert(
                    finite(value) and value >= minimum and value <= 1000000,
                    "HESTIA invalid numeric value"
                )
                result[key] = value
            elseif type(value) == "string" then
                assert(#value <= 128, "HESTIA text too long")
                result[key] = value
            else
                result[key] = value
            end
        elseif next(schema) == nil then
            if type(value) == "table" then
                result[key] = validate(value, {}, path .. tostring(key) .. ".", depth + 1)
            elseif type(value) == "number" then
                assert(finite(value) and math.abs(value) <= 1000000, "HESTIA invalid map number")
                result[key] = value
            elseif type(value) == "boolean" or type(value) == "string" then
                result[key] = value
            else
                error("HESTIA invalid dynamic config value")
            end
        end
    end
    return result
end
function Validation.Validate(source, schema)
    local result = validate(source, schema, "", 0)
    local c = result.Generator or {}
    local below, untilValue, emergency =
        c.FuelBelow or schema.Generator.FuelBelow,
        c.FuelUntil or schema.Generator.FuelUntil,
        c.EmergencyFuel or schema.Generator.EmergencyFuel
    assert(
        emergency <= below and below < untilValue and untilValue <= 100,
        "HESTIA requires emergency <= start < stop <= 100"
    )
    local interface = result.Interface or {}
    if interface.MenuKey then
        assert(Enum.KeyCode[interface.MenuKey], "HESTIA unknown menu key")
    end
    if interface.WidgetOpacity then
        assert(interface.WidgetOpacity <= 1, "HESTIA opacity must be 0-1")
    end
    local function at(tree, path)
        local node = tree
        for key in path:gmatch("[^.]+") do
            node = type(node) == "table" and node[key] or nil
        end
        return node
    end
    local bounds = {
        ["Farming.ScrapDelay"] = { 0.1, 10 },
        ["Farming.PickupDelay"] = { 0.1, 10 },
        ["Farming.TargetTimeout"] = { 3, 120 },
        ["Farming.StuckTimeout"] = { 1, 20 },
        ["Farming.PathRetries"] = { 0, 10 },
        ["Combat.Range"] = { 1, 50 },
        ["Combat.AttackDelay"] = { 0.1, 10 },
        ["Repair.Rate"] = { 0.2, 10 },
        ["Player.WalkSpeed"] = { 0, 100 },
        ["Player.SprintSpeed"] = { 0, 150 },
        ["Player.JumpPower"] = { 0, 150 },
        ["Player.FlySpeed"] = { 1, 150 },
    }
    for path, range in pairs(bounds) do
        local value = at(result, path)
        if value ~= nil then
            assert(value >= range[1] and value <= range[2], "HESTIA out-of-range value: " .. path)
        end
    end
    for path, choices in pairs({
        ["Farming.ScrapPriority"] = { "Nearest", "Value" },
        ["Combat.Priority"] = { "Nearest", "LowestHP", "HighestHP" },
        ["Repair.Priority"] = { "Nearest", "LowestHealth" },
        ["Interface.NotificationSide"] = { "Left", "Right" },
    }) do
        local value = at(result, path)
        if value then
            assert(table.find(choices, value), "HESTIA invalid selection: " .. path)
        end
    end
    if c.FuelPriority then
        assert(#c.FuelPriority > 0 and #c.FuelPriority <= 32, "HESTIA fuel priority must be an array")
        for key, name in pairs(c.FuelPriority) do
            assert(type(key) == "number" and type(name) == "string", "HESTIA invalid fuel priority")
        end
    end
    local function color(rgb)
        assert(#rgb == 3, "HESTIA color requires three components")
        for _, n in ipairs(rgb) do
            assert(finite(n) and n >= 0 and n <= 255, "HESTIA invalid color")
        end
    end
    if interface.Accent then
        color(interface.Accent)
    end
    for _, item in pairs((result.Visuals or {}).Categories or {}) do
        if item.Color then
            color(item.Color)
        end
    end
    for _, location in pairs((result.Teleports or {}).Saved or {}) do
        assert(
            type(location) == "table" and #location == 12,
            "HESTIA saved location requires 12 CFrame components"
        )
        for _, n in ipairs(location) do
            assert(finite(n), "HESTIA invalid location")
        end
    end
    return result
end
return Validation
