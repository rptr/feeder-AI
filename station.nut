require("world.nut");

class Platform
{
    orientation = null;
    tiles       = null;
}

class Station extends WorldObject
{
    station_id  = null;
    platforms   = null;

    constructor (location, id)
    {
        Debug("new station at tile index", location);

		WorldObject.constructor(location, rotation);
        this.station_id = id;
        this.platforms  = [];
       
        this.find_platforms(); 
    }
}

function Station::find_platforms ()
{
    Debug("find platforms");

    this.platforms = [];
    local tiles = AITileList_StationType(this.id, STATION_TRAIN); 

    for (local tile = tiles.Begin(); tiles.HasNext(); tile = tiles.Next())
    {
        local dir = AIRail.GetRailStationDirection(tile);
        Debug(dir);
    }
}

