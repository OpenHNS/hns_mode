#include <amxmodx>
#include <hamsandwich>
#include <reapi>

new bool: g_playerHideKnife[MAX_PLAYERS + 1][TeamName];

public plugin_init() {
	register_plugin("HNS: Hideknife", "1.0.0", "OpenHNS"); // ufame (https://github.com/ufame/brohns/blob/master/server/src/scripts/hns/hns_hideknife.sma)

	register_clcmd("say /hideknife", "commandHideKnife");
	register_clcmd("say_team /hideknife", "commandHideKnife");
	register_clcmd("say /knife", "commandHideKnife");
	register_clcmd("say_team /knife", "commandHideKnife");

	RegisterHam(Ham_Item_Deploy, "weapon_knife", "knifeDeploy", 1);
}

public commandHideKnife(id) {
	new menu = menu_create("Hide knife", "hideknifeHandler");

	menu_additem(
		menu,
		fmt(
			"Hide for \yTE \r%s",
			g_playerHideKnife[id][TEAM_TERRORIST] ? "YES" : "NO"
		)
	);

	menu_additem(
		menu,
		fmt(
			"Hide for \yCT \r%s",
			g_playerHideKnife[id][TEAM_CT] ? "YES" : "NO"
		)
	);

	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public hideknifeHandler(const id, const menu, const item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	menu_destroy(menu);

	new bool: hideKnife;
	new TeamName: hideTeam;

	switch (item) {
	case 0: {
		hideTeam = TEAM_TERRORIST;

		hideKnife = g_playerHideKnife[id][hideTeam] = !g_playerHideKnife[id][hideTeam];
	}
	case 1: {
		hideTeam = TEAM_CT;

		hideKnife = g_playerHideKnife[id][hideTeam] = !g_playerHideKnife[id][hideTeam];
	}
	}

	if (is_user_alive(id) && hideTeam == get_member(id, m_iTeam)) {
		new activeItem = get_member(id, m_pActiveItem);

		if (is_nullent(activeItem) || get_member(activeItem, m_iId) != WEAPON_KNIFE)
			return PLUGIN_HANDLED;

		set_entvar(id, var_viewmodel, hideKnife ? "" : "models/v_knife.mdl");
	}

	return PLUGIN_HANDLED;
}

public knifeDeploy(const entity) {
	new player = get_member(entity, m_pPlayer);
	new TeamName: team = get_member(player, m_iTeam);

	if (g_playerHideKnife[player][team])
		set_entvar(player, var_viewmodel, "");
}