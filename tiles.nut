
class Const
{
    static cardinal_tiles = [[-1, 0], 
                             [1, 0], 
                             [0, -1], 
                             [0, 1]];
}

/*
 * coords: [x, y]
 * returns int
 */
function coords_to_tile_index (coords)
{
    return AIMap.GetTileIndex(coords[0], coords[1]);
}

/* TODO this could maybe be optimised, don't know what AIMap.* call
* tile_index + map_width etc
*/
/*
 * coords: [x, y]
 * returns a new tile_index with the coords added (int)
 */
function tile_index_add_coords (tile_index, coords)
{
    local x = AIMap.GetTileX(tile_index);
    local y = AIMap.GetTileY(tile_index);

    return AIMap.GetTileIndex(x + coords[0], y + coords[1]);
}

/*
 * direction: AIRail::RailTrack
 * only NE_SW or NW_SE (TODO)
 * returns bool
 */
function railstation_tiles_connectable (tile_index_1, tile_index_2, direction)
{
    local x1 = AIMap.GetTileX(tile_index_1);
    local y1 = AIMap.GetTileY(tile_index_1);
    local x2 = AIMap.GetTileX(tile_index_2);
    local y2 = AIMap.GetTileY(tile_index_2);

    return (AIRail.RAILTRACK_NW_SE == direction && x2 == x1 
            && (y1 == y2 + 1 || y1 == y2 - 1))
            ||
           (AIRail.RAILTRACK_NE_SW == direction && y2 == y1 
            && (x1 == x2 + 1 || x1 == x2 - 1));
}

/*
 * checks tiles adjacent to tile_index to see if they can access it
 * returns array of tiles
 */
function railstation_get_free_connectable_tiles (tile_index)
{
    local dir = AIRail.GetRailStationDirection(tile_index);
    local tiles = [];
    
    foreach (i, cardinal in Const.cardinal_tiles)
    {
        local index = tile_index_add_coords(tile_index, cardinal);

        if (!AIMap.IsValidTile(index)) continue;

        if (!railstation_tiles_connectable(tile_index, index, dir)) continue;

        if (!AITile.IsBuildable(index)) continue;

        tiles.push(index);
    }

    return tiles;
}

