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
            Debug("found a new station");

            this.big_stations.AddItem(station, 0);
            this.stations.push(Station(station));
        }
	}
}

function Plan::get_fresh_task ()
{
    if (this.big_stations.Count() == 0)
    {
        return null;
    }

    local station = get_free_feeder_station();

    if (null == station)
    {
        DEBUG("nowhere to feed into");
        return null;
    }

    local task = FeedLine(station);

    return task;
}

function Plan::get_free_feeder_station ()
{
    foreach (i, station in stations)
    {
        local platform  = station.get_free_platform();

        if (platform != null)
        {
            return station;
        }
    }

    return null;
}

function is_big_station (station)
{
    local name = AIStation.GetName(station);

    return true;
    /* return (name.find("BIG") != null); */
}
