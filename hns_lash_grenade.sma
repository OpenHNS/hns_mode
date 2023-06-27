#include <amxmodx>
#include <reapi>

#define rg_get_user_team(%0) get_member(%0, m_iTeam)

new bool:g_bLastFlash;

public plugin_init() {
	register_plugin("HNS Last grenade", "1.0.0", "OpenHNS");

	RegisterHookChain(RG_CSGameRules_RestartRound, "rgRoundStart", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "rgPlayerKilled", true);
}

public rgRoundStart() {
	g_bLastFlash = false;
}

public rgPlayerKilled(victim, attacker) {
	if (rg_get_user_team(victim) != TEAM_TERRORIST || g_bLastFlash)
			return HC_CONTINUE;

	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "aech", "TERRORIST");
	if (iNum == 1) {
		g_bLastFlash = true;
		NewNadesMenu(iPlayers[0]);
	}

	return HC_CONTINUE;
}

public NewNadesMenu(id) {
	new hMenu = menu_create("\rНужны гранаты?", "NadesHandler");
	
	menu_additem(hMenu, "Да.");
	menu_additem(hMenu, "Нет.");
	
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
		if (user_has_weapon(id, CSW_FLASHBANG)) {
			rg_set_user_bpammo(id, WEAPON_SMOKEGRENADE, rg_get_user_bpammo(id, WEAPON_SMOKEGRENADE) + 1);
		} else {
			rg_give_item(id, "weapon_flashbang");
		}

		if (user_has_weapon(id, CSW_SMOKEGRENADE))
		{
			rg_set_user_bpammo(id, WEAPON_HEGRENADE, rg_get_user_bpammo(id, WEAPON_HEGRENADE) + 1);
		} else {
			rg_give_item(id, "weapon_smokegrenade");
		}
	}

	g_bLastFlash = false;

	menu_destroy(hMenu);
	return PLUGIN_HANDLED;
}