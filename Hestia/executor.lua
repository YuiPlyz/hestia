-- HESTIA client entry point. Repository settings are synchronized by tools/package.py.
local Repository = { Owner = "YuiPlyz", Name = "hestia", Channel = "main", Directory = "Hestia" }
assert(type(loadstring) == "function", "HESTIA: this runtime does not expose loadstring")
local environment = type(getgenv) == "function" and getgenv() or shared
assert(type(environment) == "table", "HESTIA: shared runtime environment unavailable")
assert(not environment.HESTIA_LOADING, "HESTIA is already loading; wait for startup to finish")
environment.HESTIA_LOADING = true

local ok, result = xpcall(function()
    local players = game:GetService("Players")
    local deadline = os.clock() + 20
    while not players.LocalPlayer and os.clock() < deadline do
        task.wait(0.1)
    end
    assert(
        players.LocalPlayer and players.LocalPlayer:WaitForChild("PlayerGui", 10),
        "HESTIA: join your experience before starting the client loader"
    )
    local base = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/",
        Repository.Owner,
        Repository.Name,
        Repository.Channel
    )
    local directory = (Repository.Directory or ""):gsub("^/+", ""):gsub("/+$", "")
    assert(
        not directory:find("..", 1, true) and (directory == "" or directory:match("^[%w_/%-]+$")),
        "HESTIA invalid repository directory"
    )
    if directory ~= "" then
        base = base .. directory .. "/"
    end
    local requestFunction = type(request) == "function" and request
        or (type(http_request) == "function" and http_request)
    local function fetch(url)
        if requestFunction then
            local response = requestFunction({ Url = url, Method = "GET" })
            assert(type(response) == "table", "HESTIA invalid HTTP response")
            local status = tonumber(response.StatusCode)
            assert(status and status >= 200 and status < 300, "HESTIA HTTP status: " .. tostring(status))
            assert(type(response.Body) == "string" and #response.Body > 0, "HESTIA empty HTTP body")
            return response.Body
        end
        local success, body = pcall(function()
            return game:HttpGet(url)
        end)
        assert(
            success and type(body) == "string" and #body > 0,
            "HESTIA HTTP unavailable or request failed: " .. tostring(body)
        )
        return body
    end
    local sources = {}
    local function bootstrapFetch(url)
        if sources[url] then
            return sources[url]
        end
        local reason
        for attempt = 1, 3 do
            local success, value = pcall(fetch, url)
            if success then
                sources[url] = value
                return value
            end
            reason = value
            if attempt < 3 then
                task.wait(attempt)
            end
        end
        error("HESTIA bootstrap download failed: " .. url .. "\n" .. tostring(reason), 0)
    end
    local runtimeSource = bootstrapFetch(base .. "client/ExecutorRuntime.lua")
    local runtimeChunk, reason = loadstring(runtimeSource, "HESTIA/ExecutorRuntime")
    assert(runtimeChunk, "HESTIA client runtime compilation failed: " .. tostring(reason))
    local capabilities = {
        BaseURL = base,
        Environment = environment,
        Compile = loadstring,
        Wait = task.wait,
        Fetch = function(url)
            if url == base .. "src/RemoteImporter.lua" then
                return bootstrapFetch(url)
            end
            return fetch(url)
        end,
        Decode = function(raw)
            return game:GetService("HttpService"):JSONDecode(raw)
        end,
        Log = function(level, message)
            print("[HESTIA][" .. level .. "] " .. message)
        end,
        FileSystem = {
            Write = writefile,
            Read = readfile,
            IsFile = isfile,
            MakeFolder = makefolder,
            IsFolder = isfolder,
        },
    }
    return runtimeChunk().Start(Repository, capabilities)
end, debug.traceback)
environment.HESTIA_LOADING = nil
assert(ok, "HESTIA client startup failed:\n" .. tostring(result))
return result
