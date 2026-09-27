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
