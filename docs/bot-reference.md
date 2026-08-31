# MiniMarkers bot reference

Addon: MiniMarkers, version 4.4.4, by Verz.
Supported interface versions (from the .toc): 120100, 50504, 40402, 38002, 38000, 30405, 20506, 11509. This covers retail (12.1.0) and the Classic clients (Mists Classic, Cataclysm Classic, Wrath Classic, TBC Classic, Classic Era).
Saved variables: MiniMarkersDB (account wide). Optional dependency: FrameSort (used for spec detection when present; MiniMarkers has its own inspector otherwise).

## What it does

MiniMarkers draws an icon (a "marker") above unit nameplates: spec icons, role icons, class icons, or a custom texture, plus special icons for Battle.net friends, guild members, and pets. It was made mostly for arena to track teammate positioning, but works in any content. Markers only appear on nameplates, so nameplates must be enabled in the game for anything to show.

## Slash commands

`/minimarkers`, `/minim`, and `/mm` all open the settings panel (Options -> AddOns -> MiniMarkers). There are no subcommands.

## How a marker is chosen

For each nameplate, checks run in this order. The first match wins:

1. Your own nameplate never gets a marker (avoids the personal resource display).
2. Totems never get a marker.
3. If "Arena Only" is on and you are not in an arena, no marker.
4. Pets: your own pet uses a dedicated own-pet icon at full size (needs "My Pet" on). Other pets use the pet icon at 50% scale (needs "Pets" on).
5. Battle.net friends get the friend icon (needs "Friends" on, Special Icons panel).
6. Guild members get the guild icon (needs "Guild" on, Special Icons panel).
7. Otherwise the unit must pass at least one filter (Allies, Enemies, Group, NPCs, PvP Flagged), then the role filters (Roles panel), and then gets an icon by type priority: spec -> role -> class -> texture. Only enabled icon types are considered; if none of the enabled types can produce an icon, no marker shows.

Friend and guild icons apply regardless of the Allies/Group filters, and use the Friendly size/background/border settings.

Reaction rules: group members always count as friendly (this covers cross-faction / mercenary arena teammates). Neutral units count as friendly.

## Icon types

- Spec Icons: the unit's specialization icon. Spec data comes from FrameSort when it is installed, otherwise from MiniMarkers' own inspector (see Spec detection).
- Role Icons: tank/healer/dps icons. For group members the assigned role is used. For anyone else the role is inferred from their spec.
- Class Icons: the game's own class icons.
- Texture Icons: the custom texture from the Custom Texture panel.

Colouring: role and texture icons are tinted red for enemies when "Red enemies" is on (default), otherwise class-coloured when class colours are enabled (default, saved-variable only, see Hidden settings). Class and spec icons are never tinted.

## Settings

All settings apply immediately. A "Reset" button sits at the top right of the main panel; it asks for confirmation and restores all defaults (it is blocked during combat).

### Main panel (MiniMarkers)

Header text: "Show markers above nameplates." followed by "Priority: spec > role -> class -> texture."

Friendly Icon Types:

| Option | Default | Notes |
|---|---|---|
| Spec Icons | On | On for new installs and after a reset; an existing config keeps whatever it was set to |
| Role Icons | Off | |
| Class Icons | Off | |
| Texture Icons | Off | Uses the Custom Texture panel's texture |

Enemy Icon Types (hidden on Midnight clients, see Version-gated behaviour):

| Option | Default |
|---|---|
| Spec Icons | On |
| Role Icons | Off |
| Class Icons | Off |
| Texture Icons | Off |

Filters:

| Option | Default | What it shows markers for |
|---|---|---|
| Allies | On | All friendly players |
| Enemies | On | All enemy players (hidden on Midnight clients) |
| Group | On | Group members |
| PvP Flagged | On | PvP-flagged players |
| Pets | Off | Other players' pets (50% size) |
| My Pet | Off | Your own pet, even when Pets is off |
| NPCs | Off | Non-player units |
| Arena Only | Off | Restricts all markers to arenas |

Size & Position & Background: two tabs, Friendly and Enemy, each with the same controls (the Enemy tab is hidden on Midnight clients). Both sides default to the same values:

| Option | Default | Range | Notes |
|---|---|---|---|
| Shape (dropdown) | Square | Square / Circle | Shape of the icon mask, background and border |
| Background | On | checkbox | Black background behind the icon |
| Border | On | checkbox | Class-coloured border around the icon (needs a resolvable class colour) |
| Size | 50 | 20-200, step 5 | Sets icon width and height together |
| Padding | 1 | 0-30, step 1 | Background padding around the icon |
| X Offset | 0 | -200 to 200, step 5 | Horizontal offset from the nameplate |
| Y Offset | 20 | -200 to 200, step 5 | Vertical offset above the nameplate |

### Roles subpanel

Role filters only take effect once at least one role is unchecked on that side. When they are active, units whose role cannot be determined (not in your group and no spec data yet) are hidden.

- Friendly Filters: Tanks (On), Healers (On), DPS (On).
- Enemy Filters (hidden on Midnight clients): Tanks (On), Healers (On), DPS (On).
- Enemy Colouring (hidden on Midnight clients): "Red enemies" (On) - tints enemy role and texture icons red.

### Custom Texture subpanel

- Texture (edit box): atlas name, texture path, or texture file ID. Default: `plunderstorm-glues-logoarrow` (an arrow).
- Rotation (slider): 0-360 degrees, step 15, default 0.
- A clickable picker grid with preset choices: single arrow, double arrow, triangle, smiley, exclamation mark, question mark, love heart. Presets that do not exist on the current game client are filtered out of the grid.

### Special Icons subpanel

- Friends (On): special icon for Battle.net (btag) friends. Only Battle.net friends who are online in WoW are detected; the in-game character friends list is not used.
- Guild (On): special icon for guild members.

## Hidden settings (saved variables only, no UI)

These exist in MiniMarkersDB but have no options widget:

| Key | Default | Effect |
|---|---|---|
| IconClassColors | true | Class-colour role and texture icons |
| IconDesaturated | true | Desaturate role and texture icons before tinting |
| EnableDistanceFading | false | When false, markers ignore nameplate alpha fading and stay fully opaque |
| PetIconScale | 0.5 | Size multiplier for other players' pet icons (own pet is always full size) |
| SpecCache | {} | GUID -> spec cache written by the built-in inspector, not a user setting. Entries expire after 3 days |

## Spec detection

Spec IDs are resolved through a fallback chain, first hit wins:

1. FrameSort's Inspector API, when FrameSort is installed.
2. MiniMarkers' own inspector: a cached GUID -> spec table, then the unit's tooltip, then an async `NotifyInspect` queue that walks your group. Results are cached in MiniMarkersDB and survive reloads for 3 days.
3. `GetArenaOpponentSpec` for arena opponents, matched to nameplate units by unit token.

Only friendly units can be inspected, so enemy specs come from the tooltip or from the arena opponent list. Markers refresh automatically whenever any source learns a new spec.

## Integrations

- FrameSort (optional dependency): its Inspector API is the preferred spec source and is asked first. MiniMarkers refreshes markers whenever FrameSort reports new inspect data. Nothing breaks without it; the built-in inspector takes over.
- Nameplate addons (Plater, Platynator, etc.): supported. Markers anchor to the Blizzard nameplate unit frame, or to the nameplate itself when an addon hides that frame. MiniMarkers deliberately processes nameplate events one frame late so nameplate addons run first.

## Version-gated behaviour

On Midnight clients (expansion level 12+, where the game returns "secret" protected values):

- Enemy markers are not supported and are disabled. The Enemy Icon Types section, the Enemies filter, the Enemy size/position tab, the Enemy role filters, and "Red enemies" are all hidden from the options UI.
- Battle.net friend detection fails when the game hides unit names, so friend icons may not show.
- Totem detection is unavailable, so totems may be treated as NPCs.

On clients without nameplate APIs at all, the addon prints "Unable to run due to missing nameplate APIs." and does nothing.

## Troubleshooting by symptom

- No markers at all: check that nameplates are enabled in the game (friendly and/or enemy nameplates, default keys V / shift-V). Markers can only attach to visible nameplates. Also check "Arena Only" is not on while outside an arena.
- No marker on my own character: intentional. Your own nameplate is always skipped.
- Spec icons not showing: spec data has to be inspected first, so an icon can appear a moment after a unit shows up. Enemies outside arena often never resolve, since the game does not allow inspecting them.
- Role icons missing on some players: players outside your group need a resolved spec for role detection; group members need an assigned role.
- Some players lost their markers after I unchecked a role: with any role filter unchecked, units whose role cannot be determined are hidden too.
- Enemy markers gone / enemy options missing: on Midnight clients enemy markers are unsupported and their options are hidden.
- Friend icon not showing for a friend: only Battle.net friends currently online in WoW get the icon, not the character-level friends list.
- Pet has no marker: "Pets" (other players' pets) and "My Pet" (your own) are separate checkboxes and both default to off.
- No marker on totems: intentional, totems are always skipped.
- Marker is in the wrong place: adjust X/Y Offset per side under Size & Position & Background. Friendly and Enemy have separate offsets.
- Enemy icons are red: "Red enemies" on the Roles panel, on by default. It only affects role and texture icons.
- Border option does nothing: the border is class-coloured, so it needs a unit whose class colour can be resolved.
- Custom texture not showing: the Texture box accepts an atlas name, a texture path, or a file ID; an invalid value renders nothing. Texture Icons must also be enabled as an icon type, and every higher-priority enabled type (spec, role, class) takes precedence.
- Settings did not save / reset unexpectedly: settings older than the current format are migrated automatically; upgrading from version 1 of the settings format required a full reset.
