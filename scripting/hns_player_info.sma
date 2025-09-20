#include <amxmodx>
#include <reapi>

#include <hns_mode_main>
#include <hns_mode_rank>
#include <hns_mode_filter>

native hns_shop_init();

#define TASK_HUD 1328

new g_szPrefix[24];

new bool:g_bShowHud;

new bool:g_bPlayerInfo[MAX_PLAYERS + 1];

new g_MsgSync;

public plugin_init() {
	register_plugin("HNS: Player info", "1.1", "OpenHNS");

	RegisterSayCmd("playerinfo", "pi", "cmdPlayerInfo", 0, "Show player info");

	set_task(1.0, "task_ShowPlayerInfo", .flags = "b");

	g_MsgSync = CreateHudSyncObj();
}

public plugin_natives() {
	set_native_filter("hns_mode_additons");
}

public hns_cvars_init() {
	hns_get_prefix(g_szPrefix, charsmax(g_szPrefix));
}

public cmdPlayerInfo(id) {
	g_bPlayerInfo[id] = !g_bPlayerInfo[id];
	
	if (g_bPlayerInfo[id])
		client_print_color(id, print_team_blue, "%L", id, "PLAYERINFO_ON", g_szPrefix);
	else
		client_print_color(id, print_team_blue, "%L", id, "PLAYERINFO_OFF", g_szPrefix);

	return PLUGIN_HANDLED;
}

public hns_round_end(iWinTeam) {
	g_bShowHud = true;
}

public hns_round_start() {
	if (hns_get_mode() == MODE_PUBLIC) {
		set_task(10.0, "end_show_hud", TASK_HUD);
	} else {
		g_bShowHud = true;
	}
}

public end_show_hud() {
	g_bShowHud = false;
}

public client_disconnected(id) {
	g_bPlayerInfo[id] = true;
}

public client_putinserver(id) {
	g_bPlayerInfo[id] = true;
}

public task_ShowPlayerInfo() {
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ch");

	for(new i; i < iNum; i++) {
		new id = iPlayers[i];

		new show_id = is_user_alive(id) ? id : get_entvar(id, var_iuser2);

		if(!is_user_connected(show_id)) {
			continue;
		}

		if (!g_bPlayerInfo[id]) {
			continue;
		}

		set_hudmessage(.red = 100, .green = 100, .blue = 100, .x = 0.01, .y = 0.20, .holdtime = 1.0);
		new szHudMess[1024], iLen;

		if (g_bShowHud || show_id != id) {
			iLen += format(szHudMess[iLen], sizeof szHudMess - iLen, "\
				HNS %s Mode %daa^n", hns_get_mode() == MODE_PUBLIC ? "Public" : "DeathMatch", get_cvar_num("sv_airaccelerate"));
		}

		if (g_bShowHud || show_id != id) {
			iLen += format(szHudMess[iLen], sizeof szHudMess - iLen, "\
				Player: %n (#%d)^n", 
			show_id, hns_rank_get_top(show_id));
		}

		if (g_bShowHud || show_id != id) {
			iLen += format(szHudMess[iLen], sizeof szHudMess - iLen, "\
				Rank: %d Exp: %d^n^n",
				hns_rank_get_rank(show_id), hns_rank_get_exp(show_id));
		}

		if (g_bShowHud && show_id == id) {
			iLen += format(szHudMess[iLen], sizeof szHudMess - iLen, "\
				%sMain menu (N)^n", hns_shop_init() == 1 && hns_get_mode() == MODE_PUBLIC ? "Buy menu (b) " : "");
		}

		ShowSyncHudMsg(id, g_MsgSync, "%s", szHudMess);
	}
}