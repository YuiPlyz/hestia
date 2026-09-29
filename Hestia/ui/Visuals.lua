local Visuals = {}
function Visuals.Build(ui, tab, h)
    local section = ui:Section(tab, "ESP settings")
    ui:Number(section, "Distance (0 = unlimited)", "Visuals.MaxDistance", 0, 1000000)
    ui:Number(section, "Text size", "Visuals.TextSize", 8, 32)
    ui:Number(section, "Highlight transparency", "Visuals.FillTransparency", 0, 1)
    ui:Number(section, "Outline transparency", "Visuals.OutlineTransparency", 0, 1)
    ui:Toggle(section, "Fullbright", "Visuals.Fullbright")
    ui:Toggle(section, "Remove fog", "Visuals.RemoveFog")
    ui:Button(section, "Enable all ESP", function()
        for name in pairs(h.Config.Visuals.Categories) do
            h:Set("Visuals.Categories." .. name .. ".Enabled", true)
        end
    end)
    ui:Button(section, "Disable all ESP", function()
        for name in pairs(h.Config.Visuals.Categories) do
            h:Set("Visuals.Categories." .. name .. ".Enabled", false)
        end
    end)
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
        ui:Number(section, "Distance (0 = unlimited)", path .. "MaxDistance", 0, 1000000)
        ui:JSON(section, "Color [R,G,B]", path .. "Color")
    end
end
return Visuals
