#include <amxmodx>
#include <reapi>
#include <xs>

#include <hns_mode_main>

new bool:g_bDebugMode;

forward hns_ownage(iToucher, iTouched);

#define TASK_TIMER 54345

enum _: PLAYER_STATS {
	PLR_STATS_KILLS,
	PLR_STATS_DEATHS,
	PLR_STATS_ASSISTS,
	PLR_STATS_STABS,
	PLR_STATS_DMG_CT,
	PLR_STATS_DMG_TT,
	Float:PLR_STATS_AVG_SPEED,
	Float:PLR_STATS_RUNNED,
	Float:PLR_STATS_RUNTIME,
	Float:PLR_STATS_FLASHTIME,
	Float:PLR_STATS_SURVTIME,
	PLR_STATS_OWNAGES,
}

new g_StatsRound[MAX_PLAYERS + 1][PLAYER_STATS];

new iLastAttacker[MAX_PLAYERS + 1];

new Float:last_position[MAX_PLAYERS+ 1][3];

new g_hApplyStatsForward;

public plugin_init() {
	register_plugin("HNS: Stats", "1.1", "OpenHNS"); // Garey

	RegisterHookChain(RG_CBasePlayer_Killed, "rgPlayerKilled", true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "rgPlayerTakeDamage", false);
	RegisterHookChain(RG_CBasePlayer_PreThink, "rgPlayerPreThink", true);
	RegisterHookChain(RG_CSGameRules_FlPlayerFallDamage, "rgPlayerFallDamage", true);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "rgRoundFreezeEnd", true);
	RegisterHookChain(RG_CSGameRules_RestartRound, "rgRestartRound", true);

	g_hApplyStatsForward = CreateMultiForward("hns_apply_stats", ET_CONTINUE, FP_CELL);

	g_bDebugMode = bool:(plugin_flags() & AMX_FLAG_DEBUG);
}

public hns_ownage(iToucher, iTouched) {
	g_StatsRound[iToucher][PLR_STATS_OWNAGES]++;

	if (g_bDebugMode) server_print("[HNS_STATS] Player %n add ownage %d", iToucher, g_StatsRound[iToucher][PLR_STATS_OWNAGES]);
}

public rgPlayerKilled(victim, attacker) {
	if (hns_get_mode() != MODE_PUBLIC) {
		return HC_CONTINUE;
	}

	if (is_user_connected(attacker) && victim != attacker) {
		g_StatsRound[attacker][PLR_STATS_KILLS]++;
	}

	if (iLastAttacker[victim] && iLastAttacker[victim] != attacker) {
		g_StatsRound[iLastAttacker[victim]][PLR_STATS_ASSISTS]++;
		if (g_bDebugMode) server_print("[HNS_STATS] Player %n add assists %d", iLastAttacker[victim], g_StatsRound[iLastAttacker[victim]][PLR_STATS_ASSISTS]);
		iLastAttacker[victim] = 0;
	}

	return HC_CONTINUE;
}

public rgPlayerTakeDamage(iVictim, iWeapon, iAttacker, Float:fDamage) {
	if (hns_get_mode() != MODE_PUBLIC) {
		return HC_CONTINUE;
	}

	if (is_user_alive(iAttacker) && iVictim != iAttacker) {
		new Float:fHealth; get_entvar(iVictim, var_health, fHealth);
		if (fDamage < fHealth) {
			iLastAttacker[iVictim] = iAttacker;
		}

		g_StatsRound[iAttacker][PLR_STATS_STABS]++;

		if (g_bDebugMode) server_print("[HNS_STATS] Player %n add stabs %d", iAttacker, g_StatsRound[iAttacker][PLR_STATS_STABS]);
	}

	return HC_CONTINUE;
}

public rgPlayerFallDamage(id) {
	if (hns_get_mode() != MODE_PUBLIC) {
		return HC_CONTINUE;
	}

	new dmg = floatround(Float:GetHookChainReturn(ATYPE_FLOAT));

	if (rg_get_user_team(id) == TEAM_TERRORIST) {
		g_StatsRound[id][PLR_STATS_DMG_TT] += dmg;
		if (g_bDebugMode) server_print("[HNS_STATS] Player %n add damage tt %d", id, g_StatsRound[id][PLR_STATS_DMG_TT]);
	} else {
		g_StatsRound[id][PLR_STATS_DMG_CT] += dmg;
		if (g_bDebugMode) server_print("[HNS_STATS] Player %n add damage ct %d", id, g_StatsRound[id][PLR_STATS_DMG_CT]);
	}

	return HC_CONTINUE;
}

public PlayerBlind(const index, const inflictor, const attacker, const Float:fadeTime, const Float:fadeHold, const alpha) {
	g_StatsRound[attacker][PLR_STATS_FLASHTIME] += fadeHold;
	if (g_bDebugMode) server_print("[HNS_STATS] Player %n add flashtime %f", attacker, g_StatsRound[attacker][PLR_STATS_FLASHTIME]);
}

public rgPlayerPreThink(id) {
	if (hns_get_mode() != MODE_PUBLIC) {
		return HC_CONTINUE;
	}

	static Float:origin[3];
	static Float:velocity[3];
	static Float:last_updated[MAX_PLAYERS + 1];
	static Float:frametime;
	get_entvar(id, var_origin, origin);
	get_entvar(id, var_velocity, velocity);

	frametime = get_gametime() - last_updated[id];
	if (frametime > 1.0) {
		frametime = 1.0;
	}

	if (is_user_alive(id)) {
		if (rg_get_user_team(id) == TEAM_TERRORIST) {
			if (vector_length(velocity) * frametime >= get_distance_f(origin, last_position[id])) {
				velocity[2] = 0.0;
				if (vector_length(velocity) > 125.0) {
					g_StatsRound[id][PLR_STATS_RUNNED] += vector_length(velocity) * frametime;
					g_StatsRound[id][PLR_STATS_RUNTIME] += frametime;
					if (g_StatsRound[id][PLR_STATS_RUNTIME]) {
						g_StatsRound[id][PLR_STATS_AVG_SPEED] = g_StatsRound[id][PLR_STATS_RUNNED] / g_StatsRound[id][PLR_STATS_RUNTIME];
					}
				}
			}

		}
	}

	last_updated[id] = get_gametime();
	xs_vec_copy(origin, last_position[id]);

	return HC_CONTINUE;
}

public rgRoundFreezeEnd() {
	if (hns_get_mode() != MODE_PUBLIC) {
		return HC_CONTINUE;
	}

	set_task(0.25, "taskRoundEvent", .id = TASK_TIMER, .flags = "b");

	return HC_CONTINUE;
}

public rgRestartRound() {
	remove_task(TASK_TIMER);
}

public taskRoundEvent() {
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ech", "TERRORIST");

	for (new i = 0; i < iNum; i++) {
		new id = iPlayers[i];
		if (is_user_alive(id)) {
			g_StatsRound[id][PLR_STATS_SURVTIME] += 0.25;
		}
	}
}

public hns_round_end(iWinTeam) {
	remove_task(TASK_TIMER);

	ExecuteForward(g_hApplyStatsForward, _, iWinTeam);
}

public hns_round_start() {
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ch");

	for (new i = 0; i < iNum; i++) {
		new id = iPlayers[i];
		arrayset(g_StatsRound[id], 0, PLAYER_STATS);
		arrayset(last_position[id], 0, 3);
	
		iLastAttacker[id] = 0;
	}
	
}

public plugin_natives() {
	register_native("hns_get_stats_kills", "native_get_stats_kills");
	register_native("hns_get_stats_deaths", "native_get_stats_deaths");
	register_native("hns_get_stats_assists", "native_get_stats_assists");
	register_native("hns_get_stats_stabs", "native_get_stats_stabs");
	register_native("hns_get_stats_dmgct", "native_get_stats_dmgct");
	register_native("hns_get_stats_dmgtt", "native_get_stats_dmgtt");
	register_native("hns_get_stats_run", "native_get_stats_run");
	register_native("hns_get_stats_flashtime", "native_get_stats_flashtime");
	register_native("hns_get_stats_surv", "native_get_stats_surv");
	register_native("hns_get_stats_ownages", "native_get_stats_ownages");
}

public native_get_stats_kills(amxx, params) {
	enum { id = 1 };
	return g_StatsRound[get_param(id)][PLR_STATS_KILLS];
}

public native_get_stats_deaths(amxx, params) {
	enum { id = 1 };
	return g_StatsRound[get_param(id)][PLR_STATS_DEATHS];
}

public native_get_stats_assists(amxx, params) {
	enum { id = 1 };
	return g_StatsRound[get_param(id)][PLR_STATS_ASSISTS];
}

public native_get_stats_stabs(amxx, params) {
	enum { id = 1 };
	return g_StatsRound[get_param(id)][PLR_STATS_STABS];
}

public native_get_stats_dmgct(amxx, params) {
	enum { id = 1 };
	return g_StatsRound[get_param(id)][PLR_STATS_DMG_CT];
}

public native_get_stats_dmgtt(amxx, params) {
	enum { id = 1 };
	return g_StatsRound[get_param(id)][PLR_STATS_DMG_TT];
}

public Float:native_get_stats_run(amxx, params) {
	enum { id = 1 };
	return g_StatsRound[get_param(id)][PLR_STATS_RUNNED];
}

public Float:native_get_stats_flashtime(amxx, params) {
	enum { id = 1 };
	return g_StatsRound[get_param(id)][PLR_STATS_FLASHTIME];
}

public Float:native_get_stats_surv(amxx, params) {
	enum { id = 1 };
	return g_StatsRound[get_param(id)][PLR_STATS_SURVTIME];
}

public native_get_stats_ownages(amxx, params) {
	enum { id = 1 };
	return g_StatsRound[get_param(id)][PLR_STATS_OWNAGES];
}
