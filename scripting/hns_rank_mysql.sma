#include <amxmodx>
#include <reapi>
#include <sqlx>

#include <hns_mode_main>
#include <hns_mode_stats>

new bool:g_bDebugMode;

new g_szTablePlayers[] = "hns_rank_stats";

#define SQL_CREATE_TABLE \
"CREATE TABLE IF NOT EXISTS `%s` \
( \
	`id`			INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY, \
	`name`			VARCHAR(32) NULL DEFAULT NULL, \
	`steamid`		VARCHAR(24) NULL DEFAULT NULL, \
	`ip`			VARCHAR(22) NULL DEFAULT NULL, \
	`rank`			INT NOT NULL DEFAULT 0, \
	`exp`			INT NOT NULL DEFAULT 0, \
	`wintt`			INT NOT NULL DEFAULT 0, \
	`stabs`			INT NOT NULL DEFAULT 0, \
	`ownages`		INT NOT NULL DEFAULT 0, \
	`avgsurv`		FLOAT NOT NULL DEFAULT 0.0, \
	`countsurv` 	INT NOT NULL DEFAULT 0, \
	`playtime`		INT NOT NULL DEFAULT 0, \
	`lastconnect`	TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP \
);"

#define SQL_SELECT_DATA \
"SELECT * FROM \
	`%s` \
WHERE \
	`steamid` = '%s'"

#define SQL_INSERT_DATA \
"INSERT INTO `%s` ( \
	name, \
	steamid, \
	ip \
) VALUES ( \
	'%s', \
	'%s', \
	'%s' \
)"

#define SQL_UPDATE_NAME \
"UPDATE `%s` SET \
	`name` = '%s' \
WHERE \
	`id` = %d"

#define SQL_UPDATE_IP \
"UPDATE `%s` SET \
	`ip` = '%s' \
WHERE \
	`id` = %d"

#define SQL_SET_PLAYTIME \
"UPDATE `%s` SET \
	`playtime` = `playtime` + %d \
WHERE \
	`id` = %d"

#define SQL_SET_STATS_TT \
"UPDATE `%s` SET \
	`rank` = %d, \
	`exp` = `exp` + %d, \
	`wintt` = `wintt` + %d, \
	`ownages` = `ownages` + %d, \
	`avgsurv` = %f, \
	`countsurv` = `countsurv` + 1 \
WHERE \
	`id` = %d"

#define SQL_SET_STATS_CT \
"UPDATE `%s` SET \
	`rank` = %d, \
	`exp` = `exp` + %d, \
	`stabs` = `stabs` + %d \
WHERE \
	`id` = %d"

enum _:HNS_CVAR {
	c_szHost[48],
	c_szUser[32],
	c_szPass[32],
	c_szDB[32]
};

new g_pCvar[HNS_CVAR];
new _:g_iSettings[HNS_CVAR];

enum SQL {
	SQL_TABLE,
	SQL_SELECT,
	SQL_INSERT,
	SQL_NAME,
	SQL_IP,
	SQL_PLAYTIME,
	SQL_STATS_TT,
	SQL_STATS_CT
};

new Handle:g_hSqlTuple;

enum _:REC_DATA {
	SQL:REQUEST = 0,
	PLAYER_ID,
};

new g_iPlayerID[MAX_PLAYERS + 1];

enum _:HNS_RANK_DATA {
	HNS_RANK,
	RANK_EXP,
	RANK_WINTT,
	RANK_STABS,
	RANK_OWNAGES,
	Float:RANK_AVGSURV,
	RANK_COUNTSURV,
	RANK_PLAYTIME
}

new g_eRankData[MAX_PLAYERS + 1][HNS_RANK_DATA];

public plugin_init() {
	register_plugin("HNS: Rank mysql", "1.0", "OpenHNS");

	g_pCvar[c_szHost] = create_cvar("hns_rank_host", "127.0.0.1", FCVAR_PROTECTED, "Database host");
	bind_pcvar_string(g_pCvar[c_szHost], g_iSettings[c_szHost], charsmax(g_iSettings[c_szHost]));

	g_pCvar[c_szUser] = create_cvar("hns_rank_user", "user", FCVAR_PROTECTED, "Database user");
	bind_pcvar_string(g_pCvar[c_szUser], g_iSettings[c_szUser], charsmax(g_iSettings[c_szUser]));

	g_pCvar[c_szPass] = create_cvar("hns_rank_pass", "pass", FCVAR_PROTECTED, "Database password");
	bind_pcvar_string(g_pCvar[c_szPass], g_iSettings[c_szPass], charsmax(g_iSettings[c_szPass]));

	g_pCvar[c_szDB] = create_cvar("hns_rank_db", "db", FCVAR_PROTECTED, "Database table");
	bind_pcvar_string(g_pCvar[c_szDB], g_iSettings[c_szDB], charsmax(g_iSettings[c_szDB]));

	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoName, "rgSetClientUserInfoName", true);

	g_bDebugMode = bool:(plugin_flags() & AMX_FLAG_DEBUG);
}

public hns_cvars_init() {
	g_hSqlTuple = SQL_MakeDbTuple(g_iSettings[c_szHost], g_iSettings[c_szUser], g_iSettings[c_szPass], g_iSettings[c_szDB]);
	SQL_SetCharset(g_hSqlTuple, "utf-8");

	new szQuery[1024];

	new cData[REC_DATA];
	cData[REQUEST] = SQL_TABLE,
	
	formatex(szQuery, charsmax(szQuery), SQL_CREATE_TABLE, g_szTablePlayers);
	
	SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery, cData, sizeof(cData));
}

public hns_apply_stats(iWinTeam) {
	new iPlayers[MAX_PLAYERS], iNum;
	get_players(iPlayers, iNum, "ch");

	for (new i = 0; i < iNum; i++) {
		new id = iPlayers[i];

		new iExp;

		if (rg_get_user_team(id) == TEAM_TERRORIST) {
			new iWinTT;
			if (iWinTeam == WIN_TT) {
				if (is_user_alive(id)) {
					iWinTT++;
					iExp += 10;
				} else {
					iExp += 5;
				}
			}

			new iOwnages = hns_get_stats_ownages(id);

			if (iOwnages) {
				iExp += iOwnages * 15;
			}

			new Float:flAvgSurv = calcAvgSurv(g_eRankData[id][RANK_AVGSURV], g_eRankData[id][RANK_COUNTSURV], hns_get_stats_surv(id));

			SQL_UpdateStatsTT(id, 1, iExp, iWinTT, iOwnages, flAvgSurv);
		} else if (rg_get_user_team(id) == TEAM_CT) {
			new iStabs = hns_get_stats_stabs(id);

			if (iWinTeam == WIN_CT) {
				if (is_user_alive(id)) {
					iExp += 2;
				}

				iExp += 3;
			}

			if (iStabs) {
				iExp += iStabs * 5;
			}

			SQL_UpdateStatsCT(id, 1, iExp, iStabs);
		}

	}
}

stock Float:calcExp(Float:flAvgSurv) {
	new Float:newCount = floatadd(float(iCount), 1.0);
	new Float:totalSum = floatadd(floatmul(flAvgSurv, float(iCount)), flSurvTime);
	new Float:newAvg = floatdiv(totalSum, newCount);

	return newAvg;
}

stock Float:calcAvgSurv(Float:flAvgSurv, iCount, Float:flSurvTime) {
	new Float:newCount = floatadd(float(iCount), 1.0);
	new Float:totalSum = floatadd(floatmul(flAvgSurv, float(iCount)), flSurvTime);
	new Float:newAvg = floatdiv(totalSum, newCount);

	return newAvg;
}

public plugin_natives() {
	register_native("hns_rank_get_rank", "native_rank_get_rank");
	register_native("hns_rank_get_exp", "native_rank_get_exp");
}

public native_rank_get_rank(amxx, params) {
	enum { id = 1 };

	if (g_bDebugMode) server_print("[HNS_RANK] native_rank_get_rank(%n) return %d", get_param(id), g_eRankData[id][HNS_RANK])

	return g_eRankData[id][HNS_RANK];
}

public native_rank_get_exp(amxx, params) {
	enum { id = 1 };

	if (g_bDebugMode) server_print("[HNS_RANK] native_rank_get_exp(%n) return %d", get_param(id), g_eRankData[id][RANK_EXP])

	return g_eRankData[id][RANK_EXP];
}

public rgSetClientUserInfoName(id, infobuffer[], szNewName[]) {
	if (!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id)) {
		return HC_CONTINUE;
	}

	SQL_UpdateName(id, szNewName);

	return HC_CONTINUE;
}

public client_putinserver(id) {
	g_iPlayerID[id] = 0;

	arrayset(g_eRankData[id], 0, HNS_RANK_DATA);

	if (is_user_hltv(id) || is_user_bot(id)) {
		return PLUGIN_HANDLED;
	}

	SQL_SelectData(id);

	return PLUGIN_HANDLED;
}

public client_disconnected(id) {
	if (is_user_hltv(id) || is_user_bot(id)) {
		return PLUGIN_HANDLED;
	}

	SQL_UpdatePlayTime(id);

	g_iPlayerID[id] = 0;

	arrayset(g_eRankData[id], 0, HNS_RANK_DATA);

	return PLUGIN_HANDLED;
}

public plugin_end() {
	SQL_FreeHandle(g_hSqlTuple);
}

public QueryHandler(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime) {
	if (iFailState != TQUERY_SUCCESS) {
		log_amx("SQL Error #%d - %s", iErrnum, szError);
		return PLUGIN_HANDLED;
	}

	switch(cData[REQUEST]) {
		case SQL_SELECT: {
			new id = cData[PLAYER_ID];
			if (g_bDebugMode) server_print("[HNS_RANK] SQL Handler (SQL_SELECT) player: %n", id);

			if (!is_user_connected(id))
				return PLUGIN_HANDLED;

			if (SQL_NumResults(hQuery)) {
				new index_id = SQL_FieldNameToNum(hQuery, "id");
				new index_name = SQL_FieldNameToNum(hQuery, "name");
				new index_ip = SQL_FieldNameToNum(hQuery, "ip");
				new index_rank = SQL_FieldNameToNum(hQuery, "rank");
				new index_exp = SQL_FieldNameToNum(hQuery, "exp");
				new index_wintt = SQL_FieldNameToNum(hQuery, "wintt");
				new index_stabs = SQL_FieldNameToNum(hQuery, "stabs");
				new index_ownages = SQL_FieldNameToNum(hQuery, "ownages");
				new index_avgsurv = SQL_FieldNameToNum(hQuery, "avgsurv");
				new index_countsurv = SQL_FieldNameToNum(hQuery, "countsurv");
				new index_playtime = SQL_FieldNameToNum(hQuery, "playtime");

				g_iPlayerID[id] = SQL_ReadResult(hQuery, index_id);

				if (g_bDebugMode) server_print("[HNS_RANK] (SQL_SELECT) Get player id: %d for player: %n", g_iPlayerID[id], id);

				new szNewName[MAX_NAME_LENGTH];
				new szNewNameSQL[MAX_NAME_LENGTH * 2]
				get_user_name(id, szNewName, charsmax(szNewName));
				SQL_QuoteString(Empty_Handle, szNewNameSQL, charsmax(szNewNameSQL), fmt("%s", szNewNameSQL));

				new szOldName[MAX_NAME_LENGTH];
				SQL_ReadResult(hQuery, index_name, szOldName, charsmax(szOldName));

				if (!equal(szNewNameSQL, szOldName))
					SQL_UpdateName(id, szNewNameSQL);
				
				new szNewIp[MAX_IP_LENGTH]; 
				get_user_ip(id, szNewIp, charsmax(szNewIp), true);

				new szOldIp[MAX_NAME_LENGTH]; 
				SQL_ReadResult(hQuery, index_ip, szOldIp, charsmax(szOldIp));

				if (!equal(szNewIp, szOldIp))
					SQL_UpdateIP(id, szNewIp);

				g_eRankData[id][HNS_RANK] =  SQL_ReadResult(hQuery, index_rank);
				g_eRankData[id][RANK_EXP] =  SQL_ReadResult(hQuery, index_exp);
				g_eRankData[id][RANK_WINTT] =  SQL_ReadResult(hQuery, index_wintt);
				g_eRankData[id][RANK_STABS] =  SQL_ReadResult(hQuery, index_stabs);
				g_eRankData[id][RANK_OWNAGES] =  SQL_ReadResult(hQuery, index_ownages);
				g_eRankData[id][RANK_AVGSURV] =  _:SQL_ReadResult(hQuery, index_avgsurv);
				g_eRankData[id][RANK_COUNTSURV] =  SQL_ReadResult(hQuery, index_countsurv);
				g_eRankData[id][RANK_PLAYTIME] =  SQL_ReadResult(hQuery, index_playtime);
			} else {
				SQL_InsertData(id);
			}
		}
		case SQL_INSERT: {
			new id = cData[PLAYER_ID];
			if (g_bDebugMode) server_print("[HNS_RANK] SQL Handler (SQL_INSERT) player: %n", id);

			g_iPlayerID[id] = SQL_GetInsertId(hQuery);

			if (g_bDebugMode) server_print("[HNS_RANK] (SQL_INSERT) Get player id: %d for player: %n", g_iPlayerID[id], id);
		}
		case SQL_IP: {
			new id = cData[PLAYER_ID];
			if (g_bDebugMode) server_print("[HNS_RANK] SQL Handler (SQL_IP) player: %n", id);
		}
		case SQL_NAME: {
			new id = cData[PLAYER_ID];
			if (g_bDebugMode) server_print("[HNS_RANK] SQL Handler (SQL_NAME) player: %n", id);
		}
		case SQL_PLAYTIME: {
			// new id = cData[PLAYER_ID];
			// if (g_bDebugMode) server_print("[HNS_RANK] SQL Handler (SQL_PLAYTIME) player: %n", id);
		}
		case SQL_STATS_TT: {
			new id = cData[PLAYER_ID];
			if (g_bDebugMode) server_print("[HNS_RANK] SQL Handler (SQL_STATS_TT) player: %n", id);
		}
		case SQL_STATS_CT: {
			new id = cData[PLAYER_ID];
			if (g_bDebugMode) server_print("[HNS_RANK] SQL Handler (SQL_STATS_CT) player: %n", id);
		}
	}

	return PLUGIN_HANDLED;
}

stock SQL_SelectData(id) {
	new szQuery[512];

	new cData[REC_DATA];
	cData[REQUEST] = SQL_SELECT, 
	cData[PLAYER_ID] = id;

	new szAuthId[MAX_AUTHID_LENGTH];
	get_user_authid(id, szAuthId, charsmax(szAuthId));

	if (g_bDebugMode) server_print("[HNS_RANK] SQL Request Select: %n, %s", id, szAuthId);

	formatex(szQuery, charsmax(szQuery), SQL_SELECT_DATA, g_szTablePlayers, szAuthId);
	SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery, cData, sizeof(cData));

	return PLUGIN_HANDLED;
}

stock SQL_InsertData(id) {
	new szQuery[512];

	new cData[REC_DATA];
	cData[REQUEST] = SQL_INSERT,
	cData[PLAYER_ID] = id;

	new szName[MAX_NAME_LENGTH * 2];
	SQL_QuoteString(Empty_Handle, szName, charsmax(szName), fmt("%n", id));

	new szAuthId[MAX_AUTHID_LENGTH];
	get_user_authid(id, szAuthId, charsmax(szAuthId));

	new szIp[MAX_IP_LENGTH];
	get_user_ip(id, szIp, charsmax(szIp), true);

	if (g_bDebugMode) server_print("[HNS_RANK] SQL Request Insert: %n, %s, %s", id, szAuthId, szIp);

	formatex(szQuery, charsmax(szQuery), SQL_INSERT_DATA, g_szTablePlayers, szName, szAuthId, szIp);
	SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery, cData, sizeof(cData));

	return PLUGIN_HANDLED;
}

stock SQL_UpdateName(id, szNewname[]) {
	new szQuery[512]

	new cData[REC_DATA];
	cData[REQUEST] = SQL_NAME;
	cData[PLAYER_ID] = id;

	new szName[MAX_NAME_LENGTH * 2];
	SQL_QuoteString(Empty_Handle, szName, charsmax(szName), szNewname);

	if (g_bDebugMode) server_print("[HNS_RANK] SQL Request Update Name: %n, %s, %d", id, szName, g_iPlayerID[id]);

	formatex(szQuery, charsmax(szQuery), SQL_UPDATE_NAME, g_szTablePlayers, szName, g_iPlayerID[id]);
	SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery, cData, sizeof(cData));
}

stock SQL_UpdateIP(id, szNewip[]) {
	new szQuery[512];
	
	new cData[REC_DATA];
	cData[REQUEST] = SQL_IP;
	cData[PLAYER_ID] = id;

	if (g_bDebugMode) server_print("[HNS_RANK] SQL Request Update IP: %n, %s, %d", id, szNewip, g_iPlayerID[id]);

	formatex(szQuery, charsmax(szQuery), SQL_UPDATE_IP, g_szTablePlayers, szNewip, g_iPlayerID[id]);
	SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery, cData, sizeof(cData));
}

stock SQL_UpdatePlayTime(id) {
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;

	new szQuery[512];
	
	new cData[REC_DATA];
	cData[REQUEST] = SQL_PLAYTIME;
	cData[PLAYER_ID] = id;
	
	new iPlaytime = get_user_time(id);

	if (g_bDebugMode) server_print("[HNS_RANK] SQL Request Update Playtime: %n, %d, %d", id, iPlaytime, g_iPlayerID[id]);
	
	formatex(szQuery, charsmax(szQuery), SQL_SET_PLAYTIME, g_szTablePlayers, iPlaytime, g_iPlayerID[id]);
	SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery, cData, sizeof(cData));

	return PLUGIN_HANDLED;
}

stock SQL_UpdateStatsTT(id, iRank, iExp, iWintt, iOwnages, Float:flAvgSurv) {
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;

	new szQuery[512];
	
	new cData[REC_DATA];
	cData[REQUEST] = SQL_STATS_TT;
	cData[PLAYER_ID] = id;

	if (g_bDebugMode) server_print("[HNS_RANK] SQL Request Update Stats TT: %n, %d, %d, %d, %d, %f, %d", id, iRank, iExp, iWintt, iOwnages, flAvgSurv, g_iPlayerID[id]);
	
	formatex(szQuery, charsmax(szQuery), SQL_SET_STATS_TT, g_szTablePlayers, iRank, iExp, iWintt, iOwnages, flAvgSurv, g_iPlayerID[id]);
	SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery, cData, sizeof(cData));

	return PLUGIN_HANDLED;
}

stock SQL_UpdateStatsCT(id, iRank, iExp, iStabs) {
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;

	new szQuery[512];
	
	new cData[REC_DATA];
	cData[REQUEST] = SQL_STATS_CT;
	cData[PLAYER_ID] = id;

	if (g_bDebugMode) server_print("[HNS_RANK] SQL Request Update Stats CT: %n, %d, %d, %d, %d", id, iRank, iExp, iStabs, g_iPlayerID[id]);
	
	formatex(szQuery, charsmax(szQuery), SQL_SET_STATS_CT, g_szTablePlayers, iRank, iExp, iStabs, g_iPlayerID[id]);
	SQL_ThreadQuery(g_hSqlTuple, "QueryHandler", szQuery, cData, sizeof(cData));

	return PLUGIN_HANDLED;
}