/*  SM Franug Attack Delay antiCheat
 *
 *  Copyright (C) 2020 Francisco 'Franc1sco' García
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
 

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define DATA "0.2.4 debug"

public Plugin myinfo = 
{
	name = "SM Franug Attack Delay antiCheat",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

Handle _aWeapons, _aWeaponsDelays;
Handle _aEvents[MAXPLAYERS+1];

char g_sCmdLogPath[256];

enum struct Events
{
	int userid;
	char weapon[64];
	float delay;
}

public void OnPluginStart()
{
	for(int i=0;;i++)
	{
		BuildPath(Path_SM, g_sCmdLogPath, sizeof(g_sCmdLogPath), "logs/franug_attackdelay_%d.log", i);
		if ( !FileExists(g_sCmdLogPath) )
			break;
	}
	
	// Load Translations.
	LoadTranslations("franug_attackdelayac.phrases.txt");
	
	_aWeapons = CreateArray(128);
	_aWeaponsDelays = CreateArray();
	
	//HookEvent("player_hurt",  Event_PlayerHurt);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				OnClientPutInServer(i);
	
}

public void OnMapStart()
{
	LoadKV();
}

public Action Event_PlayerSpawn(Event event, const char[] sName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	ClearArray(_aEvents[client]);
}

/*
public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!IsValidClient(attacker))return;
	
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (victim == attacker)return;
	
	//LogToFileEx(g_sCmdLogPath, "playerhurt 1");
	
	char weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	Format(weapon, sizeof(weapon), "weapon_%s", weapon);
	
	//LogToFileEx(g_sCmdLogPath, "weapon hurt is %s", weapon);
	
	int index = FindStringInArray(_aWeapons, weapon);
	
	if (index == -1)return;
	
	//LogToFileEx(g_sCmdLogPath, "playerhurt 2");
	
	int size = GetArraySize(_aEvents[attacker]);
	
	//LogToFileEx(g_sCmdLogPath, "playerhurt 3");
	
	Events events;
	
	int victimID = GetClientUserId(victim);
	
	//LogToFileEx(g_sCmdLogPath, "playerhurt 4");
	
	if(size > 0)
	{
		for(int i=0;i<size;++i)
		{
			GetArrayArray(_aEvents[attacker], i, events);
			//LogToFileEx(g_sCmdLogPath, "playerhurt 4.1");
			if(victimID == events.userid)
			{
				//LogToFileEx(g_sCmdLogPath, "playerhurt 4.2");
				RemoveFromArray(_aEvents[attacker], i);
				break;
			}
		}
	}
	//LogToFileEx(g_sCmdLogPath, "playerhurt 5");
	
	events.userid = victimID;
	events.weapon = weapon;
	events.delay = GetGameTime() + view_as<float>(GetArrayCell(_aWeaponsDelays, index));
	
	PushArrayArray(_aEvents[attacker], events);
	
	//LogToFileEx(g_sCmdLogPath, "playerhurt 6");
	
	//SetTrieValue(_tDelays[attacker], weapon, GetGameTime()+GetArrayCell(_aWeaponsDelays, index));
	
}
*/

public void OnClientPutInServer(int client)
{
	//_iTarget[client] = 0;
	
	_aEvents[client] = CreateArray(66);
	
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	delete _aEvents[client];
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	LogToFileEx(g_sCmdLogPath, "ontakedamage 0.1");
	
	if (!IsValidClient(attacker) || victim == attacker)return Plugin_Continue;
	
	LogToFileEx(g_sCmdLogPath, "ontakedamage 0.2");
	
	char weapon[64];
	
	if(attacker == inflictor)
	{
		GetClientWeapon(attacker, weapon, sizeof(weapon));
	}
	else
	{
		if(!IsValidEntity(inflictor))return Plugin_Continue;
		
		if(!GetEdictClassname(inflictor, weapon, 64))return Plugin_Continue;
	}
	
	LogToFileEx(g_sCmdLogPath, "ontakedamage 0.3");
	
	LogToFileEx(g_sCmdLogPath, "ontakedamage 1");
	
	LogToFileEx(g_sCmdLogPath, "ontakedamage 2 with weapon %s", weapon);
	
	if(strlen(weapon) < 1)return Plugin_Continue;
	
	int index = FindStringInArray(_aWeapons, weapon);
	
	if (index == -1)return Plugin_Continue;
	
	LogToFileEx(g_sCmdLogPath, "ontakedamage 3");
	
	Events events;
	
	int victimID = GetClientUserId(victim);
	
	int size = GetArraySize(_aEvents[attacker]);
	
	if(size > 0){
	
		LogToFileEx(g_sCmdLogPath, "ontakedamage 4");
		
		LogToFileEx(g_sCmdLogPath, "ontakedamage 4 size %i", size);
		for(int i=0;i<size;++i)
		{
			GetArrayArray(_aEvents[attacker], i, events);
			LogToFileEx(g_sCmdLogPath, "ontakedamage 5");
			LogToFileEx(g_sCmdLogPath, "ontakedamage 5 with userid %i", events.userid);
			
			if(victimID == events.userid)
			{
				LogToFileEx(g_sCmdLogPath, "compared %s with %s",weapon, events.weapon);
				if(StrEqual(weapon, events.weapon))
				{
					LogToFileEx(g_sCmdLogPath, "time is now %f against %f", events.delay, GetGameTime());
					if(GetGameTime()<events.delay)
					{
						LogToFileEx(g_sCmdLogPath, "%L detected with a delay of %f", attacker, events.delay - GetGameTime());
						PrintToChat(attacker, "%T", "DamageBlocked", attacker);
						return Plugin_Handled;
					}
				}
			}
		}
		
		
	}
	
	LogToFileEx(g_sCmdLogPath, "ontakedamage 6");
	
	
	// continue then save data
	
	events.userid = victimID;
	//events.weapon = weapon;
	Format(events.weapon, 64, weapon);
	events.delay = (GetGameTime() + view_as<float>(GetArrayCell(_aWeaponsDelays, index)));
	
	PushArrayArray(_aEvents[attacker], events);
	
	return Plugin_Continue;
}

public void LoadKV()
{
	char sConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfig, PLATFORM_MAX_PATH, "configs/franug_attackdelay.txt");
	if(!FileExists(sConfig))
	{
		SetFailState("File %s not found", sConfig);
	}
	
	ClearArray(_aWeapons);
	ClearArray(_aWeaponsDelays);
	
	KeyValues kv = CreateKeyValues("Config");
	FileToKeyValues(kv, sConfig);

	char temp[128];
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetSectionName(kv, temp, 128);
			PushArrayString(_aWeapons, temp);
			PushArrayCell(_aWeaponsDelays, view_as<float>(KvGetFloat(kv, "delay")));
			
			LogToFileEx(g_sCmdLogPath, "weapon %s saved with %f delay", temp, view_as<float>(KvGetFloat(kv, "delay")));
			
			
			
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);
	
	delete kv;
	
}

stock bool IsValidClient( int client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}