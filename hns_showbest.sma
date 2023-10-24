#include <amxmodx>

#include <hns_mode_main>
#include <hns_mode_stats>

#define rg_get_user_team(%0) get_member(%0, m_iTeam)

#define TASK_SHOWSTATS 1328

new g_szPrefix[24];

enum _: PLAYER_STATS {
	PLR_STATS_KILLS,
	PLR_STATS_DEATHS,
	PLR_STATS_ASSISTS,
	PLR_STATS_STABS,
	PLR_STATS_DMG_CT,
	PLR_STATS_DMG_TT,
	Float:PLR_STATS_RUNNED,
	Float:PLR_STATS_FLASHTIME,
	Float:PLR_STATS_SURVTIME,
	PLR_STATS_OWNAGES,
}

new g_StatsRound[MAX_PLAYERS + 1][PLAYER_STATS];

new bool:g_bRoundInfo[MAX_PLAYERS + 1];

new g_eBestIndex[PLAYER_STATS];
new g_eBestStats[PLAYER_STATS];

new g_szMess[2048];

new g_iSecShow;

new g_HudSync;

public plugin_init() {
	register_plugin("HNS Show round best players", "1.0", "OpenHNS");

	register_clcmd("say /roundinfo", "cmdRoundInfo");
	register_clcmd("say_team /roundinfo", "cmdRoundInfo");

	g_HudSync = CreateHudSyncObj();
}

public client_putinserver(id) {
	g_bRoundInfo[id] = true;
}

public plugin_cfg() {
	hns_get_prefix(g_szPrefix, charsmax(g_szPrefix));
}

public cmdRoundInfo(id) {
	g_bRoundInfo[id] = !g_bRoundInfo[id];
	
	if (g_bRoundInfo[id])
		client_print_color(id, print_team_blue, "%L", id, "ROUNDINFO_ON", g_szPrefix);
	else
		client_print_color(id, print_team_blue, "%L", id, "ROUNDINFO_OFF", g_szPrefix);

	return PLUGIN_HANDLED;
}

public hns_round_end() {
	new iPlayers[MAX_PLAYERS], iCTNum, iTTNum
	get_players(iPlayers, iCTNum, "che", "CT");
	get_players(iPlayers, iTTNum, "che", "TERRORIST");

	if (iCTNum + iTTNum > 1) {
		set_best_stats();

		set_best_mess();

		g_iSecShow = 10;
		set_task(1.0, "taskShowStats", TASK_SHOWSTATS, .flags = "b");
	}
}

public set_best_stats() {
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ch");

	for (new i = 0; i < iNum; i++) {
		new id = iPlayers[i];

		get_player_stats(id);
		
		for (new j = 0; j < PLAYER_STATS; j++) {
			if (g_StatsRound[id][j] > g_eBestStats[j])
			{
				g_eBestStats[j] = g_StatsRound[id][j];
				g_eBestIndex[j] = id;
			}
		}
	}
}

public get_player_stats(id) {
	g_StatsRound[id][PLR_STATS_KILLS] = hns_get_stats_kills(id);
	g_StatsRound[id][PLR_STATS_DEATHS] = hns_get_stats_deaths(id);
	g_StatsRound[id][PLR_STATS_ASSISTS] = hns_get_stats_assists(id);
	g_StatsRound[id][PLR_STATS_STABS] = hns_get_stats_stabs(id);
	g_StatsRound[id][PLR_STATS_DMG_CT] = hns_get_stats_dmgct(id);
	g_StatsRound[id][PLR_STATS_DMG_TT] =  hns_get_stats_dmgtt(id);
	g_StatsRound[id][PLR_STATS_RUNNED] = hns_get_stats_run(id);
	g_StatsRound[id][PLR_STATS_FLASHTIME] = hns_get_stats_flashtime(id);
	g_StatsRound[id][PLR_STATS_SURVTIME] = hns_get_stats_surv(id);
	g_StatsRound[id][PLR_STATS_OWNAGES] = hns_get_stats_ownages(id);
}

public set_best_mess() {
	new iLen = format(g_szMess, sizeof g_szMess - 1, "Best players of the round:^n^n");

	new sTime[24];
	fnConvertTime(g_eBestStats[PLR_STATS_SURVTIME], sTime, charsmax(sTime));
	
	if (g_eBestIndex[PLR_STATS_SURVTIME])	iLen += format(g_szMess[iLen], sizeof g_szMess - iLen, "Survived: %n - %s^n", g_eBestIndex[PLR_STATS_SURVTIME], sTime)
	if (g_eBestIndex[PLR_STATS_OWNAGES])	iLen += format(g_szMess[iLen], sizeof g_szMess - iLen, "Ownages: %n - %d^n", g_eBestIndex[PLR_STATS_OWNAGES], g_eBestStats[PLR_STATS_OWNAGES])
	if (g_eBestIndex[PLR_STATS_KILLS])		iLen += format(g_szMess[iLen], sizeof g_szMess - iLen, "Killed: %n - %d^n", g_eBestIndex[PLR_STATS_KILLS], g_eBestStats[PLR_STATS_KILLS])
	if (g_eBestIndex[PLR_STATS_ASSISTS])	iLen += format(g_szMess[iLen], sizeof g_szMess - iLen, "Assists: %n - %d^n", g_eBestIndex[PLR_STATS_ASSISTS], g_eBestStats[PLR_STATS_ASSISTS])
	if (g_eBestIndex[PLR_STATS_STABS])		iLen += format(g_szMess[iLen], sizeof g_szMess - iLen, "Stabs: %n - %d^n", g_eBestIndex[PLR_STATS_STABS], g_eBestStats[PLR_STATS_STABS])
	if (g_eBestIndex[PLR_STATS_DMG_CT])		iLen += format(g_szMess[iLen], sizeof g_szMess - iLen, "CT Dmg: %n - %d^n", g_eBestIndex[PLR_STATS_DMG_CT], g_eBestStats[PLR_STATS_DMG_CT])
	if (g_eBestIndex[PLR_STATS_DMG_TT])		iLen += format(g_szMess[iLen], sizeof g_szMess - iLen, "TT Dmg: %n - %d^n", g_eBestIndex[PLR_STATS_DMG_TT], g_eBestStats[PLR_STATS_DMG_TT])
	if (g_eBestIndex[PLR_STATS_RUNNED])		iLen += format(g_szMess[iLen], sizeof g_szMess - iLen, "Runned: %n - %.2f^n", g_eBestIndex[PLR_STATS_RUNNED], g_eBestStats[PLR_STATS_RUNNED])
	if (g_eBestIndex[PLR_STATS_FLASHTIME]) 	iLen += format(g_szMess[iLen], sizeof g_szMess - iLen, "Flashed: %n - %.2f^n", g_eBestIndex[PLR_STATS_FLASHTIME], g_eBestStats[PLR_STATS_FLASHTIME])
}

public fnConvertTime(Float:time, convert_time[], len) {
	new sTemp[24];
	new Float:fSeconds = time, iMinutes;

	iMinutes = floatround(fSeconds / 60.0, floatround_floor);
	fSeconds -= iMinutes * 60.0;
	new intpart = floatround(fSeconds, floatround_floor);
	new Float:decpart = (fSeconds - intpart) * 100.0;
	intpart = floatround(decpart);

	formatex(sTemp, charsmax(sTemp), "%02i:%02.0f.%d", iMinutes, fSeconds, intpart);

	formatex(convert_time, len, sTemp);

	return (PLUGIN_HANDLED);
}


public taskShowStats(id) {
	if (g_iSecShow) {
		g_iSecShow--;
	} else {
		remove_task(TASK_SHOWSTATS);
	}

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ch");

	for (new i = 0; i < iNum; i++) {
		new id = iPlayers[i];
	
		if (!is_user_connected(id) || !g_bRoundInfo[id]) {
			continue;
		}

		set_hudmessage(.red = 100, .green = 100, .blue = 100, .x = 0.1, .y = -1.0, .fxtime = 0.0, .holdtime = 1.0);
		ShowSyncHudMsg(id, g_HudSync, g_szMess);
	}
}

public hns_round_start() {
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ch");

	for (new i = 0; i < iNum; i++) {
		new id = iPlayers[i];
		arrayset(g_StatsRound[id], 0, PLAYER_STATS);

	}

	arrayset(g_eBestIndex, 0, PLAYER_STATS);
	arrayset(g_eBestStats, 0, PLAYER_STATS);
	g_szMess[0] = 0;
}