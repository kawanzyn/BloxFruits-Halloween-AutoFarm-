# Research Notes — Halloween Event 2026

Research date: 2026-11-06  
Game: Blox Fruits  
Build target: Delta iOS client  
Implementation status: scanner / diagnostics only

## Confirmed event loop

- The Halloween update is listed as Update 30.1 and launched on 2026-10-31.
- Trick-or-Treat doors are part of the Harvest Moon window: the first 10 minutes of each UTC hour (XX:00–XX:10).
- Door interactions can lead to normal trick/treat rooms, the returning Unbound Werewolf, or the new Hellfire Gas raid boss.
- Jack-o'-lantern/pumpkin farming is the between-window activity. Breaking a pumpkin can spawn a Jack-o'-lantern.
- Candy Corn is the Spooky Gacha currency. The current wiki describes 500 Candy Corn per roll and up to two rolls per hour.
- Pumpkin Bits and Cursed Pumpkin Seeds are the resources used for Witch recipes and the Great Pumpkin summon.
- The Great Pumpkin summon is listed as 200 Pumpkin Bits + 3 Cursed Pumpkin Seeds.
- Hellfire Gas is listed as a level 3000 raid boss with 415,000 HP; it can appear behind a Harvest Moon door.
- Zioles' Gacha locations vary by sea: Middle Town (First Sea), Café (Second Sea), Mansion (Third Sea).

## Event time calculation

The scanner derives the expected Harvest Moon interval from UTC epoch time:
- Active window: UTC minute 00 through 09.
- Inactive interval: UTC minute 10 through 59.

This clock is only a prediction based on the device clock. It does not query the game server, and server timing can differ.

## Reward and material notes

The Great Pumpkin is an event raid boss. The Witch opens the portal after the player brings 200 Pumpkin Bits and 3 Cursed Pumpkin Seeds. The pumpkin material page lists pumpkin breaking, Jack-o'-lanterns, and Pumpkin Snowmen as material sources.

The Spooky Gacha is listed as 500 Candy Corn per roll, with a maximum of two rolls per hour and a shared cooldown with the regular gacha.

## Important uncertainty

A current third-party guide reports an end date of 2026-11-15, 01:00 UTC, while another guide updated 2026-11-02 says the developers had not announced an end date. Treat the end date as provisional unless the in-game event notice or the developers confirm it.

## Source list

- Blox Fruits Wiki — Update 30.1: https://bloxfruitswiki.org/wiki/updates/301/
- Blox Fruits Wiki — Trick or Treating: https://bloxfruitswiki.org/wiki/trick-or-treating/
- Blox Fruits Wiki — Spooky Gacha: https://bloxfruitswiki.org/wiki/spooky-gacha/
- BFFR Wiki — Update 30.1 and boss requirements: https://bffr.fr/wiki/en/updates/updates-30-1/
- BFFR Wiki — Pumpkin Bits: https://bffr.fr/wiki/en/materiaux/pumpkin-bits/
- Games.gg — Event guide (updated 2026-11-02): https://games.gg/pt-BR/roblox/guides/guia-completo-do-evento-hellfire-halloween-em-blox-fruits/
- All Things How — Witch recipes and summon requirements: https://allthings.how/blox-fruits-halloween-every-witch-potion-recipe-and-how-to-summon-the-great-pumpkin/
- All Things How — Event town and Harvest Moon observations: https://allthings.how/blox-fruits-halloween-update-release-date/

## Implementation decisions

- First delivery is read-only. It never attacks, teleports, activates prompts, fires remotes, or downloads remote code.
- The exact live instance hierarchy is not established by public guides. The scanner therefore uses name hints and exposes its report so the actual server hierarchy can be checked before interaction logic is added.
- Scan interval is 30 seconds to limit repeated Workspace traversals on a mobile device.
