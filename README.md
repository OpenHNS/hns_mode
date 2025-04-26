## [README in English](https://github.com/OpenHNS/hns_mode/blob/main/README_ENG.md)

# hns_mode

Hide'N'Seek мод для Counter-Strike 1.6 и доп. плагины к моду.

## Требование

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

## Характеристики

- Public / DeathMatch мод.
- Автоматический свап команд в случае неоднократной победы команды ТТ.
- Гибкая настройка кварами и lang файл.
- Кастомная пикалка (+USE) у команды ТТ и свист раз в 15 секунд.
- Возможность добавлять и связывать дополнительные плагины для основного плагина.

## Описание

Hide'N'Seek - По большей части догонялки. Команда КТ догоняет команду ТТ. Команде ТТ дается 5 секунд (mp_freezetime) чтобы разбежаться. У команды ТТ есть гранаты, у команды КТ только нож. Но не все так просто, мод интересен тем, что из-за особенностей движка игроки с помощью "багов" могут передвигаться быстрее.

## Консольные команды (квары)

| Cvar | Default | Description |
| :-: | :-: | :-: |
| hns_deathmatchт| 0 | Дезматч мод `1` Включить / `0` Отключить |
| hns_respawn | 3 | Кол-во секунд возрождения игроков в режиме ДМ |
| hns_he | 0 | Кол-во HE гранат у команды ТТ |
| hns_flash | 2 | Кол-во Flash гранат у команды ТТ |
| hns_smoke | 1 | Кол-во Smoke гранат у команды ТТ |
| hns_swap_team | 2 | Кол-во выигранных раундов подряд команды ТТ после которого поменять команды местами |
| hns_swist | 1 | Свист (+USE) у команды ТТ `1` Включить / `0` Отключить |
| hns_prefix | HNS | Префикс сообщений в чате |
| hns_ownage_delay | 5.0 | Время между ownage |
| hns_ownage_save | 1 | Сохранение и вывод общего кол-вa ownage |
| hns_roundtime | 2.5 | Время раунда в паблик режиме |
| hns_last_he | 0 | Кол-во HE гранат последнему ТТ |
| hns_last_flash | 1 | Кол-во Flash гранат последнему ТТ |
| hns_last_smoke | 1 | Кол-во Smoke гранат последнему ТТ |
| hns_start_night | 23 | Во сколько часов запускать ночной deathmatch |
| hns_end_night | 9 | Во сколько часов отключать ночной deathmatch |

## Плагины

- hns_main.sma - Основной плагин мода.
- hns_stats.sma - Плагин для подсчета статистики раунда.
- hns_showbest.sma - Плагин выводит статистику лучших игроков в конце раунда.
- hns_hideknife.sma - Позволяет спрятать нож.
- hns_specback.sma - Переходить за наблюдателей и обратно (/spec /back).
- hns_lash_grenade.sma - Последнему живому террористу выдает гранаты.
- hns_night_mode.sma - Плагин ночью включает deathmatch.

## Установка
 
1. Скомпилируйте плагин.

2. Скопируйте скомпилированный файл `.amxx` в директорию: `amxmodx/plugins/`.

3. Скопируйте содержимое папки и саму папку `cstrike/sound/openhns` в директорию: `cstrike/sound/` на вашем сервере.

4. Скопируйте содержимое папки `data/lang/` в директорию: `amxmodx/data/lang/` на вашем сервере.

5. Пропишите `.amxx` в файле `amxmodx/configs/plugins.ini`

6. Перезапустите сервер или поменяйте карту.