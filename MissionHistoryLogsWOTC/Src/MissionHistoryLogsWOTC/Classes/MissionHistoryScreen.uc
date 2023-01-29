// This is an Unreal Script

class MissionHistoryScreen extends UIScreen implements(IUISortableScreen);

// I think we can take advantage of localization to override the Screen title and other header names.

/*
enum EMissionHistorySortType
{
	eMissionHistorySortType_MissionName,
	eMissionHistorySortType_Squad,
	eMissionHistorySortType_Date,
	eMissionHistorySortType_Rating,
	eMissionHistorySortType_Rate
};

var EMissionHistorySortType header;

var localized string labels[EMissionHistorySortType.EnumCount]<BoundEnum = EMissionHistorySortType>;

// this is what changes the upper part of the UI to match what was selected in the bottom part.
// This also sets the headers for the upper part of the UI.
// I guess it can pull any params it wants?
simulated function OnSelectedChange(UIList ContainerList, int ItemIndex) {
	local XComOnlineProfileSettings Profile;
	local MissionHistoryLogsDetails Data;

	Profile = `XPROFILESETTINGS;

	Data = MissionHistory_ListItem(ContainerList.GetItem(ItemIndex)).Datum;
	mc.BeginFunctionOp("SetChallengeDetails");
	mc.QueueString("img:///" $ Data.MapImagePath);
	mc.QueueString(Data.MissionLocation);
	mc.QueueString(m_Header_Squad);
	mc.QueueString(Data.QuestGiver);
	mc.QueueString(m_Header_Enemies);
	mc.QueueString(Data.Enemies);
	mc.QueueString(m_Header_Objective);
	mc.QueueString(Data.MissionObjective);

	mc.QueueString(class'UITLEHub'.default.m_VictoryLabel);
	mc.QueueString(string(Profile.Data.HubStats.NumOfflineChallengeVictories));
	mc.QueueString("");

	mc.QueueString(class'UITLEHub'.default.m_HighestScore);
	mc.QueueString(string(Profile.Data.HubStats.OfflineChallengeHighScore));

	mc.QueueString(class'UITLEHub'.default.m_CompletedLabel);
	mc.QueueString(string(Profile.Data.HubStats.OfflineChallengeCompletion.length));

	mc.QueueString("");
	mc.QueueString("");

	mc.EndOp();

}

// carve out this function for three reasons
// 1. If an entry is clicked, we don't want to accidentally open a random challenge
// 2. If an entry is clicked, don't want to accidentally cause a crash
// 3. If we decide that we want to do something after an entry is clicked, the function we need is ready to go.
simulated function OnChallengeClicked(UIList ContainerList, int ListItemIndex) {
	local TDialogueBoxData DialogData;
	local MissionHistoryLogsDetails Data;
	local String StrDetails;

	Data = MissionHistory_ListItem(ContainerList.GetItem(ListItemIndex)).Datum;
	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = Data.MissionName;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	StrDetails = "Troops Deployed:"@Data.NumSoldiersDeployed;
	StrDetails = StrDetails $ "\nTroops Injured:"@Data.NumSoldiersInjured;
	StrDetails = StrDetails $ "\nTroops MIA:" @ Data.NumSoldiersMIA;
	StrDetails = StrDetails $ "\nTroops Killed:" @ Data.NumSoldiersKilled;
	StrDetails = StrDetails $ "\nOn Map:" @ Data.MapName;
	if (Data.Enemies != "Advent") {
		StrDetails = StrDetails $ "\nAgainst Chosen:" @ Data.Enemies;
		StrDetails = StrDetails $ "\n"$Data.ChosenName;
		StrDetails = StrDetails $ "\nNumber of times XCOM has encountered this chosen"@Data.NumChosenEncounters;
		StrDetails = StrDetails $ "\nXCOM's win rate against this chosen"@(Data.WinPercentageAgainstChosen*100)$"%";
	} else {
		StrDetails = StrDetails $ "\nAgainst:" @ Data.Enemies;
	}
	StrDetails = StrDetails $ "\nWith a force level of"@Data.ForceLevel;
	StrDetails = StrDetails $ "\nSoldier MVP:" @ Data.SoldierMVP;
	if (Data.bIsVIPMission) {
		if (Data.VIP == "" && Data.SoldierVIPOne == "" && Data.SoldierVIPTwo == "") {
		StrDetails = StrDetails $ "\nAll Agents died in the recovery attempt";
	} else {
		if (Data.VIP != "") StrDetails = StrDetails $ "\nVIP Rescued:"@Data.VIP;
		if (Data.SoldierVIPOne != "" && Data.SoldierVIPTwo != "") { StrDetails = StrDetails $ "\nAgents Rescued:" @Data.SoldierVIPOne@Data.SoldierVIPTwo;}
		else if (Data.SoldierVIPOne != "") {StrDetails = StrDetails $ "\nAgent Rescued:"@Data.SoldierVIPOne;}
		else if (Data.SoldierVIPTwo != "") {StrDetails = StrDetails $ "\nAgent Rescued:"@Data.SoldierVIPTwo;}
	}
	}
	DialogData.strText = StrDetails;
	DialogData.strImagePath = class'UIUtilities_Image'.static.ValidateImagePath(Data.ObjectiveImagePath);

	Movie.Pres.UIRaiseDialog( DialogData );

}

// need to override the following 3 functions to use our config array and struct definition
simulated function UpdateList() {
	local int SelIdx, ItemIndex;
	local XComGameState_MissionHistoryLogs Logs;
	Logs = XComGameState_MissionHistoryLogs(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_MissionHistoryLogs', true));
	
	SelIdx = List.SelectedIndex;
	
	for( ItemIndex = 0; ItemIndex < Logs.TableData.Length; ItemIndex++ )
	{
		MissionHistory_ListItem(List.GetItem(ItemIndex)).RefreshHistory(Logs.TableData[ItemIndex]);
	}

	// Always select first option if using controller (and last selection is invalid)
	// bsg-dforrest (5.16.17): also reset the index if above the list size, this can happen with delete
	if( (SelIdx < 0 || SelIdx >= List.itemCount) && List.itemCount > 0 && `ISCONTROLLERACTIVE)
	   // bsg-dforrest (5.16.17): end
	{
		SelIdx = 0;
	}

	List.SetSelectedIndex(SelIdx);
	List.Navigator.SetSelected(List.GetItem(SelIdx));

	Navigator.SetSelected(List);

}

private function BuildListItems(){
	local int i;
	local XComGameState_MissionHistoryLogs Logs;
	`log("Our BuildListItems function");
	Logs = XComGameState_MissionHistoryLogs(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_MissionHistoryLogs', true));
	for( i= 0; i < Logs.TableData.Length; i++ )
	{
		Spawn(class'MissionHistory_ListItem', List.itemContainer).InitPanel();
	}

}

function LoadFinished()
{
	Movie.Pres.UICloseProgressDialog();

	BuildListItems();

	RefreshData();

	Navigator.SetSelected(List);
	List.Navigator.SelectFirstAvailable();

	NavHelp = GetNavHelp();
	UpdateNavHelp();
}

function int GetSortType() {
	return header;
}

function SetSortType(int eSortType)
{
	header = EMissionHistorySortType(eSortType);
	SortData();
}
// we do need to override sort
function SortData()
{
	local XComGameState_MissionHistoryLogs Logs;
	Logs = XComGameState_MissionHistoryLogs(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_MissionHistoryLogs', true));
	switch( header )
	{
	// Operation Name
	case eMissionHistorySortType_MissionName: Logs.TableData.Sort(SortByMission);	break;
	case eMissionHistorySortType_Squad:	 Logs.TableData.Sort(SortByTeam);	break;
	case eMissionHistorySortType_Date:		 Logs.TableData.Sort(SortByDate);			break;
	case eMissionHistorySortType_Rating:		 Logs.TableData.Sort(SortByRating);		break;
	case eMissionHistorySortType_Rate:	 Logs.TableData.Sort(SortByRate);		break;
	}
	
	UpdateList();
}

simulated function int SortByMission(MissionHistoryLogsDetails A, MissionHistoryLogsDetails B)
{
	return SortAlphabetically(A.MissionName, B.MissionName);
}
simulated function int SortByTeam(MissionHistoryLogsDetails A, MissionHistoryLogsDetails B)
{
	return SortAlphabetically(A.SquadName, B.SquadName);
}
simulated function int SortByDate(MissionHistoryLogsDetails A, MissionHistoryLogsDetails B) {
	return SortRawDate(A.RawDate, B.RawDate);
}
simulated function int SortByRating(MissionHistoryLogsDetails A, MissionHistoryLogsDetails B) {
	return SortAlphabetically(A.MissionRating, B.MissionRating);
}
simulated function int SortByRate(MissionHistoryLogsDetails A, MissionHistoryLogsDetails B) {
	return SortAlphabetically(A.SuccessRate, B.SuccessRate);
}
simulated function int SortByEntryIndex(MissionHistoryLogsDetails A, MissionHistoryLogsDetails B)
{
	local string first, second;
	first = string(A.EntryIndex);
	second = string(B.EntryIndex);
	return SortAlphabetically(first, second);
}

// Important: sorting is the same its just the params that matter. Create a sort function for ints, or can we cast an int to a string for values that are ints.

simulated function int SortAlphabetically(string A, string B)
{
	if( A < B )
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if( A > B )
	{
		return m_bFlipSort ? 1 : -1;
	}
	else // Names match
	{
		return 0;
	}
}

simulated function int SortRawDate(TDateTime A, TDateTime B) {

	if (class 'X2StrategyGameRulesetDataStructures'.static.LessThan(A, B)) {
		return m_bFlipSort ? -1 : 1;
	}
	else if (class 'X2StrategyGameRulesetDataStructures'.static.LessThan(B, A)) {
		return m_bFlipSort ? 1 : -1;
	}
	else 
	{
		return 0;
	}
}


// This is where we can find the labels for the bottom half of the UI

simulated function BuildHeaders()
{
	Spawn(class'UIFlipSortButton', self).InitFlipSortButton("Header0",
															eMissionHistorySortType_MissionName,
															labels[eMissionHistorySortType_MissionName]);
	Spawn(class'UIFlipSortButton', self).InitFlipSortButton("Header1",
															eMissionHistorySortType_Squad,
															labels[eMissionHistorySortType_Squad]);
	Spawn(class'UIFlipSortButton', self).InitFlipSortButton("Header2",
															eMissionHistorySortType_Date,
															labels[eMissionHistorySortType_Date]);
	Spawn(class'UIFlipSortButton', self).InitFlipSortButton("Header3",
															eMissionHistorySortType_Rating,
															labels[eMissionHistorySortType_Rating]);
	Spawn(class'UIFlipSortButton', self).InitFlipSortButton("Header4",
															eMissionHistorySortType_Rate,
															labels[eMissionHistorySortType_Rate]);
	
}


state LoadingItems
{
Begin:
	LoadFinished();
}

*/

var UIList MemorialList;
var UINavigationHelp NavHelp;
var MissionHistory_ListItem LastHighlighted;

var UIPanel m_kDeceasedSortHeader;

// these are set in UIFlipSortButton
var bool m_bFlipSort;

enum EGMemorialSort_Type
{
	eGM_SortMissionName,
	eGM_SortSquad,
	eGM_SortDate,
	eGM_SortRating,
	eGM_SortRate
};

var EGMemorialSort_Type m_eSortType;


delegate int SortDelegate(MissionHistory_ListItem A, MissionHistory_ListItem B);

simulated function InitMemorial()
{
	MemorialList = Spawn(class'UIList', self);
	//MemorialList.InitList('ListGlobalMemorial', 96, 96, 1280, 740,, true);
	MemorialList.bIsNavigable = true;
	MemorialList.InitList('listAnchor', , , 961, 780);
	MemorialList.bStickyHighlight = false;
	MemorialList.OnItemClicked = OnDeceasedSelected;
	
	CreateSortHeaders();
	PopulateData();
	SortData();

	MC.FunctionString("SetScreenHeader", "Mission History Log");

	NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();
	NavHelp.AddBackButton(OnCancel);
}

simulated function CreateSortHeaders()
{
	m_kDeceasedSortHeader = Spawn(class'UIPanel', self);
	m_kDeceasedSortHeader.bIsNavigable = false;
	m_kDeceasedSortHeader.InitPanel('deceasedSort', 'DeceasedSortHeader');
	m_kDeceasedSortHeader.Hide();

	Spawn(class'UIPanel', self).InitPanel('soldierSort', 'SoldierSortHeader').Hide();
	
	Spawn(class'UIPanel', self).InitPanel('personnelSort', 'PersonnelSortHeader').Hide();

	Spawn(class'UIFlipSortButton', m_kDeceasedSortHeader).InitFlipSortButton("nameButton", eGM_SortMissionName, "Operation Name");
	Spawn(class'UIFlipSortButton', m_kDeceasedSortHeader).InitFlipSortButton("killsButton", eGM_SortSquad, "Squad");
	Spawn(class'UIFlipSortButton', m_kDeceasedSortHeader).InitFlipSortButton("missionsButton", eGM_SortDate, "Date");
	Spawn(class'UIFlipSortButton', m_kDeceasedSortHeader).InitFlipSortButton("operationButton", eGM_SortRating, "Rating");
	Spawn(class'UIFlipSortButton', m_kDeceasedSortHeader).InitFlipSortButton("dateButton", eGM_SortRate, "Current Success Rate");
	m_kDeceasedSortHeader.Show();
}

simulated function OnCancel()
{
	Movie.Stack.PopFirstInstanceOfClass(class'MissionHistoryScreen');

	Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local TDialogueBoxData DialogData;

	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;
		
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			break; 
		case class'UIUtilities_Input'.const.FXS_KEY_F:
		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
			`log("F",,'GlobalMemorialScreen');
			DialogData.eType = eDialog_Normal;
			DialogData.strTitle = "Memorial";
			DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
				
			DialogData.strText = "Respect paid";

			Movie.Pres.UIRaiseDialog( DialogData );
			break;
	}

	return super.OnUnrealCommand(cmd, arg);
}

// Check the TLE version if it does something similar.
simulated function PopulateData()
{
	local int ItemIndex;
	local XComGameState_MissionHistoryLogs Logs;
	Logs = XComGameState_MissionHistoryLogs(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_MissionHistoryLogs', true));
	
	for( ItemIndex = 0; ItemIndex < Logs.TableData.Length; ItemIndex++ )
	{
		MissionHistory_ListItem(MemorialList.CreateItem(class'MissionHistory_ListItem')).RefreshHistory(Logs.TableData[ItemIndex]);
	}
	MemorialList.RealizeItems();

	MC.FunctionString("SetEmptyLabel", Logs.TableData.Length == 0 ? "No missions recorded" : "");

}

simulated function ChangeSelection(UIList ContainerList, int ItemIndex)
{
	if (LastHighlighted != none)
		LastHighlighted.SetHighlighted(false);
	LastHighlighted = MissionHistory_ListItem(MemorialList.GetSelectedItem());
	LastHighlighted.SetHighlighted(true);
}

simulated function OnItemMouseEvent(UIPanel ListItem, int cmd)
{
	local int i;
	local MissionHistory_ListItem icon;

	for (i = 0; i < MemorialList.ItemCount; i++)
	{
		icon = MissionHistory_ListItem(MemorialList.GetItem(i));
		if (ListItem == icon)  
		{
			switch (cmd)
			{
				case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
					OpenMemorialDetail(icon);
					icon.SetHighlighted(false);
					break;
				case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
					icon.SetHighlighted(true);
					break;
				case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
				case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
					icon.SetHighlighted(false);
					break;

			}
		}
	}
}

simulated function OnDeceasedSelected( UIList kList, int index )
{
	if( !MissionHistory_ListItem(kList.GetItem(index)).IsDisabled )
	{
		OpenMemorialDetail(MissionHistory_ListItem(kList.GetItem(index)));
	}
}

simulated function OpenMemorialDetail(MissionHistory_ListItem icon)
{
	local TDialogueBoxData DialogData;
	local MissionHistoryLogsDetails Data;
	local String StrDetails;

	Data = icon.Datum;
	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = Data.MissionName;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	StrDetails = "Objective:"@Data.MissionObjective;
	StrDetails = StrDetails $ "Intel received from"@Data.QuestGiver;
	StrDetails = StrDetails $ "Troops Deployed:"@Data.NumSoldiersDeployed;
	StrDetails = StrDetails $ "\nTroops Injured:"@Data.NumSoldiersInjured;
	StrDetails = StrDetails $ "\nTroops MIA:" @ Data.NumSoldiersMIA;
	StrDetails = StrDetails $ "\nTroops Killed:" @ Data.NumSoldiersKilled;
	StrDetails = StrDetails $ "At"@Data.MissionLocation;
	StrDetails = StrDetails $ "\nOn Map:" @ Data.MapName;
	if (Data.Enemies != "Advent") {
		StrDetails = StrDetails $ "\nAgainst Chosen:" @ Data.Enemies;
		StrDetails = StrDetails $ "\n"$Data.ChosenName;
		StrDetails = StrDetails $ "\nNumber of times XCOM has encountered this chosen"@Data.NumChosenEncounters;
		StrDetails = StrDetails $ "\nXCOM's win rate against this chosen"@(Data.WinPercentageAgainstChosen*100)$"%";
	} else {
		StrDetails = StrDetails $ "\nAgainst:" @ Data.Enemies;
	}
	StrDetails = StrDetails $ "\nWith a force level of"@Data.ForceLevel;
	StrDetails = StrDetails $ "\nSoldier MVP:" @ Data.SoldierMVP;
	if (Data.bIsVIPMission) {
		if (Data.VIP == "" && Data.SoldierVIPOne == "" && Data.SoldierVIPTwo == "") {
		StrDetails = StrDetails $ "\nAll Agents died in the recovery attempt";
		} 
		else {
			if (Data.VIP != "") StrDetails = StrDetails $ "\nVIP Rescued:"@Data.VIP;
			if (Data.SoldierVIPOne != "" && Data.SoldierVIPTwo != "") { StrDetails = StrDetails $ "\nAgents Rescued:" @Data.SoldierVIPOne@Data.SoldierVIPTwo;}
			else if (Data.SoldierVIPOne != "") {StrDetails = StrDetails $ "\nAgent Rescued:"@Data.SoldierVIPOne;}
			else if (Data.SoldierVIPTwo != "") {StrDetails = StrDetails $ "\nAgent Rescued:"@Data.SoldierVIPTwo;}
		}
	}
	DialogData.strText = StrDetails;
	DialogData.strImagePath = class'UIUtilities_Image'.static.ValidateImagePath("img:///"$Data.MapImagePath);
	// DialogData.strImagePath = class'UIUtilities_Image'.static.ValidateImagePath(Data.ObjectiveImagePath); // this ui does not allow two images
	Movie.Pres.UIRaiseDialog( DialogData );
}

//FlipSort
function bool GetFlipSort()
{
	return m_bFlipSort;
}
function int GetSortType()
{
	return int(m_eSortType);
}
function SetFlipSort(bool bFlip)
{
	m_bFlipSort = bFlip;
}
function SetSortType(int eSortType)
{
	m_eSortType = EGMemorialSort_Type(eSortType);
}

simulated function RefreshData()
{
	SortData();
}

function SortData()
{
	local int i;
	local array<UIPanel> SortButtons;

	switch( m_eSortType )
	{
		case eGM_SortMissionName:
			SortCurrentData(SortByOp);
			break;
		case eGM_SortSquad:
			SortCurrentData(SortBySquad);
			break;
		case eGM_SortDate:
			SortCurrentData(SortByDate);
			break;
		case eGM_SortRating:
			SortCurrentData(SortByRating);
			break;
		case eGM_SortRate:
			SortCurrentData(SortByRate);
			break;
	}

	// Realize sort buttons
	m_kDeceasedSortHeader.GetChildrenOfType(class'UIFlipSortButton', SortButtons);
	for(i = 0; i < SortButtons.Length; ++i)
	{
		UIFlipSortButton(SortButtons[i]).RealizeSortOrder();
	}
}

simulated function SortCurrentData(delegate<SortDelegate> SortFunction)
{
	local array<MissionHistory_ListItem> NewOrder;
	local int i;

	for (i = 0; i < MemorialList.ItemCount; i++)
	{
		NewOrder.AddItem( MissionHistory_ListItem(MemorialList.GetItem(i)) );
	}

	NewOrder.Sort(SortFunction);

	
	for (i = 0; i < NewOrder.Length; i++)
	{
		MemorialList.MoveItemToBottom(NewOrder[i]);
	}
	MemorialList.RealizeItems();
}


simulated function int SortByOp(MissionHistory_ListItem A, MissionHistory_ListItem B)
{
	local string ValA, ValB;

	ValA = A.Datum.MissionName;
	ValB = B.Datum.MissionName;
	if (ValA < ValB)
		return m_bFlipSort ? -1 : 1;
	else if( ValA > ValB )
		return m_bFlipSort ? 1 : -1;
	return 0;
}

simulated function int SortBySquad(MissionHistory_ListItem A, MissionHistory_ListItem B)
{
	local string ValA, ValB;

	ValA = A.Datum.SquadName;
	ValB = B.Datum.SquadName;

	if (ValA > ValB)
		return m_bFlipSort ? -1 : 1;
	else if( ValA < ValB )
		return m_bFlipSort ? 1 : -1;
	return 0;
}

simulated function int SortByDate(MissionHistory_ListItem A, MissionHistory_ListItem B)
{
	local TDateTime ValA, ValB;

	ValA = A.Datum.RawDate;
	ValB = B.Datum.RawDate;

	if (class 'X2StrategyGameRulesetDataStructures'.static.LessThan(ValA, ValB))
		return m_bFlipSort ? -1 : 1;
	else if(class 'X2StrategyGameRulesetDataStructures'.static.LessThan(ValB, ValA))
		return m_bFlipSort ? 1 : -1;
	return 0;
}

simulated function int SortByRating(MissionHistory_ListItem A, MissionHistory_ListItem B)
{
	local string ValA, ValB;

	ValA = A.Datum.MissionRating;
	ValB = B.Datum.MissionRating;

	if (ValA > ValB)
		return m_bFlipSort ? -1 : 1;
	else if( ValA < ValB )
		return m_bFlipSort ? 1 : -1;
	return 0;
}

simulated function int SortByRate(MissionHistory_ListItem A, MissionHistory_ListItem B)
{
	local string ValA, ValB;

	ValA = A.Datum.SuccessRate;
	ValB = B.Datum.SuccessRate;

	if (ValA > ValB)
		return m_bFlipSort ? -1 : 1;
	else if( ValA < ValB )
		return m_bFlipSort ? 1 : -1;
	return 0;
}

simulated function int SortByEntryIndex(MissionHistory_ListItem A, MissionHistory_ListItem B) {
	local int ValA, ValB;

	ValA = A.Datum.EntryIndex;
	ValB = B.Datum.EntryIndex;

	if (ValA > ValB)
		return m_bFlipSort ? -1 : 1;
	else if( ValA < ValB )
		return m_bFlipSort ? 1 : -1;
	return 0;
	
}

defaultproperties
{
	MCName          = "theScreen";
	Package = "/ package/gfxSoldierList/SoldierList";
	bConsumeMouseEvents = true;
	m_eSortType = eGM_SortMissionName;
}