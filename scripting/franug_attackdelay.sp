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

#define DATA "0.1"

public Plugin myinfo = 
{
	name = "SM Franug Attack Delay antiCheat",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

Handle _aWeapons, _aWeaponsDelays;
Handle _tDelays[MAXPLAYERS+1];

int _iTarget[MAXPLAYERS + 1];

public void OnPluginStart()
{
	_aWeapons = CreateArray(128);
	_aWeaponsDelays = CreateArray();
	
	HookEvent("player_hurt",  Event_PlayerHurt);
	
	for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				OnClientPutInServer(i);
	
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!IsValidClient(attacker))return;
	
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (victim == attacker)return;
	
	_iTarget[attacker] = victim;
	
	char weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	int index = FindStringInArray(_aWeapons, weapon);
	
	if(index != -1)
		SetTrieValue(_tDelays[attacker], weapon, GetGameTime()+GetArrayCell(_aWeaponsDelays, index));
	
}

public void OnClientPutInServer(int client)
{
	_iTarget[client] = 0;
	
	_tDelays[client] = CreateTrie();
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	delete _tDelays[client];
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!IsValidClient(attacker) || victim == attacker)return Plugin_Continue;
	
	if(_iTarget[attacker] != victim)return Plugin_Continue;
	
	if(!IsValidEntity(weapon))return Plugin_Continue;
	
	char sweapon[64];
	
	if(!GetEdictClassname(weapon, sweapon, 64))return Plugin_Continue;
	
	int index;
	
	//int index = FindStringInArray(_aWeapons, weapon);
	
	//if(index == -1)return Plugin_Continue;
	
	if (!GetTrieValue(_tDelays[attacker], sweapon, index))return Plugin_Continue;
	
	if(index <= GetGameTime())
	{
		PrintToChat(attacker, "[AttackDelay-AC] Damage blocked");
		return Plugin_Handled;
	}
	
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
	
	KeyValues kv = CreateKeyValues("Config");
	FileToKeyValues(kv, sConfig);

	char temp[128];
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetSectionName(kv, temp, 128);
			PushArrayString(_aWeapons, temp);
			PushArrayCell(_aWeaponsDelays, KvGetFloat(kv, "delay"));
			
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