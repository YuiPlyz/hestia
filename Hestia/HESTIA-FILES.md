# HESTIA complete project

Every project file is included below.

## FILE: .gitignore

````text
tools/.bin/
__pycache__/
dist/

````

## FILE: client/Runtime.client.lua

````lua
local replicated = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local root = replicated:WaitForChild("HESTIA", 20)
assert(root, "HESTIA package missing")
local player = players.LocalPlayer
if not game:GetService("RunService"):IsStudio() and player:GetAttribute("HESTIA_Enabled") ~= true then
    local deadline = os.clock() + 15
    repeat
        task.wait(0.2)
    until player:GetAttribute("HESTIA_Enabled") == true or os.clock() > deadline
    if player:GetAttribute("HESTIA_Enabled") ~= true then
        return
    end
end
local deadline = os.clock() + 12
repeat
    task.wait(0.1)
until root:GetAttribute("VersionReady") or os.clock() > deadline
local hooks = table.clone(require(root.src.Hooks))
local remote = replicated:WaitForChild("HESTIA Config", 10)
if remote then
    hooks.SaveConfig = hooks.SaveConfig
        or function(folder, raw)
            return remote:InvokeServer("Save", folder, raw)
        end
    hooks.LoadConfig = hooks.LoadConfig
        or function(folder)
            return remote:InvokeServer("Load", folder)
        end
end
local app = require(root.src.Main).new(root, hooks)
app:Start()
local destroying
destroying = script.Destroying:Connect(function()
    app:Unload()
    destroying:Disconnect()
end)
app.Connections:Add("HESTIA.ClientLifecycle", destroying)

````

## FILE: data/Enemies.lua

````lua
return {
    Runner = "Normal",
    Crawler = "Normal",
    Riot = "Armored",
    Zombie = "Normal",
    Brute = "Heavy",
    Spitter = "Ranged",
    Boss = "Boss",
}

````

## FILE: data/Items.lua

````lua
return {
    Gun = {
        "AA-12",
        "AK-47",
        "Assault Rifle",
        "Desert Eagle",
        "Double Barrel",
        "Flamethrower",
        "Grenade Launcher",
        "LMG",
        "MediGun",
        "Pistol",
        "Ray Gun",
        "Revolver",
        "Rifle",
        "Shotgun",
        "Sniper",
        "SVD",
        "Uzi",
    },
    Melee = {
        "Bat",
        "Chainsaw",
        "Crowbar",
        "Fire Axe",
        "Hatchet",
        "Katana",
        "Knife",
        "Riot Shield",
        "Scythe",
        "Sledgehammer",
        "Spear",
        "Spiked Bat",
    },
    Medical = { "Bandage", "Compound H", "Compound I", "Compound R", "Compound S", "Medkit" },
    Armor = { "Power Armor", "Light Armor", "Medium Armor", "Heavy Armor" },
    Food = { "Chips", "Carrot", "Bloxiade", "Beans", "MRE", "Bloxy Cola" },
    Resource = {
        "AC",
        "Battery",
        "Battery Pack",
        "Bucket",
        "Dumbell",
        "Exhaust Pipe",
        "Reactor Component",
        "Refined Metal",
        "Satellite Dish",
        "Screws",
        "Spatula",
        "Tray",
        "TV",
        "Watch",
        "Zombie Heart",
    },
    Fuel = { "Nuclear Fuel", "Refined Fuel", "Fuel" },
    Ability = {
        "Airstrike",
        "Attack Order",
        "Call of the Dead",
        "Summon Brute",
        "Summon Zombies",
        "Taunt",
        "The Future",
        "The Past",
        "The Present",
    },
    Ammo = { "Ammo Box", "Long Ammo", "Medium Ammo", "Pistol Ammo", "Shells" },
    Structures = {
        "Ammo Crate",
        "Barbed Wire",
        "Bear Trap",
        "Boost Pad",
        "Electric Fence",
        "Farm Plot",
        "Fence",
        "Floodlight",
        "Gate",
        "Landmine",
        "Map",
        "Repair Drone",
        "Shelf",
        "Teleporter",
        "Time Machine",
        "Turret",
        "Wall",
        "Watchtower",
    },
    Consumables = { "Grenade", "Molotov" },
    Backpacks = { "Basic Backpack", "Good Backpack", "Great Backpack" },
    MiscItems = {
        "Emerald",
        "Gas Mask",
        "Power Armor Arm",
        "Power Armor Core",
        "Radio Tower Part",
        "Blueprint",
        "Military Keycard",
        "Repair Hammer",
        "Suppressor",
    },
    Scrap = { "Scrap" },
}

````

## FILE: data/Locations.lua

````lua
-- HESTIA paths are relative to Workspace. Custom CFrames belong in saved configuration.
return { Spawn = { "SpawnLocation" }, Center = { "Map", "Tiles", "Center" } }

````

## FILE: data/Structures.lua

````lua
return {
    Generator = { FuelAttribute = "Fuel", CapacityAttribute = "MaxFuel" },
    Default = { HealthAttribute = "Health", MaxHealthAttribute = "MaxHealth", RepairTool = "Repair Hammer" },
}

````

## FILE: data/Weapons.lua

````lua
return {
    ["Knife"] = { SwingDelay = 0.25 },
    ["Katana"] = { SwingDelay = 0.3 },
    ["Crowbar"] = { SwingDelay = 0.35 },
    ["Bat"] = { SwingDelay = 0.45 },
    ["Spiked Bat"] = { SwingDelay = 0.45 },
    ["Hatchet"] = { SwingDelay = 0.4 },
    ["Scythe"] = { SwingDelay = 0.4 },
    ["Spear"] = { SwingDelay = 0.4 },
    ["Fire Axe"] = { SwingDelay = 0.55 },
    ["Sledgehammer"] = { SwingDelay = 0.6 },
    ["Chainsaw"] = { SwingDelay = 0.35 },
    ["Riot Shield"] = { SwingDelay = 0.5 },
}

````

## FILE: docs/INTEGRATION.md

````markdown
# HESTIA integration contract

Edit `src/Hooks.lua` in your repository and return an implementation table. `GameAdapter` is the only feature-facing boundary. Hooks execute on the client; use your game's existing request/response API. The server remains responsible for distance, ownership, capacity, resources, target type and cooldown checks.

Methods that change state return `true` only after the server confirms the operation, optionally followed by an actual quantity. On rejection return `false, reason`. Sending a RemoteEvent alone is not confirmation; use your existing acknowledgment mechanism or a validated RemoteFunction. HESTIA cannot revoke a server request already in flight when a task is preempted or unloaded.

| Hook | Arguments | Return |
| --- | --- | --- |
| `CollectItem` | World item Instance | `true, actualQuantity` or `false, reason` |
| `AddFuel` | Generator Model, inventory fuel Instance | `true` or `false, reason` |
| `AttackTarget` | NPC Model | `true` or `false, reason` |
| `StoreItem` | Owned inventory Instance, integer quantity, storage Model | `true, actualQuantity` or failure |
| `RepairStructure` | Structure Model | `true` or failure |
| `UseSurvival` | `Heal`, `Bandage`, `Eat` or `Drink` | `true` or failure |
| `GetInventory` | None | Array of `{Instance, Name, Category, Quantity}` records |
| `InventoryFull` | None | Boolean |
| `GetFuelPercent` | Generator Instance or nil | Number 0–100, or nil when unknown |
| `GetStorage` | None | Storage Model or nil |
| `GetLocation` | Location name | CFrame or nil |
| `Vitals` | None | `{Health=0..100, Hunger=0..100, Thirst=0..100, Bleeding=boolean}` |
| `EquipWeapon` | None | Boolean |
| `Teleport` | CFrame | `true` or failure |
| `SaveConfig` | Namespace, JSON string | `true` or failure |
| `LoadConfig` | Namespace | `true, JSONstring` or failure |

Persistence hooks are provided by the default client entry point. Hooks you supply explicitly take precedence. Inventory defaults to Tools in Backpack/Character. Quantity defaults to one; category comes from `HestiaCategory` or the shared item database. A storage reserve applies per item name, including fuel type.

The complete, working example implementations are in `examples/DemoHooks.lua` and `examples/Demo.server.lua`. Set `Repository.InstallDemo = true` to install them. The demo accepts interactions only in Studio, validates target identity/tags, validates owned tools and quantities, enforces distance and attack cooldowns, and changes state on the server. It is a finite test scene, not a production inventory or combat system.

## Object discovery

Prefer CollectionService tags on the top-level Model, Tool or BasePart:

```text
HESTIA_Enemies
HESTIA_Items
HESTIA_Scrap
HESTIA_Fuel
HESTIA_Structures
HESTIA_Generator
HESTIA_Chest
```

Tagging Scrap or Fuel also registers it as an item. Use one gameplay object per tag, not every descendant part. Set `HestiaCategory` for custom item types. Dynamically tagged objects and streaming additions/removals are tracked by signals. Renaming an object into a semantic category is not the registration API; tag it or update its category attribute.

Fallback folders are `Characters`/`NPCs`/`Enemies`, `DroppedItems`/`Items`/`Drops`, `Structures`/`PlayerStructures`/`Buildings`, and `Storage`/`Storages`. Direct children are treated as objects. Put alternate nested layouts in the adapter or use tags.

Default generator attributes are `Fuel` and `MaxFuel`. Default structure/NPC attributes are `Health` and `MaxHealth`; a Humanoid takes precedence. NPCs must be Models. `Boss = true` enables boss priority. Scrap uses `ScrapValue` for ranking. Change adapter accessors if your experience uses NumberValues or custom data modules.

## Permissions and server authority

Studio permits the client framework for development. In a published experience, set `HESTIA_Enabled` on authorized players from a trusted server script. Set `HESTIA_AllowMovement` separately if your own game supports the movement utilities. These attributes are not substitutes for validation of gameplay requests.

There are no guessed game remotes, injected scripts, hidden-property operations, detection bypasses, client-awarded inventory, or client-authoritative damage in this package. The optional demo RemoteFunction is dedicated to its own test scene. Port its patterns into your own systems only where they match your experience.

## Cleanup ownership

Features own instances, tasks and connections they create. Use `h.Connections:Add(uniqueName, connection)` for connections, `h.Scheduler:Add(name, interval, callback, onError)` for background work, and `h.Tasks:Request/Release` around actions competing for character control. A feature's `Stop`/`Destroy` must release its task even if its target disappears.

Hook implementations must bound their waits and clean up their own extra resources. Avoid unbounded `WaitForChild` calls or unresolved request promises. HESTIA cancels client scheduler coroutines at unload, but cannot undo a committed transaction on your server.

````

## FILE: docs/RAW_URLS.md

````markdown
# HESTIA raw URLs

These URLs become available after uploading the matching files to `YuiPlyz/hestia`, branch `main`, directory `Hestia`.

```text
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/client/Runtime.client.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/data/Enemies.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/data/Items.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/data/Locations.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/data/Structures.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/data/Weapons.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/docs/INTEGRATION.md
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/docs/TESTING.md
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/docs/TREE.md
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/docs/VERIFICATION.md
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/examples/Demo.server.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/examples/DemoHooks.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/loader.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/manifest.json
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/AutoPickup.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/AutoStore.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/Combat.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/ESP.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/FarmWorker.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/Fly.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/FuelFarm.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/Generator.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/ItemESP.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/ItemFarm.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/KillAura.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/Lighting.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/MobESP.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/Movement.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/Noclip.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/NPCTargeting.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/PlayerESP.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/Repair.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/ScrapFarm.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/StructureESP.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/Survival.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/Teleports.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/Utilities.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/README.md
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/server/Runtime.server.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/Config.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/ConfigStore.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/ConfigValidation.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/Connections.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/GameAdapter.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/Hooks.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/Importer.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/Installer.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/Logger.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/Main.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/Navigator.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/Notifications.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/Scheduler.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/Services.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/State.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/TaskManager.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/Version.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/tests/core.spec.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/ui/Combat.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/ui/Dashboard.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/ui/Farming.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/ui/Generator.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/ui/Interface.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/ui/Misc.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/ui/Player.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/ui/Settings.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/ui/Teleports.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/ui/ThemeManager.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/ui/Visuals.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/ui/Widget.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/version.json
```

````

## FILE: docs/TESTING.md

````markdown
# HESTIA verification

## Automated checks

Run `python tools/package.py` followed by `python tools/verify.py`. Official Luau binaries belong in `tools/.bin`. These checks cover syntax and pure/runtime-mocked behavior; they do not simulate Roblox physics or render the GUI.

## Studio smoke test

1. In an empty owned test place, set `InstallDemo = true` in `loader.lua`, install, then Play. Confirm HESTIA loads with all automation off and nine tabs visible.
2. Enable Auto Scrap and Auto Fuel. The demo generator begins at 15%. Fueling should claim priority 90, interrupt scrap movement, collect fuel, return and refuel to at least 90%, then release control to scrap.
3. Disable Auto Fuel while traveling. Its task must disappear and scrap must resume. Move/remove a target while a path is computing; no stale path should move the character afterward.
4. Set the generator to low fuel after removing all fuel objects and tools. Confirm the warning appears, no successes are counted, and farming can resume during the five-second retry backoff.
5. Set Scrap priority to Value. Higher `ScrapValue` objects should be selected first. Add whitelist/blacklist rules and check that blacklisting wins. Block a target with an obstacle to exercise stuck detection, retry limits and target switching.
6. Enable Enemy, Scrap, Fuel and Generator ESP. Change name/distance/health, color and range options. Remove targets and confirm their visuals disappear. Inspect memory/connections after repeated enable/disable cycles.
7. Enable Kill Aura and Auto Equip near the demo Zombie. Check weapon cadence, NPC-only damage and the target outline. Move out of range and confirm combat releases its task.
8. Enable survival controls and collect supplies. Confirm healing/eating/drinking/bandaging occur only with server-owned supplies. Repair the nearby Wall while carrying the demo Repair Hammer.
9. Enable storage, set a scrap reserve smaller than collected inventory, and verify only confirmed excess is removed from inventory. Repeat with a keep rule and per-item minimum quantity.
10. Change walk speed, jump power, sprint, fly and noclip, then disable them and reset the character. Confirm original humanoid values, collision states and AutoRotate are restored. Fly uses WASD, Space and LeftControl.
11. Drag/collapse the widget, adjust opacity/accent, toggle the menu and test a small viewport. Inspect the interface directly in Studio for clipping and touch interaction.
12. Export/import JSON, save/load within the same Play session, and reject invalid thresholds and malformed colors. Save a negative-coordinate location and verify its config round trip. Studio persistence intentionally ends with the session.
13. Unload while navigating, flying and displaying ESP. Confirm no HESTIA GUI/highlights/flight constraints remain, no tasks or client connections remain, and lighting/collision/movement return to prior values.
14. End Play, install with `InstallDemo = false`, connect your game hooks, and repeat interaction checks in your actual experience. Published testing additionally requires server authorization and working DataStore access.

The automated tests were executed during generation. This environment has no Roblox Studio session attached, so the Studio checks and visual inspection above remain to be performed in the experience.

````

## FILE: docs/TREE.md

````markdown
# HESTIA repository tree

```text
Hestia/
├── .gitignore
├── README.md
├── loader.lua
├── manifest.json
├── stylua.toml
├── version.json
├── client/
│   └── Runtime.client.lua
├── data/
│   ├── Enemies.lua
│   ├── Items.lua
│   ├── Locations.lua
│   ├── Structures.lua
│   └── Weapons.lua
├── docs/
│   ├── INTEGRATION.md
│   ├── RAW_URLS.md
│   ├── TESTING.md
│   ├── TREE.md
│   └── VERIFICATION.md
├── examples/
│   ├── Demo.server.lua
│   └── DemoHooks.lua
├── modules/
│   ├── AutoPickup.lua
│   ├── AutoStore.lua
│   ├── Combat.lua
│   ├── ESP.lua
│   ├── FarmWorker.lua
│   ├── Fly.lua
│   ├── FuelFarm.lua
│   ├── Generator.lua
│   ├── ItemESP.lua
│   ├── ItemFarm.lua
│   ├── KillAura.lua
│   ├── Lighting.lua
│   ├── MobESP.lua
│   ├── Movement.lua
│   ├── NPCTargeting.lua
│   ├── Noclip.lua
│   ├── PlayerESP.lua
│   ├── Repair.lua
│   ├── ScrapFarm.lua
│   ├── StructureESP.lua
│   ├── Survival.lua
│   ├── Teleports.lua
│   └── Utilities.lua
├── server/
│   └── Runtime.server.lua
├── src/
│   ├── Config.lua
│   ├── ConfigStore.lua
│   ├── ConfigValidation.lua
│   ├── Connections.lua
│   ├── GameAdapter.lua
│   ├── Hooks.lua
│   ├── Importer.lua
│   ├── Installer.lua
│   ├── Logger.lua
│   ├── Main.lua
│   ├── Navigator.lua
│   ├── Notifications.lua
│   ├── Scheduler.lua
│   ├── Services.lua
│   ├── State.lua
│   ├── TaskManager.lua
│   └── Version.lua
├── tests/
│   └── core.spec.lua
├── tools/
│   ├── generate_content.py
│   ├── package.py
│   └── verify.py
└── ui/
    ├── Combat.lua
    ├── Dashboard.lua
    ├── Farming.lua
    ├── Generator.lua
    ├── Interface.lua
    ├── Misc.lua
    ├── Player.lua
    ├── Settings.lua
    ├── Teleports.lua
    ├── ThemeManager.lua
    ├── Visuals.lua
    └── Widget.lua
```

````

## FILE: docs/VERIFICATION.md

````markdown
# HESTIA verification results

Executed locally using the official Luau 0.740 Windows binaries:

- 63 Luau files compiled successfully.
- 56 manifest modules resolved; dependency graph and literal production imports validated.
- 16 behavioral tests passed: import alias caching, dependency cycles/retry, idempotent unload, priority preemption/resumption, stable tie handling, numeric versions, threshold validation, filter types, saved negative CFrames, interval/color validation, connection cleanup, generator hysteresis, missing-fuel backoff, confirmed-only farm counts, storage navigation continuity and reserve protection.
- Static analysis reported no non-Roblox-global/type errors after review. This is not a full Roblox Studio typecheck.
- Source audit found no old project branding in production code and no unsupported executor runtime calls.

The original source was used for the item catalog, weapon timing and layout fallbacks. Game interactions have explicit owner-supplied hooks; the optional demo supplies a functioning server-validated example.

Not executed here: Roblox Studio Play tests, live DataStore/HTTP integration, physics/navigation under the real map, visual layout inspection, or a GitHub deployment. Follow `docs/TESTING.md` in your experience before release.

````

## FILE: examples/Demo.server.lua

````lua
-- HESTIA isolated Studio smoke-test scene. This script never runs on live servers.
local run = game:GetService("RunService")
if not run:IsStudio() then
    return
end
local players, tags = game:GetService("Players"), game:GetService("CollectionService")
local replicated = game:GetService("ReplicatedStorage")
local packageRoot = replicated:WaitForChild("HESTIA")
local weapons = require(packageRoot.data.Weapons)
local scene = Instance.new("Folder")
scene.Name = "HESTIA Demo"
scene.Parent = workspace
local remote = Instance.new("RemoteFunction")
remote.Name = "HESTIA Demo"
remote.Parent = replicated
local stored, last = {}, {}
local function model(name, position, category, tag)
    local object = Instance.new("Model")
    object.Name = name
    local part = Instance.new("Part")
    part.Name = "Root"
    part.Size = Vector3.new(3, 3, 3)
    part.Anchored = true
    part.Position = position
    part.Color = Color3.fromRGB(145, 90, 255)
    part.Parent = object
    object.PrimaryPart = part
    object:SetAttribute("HestiaCategory", category)
    object.Parent = scene
    if tag then
        tags:AddTag(object, "HESTIA_" .. tag)
    end
    return object
end
local floor = Instance.new("Part")
floor.Name = "HESTIA Floor"
floor.Size = Vector3.new(180, 1, 180)
floor.Position = Vector3.new(0, -0.5, 0)
floor.Anchored = true
floor.Parent = scene
if not workspace:FindFirstChild("SpawnLocation") then
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "SpawnLocation"
    spawn.Position = Vector3.new(0, 1, 0)
    spawn.Anchored = true
    spawn.Parent = scene
end
local generator = model("Generator", Vector3.new(16, 2, 0), "Generator", "Generator")
generator:SetAttribute("Fuel", 15)
generator:SetAttribute("MaxFuel", 100)
local storage = model("Storage", Vector3.new(-16, 2, 0), "Structure")
local structure = model("Wall", Vector3.new(-8, 2, -12), "Structure", "Structures")
structure:SetAttribute("Health", 30)
structure:SetAttribute("MaxHealth", 100)
model("Chest", Vector3.new(-24, 2, 10), "Chest", "Chest")
for i = 1, 10 do
    local scrap =
        model("Scrap", Vector3.new((i % 5) * 8 - 16, 2, 24 + math.floor(i / 5) * 12), "Scrap", "Scrap")
    scrap:SetAttribute("Quantity", i)
    scrap:SetAttribute("ScrapValue", i)
end
for i, name in ipairs({ "Nuclear Fuel", "Refined Fuel", "Fuel", "Fuel" }) do
    model(name, Vector3.new(26, 2, i * 9), "Fuel", "Fuel")
end
for i, name in ipairs({ "Medkit", "Bandage", "MRE", "Bloxiade" }) do
    model(name, Vector3.new(-26, 2, i * 8), i <= 2 and "Medical" or "Food", "Items")
end
local enemy = model("Zombie", Vector3.new(0, 2, -20), "Enemy", "Enemies")
enemy:SetAttribute("Health", 100)
enemy:SetAttribute("MaxHealth", 100)
local function give(player, name, category, quantity)
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        return false
    end
    local existing = backpack:FindFirstChild(name)
    if existing and existing:IsA("Tool") then
        existing:SetAttribute("Quantity", (existing:GetAttribute("Quantity") or 1) + quantity)
        return true
    end
    local tool = Instance.new("Tool")
    tool.Name = name
    tool.RequiresHandle = false
    tool:SetAttribute("HestiaCategory", category)
    tool:SetAttribute("Quantity", quantity)
    tool.Parent = backpack
    return true
end
local function owns(player, item)
    return typeof(item) == "Instance"
        and item:IsA("Tool")
        and (
            (player.Character and item.Parent == player.Character)
            or item.Parent == player:FindFirstChild("Backpack")
        )
end
local function near(player, object, distance)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    return typeof(object) == "Instance"
        and object:IsDescendantOf(scene)
        and object:IsA("Model")
        and object.PrimaryPart
        and root
        and (root.Position - object.PrimaryPart.Position).Magnitude <= distance
end
local function consume(item, quantity)
    local amount = item:GetAttribute("Quantity") or 1
    if amount < quantity then
        return false
    end
    if amount == quantity then
        item:Destroy()
    else
        item:SetAttribute("Quantity", amount - quantity)
    end
    return true
end
local function findTool(player, name)
    local backpack = player:FindFirstChild("Backpack")
    local char = player.Character
    local tool = backpack and backpack:FindFirstChild(name) or char and char:FindFirstChild(name)
    return tool and tool:IsA("Tool") and tool or nil
end
remote.OnServerInvoke = function(player, action, object, value, destination)
    if type(action) ~= "string" then
        return false, "Invalid action"
    end
    local intervals = { Collect = 0.2, Fuel = 0.5, Attack = 0.4, Store = 0.5, Repair = 0.5, Survival = 1 }
    if not intervals[action] then
        return false, "Unsupported action"
    end
    last[player] = last[player] or {}
    local now = os.clock()
    if now - (last[player][action] or -math.huge) < intervals[action] then
        return false, "Cooldown"
    end
    last[player][action] = now
    if action == "Collect" then
        if
            not near(player, object, 8)
            or not (
                tags:HasTag(object, "HESTIA_Items")
                or tags:HasTag(object, "HESTIA_Scrap")
                or tags:HasTag(object, "HESTIA_Fuel")
            )
        then
            return false, "Invalid pickup"
        end
        local backpack = player:FindFirstChild("Backpack")
        if not backpack or #backpack:GetChildren() >= 30 then
            return false, "Inventory full"
        end
        local quantity = object:GetAttribute("Quantity") or 1
        if not give(player, object.Name, object:GetAttribute("HestiaCategory"), quantity) then
            return false, "No backpack"
        end
        object:Destroy()
        return true, quantity
    elseif action == "Fuel" then
        if object ~= generator or not near(player, generator, 8) or not owns(player, value) then
            return false, "Invalid fuel request"
        end
        local fuelValues = { ["Nuclear Fuel"] = 80, ["Refined Fuel"] = 40, Fuel = 20 }
        local amount = fuelValues[value.Name]
        if not amount or not consume(value, 1) then
            return false, "Unsupported fuel"
        end
        generator:SetAttribute("Fuel", math.min(100, generator:GetAttribute("Fuel") + amount))
        return true
    elseif action == "Attack" then
        if
            not near(player, object, 7)
            or not tags:HasTag(object, "HESTIA_Enemies")
            or players:GetPlayerFromCharacter(object)
        then
            return false, "Invalid NPC"
        end
        local weapon = player.Character and player.Character:FindFirstChildOfClass("Tool")
        local data = weapon and weapons[weapon.Name]
        if not data then
            return false, "Equip a weapon"
        end
        if now - (last[player].WeaponAttack or -math.huge) < data.SwingDelay then
            return false, "Weapon cooldown"
        end
        last[player].WeaponAttack = now
        local hp = object:GetAttribute("Health")
        if not hp or hp <= 0 then
            return false, "NPC defeated"
        end
        object:SetAttribute("Health", math.max(0, hp - 20))
        return true
    elseif action == "Store" then
        if
            destination ~= storage
            or not near(player, storage, 8)
            or not owns(player, object)
            or type(value) ~= "number"
            or value ~= value
            or value < 1
            or value % 1 ~= 0
        then
            return false, "Invalid storage request"
        end
        local name = object.Name
        if not consume(object, value) then
            return false, "Insufficient quantity"
        end
        stored[player] = stored[player] or {}
        stored[player][name] = (stored[player][name] or 0) + value
        return true, value
    elseif action == "Repair" then
        if
            not near(player, object, 30)
            or not tags:HasTag(object, "HESTIA_Structures")
            or not findTool(player, "Repair Hammer")
        then
            return false, "Invalid repair"
        end
        object:SetAttribute(
            "Health",
            math.min(object:GetAttribute("MaxHealth"), object:GetAttribute("Health") + 10)
        )
        return true
    elseif action == "Survival" then
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local names = { Heal = "Medkit", Bandage = "Bandage", Eat = "MRE", Drink = "Bloxiade" }
        local tool = names[object] and findTool(player, names[object])
        if not hum or hum.Health <= 0 or not tool or not consume(tool, 1) then
            return false, "Survival supply unavailable"
        end
        if object == "Heal" then
            hum.Health = math.min(hum.MaxHealth, hum.Health + 50)
        elseif object == "Bandage" then
            char:SetAttribute("Bleeding", false)
        elseif object == "Eat" then
            char:SetAttribute("Hunger", 100)
        elseif object == "Drink" then
            char:SetAttribute("Thirst", 100)
        end
        return true
    end
    return false, "Unsupported action"
end
local function setup(player)
    player:SetAttribute("InventoryCapacity", 30)
    local function character(char)
        char:SetAttribute("Hunger", 30)
        char:SetAttribute("Thirst", 30)
        char:SetAttribute("Bleeding", true)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum.Health = 40
        end
        player:WaitForChild("Backpack", 5)
        give(player, "Knife", "Melee", 1)
        give(player, "Repair Hammer", "MiscItems", 1)
    end
    player.CharacterAdded:Connect(character)
    if player.Character then
        task.spawn(character, player.Character)
    end
end
players.PlayerAdded:Connect(setup)
for _, player in ipairs(players:GetPlayers()) do
    setup(player)
end
players.PlayerRemoving:Connect(function(player)
    last[player], stored[player] = nil, nil
end)
print("[HESTIA] Studio demo ready. Enable Auto Scrap and Auto Fuel to test emergency preemption.")

````

## FILE: examples/DemoHooks.lua

````lua
-- HESTIA demo integration, installed only when Repository.InstallDemo is true.
local remote = game:GetService("ReplicatedStorage"):WaitForChild("HESTIA Demo", 10)
assert(remote, "HESTIA demo server is not running")
local function call(action, ...)
    return remote:InvokeServer(action, ...)
end
return {
    CollectItem = function(item)
        return call("Collect", item)
    end,
    AddFuel = function(generator, fuel)
        return call("Fuel", generator, fuel)
    end,
    AttackTarget = function(target)
        return call("Attack", target)
    end,
    StoreItem = function(item, quantity, storage)
        return call("Store", item, quantity, storage)
    end,
    RepairStructure = function(target)
        return call("Repair", target)
    end,
    UseSurvival = function(kind)
        return call("Survival", kind)
    end,
    GetStorage = function()
        local scene = workspace:FindFirstChild("HESTIA Demo")
        return scene and scene:FindFirstChild("Storage")
    end,
}

````

## FILE: loader.lua

````lua
-- HESTIA Studio installer. Paste this file into the Command Bar in Edit mode.
local Repository =
    { Owner = "YuiPlyz", Name = "hestia", Channel = "main", Directory = "Hestia", InstallDemo = false }
local HttpService = game:GetService("HttpService")
assert(
    game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(),
    "HESTIA installer requires Studio Edit mode"
)
assert(
    Repository.Channel == "main" or Repository.Channel == "beta" or Repository.Channel == "dev",
    "HESTIA invalid channel"
)
local base = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/",
    Repository.Owner,
    Repository.Name,
    Repository.Channel
)
local directory = (Repository.Directory or ""):gsub("^/+", ""):gsub("/+$", "")
assert(
    not directory:find("..", 1, true) and (directory == "" or directory:match("^[%w_/%-]+$")),
    "HESTIA invalid repository directory"
)
if directory ~= "" then
    base = base .. directory .. "/"
end
local source, reason
for attempt = 1, 3 do
    local ok, result = pcall(HttpService.GetAsync, HttpService, base .. "src/Installer.lua", true)
    if ok then
        source = result
        break
    end
    reason = result
    if attempt < 3 then
        task.wait(attempt)
    end
end
assert(source, "HESTIA installer download failed: " .. tostring(reason))
local bootstrap = Instance.new("ModuleScript")
bootstrap.Name = "HESTIA Installer"
bootstrap.Source = source
bootstrap.Parent = game:GetService("ServerStorage")
local ok, result = xpcall(function()
    return require(bootstrap).Install(Repository)
end, debug.traceback)
bootstrap:Destroy()
assert(ok, "HESTIA installation failed: " .. tostring(result))
print("[HESTIA] Installed. Start a Play test to launch HESTIA.")

````

## FILE: manifest.json

````json
{
  "name": "HESTIA",
  "version": "1.0.0",
  "modules": {
    "Config": {
      "path": "src/Config.lua",
      "dependencies": [],
      "optional": false
    },
    "ConfigStore": {
      "path": "src/ConfigStore.lua",
      "dependencies": [
        "ConfigValidation"
      ],
      "optional": false
    },
    "ConfigValidation": {
      "path": "src/ConfigValidation.lua",
      "dependencies": [],
      "optional": false
    },
    "Connections": {
      "path": "src/Connections.lua",
      "dependencies": [],
      "optional": false
    },
    "GameAdapter": {
      "path": "src/GameAdapter.lua",
      "dependencies": [
        "Items",
        "Weapons",
        "Enemies",
        "Locations",
        "Structures"
      ],
      "optional": false
    },
    "Hooks": {
      "path": "src/Hooks.lua",
      "dependencies": [],
      "optional": false
    },
    "Importer": {
      "path": "src/Importer.lua",
      "dependencies": [],
      "optional": false
    },
    "Logger": {
      "path": "src/Logger.lua",
      "dependencies": [],
      "optional": false
    },
    "Main": {
      "path": "src/Main.lua",
      "dependencies": [
        "Importer",
        "Config",
        "State",
        "Services",
        "Connections",
        "Logger",
        "Notifications",
        "Scheduler",
        "GameAdapter",
        "TaskManager",
        "Navigator",
        "ConfigStore",
        "ConfigValidation",
        "Interface",
        "Hooks",
        "Version"
      ],
      "optional": false
    },
    "Navigator": {
      "path": "src/Navigator.lua",
      "dependencies": [],
      "optional": false
    },
    "Notifications": {
      "path": "src/Notifications.lua",
      "dependencies": [],
      "optional": false
    },
    "Scheduler": {
      "path": "src/Scheduler.lua",
      "dependencies": [],
      "optional": false
    },
    "Services": {
      "path": "src/Services.lua",
      "dependencies": [],
      "optional": false
    },
    "State": {
      "path": "src/State.lua",
      "dependencies": [],
      "optional": false
    },
    "TaskManager": {
      "path": "src/TaskManager.lua",
      "dependencies": [],
      "optional": false
    },
    "Version": {
      "path": "src/Version.lua",
      "dependencies": [],
      "optional": false
    },
    "AutoPickup": {
      "path": "modules/AutoPickup.lua",
      "dependencies": [],
      "optional": true
    },
    "AutoStore": {
      "path": "modules/AutoStore.lua",
      "dependencies": [],
      "optional": true
    },
    "Combat": {
      "path": "modules/Combat.lua",
      "dependencies": [
        "NPCTargeting",
        "Weapons"
      ],
      "optional": true
    },
    "ESP": {
      "path": "modules/ESP.lua",
      "dependencies": [
        "ItemESP",
        "MobESP",
        "PlayerESP",
        "StructureESP"
      ],
      "optional": true
    },
    "FarmWorker": {
      "path": "modules/FarmWorker.lua",
      "dependencies": [],
      "optional": true
    },
    "Fly": {
      "path": "modules/Fly.lua",
      "dependencies": [],
      "optional": true
    },
    "FuelFarm": {
      "path": "modules/FuelFarm.lua",
      "dependencies": [
        "FarmWorker",
        "Utilities"
      ],
      "optional": true
    },
    "Generator": {
      "path": "modules/Generator.lua",
      "dependencies": [],
      "optional": true
    },
    "ItemESP": {
      "path": "modules/ItemESP.lua",
      "dependencies": [],
      "optional": true
    },
    "ItemFarm": {
      "path": "modules/ItemFarm.lua",
      "dependencies": [
        "FarmWorker",
        "Utilities"
      ],
      "optional": true
    },
    "KillAura": {
      "path": "modules/KillAura.lua",
      "dependencies": [],
      "optional": true
    },
    "Lighting": {
      "path": "modules/Lighting.lua",
      "dependencies": [],
      "optional": true
    },
    "MobESP": {
      "path": "modules/MobESP.lua",
      "dependencies": [],
      "optional": true
    },
    "Movement": {
      "path": "modules/Movement.lua",
      "dependencies": [
        "Fly",
        "Noclip"
      ],
      "optional": true
    },
    "Noclip": {
      "path": "modules/Noclip.lua",
      "dependencies": [],
      "optional": true
    },
    "NPCTargeting": {
      "path": "modules/NPCTargeting.lua",
      "dependencies": [
        "Utilities",
        "Enemies"
      ],
      "optional": true
    },
    "PlayerESP": {
      "path": "modules/PlayerESP.lua",
      "dependencies": [],
      "optional": true
    },
    "Repair": {
      "path": "modules/Repair.lua",
      "dependencies": [],
      "optional": true
    },
    "ScrapFarm": {
      "path": "modules/ScrapFarm.lua",
      "dependencies": [
        "FarmWorker",
        "Utilities"
      ],
      "optional": true
    },
    "StructureESP": {
      "path": "modules/StructureESP.lua",
      "dependencies": [],
      "optional": true
    },
    "Survival": {
      "path": "modules/Survival.lua",
      "dependencies": [],
      "optional": true
    },
    "Teleports": {
      "path": "modules/Teleports.lua",
      "dependencies": [],
      "optional": true
    },
    "Utilities": {
      "path": "modules/Utilities.lua",
      "dependencies": [],
      "optional": true
    },
    "UICombat": {
      "path": "ui/Combat.lua",
      "dependencies": [],
      "optional": false
    },
    "Dashboard": {
      "path": "ui/Dashboard.lua",
      "dependencies": [],
      "optional": false
    },
    "Farming": {
      "path": "ui/Farming.lua",
      "dependencies": [],
      "optional": false
    },
    "UIGenerator": {
      "path": "ui/Generator.lua",
      "dependencies": [],
      "optional": false
    },
    "Interface": {
      "path": "ui/Interface.lua",
      "dependencies": [
        "ThemeManager",
        "Widget"
      ],
      "optional": false
    },
    "Misc": {
      "path": "ui/Misc.lua",
      "dependencies": [],
      "optional": false
    },
    "Player": {
      "path": "ui/Player.lua",
      "dependencies": [],
      "optional": false
    },
    "Settings": {
      "path": "ui/Settings.lua",
      "dependencies": [],
      "optional": false
    },
    "UITeleports": {
      "path": "ui/Teleports.lua",
      "dependencies": [],
      "optional": false
    },
    "ThemeManager": {
      "path": "ui/ThemeManager.lua",
      "dependencies": [],
      "optional": false
    },
    "Visuals": {
      "path": "ui/Visuals.lua",
      "dependencies": [],
      "optional": false
    },
    "Widget": {
      "path": "ui/Widget.lua",
      "dependencies": [],
      "optional": false
    },
    "Enemies": {
      "path": "data/Enemies.lua",
      "dependencies": [],
      "optional": false
    },
    "Items": {
      "path": "data/Items.lua",
      "dependencies": [],
      "optional": false
    },
    "Locations": {
      "path": "data/Locations.lua",
      "dependencies": [],
      "optional": false
    },
    "Structures": {
      "path": "data/Structures.lua",
      "dependencies": [],
      "optional": false
    },
    "Weapons": {
      "path": "data/Weapons.lua",
      "dependencies": [],
      "optional": false
    }
  },
  "entrypoints": {
    "client": "client/Runtime.client.lua",
    "server": "server/Runtime.server.lua"
  }
}

````

## FILE: modules/AutoPickup.lua

````lua
local Pickup = {}
Pickup.__index = Pickup
function Pickup.new(h)
    return setmetatable({ H = h, Cooldowns = setmetatable({}, { __mode = "k" }) }, Pickup)
end
function Pickup:TryCollect(item)
    local h, c = self.H, self.H.Config.Farming
    if
        not h.Tasks:IsOwner("AutoPickup")
        or not h.Adapter:Valid(item)
        or h.Adapter:Distance(item) > c.PickupRadius
        or h.Adapter:InventoryFull()
    then
        return false
    end
    if (self.Cooldowns[item] or 0) > os.clock() then
        return false
    end
    if
        not h:Import("Utilities").Allowed(
            item.Name,
            h.Adapter:Category(item),
            c.PickupWhitelist,
            c.PickupBlacklist,
            not c.AllItems and c.PickupCategories or nil
        )
    then
        return false
    end
    self.Cooldowns[item] = os.clock() + math.max(c.PickupDelay, 1)
    local ok, quantity = h.Adapter:CollectItem(item)
    if ok then
        h.State.Stats.Pickups = h.State.Stats.Pickups + (type(quantity) == "number" and quantity or 1)
    end
    return ok
end
function Pickup:Start()
    self.H.Scheduler:Add("AutoPickup", 0.2, function()
        local h = self.H
        if os.clock() < (self.NextCollect or 0) then
            return
        end
        if not h.Tasks:Request("AutoPickup", 30) then
            return
        end
        for object in pairs(h.Registry.Items) do
            if self:TryCollect(object) then
                self.NextCollect = os.clock() + h.Config.Farming.PickupDelay
                break
            end
        end
        h.Tasks:Release("AutoPickup")
    end, function()
        self:Stop()
    end)
end
function Pickup:Stop()
    self.H.Scheduler:Remove("AutoPickup")
    self.H.Tasks:Release("AutoPickup")
end
Pickup.Destroy = Pickup.Stop
return Pickup

````

## FILE: modules/AutoStore.lua

````lua
local Store = {}
Store.__index = Store
function Store.new(h)
    return setmetatable({ H = h }, Store)
end
function Store:Step()
    local h, config = self.H, self.H.Config.Storage
    if config.OnlyWhenFull and not h.Adapter:InventoryFull() then
        h.Tasks:Release("AutoStore")
        h.Navigator:Cancel("AutoStore")
        return
    end
    local storage = h.Adapter:GetStorage()
    if not storage then
        self.Status = "Storage unavailable"
        h.Tasks:Release("AutoStore")
        h.Navigator:Cancel("AutoStore")
        return
    end
    local totals, selected, amount = {}, nil, nil
    local inventory = h.Adapter:GetInventory()
    for _, item in ipairs(inventory) do
        totals[item.Name] = (totals[item.Name] or 0) + item.Quantity
    end
    for _, item in ipairs(inventory) do
        if config.Categories[item.Category] and not config.Keep[item.Name] then
            local reserve = config.Minimum[item.Name] or 0
            if item.Category == "Scrap" then
                reserve = math.max(reserve, config.ScrapReserve)
            end
            if item.Category == "Fuel" then
                reserve = math.max(reserve, config.FuelReserve)
            end
            local excess = math.min(item.Quantity, totals[item.Name] - reserve)
            if excess > 0 then
                selected, amount = item.Instance, excess
                break
            end
        end
    end
    if not selected then
        self.Status = "Nothing to store"
        h.Tasks:Release("AutoStore")
        h.Navigator:Cancel("AutoStore")
        return
    end
    if not h.Tasks:Request("AutoStore", h.Adapter:InventoryFull() and 55 or 35) then
        self.Status = "Paused"
        return
    end
    self.Status = h.Navigator:Step("AutoStore", storage, 5)
    if self.Status == "Arrived" and h.Tasks:IsOwner("AutoStore") then
        local ok, confirmed = h.Adapter:StoreItem(selected, amount, storage)
        if ok then
            h.State.Stats.Stored = h.State.Stats.Stored
                + (type(confirmed) == "number" and confirmed or amount)
        end
        h.Tasks:Release("AutoStore")
    end
end
function Store:Start()
    self.H.Scheduler:Add("AutoStore", 0.5, function()
        self:Step()
    end, function()
        self:Stop()
    end)
end
function Store:Stop()
    self.H.Scheduler:Remove("AutoStore")
    self.H.Tasks:Release("AutoStore")
    self.H.Navigator:Cancel("AutoStore")
end
Store.Destroy = Store.Stop
return Store

````

## FILE: modules/Combat.lua

````lua
local Combat = {}
Combat.__index = Combat
function Combat.new(h)
    return setmetatable({ H = h, LastAttack = 0 }, Combat)
end
function Combat:GetEnemies()
    return self.H.Adapter:GetEnemies()
end
function Combat:GetTarget()
    return self.H:Import("NPCTargeting").Select(self.H)
end
function Combat:AttackTarget(target)
    local h = self.H
    if not h.Adapter:Valid(target) or h.Adapter:Distance(target) > h.Config.Combat.Range then
        return false
    end
    local hp = h.Adapter:Health(target)
    if not hp or hp <= 0 then
        return false
    end
    if h.Config.Combat.AutoEquip then
        h.Adapter:EquipWeapon()
    end
    local character = h.Adapter:Character()
    local tool = character and character:FindFirstChildOfClass("Tool")
    local data = tool and h:Import("Weapons")[tool.Name]
    local delay = math.max(h.Config.Combat.AttackDelay, data and data.SwingDelay or 0.4)
    if os.clock() - self.LastAttack < delay then
        return false
    end
    self.LastAttack = os.clock()
    local ok = h.Adapter:AttackTarget(target)
    if ok then
        h.State.Stats.Attacks = h.State.Stats.Attacks + 1
    end
    return ok
end
function Combat:Step()
    local h = self.H
    self.Target = self:GetTarget()
    if not self.Target then
        h.Tasks:Release("Combat")
    end
    if self.Indicator then
        self.Indicator:Destroy()
        self.Indicator = nil
    end
    if not self.Target then
        return
    end
    if h.Config.Combat.PauseFarming then
        if not h.Tasks:Request("Combat", 80) then
            return
        end
    else
        h.Tasks:Release("Combat")
    end
    if h.Config.Combat.TargetIndicator then
        self.Indicator = Instance.new("Highlight")
        self.Indicator.Name = "HESTIA Target"
        self.Indicator.Adornee = self.Target
        self.Indicator.FillTransparency = 1
        self.Indicator.OutlineColor = Color3.fromRGB(255, 170, 100)
        self.Indicator.Parent = h.UI.Gui
    end
    if self.Target:GetAttribute("Boss") or h:Import("Enemies")[self.Target.Name] == "Boss" then
        h.Notifications:Send("Boss detected.", "HESTIA Combat", "Boss", 30)
    end
    self:AttackTarget(self.Target)
end
function Combat:Start()
    self.H.Scheduler:Add("Combat", 0.1, function()
        self:Step()
    end, function()
        self:Stop()
    end)
end
function Combat:Stop()
    self.H.Scheduler:Remove("Combat")
    self.H.Tasks:Release("Combat")
    self.Target = nil
    if self.Indicator then
        self.Indicator:Destroy()
        self.Indicator = nil
    end
end
Combat.Destroy = Combat.Stop
return Combat

````

## FILE: modules/ESP.lua

````lua
local ESP = {}
ESP.__index = ESP
function ESP.new(h)
    return setmetatable({ H = h, Providers = {}, Objects = {}, Cursor = 1, Queue = {} }, ESP)
end
function ESP:Register(name, provider)
    self.Providers[name] = provider
end
function ESP:Remove(object)
    local record = self.Objects[object]
    if record then
        record.Highlight:Destroy()
        record.Gui:Destroy()
        self.Objects[object] = nil
    end
end
function ESP:Create(object, category)
    local root = self.H.Adapter:Root(object)
    if not root then
        return
    end
    local highlight = Instance.new("Highlight")
    highlight.Name = "HESTIA " .. category
    highlight.Adornee = object
    highlight.FillTransparency = 0.75
    highlight.Parent = self.H.UI.Gui
    local gui = Instance.new("BillboardGui")
    gui.Name = "HESTIA " .. category
    gui.Adornee = root
    gui.Size = UDim2.fromOffset(180, 48)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    gui.Parent = self.H.UI.Gui
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextStrokeTransparency = 0.4
    label.Parent = gui
    self.Objects[object] = { Highlight = highlight, Gui = gui, Label = label, Category = category }
end
function ESP:Reconcile()
    local desired = {}
    for _, provider in pairs(self.Providers) do
        for object, category in pairs(provider()) do
            local config = self.H.Config.Visuals.Categories[category]
            if
                config
                and config.Enabled
                and self.H.Adapter:Valid(object)
                and self.H.Adapter:Distance(object)
                    <= math.min(config.MaxDistance, self.H.Config.Visuals.MaxDistance)
            then
                desired[object] = category
            end
        end
    end
    for object, record in pairs(self.Objects) do
        if desired[object] ~= record.Category then
            self:Remove(object)
        end
    end
    table.clear(self.Queue)
    for object, category in pairs(desired) do
        if not self.Objects[object] then
            self:Create(object, category)
        end
        table.insert(self.Queue, object)
    end
    self.Cursor = math.min(self.Cursor, math.max(1, #self.Queue))
end
function ESP:Update()
    local h = self.H
    -- At most 100 objects per tick; large populations rotate through the queue.
    for _ = 1, math.min(100, #self.Queue) do
        local object = self.Queue[self.Cursor]
        self.Cursor = self.Cursor % #self.Queue + 1
        local record = self.Objects[object]
        if record then
            if not h.Adapter:Valid(object) then
                self:Remove(object)
            else
                local c = h.Config.Visuals.Categories[record.Category]
                local distance = h.Adapter:Distance(object)
                local visible = c.Enabled
                    and distance <= math.min(c.MaxDistance, h.Config.Visuals.MaxDistance)
                local color = Color3.fromRGB(table.unpack(c.Color))
                record.Highlight.Enabled = visible and c.Highlight
                record.Highlight.FillColor, record.Highlight.OutlineColor = color, color
                record.Gui.Enabled = visible and (c.Name or c.Distance or c.Health)
                record.Gui.Adornee = h.Adapter:Root(object)
                record.Label.TextColor3 = color
                local text = {}
                if c.Name then
                    table.insert(text, object.Name)
                end
                if c.Distance then
                    table.insert(text, string.format("%.0f studs", distance))
                end
                local hp, maximum = h.Adapter:Health(object)
                if c.Health and hp and maximum then
                    table.insert(text, string.format("%.0f/%.0f HP", hp, maximum))
                end
                record.Label.Text = table.concat(text, "  ")
            end
        end
    end
end
function ESP:Start()
    for _, provider in ipairs({ "ItemESP", "MobESP", "PlayerESP", "StructureESP" }) do
        self.H:Import(provider).Register(self, self.H)
    end
    self.H.Scheduler:Add("ESP.Registry", 0.5, function()
        self:Reconcile()
    end, function()
        self:Stop()
    end)
    self.H.Scheduler:Add("ESP.Update", 0.1, function()
        self:Update()
    end, function()
        self:Stop()
    end)
end
function ESP:Stop()
    self.H.Scheduler:Remove("ESP.Registry")
    self.H.Scheduler:Remove("ESP.Update")
    for object in pairs(self.Objects) do
        self:Remove(object)
    end
    table.clear(self.Queue)
end
ESP.Destroy = ESP.Stop
return ESP

````

## FILE: modules/FarmWorker.lua

````lua
local Worker = {}
Worker.__index = Worker
function Worker.new(h, name, options)
    return setmetatable({
        H = h,
        Name = name,
        Options = options,
        Rejected = setmetatable({}, { __mode = "k" }),
        Collected = 0,
    }, Worker)
end
function Worker:FindNearest()
    return self:Find(false)
end
function Worker:FindBest()
    return self:Find(true)
end
function Worker:Find(best)
    local h, options = self.H, self.Options
    return h:Import("Utilities").Nearest(h, h.Registry[options.Registry], options.Radius(), function(object)
        return (self.Rejected[object] or 0) < os.clock() and (not options.Filter or options.Filter(object))
    end, best and function(object, distance)
        return -(tonumber(object:GetAttribute("ScrapValue")) or 1) * 100000 + distance
    end or nil)
end
function Worker:SetTarget(target)
    self.Target = target
    self.H.Navigator:Cancel(self.Name)
end
function Worker:Collect(target)
    if not self.H.Tasks:IsOwner(self.Name) or not self.H.Adapter:Valid(target) then
        return false
    end
    local ok, quantity = self.H.Adapter:CollectItem(target)
    if ok then
        local amount = type(quantity) == "number" and math.max(tonumber(quantity) or 0, 0) or 1
        self.Collected = self.Collected + amount
        if self.Options.Stat then
            self.H.State.Stats[self.Options.Stat] = self.H.State.Stats[self.Options.Stat] + amount
        end
    end
    self.Rejected[target] = os.clock() + (ok and 5 or 10)
    return ok
end
function Worker:Step()
    local h = self.H
    if self.Options.Ready and not self.Options.Ready() then
        h.Tasks:Release(self.Name)
        h.Navigator:Cancel(self.Name)
        self.Status = "Waiting"
        return
    end
    if not self.Target or not h.Adapter:Valid(self.Target) then
        self.Target = self.Options.Best and self.Options.Best() and self:FindBest() or self:FindNearest()
    end
    if not self.Target then
        h.Tasks:Release(self.Name)
        self.Status = "Searching"
        return
    end
    if not h.Tasks:Request(self.Name, self.Options.Priority) then
        self.Status = "Paused"
        return
    end
    local status = h.Navigator:Step(self.Name, self.Target, 5)
    self.Status = status
    if status == "Arrived" and os.clock() >= (self.NextCollect or 0) then
        local target = self.Target
        self.NextCollect = os.clock() + (self.Options.Delay and self.Options.Delay() or 0.25)
        self:Collect(target)
        self.Target = nil
    elseif status == "Timeout" or status == "Unreachable" or status == "Invalid" then
        self.Rejected[self.Target] = os.clock() + 30
        self.Target = nil
        h.Tasks:Release(self.Name)
    end
end
function Worker:Start()
    if self.Running then
        return
    end
    self.Running, self.StartedAt, self.Status = true, os.clock(), "Searching"
    self.H.Scheduler:Add(self.Name, 0.25, function()
        self:Step()
    end, function()
        self:Stop()
    end)
end
function Worker:Stop()
    self.Running, self.Target, self.Status = false, nil, "Disabled"
    self.H.Scheduler:Remove(self.Name)
    self.H.Tasks:Release(self.Name)
    self.H.Navigator:Cancel(self.Name)
end
Worker.Destroy = Worker.Stop
return Worker

````

## FILE: modules/Fly.lua

````lua
local Fly = {}
Fly.__index = Fly
function Fly.new(h)
    return setmetatable({ H = h }, Fly)
end
function Fly:Step()
    local h, root, hum = self.H, self.H.Adapter:Root(self.H.Adapter:Character()), self.H.Adapter:Humanoid()
    if self.Root ~= root then
        self:Stop()
    end
    if not root or not hum then
        return
    end
    if not self.Velocity then
        self.Root, self.Humanoid, self.AutoRotate = root, hum, hum.AutoRotate
        self.Attachment = Instance.new("Attachment")
        self.Attachment.Name = "HESTIA Flight"
        self.Attachment.Parent = root
        self.Velocity = Instance.new("LinearVelocity")
        self.Velocity.Attachment0 = self.Attachment
        self.Velocity.MaxForce = math.huge
        self.Velocity.RelativeTo = Enum.ActuatorRelativeTo.World
        self.Velocity.Parent = root
        hum.AutoRotate = false
    end
    local input, camera = h.Services.UserInputService, workspace.CurrentCamera
    local direction = Vector3.zero
    if not input:GetFocusedTextBox() and camera then
        if input:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + camera.CFrame.LookVector
        end
        if input:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - camera.CFrame.LookVector
        end
        if input:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + camera.CFrame.RightVector
        end
        if input:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - camera.CFrame.RightVector
        end
        if input:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + Vector3.yAxis
        end
        if input:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction = direction - Vector3.yAxis
        end
    end
    self.Velocity.VectorVelocity = direction.Magnitude > 0 and direction.Unit * h.Config.Player.FlySpeed
        or Vector3.zero
end
function Fly:Stop()
    if self.Velocity then
        self.Velocity:Destroy()
    end
    if self.Attachment then
        self.Attachment:Destroy()
    end
    if self.Humanoid and self.Humanoid.Parent then
        self.Humanoid.AutoRotate = self.AutoRotate
    end
    self.Velocity, self.Attachment, self.Root, self.Humanoid = nil, nil, nil, nil
end
Fly.Destroy = Fly.Stop
return Fly

````

## FILE: modules/FuelFarm.lua

````lua
local FuelFarm = {}
function FuelFarm.new(h)
    return h:Import("FarmWorker").new(h, "FuelFarm", {
        Registry = "Fuel",
        Priority = 40,
        Stat = "Pickups",
        Radius = function()
            return h.Config.Generator.FuelRadius
        end,
        Ready = function()
            local amount = 0
            for _, item in ipairs(h.Adapter:GetInventory()) do
                if item.Category == "Fuel" then
                    amount = amount + item.Quantity
                end
            end
            return amount < h.Config.Farming.FuelReserve and not h.Adapter:InventoryFull()
        end,
    })
end
return FuelFarm

````

## FILE: modules/Generator.lua

````lua
local Generator = {}
Generator.__index = Generator
function Generator.new(h)
    return setmetatable(
        { H = h, Status = "Disabled", Rejected = setmetatable({}, { __mode = "k" }) },
        Generator
    )
end
function Generator:GetInstance()
    return self.H.Adapter:GetGenerator()
end
function Generator:GetFuel()
    local generator = self:GetInstance()
    return generator and generator:GetAttribute("Fuel")
end
function Generator:GetFuelPercent()
    return self.H.Adapter:GetFuelPercent()
end
function Generator:FindBestFuel(inventory)
    local h, ranking = self.H, {}
    for i, name in ipairs(h.Config.Generator.FuelPriority) do
        ranking[name] = i
    end
    if inventory then
        local best, rank = nil, math.huge
        for _, item in ipairs(h.Adapter:GetInventory()) do
            local value = ranking[item.Name] or 100
            if item.Category == "Fuel" and item.Quantity > 0 and value < rank then
                best, rank = item.Instance, value
            end
        end
        return best
    end
    return h:Import("Utilities").Nearest(h, h.Registry.Fuel, h.Config.Generator.FuelRadius, function(object)
        return (self.Rejected[object] or 0) < os.clock()
    end, function(object, distance)
        return (ranking[object.Name] or 100) * 100000 + distance
    end)
end
function Generator:CollectFuel()
    local h = self.H
    if not self.Target or not h.Adapter:Valid(self.Target) then
        self.Target = self:FindBestFuel(false)
    end
    if not self.Target then
        return false, "No available fuel"
    end
    self.CurrentFuel = self.Target.Name
    local result = h.Navigator:Step("Generator", self.Target, 5)
    if result == "Arrived" and h.Tasks:IsOwner("Generator") then
        local target = self.Target
        local ok = h.Adapter:CollectItem(target)
        self.Rejected[target] = os.clock() + (ok and 5 or 15)
        self.Target = nil
        return ok, ok and "Returning" or "Collection rejected"
    elseif result == "Timeout" or result == "Unreachable" then
        self.Rejected[self.Target] = os.clock() + 30
        self.Target = nil
    end
    return false, result
end
function Generator:AddFuel()
    local h, fuel = self.H, self:FindBestFuel(true)
    if not fuel then
        return false, "No inventory fuel"
    end
    self.CurrentFuel = fuel.Name
    local status = h.Navigator:Step("Generator", self:GetInstance(), 5)
    if status == "Arrived" and h.Tasks:IsOwner("Generator") then
        local ok, reason = h.Adapter:AddFuel(self:GetInstance(), fuel)
        if ok then
            return true
        end
        return false, "Fuel insertion rejected: " .. tostring(reason)
    end
    return false, status
end
function Generator:Step()
    local h, config = self.H, self.H.Config.Generator
    local percent = self:GetFuelPercent()
    if not percent then
        self.Status = "Generator unavailable"
        h.Tasks:Release("Generator")
        h.Navigator:Cancel("Generator")
        return
    end
    if percent < config.FuelBelow then
        self.Fueling = true
    end
    if self.Fueling and percent >= config.FuelUntil then
        self.Fueling = false
        h.Tasks:Release("Generator")
        h.Navigator:Cancel("Generator")
        h.Notifications:Send(
            "Generator restored to " .. math.floor(percent) .. "%. Previous automation resumed.",
            "HESTIA Generator",
            "GeneratorRestored",
            10
        )
    end
    if not self.Fueling then
        self.Status = "Stable"
        h.Tasks:Release("Generator")
        return
    end
    local emergency = percent <= config.EmergencyFuel
    if emergency then
        h.Notifications:Send(
            "Fuel at " .. math.floor(percent) .. "%. Emergency fueling started.",
            "HESTIA Generator",
            "EmergencyFuel",
            30
        )
    end
    if os.clock() < (self.Backoff or 0) then
        self.Status = "Waiting for fuel"
        return
    end
    if not h.Tasks:Request("Generator", emergency and 90 or 60) then
        self.Status = "Paused"
        return
    end
    local ownedFuel = self:FindBestFuel(true)
    local ok, reason
    if ownedFuel then
        ok, reason = self:AddFuel()
    else
        ok, reason = self:CollectFuel()
    end
    self.Status = emergency and "EMERGENCY FUELING" or (ownedFuel and "Adding fuel" or "Collecting fuel")
    if
        not ok
        and (
            reason == "No available fuel"
            or reason == "Collection rejected"
            or reason == "Unreachable"
            or reason == "Timeout"
            or (type(reason) == "string" and reason:find("Fuel insertion rejected", 1, true))
            or (type(reason) == "string" and reason:find("Unsupported"))
        )
    then
        self.Status = reason
        self.Backoff = os.clock() + 5
        h.Tasks:Release("Generator")
        h.Navigator:Cancel("Generator")
    end
end
function Generator:Start()
    self.H.Scheduler:Add("Generator", 1, function()
        self:Step()
    end, function()
        self:Stop()
    end)
end
function Generator:Stop()
    self.H.Scheduler:Remove("Generator")
    self.H.Tasks:Release("Generator")
    self.H.Navigator:Cancel("Generator")
    self.Status, self.Target, self.Fueling = "Disabled", nil, false
end
Generator.Destroy = Generator.Stop
return Generator

````

## FILE: modules/ItemESP.lua

````lua
local Provider = {}
function Provider.Register(esp, h)
    esp:Register("Items", function()
        local result = {}
        for object in pairs(h.Registry.Items) do
            result[object] = h.Registry.Scrap[object] and "Scrap"
                or h.Registry.Fuel[object] and "Fuel"
                or h.Adapter:Category(object)
        end
        return result
    end)
end
return Provider

````

## FILE: modules/ItemFarm.lua

````lua
local ItemFarm = {}
function ItemFarm.new(h)
    return h:Import("FarmWorker").new(h, "ItemFarm", {
        Registry = "Items",
        Priority = 40,
        Stat = "Pickups",
        Radius = function()
            return h.Config.Farming.ItemRadius
        end,
        Filter = function(object)
            return h.Config.Farming.ItemCategories[h.Adapter:Category(object)] == true
        end,
        Ready = function()
            return not h.Adapter:InventoryFull()
        end,
    })
end
return ItemFarm

````

## FILE: modules/KillAura.lua

````lua
-- HESTIA facade; Combat owns the single attack scheduler.
local KillAura = {}
function KillAura.new(h)
    return {
        Start = function()
            h:Set("Combat.KillAura", true)
        end,
        Stop = function()
            h:Set("Combat.KillAura", false)
        end,
        GetTarget = function()
            return h.Features.Combat:GetTarget()
        end,
    }
end
return KillAura

````

## FILE: modules/Lighting.lua

````lua
local Lighting = {}
Lighting.__index = Lighting
function Lighting.new(h)
    return setmetatable({ H = h }, Lighting)
end
function Lighting:Restore()
    if self.Original then
        for key, value in pairs(self.Original) do
            self.H.Services.Lighting[key] = value
        end
        self.Original = nil
    end
end
function Lighting:Start()
    self.H.Scheduler:Add("Lighting", 0.5, function()
        if self.H.Config.Visuals.Fullbright then
            local lighting = self.H.Services.Lighting
            if not self.Original then
                self.Original = {
                    Brightness = lighting.Brightness,
                    ClockTime = lighting.ClockTime,
                    Ambient = lighting.Ambient,
                }
            end
            lighting.Brightness = 2
            lighting.ClockTime = 14
            lighting.Ambient = Color3.fromRGB(170, 170, 180)
        else
            self:Restore()
        end
    end, function()
        self:Restore()
    end)
end
function Lighting:Destroy()
    self.H.Scheduler:Remove("Lighting")
    self:Restore()
end
return Lighting

````

## FILE: modules/MobESP.lua

````lua
local Provider = {}
function Provider.Register(esp, h)
    esp:Register("Enemies", function()
        local result = {}
        for object in pairs(h.Registry.Enemies) do
            local hp = h.Adapter:Health(object)
            if hp and hp > 0 then
                result[object] = "Enemy"
            end
        end
        return result
    end)
end
return Provider

````

## FILE: modules/Movement.lua

````lua
local Movement = {}
Movement.__index = Movement
function Movement.new(h)
    return setmetatable({ H = h, Fly = h:Import("Fly").new(h), Noclip = h:Import("Noclip").new(h) }, Movement)
end
function Movement:Restore()
    if self.Humanoid and self.Humanoid.Parent and self.Original then
        for key, value in pairs(self.Original) do
            self.Humanoid[key] = value
        end
    end
    self.Humanoid, self.Original = nil, nil
end
function Movement:Step()
    local h, c = self.H, self.H.Config.Player
    if not h.Adapter:CanUseMovement() then
        self:Restore()
        self.Fly:Stop()
        self.Noclip:Stop()
        return
    end
    local hum = h.Adapter:Humanoid()
    if self.Humanoid ~= hum then
        self:Restore()
    end
    if hum and (c.OverrideMovement or c.AutoSprint) then
        if not self.Original then
            self.Humanoid = hum
            self.Original =
                { WalkSpeed = hum.WalkSpeed, JumpPower = hum.JumpPower, UseJumpPower = hum.UseJumpPower }
        end
        hum.WalkSpeed = c.AutoSprint and c.SprintSpeed
            or (c.OverrideMovement and c.WalkSpeed or self.Original.WalkSpeed)
        hum.UseJumpPower = c.OverrideMovement or self.Original.UseJumpPower
        hum.JumpPower = c.OverrideMovement and c.JumpPower or self.Original.JumpPower
    else
        self:Restore()
    end
    if c.Fly then
        if h.Tasks:Request("ManualFlight", 110) then
            self.Fly:Step()
        else
            self.Fly:Stop()
        end
    else
        h.Tasks:Release("ManualFlight")
        self.Fly:Stop()
    end
    if c.Noclip then
        self.Noclip:Step()
    else
        self.Noclip:Stop()
    end
    if hum and c.BunnyHop and hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end
end
function Movement:Start()
    self.H.Connections:Add(
        "HESTIA.Movement",
        self.H.Services.RunService.PreSimulation:Connect(function()
            self:Step()
        end)
    )
    self.H.Connections:Add(
        "HESTIA.Jump",
        self.H.Services.UserInputService.JumpRequest:Connect(function()
            local hum = self.H.Adapter:Humanoid()
            if hum and self.H.Config.Player.InfiniteJump and self.H.Adapter:CanUseMovement() then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    )
end
function Movement:Reset()
    local c = self.H.Config.Player
    for _, key in ipairs({ "AutoSprint", "InfiniteJump", "Noclip", "Fly", "OverrideMovement", "BunnyHop" }) do
        c[key] = false
    end
    self:Restore()
    self.Fly:Stop()
    self.Noclip:Stop()
    self.H.Tasks:Release("ManualFlight")
end
function Movement:Stop()
    self:Reset()
    self.H.Connections:Remove("HESTIA.Movement")
    self.H.Connections:Remove("HESTIA.Jump")
end
Movement.Destroy = Movement.Stop
return Movement

````

## FILE: modules/Noclip.lua

````lua
local Noclip = {}
Noclip.__index = Noclip
function Noclip.new(h)
    return setmetatable({ H = h, Original = {} }, Noclip)
end
function Noclip:Step()
    local char = self.H.Adapter:Character()
    if self.Character ~= char then
        self:Stop()
        self.Character = char
    end
    if not char then
        return
    end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if self.Original[part] == nil then
                self.Original[part] = part.CanCollide
            end
            part.CanCollide = false
        end
    end
end
function Noclip:Stop()
    for part, value in pairs(self.Original) do
        if part.Parent then
            part.CanCollide = value
        end
    end
    table.clear(self.Original)
    self.Character = nil
end
Noclip.Destroy = Noclip.Stop
return Noclip

````

## FILE: modules/NPCTargeting.lua

````lua
local Targeting = {}
function Targeting.Select(h)
    local config = h.Config.Combat
    return h:Import("Utilities").Nearest(h, h.Adapter:GetEnemies(), config.Range, function(object)
        if not object:IsA("Model") then
            return false
        end
        local hp = h.Adapter:Health(object)
        return hp ~= nil and hp > 0 and not h.Services.Players:GetPlayerFromCharacter(object)
    end, function(object, distance)
        local hp = h.Adapter:Health(object)
        local score = distance
        if config.Priority == "LowestHP" then
            score = hp
        elseif config.Priority == "HighestHP" then
            score = -hp
        end
        local boss = object:GetAttribute("Boss") or h:Import("Enemies")[object.Name] == "Boss"
        return score - (config.BossPriority and boss and 10000000 or 0)
    end)
end
return Targeting

````

## FILE: modules/PlayerESP.lua

````lua
local Provider = {}
function Provider.Register(esp, h)
    esp:Register("Players", function()
        local result = {}
        for _, player in ipairs(h.Services.Players:GetPlayers()) do
            if player ~= h.Services.Players.LocalPlayer and player.Character then
                result[player.Character] = "Player"
            end
        end
        return result
    end)
end
return Provider

````

## FILE: modules/Repair.lua

````lua
local Repair = {}
Repair.__index = Repair
function Repair.new(h)
    return setmetatable({ H = h, Last = 0 }, Repair)
end
function Repair:Step()
    local h, config = self.H, self.H.Config.Repair
    if os.clock() - self.Last < config.Rate then
        return
    end
    h.Tasks:Release("Repair")
    if not h.Adapter:HasRepairEquipment() then
        self.Status = "Repair equipment unavailable"
        return
    end
    local target = h:Import("Utilities").Nearest(h, h.Registry.Structures, config.Radius, function(object)
        local hp, maximum = h.Adapter:Health(object)
        return hp and maximum and hp > 0 and hp < maximum
    end, function(object, distance)
        local hp, maximum = h.Adapter:Health(object)
        return config.Priority == "LowestHealth" and hp / maximum or distance
    end)
    self.Target = target
    if not target then
        self.Status = "Stable"
        return
    end
    local hp, maximum = h.Adapter:Health(target)
    self.Status = string.format("%s  %.0f/%.0f", target.Name, hp, maximum)
    local priority = config.Emergency and hp / maximum * 100 <= config.EmergencyBelow and 85 or 60
    if not h.Tasks:Request("Repair", priority) then
        return
    end
    self.Last = os.clock()
    if h.Adapter:RepairStructure(target) then
        h.State.Stats.Repairs = h.State.Stats.Repairs + 1
    end
    h.Tasks:Release("Repair")
end
function Repair:Start()
    self.H.Scheduler:Add("Repair", 0.2, function()
        self:Step()
    end, function()
        self:Stop()
    end)
end
function Repair:Stop()
    self.H.Scheduler:Remove("Repair")
    self.H.Tasks:Release("Repair")
end
Repair.Destroy = Repair.Stop
return Repair

````

## FILE: modules/ScrapFarm.lua

````lua
local ScrapFarm = {}
function ScrapFarm.new(h)
    local config = h.Config.Farming
    return h:Import("FarmWorker").new(h, "ScrapFarm", {
        Registry = "Scrap",
        Priority = 50,
        Stat = "Scrap",
        Radius = function()
            return config.ScrapRadius
        end,
        Delay = function()
            return config.ScrapDelay
        end,
        Best = function()
            return config.ScrapPriority == "Value"
        end,
        Filter = function(object)
            return h:Import("Utilities")
                .Allowed(object.Name, "Scrap", config.ScrapWhitelist, config.ScrapBlacklist)
        end,
        Ready = function()
            return not h.Adapter:InventoryFull()
        end,
    })
end
return ScrapFarm

````

## FILE: modules/StructureESP.lua

````lua
local Provider = {}
function Provider.Register(esp, h)
    esp:Register("Structures", function()
        local result = {}
        for object in pairs(h.Registry.Structures) do
            result[object] = "Structure"
        end
        for object in pairs(h.Registry.Chest) do
            result[object] = "Chest"
        end
        for object in pairs(h.Registry.Generator) do
            result[object] = "Generator"
        end
        return result
    end)
end
return Provider

````

## FILE: modules/Survival.lua

````lua
local Survival = {}
Survival.__index = Survival
function Survival.new(h)
    return setmetatable({ H = h }, Survival)
end
function Survival:Step()
    local h, config = self.H, self.H.Config.Survival
    local v = h.Adapter:Vitals()
    local kind
    if config.AutoHeal and v.Health < config.HealBelow then
        kind = "Heal"
    elseif config.AutoBandage and v.Bleeding then
        kind = "Bandage"
    elseif config.AutoEat and v.Hunger < config.EatBelow then
        kind = "Eat"
    elseif config.AutoDrink and v.Thirst < config.DrinkBelow then
        kind = "Drink"
    end
    if not kind then
        h.Tasks:Release("Survival")
        self.Status = "Stable"
        return
    end
    local emergency = v.Health <= config.EmergencyHealth
    if not h.Tasks:Request("Survival", emergency and 100 or 70) then
        self.Status = "Paused"
        return
    end
    self.Status = kind
    h.Adapter:UseSurvival(kind)
    h.Tasks:Release("Survival")
end
function Survival:Start()
    self.H.Scheduler:Add("Survival", 1, function()
        self:Step()
    end, function()
        self:Stop()
    end)
end
function Survival:Stop()
    self.H.Scheduler:Remove("Survival")
    self.H.Tasks:Release("Survival")
end
Survival.Destroy = Survival.Stop
return Survival

````

## FILE: modules/Teleports.lua

````lua
local Teleports = {}
Teleports.__index = Teleports
function Teleports.new(h)
    return setmetatable({ H = h }, Teleports)
end
function Teleports:Save(name)
    assert(
        type(name) == "string" and #name > 0 and #name <= 64,
        "HESTIA location name must be 1-64 characters"
    )
    local root = self.H.Adapter:Root(self.H.Adapter:Character())
    if root then
        self.H.Config.Teleports.Saved[name] = { root.CFrame:GetComponents() }
        return true
    end
    return false
end
function Teleports:Resolve(name)
    local h = self.H
    local saved = h.Config.Teleports.Saved[name]
    if saved then
        return CFrame.new(table.unpack(saved))
    end
    if name == "Spawn" then
        return h.Adapter:GetLocation("Spawn")
    end
    local object
    if name == "Generator" then
        object = h.Adapter:GetGenerator()
    elseif name == "Selected Player" then
        local player = h.Services.Players:FindFirstChild(h.Config.Teleports.SelectedPlayer)
        object = player and player.Character
    else
        local set = ({
            ["Nearest Scrap"] = "Scrap",
            ["Nearest Fuel"] = "Fuel",
            ["Nearest Chest"] = "Chest",
            ["Nearest Enemy"] = "Enemies",
        })[name]
        if set then
            object = h:Import("Utilities").Nearest(h, h.Registry[set], math.huge)
        end
    end
    local root = h.Adapter:Root(object)
    return root and root.CFrame + Vector3.new(0, 4, 0)
end
function Teleports:Go(name)
    local target = self:Resolve(name)
    if not target then
        return false, "Location unavailable: " .. name
    end
    self.H.Tasks:Request("Teleport", 120)
    local ok, reason = self.H.Adapter:Teleport(target)
    self.H.Tasks:Release("Teleport")
    return ok, reason
end
return Teleports

````

## FILE: modules/Utilities.lua

````lua
local Utilities = {}
function Utilities.Allowed(name, category, whitelist, blacklist, categories)
    if blacklist and blacklist[name] then
        return false
    end
    if whitelist and next(whitelist) and not whitelist[name] then
        return false
    end
    if categories and next(categories) and not categories[category] then
        return false
    end
    return true
end
function Utilities.Nearest(h, registry, radius, predicate, score)
    local best, value = nil, math.huge
    for object in pairs(registry) do
        if h.Adapter:Valid(object) then
            local distance = h.Adapter:Distance(object)
            if distance <= radius and (not predicate or predicate(object)) then
                local rank = score and score(object, distance) or distance
                if rank < value then
                    best, value = object, rank
                end
            end
        end
    end
    return best
end
function Utilities.Duration(seconds)
    return string.format(
        "%02d:%02d:%02d",
        math.floor(seconds / 3600),
        math.floor(seconds / 60) % 60,
        math.floor(seconds) % 60
    )
end
function Utilities.Count(set)
    local count = 0
    for _ in pairs(set) do
        count = count + 1
    end
    return count
end
return Utilities

````

## FILE: README.md

````markdown
# HESTIA

A modular Roblox survival-game utility framework for experiences you own and test.

HESTIA includes a charcoal and violet interface, farming and generator automation, NPC combat, survival routines, centralized ESP, movement utilities, saved locations, and priority-based character control. All automation starts disabled.

## Structure

The full repository tree is in [docs/TREE.md](docs/TREE.md). The code is divided by responsibility:

| Directory | Responsibility |
| --- | --- |
| `loader.lua` | Small Studio Command Bar installer; repository settings live here |
| `src/` | Lifecycle, importer, configuration, adapter, registries, navigation, scheduling |
| `modules/` | Independently replaceable gameplay and visual features |
| `ui/` | Native Roblox interface, nine tabs, theme manager and floating widget |
| `data/` | Shared item catalog, weapon timing, enemies, structures and location paths |
| `client/` | Client entry point |
| `server/` | Per-player config persistence and one startup update check |
| `examples/` | Optional Studio test scene and validated interaction hooks |
| `tests/` | Executable behavioral regression tests |
| `tools/` | Verification, manifest and release packaging |

## Installation

1. Upload the extracted `Hestia` folder to `YuiPlyz/hestia` on branch `main`. Keep the folder itself, so the GitHub path is `Hestia/loader.lua`. This delivery does not upload changes to GitHub.
2. Open your own experience in Roblox Studio, in **Edit mode**. Enable **Allow HTTP Requests** in Game Settings → Security.
3. Open `Hestia/loader.lua` on GitHub (or the local `loader.lua`). Its `Repository` table sets the owner, repository, branch and `Directory = "Hestia"`. Use `Directory = ""` if you later move files to the repository root. To install the optional test scene, set `InstallDemo = true`.
4. Paste the complete contents of `loader.lua` into Studio's Command Bar and run it.
5. Start a Play test. HESTIA opens automatically; `RightShift` toggles the menu. The small **H** button also opens it on touch devices.

The installer downloads each path once, caches responses for that installation, retries failed downloads three times, validates manifest dependencies, and stages the complete package before replacing an existing HESTIA installation. Required download failures leave the old installation intact. Optional feature failures are logged, and the UI can still open. Reinstalling replaces the installed `Hooks` module, so keep custom hook changes in your repository.

Installed objects:

```text
ReplicatedStorage/HESTIA
StarterPlayer/StarterPlayerScripts/HESTIA Client
ServerScriptService/HESTIA Server
ServerScriptService/HESTIA Demo    (only when requested)
```

Normal Roblox client scripts cannot fetch and execute arbitrary Luau via the commonly shown `game:HttpGet` loader pattern. HESTIA downloads code **at Studio installation time**, installs normal ModuleScripts, and uses `require` at runtime. It does not need an executor or client `loadstring`. Roblox documents [HTTP access](https://create.roblox.com/docs/cloud-services/http-service) and [Studio script editing](https://create.roblox.com/docs/reference/engine/classes/ScriptEditorService).

After installation, the minimal application loader is:

```lua
local root = game:GetService("ReplicatedStorage"):WaitForChild("HESTIA")
local Hestia = require(root.src.Main).new(root)
Hestia:Start()
```

The included client entry point already performs startup and adds configuration persistence hooks. Use the snippet only when replacing that entry point. Prefer running the complete `loader.lua` for GitHub installation; it contains retry and diagnostic handling.

## Configuration

Defaults live in `src/Config.lua`. Every UI control edits the same configuration object. JSON filter fields accept objects such as `{"Scrap":true}`; color controls accept `[145,90,255]`; fuel priority accepts a JSON array of item names. Empty whitelists impose no name restriction. Blacklists take precedence. Item-farm category selection is explicit.

Generator thresholds must satisfy `EmergencyFuel <= FuelBelow < FuelUntil <= 100`. The default values are 20, 50 and 90. Once fueling starts it continues until the stop threshold, even after fuel rises above the start threshold.

Settings provides export/import and save/load. The namespace is `HESTIA/survive-the-apocalypse`, backed by the `HESTIA` DataStore in published experiences. Studio tests use session memory and do not require DataStore API access; export JSON to retain a test configuration across Play sessions. Configuration is validated before application and is not automatically loaded with automation enabled.

In a published experience, your server must authorize testers by setting `player:SetAttribute("HESTIA_Enabled", true)`. Movement utilities also require `HESTIA_AllowMovement = true` or a custom adapter implementation. These flags are set by your game server; the package grants them automatically only through the Studio environment check.

## Modules

`Hestia:Import("ScrapFarm")` and `Hestia:Import("modules/ScrapFarm.lua")` resolve the same installed module and return the same cached export. `manifest.json` maps names to exact paths and declares dependencies. Each module exports a stateless factory or helper table. Per-session mutable state belongs to instances created with `.new(hestia)`.

| System | Behavior |
| --- | --- |
| ScrapFarm | Nearest/highest-value search, name filters, retries, timeout, stuck detection, confirmed statistics |
| ItemFarm / FuelFarm | Shared farming worker with category selection and fuel reserve limits |
| Generator | Hysteresis, emergency priority, fuel ranking, pickup/return/insert loop and missing-fuel backoff |
| AutoPickup | Distance, name/category filters, cooldown and confirmed pickup counts |
| AutoStore | Category filters, keep rules, minimum quantities and excess storage |
| Combat / KillAura | NPC-only targeting, boss priority, weapon timing, auto-equip and target highlight |
| Survival | Heal/eat/drink/bandage routines with priority claims |
| Repair | Nearest or lowest-health target, equipment check, rate limit and emergency priority |
| ESP | One renderer with item/NPC/player/structure providers; Highlight and BillboardGui |
| Movement | Sprint, speed/jump settings, flight, noclip and respawn-aware restoration |
| Teleports | Registry targets, selected player, map locations and saved CFrames |
| Lighting | Fullbright with exact restoration of changed properties |

Every actual game interaction is in `src/GameAdapter.lua` and `src/Hooks.lua`. The source game's item catalog, NPC names, weapon timing and layout fallbacks are retained. Its remote invocation mechanisms are not carried over. No game-specific server behavior can be inferred reliably from a client script: connect your experience's legitimate systems using [the integration contract](docs/INTEGRATION.md). Unsupported interactions return a visible diagnostic and never fabricate success.

### UI implementation

The native `ui/Interface.lua` wrapper keeps feature modules independent of the GUI. It implements the requested nine tabs, compact controls, live dashboard, accent changes, menu key, notifications and draggable/collapsible/opacity-adjustable widget.

The upstream [Obsidian library](https://github.com/deividcomsono/Obsidian/blob/main/Library.lua) depends on CoreGui/executor-oriented APIs. HESTIA uses ordinary PlayerGui controls and its own `ui/ThemeManager.lua` and configuration service so it runs inside your experience without those dependencies. This is a deliberate replacement of the UI backend.

### Scheduling and task ownership

One scheduler services independent jobs: combat and ESP at 0.10 seconds, pickup at 0.20, farm/navigation at 0.25, dashboard/statistics and registry reconciliation at 0.50, generator and survival at 1.00. ESP updates a maximum of 100 objects per tick. Large populations therefore rotate through batches. Movement physics has one PreSimulation callback.

Registry initialization scans Workspace once. Folder, ancestry, tag and descendant signals maintain caches afterward. Farm and ESP loops never rescan all Workspace descendants. Noclip examines only the local character.

Movement priorities are survival 100, emergency fuel 90, optional emergency repair 85, combat 80, healing 70, generator/repair 60, full-inventory storage 55, scrap 50, item/fuel farming 40, ordinary storage 35, pickup 30, idle 10. Explicit manual flight (110) and teleport (120) override automation. Lower-priority requests remain queued and resume automatically. Yielding path computations must still possess the original lease before issuing movement.

## Updating

Edit an individual feature's raw file, commit it, and rerun the Studio installer. Code is not hot-replaced during a running session. `main` is stable, `beta` is testing, and `dev` is development; set `Repository.Channel` in the loader accordingly. Set `version.json.channel` on each branch to the matching release label. No branches are created automatically.

The installed `Hestia.Version` is compared numerically with remote version metadata. The server requests version metadata once per startup and shares it with clients. Failed requests log a warning and retain the installation snapshot. Version messages and changelog appear in Settings; checking never runs per frame.

Every resulting raw URL is listed in [docs/RAW_URLS.md](docs/RAW_URLS.md), including:

```text
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/loader.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/Main.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/ScrapFarm.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/Generator.lua
```

## Development

Download the official [Luau Windows release](https://github.com/luau-lang/luau/releases) and place `luau.exe` and `luau-compile.exe` under `tools/.bin/`.

```powershell
python tools/package.py
python tools/verify.py
```

Verification compiles every Luau file, checks manifest dependencies and import paths, and runs behavioral tests for task preemption, generator hysteresis, failure backoff, inventory reserves, config validation and cleanup. The code was checked with Luau 0.740. Full Studio physics, rendering and server interaction tests require Roblox Studio; use [docs/TESTING.md](docs/TESTING.md).

`tools/package.py` regenerates the manifest, complete repository tree and exact URLs, then produces `dist/HESTIA.zip` and `dist/HESTIA-FILES.md`. The Markdown artifact contains every file separately with `FILE: path` headings and complete source.

Unload with `Hestia:Unload()` or the Settings button. The client stops scheduled tasks, releases movement ownership, disconnects its connections, restores modified movement/lighting properties, destroys ESP and UI, and clears registries and its import cache. Roblox's internal `require` cache remains engine-managed; exports contain no mutable session state. The server config endpoint and optional demo scene belong to the installed experience and persist until the Play session ends.

## Changelog

### HESTIA 1.0.0

- Modular GitHub installation and cached imports with dependency diagnostics.
- Unified object registries, navigation, scheduling, task ownership and cleanup.
- Farming, emergency fueling, storage, repair, NPC combat and survival modules.
- Native HESTIA dashboard, consolidated ESP, movement tools and location management.
- Configuration validation/persistence, release channels and changelog metadata.
- Optional Studio demonstration with server-validated actions and regression tests.

````

## FILE: server/Runtime.server.lua

````lua
-- HESTIA server services: startup metadata and per-player configuration only.
local http, replicated = game:GetService("HttpService"), game:GetService("ReplicatedStorage")
local players, run = game:GetService("Players"), game:GetService("RunService")
local root = replicated:WaitForChild("HESTIA")
local remote = Instance.new("RemoteFunction")
remote.Name = "HESTIA Config"
remote.Parent = replicated
local store = game:GetService("DataStoreService"):GetDataStore("HESTIA")
local validator, defaults = require(root.src.ConfigValidation), require(root.src.Config)
local last, memory, busy = {}, {}, {}
local function allowed(player)
    return run:IsStudio() or player:GetAttribute("HESTIA_Enabled") == true
end
remote.OnServerInvoke = function(player, action, folder, raw)
    if not allowed(player) then
        return false, "HESTIA permission required"
    end
    if action ~= "Save" and action ~= "Load" then
        return false, "Invalid action"
    end
    if folder ~= "HESTIA/survive-the-apocalypse" then
        return false, "Invalid config namespace"
    end
    local id = player.UserId
    if busy[id] or os.clock() - (last[id] or -math.huge) < 2 then
        return false, "Please wait before another config request"
    end
    last[id], busy[id] = os.clock(), true
    local ok, value = pcall(function()
        if action == "Save" then
            assert(type(raw) == "string" and #raw <= 60000, "Invalid config size")
            local data = http:JSONDecode(raw)
            assert(data.Schema == 1 and type(data.Config) == "table", "Invalid config schema")
            local clean = http:JSONEncode({ Schema = 1, Config = validator.Validate(data.Config, defaults) })
            if run:IsStudio() then
                memory[id] = clean
            else
                store:SetAsync("survive-the-apocalypse/" .. id, clean)
            end
            return "Saved"
        end
        local saved = run:IsStudio() and memory[id]
            or (not run:IsStudio() and store:GetAsync("survive-the-apocalypse/" .. id))
        assert(type(saved) == "string", "No saved HESTIA configuration")
        return saved
    end)
    busy[id] = nil
    return ok, value
end
players.PlayerRemoving:Connect(function(player)
    last[player.UserId], memory[player.UserId], busy[player.UserId] = nil, nil, nil
end)
-- One HTTP request per server startup, never per frame or per player.
local ok, result = pcall(function()
    local raw = http:GetAsync(root:GetAttribute("BaseURL") .. "version.json", true)
    local version = http:JSONDecode(raw)
    assert(version.name == "HESTIA" and type(version.version) == "string", "Invalid HESTIA version data")
    return raw
end)
if ok then
    root:SetAttribute("RemoteVersion", result)
else
    warn("[HESTIA] Startup version request failed; using installation metadata: " .. tostring(result))
end
root:SetAttribute("VersionReady", true)

````

## FILE: src/Config.lua

````lua
local Config = {
    Debug = false,
    Farming = {
        AutoScrap = false,
        ScrapRadius = 500,
        ScrapDelay = 0.25,
        ScrapPriority = "Nearest",
        ScrapWhitelist = {},
        ScrapBlacklist = {},
        TargetTimeout = 20,
        StuckTimeout = 3,
        PathRetries = 2,
        AutoItems = false,
        ItemRadius = 250,
        ItemCategories = { Medical = true, Resource = true },
        AutoFuelFarm = false,
        FuelReserve = 5,
        AutoPickup = false,
        PickupRadius = 25,
        PickupDelay = 0.2,
        AllItems = true,
        PickupWhitelist = {},
        PickupBlacklist = {},
        PickupCategories = {},
    },
    Generator = {
        AutoFuel = false,
        FuelBelow = 50,
        FuelUntil = 90,
        EmergencyFuel = 20,
        FuelRadius = 500,
        FuelPriority = { "Nuclear Fuel", "Refined Fuel", "Fuel" },
    },
    Combat = {
        KillAura = false,
        Range = 7,
        AttackDelay = 0.4,
        Priority = "Nearest",
        BossPriority = true,
        AutoEquip = false,
        PauseFarming = true,
        TargetIndicator = true,
    },
    Survival = {
        AutoHeal = false,
        HealBelow = 45,
        AutoEat = false,
        EatBelow = 35,
        AutoDrink = false,
        DrinkBelow = 35,
        AutoBandage = false,
        EmergencyHealth = 20,
    },
    Storage = {
        Enabled = false,
        Categories = { Resource = true, Scrap = true, Fuel = true },
        Keep = {},
        Minimum = {},
        ScrapReserve = 20,
        FuelReserve = 5,
        OnlyWhenFull = false,
    },
    Repair = {
        Enabled = false,
        Radius = 30,
        Rate = 1,
        Priority = "LowestHealth",
        Emergency = false,
        EmergencyBelow = 20,
    },
    Player = {
        AutoSprint = false,
        InfiniteJump = false,
        Noclip = false,
        Fly = false,
        FlySpeed = 60,
        WalkSpeed = 16,
        SprintSpeed = 24,
        JumpPower = 50,
        OverrideMovement = false,
        BunnyHop = false,
    },
    Interface = {
        MenuKey = "RightShift",
        Accent = { 145, 90, 255 },
        NotificationSide = "Right",
        Widget = true,
        WidgetOpacity = 0.92,
        WidgetCollapsed = false,
    },
    Visuals = { MaxDistance = 500, Fullbright = false, Categories = {} },
    Teleports = { Saved = {}, SelectedPlayer = "" },
}
for _, name in ipairs({
    "Enemy",
    "Player",
    "Gun",
    "Melee",
    "Medical",
    "Armor",
    "Food",
    "Resource",
    "Scrap",
    "Fuel",
    "Ability",
    "Structure",
    "Generator",
    "Chest",
}) do
    Config.Visuals.Categories[name] = {
        Enabled = false,
        Highlight = true,
        Name = true,
        Distance = true,
        Health = true,
        Color = { 145, 90, 255 },
        MaxDistance = 500,
    }
end
return Config

````

## FILE: src/ConfigStore.lua

````lua
local Store = {}
Store.__index = Store
local function clone(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, child in pairs(value) do
        result[key] = clone(child)
    end
    return result
end
local function merge(target, source, path)
    for key, value in pairs(source) do
        local old = target[key]
        if old ~= nil and type(old) == type(value) then
            local keyPath = path .. tostring(key)
            local map = keyPath:match("Whitelist$")
                or keyPath:match("Blacklist$")
                or keyPath == "Farming.ItemCategories"
                or keyPath == "Farming.PickupCategories"
                or keyPath == "Storage.Categories"
                or keyPath == "Storage.Keep"
                or keyPath == "Storage.Minimum"
                or keyPath == "Teleports.Saved"
            if type(value) == "table" and next(old) ~= nil and #old == 0 and not map then
                merge(old, value, keyPath .. ".")
            else
                target[key] = clone(value)
            end
        end
    end
end
function Store.new(h)
    return setmetatable({ H = h }, Store)
end
function Store:Export()
    return self.H.Services.HttpService:JSONEncode({ Schema = 1, Config = self.H.Config })
end
function Store:Import(raw)
    assert(type(raw) == "string" and #raw <= 60000, "HESTIA configuration is too large")
    local payload = self.H.Services.HttpService:JSONDecode(raw)
    assert(payload.Schema == 1 and type(payload.Config) == "table", "HESTIA unsupported config schema")
    local validated = self.H:Import("ConfigValidation").Validate(payload.Config, self.H.Config)
    merge(self.H.Config, validated, "")
    self.H:SyncFeatures()
    self.H.UI.ThemeManager:Apply()
    return true
end
function Store:Save()
    local ok, reason = self.H.Adapter:Call("SaveConfig", "HESTIA/survive-the-apocalypse", self:Export())
    if ok then
        self.H.Notifications:Send("Configuration saved.")
    end
    return ok, reason
end
function Store:Load()
    local ok, value = self.H.Adapter:Call("LoadConfig", "HESTIA/survive-the-apocalypse")
    if not ok then
        return false, value
    end
    local success, err = pcall(function()
        self:Import(value)
    end)
    return success, err
end
return Store

````

## FILE: src/ConfigValidation.lua

````lua
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

````

## FILE: src/Connections.lua

````lua
local Connections = {}
Connections.__index = Connections
function Connections.new()
    return setmetatable({ Entries = {} }, Connections)
end
function Connections:Add(name, connection)
    self:Remove(name)
    self.Entries[name] = connection
    return connection
end
function Connections:Remove(name)
    local entry = self.Entries[name]
    self.Entries[name] = nil
    if entry then
        entry:Disconnect()
    end
end
function Connections:DisconnectAll()
    for name in pairs(self.Entries) do
        self:Remove(name)
    end
end
return Connections

````

## FILE: src/GameAdapter.lua

````lua
local Adapter = {}
Adapter.__index = Adapter
-- HESTIA: the only module that knows experience layout and interaction contracts.
Adapter.Folders = {
    Characters = { "Characters", "NPCs", "Enemies" },
    Items = { "DroppedItems", "Items", "Drops" },
    Structures = { "Structures", "PlayerStructures", "Buildings" },
    Storage = { "Storage", "Storages" },
}
function Adapter.new(h, hooks)
    local self = setmetatable({ H = h, Hooks = hooks or {}, Lookup = {}, Watched = {}, NextId = 0 }, Adapter)
    for category, names in pairs(h:Import("Items")) do
        for _, name in ipairs(names) do
            self.Lookup[name] = category
        end
    end
    return self
end
function Adapter:Call(name, ...)
    local hook = self.Hooks[name]
    if not hook then
        self.H.Notifications:Send("Connect GameAdapter hook: " .. name, "HESTIA Integration", name, 60)
        return false, "Unsupported hook: " .. name
    end
    local results = table.pack(pcall(hook, ...))
    if not results[1] then
        self.H.Logger:Log("ERROR", name .. ": " .. tostring(results[2]))
        return false, tostring(results[2])
    end
    return table.unpack(results, 2, results.n)
end
function Adapter:Folder(kind)
    for _, name in ipairs(self.Folders[kind] or {}) do
        local folder = workspace:FindFirstChild(name)
        if folder then
            return folder
        end
    end
end
function Adapter:GetCharactersFolder()
    return self:Folder("Characters")
end
function Adapter:GetDroppedItemsFolder()
    return self:Folder("Items")
end
function Adapter:GetStructuresFolder()
    return self:Folder("Structures")
end
function Adapter:GetStorage()
    if self.Hooks.GetStorage then
        return self.Hooks.GetStorage()
    end
    local folder = self:Folder("Storage")
    return folder and (folder:IsA("Model") and folder or folder:FindFirstChildWhichIsA("Model"))
end
function Adapter:Root(object)
    if not object then
        return nil
    end
    if object:IsA("BasePart") then
        return object
    end
    if object:IsA("Model") then
        return object.PrimaryPart
            or object:FindFirstChild("HumanoidRootPart")
            or object:FindFirstChildWhichIsA("BasePart", true)
    end
    if object:IsA("Tool") then
        return object:FindFirstChild("Handle")
    end
end
function Adapter:Character()
    local player = self.H.Services.Players.LocalPlayer
    return player and player.Character
end
function Adapter:Humanoid()
    local character = self:Character()
    return character and character:FindFirstChildOfClass("Humanoid")
end
function Adapter:Distance(object)
    local root, target = self:Root(self:Character()), self:Root(object)
    return root and target and (root.Position - target.Position).Magnitude or math.huge
end
function Adapter:Valid(object)
    return typeof(object) == "Instance" and object:IsDescendantOf(workspace) and self:Root(object) ~= nil
end
function Adapter:Health(object)
    local hum = object and object:FindFirstChildOfClass("Humanoid")
    if hum then
        return hum.Health, hum.MaxHealth
    end
    if not object then
        return nil, nil
    end
    return object:GetAttribute("Health"), object:GetAttribute("MaxHealth")
end
function Adapter:Category(object)
    return object:GetAttribute("HestiaCategory")
        or (object.Name == "Scrap" and "Scrap")
        or self.Lookup[object.Name]
end
function Adapter:Classify(object)
    local sets = {}
    if not (object:IsA("Model") or object:IsA("BasePart") or object:IsA("Tool")) then
        return sets
    end
    local cs = self.H.Services.CollectionService
    for _, key in ipairs({ "Enemies", "Items", "Scrap", "Fuel", "Structures", "Generator", "Chest" }) do
        if cs:HasTag(object, "HESTIA_" .. key) then
            sets[key] = true
        end
    end
    local parent = object.Parent
    if parent == self:GetDroppedItemsFolder() then
        sets.Items = true
        local cat = self:Category(object)
        if cat == "Scrap" or cat == "Fuel" then
            sets[cat] = true
        end
    end
    if
        parent == self:GetCharactersFolder()
        and object:IsA("Model")
        and not self.H.Services.Players:GetPlayerFromCharacter(object)
    then
        sets.Enemies = true
    end
    if parent == self:GetStructuresFolder() then
        sets.Structures = true
    end
    if object.Name == "Generator" then
        sets.Generator = true
    end
    if object.Name == "Chest" then
        sets.Chest = true
    end
    if sets.Scrap or sets.Fuel then
        sets.Items = true
    end
    if object:IsA("Model") and self.H.Services.Players:GetPlayerFromCharacter(object) then
        sets = { Players = true }
    end
    return sets
end
function Adapter:Refresh(object)
    local sets = object:IsDescendantOf(workspace) and self:Classify(object) or {}
    for kind, registry in pairs(self.H.Registry) do
        registry[object] = sets[kind] or nil
    end
end
function Adapter:Watch(object)
    if self.Watched[object] or not (object:IsA("Model") or object:IsA("BasePart") or object:IsA("Tool")) then
        return
    end
    -- Models and tools can move into tracked folders later. Ignore decorative parts.
    if object:IsA("BasePart") and not next(self:Classify(object)) then
        return
    end
    self.NextId = self.NextId + 1
    local id = "HESTIA.Registry." .. self.NextId
    self.Watched[object] = id
    self.H.Connections:Add(
        id,
        object.AncestryChanged:Connect(function()
            self:Refresh(object)
        end)
    )
    self.H.Connections:Add(
        id .. ".Category",
        object:GetAttributeChangedSignal("HestiaCategory"):Connect(function()
            self:Refresh(object)
        end)
    )
    self:Refresh(object)
end
function Adapter:Forget(object)
    for _, registry in pairs(self.H.Registry) do
        registry[object] = nil
    end
    local id = self.Watched[object]
    if id then
        self.H.Connections:Remove(id)
        self.H.Connections:Remove(id .. ".Category")
    end
    self.Watched[object] = nil
end
function Adapter:Start()
    local function bindFolder(folder)
        for _, names in pairs(self.Folders) do
            if table.find(names, folder.Name) then
                self.H.Connections:Add(
                    "HESTIA.Folder." .. folder.Name,
                    folder.ChildAdded:Connect(function(object)
                        self:Watch(object)
                        self:Refresh(object)
                    end)
                )
                for _, object in ipairs(folder:GetChildren()) do
                    self:Watch(object)
                    self:Refresh(object)
                end
            end
        end
    end
    self.H.Connections:Add("HESTIA.FolderAdded", workspace.ChildAdded:Connect(bindFolder))
    for _, folder in ipairs(workspace:GetChildren()) do
        bindFolder(folder)
    end
    self.H.Connections:Add(
        "HESTIA.Registry.Add",
        workspace.DescendantAdded:Connect(function(object)
            self:Watch(object)
        end)
    )
    self.H.Connections:Add(
        "HESTIA.Registry.Remove",
        workspace.DescendantRemoving:Connect(function(object)
            self:Forget(object)
        end)
    )
    for kind in pairs(self.H.Registry) do
        local tag = "HESTIA_" .. kind
        self.H.Connections:Add(
            tag .. ".Add",
            self.H.Services.CollectionService:GetInstanceAddedSignal(tag):Connect(function(object)
                self:Watch(object)
                self:Refresh(object)
            end)
        )
        self.H.Connections:Add(
            tag .. ".Remove",
            self.H.Services.CollectionService:GetInstanceRemovedSignal(tag):Connect(function(object)
                self:Refresh(object)
            end)
        )
    end
    -- One initial scan; all subsequent registry changes are event driven.
    for _, object in ipairs(workspace:GetDescendants()) do
        self:Watch(object)
    end
    self.H.Logger:Log("SUCCESS", "Object registries initialized")
end
function Adapter:GetEnemies()
    return self.H.Registry.Enemies
end
function Adapter:GetScrap()
    return self.H.Registry.Scrap
end
function Adapter:GetFuel()
    return self.H.Registry.Fuel
end
function Adapter:GetGenerator()
    for object in pairs(self.H.Registry.Generator) do
        if self:Valid(object) then
            return object
        end
    end
end
function Adapter:GetFuelPercent()
    local generator = self:GetGenerator()
    if self.Hooks.GetFuelPercent then
        return self.Hooks.GetFuelPercent(generator)
    end
    if not generator then
        return nil
    end
    local fuel, maximum = generator:GetAttribute("Fuel"), generator:GetAttribute("MaxFuel")
    if type(fuel) == "number" and type(maximum) == "number" and maximum > 0 then
        return math.clamp(fuel / maximum * 100, 0, 100)
    end
end
function Adapter:GetInventory()
    if self.Hooks.GetInventory then
        return self.Hooks.GetInventory()
    end
    local result = {}
    local player = self.H.Services.Players.LocalPlayer
    for _, container in pairs({ player:FindFirstChild("Backpack"), self:Character() }) do
        for _, object in ipairs(container:GetChildren()) do
            if object:IsA("Tool") then
                table.insert(result, {
                    Instance = object,
                    Name = object.Name,
                    Category = self:Category(object),
                    Quantity = object:GetAttribute("Quantity") or 1,
                })
            end
        end
    end
    return result
end
function Adapter:InventoryFull()
    if self.Hooks.InventoryFull then
        return self.Hooks.InventoryFull()
    end
    local player = self.H.Services.Players.LocalPlayer
    local capacity = player:GetAttribute("InventoryCapacity")
    return type(capacity) == "number" and #self:GetInventory() >= capacity
end
function Adapter:Vitals()
    if self.Hooks.Vitals then
        return self.Hooks.Vitals()
    end
    local char = self:Character()
    local hp, max = self:Health(char)
    return {
        Health = hp and max and max > 0 and hp / max * 100 or 100,
        Hunger = char and char:GetAttribute("Hunger") or 100,
        Thirst = char and char:GetAttribute("Thirst") or 100,
        Bleeding = char and char:GetAttribute("Bleeding") == true,
    }
end
function Adapter:CollectItem(item)
    return self:Call("CollectItem", item)
end
function Adapter:AddFuel(generator, fuel)
    return self:Call("AddFuel", generator, fuel)
end
function Adapter:AttackTarget(target)
    if not target:IsA("Model") then
        return false, "NPC models only"
    end
    if self.H.Services.Players:GetPlayerFromCharacter(target) then
        return false, "NPC targets only"
    end
    return self:Call("AttackTarget", target)
end
function Adapter:StoreItem(item, quantity, storage)
    return self:Call("StoreItem", item, quantity, storage)
end
function Adapter:RepairStructure(object)
    return self:Call("RepairStructure", object)
end
function Adapter:UseSurvival(kind)
    return self:Call("UseSurvival", kind)
end
function Adapter:HasRepairEquipment()
    for _, item in ipairs(self:GetInventory()) do
        if item.Name == "Repair Hammer" then
            return true
        end
    end
    return false
end
function Adapter:EquipWeapon()
    if self.Hooks.EquipWeapon then
        return self.Hooks.EquipWeapon()
    end
    local best, speed = nil, math.huge
    for _, item in ipairs(self:GetInventory()) do
        local data = self.H:Import("Weapons")[item.Name]
        if data and data.SwingDelay < speed then
            best, speed = item.Instance, data.SwingDelay
        end
    end
    local hum = self:Humanoid()
    if best and hum then
        hum:EquipTool(best)
        return true
    end
    return false
end
function Adapter:CanUseMovement()
    return self.H.Services.RunService:IsStudio()
        or self.H.Services.Players.LocalPlayer:GetAttribute("HESTIA_AllowMovement") == true
end
function Adapter:Teleport(cframe)
    if self.Hooks.Teleport then
        return self.Hooks.Teleport(cframe)
    end
    if not self:CanUseMovement() then
        return false, "Movement permission required"
    end
    local char = self:Character()
    if char then
        char:PivotTo(cframe)
        return true
    end
    return false, "No character"
end
function Adapter:GetLocation(name)
    if self.Hooks.GetLocation then
        return self.Hooks.GetLocation(name)
    end
    local path = self.H:Import("Locations")[name]
    local node = workspace
    for _, part in ipairs(path or {}) do
        node = node and node:FindFirstChild(part)
    end
    if not node and name == "Spawn" then
        node = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    end
    local root = path and self:Root(node)
    return root and root.CFrame
end
function Adapter:Destroy()
    for object in pairs(self.Watched) do
        self:Forget(object)
    end
end
return Adapter

````

## FILE: src/Hooks.lua

````lua
-- HESTIA integration: return synchronous, confirmed results from your own game systems.
-- See docs/INTEGRATION.md for contracts and a working server-validated demo.
-- No game remotes are guessed or called automatically.
return {}

````

## FILE: src/Importer.lua

````lua
local Importer = {}
Importer.__index = Importer
function Importer.new(root, manifest, requireModule)
    manifest = manifest or game:GetService("HttpService"):JSONDecode(root:GetAttribute("Manifest"))
    return setmetatable(
        { Root = root, Manifest = manifest, Require = requireModule or require, Cache = {}, Loading = {} },
        Importer
    )
end
function Importer:Import(name)
    local entry = self.Manifest.modules[name]
    if not entry then
        for _, candidate in pairs(self.Manifest.modules) do
            if candidate.path == name then
                entry = candidate
                break
            end
        end
    end
    assert(entry, "HESTIA unknown module: " .. tostring(name))
    local path = entry.path
    if self.Cache[path] ~= nil then
        return self.Cache[path]
    end
    assert(not self.Loading[path], "HESTIA dependency cycle at " .. path)
    self.Loading[path] = true
    local ok, result = xpcall(function()
        for _, dependency in ipairs(entry.dependencies or {}) do
            self:Import(dependency)
        end
        local object = self.Root
        for part in path:gmatch("[^/]+") do
            object = object:FindFirstChild((part:gsub("%.lua$", "")))
            assert(object, "HESTIA missing installed module: " .. path)
        end
        print("[HESTIA] Loading " .. path .. "...")
        return self.Require(object)
    end, debug.traceback)
    self.Loading[path] = nil
    if not ok then
        error(result, 0)
    end
    self.Cache[path] = result
    return result
end
function Importer:Clear()
    table.clear(self.Cache)
    table.clear(self.Loading)
end
return Importer

````

## FILE: src/Installer.lua

````lua
local Installer = {}
function Installer.Install(repository)
    local http = game:GetService("HttpService")
    local base = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/",
        repository.Owner,
        repository.Name,
        repository.Channel
    )
    local directory = (repository.Directory or ""):gsub("^/+", ""):gsub("/+$", "")
    assert(
        not directory:find("..", 1, true) and (directory == "" or directory:match("^[%w_/%-]+$")),
        "HESTIA invalid repository directory"
    )
    if directory ~= "" then
        base = base .. directory .. "/"
    end
    local cache = {}
    local function fetch(path)
        if cache[path] then
            return cache[path]
        end
        assert(
            type(path) == "string"
                and not path:find("..", 1, true)
                and not path:match("^/")
                and path:match("^[%w_./%-]+$"),
            "HESTIA invalid path"
        )
        local reason
        for attempt = 1, 3 do
            local ok, result = pcall(http.GetAsync, http, base .. path, true)
            if ok and #result > 0 then
                cache[path] = result
                return result
            end
            reason = result
            warn(string.format("[HESTIA] Retry %d/3: %s (%s)", attempt, tostring(path), tostring(reason)))
            if attempt < 3 then
                task.wait(attempt)
            end
        end
        error("HESTIA failed to download " .. path .. ": " .. tostring(reason))
    end
    local manifestRaw = fetch("manifest.json")
    local manifest = http:JSONDecode(manifestRaw)
    assert(manifest.name == "HESTIA" and type(manifest.modules) == "table", "HESTIA invalid manifest")
    local marks = {}
    local function validate(name)
        assert(manifest.modules[name], "HESTIA missing dependency: " .. name)
        assert(marks[name] ~= "loading", "HESTIA dependency cycle: " .. name)
        if marks[name] == "done" then
            return
        end
        marks[name] = "loading"
        for _, dependency in ipairs(manifest.modules[name].dependencies or {}) do
            validate(dependency)
        end
        marks[name] = "done"
    end
    for name in pairs(manifest.modules) do
        validate(name)
    end
    local staging = Instance.new("Folder")
    staging.Name = "HESTIA"
    local client, server, demo
    local ok, err = xpcall(function()
        staging:SetAttribute("Manifest", manifestRaw)
        staging:SetAttribute("BaseURL", base)
        staging:SetAttribute("Channel", repository.Channel)
        staging:SetAttribute("VersionReady", false)
        local versionOk, version = pcall(fetch, "version.json")
        if versionOk then
            staging:SetAttribute("RemoteVersion", version)
        end
        local paths = {}
        for name, entry in pairs(manifest.modules) do
            assert(not paths[entry.path], "HESTIA duplicate module path: " .. entry.path)
            paths[entry.path] = true
            local success, source = pcall(fetch, entry.path)
            if not success and not entry.optional then
                error(source)
            end
            if success then
                local parent, segments = staging, string.split(entry.path, "/")
                for i = 1, #segments - 1 do
                    local folder = parent:FindFirstChild(segments[i])
                    if not folder then
                        folder = Instance.new("Folder")
                        folder.Name = segments[i]
                        folder.Parent = parent
                    end
                    parent = folder
                end
                local module = Instance.new("ModuleScript")
                module.Name = segments[#segments]:gsub("%.lua$", "")
                module.Source = source
                module.Parent = parent
                print("[HESTIA] Installed " .. name)
            else
                warn("[HESTIA] Optional module unavailable: " .. name .. "\n" .. tostring(source))
            end
        end
        client = Instance.new("LocalScript")
        client.Name = "HESTIA Client"
        client.Source = fetch(manifest.entrypoints.client)
        server = Instance.new("Script")
        server.Name = "HESTIA Server"
        server.Source = fetch(manifest.entrypoints.server)
        if repository.InstallDemo then
            staging.src.Hooks.Source = fetch("examples/DemoHooks.lua")
            demo = Instance.new("Script")
            demo.Name = "HESTIA Demo"
            demo.Source = fetch("examples/Demo.server.lua")
        end
    end, debug.traceback)
    if not ok then
        staging:Destroy()
        if client then
            client:Destroy()
        end
        if server then
            server:Destroy()
        end
        if demo then
            demo:Destroy()
        end
        error(err)
    end
    -- Download and validate the whole package before touching an existing installation.
    local targets = {
        { game:GetService("ReplicatedStorage"), staging },
        { game:GetService("StarterPlayer").StarterPlayerScripts, client },
        { game:GetService("ServerScriptService"), server },
    }
    for _, pair in ipairs(targets) do
        local previous = pair[1]:FindFirstChild(pair[2].Name)
        if previous then
            previous:Destroy()
        end
        pair[2].Parent = pair[1]
    end
    local priorDemo = game:GetService("ServerScriptService"):FindFirstChild("HESTIA Demo")
    if priorDemo then
        priorDemo:Destroy()
    end
    if demo then
        demo.Parent = game:GetService("ServerScriptService")
    end
    return staging
end
return Installer

````

## FILE: src/Logger.lua

````lua
local Logger = {}
Logger.__index = Logger
function Logger.new(config)
    return setmetatable({ Config = config, History = {} }, Logger)
end
function Logger:Log(level, message)
    if level == "DEBUG" and not self.Config.Debug then
        return
    end
    local text = string.format("[HESTIA][%s] %s", level, tostring(message))
    table.insert(self.History, text)
    if #self.History > 100 then
        table.remove(self.History, 1)
    end
    if level == "ERROR" or level == "WARN" then
        warn(text)
    else
        print(text)
    end
end
return Logger

````

## FILE: src/Main.lua

````lua
local Hestia = {}
Hestia.__index = Hestia
Hestia.Name, Hestia.Version, Hestia.Game = "HESTIA", "1.0.0", "Survive the Apocalypse"
local featureSwitches = {
    ScrapFarm = "Farming.AutoScrap",
    ItemFarm = "Farming.AutoItems",
    FuelFarm = "Farming.AutoFuelFarm",
    Generator = "Generator.AutoFuel",
    AutoPickup = "Farming.AutoPickup",
    AutoStore = "Storage.Enabled",
    Combat = "Combat.KillAura",
    Repair = "Repair.Enabled",
}
function Hestia.new(root, hooks)
    local importer = require(root.src.Importer).new(root)
    local self = setmetatable({
        Root = root,
        Importer = importer,
        Modules = importer.Cache,
        Features = {},
        Enabled = {},
        Hooks = hooks,
    }, Hestia)
    return self
end
function Hestia:Import(name)
    return self.Importer:Import(name)
end
function Hestia:Get(path)
    local value = self.Config
    for key in path:gmatch("[^.]+") do
        value = value[key]
    end
    return value
end
function Hestia:Set(path, value)
    local patch, node, keys = {}, nil, {}
    for key in path:gmatch("[^.]+") do
        table.insert(keys, key)
    end
    node = patch
    for i = 1, #keys - 1 do
        node[keys[i]] = {}
        node = node[keys[i]]
    end
    node[keys[#keys]] = value
    self:Import("ConfigValidation").Validate(patch, self.Config)
    node = self.Config
    for i = 1, #keys - 1 do
        assert(node[keys[i]], "HESTIA unknown config path")
        node = node[keys[i]]
    end
    assert(node[keys[#keys]] ~= nil, "HESTIA unknown config path")
    node[keys[#keys]] = value
    self:SyncFeatures()
    if self.UI then
        self.UI.ThemeManager:Apply()
    end
end
function Hestia:SyncFeatures()
    for name, path in pairs(featureSwitches) do
        local wanted = self:Get(path)
        local feature = self.Features[name]
        if feature and wanted ~= self.Enabled[name] then
            if wanted then
                feature:Start()
            else
                feature:Stop()
            end
            self.Enabled[name] = wanted
            self.Notifications:Send(name .. (wanted and " enabled." or " disabled."))
        end
    end
end
function Hestia:Start()
    if self.State and self.State.Running then
        return self
    end
    assert(not self.Unloaded, "HESTIA create a fresh instance after unload")
    local ok, err = xpcall(function()
        self.Services = self:Import("Services")
        self.Config =
            self.Services.HttpService:JSONDecode(self.Services.HttpService:JSONEncode(self:Import("Config")))
        self.State = self:Import("State")()
        self.Registry = self.State.Registry
        self.Logger = self:Import("Logger").new(self.Config)
        self.Connections = self:Import("Connections").new()
        self.Notifications = self:Import("Notifications").new(self)
        self.Scheduler = self:Import("Scheduler").new(self)
        self.Adapter = self:Import("GameAdapter").new(self, self.Hooks or self:Import("Hooks"))
        self.Tasks = self:Import("TaskManager").new(function(active, previous)
            if self.Navigator then
                self.Navigator:Cancel(previous)
            end
            self.Logger:Log("DEBUG", "Active task: " .. (active or "Idle"))
        end)
        self.Navigator = self:Import("Navigator").new(self)
        self.Adapter:Start()
        self.ConfigStore = self:Import("ConfigStore").new(self)
        self.UI = self:Import("Interface").new(self)
        for _, name in ipairs({
            "ScrapFarm",
            "ItemFarm",
            "FuelFarm",
            "Generator",
            "AutoPickup",
            "AutoStore",
            "Combat",
            "Repair",
            "Survival",
            "Movement",
            "Teleports",
            "ESP",
            "Lighting",
        }) do
            local success, result = xpcall(function()
                return self:Import(name).new(self)
            end, debug.traceback)
            if success then
                self.Features[name] = result
                self.Logger:Log("SUCCESS", name)
            else
                self.State.Errors[name] = result
                self.Logger:Log("ERROR", name .. ": " .. result)
            end
        end
        self.UI:Start()
        for _, name in ipairs({ "Survival", "Movement", "ESP", "Lighting" }) do
            local feature = self.Features[name]
            if feature then
                local success, reason = pcall(function()
                    feature:Start()
                end)
                if not success then
                    pcall(function()
                        feature:Destroy()
                    end)
                    self.State.Errors[name] = reason
                    self.Logger:Log("ERROR", reason)
                end
            end
        end
        self:SyncFeatures()
        local checked, reason = pcall(function()
            self:Import("Version").Check(self)
        end)
        if not checked then
            self.Logger:Log("WARN", "Version check: " .. tostring(reason))
        end
        self.State.Running = true
        self.Notifications:Send("Successfully loaded.", "HESTIA v" .. self.Version)
        self.Logger:Log("SUCCESS", "Ready.")
    end, debug.traceback)
    if not ok then
        self:Unload()
        error("HESTIA initialization failed: " .. tostring(err), 0)
    end
    return self
end
function Hestia:Unload()
    if self.Unloaded then
        return
    end
    self.Unloaded = true
    if self.State then
        self.State.Running = false
    end
    local function safely(label, callback)
        local ok, err = pcall(callback)
        if not ok then
            warn("[HESTIA] Cleanup " .. label .. ": " .. tostring(err))
        end
    end
    if self.Scheduler then
        safely("scheduler", function()
            self.Scheduler:Destroy()
        end)
    end
    for name, feature in pairs(self.Features) do
        if feature.Destroy then
            safely(name, function()
                feature:Destroy()
            end)
        end
    end
    if self.Navigator then
        safely("navigation", function()
            self.Navigator:Cancel()
        end)
    end
    if self.Tasks then
        safely("tasks", function()
            self.Tasks:ReleaseAll()
        end)
    end
    if self.Adapter then
        safely("adapter", function()
            self.Adapter:Destroy()
        end)
    end
    if self.Connections then
        safely("connections", function()
            self.Connections:DisconnectAll()
        end)
    end
    if self.UI then
        safely("UI", function()
            self.UI:Destroy()
        end)
    end
    if self.Registry then
        for _, registry in pairs(self.Registry) do
            table.clear(registry)
        end
    end
    table.clear(self.Features)
    table.clear(self.Enabled)
    self.Importer:Clear()
    print("[HESTIA] Unloaded successfully.")
end
return Hestia

````

## FILE: src/Navigator.lua

````lua
local Navigator = {}
Navigator.__index = Navigator
function Navigator.new(h)
    return setmetatable({ H = h }, Navigator)
end
function Navigator:Cancel(owner)
    if owner and self.Owner ~= owner then
        return
    end
    self.Generation = (self.Generation or 0) + 1
    self.Owner, self.Target, self.Waypoints = nil, nil, nil
    local hum, root = self.H.Adapter:Humanoid(), self.H.Adapter:Root(self.H.Adapter:Character())
    if hum and root then
        hum:MoveTo(root.Position)
    end
end
-- Nonblocking navigation: path computation may yield, but its result needs a valid lease.
function Navigator:Step(owner, target, range)
    local h, a = self.H, self.H.Adapter
    if not h.Tasks:IsOwner(owner) then
        return "Paused"
    end
    if not a:Valid(target) then
        self:Cancel(owner)
        return "Invalid"
    end
    local root, hum = a:Root(a:Character()), a:Humanoid()
    if not root or not hum or hum.Health <= 0 then
        return "NoCharacter"
    end
    if a:Distance(target) <= (range or 5) then
        self:Cancel(owner)
        return "Arrived"
    end
    if self.Owner ~= owner or self.Target ~= target then
        self:Cancel()
        self.Owner, self.Target, self.Started, self.ProgressAt = owner, target, os.clock(), os.clock()
        self.LastPosition, self.Attempts, self.NextPath = root.Position, 0, 0
    end
    local config, now = h.Config.Farming, os.clock()
    if now - self.Started > config.TargetTimeout then
        self:Cancel(owner)
        return "Timeout"
    end
    if (root.Position - self.LastPosition).Magnitude > 1 then
        self.LastPosition, self.ProgressAt = root.Position, now
    elseif now - self.ProgressAt > config.StuckTimeout then
        self.Waypoints, self.ProgressAt = nil, now
        self.Attempts = self.Attempts + 1
    end
    if self.Attempts > config.PathRetries then
        self:Cancel(owner)
        return "Unreachable"
    end
    if not self.Waypoints then
        if now < self.NextPath then
            return "Moving"
        end
        self.NextPath = now + 0.5
        local generation, token = self.Generation, h.Tasks.Serial
        local destination = a:Root(target).Position
        local path = h.Services.PathfindingService:CreatePath({ AgentCanJump = true })
        local ok = pcall(function()
            path:ComputeAsync(root.Position, destination)
        end)
        if generation ~= self.Generation or not h.Tasks:IsOwner(owner, token) or not a:Valid(target) then
            return "Paused"
        end
        if not ok or path.Status ~= Enum.PathStatus.Success then
            self.Attempts = self.Attempts + 1
            return "Moving"
        end
        self.Waypoints, self.Index, self.Destination = path:GetWaypoints(), 2, destination
    end
    if (a:Root(target).Position - self.Destination).Magnitude > 6 then
        self.Waypoints = nil
        return "Moving"
    end
    local point = self.Waypoints[self.Index]
    if not point then
        self.Waypoints = nil
        return "Moving"
    end
    if (root.Position - point.Position).Magnitude < 3 then
        self.Index = self.Index + 1
    end
    if point.Action == Enum.PathWaypointAction.Jump then
        hum.Jump = true
    end
    hum:MoveTo(point.Position)
    return "Moving"
end
return Navigator

````

## FILE: src/Notifications.lua

````lua
local Notifications = {}
Notifications.__index = Notifications
function Notifications.new(h)
    return setmetatable({ H = h, Last = {} }, Notifications)
end
function Notifications:Send(message, title, key, cooldown)
    if key and os.clock() - (self.Last[key] or -math.huge) < (cooldown or 10) then
        return
    end
    if key then
        self.Last[key] = os.clock()
    end
    self.H.Logger:Log("INFO", (title or "HESTIA") .. ": " .. message)
    if self.H.UI then
        self.H.UI:Notify(title or "HESTIA", message)
    end
end
return Notifications

````

## FILE: src/Scheduler.lua

````lua
local Scheduler = {}
Scheduler.__index = Scheduler
function Scheduler.new(h)
    local self = setmetatable({ H = h, Jobs = {}, Running = true }, Scheduler)
    h.Connections:Add(
        "HESTIA.Scheduler",
        h.Services.RunService.Heartbeat:Connect(function(dt)
            self:Step(dt)
        end)
    )
    return self
end
function Scheduler:Add(name, interval, callback, onError)
    self:Remove(name)
    self.Jobs[name] =
        { Interval = interval, Elapsed = interval, Callback = callback, OnError = onError, Busy = false }
end
function Scheduler:Remove(name)
    local job = self.Jobs[name]
    self.Jobs[name] = nil
    if
        job
        and job.Thread
        and coroutine.status(job.Thread) ~= "dead"
        and job.Thread ~= coroutine.running()
    then
        pcall(task.cancel, job.Thread)
    end
end
function Scheduler:Step(dt)
    if not self.Running then
        return
    end
    self.H.State.FPS = self.H.State.FPS * 0.9 + (1 / math.max(dt, 0.001)) * 0.1
    for name, job in pairs(self.Jobs) do
        job.Elapsed = job.Elapsed + dt
        if not job.Busy and job.Elapsed >= job.Interval then
            job.Elapsed, job.Busy = 0, true
            job.Thread = task.spawn(function()
                local ok, err = xpcall(job.Callback, debug.traceback)
                job.Busy = false
                if not ok then
                    self.H.Logger:Log("ERROR", name .. ": " .. tostring(err))
                    self.H.State.Errors[name] = tostring(err)
                    if job.OnError then
                        pcall(job.OnError, err)
                    end
                    self:Remove(name)
                end
            end)
        end
    end
end
function Scheduler:Destroy()
    self.Running = false
    for name in pairs(self.Jobs) do
        self:Remove(name)
    end
end
return Scheduler

````

## FILE: src/Services.lua

````lua
local result = {}
for _, name in ipairs({
    "Players",
    "RunService",
    "CollectionService",
    "PathfindingService",
    "UserInputService",
    "TweenService",
    "Lighting",
    "HttpService",
    "ReplicatedStorage",
    "StarterGui",
}) do
    result[name] = game:GetService(name)
end
result.Workspace = workspace
return result

````

## FILE: src/State.lua

````lua
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

````

## FILE: src/TaskManager.lua

````lua
local TaskManager = {}
TaskManager.__index = TaskManager
TaskManager.Priorities = {
    EmergencySurvival = 100,
    EmergencyFuel = 90,
    Combat = 80,
    AutoHeal = 70,
    Generator = 60,
    ScrapFarm = 50,
    ItemFarm = 40,
    AutoPickup = 30,
    Idle = 10,
}
function TaskManager.new(onChanged)
    return setmetatable(
        { Requests = {}, Active = nil, Serial = 0, Order = 0, OnChanged = onChanged },
        TaskManager
    )
end
function TaskManager:Reconcile()
    local best, record
    for name, request in pairs(self.Requests) do
        if
            not record
            or request.Priority > record.Priority
            or (request.Priority == record.Priority and request.Order < record.Order)
        then
            best, record = name, request
        end
    end
    if best ~= self.Active then
        local previous = self.Active
        self.Active = best
        self.Serial = self.Serial + 1
        if self.OnChanged then
            self.OnChanged(best, previous)
        end
    end
end
function TaskManager:Request(name, priority)
    assert(type(name) == "string" and type(priority) == "number", "HESTIA invalid task request")
    local old = self.Requests[name]
    if not old then
        self.Order = self.Order + 1
    end
    self.Requests[name] = { Priority = priority, Order = old and old.Order or self.Order }
    self:Reconcile()
    return self:IsOwner(name), self.Serial
end
function TaskManager:Release(name)
    self.Requests[name] = nil
    self:Reconcile()
end
function TaskManager:IsOwner(name, token)
    return self.Active == name and (token == nil or token == self.Serial)
end
function TaskManager:ReleaseAll()
    table.clear(self.Requests)
    self:Reconcile()
end
return TaskManager

````

## FILE: src/Version.lua

````lua
local Version = {}
local function parts(value)
    local a, b, c = tostring(value):match("^(%d+)%.(%d+)%.(%d+)$")
    assert(a, "HESTIA expected numeric major.minor.patch version")
    return { tonumber(a), tonumber(b), tonumber(c) }
end
function Version.IsNewer(remote, installed)
    local a, b = parts(remote), parts(installed)
    for i = 1, 3 do
        if a[i] ~= b[i] then
            return a[i] > b[i]
        end
    end
    return false
end
function Version.Check(h)
    if h.VersionChecked then
        return
    end
    h.VersionChecked = true
    local raw = h.Root:GetAttribute("RemoteVersion")
    if not raw then
        h.Logger:Log("WARN", "Version information unavailable")
        return
    end
    local data = h.Services.HttpService:JSONDecode(raw)
    assert(data.name == "HESTIA", "HESTIA invalid version metadata")
    h.Release = data
    if Version.IsNewer(data.version, h.Version) then
        h.Notifications:Send(
            "Installed: " .. h.Version .. "\nLatest: " .. data.version,
            "HESTIA Update Available"
        )
    end
end
return Version

````

## FILE: stylua.toml

````text
syntax = "Luau"
column_width = 110
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 4
quote_style = "AutoPreferDouble"
call_parentheses = "Always"

````

## FILE: tests/core.spec.lua

````lua
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
    assert(not worker:Collect({}) and attempts == 0)
    h.Tasks:Release("Generator")
    assert(not worker:Collect({}) and h.State.Stats.Scrap == 0)
    h.Adapter.CollectItem = function()
        return true, 8
    end
    assert(worker:Collect({}) and h.State.Stats.Scrap == 8)
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
print(string.format("HESTIA: %d core tests passed", passed))

````

## FILE: tools/generate_content.py

````python
"""HESTIA repository maintenance: generate declarative UI panels and source catalog."""
from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

def write(path, text):
    (ROOT / path).write_text(text.strip() + '\n', encoding='utf-8')

def catalog(reference):
    source = Path(reference).read_text(encoding='utf-8-sig')
    section = source.split('local espDefinitions = {', 1)[1].split('-- Build per-ESP', 1)[0]
    items = {key: re.findall(r'"([^"\n]+)"', names) for key, names in re.findall(r'key\s*=\s*"([^"]+)".*?items\s*=\s*\{(.*?)\}', section, re.S)}
    extra = source.split('local extraItemCategories = {', 1)[1].split('for catName', 1)[0]
    for key, names in re.findall(r'(\w+)\s*=\s*\{([^{}]*)\}', extra):
        items[key] = re.findall(r'"([^"\n]+)"', names)
    items['Resource'].remove('Scrap')
    items['Scrap'] = ['Scrap']
    write('data/Items.lua', 'return {\n' + '\n'.join('    '+k+' = { '+', '.join(json.dumps(n) for n in v)+' },' for k,v in items.items()) + '\n}')
    weapons = source.split('local weaponSwingSpeeds = {',1)[1].split('\n}',1)[0]
    write('data/Weapons.lua', 'return {\n' + '\n'.join(f'    [{json.dumps(n)}] = {{ SwingDelay = {v} }},' for n,v in re.findall(r'\["([^"]+)"\]\s*=\s*([0-9.]+)', weapons)) + '\n}')

PANELS = {
 'Farming': [
  ('Scrap grinding', [
   ('T','Auto Grind Scrap','Farming.AutoScrap'), ('C','Target priority','Farming.ScrapPriority',['Nearest','Value']),
   ('N','Search radius','Farming.ScrapRadius',5,5000), ('N','Interaction delay','Farming.ScrapDelay',0.1,10),
   ('N','Target timeout','Farming.TargetTimeout',3,120), ('N','Stuck timeout','Farming.StuckTimeout',1,20), ('N','Path retries','Farming.PathRetries',0,10),
   ('J','Whitelist (JSON name: true)','Farming.ScrapWhitelist'), ('J','Blacklist (JSON name: true)','Farming.ScrapBlacklist')]),
  ('Item and fuel farming', [('T','Auto Item Farm','Farming.AutoItems'),('N','Item radius','Farming.ItemRadius',5,5000),('J','Item categories','Farming.ItemCategories'),('T','Build fuel reserve','Farming.AutoFuelFarm'),('N','Fuel reserve','Farming.FuelReserve',0,1000)]),
  ('Pickup', [('T','Auto Pickup','Farming.AutoPickup'),('T','All categories','Farming.AllItems'),('N','Pickup radius','Farming.PickupRadius',1,100),('N','Pickup delay','Farming.PickupDelay',0.1,10),('J','Whitelist','Farming.PickupWhitelist'),('J','Blacklist','Farming.PickupBlacklist'),('J','Category filters','Farming.PickupCategories')]),
  ('Storage', [('T','Auto Store','Storage.Enabled'),('T','Only when inventory full','Storage.OnlyWhenFull'),('J','Categories','Storage.Categories'),('J','Keep items','Storage.Keep'),('J','Minimum quantities','Storage.Minimum'),('N','Keep scrap','Storage.ScrapReserve',0,10000),('N','Keep fuel per type','Storage.FuelReserve',0,1000)])
 ],
 'Generator': [('Generator automation', [('T','Auto Fuel Generator','Generator.AutoFuel'),('N','Start below (%)','Generator.FuelBelow',1,99),('N','Stop at (%)','Generator.FuelUntil',2,100),('N','Emergency at (%)','Generator.EmergencyFuel',0,99),('N','Fuel search radius','Generator.FuelRadius',5,5000),('J','Fuel priority (JSON array)','Generator.FuelPriority')])],
 'Combat': [('NPC combat', [('T','Kill Aura','Combat.KillAura'),('C','Target priority','Combat.Priority',['Nearest','LowestHP','HighestHP']),('T','Boss priority','Combat.BossPriority'),('N','Range','Combat.Range',1,50),('N','Attack delay','Combat.AttackDelay',0.1,10),('T','Auto equip weapon','Combat.AutoEquip'),('T','Pause farming during threats','Combat.PauseFarming'),('T','Target indicator','Combat.TargetIndicator')]),
 ('Survival', [('T','Auto Heal','Survival.AutoHeal'),('N','Heal below (%)','Survival.HealBelow',1,100),('T','Auto Eat','Survival.AutoEat'),('N','Eat below (%)','Survival.EatBelow',1,100),('T','Auto Drink','Survival.AutoDrink'),('N','Drink below (%)','Survival.DrinkBelow',1,100),('T','Auto Bandage','Survival.AutoBandage'),('N','Emergency health (%)','Survival.EmergencyHealth',1,100)])],
 'Player': [('Movement', [('T','Override movement values','Player.OverrideMovement'),('T','Auto Sprint','Player.AutoSprint'),('N','Walk speed','Player.WalkSpeed',0,100),('N','Sprint speed','Player.SprintSpeed',0,150),('N','Jump power','Player.JumpPower',0,150),('T','Infinite Jump','Player.InfiniteJump'),('T','Bunny Hop','Player.BunnyHop'),('T','Noclip','Player.Noclip'),('T','Fly (WASD / Space / Ctrl)','Player.Fly'),('N','Fly speed','Player.FlySpeed',1,150)])],
 'Misc': [('Structure repair', [('T','Auto Repair','Repair.Enabled'),('C','Priority','Repair.Priority',['Nearest','LowestHealth']),('N','Radius','Repair.Radius',1,100),('N','Repair interval','Repair.Rate',0.2,10),('T','Emergency repair priority','Repair.Emergency'),('N','Emergency below (%)','Repair.EmergencyBelow',1,100)]),('Utilities', [('T','Fullbright','Visuals.Fullbright'),('T','Debug logging','Debug')])],
}

EXTRA = {
 'Generator': '''ui:Label(section, "Fuel", function() local p = h.Adapter:GetFuelPercent() return p and string.format("%s  %.0f%%", string.rep("|", math.floor(p / 10)), p) or "Unavailable" end)
    ui:Label(section, "Status", function() return h.Features.Generator and h.Features.Generator.Status or "Unavailable" end)
    ui:Label(section, "Current fuel", function() return h.Features.Generator and h.Features.Generator.CurrentFuel or "None" end)''',
 'Player': '''ui:Button(section, "Reset Movement", function() h.Features.Movement:Reset() end)''',
 'Combat': '''ui:Label(section, "Current target", function() local c = h.Features.Combat return c and c.Target and c.Target.Name or "None" end)
    ui:Label(section, "Enemy count", function() return h:Import("Utilities").Count(h.Registry.Enemies) end)''',
 'Misc': '''ui:Label(section, "Structure health", function() return h.Features.Repair and h.Features.Repair.Status or "Disabled" end)
    ui:Button(section, "Rejoin this place", function() game:GetService("TeleportService"):Teleport(game.PlaceId, h.Services.Players.LocalPlayer) end)''',
}

def panels():
    methods = {'T':'Toggle','N':'Number','C':'Choice','J':'JSON'}
    for name, sections in PANELS.items():
        lines = ['local Panel = {}','function Panel.Build(ui, tab, h)','    local section']
        for title, controls in sections:
            lines.append('    section = ui:Section(tab, '+json.dumps(title)+')')
            for kind, label, path, *args in controls:
                encoded = [('{ '+', '.join(json.dumps(s) for s in a)+' }') if isinstance(a,list) else str(a) for a in args]
                lines.append('    ui:'+methods[kind]+'(section, '+', '.join([json.dumps(label),json.dumps(path)]+encoded)+')')
        if name in EXTRA: lines.append('    '+EXTRA[name])
        lines.extend(['end','return Panel'])
        write('ui/'+name+'.lua','\n'.join(lines))

if __name__ == '__main__':
    panels()
    if len(sys.argv) > 1: catalog(sys.argv[1])

````

## FILE: tools/package.py

````python
"""HESTIA manifest, exact URL inventory, and complete file-by-file delivery."""
from pathlib import Path
import json
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
DEPENDENCIES = {
 'Main':['Importer','Config','State','Services','Connections','Logger','Notifications','Scheduler','GameAdapter','TaskManager','Navigator','ConfigStore','ConfigValidation','Interface','Hooks','Version'],
 'Interface':['ThemeManager','Widget'], 'GameAdapter':['Items','Weapons','Enemies','Locations','Structures'],
 'ScrapFarm':['FarmWorker','Utilities'], 'ItemFarm':['FarmWorker','Utilities'], 'FuelFarm':['FarmWorker','Utilities'],
 'Combat':['NPCTargeting','Weapons'], 'NPCTargeting':['Utilities','Enemies'], 'Movement':['Fly','Noclip'],
 'ESP':['ItemESP','MobESP','PlayerESP','StructureESP'], 'ConfigStore':['ConfigValidation'],
}
def files():
    return sorted(p for p in ROOT.rglob('*') if p.is_file() and not any(x in p.parts for x in ['.bin','.git','dist','__pycache__']))

def main():
    loader = (ROOT/'loader.lua').read_text(encoding='utf-8')
    repository = {}
    for key in ['Owner', 'Name', 'Channel', 'Directory']:
        match = re.search(r'\b'+key+r'\s*=\s*"([^"]*)"', loader)
        if not match:
            raise ValueError('Missing repository setting in loader.lua: '+key)
        repository[key] = match.group(1)
    directory = repository['Directory'].strip('/')
    base = f"https://raw.githubusercontent.com/{repository['Owner']}/{repository['Name']}/{repository['Channel']}/"
    if directory:
        base += directory+'/'
    modules = {}
    for folder in ['src','modules','ui','data']:
        for path in sorted((ROOT/folder).glob('*.lua')):
            if path.stem == 'Installer': continue
            name = ('UI'+path.stem) if folder == 'ui' and path.stem in ['Generator','Combat','Teleports'] else path.stem
            modules[name] = {'path':path.relative_to(ROOT).as_posix(), 'dependencies':DEPENDENCIES.get(name,[]), 'optional':folder=='modules'}
    manifest = {'name':'HESTIA','version':'1.0.0','modules':modules,'entrypoints':{'client':'client/Runtime.client.lua','server':'server/Runtime.server.lua'}}
    (ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    tree_paths = [p.relative_to(ROOT).as_posix() for p in files() if p.name not in ['TREE.md','RAW_URLS.md']]
    tree_paths += ['docs/TREE.md','docs/RAW_URLS.md']
    nested = {}
    for path in sorted(set(tree_paths)):
        node = nested
        for part in path.split('/'): node = node.setdefault(part,{})
    def tree(node, prefix=''):
        rows = []
        entries = sorted(node.items(), key=lambda pair:(bool(pair[1]),pair[0]))
        for i,(name,children) in enumerate(entries):
            last = i == len(entries)-1
            rows.append(prefix+('└── ' if last else '├── ')+name+('/' if children else ''))
            rows += tree(children,prefix+('    ' if last else '│   '))
        return rows
    (ROOT/'docs/TREE.md').write_text('# HESTIA repository tree\n\n```text\nHestia/\n'+'\n'.join(tree(nested))+'\n```\n',encoding='utf-8')
    tracked = files()
    urls = [base+p.relative_to(ROOT).as_posix() for p in tracked if p.suffix in ['.lua','.json','.md'] and p.name != 'RAW_URLS.md']
    location = f"`{repository['Owner']}/{repository['Name']}`, branch `{repository['Channel']}`, directory `{directory or '(repository root)'}`"
    (ROOT/'docs/RAW_URLS.md').write_text('# HESTIA raw URLs\n\nThese URLs become available after uploading the matching files to '+location+'.\n\n```text\n'+'\n'.join(urls)+'\n```\n',encoding='utf-8')
    tracked = files()
    dist = ROOT/'dist'
    dist.mkdir(exist_ok=True)
    with (dist/'HESTIA-FILES.md').open('w',encoding='utf-8') as output:
        output.write('# HESTIA complete project\n\nEvery project file is included below.\n\n')
        for path in tracked:
            ext = {'lua':'lua','json':'json','py':'python','md':'markdown'}.get(path.suffix[1:],'text')
            output.write('## FILE: '+path.relative_to(ROOT).as_posix()+'\n\n````'+ext+'\n'+path.read_text(encoding='utf-8')+'\n````\n\n')
    with zipfile.ZipFile(dist/'HESTIA.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for path in tracked: archive.write(path,'Hestia/'+path.relative_to(ROOT).as_posix())
        archive.write(dist/'HESTIA-FILES.md','Hestia/HESTIA-FILES.md')
    print(f'HESTIA: {len(modules)} modules, {len(tracked)} project files; archive and complete source document generated.')

if __name__ == '__main__': main()

````

## FILE: tools/verify.py

````python
"""Compile all HESTIA Luau, validate module wiring and run behavioral regression tests."""
from pathlib import Path
import json
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT/'manifest.json').read_text())
modules = manifest['modules']
paths = {entry['path'] for entry in modules.values()}
errors = []
for name, entry in modules.items():
    if not (ROOT/entry['path']).is_file(): errors.append('Missing module '+name)
    for dependency in entry.get('dependencies',[]):
        if dependency not in modules: errors.append('Unknown dependency '+dependency)

visiting, visited = set(), set()
def visit(name):
    if name in visiting: raise ValueError('Dependency cycle: '+name)
    if name in visited: return
    visiting.add(name)
    for dependency in modules[name].get('dependencies',[]): visit(dependency)
    visiting.remove(name)
    visited.add(name)
for name in modules: visit(name)

sources = sorted(ROOT.rglob('*.lua'))
for path in sources:
    text = path.read_text(encoding='utf-8')
    for imported in ([] if 'tests' in path.parts else re.findall(r':Import\("([^"\n]+)"\)', text)):
        if imported not in modules and imported not in paths: errors.append(f'{path.name}: unknown import {imported}')
    if re.search(r'getgenv\s*\(|gethui\s*\(|sethiddenproperty\s*\(|fireproximityprompt\s*\(|game:HttpGet\s*\(',text):
        errors.append(f'{path.name}: unsupported runtime API')

compiler = ROOT/'tools/.bin/luau-compile.exe'
runtime = ROOT/'tools/.bin/luau.exe'
if not compiler.exists() or not runtime.exists():
    sys.exit('Install official Luau binaries in tools/.bin first; see README.')
for path in sources:
    result = subprocess.run([str(compiler),str(path)],capture_output=True,text=True)
    if result.returncode: errors.append(result.stderr)
if errors:
    print('\n'.join(errors)); sys.exit(1)
print(f'HESTIA: compiled {len(sources)} files; {len(modules)} modules and all literal imports validated.',flush=True)
subprocess.run([str(runtime), str(ROOT/'tests/core.spec.lua')], check=True, cwd=ROOT)

````

## FILE: ui/Combat.lua

````lua
local Panel = {}
function Panel.Build(ui, tab, h)
    local section
    section = ui:Section(tab, "NPC combat")
    ui:Toggle(section, "Kill Aura", "Combat.KillAura")
    ui:Choice(section, "Target priority", "Combat.Priority", { "Nearest", "LowestHP", "HighestHP" })
    ui:Toggle(section, "Boss priority", "Combat.BossPriority")
    ui:Number(section, "Range", "Combat.Range", 1, 50)
    ui:Number(section, "Attack delay", "Combat.AttackDelay", 0.1, 10)
    ui:Toggle(section, "Auto equip weapon", "Combat.AutoEquip")
    ui:Toggle(section, "Pause farming during threats", "Combat.PauseFarming")
    ui:Toggle(section, "Target indicator", "Combat.TargetIndicator")
    section = ui:Section(tab, "Survival")
    ui:Toggle(section, "Auto Heal", "Survival.AutoHeal")
    ui:Number(section, "Heal below (%)", "Survival.HealBelow", 1, 100)
    ui:Toggle(section, "Auto Eat", "Survival.AutoEat")
    ui:Number(section, "Eat below (%)", "Survival.EatBelow", 1, 100)
    ui:Toggle(section, "Auto Drink", "Survival.AutoDrink")
    ui:Number(section, "Drink below (%)", "Survival.DrinkBelow", 1, 100)
    ui:Toggle(section, "Auto Bandage", "Survival.AutoBandage")
    ui:Number(section, "Emergency health (%)", "Survival.EmergencyHealth", 1, 100)
    ui:Label(section, "Current target", function()
        local c = h.Features.Combat
        return c and c.Target and c.Target.Name or "None"
    end)
    ui:Label(section, "Enemy count", function()
        return h:Import("Utilities").Count(h.Registry.Enemies)
    end)
end
return Panel

````

## FILE: ui/Dashboard.lua

````lua
local Dashboard = {}
function Dashboard.Build(ui, tab, h)
    local util = h:Import("Utilities")
    local section = ui:Section(tab, "Overview")
    ui:Label(section, "Current task", function()
        return h.Tasks.Active or "Idle"
    end)
    ui:Label(section, "Generator", function()
        local p = h.Adapter:GetFuelPercent()
        return p and string.format("%.0f%%", p) or "Unknown"
    end)
    ui:Label(section, "Enemies", function()
        return util.Count(h.Registry.Enemies)
    end)
    ui:Label(section, "FPS", function()
        return math.floor(h.State.FPS)
    end)
    ui:Label(section, "Runtime", function()
        return util.Duration(os.clock() - h.State.StartedAt)
    end)
    section = ui:Section(tab, "Scrap farm")
    ui:Label(section, "Status", function()
        return h.Features.ScrapFarm and h.Features.ScrapFarm.Status or "Unavailable"
    end)
    ui:Label(section, "Scrap collected / session scrap", function()
        return h.State.Stats.Scrap
    end)
    ui:Label(section, "Scrap per minute", function()
        return string.format(
            "%.1f",
            h.State.Stats.Scrap / math.max((os.clock() - h.State.StartedAt) / 60, 1 / 60)
        )
    end)
    ui:Label(section, "Current target", function()
        local f = h.Features.ScrapFarm
        return f and f.Target and f.Target.Name or "None"
    end)
    ui:Label(section, "Target distance", function()
        local f = h.Features.ScrapFarm
        return f and f.Target and string.format("%.0f studs", h.Adapter:Distance(f.Target)) or "—"
    end)
    section = ui:Section(tab, "Quick actions")
    for _, entry in ipairs({
        { "Auto Scrap", "Farming.AutoScrap" },
        { "Auto Fuel", "Generator.AutoFuel" },
        { "Auto Pickup", "Farming.AutoPickup" },
        { "Auto Repair", "Repair.Enabled" },
        { "Enemy ESP", "Visuals.Categories.Enemy.Enabled" },
    }) do
        ui:Toggle(section, entry[1], entry[2])
    end
    section = ui:Section(tab, "Session activity")
    for _, name in ipairs({ "Pickups", "Stored", "Repairs", "Attacks" }) do
        ui:Label(section, name, function()
            return h.State.Stats[name]
        end)
    end
    ui:Label(section, "Module errors", function()
        return util.Count(h.State.Errors)
    end)
end
return Dashboard

````

## FILE: ui/Farming.lua

````lua
local Panel = {}
function Panel.Build(ui, tab, h)
    local section
    section = ui:Section(tab, "Scrap grinding")
    ui:Toggle(section, "Auto Grind Scrap", "Farming.AutoScrap")
    ui:Choice(section, "Target priority", "Farming.ScrapPriority", { "Nearest", "Value" })
    ui:Number(section, "Search radius", "Farming.ScrapRadius", 5, 5000)
    ui:Number(section, "Interaction delay", "Farming.ScrapDelay", 0.1, 10)
    ui:Number(section, "Target timeout", "Farming.TargetTimeout", 3, 120)
    ui:Number(section, "Stuck timeout", "Farming.StuckTimeout", 1, 20)
    ui:Number(section, "Path retries", "Farming.PathRetries", 0, 10)
    ui:JSON(section, "Whitelist (JSON name: true)", "Farming.ScrapWhitelist")
    ui:JSON(section, "Blacklist (JSON name: true)", "Farming.ScrapBlacklist")
    section = ui:Section(tab, "Item and fuel farming")
    ui:Toggle(section, "Auto Item Farm", "Farming.AutoItems")
    ui:Number(section, "Item radius", "Farming.ItemRadius", 5, 5000)
    ui:JSON(section, "Item categories", "Farming.ItemCategories")
    ui:Toggle(section, "Build fuel reserve", "Farming.AutoFuelFarm")
    ui:Number(section, "Fuel reserve", "Farming.FuelReserve", 0, 1000)
    section = ui:Section(tab, "Pickup")
    ui:Toggle(section, "Auto Pickup", "Farming.AutoPickup")
    ui:Toggle(section, "All categories", "Farming.AllItems")
    ui:Number(section, "Pickup radius", "Farming.PickupRadius", 1, 100)
    ui:Number(section, "Pickup delay", "Farming.PickupDelay", 0.1, 10)
    ui:JSON(section, "Whitelist", "Farming.PickupWhitelist")
    ui:JSON(section, "Blacklist", "Farming.PickupBlacklist")
    ui:JSON(section, "Category filters", "Farming.PickupCategories")
    section = ui:Section(tab, "Storage")
    ui:Toggle(section, "Auto Store", "Storage.Enabled")
    ui:Toggle(section, "Only when inventory full", "Storage.OnlyWhenFull")
    ui:JSON(section, "Categories", "Storage.Categories")
    ui:JSON(section, "Keep items", "Storage.Keep")
    ui:JSON(section, "Minimum quantities", "Storage.Minimum")
    ui:Number(section, "Keep scrap", "Storage.ScrapReserve", 0, 10000)
    ui:Number(section, "Keep fuel per type", "Storage.FuelReserve", 0, 1000)
end
return Panel

````

## FILE: ui/Generator.lua

````lua
local Panel = {}
function Panel.Build(ui, tab, h)
    local section
    section = ui:Section(tab, "Generator automation")
    ui:Toggle(section, "Auto Fuel Generator", "Generator.AutoFuel")
    ui:Number(section, "Start below (%)", "Generator.FuelBelow", 1, 99)
    ui:Number(section, "Stop at (%)", "Generator.FuelUntil", 2, 100)
    ui:Number(section, "Emergency at (%)", "Generator.EmergencyFuel", 0, 99)
    ui:Number(section, "Fuel search radius", "Generator.FuelRadius", 5, 5000)
    ui:JSON(section, "Fuel priority (JSON array)", "Generator.FuelPriority")
    ui:Label(section, "Fuel", function()
        local p = h.Adapter:GetFuelPercent()
        return p and string.format("%s  %.0f%%", string.rep("|", math.floor(p / 10)), p) or "Unavailable"
    end)
    ui:Label(section, "Status", function()
        return h.Features.Generator and h.Features.Generator.Status or "Unavailable"
    end)
    ui:Label(section, "Current fuel", function()
        return h.Features.Generator and h.Features.Generator.CurrentFuel or "None"
    end)
end
return Panel

````

## FILE: ui/Interface.lua

````lua
local Interface = {}
Interface.__index = Interface
local function make(class, parent, properties)
    local object = Instance.new(class)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end
local function round(parent, radius)
    make("UICorner", parent, { CornerRadius = UDim.new(0, radius or 8) })
end
function Interface.new(h)
    local self = setmetatable({ H = h, Tabs = {}, Bindings = {}, Serial = 0 }, Interface)
    self.ThemeManager = h:Import("ThemeManager").new(self)
    self.Gui = make("ScreenGui", h.Services.Players.LocalPlayer:WaitForChild("PlayerGui"), {
        Name = "HESTIA",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 50,
    })
    self.Window = make("Frame", self.Gui, {
        Size = UDim2.fromOffset(860, 560),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(24, 24, 29),
        BorderSizePixel = 0,
    })
    round(self.Window, 12)
    self.Scale = make("UIScale", self.Window)
    local header = make("Frame", self.Window, { Size = UDim2.new(1, 0, 0, 76), BackgroundTransparency = 1 })
    local title = self:Text(header, "HESTIA", UDim2.fromOffset(24, 12), UDim2.fromOffset(300, 28), 25)
    self.ThemeManager:Track(title, "TextColor3")
    self:Text(header, "Survive the Apocalypse", UDim2.fromOffset(25, 43), UDim2.fromOffset(400, 20), 12)
    self:Text(
        header,
        "v" .. h.Version .. "  /  SURVIVAL AUTOMATION",
        UDim2.new(1, -335, 0, 24),
        UDim2.fromOffset(275, 25),
        11
    )
    self:ButtonAt(header, "×", UDim2.new(1, -48, 0, 18), UDim2.fromOffset(30, 30), function()
        self.Window.Visible = false
    end)
    self:Drag(header, self.Window)
    self.Nav = make("Frame", self.Window, {
        Position = UDim2.fromOffset(14, 88),
        Size = UDim2.new(0, 151, 1, -102),
        BackgroundColor3 = Color3.fromRGB(16, 16, 20),
        BorderSizePixel = 0,
    })
    round(self.Nav)
    make("UIListLayout", self.Nav, { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
    make(
        "UIPadding",
        self.Nav,
        { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }
    )
    self.Content = make("Frame", self.Window, {
        Position = UDim2.fromOffset(180, 88),
        Size = UDim2.new(1, -195, 1, -102),
        BackgroundTransparency = 1,
    })
    self.Toast = make("Frame", self.Gui, {
        Size = UDim2.fromOffset(320, 88),
        Position = UDim2.new(1, -336, 0, 24),
        BackgroundColor3 = Color3.fromRGB(28, 26, 36),
        Visible = false,
        BorderSizePixel = 0,
    })
    round(self.Toast)
    self.ToastTitle = self:Text(self.Toast, "HESTIA", UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 24), 15)
    self.ThemeManager:Track(self.ToastTitle, "TextColor3")
    self.ToastBody = self:Text(self.Toast, "", UDim2.fromOffset(14, 34), UDim2.new(1, -28, 0, 46), 12)
    self.ToastBody.TextWrapped = true
    self:Connect(h.Services.UserInputService.InputBegan, function(input, processed)
        if not processed and input.KeyCode.Name == h.Config.Interface.MenuKey then
            self.Window.Visible = not self.Window.Visible
        end
    end)
    self:ButtonAt(self.Gui, "H", UDim2.fromOffset(12, 90), UDim2.fromOffset(34, 34), function()
        self.Window.Visible = not self.Window.Visible
    end)
    return self
end
function Interface:Connect(signal, callback)
    self.Serial = self.Serial + 1
    self.H.Connections:Add(
        "HESTIA.UI." .. self.Serial,
        signal:Connect(function(...)
            local ok, err = pcall(callback, ...)
            if not ok then
                self.H.Logger:Log("ERROR", err)
                self:Notify("HESTIA", tostring(err))
            end
        end)
    )
end
function Interface:Text(parent, text, position, size, fontSize)
    return make("TextLabel", parent, {
        Text = text,
        Position = position,
        Size = size,
        TextSize = fontSize or 13,
        Font = Enum.Font.GothamMedium,
        TextColor3 = Color3.fromRGB(220, 220, 230),
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end
function Interface:ButtonAt(parent, text, position, size, callback)
    local button = make("TextButton", parent, {
        Text = text,
        Position = position,
        Size = size,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(232, 229, 245),
        BackgroundColor3 = Color3.fromRGB(47, 39, 65),
        BorderSizePixel = 0,
    })
    round(button, 6)
    self:Connect(button.Activated, callback)
    return button
end
function Interface:Drag(handle, frame)
    handle.Active = true
    local start, position, dragging, touch
    self:Connect(handle.InputBegan, function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            start, position, dragging = input.Position, frame.Position, true
            touch = input.UserInputType == Enum.UserInputType.Touch and input or nil
        end
    end)
    self:Connect(self.H.Services.UserInputService.InputChanged, function(input)
        if
            dragging
            and (input == touch or (not touch and input.UserInputType == Enum.UserInputType.MouseMovement))
        then
            local delta = input.Position - start
            frame.Position = UDim2.new(
                position.X.Scale,
                position.X.Offset + delta.X,
                position.Y.Scale,
                position.Y.Offset + delta.Y
            )
        end
    end)
    self:Connect(self.H.Services.UserInputService.InputEnded, function(input)
        if input == touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end
function Interface:AddTab(name)
    local tab = make("ScrollingFrame", self.Content, {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Visible = false,
    })
    make("UIListLayout", tab, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    make("UIPadding", tab, { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) })
    local button = self:ButtonAt(self.Nav, name, UDim2.new(), UDim2.new(1, 0, 0, 35), function()
        self:SelectTab(name)
    end)
    button.LayoutOrder = #self.Nav:GetChildren()
    self.Tabs[name] = { Frame = tab, Button = button }
    return tab
end
function Interface:SelectTab(name)
    for key, tab in pairs(self.Tabs) do
        tab.Frame.Visible = key == name
        self.H.Services.TweenService
            :Create(tab.Button, TweenInfo.new(0.15), {
                BackgroundColor3 = key == name and Color3.fromRGB(
                    table.unpack(self.H.Config.Interface.Accent)
                ) or Color3.fromRGB(27, 26, 33),
            })
            :Play()
    end
end
function Interface:Section(tab, name)
    local frame = make("Frame", tab, {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(17, 17, 22),
        BorderSizePixel = 0,
        LayoutOrder = #tab:GetChildren(),
    })
    round(frame)
    make("UIPadding", frame, {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
    })
    make("UIListLayout", frame, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
    local title = self:Text(frame, string.upper(name), UDim2.new(), UDim2.new(1, 0, 0, 25), 12)
    self.ThemeManager:Track(title, "TextColor3")
    return frame
end
function Interface:Row(section, text)
    local row = make(
        "Frame",
        section,
        { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = #section:GetChildren() }
    )
    self:Text(row, text, UDim2.new(), UDim2.new(0.6, 0, 1, 0))
    return row
end
function Interface:Label(section, text, getter)
    local row = self:Row(section, text)
    local value = self:Text(row, "", UDim2.fromScale(0.48, 0), UDim2.fromScale(0.52, 1))
    value.TextXAlignment = Enum.TextXAlignment.Right
    table.insert(self.Bindings, function()
        value.Text = tostring(getter())
    end)
    return value
end
function Interface:Toggle(section, label, path)
    local row = self:Row(section, label)
    local button = self:ButtonAt(row, "OFF", UDim2.new(1, -64, 0, 2), UDim2.fromOffset(64, 28), function()
        self.H:Set(path, not self.H:Get(path))
    end)
    table.insert(self.Bindings, function()
        local enabled = self.H:Get(path)
        button.Text = enabled and "ON" or "OFF"
        button.BackgroundColor3 = enabled and Color3.fromRGB(table.unpack(self.H.Config.Interface.Accent))
            or Color3.fromRGB(44, 43, 51)
    end)
end
function Interface:Input(section, label, getter, setter)
    local row = self:Row(section, label)
    local box = make("TextBox", row, {
        Size = UDim2.new(0.45, 0, 0, 28),
        Position = UDim2.new(0.55, 0, 0, 2),
        BackgroundColor3 = Color3.fromRGB(32, 31, 40),
        TextColor3 = Color3.fromRGB(222, 217, 238),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Text = tostring(getter()),
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
    })
    round(box, 5)
    self:Connect(box.FocusLost, function()
        setter(box.Text)
        box.Text = tostring(getter())
    end)
    table.insert(self.Bindings, function()
        if not box:IsFocused() then
            box.Text = tostring(getter())
        end
    end)
    return box
end
function Interface:Number(section, label, path, minimum, maximum)
    self:Input(section, label, function()
        return self.H:Get(path)
    end, function(text)
        local value = tonumber(text)
        assert(
            value and value == value and value >= minimum and value <= maximum,
            "HESTIA expected " .. minimum .. " to " .. maximum
        )
        self.H:Set(path, value)
    end)
end
function Interface:Choice(section, label, path, choices)
    local row = self:Row(section, label)
    local button = self:ButtonAt(row, "", UDim2.new(0.58, 0, 0, 2), UDim2.new(0.42, 0, 0, 28), function()
        local index = table.find(choices, self.H:Get(path)) or 0
        self.H:Set(path, choices[index % #choices + 1])
    end)
    table.insert(self.Bindings, function()
        button.Text = tostring(self.H:Get(path))
    end)
end
function Interface:JSON(section, label, path)
    self:Input(section, label, function()
        return self.H.Services.HttpService:JSONEncode(self.H:Get(path))
    end, function(text)
        self.H:Set(path, self.H.Services.HttpService:JSONDecode(text))
    end)
end
function Interface:Button(section, label, callback)
    local button = self:ButtonAt(section, label, UDim2.new(), UDim2.new(1, 0, 0, 32), callback)
    button.LayoutOrder = #section:GetChildren()
    return button
end
function Interface:Notify(title, text)
    self.ToastTitle.Text, self.ToastBody.Text, self.Toast.Visible = title, text, true
    self.ToastExpires = os.clock() + 6
    self.Toast.Position = self.H.Config.Interface.NotificationSide == "Left" and UDim2.fromOffset(16, 24)
        or UDim2.new(1, -336, 0, 24)
end
function Interface:Refresh()
    if self.ToastExpires and os.clock() > self.ToastExpires then
        self.Toast.Visible = false
    end
    local camera = workspace.CurrentCamera
    if camera then
        self.Scale.Scale = math.min(1, (camera.ViewportSize.X - 20) / 860, (camera.ViewportSize.Y - 40) / 560)
    end
    for _, binding in ipairs(self.Bindings) do
        binding()
    end
    if self.Widget then
        self.Widget:Refresh()
    end
end
function Interface:Start()
    for _, name in ipairs({
        "Dashboard",
        "Farming",
        "Generator",
        "Combat",
        "Visuals",
        "Player",
        "Teleports",
        "Misc",
        "Settings",
    }) do
        local tab = self:AddTab(name)
        local ok, err = pcall(function()
            self.H:Import("ui/" .. name .. ".lua").Build(self, tab, self.H)
        end)
        if not ok then
            self.H.Logger:Log("ERROR", name .. " UI: " .. tostring(err))
        end
    end
    self.Widget = self.H:Import("Widget").new(self)
    self:SelectTab("Dashboard")
    self:Refresh()
    self.H.Scheduler:Add("UI", 0.5, function()
        self:Refresh()
    end)
end
function Interface:Destroy()
    self.H.Scheduler:Remove("UI")
    self.Gui:Destroy()
    table.clear(self.Bindings)
end
Interface.Make = make
Interface.Round = round
return Interface

````

## FILE: ui/Misc.lua

````lua
local Panel = {}
function Panel.Build(ui, tab, h)
    local section
    section = ui:Section(tab, "Structure repair")
    ui:Toggle(section, "Auto Repair", "Repair.Enabled")
    ui:Choice(section, "Priority", "Repair.Priority", { "Nearest", "LowestHealth" })
    ui:Number(section, "Radius", "Repair.Radius", 1, 100)
    ui:Number(section, "Repair interval", "Repair.Rate", 0.2, 10)
    ui:Toggle(section, "Emergency repair priority", "Repair.Emergency")
    ui:Number(section, "Emergency below (%)", "Repair.EmergencyBelow", 1, 100)
    section = ui:Section(tab, "Utilities")
    ui:Toggle(section, "Fullbright", "Visuals.Fullbright")
    ui:Toggle(section, "Debug logging", "Debug")
    ui:Label(section, "Structure health", function()
        return h.Features.Repair and h.Features.Repair.Status or "Disabled"
    end)
    ui:Button(section, "Rejoin this place", function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, h.Services.Players.LocalPlayer)
    end)
end
return Panel

````

## FILE: ui/Player.lua

````lua
local Panel = {}
function Panel.Build(ui, tab, h)
    local section
    section = ui:Section(tab, "Movement")
    ui:Toggle(section, "Override movement values", "Player.OverrideMovement")
    ui:Toggle(section, "Auto Sprint", "Player.AutoSprint")
    ui:Number(section, "Walk speed", "Player.WalkSpeed", 0, 100)
    ui:Number(section, "Sprint speed", "Player.SprintSpeed", 0, 150)
    ui:Number(section, "Jump power", "Player.JumpPower", 0, 150)
    ui:Toggle(section, "Infinite Jump", "Player.InfiniteJump")
    ui:Toggle(section, "Bunny Hop", "Player.BunnyHop")
    ui:Toggle(section, "Noclip", "Player.Noclip")
    ui:Toggle(section, "Fly (WASD / Space / Ctrl)", "Player.Fly")
    ui:Number(section, "Fly speed", "Player.FlySpeed", 1, 150)
    ui:Button(section, "Reset Movement", function()
        h.Features.Movement:Reset()
    end)
end
return Panel

````

## FILE: ui/Settings.lua

````lua
local Settings = {}
function Settings.Build(ui, tab, h)
    local section = ui:Section(tab, "HESTIA appearance")
    ui:JSON(section, "Accent [R,G,B]", "Interface.Accent")
    ui:Choice(section, "Menu key", "Interface.MenuKey", { "RightShift", "RightControl", "F4", "Insert" })
    ui:Choice(section, "Notification side", "Interface.NotificationSide", { "Right", "Left" })
    ui:Toggle(section, "Floating widget", "Interface.Widget")
    ui:Toggle(section, "Collapse widget", "Interface.WidgetCollapsed")
    ui:Number(section, "Widget opacity", "Interface.WidgetOpacity", 0.1, 1)
    section = ui:Section(tab, "Configuration")
    local raw = ""
    local box = ui:Input(section, "Configuration JSON", function()
        return raw
    end, function(value)
        raw = value
    end)
    box.MultiLine = true
    ui:Button(section, "Export config to text field", function()
        raw = h.ConfigStore:Export()
        box.Text = raw
        box:CaptureFocus()
    end)
    ui:Button(section, "Import config from text field", function()
        raw = box.Text
        h.ConfigStore:Import(raw)
        h.Notifications:Send("Configuration imported.")
    end)
    ui:Button(section, "Save configuration", function()
        h.ConfigStore:Save()
    end)
    ui:Button(section, "Load configuration", function()
        local ok, err = h.ConfigStore:Load()
        if not ok then
            h.Notifications:Send(tostring(err))
        end
    end)
    section = ui:Section(tab, "Release and diagnostics")
    ui:Label(section, "Installed", function()
        return h.Version
    end)
    ui:Label(section, "Channel", function()
        return h.Release and h.Release.channel or h.Root:GetAttribute("Channel")
    end)
    ui:Label(section, "Latest checked at installation", function()
        return h.Release and h.Release.version or "Unavailable"
    end)
    ui:Button(section, "Print changelog", function()
        for _, line in ipairs(h.Release and h.Release.changelog or {}) do
            h.Logger:Log("INFO", line)
        end
    end)
    ui:Button(section, "Print diagnostics", function()
        for _, line in ipairs(h.Logger.History) do
            print(line)
        end
    end)
    ui:Button(section, "Unload HESTIA", function()
        h:Unload()
    end)
end
return Settings

````

## FILE: ui/Teleports.lua

````lua
local Panel = {}
function Panel.Build(ui, tab, h)
    local section = ui:Section(tab, "Locations")
    local function go(name)
        local ok, reason = h.Features.Teleports:Go(name)
        if not ok then
            h.Notifications:Send(reason or "Teleport unavailable.")
        end
    end
    for _, name in ipairs({
        "Spawn",
        "Generator",
        "Nearest Scrap",
        "Nearest Fuel",
        "Nearest Chest",
        "Nearest Enemy",
        "Selected Player",
    }) do
        ui:Button(section, name, function()
            go(name)
        end)
    end
    ui:Input(section, "Selected player username", function()
        return h.Config.Teleports.SelectedPlayer
    end, function(value)
        h:Set("Teleports.SelectedPlayer", value)
    end)
    section = ui:Section(tab, "Custom locations")
    local selected = "Camp"
    ui:Input(section, "Location name", function()
        return selected
    end, function(value)
        selected = value
    end)
    ui:Button(section, "Save current position", function()
        if h.Features.Teleports:Save(selected) then
            h.Notifications:Send("Location saved: " .. selected)
        end
    end)
    ui:Button(section, "Teleport to saved location", function()
        go(selected)
    end)
    ui:Button(section, "Delete saved location", function()
        h.Config.Teleports.Saved[selected] = nil
    end)
    ui:JSON(section, "Saved locations", "Teleports.Saved")
end
return Panel

````

## FILE: ui/ThemeManager.lua

````lua
local Theme = {}
Theme.__index = Theme
function Theme.new(ui)
    return setmetatable({ UI = ui, Accents = {} }, Theme)
end
function Theme:Track(instance, property)
    table.insert(self.Accents, { instance, property })
    instance[property] = Color3.fromRGB(table.unpack(self.UI.H.Config.Interface.Accent))
end
function Theme:Apply()
    local color = Color3.fromRGB(table.unpack(self.UI.H.Config.Interface.Accent))
    for _, item in ipairs(self.Accents) do
        if item[1].Parent then
            item[1][item[2]] = color
        end
    end
end
function Theme:SetColor(rgb)
    self.UI.H:Set("Interface.Accent", rgb)
    self:Apply()
end
return Theme

````

## FILE: ui/Visuals.lua

````lua
local Visuals = {}
function Visuals.Build(ui, tab, h)
    local section = ui:Section(tab, "ESP settings")
    ui:Number(section, "Global maximum distance", "Visuals.MaxDistance", 10, 10000)
    local categories = {}
    for name in pairs(h.Config.Visuals.Categories) do
        table.insert(categories, name)
    end
    table.sort(categories)
    for _, name in ipairs(categories) do
        section = ui:Section(tab, name)
        local path = "Visuals.Categories." .. name .. "."
        for _, key in ipairs({ "Enabled", "Highlight", "Name", "Distance", "Health" }) do
            ui:Toggle(section, key, path .. key)
        end
        ui:Number(section, "Maximum distance", path .. "MaxDistance", 1, 10000)
        ui:JSON(section, "Color [R,G,B]", path .. "Color")
    end
end
return Visuals

````

## FILE: ui/Widget.lua

````lua
local Widget = {}
Widget.__index = Widget
function Widget.new(ui)
    local self = setmetatable({ UI = ui }, Widget)
    self.Frame = ui.Make("Frame", ui.Gui, {
        Name = "HESTIA Status",
        Position = UDim2.new(1, -265, 0.5, -110),
        Size = UDim2.fromOffset(245, 200),
        BackgroundColor3 = Color3.fromRGB(20, 18, 28),
        BorderSizePixel = 0,
    })
    ui.Round(self.Frame, 10)
    local header = ui:Text(self.Frame, "HESTIA", UDim2.fromOffset(14, 8), UDim2.new(1, -58, 0, 28), 17)
    ui.ThemeManager:Track(header, "TextColor3")
    ui:Drag(header, self.Frame)
    ui:ButtonAt(self.Frame, "−", UDim2.new(1, -42, 0, 8), UDim2.fromOffset(28, 26), function()
        ui.H:Set("Interface.WidgetCollapsed", not ui.H.Config.Interface.WidgetCollapsed)
    end)
    self.Body = ui:Text(self.Frame, "", UDim2.fromOffset(14, 46), UDim2.new(1, -28, 1, -54), 13)
    self.Body.TextYAlignment = Enum.TextYAlignment.Top
    self.Body.TextWrapped = true
    return self
end
function Widget:Refresh()
    local h, c = self.UI.H, self.UI.H.Config.Interface
    self.Frame.Visible = c.Widget
    self.Frame.BackgroundTransparency = 1 - c.WidgetOpacity
    self.Frame.Size = UDim2.fromOffset(245, c.WidgetCollapsed and 44 or 200)
    self.Body.Visible = not c.WidgetCollapsed
    local percent = h.Adapter:GetFuelPercent()
    self.Body.Text = string.format(
        "Task       %s\n\nGenerator  %s\nScrap      %d\nRate       %.1f/min\nEnemies    %d",
        h.Tasks.Active or "Idle",
        percent and string.format("%.0f%%", percent) or "Unknown",
        h.State.Stats.Scrap,
        h.State.Stats.Scrap / math.max((os.clock() - h.State.StartedAt) / 60, 1 / 60),
        h:Import("Utilities").Count(h.Registry.Enemies)
    )
end
return Widget

````

## FILE: version.json

````json
{
  "name": "HESTIA",
  "version": "1.0.0",
  "channel": "stable",
  "changelog": [
    "HESTIA modular Studio package with GitHub installation and independent feature modules.",
    "Priority arbitration, event-driven registries, generator automation and shared ESP scheduler.",
    "Native charcoal and violet dashboard, config persistence, and complete client cleanup."
  ]
}

````

