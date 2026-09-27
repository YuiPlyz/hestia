-- HESTIA runtime-neutral raw importer. HTTP, compilation and JSON decoding are injected.
local Importer = {}
Importer.__index = Importer

function Importer.new(baseURL, capabilities)
    assert(
        type(baseURL) == "string" and baseURL:match("^https://raw%.githubusercontent%.com/"),
        "HESTIA invalid raw base URL"
    )
    assert(type(capabilities.Fetch) == "function", "HESTIA runtime HTTP function unavailable")
    assert(type(capabilities.Compile) == "function", "HESTIA runtime compilation unavailable")
    assert(type(capabilities.Decode) == "function", "HESTIA JSON decoder unavailable")
    local self = setmetatable({
        BaseURL = baseURL,
        Capabilities = capabilities,
        Cache = {},
        Sources = {},
        Loading = {},
        Paths = {},
    }, Importer)
    self.Manifest = capabilities.Decode(self:Fetch("manifest.json"))
    assert(
        type(self.Manifest) == "table"
            and self.Manifest.name == "HESTIA"
            and type(self.Manifest.modules) == "table",
        "HESTIA invalid manifest"
    )
    for name, entry in pairs(self.Manifest.modules) do
        assert(type(name) == "string" and type(entry) == "table", "HESTIA invalid module entry")
        self:ValidatePath(entry.path)
        assert(entry.path:match("%.lua$"), "HESTIA module path must end in .lua")
        assert(not self.Paths[entry.path], "HESTIA duplicate module path: " .. entry.path)
        self.Paths[entry.path] = entry
    end
    local visiting, visited = {}, {}
    local function validate(name)
        assert(not visiting[name], "HESTIA dependency cycle: " .. tostring(name))
        if visited[name] then
            return
        end
        local entry = self.Manifest.modules[name]
        assert(entry, "HESTIA missing dependency: " .. tostring(name))
        visiting[name] = true
        for _, dependency in ipairs(entry.dependencies or {}) do
            validate(dependency)
        end
        visiting[name], visited[name] = nil, true
    end
    for name in pairs(self.Manifest.modules) do
        validate(name)
    end
    return self
end

function Importer:ValidatePath(path)
    assert(
        type(path) == "string"
            and path ~= ""
            and not path:find("..", 1, true)
            and not path:match("^/")
            and path:match("^[%w_./%-]+$"),
        "HESTIA invalid module path"
    )
end

function Importer:Fetch(path)
    self:ValidatePath(path)
    if self.Sources[path] ~= nil then
        return self.Sources[path]
    end
    local reason
    for attempt = 1, 3 do
        local ok, result = pcall(self.Capabilities.Fetch, self.BaseURL .. path)
        if ok and type(result) == "string" and #result > 0 then
            self.Sources[path] = result
            return result
        end
        reason = ok and "Empty or invalid HTTP response" or tostring(result)
        if self.Capabilities.Log then
            self.Capabilities.Log(
                "WARN",
                string.format("Download %s: attempt %d/3: %s", path, attempt, reason)
            )
        end
        if attempt < 3 and self.Capabilities.Wait then
            self.Capabilities.Wait(attempt)
        end
    end
    error("HESTIA download failed for " .. path .. ": " .. tostring(reason), 0)
end

function Importer:Import(name)
    local entry = self.Manifest.modules[name] or self.Paths[name]
    assert(entry, "HESTIA unknown module: " .. tostring(name))
    local path = entry.path
    if self.Cache[path] ~= nil then
        return self.Cache[path]
    end
    assert(not self.Loading[path], "HESTIA concurrent or cyclic import: " .. path)
    self.Loading[path] = true
    local ok, result = xpcall(function()
        for _, dependency in ipairs(entry.dependencies or {}) do
            self:Import(dependency)
        end
        if self.Capabilities.Log then
            self.Capabilities.Log("INFO", "Loading " .. path .. "...")
        end
        local chunk, compileError = self.Capabilities.Compile(self:Fetch(path), "HESTIA/" .. path)
        assert(
            type(chunk) == "function",
            "HESTIA compilation failed for " .. path .. ": " .. tostring(compileError)
        )
        local value = chunk()
        assert(type(value) == "table" or type(value) == "function", "HESTIA invalid module export: " .. path)
        return value
    end, debug.traceback)
    self.Loading[path] = nil
    if not ok then
        error(result, 0)
    end
    self.Cache[path] = result
    return result
end

function Importer:Clear()
    table.clear(self.Cache)
    table.clear(self.Sources)
    table.clear(self.Loading)
end
return Importer
