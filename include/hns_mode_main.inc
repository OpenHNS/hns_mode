#if defined _hns_mode_main_included
	#endinput
#endif

#define _hns_mode_main_included

enum HNS_MODE {
	hns_public = 0,
	hns_deathmatch
}

native hns_get_prefix(prefix[], len);

native bool:is_deathmatch();
native hns_set_mode(HNS_MODE:eMode);

forward hns_team_swap();