/*
    Snipers Only (Strict + OSOK + Random Loadouts) — Plutonium T6 MP
    ---------------------------------------------------------------------------
    Install:
        plutonium/storage/t6/scripts/mp/snipers_only.gsc

    What it does:
        - On every spawn (humans AND Bot Warfare bots):
            * Strips any primary not in `snipers_allowed`.
            * Strips secondaries (no pistols).
            * Strips lethals (frag/semtex/betty/claymore/C4/hatchet).
            * Strips knife (no melee).
            * KEEPS tacticals and killstreaks.
            * If player has no sniper, gives them a RANDOM one from the list,
              with a RANDOM valid attachment combo and a RANDOM camo.
        - OSOK: clamps max health so every sniper hit is lethal.
        - Polls current weapon to catch ground/body pickups.
        - Disables melee engine-side via `player_meleeRange 0`.

    Camo API notes (verified against Plutonium t6-scripts + Resxt's chat_commands):
        - Camos apply via giveWeapon's 3rd argument (weaponOptions), NOT via
          setWeaponAmmoClip. The old setWeaponAmmoClip(weapon, ammo, camo) form
          is a myth — that function is (weapon, count) only.
        - The runtime camo enum is 0-45. Index 15 = Gold, 16 = Diamond.
        - Short form: self giveWeapon(weaponStr, 0, camoIndex)
        - Long form: self giveWeapon(weaponStr, 0, calcWeaponOptions(camo,0,0,0,0))

    Attachment pools are curated per-sniper to avoid invalid combinations
    (e.g. DSR-50 can't take ACOG). Two attachments max (stock limit without
    Primary Gunfighter wildcard).

    "XPR-50" in the BO2 UI maps internally to `as50_mp`.
*/

#include maps\mp\_utility;
#include common_scripts\utility;

init()
{
    if ( getdvar( "snipers_allowed" ) == "" )
        setdvar( "snipers_allowed", "dsr50_mp,ballista_mp,svu_mp,as50_mp" );
    if ( getdvar( "snipers_enforce_delay" ) == "" )
        setdvar( "snipers_enforce_delay", "0.25" );
    if ( getdvar( "snipers_osok_health" ) == "" )
        setdvar( "snipers_osok_health", "30" );
    if ( getdvar( "snipers_pickup_poll" ) == "" )
        setdvar( "snipers_pickup_poll", "0.5" );
    if ( getdvar( "snipers_randomize_camo" ) == "" )
        setdvar( "snipers_randomize_camo", "1" );
    if ( getdvar( "snipers_randomize_attach" ) == "" )
        setdvar( "snipers_randomize_attach", "1" );

    // Disable melee engine-side. Cheaper and more reliable than stripping the
    // knife on every spawn, and prevents bots from meleeing too.
    setdvar( "player_meleeRange", "0" );

    level.snipers_list          = strtok( getdvar( "snipers_allowed" ), "," );
    level.snipers_enforce_delay = getdvarfloat( "snipers_enforce_delay" );
    level.snipers_osok_health   = getdvarint( "snipers_osok_health" );
    level.snipers_pickup_poll   = getdvarfloat( "snipers_pickup_poll" );
    level.snipers_rand_camo     = getdvarint( "snipers_randomize_camo" );
    level.snipers_rand_attach   = getdvarint( "snipers_randomize_attach" );

    level.snipers_tacticals = array(
        "flash_grenade_mp",
        "concussion_grenade_mp",
        "emp_grenade_mp",
        "smoke_grenade_mp",
        "willy_pete_mp",
        "proximity_grenade_mp",
        "sensor_grenade_mp",
        "trophy_mp",
        "tacticalinsertion_mp",
        "blackhat_mp"
    );

    // Per-sniper attachment pools. Optics and utilities are separated into
    // distinct slots; each spawn can pick one from each (or neither).
    //
    // DSR-50: bolt-action anti-materiel. No ACOG (unrealistic on this class).
    level.snipers_attach[ "dsr50_mp" ]       = array( "swayreduc", "fmj", "steadyaim", "ir", "dualclip", "extbarrel" );
    level.snipers_attach_optic[ "dsr50_mp" ] = array( "vzoom" );

    // Ballista: versatile bolt-action, most attachment variety.
    level.snipers_attach[ "ballista_mp" ]       = array( "swayreduc", "fmj", "steadyaim", "ir", "dualclip", "suppressed", "extbarrel" );
    level.snipers_attach_optic[ "ballista_mp" ] = array( "vzoom", "acog", "reflex", "dualoptic" );

    // SVU: semi-auto, grip/fastads fit the profile.
    level.snipers_attach[ "svu_mp" ]       = array( "swayreduc", "fmj", "steadyaim", "ir", "extclip", "extbarrel", "grip", "fastads" );
    level.snipers_attach_optic[ "svu_mp" ] = array( "vzoom", "reflex", "acog", "eotech", "dualoptic" );

    // XPR-50 (as50_mp): semi-auto bullpup, full optic range.
    level.snipers_attach[ "as50_mp" ]       = array( "swayreduc", "fmj", "steadyaim", "ir", "extclip", "fastads" );
    level.snipers_attach_optic[ "as50_mp" ] = array( "vzoom", "acog", "reflex", "eotech", "dualoptic" );

    // Runtime camo enum (0-45). Anchors verified:
    //   11=Cherry Blossom, 12=Art of War, 15=Gold, 16=Diamond, 39=PaP (OG).
    // The 17-38 DLC block is best-guess ordering; if any index renders a
    // blank camo on your build, remove it from this list. To see the exact
    // names your Plutonium build uses, iterate mp/camoTable.csv in-game.
    level.snipers_camos = array(
        0,   // None / stock
        1,   // DEVGRU
        2,   // A-TACS AU
        3,   // ERDL
        4,   // Siberia
        5,   // Choco
        6,   // Blue Tiger
        7,   // Bloodshot
        8,   // Ghostex: Delta 6
        9,   // Kryptek: Typhon
        10,  // Carbon Fiber
        11,  // Cherry Blossom (anchor)
        12,  // Art of War (anchor)
        13,  // Ronin
        14,  // Skulls
        15,  // Gold (anchor)
        16,  // Diamond (anchor)
        17,  // DLC block begins - ordering approximate
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        35,
        36,
        37,
        38,
        39,  // Pack-a-Punch (OG) - from stock _zm_weapons.gsc
        40,  // MotD PaP
        41,  // Aqua (MP DLC)
        42,  // Breach (MP DLC)
        43,  // Coyote (MP DLC)
        44,  // Glam (MP DLC)
        45   // Origins PaP
    );

    level thread onPlayerConnect();
}

onPlayerConnect()
{
    for ( ;; )
    {
        level waittill( "connected", player );
        player thread onPlayerSpawned();
    }
}

onPlayerSpawned()
{
    self endon( "disconnect" );

    for ( ;; )
    {
        self waittill( "spawned_player" );
        self thread applyOSOK();
        self thread enforceLoadout();
        self thread watchPickup();
    }
}

applyOSOK()
{
    self endon( "disconnect" );
    self endon( "death" );

    wait 0.05;

    self.maxhealth = level.snipers_osok_health;
    self.health    = level.snipers_osok_health;
}

enforceLoadout()
{
    self endon( "disconnect" );
    self endon( "death" );

    // Wait for stock giveLoadout (CaC) and Bot Warfare loadout assignment to
    // finish before we strip — otherwise they overwrite our changes.
    wait level.snipers_enforce_delay;

    weapons   = self getweaponslist();
    hasSniper = false;

    for ( i = 0; i < weapons.size; i++ )
    {
        if ( isSniperWeapon( weapons[i] ) )
        {
            hasSniper = true;
            continue;
        }
        if ( isTacticalWeapon( weapons[i] ) )
            continue;

        // Strip everything else: pistols, ARs/SMGs/LMGs/shotguns, lethals,
        // AND knives (no melee on snipers-only).
        self takeweapon( weapons[i] );
    }

    if ( !hasSniper )
    {
        giveRandomSniper( self );
    }
}

giveRandomSniper( player )
{
    base = level.snipers_list[ randomInt( level.snipers_list.size ) ];

    if ( level.snipers_rand_attach && isDefined( level.snipers_attach[ base ] ) )
    {
        weapon_str = base + buildRandomAttachments( base );
    }
    else
    {
        weapon_str = base;
    }

    if ( level.snipers_rand_camo )
    {
        camo = level.snipers_camos[ randomInt( level.snipers_camos.size ) ];
        // Third arg to giveWeapon is weaponOptions; camo index packs into
        // the low bits. calcWeaponOptions(camo,0,0,0,0) is the explicit form;
        // the short form `giveWeapon(str, 0, camo)` also works for pure-camo
        // application. Using the explicit form for forward-compat with optics.
        options = player calcWeaponOptions( camo, 0, 0, 0, 0 );
        player giveweapon( weapon_str, 0, options );
    }
    else
    {
        player giveweapon( weapon_str );
    }

    player givemaxammo( weapon_str );
    player switchtoweapon( weapon_str );
}

// Pick one optic (or none) and one utility attachment (or none). Stock BO2
// allows up to 2 attachments without the Primary Gunfighter wildcard, so we
// cap at 2. 30% chance of no optic (iron sights for variety).
buildRandomAttachments( base )
{
    result = "";

    optics    = level.snipers_attach_optic[ base ];
    utilities = level.snipers_attach[ base ];

    if ( randomInt( 100 ) < 70 && isDefined( optics ) && optics.size > 0 )
    {
        result = result + "+" + optics[ randomInt( optics.size ) ];
    }

    if ( randomInt( 100 ) < 80 && isDefined( utilities ) && utilities.size > 0 )
    {
        result = result + "+" + utilities[ randomInt( utilities.size ) ];
    }

    return result;
}

watchPickup()
{
    self endon( "disconnect" );
    self endon( "death" );

    for ( ;; )
    {
        wait level.snipers_pickup_poll;

        current = self getcurrentweapon();

        if ( !isDefined( current ) || current == "none" )
            continue;
        if ( isSniperWeapon( current ) )
            continue;
        if ( isTacticalWeapon( current ) )
            continue;

        self takeweapon( current );

        weapons = self getweaponslist();
        for ( i = 0; i < weapons.size; i++ )
        {
            if ( isSniperWeapon( weapons[i] ) )
            {
                self switchtoweapon( weapons[i] );
                break;
            }
        }
    }
}

isSniperWeapon( weapon )
{
    if ( !isDefined( weapon ) || weapon == "none" )
        return false;

    base = getBaseName( weapon );
    for ( i = 0; i < level.snipers_list.size; i++ )
    {
        if ( base == level.snipers_list[i] )
            return true;
    }
    return false;
}

isTacticalWeapon( weapon )
{
    base = getBaseName( weapon );
    for ( i = 0; i < level.snipers_tacticals.size; i++ )
    {
        if ( base == level.snipers_tacticals[i] )
            return true;
    }
    return false;
}

getBaseName( weapon )
{
    parts = strtok( weapon, "+" );
    if ( parts.size == 0 )
        return weapon;
    return parts[0];
}
