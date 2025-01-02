# hns_mode

Hide'N'Seek mod for Counter-Strike 1.6 and additional plugins.

## Requirement

<div style="display: flex;">
<table style="border-collapse: collapse; width: 50%;">
    <tr>
        <td style="text-align: left; padding: 10px;"><a href="https://github.com/rehlds/rehlds" target="_blank">ReHLDS</a></td>
        <td style="text-align: right; padding: 10px;"><a href="https://github.com/rehlds/rehlds/releases"><img alt="GitHub Release" src="https://img.shields.io/github/v/release/rehlds/rehlds?include_prereleases&style=flat-square"></a></td>
    </tr>
    <tr>
        <td style="text-align: left; padding: 10px;"><a href="https://github.com/rehlds/ReGameDLL_CS" target="_blank">ReGameDLL_CS</a></td>
        <td style="text-align: right; padding: 10px;"><a href="https://github.com/rehlds/ReGameDLL_CS/releases"><img alt="GitHub Release" src="https://img.shields.io/github/v/release/s1lentq/ReGameDLL_CS?include_prereleases&style=flat-square"></a></td>
    </tr>
    <tr>
        <td style="text-align: left; padding: 10px;"><a href="https://github.com/rehlds/Metamod-R" target="_blank">Metamod-R</a></td>
        <td style="text-align: right; padding: 10px;"><a href="https://github.com/rehlds/Metamod-R/releases"><img alt="GitHub Release" src="https://img.shields.io/github/v/release/rehlds/Metamod-R?include_prereleases&style=flat-square"></a></td>
    </tr>
    <tr>
        <td style="text-align: left; padding: 10px;"><a href="https://github.com/rehlds/resemiclip" target="_blank">ReSemiclip</a></td>
        <td style="text-align: right; padding: 10px;"><a href="https://github.com/rehlds/resemiclip/releases"><img alt="GitHub Release" src="https://img.shields.io/github/v/release/rehlds/resemiclip?include_prereleases&style=flat-square"></a></td>
    </tr>
    <tr>
        <td style="text-align: left; padding: 10px;"><a href="https://www.amxmodx.org/downloads-new.php" target="_blank">AMXModX (v1.9 or v1.10)</a></td>
        <td style="text-align: right; padding: 10px;"><a href="https://www.amxmodx.org/downloads-new.php"><img alt="AMXModX dependency" src="https://img.shields.io/badge/AMXModX-1.9 | 1.10-blue?style=flat-square"></a></td>
    </tr>
    <tr>
        <td style="text-align: left; padding: 10px;"><a href="https://github.com/rehlds/reapi" target="_blank">ReAPI</a></td>
        <td style="text-align: right; padding: 10px;"><a href="https://github.com/rehlds/reapi/releases"><img alt="GitHub Release" src="https://img.shields.io/github/v/release/rehlds/reapi?include_prereleases&style=flat-square"></a></td>
    </tr>
</table>
</div>
## Features

- Public / DeathMatch mod.
- Automatic team swap in case of repeated TT team wins.
- Flexible customization with quars and lang file.
- Custom kicker (+USE) for TT team and whistle once in 15 seconds.
- Ability to add and link additional plugins to the main plugin.

## Description

Hide'N'Seek - For the most part a catch-up game. The CT team catches up with the TT team. The TT team is given 5 seconds (mp_freezetime) to scatter. Team TT has grenades, the CT team has only the knife. But it's not all that simple, the mod is interesting because of the peculiarities of the engine players with the "bugs" can move faster.

## Console commands (quars)

| Cvar | Default | Description |
| :-: | :-: | :-: |
| hns_deathmatch| 0 | deathmatch mod `1` Enable / `0` Disable |
| hns_respawn | 3 | Number of seconds to revive players in DM mode |
| | hns_he | 0 | HE number of grenades on TT team |
| hns_flash | 2 | Qty of Flash grenades on TT team |
| hns_smoke | 1 | Qty of Smoke grenades on the TT |
| hns_swap_team | 2 | Number of consecutive rounds won by the TT team after which to swap teams |
| hns_swist | 1 | whistle (+USE) on TT team `1` Enable / `0` Disable |
| hns_prefix | HNS | chat message prefix

## Plugins

- hns_main.sma - The main plugin of the mod.
- hns_hideknife.sma - Allows you to hide the knife.
- hns_specback.sma - Goes behind observers and back (/spec /back).
- hns_lash_grenade.sma - The last living terrorist gives grenades.

## installation
 
1. Compile the plugin.

2. Copy the compiled file `.amxx` to directory: `amxmodx/plugins/`.
3. Copy the contents of the folder and the folder itself `cstrike/sound/openhns` in the directory: `cstrike/sound/` on your server.

4. Copy the contents of the folder `data/lang/` to the directory: `amxmodx/data/lang/` on your server.

5. Write `.amxx` in file `amxmodx/configs/plugins.ini`.

6. Restart the server or change the map.