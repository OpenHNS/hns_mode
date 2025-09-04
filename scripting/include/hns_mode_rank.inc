#if defined _hns_rank_included
	#endinput
#endif
#define _hns_rank_included

/*
* Gets player rank.
*
* @param id Client index
*
* @return rank num
*/
native hns_rank_get_rank(id);

/*
* Gets player exp.
*
* @param id Client index
*
* @return exp num
*/
native hns_rank_get_exp(id);

/*
* Gets player top.
*
* @param id Client index
*
* @return top num
*/
native hns_rank_get_top(id);