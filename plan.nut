class Plan
{
    stations = null;
    big_stations = null;

    constructor ()
    {
        this.big_stations = AIList();
    }
}

function Plan::find_stations ()
{
	this.stations = AIStationList(AIStation.STATION_TRAIN);

	for (local station = this.stations.Begin();
         this.stations.HasNext(); 
         station = this.stations.Next())
    {
        if (is_big_station(station) && 
            !this.big_stations.HasItem(station))
        {
            this.big_stations.AddItem(station, station);
            Debug("found a big station");
        }
	}
}

function Plan::get_task ()
{
    if (this.big_stations.Count() == 0)
    {
        return null;
    }

    local big = this.big_stations.Begin();
    local task = FeedLine(big);

    return task;
}

function is_big_station (station)
{
    local name = AIStation.GetName(station);

    return (name.find("BIG") != null);
}
