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

    hidden var mValue;
    
    hidden var mUserProfile 	 = null;
	hidden var mTempSensor 	 = null;
	hidden var mPower 		 = null;

	hidden var mDataQuality = Q_NONE;

	function getProps() {
		
		// get user weight and height from the user profile   .heigth (cm) .weight (grams)		
		mUserProfile 	= User.getProfile();
		mTempSensor.setTemp(10);
		
		// TODO Read props from app proerties
		var props = {
			:rWeight			=> mUserProfile.weight,
			:rHeight			=> mUserProfile.height,
			:bWeight			=> 7.5,
			:crr				=> 0.0031,
			:temp			=> mTempSensor.currentTemp(),
			:windHeading		=> 90.0,
			:windSpeed		=> 10.0
		};
		
		mPower.setProps ( props );		
	}

    function initialize() {
        
        DataField.initialize();        
        	mTempSensor 		= new TemperatureSensor( false );	
		mPower 			= new VirtualPowerSensor();
		  		
        getProps();
        
        mValue = 0.0f;   
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
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

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    
    hidden function addKey ( point, key, value ) {
    		if (  value != null ) {
			point.put( key, value );
			return 1;
		}
		return 0;
	}    			
    
    hidden function dataQuality ( locationAccuracy, pointQuality ) {
    
    		Sys.println (Lang.format("Loc acc $1$  point qual $2$ \n", [locationAccuracy, pointQuality]) );
    		mDataQuality = locationAccuracy + pointQuality;
    	}
    
    function compute(info) {
 
	 	var datapoint = { };
/*			:timestamp		=> 0,
			:bearing			=> 0,
			:speed			=> 0,
			:distance		=> 0,
			:altitude		=> 0,
			:cadence			=> 0, 

			:heartrate		=> 0,
			:power			=> 0
		};
*/ 
		   
        var dataQuality = 0;
        
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
		
		mPower.setData ( datapoint );
		
		mValue = mPower.calcPower();
		        	        	        				
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
        value.setText(mValue.format("%.2f"));

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}



