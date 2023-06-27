#if defined _hns_mode_main_included
	#endinput
#endif

#define _hns_mode_main_included

enum HNS_MODE {
	hns_public = 0,
	hns_deathmatch
}

new HNS_MODE:g_eHnsMode;

native hns_get_prefix(prefix[], len);

native HNS_MODE:native_get_mode();
native hns_set_mode(HNS_MODE:eMode);

forward hns_team_swap();