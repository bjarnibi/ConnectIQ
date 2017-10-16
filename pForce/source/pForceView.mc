using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.UserProfile as User;
using Toybox.System as Sys;
using Toybox.Lang as Lang;

const Q_NONE = Gfx.COLOR_RED;
const Q_POOR = Gfx.COLOR_YELLOW;
const Q_GOOD = Gfx.COLOR_GREEN;

// need to redefine these constants since access to Position module is not allowed from datafeilds not even the constants !
//		QUALITY_NOT_AVAILABLE = 0	GPS is not available
//		QUALITY_LAST_KNOWN = 1		The Location is based on the last known GPS fix.
//		QUALITY_POOR = 2		The Location was calculated with a poor GPS fix. Only a 2-D GPS fix is available, likely due to a limited number of tracked satellites.
//		QUALITY_USABLE = 3 	The Location was calculated with a usable GPS fix. A 3-D GPS fix is available, with marginal HDOP (horizontal dilution of precision)
//		QUALITY_GOOD = 4		The Location was calculated with a good GPS fix. A 3-D GPS fix is available, with good-to-excellent HDOP (horizontal dilution of precision).      
const		GPS_NOT_AVAILABLE = 0;	//GPS is not available
const		GPS_LAST_KNOWN = 1;		//The Location is based on the last known GPS fix.
const		GPS_POOR = 2;			//The Location was calculated with a poor GPS fix. Only a 2-D GPS fix is available, likely due to a limited number of tracked satellites.
const		GPS_USABLE = 3; 			//The Location was calculated with a usable GPS fix. A 3-D GPS fix is available, with marginal HDOP (horizontal dilution of precision)
const		GPS_GOOD = 4;			//The Location was calculated with a good GPS fix. A 3-D GPS fix is available, with good-to-excellent HDOP (horizontal dilution of precision).      

class pForceView extends Ui.DataField {

    hidden var mValue, mValue2;
    
    hidden var mUserProfile 	 = null;
	hidden var mTempSensor 	 = null;
	hidden var mPower 		 = null;
	
	hidden var mAltitude = null;
    hidden var mDistance = null;
    hidden var mGrade = null;
    hidden var mAvgInterval = 5;
	
	hidden var mMeasuredPower = 0.0;
	
	hidden var mDataQuality = Q_NONE;

	function getProps() {
		
		// get user weight and height from the user profile   .heigth (cm) .weight (grams)		
		mUserProfile 	= User.getProfile();
		mTempSensor.setTemp(25);
		mAvgInterval = 5;
		
		// TODO Read props from app proerties
		var props = {
			:rWeight			=> 77.0, //mUserProfile.weight / 1000.0,  // weight in kg (grams in userprofile) 
			:rHeight			=> 1.92, //mUserProfile.height / 100.0,	 // height in metres (cm in userprofile)
			:bWeight			=> 8.0, 							// bikeweight in kg
			:crr				=> 0.0031,
			//:CdA				=> 1.0,							// Effective fronal area m2
			:draftMult		=> 1.0,
			:temp			=> 8.0, //mTempSensor.currentTemp(),
			:windHeading		=> -30.0 * Math.PI / 180.0,
			:windSpeed		=> 7.0
		};
		
		mPower.setProps ( props );		
	}

    function initialize() {
        
        DataField.initialize();        
        	mTempSensor 		= new TemperatureSensor( false );	
		mPower 			= new VirtualPowerSensor();
		mDistance 		= new RollingArray(15);
    		mAltitude 		= new RollingArray(15);
    		mGrade 			= new RollingArray(5);
		  		
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
    
    hidden function dataQuality ( locationAccuracy, pointQuality ) {
    
    		//Sys.println (Lang.format("Loc acc $1$  point qual $2$ \n", [locationAccuracy, pointQuality]) );
    		mDataQuality = locationAccuracy + pointQuality;
    	}
    
    // TEMP DEBUG
    var lastTime = 0;
    var totalDistance = 0.0;
    var lastLocation = null;
    
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
			   if ( info has :currentHeading && info.currentHeading != null ) { info.currentHeading = brng; }  
    			}
    			
    			lastLocation = location;
 		}
   		
   	}   
    // TEMP DEBUG
    
    function compute(info) {
 
	 	var datapoint = { };
/*			:timestamp		=> 0,
			:bearing			=> 0,
			:speed			=> 0,
			:distance		=> 0,
			:altitude		=> 0,
			:cadence			=> 0, 
			:slope			=> 0,

			:heartrate		=> 0,
			:power			=> 0
		};
*/  
        var dataQuality = 0;
        
        correctData ( info );   // correct data for simulator bugs 

		if( info.altitude != null && info.elapsedDistance != null ) {
		
			mAltitude.set( info.altitude );
			mDistance.set ( info.elapsedDistance );
			
        		var noData = mAltitude.length() < mAvgInterval + 2; // wait for intial data to enable averaging 		
        	
    			if ( !noData && (info.elapsedDistance - mDistance.getItem(-mAvgInterval)).abs() > 0.01) {
	    		   	
	    			mGrade.set((info.altitude-mAltitude.getItem(-mAvgInterval))/(info.elapsedDistance-mDistance.getItem(-mAvgInterval)));	
		        addKey ( datapoint, :slope, mGrade.average() );
				
        		} else {
        			addKey ( datapoint, :slope, 0.0 );
        		}

 	   }
                   
        	if (info has :elapsedTime ) {   	dataQuality += addKey ( datapoint, :timestamp, info.elapsedTime ); 	}
        	if (info has :altitude ) {   	dataQuality += addKey ( datapoint, :altitude, info.altitude ); 	}
        	if (info has :currentSpeed ) {   dataQuality += addKey ( datapoint, :speed, info.currentSpeed ); 	}
        	if (info has :currentHeading ) {   dataQuality += addKey ( datapoint, :bearing, info.currentHeading ); 	}
        	if (info has :elapsedDistance ) {   dataQuality += addKey ( datapoint, :distance, info.elapsedDistance ); 	}
        	if (info has :currentCadence ) {   dataQuality += addKey ( datapoint, :cadence, info.currentCadence ); 	}

        	if (info has :currentHeartRate ) {   addKey ( datapoint, :heartrate, info.currentHeartRate ); 	}
        	if (info has :currentPower ) {   addKey ( datapoint, :power, info.currentPower ); 	}

		mDataQuality = 
			dataQuality ( (info has :currentLocationAccuracy && info.currentLocationAccuracy != null ? info.currentLocationAccuracy : GPS_NOT_AVAILABLE), dataQuality );

		printInfo ( datapoint );
		
		mPower.setData ( datapoint );
		
		mMeasuredPower = (info has :currentPower &&  info.currentPower != null ? info.currentPower : -1.0);
		mValue = mPower.calcPower();
		mValue2 = mPower.calcPower2();	        	        	        				
    }

    function onLayout(dc) {
        var obscurityFlags = DataField.getObscurityFlags();

        // Top left quadrant so we'll use the top left layout
        if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.TopLeftLayout(dc));

        // Top right quadrant so we'll use the top right layout
        } else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.TopRightLayout(dc));

        // Bottom left quadrant so we'll use the bottom left layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.BottomLeftLayout(dc));

        // Bottom right quadrant so we'll use the bottom right layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.BottomRightLayout(dc));

        // Use the generic, centered layout
        } else {
            View.setLayout(Rez.Layouts.MainLayout(dc));
            var labelView = View.findDrawableById("label");
            labelView.locY = labelView.locY - 16;
            var valueView = View.findDrawableById("value");
            valueView.locY = valueView.locY + 7;
        }

        View.findDrawableById("label").setText(Rez.Strings.label);
        return true;
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
        // Set the background color
        View.findDrawableById("Background").setColor(getBackgroundColor());

        // Set the foreground color and value
        var value = View.findDrawableById("value");
        if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            value.setColor(Gfx.COLOR_WHITE);
        } else {
            value.setColor(Gfx.COLOR_BLACK);
        }
        value.setText(mValue.format("%d") + " | " + mMeasuredPower.format("%d") + " | " + mValue2.format("%d") );

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

    function printInfo ( info ) {
    		Logger.startLine();
        if (info.hasKey(:timestamp) ) {   	Logger.logData(":timestamp", info.get (:timestamp)); 	}
        	if (info.hasKey(:altitude )) {   	Logger.logData( " :altitude",info.get (:altitude) ); 	}
        	if (info.hasKey(:speed )) {   Logger.logData( " :speed", info.get (:speed));	}
        	if (info.hasKey(:bearing )) {   Logger.logData( " :bearing", info.get (:bearing));	}
        	if (info.hasKey(:distance )) {   Logger.logData( " :distance", info.get (:distance)); 	}
        	if (info.hasKey(:cadence )) {   Logger.logData( " :cadence", info.get (:cadence)); 	}

        	if (info.hasKey(:heartrate )) {   Logger.logData( ":heartrate", info.get (:heartrate));	}
        	if (info.hasKey(:power )) {   Logger.logData( ":power",info.get (:power)); 	}
    }
    

}



