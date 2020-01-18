require("world.nut");
require("tiles.nut");

class Platform extends WorldObject
{
    orientation     = null;
    tiles           = null;
    entrance_tiles  = null;
    length          = null;

    constructor (tile_index)
    {
        Debug("Platform::Platform(): new platform");

		WorldObject.constructor(location);
        orientation     = AIRail.GetRailStationDirection(tile_index);
        tiles           = [tile_index];
        entrance_tiles  = [];
        length          = 1;
    }
}

function Platform::can_attach (tile_index)
{
    local dir = AIRail.GetRailStationDirection(tile_index);

    foreach (i, tile in this.tiles)
    {
        local platform_dir = AIRail.GetRailStationDirection(tile);

        if (railstation_tiles_connectable(tile, tile_index, platform_dir) &&
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

    length += 1;

    this.tiles.push(tile_index);
}

function Platform::calculate_entrance_tiles ()
{
    Debug("Platform::calculate_entrance_tiles()");

    foreach (i, tile in tiles)
    {
        local entrance = railstation_get_free_connectable_tiles(tile);
        entrance_tiles.extend(entrance);
    }

    Debug("found", entrance_tiles.len(), "entrance tiles");
}

class Station extends WorldObject
{
    station_id  = null;
    platforms   = null;

    constructor (id)
    {
        Debug("new station at tile index", location);

        if (!AIStation.IsValidStation(id))
        {
            Debug("Station::Station(): not valid station id", id);
            return;
        }

        local location = AIStation.GetLocation(id);

		WorldObject.constructor(location);
        this.station_id = id;

        recalculate(); 
    }
}

/*
 * returns a platform that `tile_index` can attach to
 */
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

/* 
 *returns a platform with free entrance tiles
 */
function Station::get_free_platform ()
{
    foreach (i, platform in platforms)
    {
        if (platform.entrance_tiles.len() > 0)
        {
            return platform;
        }
    }

    return null
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

    foreach (i, platform in platforms)
    {
        platform.calculate_entrance_tiles();
    }

    Debug("found", this.platforms.len(), "platforms");
}

// re-runs all the platform detection stuff
function Station::recalculate ()
{
    platforms  = [];
    find_platforms(); 
}
