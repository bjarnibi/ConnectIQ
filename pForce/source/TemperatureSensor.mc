using Toybox.Lang as Lang;
using Toybox.System as Sys;
using Toybox.Sensor as Sensor;

class TemperatureSensor extends Lang.Object {

	hidden var mCurrentTemp = 15;  // degrees Celcius
	
	function initialize() {
	//	var availableSensors = Sensor.setEnabledSensors([Sensor.SENSOR_TEMPERATURE]);
	//    Sensor.enableSensorEvents(method(:onSensor));
	//    Sys.println(availableSensors);
	}
	
	hidden function onSensor (info) {
		
		if (info has :temperature) {
			// we have temp
			mCurrentTemp = info.temperature;
		}
	}
	
	function currentTemp() {
		return mCurrentTemp;
	}
	
	function setTemp(temp) {
		mCurrentTemp = temp;
	} 
	
	function cleanup() {
	}
	
}