using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class pForceApp extends App.AppBase {

	var mMainView = null;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    //! Return the initial view of your application here
    function getInitialView() {
    		mMainView = new pForceView();
        return [ mMainView ];
    }

    function onSettingsChanged()    {
    	if (mMainView != null) {
    		mMainView.getProps();
    		}
	    Ui.requestUpdate();
    }

}