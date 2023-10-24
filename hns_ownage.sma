#include <amxmodx>
#include <engine>
#include <reapi>

#define rg_get_user_team(%0) get_member(%0, m_iTeam)

new Float:g_pCvarDelay;

new Float:g_flLastHeadTouch[MAX_PLAYERS + 1];

new g_hForwardOwnage;

new const g_szSound[][] = {
	"openhns/mario.wav",
	"openhns/ownage.wav"
};

public plugin_init() {
	register_plugin("HNS Ownage", "1.0", "OpenHNS");

	bind_pcvar_float(register_cvar("hns_ownage_delay", "5.0"), g_pCvarDelay);

	register_touch("player", "player", "iTouchPlayer");

	g_hForwardOwnage = CreateMultiForward("hns_ownage", ET_CONTINUE, FP_CELL, FP_CELL);
}

public plugin_precache() {
	for(new i; i < sizeof(g_szSound); i++)
		precache_sound(g_szSound[i]);
}

public iTouchPlayer(iToucher, iTouched) {
	if(entity_get_int(iToucher, EV_INT_flags) & FL_ONGROUND && entity_get_edict(iToucher, EV_ENT_groundentity) == iTouched && rg_get_user_team(iToucher) == TEAM_TERRORIST && rg_get_user_team(iTouched) == TEAM_CT) {
		new Float:flGametime = get_gametime();
		
		if(flGametime > (g_flLastHeadTouch[iToucher] + g_pCvarDelay)) {
			set_dhudmessage(250, 255, 0, -1.0, 0.2, .holdtime = 4.0);
  			show_dhudmessage(0, "%L", LANG_PLAYER, "HNS_OWNAGE", iToucher, iTouched);
			
			g_flLastHeadTouch[iToucher] = flGametime;
			rg_send_audio(0, g_szSound[random(sizeof(g_szSound))]);

			ExecuteForward(g_hForwardOwnage, _, iToucher, iTouched);
		}
	}
}