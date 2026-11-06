# Blox Fruits — Halloween AutoFarm

Project target: Blox Fruits Halloween 2026  
Runtime target: iPhone 12 / Delta iOS  
Current release: **0.1.0 — Event Scanner (read-only)**

## Current status

The first delivery is a mobile-friendly event scanner. It predicts the Harvest Moon window from UTC time and scans visible Workspace objects for likely event targets (pumpkins, event bosses, Witch, Zioles, and interactive doors).

**This version does not farm automatically yet.** It does not attack, move the player, teleport, activate prompts, call game remotes, or load code from an external URL. The exact live event object hierarchy must be confirmed from a real server scan before safe interaction modules can be written.

## Run on Delta iOS

1. Open `release/HalloweenEventScanner.lua`.
2. Copy the complete file.
3. Paste it into Delta's script editor and execute it while inside Blox Fruits.
4. Use **SCANEAR** for a manual scan, **MONITOR: ON/OFF** to pause or resume the 30-second scan, and **COPIAR** to copy the report when the executor exposes clipboard support.
5. Send the report back so the next implementation step can use the actual instance names and paths.

## Repository layout

```
docs/
  RESEARCH.md
src/
  Config.lua
  Main.client.lua
  UI.lua
  Modules/
    EventScanner.lua
    HarvestMoonClock.lua
release/
  HalloweenEventScanner.lua
```

The `src` directory is the modular development version. The `release` file is the standalone single-file script intended for Delta.

## Research snapshot

- Harvest Moon: expected during UTC minutes 00–09 of each hour.
- Trick-or-Treat doors: available during Harvest Moon.
- Pumpkin/Jack-o'-lantern farming: available between Harvest Moon windows.
- Spooky Gacha: currently documented as 500 Candy Corn per roll, up to two rolls per hour.
- Great Pumpkin summon: 200 Pumpkin Bits + 3 Cursed Pumpkin Seeds.

See [docs/RESEARCH.md](docs/RESEARCH.md) for sources, citations/links, and uncertainties.

## Safety and test notes

- Use a secondary/test account if experimenting with third-party executors; executor use can violate Roblox rules and may expose an account to moderation or malicious scripts.
- Do not paste unknown remote `loadstring` URLs into the executor.
- The scanner uses only ordinary client-side instance inspection and a local ScreenGui. Results depend on the names and objects replicated to the client.
