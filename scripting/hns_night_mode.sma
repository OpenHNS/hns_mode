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

	set_task(0.6, "check_night");
}

public plugin_cfg() {
	hns_get_prefix(g_szPrefix, charsmax(g_szPrefix));
}

public check_night() {
	if (isNight()) {
		hns_set_mode(MODE_DEATHMATCH);
		g_bNight = true;
	} else {
		hns_set_mode(MODE_PUBLIC);
		g_bNight = false;
	}
}

public hns_round_start() {
	if (isNight() && !g_bNight) {
		hns_set_mode(MODE_DEATHMATCH);
		client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "NIGHT_START", g_szPrefix);
		g_bNight = true;
	} else if (!isNight() && g_bNight) {
		hns_set_mode(MODE_PUBLIC);
		client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "NIGHT_STOP", g_szPrefix);
		g_bNight = false;
	}
}

public bool:isNight() {
	static iNumChas; time(iNumChas);

	if (g_pCvar[c_iStartNight] > g_pCvar[c_iEndNight]) {
		return (iNumChas >= g_pCvar[c_iStartNight] || iNumChas < g_pCvar[c_iEndNight]) ? true : false;
	} else {
		return (g_pCvar[c_iStartNight] <= iNumChas < g_pCvar[c_iEndNight]) ? true : false;
	} 
}