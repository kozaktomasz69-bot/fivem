# Ballas Gang Resource (FiveM / QBCore)

A complete, modular gang job resource for the **Ballas** organization.

## Framework

Built for **QBCore**. (The original prompt left the framework as a placeholder
`[WSTAW TUTAJ: ESX lub QBCore]`; QBCore was chosen as the modern default. ESX
would differ mainly in: `ESX.GetPlayerData()`, `xPlayer.job.grade` instead of
`Player.PlayerData.job.grade.level`, `esx_society` instead of `qb-bossmenu`,
and the `users`/`jobs`/`job_grades` ESX SQL schema.)

## Structure

```
ballas/
  fxmanifest.lua      - resource manifest
  config.lua          - shared config (locations, vehicles, ranks, colors)
  client/main.lua     - blip, markers, garage + boss menu interactions
  server/main.lua     - authorization + vehicle spawn
  shared_jobs.lua     - QBCore shared job table + SQL (job_grades / society)
```

## Features

1. **Job & Ranks** — `ballas` job with 4 grades:
   - Grade 0: Thug, Grade 1: Hustler, Grade 2: Shot Caller, Grade 3: O.G. (boss)

2. **Map Blip** — "Ballas Territory" blip at Grove St/Davis, purple (color 27).

3. **Garage** — spawn point at the hood; roster restricted by grade; all
   vehicles get purple primary + secondary paint:
   - Thug (0): BMX, Hustler (1): Voodoo, Shot Caller (2): Buccaneer, O.G. (3): Schafter V12

4. **Boss Menu** — accessible only by O.G. (grade 3). Uses `qb-bossmenu` for
   deposit/withdraw, hire, fire, promote, demote.

5. **Optimized loop** — single client thread that sleeps 800ms when far from all
   markers, and only runs at `Wait(0)` while standing on a marker.

## Installation

1. Copy the `ballas` folder into your `resources/[jobs]/` (or any) directory.
2. Run the SQL block inside `shared_jobs.lua` against your database.
3. Add the `QBCore.Shared.Jobs['ballas']` table to `qb-core/shared/jobs.lua`.
4. Ensure `qb-bossmenu` (and optionally `ox_lib`) are started.
5. Add `ensure ballas` to your `server.cfg`.
6. Grant a player the boss role: `/setjob ballas 3`.

## Dependencies

- `qb-core`
- `qb-bossmenu` (boss / society menu)
- `ox_lib` (optional — for the garage vehicle list UI)
- `qb-vehiclekeys` (optional — sets vehicle ownership on spawn)
