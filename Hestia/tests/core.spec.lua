local Tasks = require("../src/TaskManager")
local Version = require("../src/Version")
local Generator = require("../modules/Generator")
local Worker = require("../modules/FarmWorker")
local Store = require("../modules/AutoStore")
local Config = require("../src/Config")
local Validation = require("../src/ConfigValidation")
local Connections = require("../src/Connections")
local Importer = require("../src/Importer")
local Main = require("../src/Main")
local passed = 0
local function test(name, callback)
    local ok, reason = pcall(callback)
    if not ok then
        error("FAIL " .. name .. ": " .. tostring(reason), 0)
    end
    passed = passed + 1
    print("PASS " .. name)
end
local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, child in pairs(value) do
        result[key] = copy(child)
    end
    return result
end
test("module names and raw paths share one cached export", function()
    local module = {}
    local folder = {
        FindFirstChild = function(_, name)
            return name == "Example" and module
        end,
    }
    local root = {
        FindFirstChild = function(_, name)
            return name == "modules" and folder
        end,
    }
    local calls, export = 0, {}
    local importer = Importer.new(
        root,
        { modules = { Example = { path = "modules/Example.lua" } } },
        function(object)
            assert(object == module)
            calls = calls + 1
            return export
        end
    )
    assert(importer:Import("Example") == export)
    assert(importer:Import("modules/Example.lua") == export and calls == 1)
    importer:Clear()
    assert(next(importer.Cache) == nil)
end)
test("dependency cycles fail and failed loads remain retryable", function()
    local manifest = {
        modules = {
            A = { path = "A.lua", dependencies = { "B" } },
            B = {
                path = "B.lua",
                dependencies = { "A" },
            },
        },
    }
    local root = {
        FindFirstChild = function(_, name)
            return { Name = name }
        end,
    }
    local fail = true
    local importer = Importer.new(root, manifest, function()
        if fail then
            error("Temporary module failure")
        end
        return {}
    end)
    assert(not pcall(function()
        importer:Import("A")
    end))
    assert(next(importer.Loading) == nil and next(importer.Cache) == nil)
    manifest.modules.A.dependencies = {}
    assert(not pcall(function()
        importer:Import("A")
    end))
    fail = false
    assert(type(importer:Import("A")) == "table")
    assert(not pcall(function()
        importer:Import("Unknown")
    end))
end)
test("unload is idempotent and clears owned state", function()
    local counts = {}
    local function count(key)
        counts[key] = (counts[key] or 0) + 1
    end
    local h = setmetatable({
        State = { Running = true },
        Features = {
            Example = {
                Destroy = function()
                    count("feature")
                end,
            },
        },
        Enabled = { Example = true },
        Scheduler = {
            Destroy = function()
                count("scheduler")
            end,
        },
        Navigator = {
            Cancel = function()
                count("navigation")
            end,
        },
        Tasks = {
            ReleaseAll = function()
                count("tasks")
            end,
        },
        Adapter = {
            Destroy = function()
                count("adapter")
            end,
        },
        Connections = {
            DisconnectAll = function()
                count("connections")
            end,
        },
        UI = {
            Destroy = function()
                count("ui")
            end,
        },
        Registry = { Items = { target = true } },
        Importer = {
            Clear = function()
                count("imports")
            end,
        },
    }, Main)
    h:Unload()
    h:Unload()
    for _, key in ipairs({
        "feature",
        "scheduler",
        "navigation",
        "tasks",
        "adapter",
        "connections",
        "ui",
        "imports",
    }) do
        assert(counts[key] == 1)
    end
    assert(not h.State.Running and next(h.Features) == nil and next(h.Registry.Items) == nil)
end)
test("priority preempts and resumes without dropping requests", function()
    local tasks = Tasks.new()
    assert(tasks:Request("ScrapFarm", 50))
    local token = tasks.Serial
    assert(tasks:Request("EmergencyFuel", 90))
    assert(not tasks:IsOwner("ScrapFarm", token))
    assert(tasks:Request("Survival", 100))
    tasks:Release("Survival")
    assert(tasks.Active == "EmergencyFuel")
    tasks:Release("EmergencyFuel")
    assert(tasks.Active == "ScrapFarm")
    assert(not tasks:IsOwner("ScrapFarm", token))
    tasks:ReleaseAll()
    assert(tasks.Active == nil and next(tasks.Requests) == nil)
end)
test("equal priority is stable and priority can change", function()
    local tasks = Tasks.new()
    tasks:Request("First", 40)
    tasks:Request("Second", 40)
    assert(tasks.Active == "First")
    tasks:Request("Second", 60)
    assert(tasks.Active == "Second")
    tasks:Request("Second", 30)
    assert(tasks.Active == "First")
end)
test("semantic version numeric ordering", function()
    assert(Version.IsNewer("1.10.0", "1.9.9"))
    assert(not Version.IsNewer("1.0.0", "1.0.0"))
    assert(not Version.IsNewer("1.9.0", "2.0.0"))
    assert(not pcall(Version.IsNewer, "broken", "1.0.0"))
end)
test("invalid thresholds rejected before config mutation", function()
    assert(not pcall(Validation.Validate, { Generator = { FuelBelow = 95 } }, Config))
    assert(not pcall(Validation.Validate, { Generator = { EmergencyFuel = 80 } }, Config))
    assert(not pcall(Validation.Validate, { Player = { WalkSpeed = 0 / 0 } }, Config))
    assert(not pcall(Validation.Validate, { Storage = { Minimum = { Scrap = -1 } } }, Config))
    assert(Config.Generator.FuelBelow == 50)
end)
test("filters accept new categories and reject non-booleans", function()
    local result = Validation.Validate({ Farming = { ItemCategories = { Fuel = true } } }, Config)
    assert(result.Farming.ItemCategories.Fuel == true)
    assert(not pcall(Validation.Validate, { Farming = { PickupBlacklist = { Scrap = 42 } } }, Config))
end)
test("saved negative CFrames survive repeated validation", function()
    local cframe = { -25, 3, -40, 1, 0, 0, 0, 1, 0, 0, 0, 1 }
    local source = { Teleports = { Saved = { Camp = cframe } } }
    local schema = copy(Config)
    assert(Validation.Validate(source, schema).Teleports.Saved.Camp[1] == -25)
    schema.Teleports.Saved.Camp = cframe
    assert(Validation.Validate(source, schema).Teleports.Saved.Camp[3] == -40)
    assert(not pcall(Validation.Validate, { Teleports = { Saved = { Camp = { 1, 2 } } } }, schema))
end)
test("unsafe intervals and malformed colors are rejected", function()
    assert(not pcall(Validation.Validate, { Combat = { AttackDelay = 0 } }, Config))
    assert(not pcall(Validation.Validate, { Interface = { Accent = { 300, 0, 0 } } }, Config))
    assert(not pcall(Validation.Validate, { Generator = { FuelPriority = {} } }, Config))
end)
test("connection replacement and repeated cleanup", function()
    local count = 0
    local function entry()
        return {
            Disconnect = function()
                count = count + 1
            end,
        }
    end
    local c = Connections.new()
    c:Add("A", entry())
    c:Add("A", entry())
    assert(count == 1)
    c:Add("B", entry())
    c:DisconnectAll()
    assert(count == 3)
    c:DisconnectAll()
    assert(count == 3)
end)
local function harness()
    local h = {
        Config = copy(Config),
        Tasks = Tasks.new(),
        State = { Stats = { Scrap = 0, Stored = 0 } },
        Registry = { Scrap = {} },
    }
    h.Navigator = {
        Cancel = function() end,
        Step = function()
            return "Arrived"
        end,
    }
    h.Notifications = { Send = function() end }
    h.Scheduler = { Add = function() end, Remove = function() end }
    h.Adapter = {
        Valid = function()
            return true
        end,
        Distance = function()
            return 1
        end,
        GetInventory = function()
            return {}
        end,
        GetFuelPercent = function()
            return 15
        end,
        InventoryFull = function()
            return false
        end,
    }
    return h
end
test("generator hysteresis holds emergency lease and resumes scrap", function()
    local h = harness()
    h.Tasks:Request("ScrapFarm", 50)
    local g = Generator.new(h)
    g.FindBestFuel = function()
        return { Name = "Fuel" }
    end
    local added = 0
    g.AddFuel = function()
        added = added + 1
        return true
    end
    g:Step()
    assert(h.Tasks.Active == "Generator" and h.Tasks.Requests.Generator.Priority == 90)
    h.Adapter.GetFuelPercent = function()
        return 65
    end
    g:Step()
    assert(h.Tasks.Active == "Generator" and g.Fueling)
    h.Adapter.GetFuelPercent = function()
        return 90
    end
    g:Step()
    assert(h.Tasks.Active == "ScrapFarm" and not g.Fueling and added == 2)
    g:Stop()
    assert(h.Tasks.Active == "ScrapFarm")
end)
test("generator releases movement during missing-fuel backoff", function()
    local h = harness()
    h.Tasks:Request("ScrapFarm", 50)
    local g = Generator.new(h)
    g.FindBestFuel = function()
        return nil
    end
    g:Step()
    assert(h.Tasks.Active == "ScrapFarm")
    assert(g.Status == "No available fuel" and g.Backoff > os.clock())
end)
test("farm never collects while preempted and only counts confirmation", function()
    local h = harness()
    local attempts = 0
    h.Adapter.CollectItem = function()
        attempts = attempts + 1
        return false
    end
    local worker = Worker.new(h, "ScrapFarm", { Stat = "Scrap" })
    h.Tasks:Request("ScrapFarm", 50)
    h.Tasks:Request("Generator", 90)
    assert(not worker:Collect({ Name = "Scrap" }) and attempts == 0)
    h.Tasks:Release("Generator")
    assert(not worker:Collect({ Name = "Scrap" }) and h.State.Stats.Scrap == 0)
    h.Adapter.CollectItem = function()
        return true, 8
    end
    assert(worker:Collect({ Name = "Scrap" }) and h.State.Stats.Scrap == 8)
    worker:Stop()
    assert(next(h.Tasks.Requests) == nil)
end)
test("storage retains a movement lease across navigation ticks", function()
    local h = harness()
    local target = {}
    h.Adapter.GetStorage = function()
        return target
    end
    h.Adapter.GetInventory = function()
        return { { Instance = {}, Name = "Scrap", Category = "Scrap", Quantity = 30 } }
    end
    h.Adapter.StoreItem = function(_, _, quantity)
        assert(quantity == 10)
        return true, quantity
    end
    local steps = 0
    h.Navigator.Step = function()
        steps = steps + 1
        return steps < 3 and "Moving" or "Arrived"
    end
    local store = Store.new(h)
    store:Step()
    local serial = h.Tasks.Serial
    store:Step()
    assert(h.Tasks.Serial == serial and h.Tasks.Active == "AutoStore")
    store:Step()
    assert(h.State.Stats.Stored == 10 and h.Tasks.Active == nil)
end)
test("storage respects keep and reserve quantities", function()
    local h = harness()
    h.Adapter.GetStorage = function()
        return {}
    end
    h.Adapter.GetInventory = function()
        return { { Instance = {}, Name = "Scrap", Category = "Scrap", Quantity = 10 } }
    end
    h.Adapter.StoreItem = function()
        error("Must not store reserved scrap")
    end
    Store.new(h):Step()
    assert(h.Tasks.Active == nil)
end)
test("unlimited search and empty or false filters include all items", function()
    local util = require("../modules/Utilities")
    local near, far = {}, {}
    local h = {
        Adapter = {
            Valid = function()
                return true
            end,
            Distance = function(_, item)
                return item == near and 10 or 50000
            end,
        },
    }
    assert(util.Nearest(h, { [far] = true }, 0) == far)
    assert(util.Nearest(h, { [far] = true }, 5000) == nil)
    assert(util.Nearest(h, { [near] = true, [far] = true }, 0) == near)
    assert(util.Allowed("Scrap", "Scrap", {}, {}, {}))
    assert(util.Allowed("Scrap", "Scrap", { Fuel = false }, {}, { Fuel = false }))
    assert(not util.Allowed("Scrap", "Scrap", { Fuel = true }, {}, {}))
    assert(not util.Allowed("Scrap", "Scrap", { Scrap = true }, { Scrap = true }, {}))
end)
test("item selections have no 500 entry cap", function()
    local names = {}
    for i = 1, 750 do
        names["Item " .. i] = true
    end
    local result = Validation.Validate({ Farming = { ItemWhitelist = names, ItemRadius = 0 } }, Config)
    assert(result.Farming.ItemWhitelist["Item 750"])
    assert(result.Farming.ItemRadius == 0)
end)
test("pickup reports missing integration and honors range, filters and capacity", function()
    local Pickup = require("../modules/AutoPickup")
    local util = require("../modules/Utilities")
    local h = harness()
    local tick
    h.Scheduler.Add = function(_, _, _, callback)
        tick = callback
    end
    h.Adapter.Hooks = {}
    h.Registry.Items = {}
    h.State.Stats.Pickups = 0
    h.Import = function()
        return util
    end
    local pickup = Pickup.new(h)
    pickup:Start()
    tick()
    assert(pickup.Status == "Missing CollectItem hook")
    local item = { Name = "Scrap" }
    local calls = 0
    h.Adapter.Distance = function()
        return 1000
    end
    h.Adapter.Category = function()
        return "Scrap"
    end
    h.Adapter.CollectItem = function()
        calls = calls + 1
        return true, 2
    end
    h.Tasks:Request("AutoPickup", 30)
    assert(not pickup:TryCollect(item) and calls == 0)
    h.Config.Farming.PickupRadius = 0
    h.Config.Farming.PickupBlacklist = { Scrap = true }
    assert(not pickup:TryCollect(item) and calls == 0)
    h.Config.Farming.PickupBlacklist = {}
    h.Adapter.InventoryFull = function()
        return true
    end
    assert(not pickup:TryCollect(item) and calls == 0)
    h.Adapter.InventoryFull = function()
        return false
    end
    assert(pickup:TryCollect(item) and calls == 1 and h.State.Stats.Pickups == 2)
    assert(not pickup:TryCollect(item) and calls == 1)
    pickup:Stop()
    assert(h.Tasks.Active == nil)
end)
test("STA pickup routes resources to storage and requires inventory confirmation", function()
    local hooks = require("../src/Hooks")
    local function folder(children)
        return {
            FindFirstChild = function(_, name)
                return children[name]
            end,
        }
    end
    local drops, inventory, calls, now = {}, {}, {}, 0
    local world = folder({ DroppedItems = drops })
    local bag = {
        GetChildren = function()
            return inventory
        end,
    }
    local player = folder({ Backpack = bag })
    player.Character = {
        GetChildren = function()
            return {}
        end,
    }
    local function event(name, callback)
        return {
            IsA = function(_, class)
                return class == "RemoteEvent"
            end,
            FireServer = function(_, item)
                table.insert(calls, name)
                if callback then
                    callback(item)
                end
            end,
        }
    end
    local tools, interaction = {}, {}
    local storage = folder({ Remotes = folder({ Tools = folder(tools), Interaction = folder(interaction) }) })
    local collect = hooks.CreatePickup(storage, player, world, function(dt)
        now = now + dt
    end, function()
        return now
    end)
    local item = { Name = "Scrap", Parent = drops }
    assert(not collect(item, "Scrap") and #calls == 0)
    interaction.PickUpItem = event("pickup")
    tools.AdjustBackpack = event("store")
    local ok, reason, sent = collect(item, "Scrap")
    assert(not ok and sent and reason:find("confirmation") and #calls == 1 and calls[1] == "store")
    assert(now >= 0.75 and now < 1)
    table.clear(calls)
    tools.AdjustBackpack = event("store", function(target)
        table.insert(inventory, {
            Name = target.Name,
            IsA = function()
                return true
            end,
            GetAttribute = function()
                return 3
            end,
        })
    end)
    local amount
    ok, amount = collect(item, "Scrap")
    assert(ok and amount == 3 and #calls == 1 and calls[1] == "store")
    table.clear(calls)
    item.Name = "Pistol"
    ok, amount = collect(item, "Gun")
    assert(ok and amount == 3 and calls[1] == "pickup" and calls[2] == "store")
    table.clear(calls)
    item.Parent = {}
    assert(not collect(item, "Gun") and #calls == 0)
    item.Parent = drops
    tools.AdjustBackpack = event("store", function()
        error("rejected")
    end)
    assert(not collect(item, "Fuel"))
    tools.AdjustBackpack = event("store", function(target)
        target.Parent = nil
    end)
    ok, reason, sent = collect(item, "Fuel")
    assert(not ok and sent and reason:find("confirmation"))
end)
test("pickup gives every item a turn after unconfirmed requests", function()
    local Pickup = require("../modules/AutoPickup")
    local util = require("../modules/Utilities")
    local h, tick, attempted = harness(), nil, {}
    h.Registry.Items = {}
    for i = 1, 8 do
        h.Registry.Items[{ Name = "Item " .. i }] = true
    end
    h.Import = function()
        return util
    end
    h.Adapter.Hooks = { CollectItem = function() end }
    h.Adapter.Category = function()
        return "Resource"
    end
    h.Adapter.CollectItem = function(_, item)
        assert(not attempted[item], "an item starved the rest of the queue")
        attempted[item] = true
        return false, "Request sent", true
    end
    h.Scheduler.Add = function(_, _, _, callback)
        tick = callback
    end
    local pickup = Pickup.new(h)
    pickup:Start()
    for _ = 1, 8 do
        pickup.NextCollect = 0
        tick()
    end
    assert(util.Count(attempted) == 8)
    pickup:Stop()
    assert(pickup.Queue == nil)
end)
test("STA weapon and repair protocols report confirmed and unconfirmed actions", function()
    local hooks = require("../src/Hooks")
    local hp, now, calls = 100, 0, {}
    local target = {
        Parent = {},
        IsA = function(_, class)
            return class == "Model"
        end,
        FindFirstChildOfClass = function()
            return nil
        end,
        GetAttribute = function()
            return hp
        end,
    }
    local events, equipped = {}, true
    local tool = {
        Name = "Knife",
        FindFirstChild = function(_, name)
            return events[name]
        end,
    }
    local player = { Character = {
        FindFirstChildOfClass = function()
            return equipped and tool or nil
        end,
    } }
    local isPlayer = false
    local players = {
        GetPlayerFromCharacter = function()
            return isPlayer and {} or nil
        end,
    }
    local actions = hooks.CreateActions(player, players, function(dt)
        now = now + dt
    end, function()
        return now
    end)
    local function event(name, callback)
        return {
            IsA = function(_, class)
                return class == "RemoteEvent"
            end,
            FireServer = function(_, arg)
                table.insert(calls, name)
                if callback then
                    callback(arg)
                end
            end,
        }
    end
    assert(not actions.AttackTarget(target))
    events.Swing = event("swing")
    events.HitTargets = event("hit", function(arg)
        assert(arg[1] == target and #arg == 1)
        hp = hp - 10
    end)
    assert(actions.AttackTarget(target) and calls[1] == "swing" and calls[2] == "hit")
    table.clear(calls)
    isPlayer = true
    assert(not actions.AttackTarget(target) and #calls == 0)
    isPlayer = false
    equipped = false
    assert(not actions.AttackTarget(target))
    equipped = true
    events.Swing, events.HitTargets = nil, nil
    events.RemoteClick = event("click", function(arg)
        assert(arg == target)
    end)
    local ok, reason, sent = actions.AttackTarget(target)
    assert(not ok and sent and reason:find("unconfirmed") and now >= 0.4)
    assert(not actions.RepairStructure(target))
    tool.Name = "Repair Hammer"
    assert(not actions.RepairStructure(target))
    events.Repair = event("repair", function(arg)
        assert(arg == target)
        hp = hp + 5
    end)
    assert(actions.RepairStructure(target))
end)
test("fog properties restore exactly even before the first scheduled update", function()
    local Lighting = require("../modules/Lighting")
    local h = { Config = { Visuals = { RemoveFog = true } }, Services = { Lighting = {} } }
    local feature = Lighting.new(h)
    local function object(class, values)
        values.Parent = {}
        values.IsA = function(_, name)
            return class == name
        end
        return values
    end
    local atmosphere = object("Atmosphere", { Density = 0.4, Haze = 2 })
    local particle = object("ParticleEmitter", { Enabled = true })
    local part = object("BasePart", { LocalTransparencyModifier = 0.25 })
    feature:HideFog(atmosphere)
    feature:HideFog(particle)
    feature:HideFog(part)
    assert(atmosphere.Density == 0 and atmosphere.Haze == 0 and not particle.Enabled)
    assert(part.LocalTransparencyModifier == 1)
    feature:HideFog(part)
    h.Config.Visuals.RemoveFog = false
    feature:UpdateFog()
    assert(atmosphere.Density == 0.4 and atmosphere.Haze == 2 and particle.Enabled)
    assert(part.LocalTransparencyModifier == 0.25 and next(feature.FogObjects) == nil)
end)
test("ESP unlimited distance and appearance bounds", function()
    local ESP = require("../modules/ESP")
    local h = { Config = copy(Config) }
    local esp = ESP.new(h)
    assert(esp:InRange(500000, { MaxDistance = 0 }))
    assert(not esp:InRange(1000, { MaxDistance = 500 }))
    h.Config.Visuals.MaxDistance = 100
    assert(not esp:InRange(1000, { MaxDistance = 0 }))
    assert(not pcall(function()
        Validation.Validate({ Visuals = { FillTransparency = 2 } }, Config)
    end))
    assert(not pcall(function()
        Validation.Validate({ Visuals = { TextSize = 200 } }, Config)
    end))
    for _, name in ipairs({ "Ammo", "Backpacks", "Structures", "Consumables", "MiscItems" }) do
        assert(Config.Visuals.Categories[name])
    end
end)
print(string.format("HESTIA: %d core tests passed", passed))
