#if defined _hns_stats_included
	#endinput
#endif
#define _hns_stats_included

native hns_get_stats_kills(id);

/*
* Gets player deaths.
*
* @param id Client index
*
* @return deaths num
*/
native hns_get_stats_deaths(id);

/*
* Gets players assists.
*
* @param id Client index
*
* @return assists num
*/
native hns_get_stats_assists(id);

/*
* Gets players stabs.
*
* @param id Client index
*
* @return stabs num
*/
native hns_get_stats_stabs(id);

/*
* Gets players damage CT.
*
* @param id Client index
*
* @return damage CT num
*/
native hns_get_stats_dmgct(id);

/*
* Gets players damage TT.
*
* @param id Client index
*
* @return damage TT num
*/
native hns_get_stats_dmgtt(id);

/*
* Gets players runned distance.
*
* @param id Client index
*
* @return runned distance float
*/
native Float:hns_get_stats_run(id);

/*
* Gets players flash time.
*
* @param id Client index
*
* @return flash time float
*/
native Float:hns_get_stats_flashtime(id);

/*
* Gets players survive time.
*
* @param id Client index
*
* @return survive time float
*/
native Float:hns_get_stats_surv(id);

/*
* Gets players ownages.
*
* @param id Client index
*
* @return ownages num
*/
native hns_get_stats_ownages(id);


/*
* Called when statistics are complete.
*
* @param iWinTeam The winning team
*				0 - TT
*				1 - CT
*/
forward hns_apply_stats(iWinTeam);