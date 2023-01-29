// This is an Unreal Script

class MissionHistory_ListItem extends UIPersonnel_ListItem dependson(XComGameState_MissionHistoryLogs);

var MissionHistoryLogsDetails Datum;

var UIBGBox BorderBox;

simulated function RefreshHistory(MissionHistoryLogsDetails UpdateData) {
	InitPanel();
	Datum = UpdateData;
	FillTable();
}

simulated function SetHighlighted(bool IsHighlighted)
{
	if (IsHighlighted)
		BorderBox.SetOutline(true, "0x00ffff");
	else
		BorderBox.SetOutline(true, "0x000000");

}

simulated function FillTable() {
	MC.BeginFunctionOp("UpdateData");
	
	MC.QueueString(Datum.MissionName);		// Mission
	MC.QueueString(Datum.SquadName);	// Squad
	MC.QueueString(Datum.Date);			// Date
	MC.QueueString(Datum.MissionRating);				// Rating
	MC.QueueString(Datum.SuccessRate);			// Rate
	
	MC.EndOp();
}

defaultproperties
{
	LibID = "DeceasedListItem";
	height = 40;
}