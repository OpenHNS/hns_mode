#include <amxmodx>
#include <reapi>
#include <hns_mode_main>

enum HNS_CVAR {
	c_iLastHe,
	c_iLastFlash,
	c_iLastSmoke,
};

new g_pCvar[HNS_CVAR];
new _:g_iSettings[HNS_CVAR];

new bool:g_bLastFlash;

new g_szPrefix[24];

public plugin_init() {
	register_plugin("HNS: Last grenade", "1.1", "OpenHNS");

	g_pCvar[c_iLastHe] = create_cvar("hns_last_he", "0", FCVAR_NONE, "Count lash he grenade for TT", true, 0.0, true, 10.0);
	bind_pcvar_num(g_pCvar[c_iLastHe], g_iSettings[c_iLastHe]);

	g_pCvar[c_iLastFlash] = create_cvar("hns_last_flash", "1", FCVAR_NONE, "Count lash fash grenade for TT", true, 0.0, true, 10.0);
	bind_pcvar_num(g_pCvar[c_iLastFlash], g_iSettings[c_iLastFlash]);

	g_pCvar[c_iLastSmoke] = create_cvar("hns_last_smoke", "1", FCVAR_NONE, "Count lash smoke grenade for TT", true, 0.0, true, 10.0);
	bind_pcvar_num(g_pCvar[c_iLastSmoke], g_iSettings[c_iLastSmoke]);

	RegisterHookChain(RG_CSGameRules_RestartRound, "rgRoundStart", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "rgPlayerKilled", true);

	register_dictionary("hidenseek.txt");
}

public hns_cvars_init() {
	hns_get_prefix(g_szPrefix, charsmax(g_szPrefix));
}

public rgRoundStart() {
	g_bLastFlash = false;
}

public rgPlayerKilled(victim, attacker) {
	if (hns_get_mode() != MODE_PUBLIC || rg_get_user_team(victim) != TEAM_TERRORIST || g_bLastFlash) {
		return HC_CONTINUE;
	}

	if (!g_iSettings[c_iLastHe] && !g_iSettings[c_iLastFlash] && !g_iSettings[c_iLastSmoke]) {
		return HC_CONTINUE;
	}

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "aech", "TERRORIST");
	if (iNum == 1) {
		g_bLastFlash = true;
		NewNadesMenu(iPlayers[0]);
	}

	return HC_CONTINUE;
}

public NewNadesMenu(id) {
	new szMsg[64];

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "LAST_NEED");
	new hMenu = menu_create(szMsg, "NadesHandler");

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "HNS_YES");
	menu_additem(hMenu, szMsg);

	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "HNS_NO");
	menu_additem(hMenu, szMsg);

	menu_setprop(hMenu, MPROP_PERPAGE, 0);
	menu_display(id, hMenu, 0);
	return PLUGIN_HANDLED;
}

public NadesHandler(id, hMenu, item) {
	if (item == MENU_EXIT || !g_bLastFlash) {
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}

	if (!item) {
		if (g_iSettings[c_iLastHe]) {
			if (user_has_weapon(id, CSW_HEGRENADE)) {
				rg_set_user_bpammo(id, WEAPON_HEGRENADE, rg_get_user_bpammo(id, WEAPON_HEGRENADE) + g_iSettings[c_iLastHe]);
			} else {
				rg_give_item(id, "weapon_hegrenade");

				if (g_iSettings[c_iLastHe] > 1) {
					rg_set_user_bpammo(id, WEAPON_HEGRENADE, g_iSettings[c_iLastHe]);
				}
			}
		}

		if (g_iSettings[c_iLastFlash]) {
			if (user_has_weapon(id, CSW_FLASHBANG)) {
				rg_set_user_bpammo(id, WEAPON_FLASHBANG, rg_get_user_bpammo(id, WEAPON_FLASHBANG) + g_iSettings[c_iLastFlash]);
			} else {
				rg_give_item(id, "weapon_flashbang");

				if (g_iSettings[c_iLastFlash] > 1) {
					rg_set_user_bpammo(id, WEAPON_FLASHBANG, g_iSettings[c_iLastFlash]);
				}
			}
		}

		if (g_iSettings[c_iLastSmoke]) {
			if (user_has_weapon(id, CSW_SMOKEGRENADE)) {
				rg_set_user_bpammo(id, WEAPON_SMOKEGRENADE, rg_get_user_bpammo(id, WEAPON_SMOKEGRENADE) + g_iSettings[c_iLastSmoke]);
			} else {
				rg_give_item(id, "weapon_smokegrenade");

				if (g_iSettings[c_iLastSmoke] > 1) {
					rg_set_user_bpammo(id, WEAPON_SMOKEGRENADE, g_iSettings[c_iLastSmoke]);
				}
			}
		}

		client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "LAST_SET", g_szPrefix, id);
	}

	g_bLastFlash = false;

	menu_destroy(hMenu);
	return PLUGIN_HANDLED;
}