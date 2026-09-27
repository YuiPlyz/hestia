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
