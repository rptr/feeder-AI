class Plan
{
    stations = null;
}

function Plan::FindStations ()
{
	this.stations = AIStationList(AIStation.STATION_TRAIN);

	for (local station = stations.Begin();
         stations.HasNext(); 
         station = stations.Next())
    {
		towns.RemoveItem(AIStation.GetNearestTown(station));
	}
}
