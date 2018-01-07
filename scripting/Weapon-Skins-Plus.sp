/* Weapon Skins+
 *
 * Copyright (C) 2017-2018 Oscar Wos // github.com/OSCAR-WOS | theoscar@protonmail.com
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see http://www.gnu.org/licenses/.
 */

// Compiler Info: Pawn 1.8 - build 6040

#define PLUGIN_PREFIX "\x01[\x07WS++\x01]"
#define SQL_PREFIX "[WeaponSkins] SQL Error"
#define MENU_PREFIX "WeaponSkins++"
#define PLUGIN_VERSION "1.03"
#define GROUP_ID 111

//CREATE TABLE IF NOT EXISTS `weapons` (steamid VARCHAR(64) NOT NULL, weaponslot INT(4) NOT NULL, value INT(4) NOT NULL, PRIMARY KEY (`steamid`, `weaponslot`));
//CREATE TABLE IF NOT EXISTS `skins` (steamid VARCHAR(64) NOT NULL, weaponid INT(4) NOT NULL, skinid INT(4) NOT NULL, seed INT(4) NOT NULL, wear INT(4) NOT NULL, stattrak INT(4) NOT NULL, name VARCHAR(64) NOT NULL, PRIMARY KEY (`steamid`, `weaponid`));

#include <sourcemod>
#include <smlib>
#include <sdkhooks>
#include <SteamWorks>

enum {
	ITEMSLOT_PRIMARY,
	ITEMSLOT_SECONDARY,
	ITEMSLOT_KNIFE,
}

ArrayList gA_Items[5];
ArrayList gA_SqlQueries;

Database gD_Main;

bool gB_Authorised[MAXPLAYERS + 1];
bool gB_JustJoined[MAXPLAYERS + 1];

int gI_TotalItems;
int gI_PlayerItems[MAXPLAYERS + 1][34];
int gI_PlayerKnife[MAXPLAYERS + 1];

char gC_SelectedWeapon[MAXPLAYERS + 1][512];
char gC_PlayerSteamId[MAXPLAYERS + 1][64];

int gI_SelectedSearch[MAXPLAYERS + 1];
int gI_IndepthSelectedSearch[MAXPLAYERS + 1];

int gI_KnifeIndexes[12][2];

public Plugin myinfo = {
	name = "Weapon Skins++",
	author = "Oscar Wos (OSWO)",
	description = "WeaponSkins++",
	version = PLUGIN_VERSION,
	url = "",
};

char gC_Knives[][][] = {
	{"42", "Default CT", "models/weapons/v_knife_default_ct.mdl", "models/weapons/w_knife_default_ct.mdl"},
	{"59", "Default T", "models/weapons/v_knife_default_t.mdl", "models/weapons/w_knife_default_t.mdl"},
	{"500", "Bayonet Knife", "models/weapons/v_knife_bayonet.mdl", "models/weapons/w_knife_bayonet.mdl"},
	{"505", "Flip Knife", "models/weapons/v_knife_flip.mdl", "models/weapons/w_knife_flip.mdl"},
	{"506", "Gut Knife", "models/weapons/v_knife_gut.mdl", "models/weapons/w_knife_gut.mdl"},
	{"507", "Karambit Knife", "models/weapons/v_knife_karam.mdl", "models/weapons/w_knife_karam.mdl"},
	{"508", "M9 Bayonet Knife", "models/weapons/v_knife_m9_bay.mdl", "models/weapons/w_knife_m9_bay.mdl"},
	{"509", "Huntsman Knife", "models/weapons/v_knife_tactical.mdl", "models/weapons/w_knife_tactical.mdl"},
	{"512", "Falchion Knife", "models/weapons/v_knife_falchion_advanced.mdl", "models/weapons/w_knife_falchion_advanced.mdl"},
	{"514", "Bowie Knife", "models/weapons/v_knife_survival_bowie.mdl", "models/weapons/w_knife_survival_bowie.mdl"},
	{"515", "Butterfly Knife", "models/weapons/v_knife_butterfly.mdl", "models/weapons/w_knife_butterfly.mdl"},
	{"516", "Shaddow Daggers", "models/weapons/v_knife_push.mdl", "models/weapons/w_knife_push.mdl"},
}

char gC_Weapons[][][] = {
	{"weapon_knife", "Knife", "2", "0"},
	{"weapon_ak47", "AK-47", "0", "7"},
	{"weapon_aug", "AUG", "0", "8"},
	{"weapon_awp", "AWP", "0", "9"},
	{"weapon_bizon", "PP-Bizon", "0", "26"},
	{"weapon_cz75a", "CZ-75 Auto", "1", "63"},
	{"weapon_deagle", "Desert Eagle", "1", "1"},
	{"weapon_elite", "Dual Berettas", "1", "2"},
	{"weapon_famas", "FAMAS", "0", "10"},
	{"weapon_fiveseven", "Five-SeveN", "1", "3"},
	{"weapon_g3sg1", "G3SG1", "0", "11"},
	{"weapon_galilar", "Galil AR", "0", "13"},
	{"weapon_glock", "Glock-18", "1", "4"},
	{"weapon_hkp2000", "P2000", "1", "32"},
	{"weapon_m249", "M249", "0", "14"},
	{"weapon_m4a1", "M4A4", "0", "16"},
	{"weapon_m4a1_silencer", "M4A1-S", "0", "60"},
	{"weapon_mac10", "MAC-10", "0", "17"},
	{"weapon_mag7", "MAG-7", "0", "27"},
	{"weapon_mp7", "MP7", "0", "33"},
	{"weapon_mp9", "MP9", "0", "34"},
	{"weapon_negev", "Negev", "0", "28"},
	{"weapon_nova", "Nova", "0", "35"},
	{"weapon_p250", "P250", "1", "36"},
	{"weapon_p90", "P90", "0", "19"},
	{"weapon_sawedoff", "Sawed-Off", "0", "29"},
	{"weapon_scar20", "SCAR-20", "0", "38"},
	{"weapon_sg556", "SG 553", "0", "39"},
	{"weapon_ssg08", "SSG 08", "0", "40"},
	{"weapon_tec9", "Tec-9", "1", "30"},
	{"weapon_ump45", "UMP-45", "0", "24"},
	{"weapon_usp_silencer", "USP-S", "1", "61"},
	{"weapon_xm1014", "XM1014", "0", "25"},
	{"weapon_revolver", "R8 Revolver", "1", "64"},
}

char gC_Cases[][][] = {
	{"case_csgo_1", "CS:GO Weapon Case"},
	{"case_csgo_2", "CS:GO Weapon Case 2"},
	{"case_csgo_3", "CS:GO Weapon Case 3"},
	{"case_chroma_1", "Chroma Case"},
	{"case_chroma_2", "Chroma Case 2"},
	{"case_chroma_3", "Chroma Case 3"},
	{"case_esports", "eSports 2013 Case"},
	{"case_esports_winter", "eSports 2013 Winter Case"},
	{"case_esports_summer", "eSports 2014 Summer Case"},
	{"case_falchion", "Falchion Case"},
	{"case_gamma_1", "Gamma Case"},
	{"case_gamma_2", "Gamma 2 Case"},
	{"case_glove", "Glove Case"},
	{"case_huntsman", "Huntsman Weapon Case"},
	{"case_bravo", "Operation Bravo Case"},
	{"case_breakout", "Operation Breakout Case"},
	{"case_phoenix", "Operation Phoenix Case"},
	{"case_vanguard", "Operation Vanguard Case"},
	{"case_wildfire", "Operation Wildfire Case"},
	{"case_revolver", "Revolver Case"},
	{"case_shadow", "Shadow Case"},
	{"case_winter", "Winter Offensive Weapon Case"},
	{"collection_alpha", "Alpha Collection"},
	{"collection_assault", "Assault Collection"},
	{"collection_aztec", "Aztec Collection"},
	{"collection_baggage", "Baggage Collection"},
	{"collection_bank", "Bank Collection"},
	{"collection_cache", "Cache Collection"},
	{"collection_chopshop", "Chop Shop Collection"},
	{"collection_cobblestone", "Cobblestone Collection"},
	{"collection_dust", "Dust Collection"},
	{"collection_dust2", "Dust 2 Collection"},
	{"collection_gods", "Gods and Monsters Collection"},
	{"collection_inferno", "Inferno Collection"},
	{"collection_italy", "Italy Collection"},
	{"collection_lake", "Lake Collection"},
	{"collection_militia", "Militia Collection"},
	{"collection_mirage", "Mirage Collection"},
	{"collection_nuke", "Nuke Collection"},
	{"collection_office", "Office Collection"},
	{"collection_overpass", "Overpass Collection"},
	{"collection_sun", "Rising Sun Collection"},
	{"collection_safehouse", "Safehouse Collection"},
	{"collection_train", "Train Collection"},
	{"collection_vertigo", "Vertigo Collection"},
}

char gC_Rarity[][][] = {
	{"rarity_white", "Consumer (White)"},
	{"rarity_lightblue", "Industrial (Light Blue)"},
	{"rarity_darkblue", "Mil-Spec (Dark Blue)"},
	{"rarity_purple", "Restricted (Purple)"},
	{"rarity_pink", "Classified (Pink)"},
	{"rarity_red", "Covert (Red)"},
	{"rarity_brown", "Contraband (Brown)"},
	{"rarity_gold", "Knife (Gold)"}
}

char gC_Array[][][] = {
	{"512", "weapon"},
	{"512", "case"},
	{"8", "skinid"},
	{"512", "rarity"},
	{"64", "skinname"},
}

public void OnPluginStart() {
	sql_DatabaseConnect();
	misc_LoadItems();

	gA_SqlQueries = new ArrayList(512);

	RegConsoleCmd("sm_knife", command_knife);
	RegConsoleCmd("sm_knifes", command_knife);
	RegConsoleCmd("sm_knives", command_knife);

	RegConsoleCmd("sm_ws", command_ws);
	RegConsoleCmd("sm_skins", command_ws);
	RegConsoleCmd("sm_paints", command_ws);

	RegConsoleCmd("sm_guns", command_guns);
	//RegConsoleCmd("sm_test", command_test);

	for (int i = 0; i < MaxClients; i++) {
		if (IsValidClient(i)) {
			OnClientPostAdminCheck(i);
		}
	}

	HookEvent("player_spawn", Hook_PlayerSpawn, EventHookMode_Post);
}

public Action Hook_PlayerSpawn(Event E_Event, char[] C_Name, bool B_DontBroadcast) {
	int I_Client = GetClientOfUserId(E_Event.GetInt("userid"));

	if (IsValidClient(I_Client)) {
		if (gB_JustJoined[I_Client]) {
			PrintToChat(I_Client, "%s Welcome to the Server \x10%N\x01! The server is using \x07WeaponSkins++ \x01Use \x09!knife \x01or \x09!ws", PLUGIN_PREFIX, I_Client);
		}
		//CreateTimer(0.1, Timer_Spawn, I_Client);
	}
}

public Action Timer_Spawn(Handle H_Timer, int I_Client) {
	int I_Weapon = GetPlayerWeaponSlot(I_Client, ITEMSLOT_KNIFE);

	if (I_Weapon > 0) {
		RemovePlayerItem(I_Client, I_Weapon);
		AcceptEntityInput(I_Weapon, "Kill");
	}

	int I_Entity = GivePlayerItem(I_Client, "weapon_knife");
	EquipPlayerWeapon(I_Client, I_Entity);
}

public void OnMapStart() {
	for (int i = 0; i < sizeof(gC_Knives); i++) {
		for (int x = 0; x < 2; x++) {
			gI_KnifeIndexes[i][x] = PrecacheModel(gC_Knives[i][2+x]);
		}
	}
}

public void OnClientPostAdminCheck(int I_Client) {
	misc_ResetPlayer(I_Client);

	GetClientAuthId(I_Client, AuthId_SteamID64, gC_PlayerSteamId[I_Client], 64, false);
	sql_LoadData(I_Client);

	misc_TryVerifyClient(I_Client);

	gB_JustJoined[I_Client] = true;

	SDKHook(I_Client, SDKHook_WeaponEquipPost, Hook_OnPostWeaponEquip);
	SDKHook(I_Client, SDKHook_WeaponEquip, Hook_OnWeaponEquip);
}

public void OnClientDisconnect(int I_Client) {
	char C_buffer[512], C_PlayerId[128];

	GetClientAuthId(I_Client, AuthId_SteamID64, C_PlayerId, sizeof(C_PlayerId), false);

	for (int i = 0; i < sizeof(gC_Weapons); i++) {
		if (gI_PlayerItems[I_Client][i] > 1) {
			Format(C_buffer, sizeof(C_buffer), "INSERT INTO `skins` VALUES ('%s', '%s', '%i', '0', '0', '0', '0') ON DUPLICATE KEY UPDATE skinid = '%i'", C_PlayerId, gC_Weapons[i][0], gI_PlayerItems[I_Client][i], gI_PlayerItems[I_Client][i]);
			gA_SqlQueries.PushString(C_buffer);
		}
	}

	if (gI_PlayerKnife[I_Client] != 0) {
		Format(C_buffer, sizeof(C_buffer), "INSERT INTO `weapons` VALUES ('%s', '%i', '%i') ON DUPLICATE KEY UPDATE value = '%i'", C_PlayerId, ITEMSLOT_KNIFE, gI_PlayerKnife[I_Client], gI_PlayerKnife[I_Client]);
		gA_SqlQueries.PushString(C_buffer);
	}

	misc_ResetPlayer(I_Client);
	SDKUnhook(I_Client, SDKHook_WeaponEquipPost, Hook_OnPostWeaponEquip);
	SDKUnhook(I_Client, SDKHook_WeaponEquip, Hook_OnWeaponEquip);
}

public void misc_ResetPlayer(int I_Client) {
	for (int i = 0; i < 33; i++) {
		gI_PlayerItems[I_Client][i] = -1;
	}

	gI_PlayerKnife[I_Client] = 0;

	gB_Authorised[I_Client] = false;
	gB_JustJoined[I_Client] = false;
	Format(gC_PlayerSteamId[I_Client], 512, "");

	misc_ResetTemp(I_Client);
}

public void misc_ResetTemp(int I_Client) {
	Format(gC_SelectedWeapon[I_Client], 512, "");

	gI_SelectedSearch[I_Client] = -1;
	gI_IndepthSelectedSearch[I_Client] = -1;
}

public void misc_LoadItems() {
	char C_buffer[512], C_Path[512];

	gI_TotalItems = 0;

	for (int i = 0; i < 5; i++) {
		delete gA_Items[i];
		gA_Items[i] = new ArrayList(StringToInt(gC_Array[i][0]));
	}

	BuildPath(Path_SM, C_Path, 512, "configs/WeaponSkins.cfg");

	KeyValues K_Skins = new KeyValues("WeaponSkins");
	K_Skins.ImportFromFile(C_Path);

	K_Skins.JumpToKey("WeaponSkins");
	K_Skins.GotoFirstSubKey();

	do {
		for (int i = 0; i < 5; i++) {
			gA_Items[i].Resize(gI_TotalItems + 1);
			K_Skins.GetString(gC_Array[i][1], C_buffer, sizeof(C_buffer));

			gA_Items[i].SetString(gI_TotalItems, C_buffer);
		}

		gI_TotalItems++;
	} while (K_Skins.GotoNextKey())

	delete K_Skins;
}

public void sql_DatabaseConnect() {
	char C_Error[512];

	gD_Main = SQL_Connect("WeaponSkins", true, C_Error, 512);

	if (gD_Main == INVALID_HANDLE) {
		CloseHandle(gD_Main);
		SetFailState("%s - (Connect) - %s", SQL_PREFIX, C_Error);
	}

	CreateTimer(0.1, Timer_SqlQueries, _, TIMER_REPEAT);
}

public void sql_LoadData(int I_Client) {
	char C_buffer[512];

	Transaction T_Trans = SQL_CreateTransaction();

	Format(C_buffer, sizeof(C_buffer), "SELECT * FROM `skins` WHERE steamid = '%s'", gC_PlayerSteamId[I_Client]);
	T_Trans.AddQuery(C_buffer);

	Format(C_buffer, sizeof(C_buffer), "SELECT * FROM `weapons` WHERE steamid = '%s'", gC_PlayerSteamId[I_Client]);
	T_Trans.AddQuery(C_buffer);

	SQL_ExecuteTransaction(gD_Main, T_Trans, sqlLoadDataCallbackSuccess, sqlLoadDataCallbackError, GetClientUserId(I_Client), DBPrio_High);
}

public void sqlLoadDataCallbackSuccess(Database D_Database, int I_UserId, int I_Queries, Handle[] H_Results, any[] A_QueryData) {
	int I_Client = GetClientOfUserId(I_UserId);

	if (IsValidClient(I_Client)) {
		while (SQL_FetchRow(H_Results[0])) {
			char C_WeaponName[32];
			int I_SkinId, I_Slot;

			SQL_FetchString(H_Results[0], 1, C_WeaponName, sizeof(C_WeaponName));
			I_Slot = misc_WeaponNameToIndex(C_WeaponName);
			I_SkinId = SQL_FetchInt(H_Results[0], 2);

			gI_PlayerItems[I_Client][I_Slot] = I_SkinId;
		}

		while (SQL_FetchRow(H_Results[1])) {
			int I_WeaponSlot, I_Value;

			I_WeaponSlot = SQL_FetchInt(H_Results[1], 1);
			I_Value = SQL_FetchInt(H_Results[1], 2);

			if (I_WeaponSlot == ITEMSLOT_KNIFE) {
				gI_PlayerKnife[I_Client] = I_Value;
			}
		}
	}
}

public void sqlLoadDataCallbackError(Database D_Database, any A_Data, int I_Queries, char[] C_Error, int I_FailIndex, any[] A_QueryData) {

}

public Action Timer_SqlQueries(Handle H_Timer) {
	if (gA_SqlQueries.Length > 0) {
		char C_buffer[512];
		Transaction T_Trans = SQL_CreateTransaction();

		for (int i = 0; i < gA_SqlQueries.Length; i++) {
			gA_SqlQueries.GetString(i, C_buffer, sizeof(C_buffer));
			T_Trans.AddQuery(C_buffer);
		}

		SQL_ExecuteTransaction(gD_Main, T_Trans, sqlQueriesSuccess, sqlQueriesError, DBPrio_Normal);

		delete gA_SqlQueries;
		gA_SqlQueries = new ArrayList(512);
	}
}

public void sqlQueriesSuccess(Database D_Database, any A_Data, int I_Queries, Handle[] H_Results, any[] A_QueryData) {
}

public void sqlQueriesError(Database D_Database, any A_Data, int I_Queries, char[] C_Error, int I_FailIndex, any[] A_QueryData) {
}

public Action command_knife(int I_Client, int I_Args) {
	menu_Knife(I_Client, 0);

	/*
	if (IsPlayerAlive(I_Client)) {
		int I_Weapon = GetPlayerWeaponSlot(I_Client, 2);

		if (I_Weapon == -1) {
			int I_Entity = GivePlayerItem(I_Client, "weapon_knife");
			EquipPlayerWeapon(I_Client, I_Entity);
		}
	}
	*/

	return Plugin_Handled;
}

public void menu_Knife(int I_Client, int I_DisplayAt) {
	char C_buffer[512];
	Menu M_Menu = new Menu(KnifeHandle);

	Format(C_buffer, 512, "%s - Knife\n", MENU_PREFIX);
	Format(C_buffer, 512, "%s \n", C_buffer);
	M_Menu.SetTitle(C_buffer);

	for (int i = 0; i < sizeof(gC_Knives); i++) {
		if (gI_PlayerKnife[I_Client] == StringToInt(gC_Knives[i][0])) {
			Format(C_buffer, sizeof(C_buffer), "%s (Equipped)", gC_Knives[i][1]);
			M_Menu.AddItem(C_buffer, C_buffer, ITEMDRAW_DISABLED);
		} else {
			M_Menu.AddItem(gC_Knives[i][1], gC_Knives[i][1]);
		}
	}

	M_Menu.DisplayAt(I_Client, I_DisplayAt, 0);
}

public int KnifeHandle(Menu M_Menu, MenuAction mA_Action, int I_Param1, int I_Param2) {
	if (mA_Action == MenuAction_Select) {
		int I_Temp = RoundToFloor(float(I_Param2) / 6.0) * 6;
		int I_Weapon = GetPlayerWeaponSlot(I_Param1, 2);

		gI_PlayerKnife[I_Param1] = StringToInt(gC_Knives[I_Param2][0]);

		if (I_Weapon > 0) {
			RemovePlayerItem(I_Param1, I_Weapon);
			AcceptEntityInput(I_Weapon, "Kill");
		}

		if (IsPlayerAlive(I_Param1)) {
			int I_Entity = GivePlayerItem(I_Param1, "weapon_knife");
			EquipPlayerWeapon(I_Param1, I_Entity);
		}

		menu_Knife(I_Param1, I_Temp);
	}
}

public Action command_ws(int I_Client, int I_Args) {
	if (gB_Authorised[I_Client]) {
		menu_Main(I_Client);
	} else {
		misc_TryVerifyClient(I_Client);
	}

	return Plugin_Handled;
}

public Action command_guns(int I_Client, int I_Args) {
	menu_Guns(I_Client, 0);
	return Plugin_Handled;
}

public void misc_TryVerifyClient(int I_Client) {
	SteamWorks_GetUserGroupStatus(I_Client, GROUP_ID);
}

public SteamWorks_OnClientGroupStatus(int I_AuthId, int I_GroupId, bool B_IsMember, bool B_IsOfficer) {
	int I_Client = misc_GetClientFromSteamId(I_AuthId);

	if (I_Client) {
		if (B_IsMember) {
			if (!gB_Authorised[I_Client]) {
				gB_Authorised[I_Client] = true;

				if (!gB_JustJoined[I_Client]) {
					PrintToChat(I_Client, "%s \x06Authorised! \x01Enjoy!", PLUGIN_PREFIX);
					menu_Main(I_Client);
				}
			}
		} else {
			if (!gB_JustJoined[I_Client]) {
				PrintToChat(I_Client, "%s You need to be apart of SteamGroup! YOUR GROUP URL", PLUGIN_PREFIX);
				OpenMOTD(I_Client, "YOUR GROUP URL");
			}
		}
	}

	gB_JustJoined[I_Client] = false;
}

public void menu_Guns(int I_Client, int I_DisplayAt) {
	char C_buffer[512];
	Menu M_Menu = new Menu(GunsHandle);

	Format(C_buffer, 512, "%s - Guns\n", MENU_PREFIX);
	Format(C_buffer, 512, "%s \n", C_buffer);
	M_Menu.SetTitle(C_buffer);

	for (int i = 0; i < sizeof(gC_Weapons); i++) {
		M_Menu.AddItem(gC_Weapons[i][1], gC_Weapons[i][1]);
	}

	M_Menu.DisplayAt(I_Client, I_DisplayAt, 0);
}

public int GunsHandle(Menu M_Menu, MenuAction mA_Action, int I_Param1, int I_Param2) {
	if (mA_Action == MenuAction_Select) {
		int I_Type = StringToInt(gC_Weapons[I_Param2][2]);
		int I_Weapon = GetPlayerWeaponSlot(I_Param1, I_Type);
		int I_Temp = RoundToFloor(float(I_Param2) / 6.0) * 6;

		if (I_Weapon > 0) {
			RemovePlayerItem(I_Param1, I_Weapon);
			AcceptEntityInput(I_Weapon, "Kill");
		}

		if (IsPlayerAlive(I_Param1)) {
			int I_Entity = GivePlayerItem(I_Param1, gC_Weapons[I_Param2][0]);

			if (GetPlayerWeaponSlot(I_Param1, I_Type) == -1) {
				EquipPlayerWeapon(I_Param1, I_Entity);
			}
		}

		menu_Guns(I_Param1, I_Temp);
	}
}

public void menu_Main(int I_Client) {
	char C_buffer[512];
	Menu M_Menu = new Menu(MainHandle);

	misc_ResetTemp(I_Client);

	Format(C_buffer, 512, "%s - Main Menu\n", MENU_PREFIX);
	Format(C_buffer, 512, "%s \n", C_buffer);
	M_Menu.SetTitle(C_buffer);

	Format(C_buffer, 512, "Use Active Weapon");
	M_Menu.AddItem(C_buffer, C_buffer);

	Format(C_buffer, 512, "Select Weapon");
	M_Menu.AddItem(C_buffer, C_buffer);

	M_Menu.Display(I_Client, 0);
}

public int MainHandle(Menu M_Menu, MenuAction mA_Action, int I_Param1, int I_Param2) {
	if (mA_Action == MenuAction_Select) {
		switch (I_Param2) {
			case 0: {
				int I_Weapon = GetEntPropEnt(I_Param1, Prop_Data, "m_hActiveWeapon");

				if (IsValidEntity(I_Weapon)) {
					char C_Classname[512];

					GetEdictClassname(I_Weapon, C_Classname, sizeof(C_Classname))
					if (StrContains(C_Classname, "weapon_knife") == 0 || StrContains(C_Classname, "weapon_bayonet") == 0) {
						Format(gC_SelectedWeapon[I_Param1], 512, "weapon_knife");
					} else {
						int I_Definition = GetEntProp(I_Weapon, Prop_Send, "m_iItemDefinitionIndex");

						for (int i = 0; i < sizeof(gC_Weapons); i++) {
							if (I_Definition == StringToInt(gC_Weapons[i][3])) {
								Format(gC_SelectedWeapon[I_Param1], 512, gC_Weapons[i][0]);
								break;
							}
						}
					}

					menu_SelectedWeapon(I_Param1);
				} else {
					PrintToChat(I_Param1, "%s Invalid Weapon!", PLUGIN_PREFIX);
					menu_Main(I_Param1);
				}
			} case 1: {
				menu_SelectWeapon(I_Param1);
			}
		}
	}
}

public void menu_SelectWeapon(int I_Client) {
	char C_buffer[512];
	Menu M_Menu = new Menu(SelectWeaponHandle);

	Format(C_buffer, 512, "%s - Select Weapon\n", MENU_PREFIX);
	Format(C_buffer, 512, "%s \n", C_buffer);
	M_Menu.SetTitle(C_buffer);

	for (int i = 0; i < sizeof(gC_Weapons); i++) {
		M_Menu.AddItem(gC_Weapons[i][1], gC_Weapons[i][1]);
	}

	M_Menu.ExitBackButton = true;
	M_Menu.Display(I_Client, 0);
}

public int SelectWeaponHandle(Menu M_Menu, MenuAction mA_Action, int I_Param1, int I_Param2) {
	if (I_Param2 == MenuCancel_ExitBack) {
		menu_Main(I_Param1);
		return;
	}

	if (mA_Action == MenuAction_Select) {
		Format(gC_SelectedWeapon[I_Param1], 512, "%s", gC_Weapons[I_Param2][0]);
		menu_SelectedWeapon(I_Param1);
	}
}

public void menu_SelectedWeapon(int I_Client) {
	char C_buffer[512], C_SkinName[64];
	Menu M_Menu = new Menu(SelectedWeaponHandle);

	int I_WeaponIndex = misc_WeaponNameToIndex(gC_SelectedWeapon[I_Client]);
	misc_FormatSkinId(gI_PlayerItems[I_Client][I_WeaponIndex], C_SkinName, 64);

	Format(C_buffer, 512, "%s - Selected Weapon\n", MENU_PREFIX);
	Format(C_buffer, 512, "%s \n", C_buffer);
	Format(C_buffer, 512, "%sWeapon: %s\n", C_buffer, gC_SelectedWeapon[I_Client]);
	Format(C_buffer, 512, "%sSkin: %s\n", C_buffer, C_SkinName);
	Format(C_buffer, 512, "%s \n", C_buffer);
	M_Menu.SetTitle(C_buffer);

	Format(C_buffer, 512, "Change Skin");
	M_Menu.AddItem(C_buffer, C_buffer);

	Format(C_buffer, 512, "Change Wear - WIP");
	M_Menu.AddItem(C_buffer, C_buffer, ITEMDRAW_DISABLED);

	Format(C_buffer, 512, "Change Seed - WIP");
	M_Menu.AddItem(C_buffer, C_buffer, ITEMDRAW_DISABLED);

	Format(C_buffer, 512, "Change Name - WIP");
	M_Menu.AddItem(C_buffer, C_buffer, ITEMDRAW_DISABLED);

	Format(C_buffer, 512, "Change StatTrack - WIP");
	M_Menu.AddItem(C_buffer, C_buffer, ITEMDRAW_DISABLED);

	M_Menu.ExitBackButton = true;
	M_Menu.Display(I_Client, 0);
}

public int SelectedWeaponHandle(Menu M_Menu, MenuAction mA_Action, int I_Param1, int I_Param2) {
	if (I_Param2 == MenuCancel_ExitBack) {
		menu_Main(I_Param1);
		return;
	}

	if (mA_Action == MenuAction_Select) {
		menu_Search(I_Param1);
	}
}

public void menu_Search(int I_Client) {
	char C_buffer[512];
	Menu M_Menu = new Menu(SearchHandle);
	ArrayList A_ArrayList;

	switch (gI_SelectedSearch[I_Client]) {
		case -1: {
			Format(C_buffer, 512, "%s - Change Skin\n", MENU_PREFIX);
			Format(C_buffer, 512, "%s \n", C_buffer);
			Format(C_buffer, 512, "%sSearch By:\n", C_buffer);
			Format(C_buffer, 512, "%s \n", C_buffer);
			M_Menu.SetTitle(C_buffer);

			Format(C_buffer, 512, "Weapon");
			M_Menu.AddItem(C_buffer, C_buffer);

			Format(C_buffer, 512, "Case");
			M_Menu.AddItem(C_buffer, C_buffer);

			Format(C_buffer, 512, "Rarity");
			M_Menu.AddItem(C_buffer, C_buffer);

			Format(C_buffer, 512, "List all Skins");
			M_Menu.AddItem(C_buffer, C_buffer, ITEMDRAW_DISABLED);
		} case 0: {
			Format(C_buffer, 512, "%s - Change Skin - Weapon\n", MENU_PREFIX);
			Format(C_buffer, 512, "%s \n", C_buffer);
			M_Menu.SetTitle(C_buffer);

			for (int i = 0; i < sizeof(gC_Weapons); i++) {
				A_ArrayList = misc_ReturnArrayList(0, gC_Weapons[i][0]);

				Format(C_buffer, 512, "%s (%i)", gC_Weapons[i][1], A_ArrayList.Length);
				M_Menu.AddItem(C_buffer, C_buffer, (A_ArrayList.Length > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED));
			}
		} case 1: {
			Format(C_buffer, 512, "%s - Change Skin - Case\n", MENU_PREFIX);
			Format(C_buffer, 512, "%s \n", C_buffer);
			M_Menu.SetTitle(C_buffer);

			for (int i = 0; i < sizeof(gC_Cases); i++) {
				A_ArrayList = misc_ReturnArrayList(1, gC_Cases[i][0]);

				Format(C_buffer, 512, "%s (%i)", gC_Cases[i][1], A_ArrayList.Length);
				M_Menu.AddItem(C_buffer, C_buffer, (A_ArrayList.Length > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED));
			}
		} case 2: {
			Format(C_buffer, 512, "%s - Change Skin - Rarity\n", MENU_PREFIX);
			Format(C_buffer, 512, "%s \n", C_buffer);
			M_Menu.SetTitle(C_buffer);

			for (int i = 0; i < sizeof(gC_Rarity); i++) {
				A_ArrayList = misc_ReturnArrayList(2, gC_Rarity[i][0]);

				Format(C_buffer, 512, "%s (%i)", gC_Rarity[i][1], A_ArrayList.Length);
				M_Menu.AddItem(C_buffer, C_buffer, (A_ArrayList.Length > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED));
			}
		} case 3: {
			Format(C_buffer, 512, "%s - Change Skin - All Skins\n", MENU_PREFIX);
			Format(C_buffer, 512, "%s \n", C_buffer);
			M_Menu.SetTitle(C_buffer);

			for (int i = 0; i < gA_Items[0].Length; i++) {
				gA_Items[4].GetString(i, C_buffer, sizeof(C_buffer));

				M_Menu.AddItem(C_buffer, C_buffer);
			}
		}
	}

	delete A_ArrayList;

	M_Menu.ExitBackButton = true;
	M_Menu.Display(I_Client, 0);
}

public int SearchHandle(Menu M_Menu, MenuAction mA_Action, int I_Param1, int I_Param2) {
	if (I_Param2 == MenuCancel_ExitBack) {
		if (gI_SelectedSearch[I_Param1] != -1) {
			gI_SelectedSearch[I_Param1] = -1;
			menu_Search(I_Param1);
		} else {
			menu_SelectedWeapon(I_Param1);
		}

		return;
	}

	if (mA_Action == MenuAction_Select) {
		switch (gI_SelectedSearch[I_Param1]) {
			case -1: {
				gI_SelectedSearch[I_Param1] = I_Param2;
				menu_Search(I_Param1);
			} default: {
				gI_IndepthSelectedSearch[I_Param1] = I_Param2;
				menu_IndepthSearch(I_Param1, 0);
			}
		}
	}
}

public void menu_IndepthSearch(int I_Client, int I_DisplayAt) {
	char C_buffer[512];
	Menu M_Menu = new Menu(IndepthSearchHandle);
	ArrayList A_ArrayList = new ArrayList();

	switch (gI_SelectedSearch[I_Client]) {
		case 0: {
			A_ArrayList = misc_ReturnArrayList(0, gC_Weapons[gI_IndepthSelectedSearch[I_Client]][0]);
			Format(C_buffer, 512, "%s - Change Skin - Weapon\n", MENU_PREFIX);
		} case 1: {
			A_ArrayList = misc_ReturnArrayList(1, gC_Cases[gI_IndepthSelectedSearch[I_Client]][0]);
			Format(C_buffer, 512, "%s - Change Skin - Case\n", MENU_PREFIX);
		} case 2: {
			A_ArrayList = misc_ReturnArrayList(2, gC_Rarity[gI_IndepthSelectedSearch[I_Client]][0]);
			Format(C_buffer, 512, "%s - Change Skin - Rarity\n", MENU_PREFIX);
		}
	}

	Format(C_buffer, 512, "%s \n", C_buffer);
	M_Menu.SetTitle(C_buffer);

	for (int i = 0; i < A_ArrayList.Length; i++) {
		int I_Index = A_ArrayList.Get(i);
		char C_Index[16];

		IntToString(I_Index, C_Index, sizeof(C_Index));
		gA_Items[4].GetString(I_Index, C_buffer, sizeof(C_buffer));

		M_Menu.AddItem(C_Index, C_buffer);
	}

	delete A_ArrayList;

	M_Menu.ExitBackButton = true;
	M_Menu.DisplayAt(I_Client, I_DisplayAt, 0);
}

public int IndepthSearchHandle(Menu M_Menu, MenuAction mA_Action, int I_Param1, int I_Param2) {
	if (I_Param2 == MenuCancel_ExitBack) {
		gI_IndepthSelectedSearch[I_Param1] = -1;
		menu_Search(I_Param1);
		return;
	}

	if (mA_Action == MenuAction_Select) {
		int I_Index, I_SkinId, I_Slot, I_Temp;
		char C_Index[16], C_SkinId[8], C_SkinName[64];

		M_Menu.GetItem(I_Param2, C_Index, sizeof(C_Index));
		I_Index = StringToInt(C_Index);

		gA_Items[2].GetString(I_Index, C_SkinId, sizeof(C_SkinId));
		I_SkinId = StringToInt(C_SkinId);

		gA_Items[4].GetString(I_Index, C_SkinName, sizeof(C_SkinName));
		I_Slot = misc_WeaponNameToIndex(gC_SelectedWeapon[I_Param1]);
		I_Temp = RoundToFloor(float(I_Param2) / 6.0) * 6;

		gI_PlayerItems[I_Param1][I_Slot] = I_SkinId;

		PrintToChat(I_Param1, "%s \"\x10%s\x01\" -> \"\x06%s\x01\"", PLUGIN_PREFIX, gC_Weapons[I_Slot][1], C_SkinName);
		misc_ChangeWeaponSkin(I_Param1, gC_SelectedWeapon[I_Param1]);

		menu_IndepthSearch(I_Param1, I_Temp);
	}
}

public int misc_GetClientFromSteamId(int I_AuthId) {
	for (int i = 1; i < MaxClients; i++) {
		if (IsValidClient(i)) {
			if(GetSteamAccountID(i) == I_AuthId) {
				return i;
			}
		}
	}

	return 0;
}

public int misc_WeaponNameToIndex(char[] C_WeaponName) {
	TrimString(C_WeaponName);

	for (int i = 0; i < sizeof(gC_Weapons); i++) {
		if (StrEqual(gC_Weapons[i][0], C_WeaponName, false)) {
			return i;
		}
	}

	return -1;
}

public int misc_CaseNameToIndex(char[] C_CaseName) {
	TrimString(C_CaseName);

	for (int i = 0; i < sizeof(gC_Cases); i++) {
		if (StrEqual(gC_Cases[i][0], C_CaseName, false)) {
			return i;
		}
	}

	return -1;
}

public int misc_RarityNameToIndex(char[] C_RarityName) {
	TrimString(C_RarityName);

	for (int i = 0; i < sizeof(gC_Rarity); i++) {
		if (StrEqual(gC_Rarity[i][0], C_RarityName, false)) {
			return i;
		}
	}

	return -1;
}

public void misc_FormatSkinId(int I_SkinId, char[] C_buffer, int I_MaxLength) {
	if (I_SkinId != -1) {
		int I_Index;
		char C_SkinId[8];

		IntToString(I_SkinId, C_SkinId, sizeof(C_SkinId));
		I_Index = gA_Items[2].FindString(C_SkinId);

		if (I_Index != -1) {
			gA_Items[4].GetString(I_Index, C_buffer, I_MaxLength);
		} else {
			Format(C_buffer, I_MaxLength, "Error Skin");
		}
	} else {
		Format(C_buffer, I_MaxLength, "No Skin")
	}
}

public Action Hook_OnPostWeaponEquip(int I_Client, int I_Weapon) {
	if (GetEntProp(I_Weapon, Prop_Send, "m_hPrevOwner") > 0) {
		return;
	}

	misc_PrecheckEntity(I_Client, I_Weapon);
}

public Action Hook_OnWeaponEquip(int I_Client, int I_Weapon) {
	if (GetEntProp(I_Weapon, Prop_Send, "m_hPrevOwner") > 0) {
		return;
	}

	char C_Classname[512];

	if (GetEdictClassname(I_Weapon, C_Classname, sizeof(C_Classname))) {
		if (StrContains(C_Classname, "weapon_knife") >= 0 || StrContains(C_Classname, "weapon_bayonet") >= 0) {
			if (gI_PlayerKnife[I_Client] != 0) {
				SetEntProp(I_Weapon, Prop_Send, "m_iItemDefinitionIndex", gI_PlayerKnife[I_Client]);
				RequestFrame(Request_Knife, I_Weapon);
			}
		}
	}
}

public void Request_Knife(int I_Weapon) {
	int I_KnifeIndex, I_WorldIndex, I_ItemDefinition;

	I_ItemDefinition = GetEntProp(I_Weapon, Prop_Send, "m_iItemDefinitionIndex");
	I_WorldIndex = GetEntPropEnt(I_Weapon, Prop_Send, "m_hWeaponWorldModel");

	for (int i = 0; i < sizeof(gC_Knives); i++) {
		if (I_ItemDefinition == StringToInt(gC_Knives[i][0])) {
			I_KnifeIndex = i;
			break;
		}
	}

	if (IsValidEdict(I_WorldIndex)) {
		SetEntProp(I_WorldIndex, Prop_Send, "m_nModelIndex", gI_KnifeIndexes[I_KnifeIndex][1]);
	}
}

public void misc_PrecheckEntity(int I_Client, int I_Weapon) {
	char C_Classname[512];

	if (GetEdictClassname(I_Weapon, C_Classname, sizeof(C_Classname))) {
		if (StrContains(C_Classname, "weapon_knife") == 0 || StrContains(C_Classname, "weapon_bayonet") == 0) {
			misc_ChangePaint(I_Client, 0, I_Weapon);
		} else {
			int I_Definition = GetEntProp(I_Weapon, Prop_Send, "m_iItemDefinitionIndex");

			for (int i = 1; i < sizeof(gC_Weapons); i++) {
				if (I_Definition == StringToInt(gC_Weapons[i][3])) {
					misc_ChangePaint(I_Client, i, I_Weapon);
					break;
				}
			}
		}
	}
}

public void misc_ChangeWeaponSkin(int I_Client, char[] C_WeaponName) {
	int I_Index = misc_WeaponNameToIndex(C_WeaponName);
	int I_Slot = StringToInt(gC_Weapons[I_Index][2]);

	int I_Weapon = GetPlayerWeaponSlot(I_Client, I_Slot);

	if (I_Weapon > 0) {
		RemovePlayerItem(I_Client, I_Weapon);
		AcceptEntityInput(I_Weapon, "Kill");
	}

	if (IsPlayerAlive(I_Client)) {
		int I_Entity = GivePlayerItem(I_Client, C_WeaponName);

		if (GetPlayerWeaponSlot(I_Client, I_Slot) == -1) {
			EquipPlayerWeapon(I_Client, I_Entity);
		}
	}
}

public void misc_ChangePaint(int I_Client, int I_WeaponIndex, int I_Entity) {
	if (gI_PlayerItems[I_Client][I_WeaponIndex] != -1) {
		SetEntProp(I_Entity, Prop_Send, "m_iItemIDLow", -1);
		SetEntProp(I_Entity, Prop_Send, "m_nFallbackPaintKit", gI_PlayerItems[I_Client][I_WeaponIndex]);

		SetEntPropFloat(I_Entity, Prop_Send,"m_flFallbackWear", 0.01);
	}
}

public ArrayList misc_ReturnArrayList(int I_Type, char[] C_Parameter) {
	ArrayList A_ArrayList = new ArrayList();
	ArrayList A_UsedList = new ArrayList(512);
	int I_SearchType;

	switch (I_Type) {
		case 0: { //By Weapon Name
			I_SearchType = 0;
		} case 1: { //By Case Name
			I_SearchType = 1;
		} case 2: { //By Rarity
			I_SearchType = 3;
		}
	}

	for (int i = 0; i < gI_TotalItems; i++) {
		char C_buffer[512]

		gA_Items[I_SearchType].GetString(i, C_buffer, 512);

		if (StrContains(C_buffer, ",", false) > 0) {
			char C_SplitString[64][64];
			int I_Explosions = ExplodeString(C_buffer, ",", C_SplitString, 64, 64);

			for (int x = 0; x < I_Explosions; x++) {
				TrimString(C_SplitString[x]);

				if (StrEqual(C_SplitString[x], C_Parameter, false)) {
					gA_Items[4].GetString(i, C_buffer, sizeof(C_buffer));

					if (A_UsedList.FindString(C_buffer) == -1) {
						A_UsedList.PushString(C_buffer);
						A_ArrayList.Push(i);
					}
				}
			}
		} else {
			if (StrEqual(C_buffer, C_Parameter, false)) {
				gA_Items[4].GetString(i, C_buffer, sizeof(C_buffer));

				if (A_UsedList.FindString(C_buffer) == -1) {
					A_UsedList.PushString(C_buffer);
					A_ArrayList.Push(i);
				}
			}
		}
	}

	delete A_UsedList;
	return A_ArrayList;
}

stock bool IsValidClient(int I_Client) {
	if (I_Client >= 1 && (I_Client <= MaxClients) && IsValidEntity(I_Client) && IsClientConnected(I_Client) && IsClientInGame(I_Client) && !IsFakeClient(I_Client)) {
		return true;
	}

	return false;
}

stock void OpenMOTD(int client, char url[500])
{
    char UrlJS[500];
    Format(UrlJS, 500, "javascript: var x = screen.width * 0.90;var y = screen.height * 0.90;window.open(\"%s\", \"Really boomix, JS?\",\"scrollbars=yes, width='+x+',height='+y+'\");", url);
    ShowMOTDPanel(client, "Open HTML MOTD", UrlJS, MOTDPANEL_TYPE_URL );
}
