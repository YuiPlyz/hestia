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
    ui:Choice(section, "Selected player", "Teleports.SelectedPlayer", function()
        local names = {}
        for _, player in ipairs(h.Services.Players:GetPlayers()) do
            if player ~= h.Services.Players.LocalPlayer then
                table.insert(names, player.Name)
            end
        end
        table.sort(names)
        return names
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
