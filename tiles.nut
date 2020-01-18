
/*
 * direction: AIRail::RailTrack
 * only NE_SW or NW_SE (TODO)
 */
function rail_tiles_connectable (tile_index_1, tile_index_2, direction)
{
    local x1 = AIMap.GetTileX(tile_index_1);
    local y1 = AIMap.GetTileY(tile_index_1);
    local x2 = AIMap.GetTileX(tile_index_2);
    local y2 = AIMap.GetTileY(tile_index_2);

    return (AIRail.RAILTRACK_NE_SW == direction && x2 == x1 
            && (y1 == y2 + 1 || y1 == y2 - 1))
            ||
           (AIRail.RAILTRACK_NW_SE == direction && y2 == y1 
            && (x1 == x2 + 1 || x1 == x2 - 1));
}
