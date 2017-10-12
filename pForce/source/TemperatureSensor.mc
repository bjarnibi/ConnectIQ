using Toybox.Lang as Lang;
using Toybox.System as Sys;
using Toybox.Sensor as Sensor;

const DEF_TEMPERATURE	= 10.0;

class TemperatureSensor extends Lang.Object {

	hidden var mCurrentTemp = DEF_TEMPERATURE;  // degrees Celcius
	
	function initialize(activeSensor) {	
		var availableSensors = null;

		mCurrentTemp = DEF_TEMP;				
		if (activeSensor) {
			availableSensors = Sensor.setEnabledSensors([Sensor.SENSOR_TEMPERATURE]);
	  		Sensor.enableSensorEvents(method(:onSensor));
		}
	}
	
	hidden function onSensor (info) {
		mCurrentTemp = (info has :temperature ?  info.temperature : mCurrentTemp );
	}
	
	function currentTemp() {
		return mCurrentTemp;
	}
	
	function setTemp(temp) {
		mCurrentTemp = temp;
	} 
		
}