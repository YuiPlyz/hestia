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
