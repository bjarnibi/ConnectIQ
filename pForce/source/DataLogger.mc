using Toybox.Lang as Lang;
using Toybox.System as Sys;

module Logger {


	function startLine () {
		Sys.print("** ");
	}
	
	function logData ( label, item ) {
		Sys.print(label + ";" + item.format("%f") + ";");
	}
	
	function endLine() {
		Sys.println("$$");
	}

}
