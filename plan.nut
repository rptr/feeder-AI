class Plan
{
    stations = null;
    // this just keeps track of which we've already dealt with 
    big_stations = null;

    constructor ()
    {
        this.stations = [];
        this.big_stations = AIList();
    }
}

function Plan::find_stations ()
{
	local all_stations = AIStationList(AIStation.STATION_TRAIN);

	for (local station = all_stations.Begin();
         all_stations.HasNext(); 
         station = all_stations.Next())
    {
        if (is_big_station(station) && 
            !this.big_stations.HasItem(station))
        {
            this.big_stations.AddItem(station, 0);
            local tile_index = AIStation.GetLocation(station);
            this.stations.push(Station(tile_index));
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
