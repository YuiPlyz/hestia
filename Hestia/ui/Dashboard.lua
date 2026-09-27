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
