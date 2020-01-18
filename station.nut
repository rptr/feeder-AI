require("world.nut");

class Platform extends WorldObject
{
    orientation = null;
    tiles       = null;

    constructor (tile_index)
    {
        Debug("Platform::Platform(): new platform");

		WorldObject.constructor(location);
        orientation = AIRail.GetRailStationDirection(tile_index);
        tiles = [tile_index];
    }
}

function Platform::can_attach (tile_index)
{
    local dir = AIRail.GetRailStationDirection(tile_index);

    foreach (i, tile in this.tiles)
    {
        local platform_dir = AIRail.GetRailStationDirection(tile);

        if (rail_tiles_connectable(tile, tile_index, platform_dir) &&
            platform_dir == dir)
        {
            return true;
        }
    }

    return false;
}

function Platform::attach_tile (tile_index)
{
    Debug("Platform::attach_tile(): attach new tile");

    this.tiles.push(tile_index);
}

class Station extends WorldObject
{
    station_id  = null;
    platforms   = null;

    constructor (id)
    {
        if (!AIStation.IsValidStation(id))
        {
            Debug("Station::Station(): not valid station id", id);
            return;
        }

        Debug("new station at tile index", location);

        local location = AIStation.GetLocation(id);

		WorldObject.constructor(location);
        this.station_id = id;
        this.platforms  = [];
       
        this.find_platforms(); 
    }
}

function Station::get_attachable_platform (tile_index)
{
    foreach (i, platform in this.platforms)
    {
        if (platform.can_attach(tile_index))
        {
            return platform;
        }
    }

    return null;
}

function Station::find_platforms ()
{
    Debug("Station::find platforms()");

    this.platforms = [];
    local tiles = AITileList_StationType(this.station_id, 
                                         AIStation.STATION_TRAIN); 

    for (local tile = tiles.Begin(); 
         tiles.HasNext(); 
         tile = tiles.Next())
    {
        local existing = this.get_attachable_platform(tile)

        if (existing == null)
        {
            this.platforms.push(Platform(tile));
        }
        else
        {
            existing.attach_tile(tile);
        }
    }

    Debug("found", this.platforms.len(), "platforms");
}

