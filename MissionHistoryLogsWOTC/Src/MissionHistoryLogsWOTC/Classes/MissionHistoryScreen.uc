// This is an Unreal Script

class MissionHistoryScreen extends UIScreen implements(IUISortableScreen);

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