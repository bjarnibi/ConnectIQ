using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.System as Sys;

const DEF_RWEIGHT		= 77.0;
const DEF_RHEIGHT		= 1.92;
const DEF_BWEIGHT		= 7.5;
const DEF_CREFF			= 0.0031;
const DEF_TEMP			= 20.0;
const DEF_WINDHEADING	= 0.0;
const DEF_WINDSPEED		= 0.0;
const DEF_CADENCE		= 85.0;
const DEF_DRAFT 			= 1.0;
const DEF_CDA			= 0.0;

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
	var rWeight 		= DEF_RWEIGHT;		// Rider weight in kg
	var rHeight 		= DEF_RHEIGHT; 		// Rider height in in metres
	var bWeight		= DEF_BWEIGHT;		// Bike weight in kg

	// Semi-static 
	var temp				= DEF_TEMP;	// Celcius
	var windHeading		= DEF_WINDHEADING;  	// degrees
	var windSpeed		= DEF_WINDSPEED;  // km/s
    var CrEff 			= DEF_CREFF;  // crr CrV Coefficient of Rolling Resistnance
    var draft			= DEF_DRAFT;
    var CdA				= DEF_CDA;
    
	// dynamic parameters - updated every second 
	var timestamp		= 0;		// milliseconds
	var deltaTime 		= 0;  	// millisec since last update

	var bearing			= 0.0;  // 
	var speed			= 0.0;	// metres / sec
	var accel			= 0.0;  // acceleration m/s/s Vd/Td
	var watts			= 0.0;
	var watts2			= 0.0;
		
	var distance 		= 0.0;  // distance metres
	var deltaDistance	= 0.0;  // distance since last update metres
	
	var altitude			= 0.0;  // metres
	var deltaAltitude	= 0.0;	// alt diff since last update
	var slope			= 0.0;	// grade slope in percentage (-20% - 20%)
	var cadence			= DEF_CADENCE;

	function min ( a, b ) {
		return ( a < b ? a : b);
	} 

	function max ( a, b ) {
		return ( a > b ? a : b);
	} 

	function setProps ( info ) {
		rWeight = ( info.hasKey(:rWeight) ? info.get(:rWeight) : rWeight );
		rHeight = ( info.hasKey(:rHeight) ? info.get(:rHeight) : rHeight );
		bWeight = ( info.hasKey(:bWeight) ? info.get(:bWeight) : bWeight );
		CrEff = ( info.hasKey(:crr) ? info.get(:crr) : CrEff );
		temp = ( info.hasKey(:temp) ? info.get(:temp) : temp );  								// deg C
		windHeading = ( info.hasKey(:windHeading) ? info.get(:windHeading) : windHeading );   // radians -pi though pi
		windSpeed = ( info.hasKey(:windSpeed) ? info.get(:windSpeed) : windSpeed );    		// metres per sec
		draft = ( info.hasKey(:draftMult) ? info.get(:draftMult) : draft );
		CdA = ( info.hasKey(:CdA) ? info.get(:CdA) : CdA );
	}
	
	function initialize () {

	}
	
	function envelope ( value, minvalue, maxvalue, defaultval ) {
		return ( value > minvalue && value < maxvalue ? value : defaultval );
	}
	
	var V2_i = 0.0;
	var V2_f = 0.0;
	 
	function setData ( info ) {
		
		var lastTimestamp 	= timestamp;
		var lastSpeed 		= speed;
		var lastDistance 	= distance;
		var lastAltitude 	= altitude;
		
		timestamp		= ( info.hasKey(:timestamp) ? info.get(:timestamp) : timestamp );		// milliseconds
		deltaTime 		= timestamp - lastTimestamp;
		
		bearing			= ( info.hasKey(:bearing) ? info.get(:bearing) : bearing );  

		V2_i 			= V2_f;
		speed			= ( info.hasKey(:speed) ? info.get(:speed) : speed );					// metres / sec
        	V2_f 			= speed * speed;
        	
		accel 			= ( deltaTime > 0 ? (speed - lastSpeed) / deltaTime : 0.0 );
		
		distance			= ( info.hasKey(:distance) ? info.get(:distance) : distance );  		// metres
		deltaDistance	= distance - lastDistance;
		
		altitude			= ( info.hasKey(:altitude) ? info.get(:altitude) : altitude );  		// metres
		deltaAltitude	= altitude - lastAltitude;
		
		cadence			= ( info.hasKey(:cadence) ? info.get(:cadence) : cadence );
	
		if ( info.hasKey(:altitude) && info.hasKey(:distance) ) {
			slope = envelope( ( deltaDistance > 0.0 ? deltaAltitude / deltaDistance * 100.0 : slope), MIN_SLOPE, MAX_SLOPE, slope);
		}
	}
	
	function calcPower () {

		if ( cadence > 0 ) {
			
		var V_a = speed + Math.cos( bearing - windHeading ) * windSpeed;   // airspeed = speed + wind tangent component
		var V_nor = Math.sin( bearing - windHeading ) * windSpeed;    // Wind normal component
		var Yaw = Math.atan2( V_nor, V_a );
		var A = 0.0276 * Math.pow(rHeight, 0.725) * Math.pow(rWeight, 0.425) + 0.1647;
		var CdA = 0.88 * A;
		var P = 101325.0 * Math.pow(Math.E, -9.81*0.0289655*altitude/(8.31432*(273.15+temp)));
		var rho = P / (287.05*(273.15+temp));
		
		var P_at = Math.pow( V_a, 2) * speed * 0.5 * rho * ( CdA + 0.0044 );
	    
	    var 	slopeangle = Math.atan(slope * 0.01);
	    var P_rr = speed * Math.cos( Math.atan (slopeangle)) * CrEff * ( rWeight + bWeight ) * 9.81;
	    var P_wb = speed * ( 91 + 8.7 * speed) * 0.001;
	    var P_pe = max ( 0.0, speed * ( rWeight + bWeight ) * 9.81 * Math.sin(Math.atan(slopeangle)) );
	    var P_ke = max ( 0.0, 0.5 * ((rWeight + bWeight) + 0.14/0.311)*(deltaTime > 0 ? (V2_f - V2_i)/deltaTime : 0.0) );   
	    
	    	watts = (P_at + P_rr + P_wb + P_pe + P_ke)/0.976;

	 /*	Sys.println("A " + A.format("%f")); 
	 	Sys.println("CdA " + CdA.format("%f")); 
	 	Sys.println("rho " + rho.format("%f")); 
	 	Sys.println("P " + P.format("%f")); 
	 	Sys.println("V_a " + V_a.format("%f")); 
	 	
	 	
	 	Sys.println("slope " + slope.format("%f")); 
	 	
	 	Sys.println("P_at " + P_at.format("%f"));   
	 	Sys.println("P_rr " + P_rr.format("%f"));   
	 	Sys.println("P_wb " + P_wb.format("%f"));   
	 	Sys.println("P_pe " + P_pe.format("%f"));   
	 	Sys.println("P_ke " + P_ke.format("%f"));   	 	  
	 	*/ 
		} else {
			watts = 0.0;	
		}
		
		return watts;	
    }
	
	function calcPower2 () {
	
	    var adipos = Math.sqrt(rWeight/(rHeight*750.0));
		var headwind = Math.cos( bearing - windHeading ) * windSpeed;   // headwind factor convert to m/s
		var slopeangle, CrDyn, Ka, Frg, relWind, CwaRider; 
		
		if ( cadence > 0 ) {
	
	     	slopeangle = Math.atan(slope * 0.01);

	        CrDyn = 0.1 * Math.cos(slopeangle);
	        Frg = 9.81 * (bWeight + rWeight) * (CrEff * Math.cos(slopeangle) + Math.sin(slopeangle));
	
	        relWind = speed + headwind; // Wind speed against cyclist = cyclist speed + wind speed
	
	        if (CdA == 0) {  //estimate CdA
	        		CwaRider = (1 + cadence * cCad) * afCd * adipos * (((rHeight - adipos) * afSin) + adipos);
	        		CdA = CwaRider + CwaBike;
	         }
		
			Ka = 176.5 * Math.pow(Math.E, altitude * 0.0001253) * CdA * draft / (273.0 + temp);
		   
			watts2 = ( afCm * speed * (Ka * (relWind * relWind) + Frg + speed * CrDyn)) + (accel > 1.0 ? 1.0 : accel*speed*rWeight);
	 	   
		} else {
			watts2 = 0.0;	
		}
		
		return watts2;	
    }
    
 
}  