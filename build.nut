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
	
	for (local tile = area.Begin();
         area.HasNext();
         tile = area.Next())
    {
        local can_build = 
            is_buildable_rectangle(tile,
                                   stationRotation,
                                   [0, -1],
                                   [1, CARGO_STATION_LENGTH + 1],
                                   true);
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

function is_buildable_rectangle (location, 
                                 orientation, 
                                 from, 
                                 to, 
                                 mustBeFlat)
{
	// check if the area is clear and flat
	local coords = RelativeCoordinates(location, rotation);
	local height = AITile.GetMaxHeight(location);
	
	for (local x = from[0]; x < to[0]; x++)
    {
		for (local y = from[1]; y < to[1]; y++)
        {
			local tile = coords.GetTile([x, y]);
			local flat = AITile.GetMaxHeight(tile) == height && AITile.GetMinHeight(tile) == height && AITile.GetMaxHeight(tile) == height;
			if (!AITile.IsBuildable(tile) || (mustBeFlat && !flat)) {
				return false;
			}
			
			local area = AITileList();
			SafeAddRectangle(area, tile, 1);
			area.Valuate(AITile.GetMinHeight);
			area.KeepAboveValue(height - 2);
			area.Valuate(AITile.GetMaxHeight);
			area.KeepBelowValue(height + 2);
			area.Valuate(AITile.IsBuildable);
			area.KeepValue(1);
			
			local flattenable = (
				area.Count() == 9 &&
				abs(AITile.GetMinHeight(tile) - height) <= 1 &&
				abs(AITile.GetMaxHeight(tile) - height) <= 1);
			
			if (!AITile.IsBuildable(tile) || !flattenable || (mustBeFlat && !flat)) {
				return false;
			}
		}
	}
	
	return true;
}
