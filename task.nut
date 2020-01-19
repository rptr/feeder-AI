require("util.nut");
require("build.nut");

class Task
{
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

class FeedLine extends Task
{
    big_station = null;

    constructor (big_station)
    {
        this.big_station = big_station;
    }

	function _tostring()
    {
		return "feedline";
	}

	function run ()
    {
        Debug("building feedline for ", big_station);

        local platform = big_station.get_free_platform();

        if (null == platform)
        {
            Debug("station has no free platform after all");
            return TaskReturnState.TASK_ERROR;
        }

        local station_id = big_station.station_id;
        local tiles = platform.entrance_tiles;
        local tile_index = tiles[0];

        local cargoes = big_station.get_cargo_types();

        // TEMP
        local all_cargo = AICargoList();

        foreach (cc in [AICargo.CC_PASSENGERS, AICargo.CC_MAIL, AICargo.CC_EXPRESS])
        {
            all_cargo.Valuate(AICargo.HasCargoClass, cc);
            all_cargo.KeepValue(0);
        }

        cargoes.extend([all_cargo.Begin()]);

        if (cargoes.len() == 0)
        {
            Debug("station has no cargo rating");
            return TaskReturnState.TASK_ERROR;
        }

        local industries;

        foreach (i, cargo in cargoes)
        {
            industries = AIIndustryList_CargoProducing(cargo);

            if (industries.Count() > 0)
                break;
        }

        if (industries.Count() == 0)
        {
            Debug("no available industries");
            return TaskReturnState.TASK_ERROR;
        }

        // TODO pick the best one
        local industry_id = industries.Begin();

        find_industry_station_site(industry_id);
	}
}

