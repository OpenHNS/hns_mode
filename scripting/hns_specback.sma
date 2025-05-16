#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <hns_mode_main>

new bool:g_bSpec[MAX_PLAYERS + 1];
new TeamName:g_iTeam[MAX_PLAYERS + 1];

new TeamName:g_eSpecBack[MAX_PLAYERS + 1];

new g_szPrefix[24];

public plugin_init() {
	register_plugin("HNS: Spec back", "1.1", "OpenHNS");

	register_clcmd("chooseteam", "TeamMenuBlock");

	RegisterSayCmd("spec", "back", "SpecBack", 0, "Spec/Back");

	register_dictionary("hidenseek.txt");
}

public hns_cvars_init() {
	hns_get_prefix(g_szPrefix, charsmax(g_szPrefix));
}

public plugin_natives() {
	register_native("hns_specback_init", "native_specback_init");
}

public native_specback_init(amxx, params) {
	return 1;
}

public client_disconnected(id) {
	g_eSpecBack[id] = TEAM_UNASSIGNED;
}

public hns_team_swap() {
	for(new i = 1; i <= MaxClients; i++) {
		if(g_bSpec[i]) {
			if(g_iTeam[i] == TEAM_CT)
				g_iTeam[i] = TEAM_TERRORIST;
			else if(g_iTeam[i] == TEAM_TERRORIST) 
				g_iTeam[i] = TEAM_CT;
		}
	}
}

public TeamMenuBlock(id) {
	SpecBackMenu(id);

	return PLUGIN_HANDLED;
}

public SpecBackMenu(id) {
	new szMsg[64];
	formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "SPECBACK_MENU");
	new hMenu = menu_create(szMsg, "SpecBackMenuHandler");

	if (rg_get_user_team(id) == TEAM_TERRORIST || rg_get_user_team(id) == TEAM_CT) {
		formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "SPECBACK_SPEC");
	} else {
		formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "SPECBACK_BACK");
	}

	menu_additem(hMenu, szMsg, "1");

	menu_display(id, hMenu, 0);
}

public SpecBackMenuHandler(id, hMenu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(hMenu);
		return PLUGIN_HANDLED;
	}

	menu_destroy(hMenu);

	SpecBack(id);

	return PLUGIN_HANDLED;
}

public SpecBack(id) {
	if (rg_get_user_team(id) == TEAM_SPECTATOR) {
		new iNumTT = get_playersnum_ex(GetPlayers_MatchTeam, "TERRORIST");
		new iNumCT = get_playersnum_ex(GetPlayers_MatchTeam, "CT");
		
		if (iNumTT == iNumCT && g_eSpecBack[id] != TEAM_UNASSIGNED) {
			rg_set_user_team(id, g_eSpecBack[id]);
		} else if (iNumTT < iNumCT) {
			rg_set_user_team(id, TEAM_TERRORIST);
		} else {
			rg_set_user_team(id, TEAM_CT);
		}

		if (hns_get_mode() == MODE_PUBLIC) {
			if (rg_is_player_can_respawn(id)) {
				rg_round_respawn(id);
			}
		} else {
			rg_round_respawn(id);
		}
		client_print_color(id, print_team_blue, "%L", id, "SPECBACK_CHAT_BACK", g_szPrefix, id);
	} else {
		g_eSpecBack[id] = rg_get_user_team(id);
		TransferToSpec(id);
		client_print_color(id, print_team_blue, "%L", id, "SPECBACK_CHAT_SPEC", g_szPrefix, id);
	}
}

stock TransferToSpec(id) {
	SetTeam(id, TEAM_SPECTATOR);
	set_entvar(id, var_solid, SOLID_NOT);
	set_entvar(id, var_movetype, MOVETYPE_FLY);
}

SetTeam(id, TeamName:iTeam) {
	set_member(id, m_bTeamChanged, false);

	if (is_user_alive(id))
		user_silentkill(id);

	switch (iTeam) {
	case TEAM_TERRORIST: {
		rg_internal_cmd(id, "jointeam", "1");
		rg_internal_cmd(id, "joinclass", "5");
	}
	case TEAM_CT: {
		rg_internal_cmd(id, "jointeam", "2");
		rg_internal_cmd(id, "joinclass", "5");
	}
	case TEAM_SPECTATOR:
		rg_internal_cmd(id, "jointeam", "6");
	}
}