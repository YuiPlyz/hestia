# HESTIA direct client runtime

`executor.lua` is the entry point for the Solara testing setup you requested. It uses runtime capability checks rather than assuming a particular Solara version. It has not been run inside Solara during development.

## Upload and start

1. Extract the latest `dist/HESTIA.zip` and upload its **Hestia folder** to the root of `YuiPlyz/hestia`, replacing the matching files. The expected path is `Hestia/executor.lua`.
2. Upload the complete updated folder, including `manifest.json`, `src/RemoteImporter.lua`, `src/LocalConfig.lua`, `src/Main.lua`, and `client/ExecutorRuntime.lua`. Uploading only `executor.lua` is insufficient.
3. Join your own experience. Run the contents of `executor.lua` in your existing client runtime. This file does not install or inject an executor.
4. HESTIA prints startup diagnostics and opens the interface. Press RightShift or the H button to show/hide it.

If your runtime provides both `game:HttpGet` and `loadstring`, this short entry point downloads the same file:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/executor.lua"))()
```

If that line cannot download the entry point, paste the full `executor.lua` contents instead. The full entry point can also use a host-provided `request` or `http_request` function and produces more useful error messages.

`loader.lua` remains the Studio-only installer. Use `executor.lua` for this mode. Avoid running the Studio auto-start client and the direct client simultaneously. Re-running the direct client unloads the previous direct-client session before creating the next one; Settings → Unload also cleans it up.

## Runtime requirements

- `loadstring` must return a callable compiled function.
- HTTP must be provided through `request`, `http_request`, or the host's `game:HttpGet` implementation. A request response must contain a numeric `StatusCode` and string `Body`.
- `getgenv()` or `shared` must provide a persistent table for session tracking.
- The normal Roblox client must have a LocalPlayer and PlayerGui.
- Optional local saving needs `writefile`, `makefolder`, and `isfolder`; loading needs `readfile` and `isfile`. Without these, use JSON export/import in Settings.

The UI remains in PlayerGui. The client entry point uses no CoreGui protection, hidden-property operations, hooks into unrelated scripts, or anti-cheat bypasses.

## Game integration

The loader downloads `src/Hooks.lua`, which now implements STA pickup, equipped-weapon NPC attacks, and equipped Repair Hammer requests from the supplied reference. Pickup checks replicated inventory changes; attacks and repairs check observed health changes. Sent requests without confirmation are reported without increasing confirmed counters. Loading a client does not install the Studio server or demo.

Inventory changes, fueling, repairs and NPC damage still require server confirmation and validation. See Roblox's [client-server boundary guidance](https://create.roblox.com/docs/scripting/security/client-server-boundary).

The executor runtime marks its session for local movement controls. Studio-installed sessions retain their existing movement permission checks. Server corrections and restrictions can still affect local movement.

ESP includes all item catalog categories, text size, fill and outline transparency, and distance zero for unlimited display range. Fog removal restores changed local properties when disabled or unloaded. Generator fueling, chest storage and survival-item use are not implemented in the supplied reference; their menu toggles explain the missing hooks. Existing imported settings can still enable those modules, which report missing integrations when called.

The direct client provides its own local save/load hooks if your Hooks module does not override them. The settings file is in the runtime's workspace at `HESTIA/survive-the-apocalypse/settings.json`, not necessarily the Windows project folder.

## Configuration and updates

Repository owner, name, branch and directory are authored in the `Repository` table in `loader.lua`. Run `python tools/package.py` to synchronize `executor.lua` and regenerate the URLs and ZIP. Module paths in the manifest remain relative to that base directory.

The raw importer validates dependency cycles and missing dependencies, retries HTTP failures up to three times, caches sources and exports per session, and reports compilation and execution errors with module paths. Optional feature failures can leave other features usable. Version metadata is fetched during startup and compared once; it is not polled per frame. Upload new modules and rerun the entry point to update the session.

## Verification limits

The Luau compiler and behavioral tests cover the raw importer, retry limits, dependency validation, caching, local persistence and injected-importer lifecycle. Actual Solara HTTP/compilation behavior, Roblox rendering, physics and your server hooks still require testing in your own experience.
