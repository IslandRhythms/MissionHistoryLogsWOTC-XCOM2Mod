// This is an Unreal Script

class MissionHistory_ListItem extends UIPersonnel_ListItem dependson(XComGameState_MissionHistoryLogs);

var MissionHistoryLogsDetails Datum;

var UIBGBox BorderBox;

simulated function MissionHistory_ListItem RefreshHistory(MissionHistoryLogsDetails UpdateData) {
	InitPanel();
	Datum = UpdateData;
	FillTable();
	return self;
}

simulated function SetHighlighted(bool IsHighlighted)
{
	if (IsHighlighted)
		BorderBox.SetOutline(true, "0x00ffff");
	else
		BorderBox.SetOutline(true, "0x000000");

}

simulated function FillTable() {
	local string shorten;
	MC.BeginFunctionOp("UpdateData");
	
	MC.QueueString(Datum.MissionName);	// Mission
	if (Len(Datum.SquadName) > 11) {
		shorten = Left(Datum.SquadName, 11);
		MC.QueueString(shorten); // Squad
	} else {
		MC.QueueString(Datum.SquadName);	// Squad
	}
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