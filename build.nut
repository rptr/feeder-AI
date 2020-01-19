const RAIL_STATION_RADIUS = 4;

/*
 * ex choochoo
 * Find a site for a station at the given industry.
 */
function find_industry_station_site (industry)
{
    local radius = RAIL_STATION_RADIUS;
	local location = AIIndustry.GetLocation(industry);
	local area = AITileList_IndustryProducing(industry, radius);
    local platlen = FEEDER_PLATFORM_MAX_LENGTH;
	
	for (local tile = area.Begin();
         area.HasNext();
         tile = area.Next())
    {
        local can_build = SL.Tile.IsTileRectBuildableAndFlat(tile, 1, platlen);
		area.SetValue(tile, can_build ? 1 : 0);
	}
	
	area.KeepValue(1);
	
	// pick the tile farthest from the destination for increased 
    // profit
	/* area.Valuate(AITile.GetDistanceManhattanToTile, destination); */
	/* area.KeepTop(1); */
	
	// pick the tile closest to the industry for looks
	//area.Valuate(AITile.GetDistanceManhattanToTile, location);
	//area.KeepBottom(1);
	
	return area.IsEmpty() ? null : area.Begin();
}

