require("world.nut");
require("tiles.nut");

class EntranceTile extends WorldObject
{
    tile_index      = null;
    direction       = null;

    constructor (tile, dir)
    {
        tile_index  = tile;
        direction   = dir;
    }
}

class Platform extends WorldObject
{
    orientation     = null;
    tiles           = null;
    entrance_tiles  = null;
    length          = null;
    attached        = null;

    constructor (tile_index)
    {
        Debug("Platform::Platform(): new platform");

		WorldObject.constructor(location);
        orientation     = AIRail.GetRailStationDirection(tile_index);
        tiles           = [tile_index];
        entrance_tiles  = [];
        length          = 1;
        attached        = 0;
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

    local temp = [];

    foreach (i, tile in tiles)
    {
        local tile_indices = railstation_get_free_connectable_tiles(tile);
        temp.extend(tile_indices);
    }

    // EPPPE
    // E: entrance, P: platform
    foreach (i, tile in temp)
    {
        local dir = SL.Direction.GetDirectionToTile(tiles[0], tile);
        entrance_tiles.push(EntranceTile(tile, dir));
    }

    Debug("found", entrance_tiles.len(), "entrance tiles");
}

function Platform::reserve ()
{
    attached += 1;
}

function Platform::get_entrance ()
{
    return entrance_tiles[0];
}

class Industry extends WorldObject
{
    industry_id     = null;
    taken           = null;
    skip            = null;

    constructor (id)
    {
        local location = AIStation.GetLocation(id);

        Debug("new industry found at tile index", location);

        if (!AIIndustry.IsValidIndustry(id))
        {
            Warning("Industry::Industry(): not valid industry id", id);
            return;
        }

		WorldObject.constructor(location);
        industry_id = id;
        taken       = false;
        skip        = false;
    }
}

function Industry::reserve ()
{
    taken = true;
}

class Station extends WorldObject
{
    station_id      = null;
    platforms       = null;
    cargo_types     = null;
    industries      = null;

    constructor (id)
    {
        local location = AIStation.GetLocation(id);

        Debug("new station at tile index", location);

        if (!AIStation.IsValidStation(id))
        {
            Warning("Station::Station(): not valid station id", id);
            return;
        }

		WorldObject.constructor(location);
        this.station_id = id;
        industries      = [];

        find_platforms();
        find_industries();
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
    local max_len = FEEDER_PLATFORM_MAX_LENGTH;

    foreach (i, platform in platforms)
    {
        if (platform.attached == 0 && platform.entrance_tiles.len() > 0 &&
            platform.length <= max_len)
        {
            return platforms[i];
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
        platforms[i].calculate_entrance_tiles();
    }

    Info("found", this.platforms.len(), "platforms");
}

// TODO optimise
function Station::get_cargo_types ()
{
    local all_types     = AICargoList();
    local cargo_types   = [];

    foreach (i, cargo in all_types)
    {
        if (AIStation.HasCargoRating(station_id, cargo))
        {
            cargo_types.push(cargo);
        }
    }

    return cargo_types;
}

/*
 * look for relevant industries close to station - for feeding
 */
function Station::find_industries ()
{
    Debug("Station::find_industries()");

    local cargo_types   = SL.Helper.GetRawCargo();
    local station_tile  = AIStation.GetLocation(station_id);
    local max_dist      = FEEDER_MAX_DISTANCE;

    foreach (cargo, _ in cargo_types)
    {
        local all = AIIndustryList_CargoProducing(cargo);

        foreach (industry, v in all)
        {
            local tile_index = AIIndustry.GetLocation(industry);
            local dist = AIMap.DistanceManhattan(station_tile, tile_index);

            if (dist < max_dist)
            {
                industries.push(Industry(industry));
            }
        }
    }

    Info("found", industries.len(), "industries");

    return industries;
}

function Station::get_free_industry ()
{
    Debug("Station::get_free_industry()");

    local found = null;

    foreach (i, industry in industries)
    {
        if (industry.taken || industry.skip) continue;

        found = industry;
        break;
    }

    return found;
}

function Station::recalculate ()
{
}

