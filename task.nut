import("pathfinder.rail", "RailPathFinder", 1);

require("util.nut");
require("build.nut");

class Task
{
    subtasks = null;

    constructor ()
    {
        subtasks = [];
    }

    function _tostring ()
    {
        return "task";
    }

    function run ()
    {
    }
}

class LongLine extends Task
{
	function _tostring()
    {
		return "longline";
	}
	
	function run ()
    {
        Debug("building a longline");
		/* for (local i = 0; i < AIController.GetSetting("CargoLines"); i++) { */
		/* 	tasks.push(BuildCargoLine()); */
		/* } */
	}
}

class TaskFeedLine extends Task
{
    big_station = null;

    constructor (big_station)
    {
        Task.constructor();
        this.big_station = big_station;
    }

	function _tostring()
    {
		return "feedline";
	}
}

function TaskFeedLine::run ()
{
    Debug("building feedline for ", big_station);

    local platform = big_station.get_free_platform();

    if (null == platform)
    {
        Debug("station has no free platform after all");
        return TaskReturnState.ERROR;
    }

    local station_id = big_station.station_id;
    local tiles = platform.entrance_tiles;
    local target_tile_index = tiles[0];

    local cargoes = big_station.get_cargo_types();

    // TEMP
    local all_cargo = AICargoList();

    foreach (cc in [AICargo.CC_PASSENGERS, AICargo.CC_MAIL, AICargo.CC_EXPRESS])
    {
        all_cargo.Valuate(AICargo.HasCargoClass, cc);
        all_cargo.KeepValue(0);
    }

    all_cargo.Begin();
    while (all_cargo.HasNext())
        cargoes.push(all_cargo.Next());

    if (cargoes.len() == 0)
    {
        Debug("station has no cargo rating");
        return TaskReturnState.ERROR;
    }

    local industries = AIList();

    foreach (i, cargo in cargoes)
    {
        industries.AddList(AIIndustryList_CargoProducing(cargo));
        Debug("found", industries.Count(), "industries");
    }

    Debug("found", industries.Count(), "industries");

    if (industries.Count() == 0)
    {
        Debug("no available industries");
        return TaskReturnState.ERROR;
    }

    // TODO pick the best one
    local industry_id = industries.Begin();

    local source_tile_index = find_industry_station_site(industry_id);

    if (source_tile_index == null)
    {
        Debug("no available industries");
        return TaskReturnState.ERROR;
    }

    local dir = SL.Direction.DIR_NE;
    local dir2 = SL.Direction.DIR_NE;

    subtasks = 
        [
        TaskBuildFeedStation(source_tile_index),
        TaskBuildTrack(source_tile_index, dir,
                       target_tile_index, dir2)
        ];

    // make it so it doesn't have free tiles anymore
    big_station.connect(target_tile_index);

    return TaskReturnState.HAVE_SUBTASKS;
}

/*
 *
 */
class TaskBuildFeedStation extends Task
{
    entrance_tile_index = null;

    constructor (entrance_tile_index)
    {
        Debug("build feed station @", entrance_tile_index);

        Task.constructor();
        this.entrance_tile_index = entrance_tile_index;
    }

	function _tostring()
    {
		return "buildfeedstation";
	}
}

function TaskBuildFeedStation::run ()
{
    local new_id;
    local platlen   = FEEDER_PLATFORM_MAX_LENGTH;
    local direction = AIRail.RAILTRACK_NE_SW;

	AIRail.BuildRailStation(entrance_tile_index, 
                            direction, 
                            1, 
                            platlen, 
                            AIStation.STATION_NEW);
    new_id = AIStation.GetStationID(entrance_tile_index);
    Feeder.plan.register_station(new_id);

    return TaskReturnState.DONE;
}

/*
 * source_id: tile_index of source station entrance tile
 * source_direction: the direction (NE/NW/SE/SW) the station points
 */
class TaskBuildTrack extends Task
{
    source_tile_id = null;
    target_tile_id = null;
    source_direction = null;
    target_direction = null;

    constructor (source_id, source_direction, 
                 target_id, target_direction)
    {
        Debug("build track between points [",
              source_id,
              "] and [",
              target_id,
              "]");

        Task.constructor();
        source_tile_id = source_id;
        target_tile_id = target_id;
        this.source_direction = source_direction;
        this.target_direction = target_direction;
    }

	function _tostring()
    {
		return "buildtrack";
	}
}

function TaskBuildTrack::run ()
{
    Debug("TaskBuildTrack::run()");

    local path;
    local dir1 = SL.Direction.OppositeDir(source_direction);
    local prev1 = SL.Direction.GetAdjacentTileInDirection(
        source_tile_id, dir1);
    local source = 
    [
        source_tile_id,
        prev1
    ];
    local dir2 = SL.Direction.OppositeDir(target_direction);
    local prev2 = SL.Direction.GetAdjacentTileInDirection(
        target_tile_id, dir2);
    local target =
    [
        target_tile_id,
        prev2
    ];

    Debug("find path", source, target);

    Feeder.pathfinder.InitializePath([source], [target]);
    path = Feeder.pathfinder.FindPath(2000);

    if (path == null)
    {
        Debug("can't find path");
        return TaskReturnState.ERROR;
    }

    local prev = null;
    local prevprev = null;

    while (path != null)
    {
        if (prevprev != null)
        {
            if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1)
            {
                // TODO tunnel/ bridge
                prevprev = prev;
                prev = path.GetTile();
                path = path.GetParent();
            }
            else
            {
                if (!AIRail.BuildRail(prevprev, prev, path.GetTile()))
                {
                    Debug("can't place rail");
                    return TaskReturnState.ERROR;
                }
            }
        }

        if (path != null)
        {
            prevprev = prev;
            prev = path.GetTile();
            path = path.GetParent();
        }
    }

    return TaskReturnState.DONE;
}











