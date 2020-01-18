require("util.nut");
require("task.nut");
require("finance.nut");
require("plan.nut");
/* require("pathfinder.nut"); */
/* require("world.nut"); */
/* require("signs.nut"); */
/* require("builder.nut"); */
/* require("planner.nut"); */
/* require("manager.nut"); */
/* require("vehicles.nut"); */

const MIN_DISTANCE =  30;
const MAX_DISTANCE = 100;
const MAX_BUS_ROUTE_DISTANCE = 40;
const INDEPENDENTLY_WEALTHY = 1000000;	// no longer need a loan

enum Direction {
	N, E, S, W, NE, NW, SE, SW
}

// counterclockwise
enum Rotation {
	ROT_0, ROT_90, ROT_180, ROT_270
}

enum SignalMode {
	NONE, FORWARD, BACKWARD
}

class Feeder extends AIController
{
    plan = null;


    function try_add_new_task (task)
    {
        if (task == null)
        {
            return;
        }

        this.tasks.push(task);
        Debug("new task", task);
    }
	
	function WaitForMoney(amount) {
		local reserve = GetMinimumSafeMoney();
		local autorenew = GetAutoRenewMoney();
		local total = amount + reserve + autorenew;
		
		Debug("Waiting until we have £" + total + " (£" + amount + " to spend plus £" + reserve + " in reserve and £" + autorenew + " for autorenew)");
		MaxLoan();
		while (GetBankBalance() < amount) {
			local percentage = (100 * GetBankBalance()) / total;
			local bar = "";
			for (local i = 0; i < 100; i += 10) {
				if (percentage > i) {
					bar += "I";
				} else {
					bar += ".";
				}
			}
			
			// maximum sign length is 30 characters; pound sign seems to require two (bytes?)
			local currency = total >= 100000 ? "" : "£";
			SetSecondarySign("Money: need " + currency + total/1000 + "K [" + bar + "]");
			
			FullyMaxLoan();
			HandleEvents();
			Sleep(TICKS_PER_DAY);
			MaxLoan();
		}
		
		ClearSecondarySign();
	}
	
	function HandleEvents ()
    {
		while (AIEventController.IsEventWaiting ())
        {
  			local e = AIEventController.GetNextEvent();
  			local converted;
  			local vehicle;

  			switch (e.GetEventType()) {
  				case AIEvent.AI_ET_VEHICLE_UNPROFITABLE:
  					/* converted = AIEventVehicleUnprofitable.Convert(e); */
  					/* vehicle = converted.GetVehicleID(); */
  					/* Cull(vehicle); */
  					break;
  					
				case AIEvent.AI_ET_VEHICLE_WAITING_IN_DEPOT:
					/* converted = AIEventVehicleWaitingInDepot.Convert(e); */
					/* vehicle = converted.GetVehicleID(); */
					/* Warning("Selling: " + AIVehicle.GetName(vehicle)); */
					/* AIVehicle.SellVehicle(vehicle); */
					break;
				
      			default:
      			    Debug("Unhandled event:" + e);
  			}
		}
	}
	
	function CheckSetting (name, value, description)
    {
		/* if (!AIGameSettings.IsValid(name)) */
        /* { */
		/* 	Warning("Setting " + name + " does not exist! ChooChoo may not work properly."); */
		/* 	return true; */
		/* } */
		
		/* local gameValue = AIGameSettings.GetValue(name); */

		/* if (gameValue == value) */
        /* { */
		/* 	return true; */
		/* } else */
        /* { */
		/* 	Warning(name + " is " + (gameValue ? "on" : "off")); */
		/* 	Warning("You can change this setting under " + description); */
		/* 	return false; */
		/* } */
	}
	
	function Save ()
    {
		return {};
	}

	function Load(version, data)
    {}
}

function Feeder::Start ()
{
    this.plan = Plan();

	AICompany.SetAutoRenewStatus(true);
	AICompany.SetAutoRenewMonths(0);
	AICompany.SetAutoRenewMoney(0);
	
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);

	::COMPANY <- AICompany.ResolveCompanyID(
                    AICompany.COMPANY_SELF);
	::TICKS_PER_DAY <- 37;
    ::SLEEP_TICKS <- 5;
	::SIGN1 <- -1;
	::SIGN2 <- -1;
	::tasks <- [];

	AIRail.SetCurrentRailType(AIRailTypeList().Begin());

	if (AIStationList(AIStation.STATION_TRAIN).IsEmpty())         
    {
		tasks.push(LongLine());
	}

	local minMoney = 0;
	local year = 0;

	while (true)
    {
		HandleEvents();
		
		if (year != AIDate.GetYear(AIDate.GetCurrentDate()))
        {
			/* CullTrains(); */
			year = AIDate.GetYear(AIDate.GetCurrentDate());
		}

        // nothing to do	
		if (tasks.len() == 0)
        {
            this.plan.find_stations();
            this.try_add_new_task(this.plan.get_task());
		}

        // didn't find anything to do
        if (tasks.len() == 0)
        {
            Sleep(SLEEP_TICKS);
            continue;
        }
		
		Debug("Tasks: " + ArrayToString(tasks));

		try
        {
			local task = tasks[0];
			Debug("Running: " + task);
			task.run();
			tasks.remove(0);
		}
        catch (e)
        {
			if (typeof(e) == "instance")
            {
				/* if (e instanceof TaskRetryException) */
                /* { */
				/* 	Sleep(e.sleep); */
				/* 	Debug("Retrying..."); */
				/* } */
                /* else if (e instanceof TaskFailedException) */
                /* { */
				/* 	Warning(task + " failed: " + e); */
				/* 	tasks.remove(0); */
				/* 	task.Failed(); */
				/* } */
                /* else if (e instanceof NeedMoneyException) */
                /* { */
				/* 	Debug(task + " needs £" + e.amount); */
				/* 	minMoney = e.amount; */
				/* } */
			}
            else
            {
				Error("Unexpected error");
				return;
			}
		}
	}
}

