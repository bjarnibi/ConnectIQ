using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.System as Sys;
using Toybox.Lang as Lang;


// need to redefine these constants since access to Position module is not allowed from datafeilds not even the constants !
const		GPS_NOT_AVAILABLE = 0;	//GPS is not available
const		GPS_LAST_KNOWN = 1;		//The Location is based on the last known GPS fix.
const		GPS_POOR = 2;			//The Location was calculated with a poor GPS fix. Only a 2-D GPS fix is available, likely due to a limited number of tracked satellites.
const		GPS_USABLE = 3; 			//The Location was calculated with a usable GPS fix. A 3-D GPS fix is available, with marginal HDOP (horizontal dilution of precision)
const		GPS_GOOD = 4;			//The Location was calculated with a good GPS fix. A 3-D GPS fix is available, with good-to-excellent HDOP (horizontal dilution of precision).      
const 		MAX_POWER_ZONES = 8;
const 		POWER_SCALE = 100;
const 		BORDER_PAD = 2;

class pForceView extends Ui.DataField {

    hidden var mValue, mValue2;
    
    //hidden var mUserProfile 	 = null;
	hidden var mPower 		 = null;
	hidden var mDataQuality 	= GPS_NOT_AVAILABLE;
	
	hidden var mDataFont = Gfx.FONT_LARGE;
    hidden var mLabelFont = Gfx.FONT_XTINY;
    hidden var mZoneFont = Gfx.FONT_MEDIUM;
    
    hidden var mWidth;
    hidden var mHeight;
	
	hidden var mPowerZones = [ -300,0, 162, 221, 265, 309, 354, 442, 9999 ]; 
	hidden var mFtpPower = 150.0;
	hidden var mPowerScale = POWER_SCALE;
		
	hidden var mPowerZoneColors = [
		Gfx.COLOR_WHITE,
		Gfx.COLOR_LT_GRAY,  // Z1 0 - 162
		Gfx.COLOR_BLUE,  // z2
		Gfx.COLOR_DK_GREEN,  // z3
		Gfx.COLOR_YELLOW,  // z4
		Gfx.COLOR_ORANGE,  // z5 
		Gfx.COLOR_RED,   // z6
		Gfx.COLOR_DK_RED ];  // z7 443+
	
	hidden var mAltitude = null;
    hidden var mDistance = null;
    hidden var mGrade = null;
    hidden var mAvgInterval = 3;
	
	function min ( a, b ) { return ( a < b ? a : b ); }
	
	function getKey (app, key, defaultValue) {
		var val = app.getProperty(key);
		if ( val == null ) { val = defaultValue; }
		else if ( !(val instanceof Toybox.Lang.Number) ) { val = val.toNumber(); }
		return val;
	}
	
	hidden function powerZone ( power ) {
    		for (var i=1; i<MAX_POWER_ZONES; i++) {
			if ( power >= mPowerZones[i-1] && power < mPowerZones[i] ) {
				return i;		
		  	}	
		}
		return MAX_POWER_ZONES;
	} 

	function getProps() {

		var app = App.getApp();
		var defaultPower = [0,56,76,91,106,121,151,700];
		var perc;

		// get user weight and height from the user profile   .heigth (cm) .weight (grams)		
		//mUserProfile 	= User.getProfile();
		
		mAvgInterval = 4;
		
		var props = {
			:rWeight			=> getKey(app, "riderWeight_prop", 75.0).toFloat(), //mUserProfile.weight / 1000.0,  // weight in kg (grams in userprofile) 
			:rHeight			=> getKey(app, "riderHeight_prop", 175).toFloat() / 100.0, //mUserProfile.height / 100.0,	 // height in metres (cm in userprofile)
			:bWeight			=> getKey(app, "bikeHeight_prop", 8.0).toFloat(), 							// bikeweight in kg
			:crr				=> 0.0031,
			:draftMult		=> 1.0,
			:temp			=> getKey(app, "temp_prop", 15.0), //mTempSensor.currentTemp(),
			:windHeading		=> getKey(app, "windHeading_prop", 0).toFloat() * Math.PI / 180.0,
			:windSpeed		=> getKey(app, "windSpeed_prop", 0.0).toFloat()
		};
		
		mFtpPower = getKey(app, "ftpPower_prop", 150);

		for ( var i=2; i<= MAX_POWER_ZONES; i++ ) {
        		perc = getKey(app, "z"+i.toString()+"_prop", defaultPower[i-1]);         
            mPowerZones[i] = perc * mFtpPower / 100;
            if (mPowerZones[i] < mPowerZones[i-1]) {mPowerZones[i]=mPowerZones[i-1]+5;}
        }        

		mPower.setProps ( props );		
	}

    function initialize() {
        
        DataField.initialize();        
		mPower 			= new VirtualPowerSensor();
		mDistance 		= new RollingArray(10);
    		mAltitude 		= new RollingArray(10);
    		mGrade 			= new RollingArray(3);
		  		
        getProps();
        
        mValue = 0.0f;   
    }
    
    hidden function addKey ( point, key, value ) {
    		if (  value != null ) {
			point.put( key, value );
			return 1;
		}
		return 0;
	}    			
    
    
    // TEMP DEBUG
 /*   var lastTime = 0;
    var totalDistance = 0.0;
    var lastLocation = null; 
    var heading = new RollingArray(3);
    
    function correctData (info) {
 
 		if ( info has :elapsedTime && info.elapsedTime != null ) { 
 			info.elapsedDistance = totalDistance + (info.elapsedTime-lastTime).toFloat()/1000.0*info.currentSpeed; 
 			lastTime = info.elapsedTime; 
 			totalDistance = info.elapsedDistance;
 		}
    		if ( info has :currentCadence && info.currentCadence != null ) { info.currentCadence /= 2; }  // simulator bug reports 2x cadence
		
		if (info has :currentLocation && info.currentLocation != null ) {		// simulator bug no heading reported compute from lat long
    			var location = info.currentLocation.toRadians();
    			if ( lastLocation != null ) {
    				var y = Math.sin(location[1]-lastLocation[1]) * Math.cos(location[0]);
				var x = Math.cos(lastLocation[0])*Math.sin(location[0]) -
        					Math.sin(lastLocation[0])*Math.cos(location[0])*Math.cos(location[1]-lastLocation[1]);
				var brng = Math.atan2(y, x);
			   heading.set(brng);
			   if ( info has :currentHeading && info.currentHeading != null ) { info.currentHeading = heading.average(); }  
    			}
    			
    			lastLocation = location;
 		}
   		
   	}   
    // TEMP DEBUG
 */   
    function compute(info) {
 
	 	var datapoint = { }; 

        //correctData ( info );   // correct data for simulator bugs 

		if( info.altitude != null && info.elapsedDistance != null && info.elapsedDistance > 0.0 ) {
		
			mAltitude.set( info.altitude );
			mDistance.set ( info.elapsedDistance );
			
        		var avg = min (mAltitude.length(), mAvgInterval); // wait for intial data to enable averaging 		
        	
    			if ( (info.elapsedDistance - mDistance.getItem(-avg)).abs() > 0.001) {
	    		   	
	    			mGrade.set((info.altitude-mAltitude.getItem(-avg))/(info.elapsedDistance-mDistance.getItem(-avg)));	
		        addKey ( datapoint, :slope, mGrade.average() );
				
        		} else {
        			addKey ( datapoint, :slope, 0.0 );
        		}

 	   }
                   	
        	if (info has :elapsedTime ) {   	addKey ( datapoint, :timestamp, info.elapsedTime ); 	}
        	if (info has :altitude ) {   	addKey ( datapoint, :altitude, info.altitude ); 	}
        	if (info has :currentSpeed ) {   addKey ( datapoint, :speed, info.currentSpeed ); 	}
        	if (info has :currentHeading ) {  addKey ( datapoint, :bearing, info.currentHeading ); 	}
        	if (info has :elapsedDistance ) {  addKey ( datapoint, :distance, info.elapsedDistance ); 	}
        	if (info has :currentCadence ) {  addKey ( datapoint, :cadence, info.currentCadence ); 	}

        	if (info has :currentPower ) {   addKey ( datapoint, :power, info.currentPower ); 	}

 		mDataQuality = (info has :currentLocationAccuracy && info.currentLocationAccuracy != null ? info.currentLocationAccuracy : GPS_NOT_AVAILABLE);

		//printInfo ( datapoint );
		
		if ( mDataQuality >  GPS_POOR ) {
			mPower.setData ( datapoint );
			mValue = mPower.calcPower();
			mValue2 = mPower.calcPower2();	     
		}
		   	     
		//Logger.endLine();   	   	       	        				
    }
    
    	hidden function drawPowerZones (dc, xBase, yBase, maxWidth, barHeight ) {
		var x, y, width, minZone, maxZone, minPower, maxPower, power;

        x = xBase;  		
 		y = yBase+barHeight-dc.getFontHeight(mLabelFont)-BORDER_PAD;
        minPower = mValue-mPowerScale/2;
        maxPower = mValue+mPowerScale/2;
        minZone = powerZone (minPower)-1;
        maxZone = powerZone (maxPower)-1;
        power=minPower;
		for ( var i=minZone; i<=maxZone; i++ ) {		
			dc.setColor(mPowerZoneColors[i], Gfx.COLOR_TRANSPARENT);
			width = (mPowerZones[i+1]-power).toFloat()/mPowerScale*maxWidth;
			dc.fillRectangle(x, yBase, width, barHeight );
			x += width;
			power = mPowerZones[i+1];
		}
		
		x = xBase + maxWidth/2;
		y = yBase+barHeight;
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		dc.fillPolygon([[x-7,y],[x,y-9],[x+7,y]]);
	}

    function onLayout(dc) {
		mWidth = dc.getWidth();
		mHeight = dc.getHeight();
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {

        // Set the background color
        dc.setColor(Gfx.COLOR_BLACK, getBackgroundColor());
        dc.clear();
        			
 		if ( mDataQuality >  GPS_POOR ) {
 
 			var powerstr = mValue.format("%d");
 			drawPowerZones( dc, 0, 0,dc.getWidth(), dc.getHeight()); 		
		
	        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
	        dc.drawText(mWidth/2, BORDER_PAD, mLabelFont, "Est Power", Gfx.TEXT_JUSTIFY_CENTER);
	   		dc.drawText(mWidth/2, mHeight/2-Gfx.getFontAscent(mDataFont)/2, mDataFont, powerstr,  Gfx.TEXT_JUSTIFY_CENTER); 		
				
			var y=mHeight/2 + Gfx.getFontAscent(mDataFont)/2 - Gfx.getFontAscent(mLabelFont);	
			var x=mWidth/2+dc.getTextDimensions(powerstr, mDataFont)[0]/2+BORDER_PAD;
			
	        dc.drawText(x, y, mLabelFont, "watts", Gfx.TEXT_JUSTIFY_LEFT);  
	        // draw zone
	        y = y - Gfx.getFontAscent(mZoneFont);
	        dc.drawText(x, y, mZoneFont, "Z" + (powerZone(mValue)-1).toString(), Gfx.TEXT_JUSTIFY_LEFT);
	     
	    } else { 
	     
	     	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
	        dc.drawText(mWidth/2, BORDER_PAD, mLabelFont, "Est Power", Gfx.TEXT_JUSTIFY_CENTER);
	   		dc.drawText(mWidth/2, mHeight/2-Gfx.getFontAscent(mDataFont)/2, mDataFont, "Poor GPS",  Gfx.TEXT_JUSTIFY_CENTER); 		
	   	}
    }

 /*   function printInfo ( info ) {
    		Logger.startLine();
        if (info.hasKey(:timestamp) ) {   	Logger.logData(":timestamp", info.get (:timestamp)); 	}
        	if (info.hasKey(:altitude )) {   	Logger.logData( " :altitude",info.get (:altitude) ); 	}
        	if (info.hasKey(:speed )) {   Logger.logData( " :speed", info.get (:speed));	}
        	if (info.hasKey(:bearing )) {   Logger.logData( " :bearing", info.get (:bearing));	}
        	if (info.hasKey(:distance )) {   Logger.logData( " :distance", info.get (:distance)); 	}
        	if (info.hasKey(:cadence )) {   Logger.logData( " :cadence", info.get (:cadence)); 	}

        	if (info.hasKey(:power )) {   Logger.logData( ":power",info.get (:power)); 	}
    }
    */

}



