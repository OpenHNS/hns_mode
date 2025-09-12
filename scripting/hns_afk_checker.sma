#include <amxmodx>
#include <reapi>
#include <hns_mode_main>

new Float: max_idle_period

new prefix[24]

new fw_player_idle = -1

public plugin_init() {
  register_plugin("HNS: AFK checker", "1.0", "OpenHNS")

  RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "@RG_CSGameRules_OnRoundFreezeEnd")
  RegisterHookChain(RG_CBasePlayer_DropIdlePlayer, "@RG_CBasePlayer_DropIdlePlayer")

  fw_player_idle = CreateMultiForward("hns_player_idle", ET_CONTINUE, FP_CELL)
}

public hns_cvars_init() {
  // TODO: create_cvar
  bind_pcvar_float(
                  register_cvar("hns_max_idle_period", "15.0"),
                  max_idle_period)

  hns_get_prefix(prefix, charsmax(prefix))
}

@RG_CSGameRules_OnRoundFreezeEnd() {
  if (get_member_game(m_fMaxIdlePeriod) != max_idle_period)
    set_member_game(m_fMaxIdlePeriod, max_idle_period)
}

@RG_CBasePlayer_DropIdlePlayer(const id, const reason[]) {
  transfer_to_spectators(id)
  client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "HNS_PLAYER_IDLE", prefix, id)

  ExecuteForward(fw_player_idle, _, id)

  return HC_SUPERCEDE
}

stock transfer_to_spectators(const id) {
  set_member(id, m_bTeamChanged, false)

  if (is_user_alive(id))
    user_silentkill(id)

  rg_internal_cmd(id, "jointeam", "6")

  set_entvar(id, var_solid, SOLID_NOT)
  set_entvar(id, var_movetype, MOVETYPE_FLY)
}