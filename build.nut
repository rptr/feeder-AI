require("world.nut");

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
        local can_build = IsBuildableRectangle(tile,
                                               Rotation.ROT_0,
                                               [0, 0],
                                               [2, platlen + 1],
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

/*
 * ex choochoo
 */
function IsBuildableRectangle(location, rotation, from, to, mustBeFlat)
{
	local coords = RelativeCoordinates(location, rotation);
	local height = AITile.GetMaxHeight(location);
	
	for (local x = from[0]; x < to[0]; x++)
    {
		for (local y = from[1]; y < to[1]; y++)
        {
			local tile = coords.GetTile([x, y]);
			local flat = AITile.GetMaxHeight(tile) == height && AITile.GetMinHeight(tile) == height && AITile.GetMaxHeight(tile) == height;

			if (!AITile.IsBuildable(tile))
            {
				return false;
			}

            if (mustBeFlat && !flat)
            {
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
			
			if (!AITile.IsBuildable(tile) || !flattenable || (mustBeFlat && !flat))
            {
				return false;
			}
		}
	}
	
	return true;
}

function rail_build_depot (tile, front)
{
    // trying to build a depot where one already exists results in AREA_NOT_CLEAR, not ALREADY_BUILT
    tile = GetTile(tile);
    front = GetTile(front);

    if (AIRail.IsRailDepotTile(tile) && 
        AIRail.GetRailDepotFrontTile(tile) == front) 
    {
        return;
    }

    AIRail.BuildRailDepot(tile, front);
    CheckError();
}

function CheckError ()
{
}
