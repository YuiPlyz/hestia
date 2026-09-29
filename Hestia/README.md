# HESTIA

A modular Roblox survival-game utility framework for experiences you own and test.

HESTIA includes a charcoal and violet interface, farming and generator automation, NPC combat, survival routines, centralized ESP, movement utilities, saved locations, and priority-based character control. All automation starts disabled.

## Structure

The full repository tree is in [docs/TREE.md](docs/TREE.md). The code is divided by responsibility:

| Directory | Responsibility |
| --- | --- |
| `loader.lua` | Small Studio Command Bar installer; repository settings live here |
| `src/` | Lifecycle, importer, configuration, adapter, registries, navigation, scheduling |
| `modules/` | Independently replaceable gameplay and visual features |
| `ui/` | Native Roblox interface, nine tabs, theme manager and floating widget |
| `data/` | Shared item catalog, weapon timing, enemies, structures and location paths |
| `client/` | Client entry point |
| `server/` | Per-player config persistence and one startup update check |
| `examples/` | Optional Studio test scene and validated interaction hooks |
| `tests/` | Executable behavioral regression tests |
| `tools/` | Verification, manifest and release packaging |

For the executor build, start with [CLIENT_RUNTIME.md](docs/CLIENT_RUNTIME.md) and use `executor.lua`. The full updated folder must be uploaded before rerunning the raw entry point.

## Installation

HESTIA has two entry points: `loader.lua` installs the Studio package; `executor.lua` loads the client modules directly in a runtime that supplies HTTP and `loadstring`. For the client runtime you requested, follow [docs/CLIENT_RUNTIME.md](docs/CLIENT_RUNTIME.md). Solara compatibility has not been tested directly.

1. Upload the extracted `Hestia` folder to `YuiPlyz/hestia` on branch `main`. Keep the folder itself, so the GitHub path is `Hestia/loader.lua`. This delivery does not upload changes to GitHub.
2. Open your own experience in Roblox Studio, in **Edit mode**. Enable **Allow HTTP Requests** in Game Settings → Security.
3. Open `Hestia/loader.lua` on GitHub (or the local `loader.lua`). Its `Repository` table sets the owner, repository, branch and `Directory = "Hestia"`. Use `Directory = ""` if you later move files to the repository root. To install the optional test scene, set `InstallDemo = true`.
4. Paste the complete contents of `loader.lua` into Studio's Command Bar and run it.
5. Start a Play test. HESTIA opens automatically; `RightShift` toggles the menu. The small **H** button also opens it on touch devices.

The installer downloads each path once, caches responses for that installation, retries failed downloads three times, validates manifest dependencies, and stages the complete package before replacing an existing HESTIA installation. Required download failures leave the old installation intact. Optional feature failures are logged, and the UI can still open. Reinstalling replaces the installed `Hooks` module, so keep custom hook changes in your repository.

Installed objects:

```text
ReplicatedStorage/HESTIA
StarterPlayer/StarterPlayerScripts/HESTIA Client
ServerScriptService/HESTIA Server
ServerScriptService/HESTIA Demo    (only when requested)
```

Normal Roblox client scripts cannot fetch and execute arbitrary Luau via the commonly shown `game:HttpGet` loader pattern. The Studio entry point downloads code **at installation time**, installs normal ModuleScripts, and uses `require` at runtime. The separate `executor.lua` entry point instead checks for host-provided HTTP and compilation functions and uses the remote importer. Roblox documents [HTTP access](https://create.roblox.com/docs/cloud-services/http-service) and [Studio script editing](https://create.roblox.com/docs/reference/engine/classes/ScriptEditorService).

After installation, the minimal application loader is:

```lua
local root = game:GetService("ReplicatedStorage"):WaitForChild("HESTIA")
local Hestia = require(root.src.Main).new(root)
Hestia:Start()
```

The included client entry point already performs startup and adds configuration persistence hooks. Use the snippet only when replacing that entry point. Prefer running the complete `loader.lua` for GitHub installation; it contains retry and diagnostic handling.

## Configuration

Defaults live in `src/Config.lua`. Every UI control edits the same configuration object. Item and category filters use searchable multi-select dropdowns, with Select all and Clear controls. Choice controls open an option list; color controls accept `[145,90,255]`; fuel priority accepts a JSON array of item names. Empty whitelists impose no name restriction. Blacklists take precedence. Empty item-farm categories include all categories. Scrap, item, fuel and pickup radii accept `0` for unlimited distance; scrap, item and fuel searches default to unlimited. Search does not bypass server pickup range or inventory capacity. Pickup status reports missing integration, full inventory and rejected actions.

Generator thresholds must satisfy `EmergencyFuel <= FuelBelow < FuelUntil <= 100`. The default values are 20, 50 and 90. Once fueling starts it continues until the stop threshold, even after fuel rises above the start threshold.

Settings provides export/import and save/load. The namespace is `HESTIA/survive-the-apocalypse`, backed by the `HESTIA` DataStore in published experiences. Studio tests use session memory and do not require DataStore API access; export JSON to retain a test configuration across Play sessions. Configuration is validated before application and is not automatically loaded with automation enabled.

The direct client entry point uses optional local filesystem functions instead of the server DataStore endpoint. It saves `HESTIA/survive-the-apocalypse/settings.json` in the host's filesystem workspace. If these functions are missing, JSON export/import is still available.

In a published experience, your server must authorize testers by setting `player:SetAttribute("HESTIA_Enabled", true)`. Studio-installed movement utilities also require `HESTIA_AllowMovement = true` or a custom adapter implementation. These flags are set by your game server; the package grants them automatically only through the Studio environment check.

## Modules

`Hestia:Import("ScrapFarm")` and `Hestia:Import("modules/ScrapFarm.lua")` resolve the same installed module and return the same cached export. `manifest.json` maps names to exact paths and declares dependencies. Each module exports a stateless factory or helper table. Per-session mutable state belongs to instances created with `.new(hestia)`.

| System | Behavior |
| --- | --- |
| ScrapFarm | Nearest/highest-value search, name filters, retries, timeout, stuck detection, confirmed statistics |
| ItemFarm / FuelFarm | Shared farming worker with category selection and fuel reserve limits |
| Generator | Hysteresis, emergency priority, fuel ranking, pickup/return/insert loop and missing-fuel backoff |
| AutoPickup | Distance, name/category filters, cooldown and confirmed pickup counts |
| AutoStore | Category filters, keep rules, minimum quantities and excess storage |
| Combat / KillAura | NPC-only targeting, boss priority, weapon timing, auto-equip and target highlight |
| Survival | Heal/eat/drink/bandage routines with priority claims |
| Repair | Nearest or lowest-health target, equipment check, rate limit and emergency priority |
| ESP | One renderer with item/NPC/player/structure providers; Highlight and BillboardGui |
| Movement | Sprint, speed/jump settings, flight, noclip and respawn-aware restoration |
| Teleports | Registry targets, selected player, map locations and saved CFrames |
| Lighting | Fullbright with exact restoration of changed properties |

Every actual game interaction is in `src/GameAdapter.lua` and `src/Hooks.lua`. The source game's item catalog, NPC names, weapon timing and layout fallbacks are retained. The supplied STA reference now provides the pickup remote paths and routing used in `src/Hooks.lua`. Equipped weapon attacks and Repair Hammer requests are also integrated. Generator fueling, chest storage and survival-item use still need implementations using [the integration contract](docs/INTEGRATION.md). Unsupported interactions return a visible diagnostic and never fabricate success.

### UI implementation

The native `ui/Interface.lua` wrapper keeps feature modules independent of the GUI. It implements the requested nine tabs, compact controls, live dashboard, accent changes, menu key, notifications and draggable/collapsible/opacity-adjustable widget.

The upstream [Obsidian library](https://github.com/deividcomsono/Obsidian/blob/main/Library.lua) depends on CoreGui/executor-oriented APIs. HESTIA uses ordinary PlayerGui controls and its own `ui/ThemeManager.lua` and configuration service so it runs inside your experience without those dependencies. This is a deliberate replacement of the UI backend.

### Scheduling and task ownership

One scheduler services independent jobs: combat and ESP at 0.10 seconds, pickup at 0.20, farm/navigation at 0.25, dashboard/statistics and registry reconciliation at 0.50, generator and survival at 1.00. ESP updates a maximum of 100 objects per tick. Large populations therefore rotate through batches. Movement physics has one PreSimulation callback.

Registry initialization scans Workspace once. Folder, ancestry, tag and descendant signals maintain caches afterward. Farm and ESP loops never rescan all Workspace descendants. Noclip examines only the local character.

Movement priorities are survival 100, emergency fuel 90, optional emergency repair 85, combat 80, healing 70, generator/repair 60, full-inventory storage 55, scrap 50, item/fuel farming 40, ordinary storage 35, pickup 30, idle 10. Explicit manual flight (110) and teleport (120) override automation. Lower-priority requests remain queued and resume automatically. Yielding path computations must still possess the original lease before issuing movement.

## Updating

Edit an individual feature's raw file, commit it, and rerun the Studio installer. Code is not hot-replaced during a running session. `main` is stable, `beta` is testing, and `dev` is development; set `Repository.Channel` in the loader accordingly. Set `version.json.channel` on each branch to the matching release label. No branches are created automatically.

The installed `Hestia.Version` is compared numerically with remote version metadata. The server requests version metadata once per startup and shares it with clients. Failed requests log a warning and retain the installation snapshot. Version messages and changelog appear in Settings; checking never runs per frame.

Every resulting raw URL is listed in [docs/RAW_URLS.md](docs/RAW_URLS.md), including:

```text
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/loader.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/src/Main.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/ScrapFarm.lua
https://raw.githubusercontent.com/YuiPlyz/hestia/main/Hestia/modules/Generator.lua
```

## Development

Download the official [Luau Windows release](https://github.com/luau-lang/luau/releases) and place `luau.exe` and `luau-compile.exe` under `tools/.bin/`.

```powershell
python tools/package.py
python tools/verify.py
```

Verification compiles every Luau file, checks manifest dependencies and import paths, and runs behavioral tests for task preemption, generator hysteresis, failure backoff, inventory reserves, config validation and cleanup. The code was checked with Luau 0.740. Full Studio physics, rendering and server interaction tests require Roblox Studio; use [docs/TESTING.md](docs/TESTING.md).

`tools/package.py` regenerates the manifest, complete repository tree and exact URLs, then produces `dist/HESTIA.zip` and `dist/HESTIA-FILES.md`. The Markdown artifact contains every file separately with `FILE: path` headings and complete source.

Unload with `Hestia:Unload()` or the Settings button. The client stops scheduled tasks, releases movement ownership, disconnects its connections, restores modified movement/lighting properties, destroys ESP and UI, and clears registries and its import cache. Roblox's internal `require` cache remains engine-managed; exports contain no mutable session state. The server config endpoint and optional demo scene belong to the installed experience and persist until the Play session ends.

## Changelog

### HESTIA 1.0.0

- Modular GitHub installation and cached imports with dependency diagnostics.
- Unified object registries, navigation, scheduling, task ownership and cleanup.
- Farming, emergency fueling, storage, repair, NPC combat and survival modules.
- Native HESTIA dashboard, consolidated ESP, movement tools and location management.
- Configuration validation/persistence, release channels and changelog metadata.
- Optional Studio demonstration with server-validated actions and regression tests.
