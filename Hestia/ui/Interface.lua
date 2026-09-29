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
function Interface:Toggle(section, label, path, requiredHook)
    local row = self:Row(section, label)
    local button = self:ButtonAt(row, "OFF", UDim2.new(1, -64, 0, 2), UDim2.fromOffset(64, 28), function()
        if requiredHook and not self.H:Get(path) and not self.H.Adapter.Hooks[requiredHook] then
            self:Notify(
                "Integration unavailable",
                label .. " needs " .. requiredHook .. "; the STA reference does not implement it."
            )
            return
        end
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
-- Native Roblox equivalent of a searchable select/options control.
function Interface:Select(section, label, getter, setter, choices, multiple)
    local row = self:Row(section, label)
    local panel = make("Frame", row, {
        Position = UDim2.fromOffset(0, 36),
        Size = UDim2.new(1, 0, 0, 220),
        BackgroundTransparency = 1,
        Visible = false,
    })
    local search = make("TextBox", panel, {
        Size = UDim2.new(1, 0, 0, 30),
        Text = "",
        PlaceholderText = "Search options...",
        ClearTextOnFocus = false,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextColor3 = Color3.fromRGB(232, 229, 245),
        BackgroundColor3 = Color3.fromRGB(32, 31, 40),
    })
    local list = make("ScrollingFrame", panel, {
        Position = UDim2.fromOffset(0, 66),
        Size = UDim2.new(1, 0, 1, -66),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
    })
    make("UIListLayout", list, { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
    local optionConnections = {}
    local function clear()
        for _, connection in ipairs(optionConnections) do
            connection:Disconnect()
        end
        table.clear(optionConnections)
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
    end
    local function available()
        local values, seen = {}, {}
        for _, value in ipairs(type(choices) == "function" and choices() or choices) do
            if not seen[value] then
                seen[value] = true
                table.insert(values, value)
            end
        end
        if multiple then
            for value in pairs(getter()) do
                if not seen[value] then
                    table.insert(values, value)
                end
            end
        end
        return values
    end
    local render
    local function close()
        panel.Visible = false
        row.Size = UDim2.new(1, 0, 0, 32)
        clear()
    end
    render = function()
        clear()
        local query = string.lower(search.Text)
        for index, value in ipairs(available()) do
            if string.find(string.lower(value), query, 1, true) then
                local selected = multiple and getter()[value] == true or getter() == value
                local option = make("TextButton", list, {
                    Size = UDim2.new(1, -8, 0, 30),
                    LayoutOrder = index,
                    Text = (selected and "[x] " or "[ ] ") .. value,
                    TextSize = 13,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = Color3.fromRGB(232, 229, 245),
                    BackgroundColor3 = Color3.fromRGB(47, 39, 65),
                    BorderSizePixel = 0,
                })
                table.insert(
                    optionConnections,
                    option.Activated:Connect(function()
                        local ok, err = pcall(function()
                            if multiple then
                                local nextValue = table.clone(getter())
                                nextValue[value] = not nextValue[value] and true or nil
                                setter(nextValue)
                                render()
                            else
                                setter(value)
                                close()
                            end
                        end)
                        if not ok then
                            self:Notify("Selection failed", tostring(err))
                        end
                    end)
                )
            end
        end
    end
    local button = self:ButtonAt(
        row,
        "Select...",
        UDim2.new(0.58, 0, 0, 2),
        UDim2.new(0.42, 0, 0, 28),
        function()
            if panel.Visible then
                close()
            else
                panel.Visible = true
                row.Size = UDim2.new(1, 0, 0, 260)
                render()
            end
        end
    )
    self:ButtonAt(panel, "Done", UDim2.new(0.7, 0, 0, 34), UDim2.new(0.3, 0, 0, 28), close)
    if multiple then
        self:ButtonAt(panel, "Select all", UDim2.fromOffset(0, 34), UDim2.new(0.34, 0, 0, 28), function()
            local value = {}
            for _, name in ipairs(available()) do
                value[name] = true
            end
            setter(value)
            render()
        end)
        self:ButtonAt(panel, "Clear", UDim2.new(0.36, 0, 0, 34), UDim2.new(0.3, 0, 0, 28), function()
            setter({})
            render()
        end)
    end
    self:Connect(search:GetPropertyChangedSignal("Text"), function()
        if panel.Visible then
            render()
        end
    end)
    self:Connect(row.Destroying, clear)
    table.insert(self.Bindings, function()
        if multiple then
            local count = 0
            for _, selected in pairs(getter()) do
                if selected then
                    count = count + 1
                end
            end
            button.Text = count .. " selected  v"
        else
            button.Text = tostring(getter()) .. "  v"
        end
    end)
end
function Interface:Choice(section, label, path, choices)
    self:Select(section, label, function()
        return self.H:Get(path)
    end, function(value)
        self.H:Set(path, value)
    end, choices, false)
end
function Interface:Filter(section, label, path, categories)
    self:Select(section, label, function()
        return self.H:Get(path)
    end, function(value)
        self.H:Set(path, value)
    end, function()
        local values = {}
        for category, names in pairs(self.H:Import("Items")) do
            if categories then
                table.insert(values, category)
            else
                for _, name in ipairs(names) do
                    table.insert(values, name)
                end
            end
        end
        for object in pairs(self.H.Registry.Items) do
            table.insert(values, categories and self.H.Adapter:Category(object) or object.Name)
        end
        table.sort(values)
        return values
    end, true)
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
