#include <amxmodx>
#include <hns_mode_main>

new g_szPrefix[24];

enum HNS_CVAR {
	c_iStartNight,
	c_iEndNight
};

new g_pCvar[HNS_CVAR];

new bool:g_bNight;

public plugin_init()
{
	register_plugin("HNS: Night deathmatch", "1.0", "OpenHNS");
	
	bind_pcvar_num(register_cvar("hns_start_night", "23"), 	g_pCvar[c_iStartNight]);
	bind_pcvar_num(register_cvar("hns_end_night", "9"),		g_pCvar[c_iEndNight]);

	check_night();
	set_task(60.0, "check_night", .flags = "b");
}

public hns_cvars_init() {
	hns_get_prefix(g_szPrefix, charsmax(g_szPrefix));
}

public check_night() {
	new bool:bNowNight = isNight();

	if (bNowNight && !g_bNight) {
		hns_set_mode(MODE_DEATHMATCH);
		client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "NIGHT_START", g_szPrefix);
		g_bNight = true;
	} else if (!bNowNight && g_bNight) {
		hns_set_mode(MODE_PUBLIC);
		client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "NIGHT_STOP", g_szPrefix);
		g_bNight = false;
	}
}

public hns_round_start() {
	check_night();
}

public bool:isNight() {
	static iNumChas; time(iNumChas);
	new iStart = clamp(g_pCvar[c_iStartNight], 0, 23);
	new iEnd = clamp(g_pCvar[c_iEndNight], 0, 23);

	if (iStart == iEnd) {
		return false;
	}

	if (iStart > iEnd) {
		return (iNumChas >= iStart || iNumChas < iEnd);
	}

	return (iNumChas >= iStart && iNumChas < iEnd);
}
