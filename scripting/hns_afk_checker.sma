#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <xs>
#include <time>

#define TASKID_RESET_SKIP 1337
#define TASKID_DELAY_TRANSFER 1338

// Support for ECD Helper. Comment to disable.
//
// Поддержка плагина ECD Helper. Закомментировать для отключения.
//#define ECD_HELPER_SUPPORT

#define CheckBit(%0,%1) (%0 & (1 << %1))
#define SetBit(%0,%1) (%0 |= (1 << %1))
#define ClearBit(%0,%1) (%0 &= ~(1 << %1))

#define IsInGame(%0) (TEAM_SPECTATOR > get_member(%0, m_iTeam) > TEAM_UNASSIGNED)

stock const SOUND_TUTOR_MSG[] = "sound/events/tutor_msg.wav"


#if defined ECD_HELPER_SUPPORT
	/**
	 * Вернет 1 если игрок проходит сканирование на данный момент
	 * Используйте этот натив в плагинах AFK, чтобы добавить проверку, и не кикать игроков
	 *
	 * @param player				player
	 * @return						1 or 0
	 */
	native ecd_is_scanning(player);
#endif

enum _:CVAR_ENUM {
	Float:CVAR_F_CHECK_INTERVAL,
	Float:CVAR_F_WARN_TIME,
	CVAR_WARN_TO_WARN,
	CVAR_MAX_WARNS,
	CVAR_MAX_KILLED_WARNS,
	Float:CVAR_F_MAXSPEED
}

new g_eCvar[CVAR_ENUM]
new g_pCvar[CVAR_ENUM]
new g_iTimerWarns[MAX_PLAYERS + 1], g_iKilledWarns[MAX_PLAYERS + 1], g_bitPlToSkip, bool:g_bOnGround[MAX_PLAYERS + 1]
new g_iSpawnOrigin[MAX_PLAYERS + 1][3]

public plugin_init() {
	register_plugin("HNS: AFK Control", "DEV", "OpenHNS") // Fork mx?! plugin afk control
	register_dictionary("afk_control.txt")

	g_pCvar[CVAR_F_CHECK_INTERVAL] = create_cvar("afk_time_check", "10", FCVAR_NONE, "Interval between checks (in seconds)", true, 1.0)
	bind_pcvar_float(g_pCvar[CVAR_F_CHECK_INTERVAL], g_eCvar[CVAR_F_CHECK_INTERVAL])

	g_pCvar[CVAR_F_WARN_TIME] = create_cvar("afk_warn_time", "10", FCVAR_NONE, "If the player does not move # seconds, this counts as AFK", true, 1.0)
	bind_pcvar_float(g_pCvar[CVAR_F_WARN_TIME], g_eCvar[CVAR_F_WARN_TIME])

	g_pCvar[CVAR_WARN_TO_WARN] = create_cvar("afk_warn_to_warn", "2", FCVAR_NONE, "On which # AFK warning should we notify about punishment? (0 - disable)", true, 0.0)
	bind_pcvar_num(g_pCvar[CVAR_WARN_TO_WARN], g_eCvar[CVAR_WARN_TO_WARN])

	g_pCvar[CVAR_MAX_WARNS] = create_cvar("afk_max_warns", "3", FCVAR_NONE, "After how many timer warnings player will be moved to spectators", true, 0.0)
	bind_pcvar_num(g_pCvar[CVAR_MAX_WARNS], g_eCvar[CVAR_MAX_WARNS])

	g_pCvar[CVAR_MAX_KILLED_WARNS] = create_cvar("afk_max_killed_warns", "3", FCVAR_NONE, "How many deaths at spawn are required to punish for AFK (0 - off)", true, 0.0)
	bind_pcvar_num(g_pCvar[CVAR_MAX_KILLED_WARNS], g_eCvar[CVAR_MAX_KILLED_WARNS])

	bind_pcvar_float(get_cvar_pointer("sv_maxspeed"), g_eCvar[CVAR_F_MAXSPEED])
	
	RegisterHookChain(RG_CBasePlayer_GetIntoGame, "CBasePlayer_GetIntoGame_Post", true)
	RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn_Pre", true)
	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Pre")

	set_task(3.5, "func_SetTask")
}

public func_SetTask() {
	set_task(g_eCvar[CVAR_F_CHECK_INTERVAL], "task_Check")
}

public task_Check() {
	func_SetTask()

	new iAliveTT, iAliveCT, iDeadTT, iDeadCT
	rg_initialize_player_counts(iAliveTT, iAliveCT, iDeadTT, iDeadCT)
	new iInGame = iAliveTT + iAliveCT + iDeadTT + iDeadCT

	new pPlayers[MAX_PLAYERS], iPlCount
	get_players(pPlayers, iPlCount)

	if(iInGame > 1) {
		CheckAllAlivePlayersForAfk(pPlayers, iPlCount)
	}
}

CheckAllAlivePlayersForAfk(const pPlayers[MAX_PLAYERS], iPlCount) {
	if(g_eCvar[CVAR_F_MAXSPEED] <= 2.0) {
		return
	}

	new Float:fGameTime = get_gametime()

	for(new i; i < iPlCount; i++) {
		CheckPlayerForAfk(pPlayers[i], fGameTime)
	}
}

bool:CheckPlayerForAfk(pPlayer, Float:fGameTime) {
	if(!is_user_alive(pPlayer) || is_user_bot(pPlayer) || CheckBit(g_bitPlToSkip, pPlayer)) {
		return false
	}

	if(!IsPlayerAfk(pPlayer, fGameTime, true)) {
		g_iTimerWarns[pPlayer] = 0
		return false
	}

	g_iTimerWarns[pPlayer]++

	if(g_eCvar[CVAR_WARN_TO_WARN] && g_iTimerWarns[pPlayer] == min(g_eCvar[CVAR_WARN_TO_WARN], g_eCvar[CVAR_MAX_WARNS] - 1)) {
		rg_send_audio(pPlayer, SOUND_TUTOR_MSG)
		client_print(pPlayer, print_center, "%l", "AFK_WARN_CENTER")
		client_print_color(pPlayer, print_team_red, "%l", "AFK_WARN_CHAT")
		return false
	}

	if(g_iTimerWarns[pPlayer] >= g_eCvar[CVAR_MAX_WARNS]) {
		func_PunishForAFK(pPlayer)
		return false
	}

	return false
}

bool:IsPlayerAfk(pPlayer, Float:fGameTime, bool:bWriteOldAngle) {
	static Float:fOldViewAngle[MAX_PLAYERS + 1][3]

	static Float:fViewAngle[3], bool:bSameAngle
	get_entvar(pPlayer, var_v_angle, fViewAngle)

	// https://github.com/s1lentq/ReGameDLL_CS/blob/a20362389e7fe5e3fdd1a6befcc854e1f6c8caff/regamedll/dlls/API/CSPlayer.cpp#L521
	bSameAngle = (floatabs(fOldViewAngle[pPlayer][1] - fViewAngle[1]) < 0.1)

	if(bWriteOldAngle) {
		xs_vec_copy(fViewAngle, fOldViewAngle[pPlayer])
	}

	return (
		bSameAngle
			&&
		fGameTime - Float:get_member(pPlayer, m_fLastMovement) >= g_eCvar[CVAR_F_WARN_TIME]
			&&
		Float:get_entvar(pPlayer, var_maxspeed) > 2.0
	);
}

public CBasePlayer_GetIntoGame_Post(pPlayer) {
	g_iTimerWarns[pPlayer] = 0
	g_iKilledWarns[pPlayer] = 0
}

public CBasePlayer_Spawn_Pre(pPlayer) {
	g_bOnGround[pPlayer] = false
	remove_task(pPlayer)
	set_task(0.1, "task_GetOrigin", pPlayer, .flags = "b")
}

public task_GetOrigin(pPlayer) {
	if(!is_user_alive(pPlayer)) {
		remove_task(pPlayer)
		return
	}

	if( !(get_entvar(pPlayer, var_flags) & FL_ONGROUND) ) {
		return
	}

	g_bOnGround[pPlayer] = true
	remove_task(pPlayer)
	get_user_origin(pPlayer, g_iSpawnOrigin[pPlayer], Origin_Client)
}

public CBasePlayer_Killed_Pre(pVictim, pKiller, iGibType) {
	if(!g_eCvar[CVAR_MAX_KILLED_WARNS] || is_user_bot(pVictim) || !g_bOnGround[pVictim] || CheckBit(g_bitPlToSkip, pVictim)) {
		return
	}

	new iOrigin[3]
	get_user_origin(pVictim, iOrigin, Origin_Client)

	if(
		IsIntCoordsNearlyEqual(iOrigin[0], g_iSpawnOrigin[pVictim][0])
			&&
		IsIntCoordsNearlyEqual(iOrigin[1], g_iSpawnOrigin[pVictim][1])
			&&
		IsIntCoordsNearlyEqual(iOrigin[2], g_iSpawnOrigin[pVictim][2])
	) {
		if(++g_iKilledWarns[pVictim] >= g_eCvar[CVAR_MAX_KILLED_WARNS]) {
			remove_task(pVictim + TASKID_RESET_SKIP)
			SetBit(g_bitPlToSkip, pVictim)
			set_task(0.1, "task_DelayTransfer", TASKID_DELAY_TRANSFER + get_user_userid(pVictim))
		}

		return
	}

	g_iKilledWarns[pVictim] = 0
}

stock bool:IsIntCoordsNearlyEqual(iCoord1, iCoord2) {
	const FLEQ_TOLERANCE = 10

	return xs_abs(iCoord1 - iCoord2) <= FLEQ_TOLERANCE

	/*if(iCoord1 == iCoord2) {
		return true
	}

	if(iCoord1 > iCoord2) {
		return _abs(iCoord1 - iCoord2) <= FLEQ_TOLERANCE
	}

	//if iCoord1 < iCoord2
	return _abs(iCoord2 - iCoord1) <= FLEQ_TOLERANCE*/
}

public task_DelayTransfer(iUserId) {
	new pPlayer = find_player("k", iUserId - TASKID_DELAY_TRANSFER)

	if(pPlayer) {
		ClearBit(g_bitPlToSkip, pPlayer)
		func_PunishForAFK(pPlayer)
	}
}

SetSkip(pPlayer) {
	remove_task(pPlayer + TASKID_RESET_SKIP)
	SetBit(g_bitPlToSkip, pPlayer)
	set_task(0.1, "ResetSkip", pPlayer + TASKID_RESET_SKIP)
}

public ResetSkip(pPlayer) {
	pPlayer -= TASKID_RESET_SKIP;
	ClearBit(g_bitPlToSkip, pPlayer)
}

bool:func_PunishForAFK(pPlayer) {
	if(IsInGame(pPlayer)) {
		func_MoveToSpec(pPlayer)
	}

	return false
}

func_MoveToSpec(pPlayer) {
	g_iTimerWarns[pPlayer] = 0
	g_iKilledWarns[pPlayer] = 0

	SetSkip(pPlayer)

	client_print_color(0, pPlayer, "%L", LANG_PLAYER, "AFK_TRANSFER_TO_SPEC_INFO", pPlayer)

	if(is_user_alive(pPlayer)) {
		new Float:fFrags = get_entvar(pPlayer, var_frags)
		new iDeaths = get_member(pPlayer, m_iDeaths)
		user_kill(pPlayer, 0)
		set_member(pPlayer, m_iDeaths, iDeaths)
		set_entvar(pPlayer, var_frags, fFrags)
	}

	if(get_member(pPlayer,m_iMenu) == Menu_ChooseAppearance) {
		rg_internal_cmd(pPlayer, "joinclass", "5")
	}

	set_member(pPlayer, m_bTeamChanged, false)
	rg_internal_cmd(pPlayer, "jointeam", "6")
	set_member(pPlayer, m_bTeamChanged, false)
	amxclient_cmd(pPlayer, "chooseteam")
}

public client_putinserver(pPlayer) {}
