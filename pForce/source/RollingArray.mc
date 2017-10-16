using Toybox.Lang as Lang;
using Toybox.System as Sys;



class RollingArray extends Lang.Object {

	hidden var mSize;
	hidden var mArray; 
	hidden var mPos;
	hidden var mLength;
	
	function initialize (n) {
		mSize = n;
		mPos = 0; 
		mLength = 0;
		mArray = new [n];
		for (var i=0; i<mSize; i++) { 
			mArray [i] = 0; 
		}
	}

	function size () {
		return mSize;
	}
	
	function pos () {
		return mPos;
	}
		
	function set (item) {
		mLength = ( mLength >= mSize ? mSize : mLength + 1);
		mArray[mPos] = item;
		mPos = (mPos + 1) % mSize;
	}
	
	function getItem (i) {
		if ( i < 0 ) {
			var index = mPos + i;
			if (index < 0) { index = index + mSize; }
			return mArray [ index ];
		} else {
			return mArray [ (mLength <= mSize ? i : (mPos + 1 + i) % mSize )  ];
		}
	}		
	
	function sum() {
		var temp=0;
		for (var i=0; i<mLength; i++) { 
			temp += mArray [i]; 
		}
		return temp;
	}
	
	function average () {
		return (mLength == 0 ? 0.0 : sum() / mLength);
	}
	
	function averageSlice (from, to) {
		var sum = 0.0;
		for (var i=from; i<=to; i++) {
			sum += getItem(i);
		}
		return sum / ((to-from).abs()+1);
	}
	
	function length () {
		return mLength;
	}
	function print () {
		for (var i=0; i<mLength; i++) {
			Sys.print(getItem(i));Sys.print(" ");
			}
		Sys.println(mLength);
		Sys.println(mPos);
	}
}