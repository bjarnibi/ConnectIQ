using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.UserProfile as User;

const Q_NONE = Gfx.COLOR_RED;
const Q_POOR = Gfx.COLOR_YELLOW;
const Q_GOOD = Gfx.COLOR_GREEN;



class pForceView extends Ui.DataField {

    hidden var mValue;
    
    hidden var mUserProfile = null;
	hidden var mTemperature = null;
	hidden var mDataQuality = Q_NONE;


	function getProps() {
		// get user weight and height from the user profile   .heigth (cm) .weight (grams)
		
		mTemperature.setTemp(10);
		
	}

	function initParams() {
		mUserProfile = User.getProfile();
		mTemperature = new TemperatureSensor();		
	}

    function initialize() {
        DataField.initialize();
        mValue = 0.0f;
   
        initParams();
        getProps();
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
    function compute(info) {
        var dataQuality = 7;
        
        	if (info has :altitude && info.altitude != null) { 			// meters
        		
        	} else {
        		dataQuality -= 1;
        	}
        	
        	if (info has :altitude && info.altitude != null) { 			// meters
        		
        	} else {
        		dataQuality -= 1;
        	}
        	
    		info.currentSpeed  		// meters per second
		info.currentHeading  	// true north referenced in radians
		
		info.currentLocation
		info.currentLocationAccuracy
		
		QUALITY_NOT_AVAILABLE = 0	GPS is not available
		QUALITY_LAST_KNOWN = 1		The Location is based on the last known GPS fix.
		QUALITY_POOR = 2		The Location was calculated with a poor GPS fix. Only a 2-D GPS fix is available, likely due to a limited number of tracked satellites.
		QUALITY_USABLE = 3 	The Location was calculated with a usable GPS fix. A 3-D GPS fix is available, with marginal HDOP (horizontal dilution of precision)
		QUALITY_GOOD = 4		The Location was calculated with a good GPS fix. A 3-D GPS fix is available, with good-to-excellent HDOP (horizontal dilution of precision).

		
		info.elapsedDistance  	// meters
		info.elapsedTime			// milliseconds
        
        if(info has :currentHeartRate){
            if(info.currentHeartRate != null){
                mValue = info.currentHeartRate;
            } else {
                mValue = 0.0f;
            }
        }
    }


	hidden function computePower () {
	

	
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



