local Runtime = {}
function Runtime.Start(repository, capabilities)
    local environment = capabilities.Environment
    local source = capabilities.Fetch(capabilities.BaseURL .. "src/RemoteImporter.lua")
    local chunk, reason = capabilities.Compile(source, "HESTIA/RemoteImporter")
    assert(chunk, "HESTIA importer compilation failed: " .. tostring(reason))
    local importer = chunk().new(capabilities.BaseURL, capabilities)
    local attributes = { Channel = repository.Channel, BaseURL = capabilities.BaseURL, ClientRuntime = true }
    local root = {
        GetAttribute = function(_, name)
            return attributes[name]
        end,
    }
    local app
    local ok, result = xpcall(function()
        local versionOK, version = pcall(function()
            return importer:Fetch("version.json")
        end)
        if versionOK then
            attributes.RemoteVersion = version
        else
            capabilities.Log("WARN", "Version check unavailable: " .. tostring(version))
        end

        local hooks = table.clone(importer:Import("Hooks"))
        local persistence, canSave, canLoad =
            importer:Import("LocalConfig").Create(capabilities.FileSystem or {})
        hooks.SaveConfig = hooks.SaveConfig or persistence.SaveConfig
        hooks.LoadConfig = hooks.LoadConfig or persistence.LoadConfig
        -- Validate a new package before replacing a running session.
        local main = importer:Import("Main")
        local previous = environment.HESTIA
        if type(previous) == "table" and type(previous.Unload) == "function" then
            previous:Unload()
        end
        app = main.new(root, hooks, importer)
        app.OnUnloaded = function(current)
            if environment.HESTIA == current then
                environment.HESTIA = nil
            end
        end
        app:Start()
        environment.HESTIA = app
        app.Logger:Log(
            "INFO",
            "Client runtime ready; local save=" .. tostring(canSave) .. ", local load=" .. tostring(canLoad)
        )
        if not canSave or not canLoad then
            app.Notifications:Send("Local file persistence is limited. JSON export/import remains available.")
        end
        return app
    end, debug.traceback)
    if not ok then
        if app then
            app:Unload()
        else
            importer:Clear()
        end
        error(result, 0)
    end
    return result
end
return Runtime
