#include <amxmodx>
#include <hamsandwich>
#include <reapi>

enum CVARS {
	c_iEnableBFITH,
	c_iEnableBCMDP,
	c_iColorFlash[16],
	c_iEnableSAG,
}

new g_eCvar[CVARS];
new _:g_iSettings[CVARS];

enum rgb { Float:red, Float:green, Float:blue };
new Float:g_eFlashColor[rgb];

public plugin_cfg() {
	set_cvar_num("mp_give_player_c4", 0);
	set_cvar_num("mp_buytime", 0);
	set_cvar_num("mp_maxmoney", 0);
	set_cvar_num("mp_ammodrop", 0);
	set_cvar_num("mp_auto_reload_weapons", 0);
	set_cvar_num("mp_refill_bpammo_weapons", 0);
	set_cvar_num("mp_max_teamkills", 0);
	set_cvar_num("mp_hostage_hurtable", 0);
	set_cvar_num("mp_show_scenarioicon", 0);
	set_cvar_num("mp_scoreboard_showhealth", 3);
	set_cvar_num("mp_scoreboard_showmoney", 0);
	set_cvar_num("mp_scoreboard_showdefkit", 0);
	set_cvar_num("mp_afk_bomb_drop_time", 0);
	set_cvar_num("mp_t_give_player_knife", 1);
	set_cvar_num("mp_ct_give_player_knife", 1);
	set_cvar_num("mp_deathmsg_flags", 0);
	set_cvar_num("mp_hullbounds_sets", 0);
	set_cvar_string("mp_ct_default_weapons_secondary", "");
	set_cvar_string("mp_t_default_weapons_secondary", "");
}

public plugin_init() {
	register_plugin ("HNS: Additons for mode", "1.2", "OpenHNS");

	//TODO: Добавить квары в семейство мода

	g_eCvar[c_iEnableBFITH] = create_cvar("hns_enable_block_fith", "1", FCVAR_NONE, "Enable block 'Fire in the hole!'", true, 0.0, true, 1.0);
	bind_pcvar_num(g_eCvar[c_iEnableBFITH], g_iSettings[c_iEnableBFITH]);

	g_eCvar[c_iEnableBCMDP] = create_cvar("hns_enable_block_cmdp", "1", FCVAR_NONE, "Enable block command process", true, 0.0, true, 1.0);
	bind_pcvar_num(g_eCvar[c_iEnableBCMDP], g_iSettings[c_iEnableBCMDP]);

	g_eCvar[c_iColorFlash] = create_cvar("hns_color_flash_rgb", "120 120 120", FCVAR_NONE, "Colored Flash");
	bind_pcvar_string(g_eCvar[c_iColorFlash], g_iSettings[c_iColorFlash], charsmax(g_iSettings[c_iColorFlash]));

	g_eCvar[c_iEnableSAG] = create_cvar("hns_sec_attack_grenade", "1", FCVAR_NONE, "Enable secondary attack grenade", true, 0.0, true, 1.0);
	bind_pcvar_num(g_eCvar[c_iEnableSAG], g_iSettings[c_iEnableSAG]);

	new szRed[4], szGreen[4], szBlue[4];
	parse(g_iSettings[c_iColorFlash], szRed, charsmax(szRed), szGreen, charsmax(szGreen), szBlue, charsmax(szBlue));
	g_eFlashColor[red]   = str_to_float(szRed);
	g_eFlashColor[green] = str_to_float(szGreen);
	g_eFlashColor[blue]  = str_to_float(szBlue);

	RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_smokegrenade", "Weapon_SecondaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_flashbang", "Weapon_SecondaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_hegrenade", "Weapon_SecondaryAttack_Pre", false );

	RegisterHookChain(RG_CBasePlayer_ThrowGrenade, "CBasePlayer_ThrowGrenade_Post", true);
	RegisterHookChain(RG_CBasePlayer_Radio, "rgBasePlayerRadio", .post = false);
	RegisterHookChain(RG_PlayerBlind, "rgPlayerBlind");

	register_clcmd("vote",			"cmdBlock");
	register_clcmd("votekick",		"cmdBlock");
	register_clcmd("voteban",		"cmdBlock");
	register_clcmd("rcon",			"cmdBlock");
	register_clcmd("amx_voteban",	"cmdBlock");
	register_clcmd("amx_votekick",	"cmdBlock");
	register_clcmd("amx_votemap",	"cmdBlock");
	register_clcmd("amx_pause",		"cmdBlock");
	register_clcmd("rcon_password", "cmdBlock");
}

public Weapon_SecondaryAttack_Pre( weapon ) {
	if (!g_iSettings[c_iEnableSAG]) {
		return HAM_IGNORED;
	}

	if (get_member(weapon, m_flStartThrow) > 0.0) {
		return HAM_IGNORED;
	}

	new player = get_member(weapon, m_pPlayer);
	
	if (get_member(player, m_bOwnsShield)) {
		return HAM_IGNORED;
	}

	if (get_member(player, m_rgAmmo, get_member(weapon, m_Weapon_iPrimaryAmmoType)) <= 0) {
		return HAM_IGNORED;
	}
	
	set_member(weapon, m_Weapon_iFamasShotsFired, 1);

	ExecuteHam( Ham_Weapon_PrimaryAttack, weapon );
	
	return HAM_IGNORED;
}

public CBasePlayer_ThrowGrenade_Post(const player, const weapon, const Float:vecSrc[3], const Float:vecThrow[3]) {
	if (!g_iSettings[c_iEnableSAG]) {
		return HAM_IGNORED;
	}

	if (!get_member(weapon, m_Weapon_iFamasShotsFired)) {
		return HC_CONTINUE;
	}

	set_member(weapon, m_Weapon_iFamasShotsFired, 0);

	new grenade = GetHookChainReturn(ATYPE_INTEGER);
	
	if (is_nullent(grenade)) {
		return HC_CONTINUE;
	}

	new Float:flVelocity[3];
	flVelocity[0] = vecThrow[0] * 0.65;
	flVelocity[1] = vecThrow[1] * 0.65;
	flVelocity[2] = vecThrow[2] * 0.65;

	set_entvar(grenade, var_velocity, flVelocity);

	return HC_CONTINUE;
}

public rgBasePlayerRadio(const iPlayer, const szMessageId[], const szMessageVerbose[], iPitch, bool:bShowIcon) {
	if (!g_iSettings[c_iEnableBFITH]) {
		return HC_CONTINUE;
	}

	#pragma unused iPlayer, szMessageId, iPitch, bShowIcon
	
	if (szMessageVerbose[0] == EOS)
		return HC_CONTINUE;
	
	if (szMessageVerbose[3] == 114) // 'r'
		return HC_SUPERCEDE;
	
	return HC_CONTINUE;
}

public cmdBlock() {
	if (!g_iSettings[c_iEnableBCMDP]) {
		return PLUGIN_CONTINUE;
	}

	return PLUGIN_HANDLED;
}

public rgPlayerBlind(const index, const inflictor, const attacker, const Float:fadeTime, const Float:fadeHold, const alpha, Float:color[3]) {
	color = g_eFlashColor;
	return HC_CONTINUE;
}