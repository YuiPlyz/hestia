# HESTIA integration contract

Edit `src/Hooks.lua` in your repository and return an implementation table. `GameAdapter` is the only feature-facing boundary. Hooks execute on the client; use your game's existing request/response API. The server remains responsible for distance, ownership, capacity, resources, target type and cooldown checks.

Methods that change state return `true` only after the server confirms the operation, optionally followed by an actual quantity. On rejection return `false, reason`. Sending a RemoteEvent alone is not confirmation; use your existing acknowledgment mechanism or a validated RemoteFunction. HESTIA cannot revoke a server request already in flight when a task is preempted or unloaded.

| Hook | Arguments | Return |
| --- | --- | --- |
| `CollectItem` | World item Instance | `true, actualQuantity` or `false, reason` |
| `AddFuel` | Generator Model, inventory fuel Instance | `true` or `false, reason` |
| `AttackTarget` | NPC Model | `true` or `false, reason` |
| `StoreItem` | Owned inventory Instance, integer quantity, storage Model | `true, actualQuantity` or failure |
| `RepairStructure` | Structure Model | `true` or failure |
| `UseSurvival` | `Heal`, `Bandage`, `Eat` or `Drink` | `true` or failure |
| `GetInventory` | None | Array of `{Instance, Name, Category, Quantity}` records |
| `InventoryFull` | None | Boolean |
| `GetFuelPercent` | Generator Instance or nil | Number 0–100, or nil when unknown |
| `GetStorage` | None | Storage Model or nil |
| `GetLocation` | Location name | CFrame or nil |
| `Vitals` | None | `{Health=0..100, Hunger=0..100, Thirst=0..100, Bleeding=boolean}` |
| `EquipWeapon` | None | Boolean |
| `Teleport` | CFrame | `true` or failure |
| `SaveConfig` | Namespace, JSON string | `true` or failure |
| `LoadConfig` | Namespace | `true, JSONstring` or failure |

Persistence hooks are provided by the default client entry point. Hooks you supply explicitly take precedence. Inventory defaults to Tools in Backpack/Character. Quantity defaults to one; category comes from `HestiaCategory` or the shared item database. A storage reserve applies per item name, including fuel type.

The complete, working example implementations are in `examples/DemoHooks.lua` and `examples/Demo.server.lua`. Set `Repository.InstallDemo = true` to install them. The demo accepts interactions only in Studio, validates target identity/tags, validates owned tools and quantities, enforces distance and attack cooldowns, and changes state on the server. It is a finite test scene, not a production inventory or combat system.

## Object discovery

Prefer CollectionService tags on the top-level Model, Tool or BasePart:

```text
HESTIA_Enemies
HESTIA_Items
HESTIA_Scrap
HESTIA_Fuel
HESTIA_Structures
HESTIA_Generator
HESTIA_Chest
```

Tagging Scrap or Fuel also registers it as an item. Use one gameplay object per tag, not every descendant part. Set `HestiaCategory` for custom item types. Dynamically tagged objects and streaming additions/removals are tracked by signals. Renaming an object into a semantic category is not the registration API; tag it or update its category attribute.

Fallback folders are `Characters`/`NPCs`/`Enemies`, `DroppedItems`/`Items`/`Drops`, `Structures`/`PlayerStructures`/`Buildings`, and `Storage`/`Storages`. Direct children are treated as objects. Put alternate nested layouts in the adapter or use tags.

Default generator attributes are `Fuel` and `MaxFuel`. Default structure/NPC attributes are `Health` and `MaxHealth`; a Humanoid takes precedence. NPCs must be Models. `Boss = true` enables boss priority. Scrap uses `ScrapValue` for ranking. Change adapter accessors if your experience uses NumberValues or custom data modules.

## Permissions and server authority

Studio permits the client framework for development. In a published experience, set `HESTIA_Enabled` on authorized players from a trusted server script. Set `HESTIA_AllowMovement` separately if your own game supports the movement utilities. These attributes are not substitutes for validation of gameplay requests.

There are no guessed game remotes, injected scripts, hidden-property operations, detection bypasses, client-awarded inventory, or client-authoritative damage in this package. The optional demo RemoteFunction is dedicated to its own test scene. Port its patterns into your own systems only where they match your experience.

## Cleanup ownership

Features own instances, tasks and connections they create. Use `h.Connections:Add(uniqueName, connection)` for connections, `h.Scheduler:Add(name, interval, callback, onError)` for background work, and `h.Tasks:Request/Release` around actions competing for character control. A feature's `Stop`/`Destroy` must release its task even if its target disappears.

Hook implementations must bound their waits and clean up their own extra resources. Avoid unbounded `WaitForChild` calls or unresolved request promises. HESTIA cancels client scheduler coroutines at unload, but cannot undo a committed transaction on your server.
