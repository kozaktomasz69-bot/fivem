# Ballas Gang Resource (FiveM / ESX Legacy)

A complete, modular gang job resource for the **Ballas** organization.

## Framework

Built for **ESX Legacy** (`es_extended`). Requires `es_extended`,
`esx_society`, `esx_addonaccount`, and `esx_menu_default` (all part of the
standard ESX Legacy bundle).

## Structure

```
ballas/
  fxmanifest.lua      - resource manifest (ESX Legacy)
  config.lua          - shared config (locations, vehicles, ranks, colors)
  client/main.lua     - blip, markers, garage + boss menu interactions
  server/main.lua     - authorization, vehicle spawn, society money
  shared_jobs.lua     - ESX SQL (jobs, job_grades, addon_account, addon_account_data)
```

## Features

1. **Job & Ranks** — `ballas` job with 4 grades:
   - Grade 0: Thug, Grade 1: Hustler, Grade 2: Shot Caller, Grade 3: O.G. (boss)
   - Grade 3's grade *name* is `boss` so `esx_society` authorizes the boss menu.

2. **Map Blip** — "Ballas Territory" blip at Grove St/Davis, purple (color 27).

3. **Garage** — spawn point at the hood; roster restricted by grade; all
   vehicles get purple primary + secondary paint:
   - Thug (0): BMX, Hustler (1): Voodoo, Shot Caller (2): Buccaneer, O.G. (3): Schafter V12

4. **Boss Menu** — accessible only by O.G. (boss grade). Opens via
   `esx_society:openBossMenu` for deposit/withdraw, hire, fire, promote, demote.
   The server also exposes `ballas:server:DepositMoney` / `WithdrawMoney` that
   talk directly to `esx_addon_account`.

5. **Optimized loop** — single client thread that sleeps 800ms when far from all
   markers, and only runs at `Wait(0)` while standing on a marker.

## Installation

1. Copy the `ballas` folder into your `resources/[jobs]/` (or any) directory.
2. Run the SQL block inside `shared_jobs.lua` against your ESX database.
3. Make sure `esx_society`, `esx_addonaccount`, and `esx_menu_default` are
   started **before** `ballas` in `server.cfg`.
4. Add `ensure ballas` to your `server.cfg`.
5. Grant a player the boss role: `/setjob <id> ballas 3`.

## Dependencies

- `es_extended` (ESX Legacy core)
- `esx_society` (boss / society menu)
- `esx_addonaccount` (society bank account backing store)
- `esx_menu_default` (garage vehicle list UI)
- `oxmysql` (database access, required by ESX anyway)
