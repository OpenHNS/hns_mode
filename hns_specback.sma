#include <amxmodx>
#include <reapi>
#include <hns_mode_main>

#define rg_get_user_team(%0) get_member(%0, m_iTeam)

new bool:g_bSpec[MAX_PLAYERS + 1];
new TeamName:g_iTeam[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("HNS Spec back", "1.0.0", "OpenHNS");

	register_clcmd("say /spec", "SpecBack");
	register_clcmd("say /back", "SpecBack");
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

public SpecBack(id) {
	g_bSpec[id] = !g_bSpec[id];

	if (g_bSpec[id]) {
		if (rg_get_user_team(id) == TEAM_SPECTATOR) {
			g_bSpec[id] = false;
			return;
		}

		g_iTeam[id] = rg_get_user_team(id);
		TransferToSpec(id);
	} else {
		if (rg_get_user_team(id) != TEAM_SPECTATOR) {
			g_bSpec[id] = true;
			return;
		}

		rg_set_user_team(id, g_iTeam[id]);

		if (is_deathmatch()) {
			rg_round_respawn(id);
		}
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