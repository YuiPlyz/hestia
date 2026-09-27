local Store = {}
Store.__index = Store

function Store.new(h)
    return setmetatable({
        H = h,
        Status = "Idle",
        LastStore = 0,
    }, Store)
end

local function safeCall(label, fn)
    local ok, a, b, c = pcall(fn)

    if not ok then
        warn(
            "[HESTIA][AutoStore][" .. tostring(label) .. "] "
                .. tostring(a)
        )

        return false
    end

    return true, a, b, c
end

function Store:Release()
    local h = self.H

    if h.Tasks then
        pcall(function()
            h.Tasks:Release("AutoStore")
        end)
    end

    if h.Navigator then
        pcall(function()
            h.Navigator:Cancel("AutoStore")
        end)
    end
end

function Store:GetInventory()
    local h = self.H

    local ok, inventory = safeCall("GetInventory", function()
        return h.Adapter:GetInventory()
    end)

    if not ok or type(inventory) ~= "table" then
        return {}
    end

    return inventory
end

function Store:FindItemToStore(inventory)
    local h = self.H
    local config = h.Config.Storage

    local totals = {}

    --------------------------------------------------
    -- Calculate total amount of every item
    --------------------------------------------------

    for _, item in ipairs(inventory) do
        if item then
            local name = tostring(item.Name or "")
            local quantity = tonumber(item.Quantity) or 0

            if name ~= "" then
                totals[name] =
                    (totals[name] or 0)
                    + quantity
            end
        end
    end

    --------------------------------------------------
    -- Find something that can be stored
    --------------------------------------------------

    for _, item in ipairs(inventory) do
        if item then
            local name = tostring(item.Name or "")
            local category = item.Category

            local quantity =
                tonumber(item.Quantity) or 0

            local instance =
                item.Instance

            --------------------------------------------------
            -- Category enabled?
            --------------------------------------------------

            local categoryEnabled = true

            if type(config.Categories) == "table" then
                categoryEnabled =
                    config.Categories[category] == true
            end

            --------------------------------------------------
            -- Keep item?
            --------------------------------------------------

            local keepItem = false

            if type(config.Keep) == "table" then
                keepItem =
                    config.Keep[name] == true
            end

            if
                categoryEnabled
                and not keepItem
                and instance
                and quantity > 0
            then
                --------------------------------------------------
                -- Reserve amount
                --------------------------------------------------

                local reserve = 0

                if type(config.Minimum) == "table" then
                    reserve =
                        tonumber(config.Minimum[name])
                        or 0
                end

                if category == "Scrap" then
                    reserve = math.max(
                        reserve,
                        tonumber(config.ScrapReserve)
                            or 0
                    )
                end

                if category == "Fuel" then
                    reserve = math.max(
                        reserve,
                        tonumber(config.FuelReserve)
                            or 0
                    )
                end

                --------------------------------------------------
                -- Calculate amount above reserve
                --------------------------------------------------

                local total =
                    tonumber(totals[name])
                    or quantity

                local excess =
                    math.max(total - reserve, 0)

                local amount =
                    math.min(quantity, excess)

                if amount > 0 then
                    return instance, amount, item
                end
            end
        end
    end

    return nil
end

function Store:Step()
    local h = self.H

    if
        not h
        or not h.Config
        or not h.Config.Storage
        or not h.Adapter
    then
        self.Status = "Configuration unavailable"
        return
    end

    local config = h.Config.Storage

    --------------------------------------------------
    -- Check inventory status
    --------------------------------------------------

    local inventoryFull = false

    local fullOK, fullResult =
        safeCall("InventoryFull", function()
            return h.Adapter:InventoryFull()
        end)

    if fullOK then
        inventoryFull =
            fullResult == true
    end

    --------------------------------------------------
    -- Only store when inventory is full
    --------------------------------------------------

    if
        config.OnlyWhenFull
        and not inventoryFull
    then
        self.Status = "Waiting for full inventory"

        self:Release()

        return
    end

    --------------------------------------------------
    -- Find storage
    --------------------------------------------------

    local storageOK, storage =
        safeCall("GetStorage", function()
            return h.Adapter:GetStorage()
        end)

    if not storageOK or not storage then
        self.Status = "Storage unavailable"

        self:Release()

        return
    end

    --------------------------------------------------
    -- Read inventory
    --------------------------------------------------

    local inventory =
        self:GetInventory()

    if #inventory == 0 then
        self.Status = "Inventory empty"

        self:Release()

        return
    end

    --------------------------------------------------
    -- Find item
    --------------------------------------------------

    local selected, amount, data =
        self:FindItemToStore(inventory)

    if not selected or not amount then
        self.Status = "Nothing to store"

        self:Release()

        return
    end

    --------------------------------------------------
    -- Request AutoStore task
    --------------------------------------------------

    local priority =
        inventoryFull
        and 55
        or 35

    local taskGranted = true

    if h.Tasks then
        local requestOK, result =
            safeCall("Task Request", function()
                return h.Tasks:Request(
                    "AutoStore",
                    priority
                )
            end)

        taskGranted =
            requestOK
            and result ~= false
    end

    if not taskGranted then
        self.Status = "Paused"

        return
    end

    --------------------------------------------------
    -- Navigate to storage
    --------------------------------------------------

    if not h.Navigator then
        self.Status = "Navigator unavailable"

        self:Release()

        return
    end

    local navigateOK, navigationStatus =
        safeCall("Navigation", function()
            return h.Navigator:Step(
                "AutoStore",
                storage,
                tonumber(config.Range)
                    or 5
            )
        end)

    if not navigateOK then
        self.Status = "Navigation failed"

        self:Release()

        return
    end

    self.Status =
        navigationStatus
        or "Moving"

    --------------------------------------------------
    -- Wait until we arrive
    --------------------------------------------------

    if navigationStatus ~= "Arrived" then
        return
    end

    --------------------------------------------------
    -- Optional ownership check
    --------------------------------------------------

    if h.Tasks and h.Tasks.IsOwner then
        local ownerOK, owns =
            safeCall("Task Owner", function()
                return h.Tasks:IsOwner(
                    "AutoStore"
                )
            end)

        -- Only reject when the task manager
        -- explicitly says another task owns control.
        if ownerOK and owns == false then
            self.Status = "Lost task ownership"
            return
        end
    end

    --------------------------------------------------
    -- Store item
    --------------------------------------------------

    local now = os.clock()

    local delay =
        tonumber(config.StoreDelay)
        or 0.15

    if now < self.LastStore + delay then
        return
    end

    self.LastStore = now

    local storeOK, success, confirmed =
        safeCall("StoreItem", function()
            return h.Adapter:StoreItem(
                selected,
                amount,
                storage
            )
        end)

    --------------------------------------------------
    -- Adapter itself errored
    --------------------------------------------------

    if not storeOK then
        self.Status = "Store error"

        self:Release()

        return
    end

    --------------------------------------------------
    -- Adapter returned false
    --------------------------------------------------

    if not success then
        self.Status =
            "Store rejected: "
            .. tostring(
                data
                and data.Name
                or selected
            )

        self:Release()

        return
    end

    --------------------------------------------------
    -- Success
    --------------------------------------------------

    local storedAmount =
        type(confirmed) == "number"
        and confirmed
        or amount

    if h.State then
        h.State.Stats =
            h.State.Stats
            or {}

        h.State.Stats.Stored =
            (h.State.Stats.Stored or 0)
            + storedAmount
    end

    self.Status =
        "Stored "
        .. tostring(storedAmount)
        .. "x "
        .. tostring(
            data
            and data.Name
            or "item"
        )

    --------------------------------------------------
    -- Release so next item can be processed
    --------------------------------------------------

    if h.Tasks then
        pcall(function()
            h.Tasks:Release("AutoStore")
        end)
    end

    if h.Navigator then
        pcall(function()
            h.Navigator:Cancel("AutoStore")
        end)
    end
end

function Store:Start()
    local h = self.H

    if not h or not h.Scheduler then
        warn(
            "[HESTIA][AutoStore] Scheduler unavailable"
        )

        return
    end

    --------------------------------------------------
    -- Prevent duplicate scheduler
    --------------------------------------------------

    pcall(function()
        h.Scheduler:Remove("AutoStore")
    end)

    h.Scheduler:Add(
        "AutoStore",
        0.25,

        function()
            local ok, err =
                pcall(function()
                    self:Step()
                end)

            if not ok then
                warn(
                    "[HESTIA][AutoStore] "
                        .. tostring(err)
                )

                self.Status = "Error"
                self:Release()
            end
        end,

        function()
            self:Stop()
        end
    )

    self.Status = "Started"

    print(
        "[HESTIA][AutoStore] Started"
    )
end

function Store:Stop()
    local h = self.H

    if h and h.Scheduler then
        pcall(function()
            h.Scheduler:Remove(
                "AutoStore"
            )
        end)
    end

    self:Release()

    self.Status = "Stopped"
end

Store.Destroy = Store.Stop

return Store
