local Importer = require("../src/RemoteImporter")
local LocalConfig = require("../src/LocalConfig")
local Main = require("../src/Main")
local Runtime = require("../client/ExecutorRuntime")
local passed = 0
local function test(name, callback)
    local ok, reason = pcall(callback)
    if not ok then
        error("FAIL " .. name .. ": " .. tostring(reason), 0)
    end
    passed = passed + 1
    print("PASS " .. name)
end
local base = "https://raw.githubusercontent.com/test/hestia/main/Hestia/"
local function harness(manifest, responses)
    local calls, executions, waits = {}, {}, {}
    local capabilities = {
        Fetch = function(url)
            assert(url:sub(1, #base) == base)
            local path = url:sub(#base + 1)
            calls[path] = (calls[path] or 0) + 1
            if path == "manifest.json" then
                return "manifest"
            end
            local response = responses[path]
            if type(response) == "function" then
                return response(calls[path])
            end
            assert(response, "404")
            return response
        end,
        Decode = function(raw)
            assert(raw == "manifest")
            return manifest
        end,
        Compile = function(source, name)
            local fn, err = loadstring(source, name)
            if not fn then
                return nil, err
            end
            return function()
                executions[name] = (executions[name] or 0) + 1
                return fn()
            end
        end,
        Wait = function(delay)
            table.insert(waits, delay)
        end,
    }
    return capabilities, calls, executions, waits
end
test("raw imports share downloads and exports across aliases", function()
    local caps, calls, executions = harness({
        name = "HESTIA",
        modules = {
            A = { path = "modules/A.lua", dependencies = { "B" } },
            B = { path = "modules/B.lua" },
        },
    }, { ["modules/A.lua"] = "return {Name = 'A'}", ["modules/B.lua"] = "return {Name = 'B'}" })
    local importer = Importer.new(base, caps)
    local a = importer:Import("A")
    assert(importer:Import("modules/A.lua") == a)
    assert(calls["modules/A.lua"] == 1 and calls["modules/B.lua"] == 1)
    assert(executions["HESTIA/modules/A.lua"] == 1)
    assert(importer:Fetch("manifest.json") == "manifest" and calls["manifest.json"] == 1)
    importer:Clear()
    assert(next(importer.Cache) == nil and next(importer.Sources) == nil and next(importer.Loading) == nil)
end)
test("raw HTTP retries are bounded and recover", function()
    local caps, calls, _, waits = harness({ name = "HESTIA", modules = { A = { path = "A.lua" } } }, {
        ["A.lua"] = function(attempt)
            if attempt < 3 then
                error("503")
            end
            return "return {}"
        end,
    })
    local importer = Importer.new(base, caps)
    assert(type(importer:Import("A")) == "table")
    assert(calls["A.lua"] == 3 and #waits == 2 and waits[1] == 1 and waits[2] == 2)
end)
test("optional raw failure does not poison unrelated imports", function()
    local caps, calls = harness({
        name = "HESTIA",
        modules = {
            A = { path = "A.lua", optional = true },
            B = { path = "B.lua" },
        },
    }, { ["B.lua"] = "return {}" })
    local importer = Importer.new(base, caps)
    assert(not pcall(function()
        importer:Import("A")
    end))
    assert(calls["A.lua"] == 3 and next(importer.Loading) == nil)
    assert(type(importer:Import("B")) == "table")
end)
test("invalid manifests fail before module execution", function()
    for _, modules in ipairs({
        { A = { path = "../A.lua" } },
        { A = { path = "A.lua", dependencies = { "Missing" } } },
        { A = { path = "A.lua", dependencies = { "B" } }, B = { path = "B.lua", dependencies = { "A" } } },
        { A = { path = "A.lua" }, B = { path = "A.lua" } },
    }) do
        local caps, calls = harness({ name = "HESTIA", modules = modules }, {})
        assert(not pcall(Importer.new, base, caps))
        assert(calls["manifest.json"] == 1 and calls["A.lua"] == nil)
    end
end)
test("compile and module execution errors clear loading state", function()
    for _, source in ipairs({ "invalid (", "error('broken')", "return nil" }) do
        local caps = harness(
            { name = "HESTIA", modules = { A = { path = "A.lua" } } },
            { ["A.lua"] = source }
        )
        local importer = Importer.new(base, caps)
        assert(not pcall(function()
            importer:Import("A")
        end))
        assert(next(importer.Loading) == nil and next(importer.Cache) == nil)
    end
end)
test("missing local filesystem returns actionable failure", function()
    local hooks, save, load = LocalConfig.Create({})
    assert(not save and not load)
    local ok, reason = hooks.SaveConfig("HESTIA/survive-the-apocalypse", "{}")
    assert(not ok and reason:find("Export", 1, true))
    assert(not hooks.LoadConfig("HESTIA/survive-the-apocalypse"))
end)
test("local persistence is restricted to the HESTIA namespace", function()
    local folders, files = {}, {}
    local hooks, canSave, canLoad = LocalConfig.Create({
        Write = function(path, raw)
            files[path] = raw
        end,
        Read = function(path)
            return files[path]
        end,
        IsFile = function(path)
            return files[path] ~= nil
        end,
        IsFolder = function(path)
            return folders[path] == true
        end,
        MakeFolder = function(path)
            folders[path] = true
        end,
    })
    assert(canSave and canLoad)
    assert(not hooks.SaveConfig("../outside", "{}"))
    assert(hooks.SaveConfig("HESTIA/survive-the-apocalypse", "saved"))
    local ok, raw = hooks.LoadConfig("HESTIA/survive-the-apocalypse")
    assert(ok and raw == "saved" and folders.HESTIA and folders["HESTIA/survive-the-apocalypse"])
end)
test("Main accepts a raw importer without accessing Studio instances", function()
    local importer = {
        Cache = {},
        Import = function(_, name)
            return name
        end,
    }
    local app = Main.new({}, {}, importer)
    assert(app:Import("Example") == "Example" and app.Modules == importer.Cache)
end)
test("client runtime replaces sessions and clears the public handle on unload", function()
    local environment, unloads, clears = {}, 0, 0
    local importer = {
        Fetch = function()
            return "version"
        end,
        Clear = function()
            clears = clears + 1
        end,
    }
    local fakeMain = {
        new = function()
            local app = {
                Logger = { Log = function() end },
                Notifications = { Send = function() end },
                Start = function(self)
                    self.Running = true
                end,
            }
            function app:Unload()
                unloads = unloads + 1
                self.Running = false
                importer:Clear()
                if self.OnUnloaded then
                    self.OnUnloaded(self)
                end
            end
            return app
        end,
    }
    importer.Import = function(_, name)
        if name == "Hooks" then
            return {}
        end
        if name == "LocalConfig" then
            return LocalConfig
        end
        if name == "Main" then
            return fakeMain
        end
        error("Unexpected import")
    end
    local capabilities = {
        Environment = environment,
        BaseURL = base,
        Fetch = function()
            return "importer"
        end,
        Compile = function()
            return function()
                return {
                    new = function()
                        return importer
                    end,
                }
            end
        end,
        Log = function() end,
    }
    local first = Runtime.Start({ Channel = "main" }, capabilities)
    assert(environment.HESTIA == first and first.Running)
    local second = Runtime.Start({ Channel = "main" }, capabilities)
    assert(environment.HESTIA == second and not first.Running and unloads == 1)
    second:Unload()
    assert(environment.HESTIA == nil and unloads == 2 and clears == 2)
end)
print(string.format("HESTIA: %d client runtime tests passed", passed))
