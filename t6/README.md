# Plutonium T6 dedicated server administration reference

This guide maps the authoritative documentation, script repositories, tooling, and configuration references for running Plutonium T6 (Call of Duty: Black Ops II) dedicated servers — both Multiplayer and Zombies — on a modern Linux/container homelab. **No single "official" doc hub covers everything**: Plutonium's own docs are terse, so the real reference set is a constellation of plutonium.pw pages, the `plutoniummod/t6-scripts` decompile, JezuzLizard's Google Drive, xerxes-at's server config templates, alicealys's `t6-gsc-utils` plugin README, and the IW4MAdmin wiki. This guide catalogs each of those with exact URLs and a statement of what you'll find there.

A critical up-front correction: **the path `plutonium.pw/docs/modding/gsc-scripting-t6/` does not exist**, and neither does `/docs/servers/`. The canonical hubs are `/docs/server/t6/…` and `/docs/modding/gsc/…`. Several other popular "guides" (e.g., the old forum topic /13) now redirect to the new docs.

## Official Plutonium documentation

Plutonium's docs (**https://plutonium.pw/docs/**) are Cloudflare-gated against automated fetchers but index fine. The T6 server-relevant hierarchy is flat and short:

| URL | What it covers |
|---|---|
| `/docs/dedicated-servers/` | High-level dedicated-server philosophy (not a setup guide). |
| `/docs/server/t6/setting-up-a-server/` | **Canonical T6 dedi install guide**: Steam-copy prep, Plutonium Launcher, server key creation at forum.plutonium.pw → "server keys", `.bat` authoring with `set key=…`, port selection. Points to xerxes-at configs. |
| `/docs/server/t6/cleaning-demos/` | Scheduled cleanup of `storage/t6/demos` `.demo`/`.data` files. |
| `/docs/server/dvars/` | **Plutonium-added server dvars**: `sv_allowAimAssist`, `sv_motd`, `sv_enableBounces`, `sv_enableDoubleTaps`, `sv_wwwBaseURL` (FastDL), `fs_game`, `g_customTeamNames`, etc. Must-read. |
| `/docs/install/#t6` | Client install (Steam BO2 required; cracked copies blocked). |
| `/docs/custom-games/` | Port 4976/udp default, port-forwarding basics. |
| `/docs/changelog/` | Contains nearly every Plutonium-added dvar and GSC feature that the rest of the docs neglect — **treat as a dvar reference**. |
| `/docs/anticheat/` | LAN mode rules for script/mod loading. |
| `/docs/modding/loading-mods/` (= `/docs/client/t6/loading-and-compiling-gsc/` = `/docs/server/t6/loading-mods/`) | GSC placement: `storage/t6/scripts/{,mp/,zm/}`; `init()`/`main()` entry points; map_restart semantics. |
| `/docs/modding/loading-textures/` | `storage/t6/images/` (the old `t6r/data` path is deprecated). |
| `/docs/modding/gsc/` | GSC docs index. |
| `/docs/modding/gsc/how-to-gsc/` | Syntax, `#include`, notifies/endon, function declaration. Based on Zeroy's CoD4 guide. |
| `/docs/modding/gsc/new-scripting-features/` | **`replaceFunc()`, map/gametype-conditional script folders (`scripts/mp/mp_rust/…`, `scripts/mp/dm/…`), stock-script overrides by path, `gamemode_callback_setup()` hook for ZM**. |
| `/docs/modding/gsc/compiler-limitations/` | Quirks of the old compiler (nested foreach, `continue;` in loops, P.E.M.D.A.S) — mostly obsolete now that xensik's GSC Tool is standard and T6 supports source-script loading since r3408. |
| `/docs/modding/plugin-sdk/v1-api/` | C++ plugin SDK: `register_function`/`register_method`, scheduler hooks, client-command handlers. |

**There is no official map list, no official gametype list, and no consolidated dvar table on plutonium.pw** — admins rely on xerxes-at and B2ORG (below).

## BO2 map codenames

These are the internal map IDs used with the `map`/`mapname` dvar and in `sv_maprotation`. Verified against `plutoniummod/t6-scripts`, xerxes-at configs, and cod.fandom.com.

### Multiplayer — base (15 maps including Nuketown bonus)

| Display | Codename | | Display | Codename |
|---|---|---|---|---|
| Aftermath | `mp_la` | | Overflow | `mp_overflow` |
| Cargo | `mp_dockside` | | **Plaza** | **`mp_nightclub`** |
| Carrier | `mp_carrier` | | Raid | `mp_raid` |
| Drone | `mp_drone` | | Slums | `mp_slums` |
| Express | `mp_express` | | **Standoff** | **`mp_village`** |
| Hijacked | `mp_hijacked` | | Turbine | `mp_turbine` |
| Meltdown | `mp_meltdown` | | **Yemen** | **`mp_socotra`** |
| **Nuketown 2025** | **`mp_nuketown_2020`** | | | |

### Multiplayer — DLC

| DLC | Map | Codename |
|---|---|---|
| Revolution | Downhill / Grind / Hydro / Mirage | `mp_downhill` / `mp_skate` / `mp_hydro` / `mp_mirage` |
| Uprising | Magma / **Encore** / Studio / Vertigo | `mp_magma` / **`mp_concert`** / `mp_studio` / `mp_vertigo` |
| Vengeance | **Cove** / **Detour** / **Rush** / Uplink | **`mp_castaway`** / `mp_bridge` / `mp_paintball` / `mp_uplink` |
| Apocalypse | Dig / **Frost** / Pod / Takeoff | `mp_dig` / `mp_frostbite` / `mp_pod` / `mp_takeoff` |

**Total: 32 MP maps.** Note especially that **Cove = `mp_castaway`** (not `mp_uplink`), **Encore = `mp_concert`** (not Hydro), and Plaza/Standoff/Yemen hide behind non-obvious codenames.

### Zombies

| Display | Codename | DLC |
|---|---|---|
| TranZit / Green Run (parent map for Bus Depot, Town, Farm, Diner) | `zm_transit` | Base |
| Nuketown Zombies | `zm_nuked` | Hardened/Care Package |
| Die Rise | `zm_highrise` | Revolution |
| Mob of the Dead (Alcatraz) | `zm_prison` | Uprising |
| Buried (Resolution 1295 / Processing) | `zm_buried` | Vengeance |
| Origins | `zm_tomb` | Apocalypse |
| **Diner (Turned variant)** | **`zm_transit_dr`** | Revolution (distinct map entity) |

TranZit survival sub-locations (Bus Depot, Town, Farm) are **not separate maps** — they all run on `zm_transit` with a start-location dvar.

## BO2 gametype codes

Gametype codes double as `.cfg` filenames in the xerxes-at repo's `gamesettings/` folder.

### Multiplayer

`tdm` Team Deathmatch · `dm` Free-for-All (Deathmatch) · `dom` Domination · `sd` Search & Destroy · `ctf` Capture the Flag · `oneflag` One-Flag CTF · `dem` Demolition · `conf` Kill Confirmed · **`hq` Headquarters** · **`koth` Hardpoint** (internal name is "King of the Hill" carried over from CoD4, but it runs Hardpoint rules) · `gun` Gun Game · `oic` One in the Chamber · `shrp` Sharpshooter · `sas` Sticks & Stones. The legacy `war` alias for TDM exists in stock scripts but isn't used on Plutonium.

### Zombies

| Code | Meaning | Valid maps |
|---|---|---|
| `zclassic` | Story/classic mode | `zm_transit`, `zm_highrise`, `zm_prison`, `zm_buried`, `zm_tomb` |
| `zstandard` | Survival (wave-based, no quest) | `zm_nuked`, `zm_transit` (Bus Depot/Town/Farm) |
| `zgrief` | 4v4 PvPvE Grief (needs GriefFix mod) | `zm_transit`, `zm_prison`, `zm_buried` |
| `zcleansed` | Turned (players play as zombies) | `zm_transit_dr`, `zm_buried` |

Supporting dvar: **`ui_zm_gamemodegroup`** accepts `zclassic`, `zsurvival`, `zgrief`, `zcleansed`. For Survival on Nuketown/TranZit, the group is `zsurvival` but `ui_gametype`/`g_gametype` evaluates to `zstandard`. Switching ZM map+mode requires four dvars set atomically (`ui_zm_mapstartlocation`, `g_gametype`, `ui_zm_gamemodegroup`, `mapname`) — a bare `map zm_transit` won't work.

## TranZit survival sub-locations — exact mechanics

This is the trickiest single configuration detail in T6 hosting. **The dvar is `ui_zm_mapstartlocation`.** Inside `sv_maprotation`, Treyarch's parser also accepts the shorthand token `loc <value>` which internally writes `ui_zm_mapstartlocation`.

### Stock-shipped values

| Map | Valid `loc` values |
|---|---|
| `zm_transit` | `transit` (Bus Depot — yes, same name as the parent mode), `town`, `farm` |
| `zm_transit_dr` | `diner` |
| `zm_nuked` | `nuked` |
| `zm_prison` | `prison` (MotD classic), `cellblock` (grief) |
| `zm_buried` | `processing` (classic), `street` (grief/turned) |
| `zm_tomb` | `tomb` |
| `zm_highrise` | `rooftop` |

### Canonical rotation example (xerxes-at `dedicated_zm.cfg` convention)

```
// Classic rotation (all story maps)
sv_maprotation "exec zclassic.cfg gametype zclassic loc processing map zm_buried gametype zclassic loc rooftop map zm_highrise gametype zstandard loc nuked map zm_nuked gametype zclassic loc prison map zm_prison gametype zclassic loc tomb map zm_tomb gametype zclassic loc transit map zm_transit"

// Survival-only
sv_maprotation "exec zstandard.cfg gametype zstandard loc town map zm_transit gametype zstandard loc transit map zm_transit gametype zstandard loc farm map zm_transit"

// Grief (requires https://github.com/JezuzLizard/Public-BO2-Mods/tree/master/GriefFix)
sv_maprotation "exec zgrief.cfg gametype zgrief loc town map zm_transit gametype zgrief loc farm map zm_transit gametype zgrief loc cellblock map zm_prison gametype zgrief loc street map zm_buried"

// Turned
sv_maprotation "exec zcleansed.cfg gametype zcleansed loc diner map zm_transit_dr gametype zcleansed loc street map zm_buried"
```

Single-map private-match form (JezuzLizard survival pack README):

```
ui_zm_gamemodegroup "zsurvival"; ui_gametype "zstandard"; g_gametype "zstandard"; ui_zm_mapstartlocation "town"; map zm_transit
```

**Operational caveats.** Some admins report that multi-entry `sv_maprotation` occasionally kicks clients at rotation on certain Plutonium builds; xerxes-at recommends one map per server instance as the reliable path. There's also a known open issue (`GaryCraft/ptero-plutonium` #… on GitHub) where a seemingly correct survival config still boots TranZit classic — the fix is invariably to ensure the `exec zstandard.cfg` token appears **before** the map tokens and that all four dvars are covered. Community-added locations (`diner`, `power`, `cornfield`, `tunnel`, `house`, `busdepot`, `nuketown`, `docks`, `building1top`, `maze`, `trenches`, `crazyplace`) require JezuzLizard's T6-ZM-Survival-Map-Pack or Bonus-Survival-Maps-for-BO2 mods — they are **not** stock.

## BO2 dvar and cvar references

There is no single comprehensive official list. The authoritative set is assembled from four sources:

**JezuzLizard's Google Drive** (linked from https://github.com/JezuzLizard/Recompilable-gscs-for-BO2-zombies-and-multiplayer): https://drive.google.com/drive/folders/1Nwv3uGFwpopIMMXDVcZdG0iq2vQAVHc- — contains the **"Bo2 Dvars list"** (the single most complete community-maintained dvar catalog), plus FastFile extractor, the original 2014 BO2 ZM dump with developer comments, BO1 full dump, BO3 decompiled scripts, and GSC Studio. A separate beta dump is at https://drive.google.com/file/d/1Rt3sAIoYhCgqhsotrElygta7-BXn-3ZM.

**B2ORG** (speedrun-community GitHub org): https://github.com/B2ORG. The key repos are **`T6-DVAR-DUMPS`** (default values from several launcher builds — the best default-value reference), `T6-B2OP-PATCH` and `T6-B2FR-PATCH` (READMEs document heavy dvar usage: `sv_cheats`, `award_perks`, `player_strafeSpeedScale`, `g_speed`, `velocity_meter`, `cg_flashScriptHashes`, etc.), and `T6-B2EXTENSIONS`.

**Stock GSC grep.** `plutoniummod/t6-scripts` is the de-facto authoritative source for discovering `scr_*`, `sv_*`, `g_*`, `perk_*`, `zombie_*`, and `bots_*` dvars — grep for `GetDvar(`/`SetDvar(`. DeepWiki summary at https://deepwiki.com/plutoniummod/t6-scripts/1-overview.

**Plutonium-added dvars.** Two pages: `/docs/server/dvars/` (server-specific additions) and `/docs/changelog/` (everything else: `cg_drawScriptUsage`, `cg_drawEntityUsage`, `cg_drawStringUsage`, `cg_drawChecksums`, `cg_drawZombieTotal`, `cg_flashScriptHashes`, `cg_drawSounddoneRefCount`, `bg_burstFireInputFix`, `weapon_load_order`, `cl_enableStreamerMode`, plus GSC fileIO).

## GSC scripting reference set

### Decompiled stock scripts
- **https://github.com/plutoniummod/t6-scripts** — the current canonical mirror of decompiled/recompiled Treyarch scripts, organized `MP/Core/…`, `ZM/Core/maps/mp/zombies/…`, and `ZM/Maps/<Mapname>/maps/mp/zm_*.gsc`. Actively maintained.
- **https://github.com/JezuzLizard/Recompilable-gscs-for-BO2-zombies-and-multiplayer** — precursor; the README now points at plutoniummod/t6-scripts, but the repo still hosts `engine functions and descriptions.md`, `debugging_guide.md`, and `CHECKING_GUIDE.md` which remain useful.
- **https://github.com/whydoesanyonecare/Plutonium-versions-of-T6-custom-survival-maps** — ported custom survival scripts (dog_town, diner) for Plutonium.

### GSC API references
**There is no single complete Plutonium GSC function list.** The learning path, confirmed by Resxt and JezuzLizard on the forum, is (1) grep the stock dumps, (2) consult **Zeroy's wiki** (https://wiki.zeroy.com) — the CoD4/WaW/BO1 scripting sections are largely applicable, (3) read existing community scripts. A curated jump-off thread is Plutonium forum **"Resource: GSC Resources and Helpful Links"** at https://forum.plutonium.pw/topic/198. Additional community references: CabConModding's BO2 GSC managed-code list (https://cabconmodding.com/threads/black-ops-2-gsc-managed-code-list.158/), UGX-Mods Scripting Guide (https://confluence.ugx-mods.com/display/UGXMODS/Scripting+Guide).

### Plutonium-specific GSC additions
The **built-in** features are documented at `/docs/modding/gsc/new-scripting-features/`: `replaceFunc(original, replacement)`, path-based script overrides, map/gametype-conditional script folders, native source-script loading (r3408+), `gamemode_callback_setup()` hook.

Beyond that, **`alicealys/t6-gsc-utils`** (https://github.com/alicealys/t6-gsc-utils, v3.0.4, Apr 2024) is the **de-facto standard server-side plugin** and is effectively required for modern Plutonium T6 GSC work. Its README is the reference for: bitwise ops (`and`/`or`/`xor`/`not`), struct/array utilities, entity flags/methods (`god`, `demigod`, `notarget`, `noclip`, `ufo`), chat hooks (`chat::register_callback`, `chat::register_command`), `say`/`tell`/`setname`/`setClantag`, file I/O rooted at `storage/t6`, `httpGet`/`httpPost`, `jsonSerialize`/`jsonParse`, **MySQL** (`mysql::set_config`/`query`/`prepared_statement` — note: **no SQLite**), int64 helpers, HUD text without configstring overflow, bot management (`dropAllBots()`, `bots.txt`), `--gsc-debug` VM stack dumps, and the `sv_display_clan_tag` dvar that fixes IW4MAdmin's clan-tag parsing. Related: `alicealys/t5-gsc-utils`, `alicealys/iw5-gsc-utils`, and the base template `skiff/t6-gsc-helper` for rolling your own builtins.

### Example GSC repositories
- **https://github.com/Resxt/Plutonium-T6-Scripts** — Plutonium staff (Resxt) scripts. Includes a full chat-commands framework (`cc_prefix`, `cc_permission_default`, `cc_permission_mode`, multi-port server support, commands for dvars/freeze/god/invisible/kick and per-mode subfolders), mapvote 2.1.5, misc utilities. Refactored Feb 2023 to drop compiled files since source loading landed.
- **https://github.com/0Nom4D/T6_Mods_Workshop** — EPITECH-style tutorial walking through a zombies mod (round counter, weapon giver, map-aware logic); great beginner onboarding.
- **https://github.com/DoktorSAS/GSC** (multi-game GSC snippets, T6 included), **https://github.com/DoktorSAS/PlutoniumT6Mapvote** (mapvote with `mv_maps`/`mv_enable`/`mv_gametypes`), **https://github.com/DoktorSAS/VanityTS** (menu framework demo).
- **https://github.com/ineedbots/t6_bot_warfare** — MP bot AI mod; canonical reference for `bots_manage_*` dvars.
- **https://github.com/Hadi77KSA/Plutonium-T6-Any-Player-EE-Scripts** — solo-unlock EE scripts.
- **https://github.com/Sparker-99/Plutonium-T6-Plugins**, **https://github.com/ZeroNullx/plutonium-zombies-gsc-scripts**, **https://github.com/mjkzy/t6-zm-chat-bank**, **https://github.com/TheSoliderror/T6-Server-Plugins**, and forum releases like **"Astroolean Approved Modpack (2026)"** (forum topic 44175) and **"Ultimate T6 Zombies Overhaul"** (topic 44437) demonstrate current `replaceFunc`/`GetFunction` detour patterns.

### Compiler and decompiler tooling
**`xensik/gsc-tool`** (https://github.com/xensik/gsc-tool) is the **recommended compiler/decompiler**. Supports T6 plus IW5/IW6/IW7/IW8/IW9/S1/S2/S4/H1/H2 (T7+ partial). Modes: `asm`, `disasm`, `comp`, `decomp`. Typical T6 invocation: `gsc-tool.exe comp t6 path\to\file.gsc`. Pre-built Windows binaries on the releases page; v1.4.6 as of mid-2024. Also wrapped by DoktorSAS's PowerShell autocompiler (forum topic 15122).

**`Scobalula/Cerberus-Repo`** (https://github.com/Scobalula/Cerberus-Repo) is the BO2/BO3 **decompiler** with smart loop detection. UI + CLI, x86 VS 2019 runtime required. Known limitations: some for-loops not marked, ternary operators shown as empty if/else, dev-block strings not recovered. A more aggressive fork is Shiversoft's `t7-source` (https://github.com/shiversoftdev/t7-source). Also: `msfwaifu/bo2-gsc-compiler` (older open-source compiler, useful for cross-checks), and the historical GSC Studio IDE bundled in the JezuzLizard Google Drive.

## Community resources

**Plutonium forum** (https://forum.plutonium.pw) structure:
- **BO2 Modding Releases & Resources** (category/23) — https://forum.plutonium.pw/category/23/bo2-modding-releases-resources. Rules/guidelines sticky at topic/514. Key stickies: "Resource: T6 Stock Scripts" (topic/20211), "Resource: Recompileable GSCs" (topic/1356), mapvote release (topic/2582), GriefFix (topic/4057).
- **BO2 Modding Support & Discussion** — https://forum.plutonium.pw/category/11/bo2-modding-support-discussion
- **BO2 Client Support** — https://forum.plutonium.pw/category/9/bo2-client-support
- **BO2 Server Hosting Support** — https://forum.plutonium.pw/category/10/bo2-server-hosting-support. Notable threads: legacy setup guide (topic/13), Windows IW4MAdmin install walkthrough (topic/1589), demo cleanup (topic/9711), **Debian/Linux Wine server guide** (topic/12870 — points at Sterbweise/T6Server).
- **FAQ** (topic/9).

**Plutonium Discord**: https://discord.gg/plutonium (~162k members). Rules at `/docs/policies/discord-rules/`.

**Linux / container tooling**:
- **https://github.com/Sterbweise/T6Server** — the most-maintained Debian Wine installer. Configures `/opt/T6Server/`, supports `t6mp`/`t6zm` with per-mode configs, uses `xvfb-run wineconsole` for headless operation.
- **https://github.com/thejcpalma/aio-plutonium-t6** — Docker all-in-one bundling Plutonium T6 + IW4MAdmin. Ports 4976/udp + 1624/tcp. Env vars: `SERVER_KEY`, `SERVER_RCON_PASSWORD`, `SERVER_MAX_CLIENTS`, `SERVER_MODE`, `SERVER_PASSWORD`. Uses screen sessions plus `mxve/plutonium-updater.rs` for binary updates.
- **https://github.com/nicokimmel/plutonium-t6** — similar Docker fork.
- **https://github.com/xerxes-at/T6ServerConfigs** — **the de-facto reference config repo**. Contains `dedicated_mp.cfg`, `dedicated_zm.cfg`, `!start_{mp,zm}_server.bat`, `gamesettings/{tdm,dom,sd,…}.cfg`, plus `gamesettings_defaults` reference for every dvar each gametype touches. Pelican/Wings eggs typically bootstrap from this repo.

**External wikis**: Call of Duty Wiki (https://callofduty.fandom.com/wiki/Call_of_Duty:_Black_Ops_II) for display-name lookups and DLC grouping; game-modes master page https://callofduty.fandom.com/wiki/Game_Modes. Activision's official mode definitions at https://support.activision.com/call-of-duty--black-ops-ii/articles/what-modes-are-available-in-black-ops-ii-multiplayer. Unofficial but well-organized third-party launcher docs at https://docs.cbservers.xyz/games/t6 (useful cross-reference, not Plutonium).

## IW4MAdmin

**Repo**: https://github.com/RaidMax/IW4M-Admin (develop branch, .NET 8, MIT). **Official download**: https://raidmax.org/IW4MAdmin (stable + nightly). **Wiki root**: https://github.com/RaidMax/IW4M-Admin/wiki. **Discord**: https://discord.gg/ZZFK5p3. **Plugin store** (subscription, auto-update): https://store.raidmax.org/plugins. **Master server** (heartbeat endpoint): https://master.iw4.zip/servers. Related: **GameLogServer** at https://github.com/RaidMax/IW4MAdmin-GameLogServer (remote Python log broadcaster, port 1625) when IW4MAdmin and the game server run on different hosts.

### Wiki pages worth knowing (sidebar order)
Home · Getting Started · FAQ · Features · **Configuration** (full `IW4MAdminSettings.json` reference) · **Commands** (canonical command list by permission level) · Permission Sets · Webfront · Plugins · **Plugin Development** · **C# Script Plugin Development Guide** (new `.cs` hot-reload format, 2026.1+) · Plugin Examples · CS Plugin Examples · **API** (REST/JSON) · **GameInterface** (in-game GSC integration) · Game Log Server · Knowledge Base · Searching · Building Locally · Docker Setup Configuration. Hundreds of auto-generated `datamodels-*`/`datamigrations*-*` pages are EF-class stubs useful only when writing plugins. A Rim mirror at https://git.rimmyscorner.com/Rim/IW4M-Admin is useful when GitHub's wiki is slow.

### T6-specific integration contract
Set **both** `RConParserVersion` and `EventParserVersion` to **`Plutonium T6 Parser`** (identical string for MP and Zombies — no separate ZM parser exists). In your `dedicated_{mp,zm}.cfg`, **`g_logSync 2`** is mandatory (T6 otherwise buffers log writes), and every server instance needs a **unique** `g_log` filename (shared logs produce `Unable to add player` parse errors). `rcon_password` must match `Password` in the server block. If IW4MAdmin is on a different host, add `rconWhitelistAdd "<iw4m_ip>"` in the cfg and set `GameLogServerUrl` in the per-server block. On WINE, set `ManualLogPath` explicitly so IW4MAdmin doesn't have to resolve Windows short paths.

Minimal per-server JSON:

```json
{
  "IPAddress": "127.0.0.1",
  "Port": 4976,
  "Password": "…",
  "RConParserVersion": "Plutonium T6 Parser",
  "EventParserVersion": "Plutonium T6 Parser",
  "ReservedSlotNumber": 0
}
```

### Command inventory (abridged)
Penalty stack: `!kick`, `!ban`, `!tempban` (minutes supported since 2025.5), `!unban`, `!warn`/`!warnclear`, `!flag`/`!unflag`, `!mute`/`!unmute`, `!mask`. Info: `!help`, `!whoami`, `!list`, `!find`/`!findall`, `!admins`, `!listreports`, `!listaliases`, `!listplugins`, `!ip`. Chat: `!say`, `!sayall`, `!pm`, `!offlinemessage`/`!readmessage`, `!report`. Server control: `!map`, `!maprotate`, `!setgametype`, `!mapgametype`, `!owner` (first-run only), `!rt` (webfront login token). Permissions: `!setlevel`, `!setpassword`, `!addclientnote`, `!addclienttag`/`!setclienttag`/`!unsetclienttag`. Stats: `!topstats`, `!mostplayed`, `!stats`, `!mostkills`, `!resetstats`. Permission tiers ascend User → Flagged → Trusted → Moderator → Administrator → SeniorAdmin → Owner → Creator; overridable via `OverridePermissionLevelNames`.

### Known Plutonium-T6 quirks
Chat commands prefixed `!` **are visible in chat** on T6 (unlike IW4x/IW5 where `/`-prefix hides them) — use the webfront for sensitive ops like `!setpassword`. T6 **Zombies** RCon/log integration has a long history of flakiness (forum topics 9715, 19690) relative to MP; MP is rock-solid. Older topic/1589 instructions reference numeric parser selection ("3 = IW5, 4 = T6") that modern builds no longer use — rely on the Configuration wiki for current prompts. Webfront defaults to port 1624; GameLogServer to 1625; modern IW4MAdmin requires the **.NET 8 ASP.NET Hosting Bundle**.

### Plugin development
Three plugin flavors: compiled C# `.dll` (traditional `IPlugin`), JavaScript `.js` (Jint ECMA 5.1, hot-reloaded), and the new **C# script `.cs`** format (2026.1+, hot-reloaded, see "C# Script Plugin Development Guide" wiki page — PR #385). Plugin API exposes DI services (`IConfigurationHandlerFactory`, `IDatabaseContextFactory`, `IMetaService`, `IManager`, `IClientService`, `ITranslationLookup`) and the `GameEvent.EventType` enum for event hooks. Canonical sample: `Plugins/Welcome/Plugin.cs`. Notable community plugins: Zwambro's **VPN detection** (https://github.com/Zwambro/iw4madmin-plugin-vpndetectors) and **IW4ToDiscord** webhook bridge (https://github.com/Zwambro/iw4madmin-plugin-iw4todiscord). Python webfront wrapper: https://pypi.org/project/iw4m/.

## Operator cheatsheet

| Thing | Value |
|---|---|
| Default game port | 4976/udp |
| Plutonium storage root (Wine) | `~/.wine/drive_c/users/<u>/AppData/Local/Plutonium/storage/t6/` |
| GSC script auto-load paths | `scripts/`, `scripts/mp/`, `scripts/zm/`, `scripts/mp/<map>/`, `scripts/mp/<gametype>/` |
| Mod folder | `mods/<Name>/scripts/{mp,zm}/`, enabled via `fs_game "mods/<Name>"` |
| Reference server configs | https://github.com/xerxes-at/T6ServerConfigs |
| Stock script reference | https://github.com/plutoniummod/t6-scripts |
| Dvar catalog | JezuzLizard Google Drive + B2ORG/T6-DVAR-DUMPS + `/docs/changelog/` |
| GSC utils plugin (near-required) | https://github.com/alicealys/t6-gsc-utils |
| Compiler/decompiler | `xensik/gsc-tool` + `Scobalula/Cerberus-Repo` |
| TranZit sub-location dvar | `ui_zm_mapstartlocation` (or `loc <v>` inside `sv_maprotation`) |
| ZM mode requires 4 dvars | `ui_zm_mapstartlocation` + `g_gametype` + `ui_zm_gamemodegroup` + `mapname` |
| IW4MAdmin T6 parser name | `Plutonium T6 Parser` (Event + RCon) |
| IW4MAdmin T6 must-have dvars | `g_logSync 2` + unique `g_log` per instance |

## Takeaways

The T6 documentation landscape is genuinely fragmented, which is the single most important thing to internalize: there is no "docs site" that answers most operational questions, and the real reference set lives in five complementary places — plutonium.pw/docs (thin), `plutoniummod/t6-scripts` (authoritative via grep), JezuzLizard's Google Drive dvars list, xerxes-at's config templates, and alicealys's `t6-gsc-utils` README. The canonical TranZit-survival mechanism is **`ui_zm_mapstartlocation`** (aliased as `loc` in `sv_maprotation`), requiring coordinated changes to four dvars plus the right `exec *.cfg` fragment — the xerxes-at repo encodes this correctly and is the template to clone. For IW4MAdmin, the single most common T6 misconfiguration is the `g_logSync 2` + unique `g_log` + matching parser-name triplet; nail those and MP works immediately, though Zombies RCon remains historically inconsistent across Plutonium builds and is worth smoke-testing on every update. Finally, modern GSC development on Plutonium is effectively a dependency on `alicealys/t6-gsc-utils` — budget time to read its README end-to-end, because it documents features (MySQL, HTTP, file I/O, regex, int64, chat hooks, debug dumps) that have no counterpart in the official Plutonium docs.
