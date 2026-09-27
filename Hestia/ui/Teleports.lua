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
