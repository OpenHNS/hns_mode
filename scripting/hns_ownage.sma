#include <amxmodx>
#include <engine>
#include <reapi>
#include <nvault>
#include <hns_mode_main>

new bool:g_bDebugMode;

new Float:g_pCvarDelay;
new Float:g_pCvarSave;

new Float:g_flLastHeadTouch[MAX_PLAYERS + 1];

new g_iPlayerOwnages[MAX_PLAYERS + 1];

new g_hForwardOwnage;

new const g_szSound[][] = {
	"openhns/mario.wav",
	"openhns/ownage.wav"
};

new g_iVault;

public plugin_init() {
	register_plugin("HNS: Ownage", "1.1", "OpenHNS");

	bind_pcvar_float(register_cvar("hns_ownage_delay", "5.0"), g_pCvarDelay);
	bind_pcvar_num(register_cvar("hns_ownage_save", "1"), g_pCvarSave);

	register_touch("player", "player", "TouchPlayer");

	g_hForwardOwnage = CreateMultiForward("hns_ownage", ET_CONTINUE, FP_CELL, FP_CELL);

	g_bDebugMode = bool:(plugin_flags() & AMX_FLAG_DEBUG);
}

public plugin_precache() {
	for(new i; i < sizeof(g_szSound); i++)
		precache_sound(g_szSound[i]);
}


public plugin_cfg() {
	g_iVault = nvault_open("ownages");

	if (g_iVault == INVALID_HANDLE) {
		log_amx("hns_ownage.amxx: plugin_cfg:: can't open file ^"ownages.vault^"!");
	}
}

public client_putinserver(id) {
	g_iPlayerOwnages[id] = 0;

	if (!g_pCvarSave) {
		return PLUGIN_HANDLED;
	}

	if (g_iVault == INVALID_HANDLE) {
		return PLUGIN_HANDLED;
	}

	new szAuthID[32];
	get_user_authid(id, szAuthID, charsmax(szAuthID));

	new szData[32], iTimeStamp;

	if (nvault_lookup(g_iVault, szAuthID, szData, charsmax(szData), iTimeStamp)) {
		new szOwnages[3];

		parse(szData, szOwnages, charsmax(szOwnages));

		g_iPlayerOwnages[id] = str_to_num(szOwnages);

		if (g_bDebugMode) server_print("[hns_ownage.amxx] Load ownages %n: %d.", id, g_iPlayerOwnages[id]);

		nvault_remove(g_iVault, szAuthID);
	}

	return PLUGIN_HANDLED;
}

public client_disconnected(id) {
	if (!g_pCvarSave) {
		return PLUGIN_HANDLED;
	}

	if (g_iVault == INVALID_HANDLE) {
		return PLUGIN_HANDLED;
	}

	if (!g_iPlayerOwnages[id]) {
		return PLUGIN_HANDLED;
	}

	new szAuthID[32];
	get_user_authid(id, szAuthID, charsmax(szAuthID));

	new szData[32];

	formatex(szData, charsmax(szData), "^"%d^"", g_iPlayerOwnages[id]);

	if (g_bDebugMode) server_print("[hns_ownage.amxx] Save ownages %n: %d.", id, g_iPlayerOwnages[id]);

	nvault_set(g_iVault, szAuthID, szData);


	g_iPlayerOwnages[id] = 0;

	return PLUGIN_HANDLED;
}

public TouchPlayer(iToucher, iTouched) {
	if(entity_get_int(iToucher, EV_INT_flags) & FL_ONGROUND && entity_get_edict(iToucher, EV_ENT_groundentity) == iTouched && rg_get_user_team(iToucher) == TEAM_TERRORIST && rg_get_user_team(iTouched) == TEAM_CT) {
		new Float:flGametime = get_gametime();
		
		if(flGametime > (g_flLastHeadTouch[iToucher] + g_pCvarDelay)) {
			ClearDHUDMessages();
			set_dhudmessage(250, 255, 0, -1.0, 0.15, 0, 0.0, 5.0, 0.1, 0.1);

			if (!g_pCvarSave) {
				show_dhudmessage(0, "%L", LANG_PLAYER, "HNS_OWNAGE", iToucher, iTouched);
			} else {
				g_iPlayerOwnages[iToucher]++;
				show_dhudmessage(0, "%L", LANG_PLAYER, "HNS_OWNAGE_COUNT", iToucher, iTouched, g_iPlayerOwnages[iToucher]);
			}
			
			g_flLastHeadTouch[iToucher] = flGametime;
			rg_send_audio(0, g_szSound[random(sizeof(g_szSound))]);

			ExecuteForward(g_hForwardOwnage, _, iToucher, iTouched);
		}
	}
}

stock ClearDHUDMessages(iClear = 8) {
	for (new iDHUD = 0; iDHUD < iClear; iDHUD++)
		show_dhudmessage(0, ""); 
}