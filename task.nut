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

        if (null == platform) return;

        local tiles = platform.entrance_tiles;
        local tile_index = tiles[0];
	}
}

