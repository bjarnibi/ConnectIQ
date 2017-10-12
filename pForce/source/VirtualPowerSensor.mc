using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.System as Sys;

const DEF_RWEIGHT		= 75.0;
const DEF_RHEIGHT		= 1.75;
const DEF_BWEIGHT		= 8.5;
const DEF_CREFF			= 0.0031;
const DEF_TEMP			= 10.0;
const DEF_WINDHEADING	= 0.0;
const DEF_WINDSPEED		= 0.0;
const DEF_CADENCE		= 85.0;

const MIN_SLOPE			= -20.0;
const MAX_SLOPE			= 20.0;

class VirtualPowerSensor extends Lang.Object {

	// constants
    var cCad				= 0.002;
    var afCd 			= 0.62;
    var afSin 			= 0.89;
    var afCm 			= 1.025;
    var afCdBike 		= 1.2;
    var afCATireV 		= 1.1;
    var afCATireH 		= 0.9;
    var afAFrame 		= 0.048;
    var ATire 			= 0.031;
    var CwaBike = afCdBike * (afCATireV * ATire + afCATireH * ATire + afAFrame);
 
 	// static parameters - from app properties
	var rWeight 		= 75.0;		// Rider weight in kg
	var rHeight 		= 1.92; 		// Rider height in in metres
	var bWeight		= 9.0;		// Bike weight in kg

	// Semi-static 
	var temp				= 10.0;	// Celcius
	var windHeading		= 0.0;  	// degrees
	var windSpeed		= 0.0;  // km/s
    var CrEff 			= 0.0031;  // crr CrV Coefficient of Rolling Resistnance
    
	// dynamic parameters - updated every second 
	var timestamp		= 0;		// milliseconds
	var deltaTime 		= 0;  	// millisec since last update

	var bearing			= 0.0;  // 
	var speed			= 0.0;	// metres / sec
	var accel			= 0.0;  // acceleration m/s/s Vd/Td
	
	var distance 		= 0.0;  // distance metres
	var deltaDistance	= 0.0;  // distance since last update metres
	
	var altitude			= 0.0;  // metres
	var deltaAltitude	= 0.0;	// alt diff since last update
	var slope			= 0.0;	// grade slope in percentage (-20% - 20%)
	var cadence			= DEF_CADENCE;

	function setProps ( info ) {
		rWeight = ( info.hasKey(:rWeight) ? info.get(:rWeight) : DEF_RWEIGHT );
		rHeight = ( info.hasKey(:rHeight) ? info.get(:rHeight) : DEF_RHEIGHT );
		bWeight = ( info.hasKey(:bWeight) ? info.get(:bWeight) : DEF_BWEIGHT);
		CrEff = ( info.hasKey(:crr) ? info.get(:crr) : DEF_CREFF );
		temp = ( info.hasKey(:temp) ? info.get(:temp) : DEF_TEMP );
		windHeading = ( info.hasKey(:windHeading) ? info.get(:windHeading) : DEF_WINDHEADING );
		windSpeed = ( info.hasKey(:windSpeed) ? info.get(:windSpeed) : DEF_WINDSPEED );
	}
	
	function initialize () {
		var initData = { };
		Sys.println(initData.isEmpty());
		setProps ( initData );
	}
	
	function envelope ( value, minvalue, maxvalue, defaultval ) {
		return ( value > minvalue && value < maxvalue ? value : defaultval );
	}
	
	function setData ( info ) {
		
		var lastTimestamp 	= timestamp;
		var lastSpeed 		= speed;
		var lastDistance 	= distance;
		var lastAltitude 	= altitude;
		
		timestamp		= ( info.hasKey(:timestamp) ? info.get(:timestamp) : timestamp );		// milliseconds
		deltaTime 		= timestamp - lastTimestamp;
		
		bearing			= ( info.hasKey(:bearing) ? info.get(:bearing) : bearing );  

		speed			= ( info.hasKey(:speed) ? info.get(:speed) : speed );					// metres / sec
		accel 			= ( deltaTime > 0 ? (speed - lastSpeed) / deltaTime : 0.0 );
		
		distance			= ( info.hasKey(:distance) ? info.get(:distance) : distance );  		// metres
		deltaDistance	= distance - lastDistance;
		
		altitude			= ( info.hasKey(:altitude) ? info.get(:altitude) : altitude );  		// metres
		deltaAltitude	= altitude - lastAltitude;
		
		cadence			= ( info.hasKey(:cadence) ? info.get(:cadence) : cadence );
	
		if ( info.hasKey(:altitude) && info.hasKey(:distance) ) {
			slope = envelope( ( deltaDistance > 0.0 ? deltaAltitude / deltaDistance * 100.0 : 0.0), MIN_SLOPE, MAX_SLOPE, slope);
		}
	}
	
	function calcPower () {
	/*
	    var adipos = Math.sqrt(rWeight/(rHeight*750));
	 
		W = cos( bearing - windHeading ) * windSpeed * 0.27777777777778;   // headwind factor
		
		if ( cadence > 0 ) {
		
		           T = p->temp;
	                double Slope = atan(p->slope * .01);
	                double V = p->kph * 0.27777777777778; // Cyclist speed m/s
	                double CrDyn = 0.1 * cos(Slope);
	
	                double Ka;
	                double Frg = 9.81 * (MBik + M) * (CrEff * cos(Slope) + sin(Slope));
	
	                double vw=V+W; // Wind speed against cyclist = cyclist speed + wind speed
	
	                if (CdA == 0) {
	                    double CwaRider = (1 + cad * cCad) * afCd * adipos * (((hRider - adipos) * afSin) + adipos);
	                    CdA = CwaRider + CwaBike;
	                }
		
		   Ka = 176.5 * exp(p->alt * .0001253) * CdA * DraftM / (273 + T);
	 	   watts = ( afCm * V * (Ka * (vw * vw) + Frg + V * CrDyn)) + (accel > 1 ? 1 : accel*V*M);
	 	   
		} else {
			watts = 0.0;
			
		}
		*/
		return 100.0;	
    }
}  