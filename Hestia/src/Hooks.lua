-- STA remote paths and item argument verified against the user-supplied reference:
-- https://raw.githubusercontent.com/HxnryLSD/SPYMM-rblx/refs/heads/main/SPYMM-STA-Latest.lua
-- RemoteEvents acknowledge sending only; inventory replication confirms ownership.
local Hooks = {}
local storeCategories = { Food = true, Fuel = true, Resource = true, Scrap = true, Ability = true }
local storeNames = { ["Power Armor Arm"] = true, ["Power Armor Core"] = true, ["Radio Tower Part"] = true }

-- Dependencies are explicit so the protocol can be tested without Roblox/network calls.
function Hooks.CreatePickup(storage, player, world, wait, clock)
    local function remote(group, name)
        local remotes = storage:FindFirstChild("Remotes")
        local folder = remotes and remotes:FindFirstChild(group)
        local value = folder and folder:FindFirstChild(name)
        return value and value:IsA("RemoteEvent") and value or nil
    end
    local function owned(name)
        local count = 0
        for _, container in pairs({ player:FindFirstChild("Backpack"), player.Character }) do
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool.Name == name then
                    local quantity = tool:GetAttribute("Quantity")
                    count = count + (type(quantity) == "number" and math.max(quantity, 0) or 1)
                end
            end
        end
        return count
    end
    return function(item, category)
        local drops = world:FindFirstChild("DroppedItems")
        if not drops or not item or item.Parent ~= drops then
            return false, "STA pickup requires an item in Workspace.DroppedItems"
        end
        if not player.Character then
            return false, "Waiting for character"
        end
        local pickup = remote("Interaction", "PickUpItem")
        local backpack = remote("Tools", "AdjustBackpack")
        local storeOnly = storeCategories[category] or storeNames[item.Name]
        if storeOnly and not backpack then
            return false, "Missing Remotes.Tools.AdjustBackpack"
        end
        if not storeOnly and not pickup and not backpack then
            return false, "Missing STA pickup remotes"
        end
        local name, before = item.Name, owned(item.Name)
        local sent, failure = false, nil
        local function send(event)
            if event then
                local ok, reason = pcall(function()
                    event:FireServer(item)
                end)
                sent = sent or ok
                if not ok then
                    failure = tostring(reason)
                end
            end
        end
        if not storeOnly then
            send(pickup)
        end
        send(backpack)
        if not sent then
            return false, failure or "Pickup request failed"
        end
        local deadline = clock() + 0.75
        repeat
            local quantity = owned(name) - before
            if quantity > 0 then
                return true, quantity, true
            end
            wait(0.05)
        until clock() >= deadline
        -- Disappearance alone may be another player picking up the item.
        -- Third result indicates a sent request, not a successful collection.
        return false, "Request sent; inventory confirmation unavailable", true
    end
end
-- Equipped-tool protocols from the same STA reference.
function Hooks.CreateActions(player, players, wait, clock)
    local function event(tool, name)
        local value = tool and tool:FindFirstChild(name)
        return value and value:IsA("RemoteEvent") and value or nil
    end
    local function health(target)
        local hum = target:FindFirstChildOfClass("Humanoid")
        return hum and hum.Health or target:GetAttribute("Health")
    end
    local function confirm(target, before, increasing)
        local deadline = clock() + 0.4
        repeat
            local after = health(target)
            if
                type(before) == "number"
                and type(after) == "number"
                and ((increasing and after > before) or (not increasing and after < before))
            then
                return true, 1, true
            end
            wait(0.05)
        until clock() >= deadline
        return false, "Request sent; health change unconfirmed", true
    end
    return {
        AttackTarget = function(target)
            if not target or not target:IsA("Model") or players:GetPlayerFromCharacter(target) then
                return false, "NPC target required"
            end
            local char = player.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if not tool then
                return false, "Equip a supported weapon"
            end
            local before = health(target)
            if type(before) ~= "number" or before <= 0 then
                return false, "No living target"
            end
            local swing, hit, click =
                event(tool, "Swing"), event(tool, "HitTargets"), event(tool, "RemoteClick")
            local ok, reason = pcall(function()
                if swing and hit then
                    swing:FireServer()
                    hit:FireServer({ target })
                elseif click then
                    click:FireServer(target)
                else
                    error("Weapon has no supported attack remote")
                end
            end)
            if not ok then
                return false, tostring(reason)
            end
            return confirm(target, before, false)
        end,
        RepairStructure = function(target)
            local char = player.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if not tool or tool.Name ~= "Repair Hammer" then
                return false, "Equip Repair Hammer"
            end
            local repair = event(tool, "Repair")
            if not repair then
                return false, "Repair Hammer has no Repair remote"
            end
            if not target or not target.Parent then
                return false, "Structure unavailable"
            end
            local before = health(target)
            local ok, reason = pcall(function()
                repair:FireServer(target)
            end)
            if not ok then
                return false, tostring(reason)
            end
            return confirm(target, before, true)
        end,
    }
end
local function actions()
    local players = game:GetService("Players")
    return Hooks.CreateActions(players.LocalPlayer, players, task.wait, os.clock)
end
function Hooks.AttackTarget(target)
    return actions().AttackTarget(target)
end
function Hooks.RepairStructure(target)
    return actions().RepairStructure(target)
end
function Hooks.CollectItem(item, category)
    return Hooks.CreatePickup(
        game:GetService("ReplicatedStorage"),
        game:GetService("Players").LocalPlayer,
        workspace,
        task.wait,
        os.clock
    )(item, category)
end
return Hooks
