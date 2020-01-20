import("pathfinder.rail", "RailPathFinder", 1);

require("util.nut");
require("world.nut");
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
    Info("TaskFeedLine::run()", big_station);

    local platform = big_station.get_free_platform();

    if (null == platform)
    {
        Warning("station has no free platform after all");
        return TaskReturnState.ERROR;
    }

    local station_id        = big_station.station_id;
    local entrance          = platform.get_entrance();
    local target_tile_index = entrance.tile_index;
    local target_direction  = entrance.direction;
    local industry = big_station.get_free_industry();

    if (null == industry)
    {
        Warning("no available industries");
        return TaskReturnState.ERROR;
    }

    local industry_id = industry.industry_id;
    local source_tile_index = find_industry_station_site(industry_id);

    if (source_tile_index == null)
    {
        Warning("industry not reachable");
        return TaskReturnState.ERROR;
    }

    local dir = SL.Direction.DIR_NE;
    local cargo = industry.get_cargo_types().Begin();

    subtasks = 
        [
        TaskBuildFeedStation(source_tile_index),
        /* TaskBuildTrack(source_tile_index, dir, */
        /*                target_tile_index, target_direction) */
        TaskBuildTrain(station_id, cargo)
        ];

    Debug("run subtasks");

    foreach (i, subtask in subtasks)
    {
        if (subtask.run() != TaskReturnState.DONE)
        {
            // TODO undo everything
            industry.skip = true;
            return TaskReturnState.ERROR;
        }
    }

    // make it so it doesn't have free tiles anymore
    platform.reserve();
    industry.reserve();
    /* big_station.recalculate(); */

    return TaskReturnState.DONE;
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
    Info("TaskBuildFeedStation::run()");

    local platlen   = FEEDER_PLATFORM_MAX_LENGTH;
    local direction = SL.Direction.DIR_NE;
    local opposite = SL.Direction.Opposite(direction);
    local offset    = SL.Direction.GetAdjacentTileInDirection(
                        entrance_tile_index,
                        direction);

    /* todo : handle any possible station orientation */

	local success = AIRail.BuildRailStation(offset, 
                            SL.Direction.ToRailTrackDirection(direction), 
                            1, 
                            platlen, 
                            AIStation.STATION_NEW);

    if (!success)
    {
        switch (AIError.GetLastError())
        {
            case AIError.ERR_NOT_ENOUGH_CASH:
                Warning("not enough cash");
                break;

            case AIError.ERR_OWNED_BY_ANOTHER_COMPANY:
                Warning("owned by other company");
                break;

            case AIError.ERR_AREA_NOT_CLEAR:
                Warning("area not clear");
                break;

            case AIError.ERR_FLAT_LAND_REQUIRED:
                Warning("flat land required");
                break;

            case AIStation.ERR_STATION_TOO_CLOSE_TO_ANOTHER_STATION:
                Warning("station too close to other station");
                break;

            case AIStation.ERR_STATION_TOO_MANY_STATIONS:
                Warning("too_many_stations");
                break;

            case AIStation.ERR_STATION_TOO_MANY_STATIONS_IN_TOWN:
                Warning("too many stations in town");
                break;

            default:
                Warning("can't place station for unhandled reason");
                break;
        }

        return TaskReturnState.ERROR;
    }

    build_rail([], entrance_tile_index, []);

    local depot_tile    = SL.Direction.GetAdjacentTileInDirection(
                            entrance_tile_index,
                            SL.Direction.TurnClockwise90Deg(direction, 1));
    // make depot from side, facing the entrance tile, a bit shit but ok
    local success       = rail_build_depot(depot_tile, entrance_tile_index);

    if (!success)
    {
        return TaskReturnState.ERROR;
    }

    local new_id = AIStation.GetStationID(offset);
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
    Info("TaskBuildTrack::run()");

    SL.Helper.SetSign(source_tile_id, "from here");
    SL.Helper.SetSign(target_tile_id, "to  here");

    local path;
    local dir1 = SL.Direction.Opposite(source_direction);
    local prev1 = SL.Direction.GetAdjacentTileInDirection(
        source_tile_id, dir1);
    local source = 
    [
        source_tile_id,
        prev1
    ];
    local dir2 = SL.Direction.Opposite(target_direction);
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
        Warning("can't find path");
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
                    Warning("can't place rail");
                    return TaskReturnState.ERROR;
                }
            }
        }

        if (path == false)
        {
            Warning("unknown path failure");
            return TaskReturnState.ERROR;
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

class TaskBuildTrain extends Task
{
    source_station  = null;
    target_station  = null;
    cargo           = null;

    constructor (target, cargo)
    {
        Task.constructor();
        target_station  = target;
        this.cargo      = cargo;

        Info("build train between stations [",
              source_station,
              "] and [",
              target_station,
              "]");
    }

	function _tostring()
    {
		return "buildtrain";
	}
}

function TaskBuildTrain::run ()
{
    Info("TaskBuildTrain::run()");

    source_station      = Feeder.plan.get_last_ai_station();
    local depot_tile    = SL.Vehicle.GetNearestDepot(source_station);

    if (null == depot_tile)
    {
        Warning("no nearby depot");
        return TaskReturnState.ERROR;
    }

    local rail_type     = AIRailTypeList().Begin();
    local engine_type   = SL.Engine.GetRailEngine(cargo, rail_type);
    local new_id = AIVehicle.BuildVehicle(depot_tile, engine_type);

    if (!AIVeicle.IsValidVehicle(result))
    {
        Warning("can't build vehicle");
        return TaskReturnState.ERROR;
    }

    local plat_len      = FEEDER_PLATFORM_MAX_LENGTH;
    local wagon_type    = SL.Engine.GetRailWagon(cargo, rail_type);

    while (SL.Vehicle.TrainLength(new_id) < plat_len)
    {
        local wagon = AIVehicle.BuildVehicle(depot_tile, wagon_type);
        CheckError();

		AIVehicle.RefitVehicle(wagon, cargo);
        CheckError();
		
        AIVehicle.MoveWagon(wagon, 0, train, 0);
    }

    return TaskReturnState.DONE;
}











