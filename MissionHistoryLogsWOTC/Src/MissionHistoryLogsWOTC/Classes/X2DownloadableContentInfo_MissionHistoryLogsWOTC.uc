//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_MissionHistoryLogsWOTC.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_MissionHistoryLogsWOTC extends X2DownloadableContentInfo;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{
	CheckUpdateOrCreateNewGameState();
}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{}

static event OnPostMission() {
	CheckUpdateOrCreateNewGameState();
}

static final function CheckUpdateOrCreateNewGameState()
{
	local XComGameState_MissionHistoryLogs Log;
    local XComGameState NewGameState;
    local XComGameStateHistory History;

    History = `XCOMHISTORY;
    Log = XComGameState_MissionHistoryLogs(History.GetSingleGameStateObjectForClass(class 'XComGameState_MissionHistoryLogs', true));

    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Check, create or Update MissionLogs");

    if (Log == none)
    {
        Log = XComGameState_MissionHistoryLogs(NewGameState.CreateNewStateObject(class'XComGameState_MissionHistoryLogs'));
    }
    else
    {
        Log = XComGameState_MissionHistoryLogs(NewGameState.ModifyStateObject(Log.Class, Log.ObjectID));
    }

    Log.UpdateTableData();

    `GAMERULES.SubmitGameState(NewGameState);
}