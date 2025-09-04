#if defined _hns_mode_filter_included
	#endinput
#endif
#define _hns_mode_filter_included


public hns_mode_additons(const szNativeName[], iNativeID, iTrapMode) {
	if (equal(szNativeName, "hns_specback_init")) { 
		return PLUGIN_HANDLED
	}

	if (equal(szNativeName, "hns_rank_get_rank")) { 
		return PLUGIN_HANDLED
	}

	if (equal(szNativeName, "hns_rank_get_exp")) { 
		return PLUGIN_HANDLED
	}

	if (equal(szNativeName, "hns_rank_get_top")) { 
		return PLUGIN_HANDLED
	}

	if (equal(szNativeName, "hns_shop_init")) { 
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE;
}