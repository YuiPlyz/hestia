# HESTIA verification

## Automated checks

Run `python tools/package.py` followed by `python tools/verify.py`. Official Luau binaries belong in `tools/.bin`. These checks cover syntax and pure/runtime-mocked behavior; they do not simulate Roblox physics or render the GUI.

## Studio smoke test

1. In an empty owned test place, set `InstallDemo = true` in `loader.lua`, install, then Play. Confirm HESTIA loads with all automation off and nine tabs visible.
2. Enable Auto Scrap and Auto Fuel. The demo generator begins at 15%. Fueling should claim priority 90, interrupt scrap movement, collect fuel, return and refuel to at least 90%, then release control to scrap.
3. Disable Auto Fuel while traveling. Its task must disappear and scrap must resume. Move/remove a target while a path is computing; no stale path should move the character afterward.
4. Set the generator to low fuel after removing all fuel objects and tools. Confirm the warning appears, no successes are counted, and farming can resume during the five-second retry backoff.
5. Set Scrap priority to Value. Higher `ScrapValue` objects should be selected first. Add whitelist/blacklist rules and check that blacklisting wins. Block a target with an obstacle to exercise stuck detection, retry limits and target switching.
6. Enable Enemy, Scrap, Fuel and Generator ESP. Change name/distance/health, color and range options. Remove targets and confirm their visuals disappear. Inspect memory/connections after repeated enable/disable cycles.
7. Enable Kill Aura and Auto Equip near the demo Zombie. Check weapon cadence, NPC-only damage and the target outline. Move out of range and confirm combat releases its task.
8. Enable survival controls and collect supplies. Confirm healing/eating/drinking/bandaging occur only with server-owned supplies. Repair the nearby Wall while carrying the demo Repair Hammer.
9. Enable storage, set a scrap reserve smaller than collected inventory, and verify only confirmed excess is removed from inventory. Repeat with a keep rule and per-item minimum quantity.
10. Change walk speed, jump power, sprint, fly and noclip, then disable them and reset the character. Confirm original humanoid values, collision states and AutoRotate are restored. Fly uses WASD, Space and LeftControl.
11. Drag/collapse the widget, adjust opacity/accent, toggle the menu and test a small viewport. Inspect the interface directly in Studio for clipping and touch interaction.
12. Export/import JSON, save/load within the same Play session, and reject invalid thresholds and malformed colors. Save a negative-coordinate location and verify its config round trip. Studio persistence intentionally ends with the session.
13. Unload while navigating, flying and displaying ESP. Confirm no HESTIA GUI/highlights/flight constraints remain, no tasks or client connections remain, and lighting/collision/movement return to prior values.
14. End Play, install with `InstallDemo = false`, connect your game hooks, and repeat interaction checks in your actual experience. Published testing additionally requires server authorization and working DataStore access.

The automated tests were executed during generation. This environment has no Roblox Studio session attached, so the Studio checks and visual inspection above remain to be performed in the experience.
