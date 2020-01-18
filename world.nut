/*
 * stolen from ChooChoo
 */

// counterclockwise
enum Rotation {
	ROT_0, ROT_90, ROT_180, ROT_270
}

enum Direction {
	N, E, S, W, NE, NW, SE, SW
}

class RelativeCoordinates
{
	static matrices =
    [
		// ROT_0
		[ 1, 0,
		  0, 1],

		// ROT_90
		[ 0,-1,
		  1, 0],

		// ROT_180
		[-1, 0,
		  0,-1],

		// ROT_270
		[ 0, 1,
		 -1, 0]
	];
	
    // TileIndex
	location = null;
	rotation = null;	
	
	constructor (location, rotation = Rotation.ROT_0)
    {
		this.location = location;
		this.rotation = rotation;
	}
	
	function GetTile (coordinates)
    {
		local matrix = matrices[rotation];
		local x = coordinates[0] * matrix[0] + 
                  coordinates[1] * matrix[1];
		local y = coordinates[0] * matrix[2] + 
                  coordinates[1] * matrix[3];
		//Debug(coordinates[0] + "," + coordinates[1] + " -> " + x + "," + y);
		return location + AIMap.GetTileIndex(x, y);
	}
}

class WorldObject
{
	relativeCoordinates = null;
	location = null;
	rotation = null;
	
	constructor (location, rotation = Rotation.ROT_0)
    {
		this.relativeCoordinates = 
            RelativeCoordinates(location, rotation);
		this.location = location;
		this.rotation = rotation;
	}
	
	function GetTile (coordinates)
    {
		return relativeCoordinates.GetTile(coordinates);
	}
	
	function TileStrip (start, end)
    {
		local tiles = [];
		local count, xstep, ystep;

		if (start[0] == end[0])
        {
			count = abs(end[1] - start[1]);
			xstep = 0;
			ystep = end[1] < start[1] ? -1 : 1;
		}
        else
        {
			count = abs(end[0] - start[0]);
			xstep = end[0] < start[0] ? -1 : 1;
			ystep = 0
		}
		
		for (local i = 0, x  = start[0], y = start[1]; 
             i <= count; 
             i++, x += xstep, y += ystep)
        {
			tiles.append(GetTile([x, y]));
		}
				
		return tiles;
	}
}
