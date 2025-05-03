#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>

#define rg_get_user_team(%0) get_member(%0, m_iTeam)

native hns_specback_init();

enum _:HNS_MODES {
	MODE_PUBLIC = 0,
	MODE_DEATHMATCH
}

new g_iCurrentMode;

enum HNS_CVAR {
	c_iDeathMatch,
	c_iDmRespawn,
	c_iHe,
	c_iFlash,
	c_iSmoke,
	c_iSwapTeams,
	c_iSwist,
	c_szPrefix[24],
	Float:c_flRoundTime
}

new g_pCvar[HNS_CVAR];
new _:g_iSettings[HNS_CVAR];

new g_pRoundTime;

new g_iRegisterSpawn;

new const g_szDenyselect[] = "common/wpn_denyselect.wav";
new const g_szUseSound[] = "buttons/blip1.wav";
new const g_szUseSwist[] = "openhns/swist.wav";

new const g_szDefaultEntities[][] = {
	"func_hostage_rescue",
	"func_bomb_target",
	"info_bomb_target",
	"hostage_entity",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone",
	"armoury_entity",
	"monster_scentist"
}

enum _: Forwards_s {
	hns_round_start,
	hns_team_swap,
	hns_round_end
};

new g_hForwards[Forwards_s];

public plugin_init() {
	register_plugin("HNS Mode Main", "1.0.4.3", "OpenHNS");

	register_clcmd("chooseteam", "BlockTeamMenu");
	register_clcmd("jointeam", "BlockCmd");
	register_clcmd("joinclass", "BlockCmd");

	g_pCvar[c_iDeathMatch] = create_cvar("hns_deathmatch", "0", FCVAR_NONE, "Deathmatch mod `1` Enable / `0` Disable", true, 0.0, true, 1.0);
	bind_pcvar_num(g_pCvar[c_iDeathMatch], g_iSettings[c_iDeathMatch]);

	g_pCvar[c_iDmRespawn] = create_cvar("hns_respawn", "3", FCVAR_NONE, "Number of seconds to revive players in DM mode", true, 0.0, true, 20.0);
	bind_pcvar_num(g_pCvar[c_iDmRespawn], g_iSettings[c_iDmRespawn]);
	
	g_pCvar[c_iHe] = create_cvar("hns_he", "0", FCVAR_NONE, "He number of grenades on TT team", true, 0.0, true, 10.0);
	bind_pcvar_num(g_pCvar[c_iHe], g_iSettings[c_iHe]);
	
	g_pCvar[c_iFlash] = create_cvar("hns_flash", "2", FCVAR_NONE, "Flash number of grenades on TT team", true, 0.0, true, 10.0);
	bind_pcvar_num(g_pCvar[c_iFlash], g_iSettings[c_iFlash]);
	
	g_pCvar[c_iSmoke] = create_cvar("hns_smoke", "1", FCVAR_NONE, "Smoke number of grenades on TT team", true, 0.0, true, 10.0);
	bind_pcvar_num(g_pCvar[c_iSmoke], g_iSettings[c_iSmoke]);
	
	g_pCvar[c_iSwapTeams] = create_cvar("hns_swap_team", "2", FCVAR_NONE, "Number of consecutive rounds won by the TT team after which to swap teams", true, 0.0, true, 10.0);
	bind_pcvar_num(g_pCvar[c_iSwapTeams], g_iSettings[c_iSwapTeams]);
	
	g_pCvar[c_iSwist] = create_cvar("hns_swist", "1", FCVAR_NONE, "whistle (+USE) on TT team `1` Enable / `0` Disable", true, 0.0, true, 1.0);
	bind_pcvar_num(g_pCvar[c_iSwist], g_iSettings[c_iSwist]);
	
	g_pCvar[c_szPrefix] = create_cvar("hns_prefix", "Match", FCVAR_NONE, "System prefix");
	bind_pcvar_string(g_pCvar[c_szPrefix], g_iSettings[c_szPrefix], charsmax(g_iSettings[c_szPrefix]));
	
	g_pCvar[c_flRoundTime] = _:create_cvar("hns_roundtime", "2.5", FCVAR_NONE, "Public roundtime", true, 0.0, true, 99.0);
	bind_pcvar_float(_:g_pCvar[c_flRoundTime], g_iSettings[c_flRoundTime]);

	g_pRoundTime = get_cvar_pointer("mp_roundtime");
	g_pCvar[c_flRoundTime] = _:get_pcvar_float(_:g_pRoundTime);

	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "rgFreezeEnd", true);
	RegisterHookChain(RG_CSGameRules_RestartRound, "rgRoundStart", true);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "rgPlayerResetMaxSpeed", true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "rgPlayerSpawn", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "rgPlayerKilled", true);
	RegisterHookChain(RG_PlayerBlind, "rgPlayerBlind");
	RegisterHookChain(RG_RoundEnd, "rgRoundEnd");
	RegisterHookChain(RH_Cvar_DirectSet, "RHCvarDirectSet");
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "hamKnifePrim");
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "hamDeployKnife", true);

	register_forward(FM_EmitSound, "fwdEmitSound");
	register_forward(FM_ClientKill, "fwdClientKill");

	unregister_forward(FM_Spawn, g_iRegisterSpawn, 1);

	//set_msg_block(get_user_msgid("SendAudio"), BLOCK_SET);
	set_msg_block(get_user_msgid("TextMsg"), BLOCK_SET);
	set_msg_block(get_user_msgid("HudTextArgs"), BLOCK_SET);
	set_msg_block(get_user_msgid("Money"), BLOCK_SET);

	set_task(0.5, "delayed_mode");

	g_hForwards[hns_round_start] = CreateMultiForward("hns_round_start", ET_CONTINUE);
	g_hForwards[hns_team_swap] = CreateMultiForward("hns_team_swap", ET_CONTINUE);
	g_hForwards[hns_round_end] = CreateMultiForward("hns_round_end", ET_CONTINUE);

	register_dictionary("hidenseek.txt");
}

public plugin_cfg() {
	new szPath[PLATFORM_MAX_PATH];
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	format(szPath, charsmax(szPath), "%s/%s", szPath, "hns_mode.cfg");
	server_cmd("exec %s", szPath);
}

public plugin_precache() {
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"));

	precache_sound(g_szUseSound);
	precache_sound(g_szUseSwist);

	new g_iHostageEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"));
	set_pev(g_iHostageEnt, pev_origin, Float:{ 0.0, 0.0, -55000.0 });
	set_pev(g_iHostageEnt, pev_size, Float:{ -1.0, -1.0, -1.0 }, Float:{ 1.0, 1.0, 1.0 });
	dllfunc(DLLFunc_Spawn, g_iHostageEnt);

	g_iRegisterSpawn = register_forward(FM_Spawn, "fwdSpawn", 1);
}

public plugin_natives() {
	register_native("hns_get_prefix", "native_get_prefix");
	
	register_native("hns_get_mode", "native_get_mode");
	register_native("hns_set_mode", "native_set_mode");

	set_native_filter("native_filter");
}

public native_get_prefix(amxx, params) {
	enum {
		arg_prefix = 1, arg_len
	};
	set_string(arg_prefix, g_iSettings[c_szPrefix], get_param(arg_len));
}

public native_get_mode(amxx, params) {
	return g_iCurrentMode;
}

public native_set_mode(amxx, params) {
	enum { argMode = 1 };
	hns_set_mode(get_param(argMode));
}

public native_filter(const szNativeName[], iNativeID, iTrapMode) {
	if (equal(szNativeName, "hns_specback_init")) { 
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE;
}

public delayed_mode() {
	set_cvar_num("mp_auto_join_team", 1);
	set_cvar_num("mp_forcechasecam", 0);
	set_cvar_num("mp_forcecamera", 0);
	set_cvar_num("mp_autoteambalance", 2);
	set_cvar_num("sv_alltalk", 1);
	set_cvar_num("mp_buytime", 0);
	set_cvar_num("mp_roundover", 2);
	set_cvar_num("mp_give_player_c4", 0);
	set_cvar_string("mp_t_default_weapons_secondary", "");
	set_cvar_string("mp_ct_default_weapons_secondary", "");

	if (g_iSettings[c_iDeathMatch]) {
		hns_set_mode(MODE_DEATHMATCH);
	} else {
		hns_set_mode(MODE_PUBLIC);
	}
}

public BlockTeamMenu(id) {
	if (hns_specback_init()) {
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_HANDLED;
}

public BlockCmd(id) {
	return PLUGIN_HANDLED;
}

public rgFreezeEnd() {
	set_dhudmessage(0, 250, 0, -1.0, 0.2, .holdtime = 4.0);
  	show_dhudmessage(0, "%L", LANG_PLAYER, "MAIN_FREEZE_END");
}

public rgRoundStart() {
	set_task(1.0, "taskDestroyBreakables");
	ExecuteForward(g_hForwards[hns_round_start]);
}

public rgPlayerResetMaxSpeed(id) {
	if (get_member_game(m_bFreezePeriod)) {
		if (rg_get_user_team(id) == TEAM_TERRORIST) {
			set_entvar(id, var_maxspeed, 250.0);
			return HC_SUPERCEDE;
		}
	}
	return HC_CONTINUE;
}

public rgPlayerSpawn(id) {
	setUserRole(id);

	if (g_iCurrentMode == MODE_DEATHMATCH)
		checkBalanceTeams();
}

public checkBalanceTeams() {
	new iPlayers[MAX_PLAYERS], iCTNum, iTTNum
	get_players(iPlayers, iCTNum, "che", "CT");
	get_players(iPlayers, iTTNum, "che", "TERRORIST");

	if (abs(iCTNum - iTTNum) < 2)
		return PLUGIN_HANDLED;

	if (iCTNum > iTTNum) {
		new iPlayer = getRandomAlivePlayer(TEAM_CT);
		if (iPlayer) {
			rg_set_user_team(iPlayer, TEAM_TERRORIST);
			setUserRole(iPlayer);
			client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "MAIN_TRANSFER_CT", g_iSettings[c_szPrefix], iPlayer);
		}
	} else {
		new iPlayer = getRandomAlivePlayer(TEAM_TERRORIST);
		if (iPlayer) {
			rg_set_user_team(iPlayer, TEAM_CT);
			setUserRole(iPlayer);

			client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "MAIN_TRANSFER_TT", g_iSettings[c_szPrefix], iPlayer);
		}
	}

	return PLUGIN_HANDLED;
}

public rgPlayerKilled(victim, attacker) {
	if (g_iCurrentMode != MODE_DEATHMATCH)
		return HC_CONTINUE;

	if (attacker == 0 || !is_user_connected(attacker)) {
		if (rg_get_user_team(victim) == TEAM_TERRORIST) {
			new iLucky = getRandomAlivePlayer(TEAM_CT);
			if (iLucky) {
				rg_set_user_team(iLucky, TEAM_TERRORIST);
				client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "MAIN_TRANSFER_TT", g_iSettings[c_szPrefix], iLucky)
				rg_set_user_team(victim, TEAM_CT);
				setUserRole(iLucky);
			}
		}
	} else if (attacker != victim && rg_get_user_team(attacker) == TEAM_CT) {
		rg_set_user_team(attacker, TEAM_TERRORIST);
		rg_set_user_team(victim, TEAM_CT);

		setUserRole(attacker);
	}

	set_task(float(g_iSettings[c_iDmRespawn]), "taskRespawnPlayer", victim);

	return HC_CONTINUE;
}

public taskRespawnPlayer(id) {
	if (!is_user_connected(id))
		return;

	if (rg_get_user_team(id) != TEAM_SPECTATOR)
		rg_round_respawn(id);
}

public taskDestroyBreakables() {
	new iEntity = -1;
	while ((iEntity = rg_find_ent_by_class(iEntity, "func_breakable" ))) {
		if(get_entvar(iEntity, var_takedamage)) {
			set_entvar(iEntity, var_origin, Float:{10000.0, 10000.0, 10000.0})
		}
	}
}


public rgPlayerBlind(id) {
	if (rg_get_user_team(id) == TEAM_TERRORIST || rg_get_user_team(id) == TEAM_SPECTATOR)
		return HC_SUPERCEDE;

	return HC_CONTINUE;
}

public rgRoundEnd(WinStatus: status, ScenarioEventEndRound: event, Float:tmDelay) {
	new g_Roundtime = get_cvar_pointer("mp_roundtime");

	set_pcvar_float(_:g_Roundtime, Float:g_iSettings[c_flRoundTime]);

	if (event == ROUND_TARGET_SAVED || event == ROUND_HOSTAGE_NOT_RESCUED) {
		SetHookChainArg(1, ATYPE_INTEGER, WINSTATUS_TERRORISTS);
		SetHookChainArg(2, ATYPE_INTEGER, ROUND_TERRORISTS_ESCAPED);
	}

	if (event == ROUND_GAME_COMMENCE) {
		set_member_game(m_bGameStarted, true);
		SetHookChainReturn(ATYPE_BOOL, false);
		return HC_SUPERCEDE;
	}

	if (status == WINSTATUS_DRAW && event == ROUND_END_DRAW) {
		return HC_CONTINUE;
	}

	static iWinsTT;

	if (status == WINSTATUS_CTS) {
		rg_swap_all_players();
		ExecuteForward(g_hForwards[hns_team_swap]);
		iWinsTT = 0;
		
		set_dhudmessage(0, 0, 255, -1.0, 0.2, .holdtime = 4.0);
  		show_dhudmessage(0, "%L", LANG_PLAYER, "MAIN_WIN_CTS");
	} else if (status == WINSTATUS_TERRORISTS) {
		new iPlayers[MAX_PLAYERS], iCTNum, iTTNum
		get_players(iPlayers, iCTNum, "che", "CT");
		get_players(iPlayers, iTTNum, "che", "TERRORIST");

		if (iCTNum + iTTNum > 2)
			iWinsTT++;

		set_dhudmessage(250, 0, 0, -1.0, 0.2, .holdtime = 4.0);
  		show_dhudmessage(0, "%L", LANG_PLAYER, "MAIN_WIN_TERRORISTS");
	}

	if (g_iSettings[c_iSwapTeams]) {
		if (iWinsTT >= g_iSettings[c_iSwapTeams]) {
			client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "MAIN_SWAP", g_iSettings[c_szPrefix], g_iSettings[c_iSwapTeams]);
			rg_swap_all_players();
			ExecuteForward(g_hForwards[hns_team_swap]);
			iWinsTT = 0;
		}
	}

	ExecuteForward(g_hForwards[hns_round_end]);

	return HC_CONTINUE;
}

public RHCvarDirectSet(pcvar, const value[]) {
	if (pcvar != g_pCvar[c_iDeathMatch]) {
		return HC_CONTINUE;
	}

	if (str_to_num(value)) {
		hns_set_mode(MODE_DEATHMATCH);
		client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "MAIN_RUN_DEATHMATCH", g_iSettings[c_szPrefix]);
	} else {
		hns_set_mode(MODE_PUBLIC);
		client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "MAIN_RUN_PUBLIC", g_iSettings[c_szPrefix]);
	}

	return HC_CONTINUE;
}

public hamKnifePrim(iPlayer) {
	ExecuteHamB(Ham_Weapon_SecondaryAttack, iPlayer)
	return HAM_SUPERCEDE
}

public hamDeployKnife(ent) {
	new id = get_member(ent, m_pPlayer);

	if(rg_get_user_team(id) == TEAM_TERRORIST) {
		set_member(ent, m_Weapon_flNextPrimaryAttack, 9999.0);
		set_member(ent, m_Weapon_flNextSecondaryAttack, 9999.0);
	}
	return HAM_IGNORED;
}

public fwdEmitSound(id, iChannel, szSample[], Float:volume, Float:attenuation, fFlags, pitch) {
	if(equal(szSample, "weapons/knife_deploy1.wav"))
		return FMRES_SUPERCEDE;

	if (is_user_alive(id) && rg_get_user_team(id) == TEAM_TERRORIST && equal(szSample, g_szDenyselect)) {
		if (!g_iSettings[c_iSwist]) {
			emit_sound(id, iChannel, g_szUseSound, volume, attenuation, fFlags, pitch);
			return FMRES_SUPERCEDE;
		}

		static Float:flNextTime[MAX_PLAYERS + 1];
		new Float:flGameTime = get_gametime();

		if(flNextTime[id] >= flGameTime) {
			emit_sound(id, iChannel, g_szUseSound, volume, attenuation, fFlags, pitch);
		} else {
			emit_sound(id, iChannel, g_szUseSwist, volume, attenuation, fFlags, pitch);
			client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "MAIN_SWIST", g_iSettings[c_szPrefix], id);
			flNextTime[id] = get_gametime() + 20.0;
		}

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

public fwdClientKill(id) {
	if (g_iCurrentMode == MODE_DEATHMATCH) {
		client_print_color(id, print_team_blue, "%L", id, "MAIN_KILL_NOT", g_iSettings[c_szPrefix]);
		return FMRES_SUPERCEDE;
	} else if (rg_get_remaining_time() > 60.0) {
		client_print_color(id, print_team_blue, "%L", id, "MAIN_KILL_WAIT", g_iSettings[c_szPrefix]);
		return FMRES_SUPERCEDE;
	} else {
		client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "MAIN_KILL", g_iSettings[c_szPrefix], id);
	}
	return FMRES_IGNORED;
}

public fwdSpawn(entid) {
	static szClassName[32];
	if (pev_valid(entid)) {
		pev(entid, pev_classname, szClassName, 31);
		if (equal(szClassName, "func_buyzone")) engfunc(EngFunc_RemoveEntity, entid);

		for (new i = 0; i < sizeof g_szDefaultEntities; i++) {
			if (equal(szClassName, g_szDefaultEntities[i])) {
				engfunc(EngFunc_RemoveEntity, entid);
				break;
			}
		}
	}
}

stock setUserRole(id) {
	if (!is_user_alive(id))
		return PLUGIN_HANDLED;

	rg_remove_all_items(id);
	switch (rg_get_user_team(id)) {
		case TEAM_TERRORIST: {
			rg_set_user_footsteps(id, true);
			rg_give_item(id, "weapon_knife");

			if (g_iSettings[c_iHe]) {
				rg_give_item(id, "weapon_hegrenade");
				rg_set_user_bpammo(id, WEAPON_HEGRENADE, g_iSettings[c_iHe]);
			}

			if (g_iSettings[c_iFlash]) {
				rg_give_item(id, "weapon_flashbang");
				rg_set_user_bpammo(id, WEAPON_FLASHBANG, g_iSettings[c_iFlash]);
			}

			if (g_iSettings[c_iSmoke]) {
				rg_give_item(id, "weapon_smokegrenade");
				rg_set_user_bpammo(id, WEAPON_SMOKEGRENADE, g_iSettings[c_iSmoke]);
			}
		}
		case TEAM_CT: {
			rg_set_user_footsteps(id, false);
			rg_give_item(id, "weapon_knife");
		}
	}

	return PLUGIN_HANDLED;
}

// Albertio
stock Float:rg_get_remaining_time() {
	return (float(get_member_game(m_iRoundTimeSecs)) - get_gametime() + Float:get_member_game(m_fRoundStartTimeReal));
}

public hns_set_mode(iCurrentMode) {
	g_iCurrentMode = iCurrentMode;

	new g_Roundtime = get_cvar_pointer("mp_roundtime");

	switch (g_iCurrentMode) {
		case MODE_DEATHMATCH: {
			set_cvar_num("mp_freezetime", 0);
			set_cvar_num("hns_roundtime", 0);
			set_pcvar_float(_:g_Roundtime, 0.0);
			set_cvar_num("mp_roundrespawn_time", -1);
			set_cvar_num("mp_round_infinite", 1);
		}
		case MODE_PUBLIC: {
			set_cvar_num("mp_freezetime", 5);
			set_pcvar_float(_:g_Roundtime, Float:g_iSettings[c_flRoundTime]);
			set_cvar_num("mp_roundrespawn_time", 20);
			set_cvar_num("mp_round_infinite", 0);
		}
	}

	set_cvar_num("sv_restart", 1);
}

stock getRandomAlivePlayer(TeamName:iTeam) {
	new iPlayers[MAX_PLAYERS], iNum

	switch (iTeam) {
		case TEAM_TERRORIST: {
			get_players(iPlayers, iNum, "ahe", "TERRORIST");
		}
		case TEAM_CT: {
			get_players(iPlayers, iNum, "ahe", "CT");
		}
		case TEAM_SPECTATOR: {
			get_players(iPlayers, iNum, "ahe", "SPECTATOR");
		}
	}

	if(!iNum)
		return 0

	return iNum > 1 ? iPlayers[random(iNum)] : iPlayers[iNum - 1];
}
