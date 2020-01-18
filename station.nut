require("world.nut");

class Platform
{
    orientation = null;
    tiles       = null;
}

class Station
{
    id          = null;
    x           = null;
    y           = null;
    platforms   = null;

    constructor (id, x, y)
    {
        this.id         = id;
        this.x          = x;
        this.y          = y;
        this.platforms  = [];
    }
}

function Station::find_platforms ()
{
    this.platforms = [];
    local tiles = AITileList_StationType(this.id, STATION_TRAIN); 

    for (local tile = tiles.Begin(); tiles.HasNext(); tile = tiles.Next())
    {
        local dir = AIRail.GetRailStationDirection(tile);
    }
}

