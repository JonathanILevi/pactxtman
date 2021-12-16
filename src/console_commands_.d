
auto bright(TC color) {
	return color+60;
}
auto bg(TC color) {
	return color+10;
}

enum TC : int {
	reset,
	bold,
	faint,
	italic,
	underline,
	slowBlink,
	rapidBlick,
	inverse,
	hide,
	crossedOut, strike = crossedOut, strikedOut = crossedOut,
	primaryFont,
	altFont1,
	altFont2,
	altFont3,
	altFont4,
	altFont5,
	altFont6,
	altFont7,
	altFont8,
	altFont9,
	fraktur,
	gothic = fraktur,
	doubleUnderline,
	normalIntensity, notBold = normalIntensity, notFaint = normalIntensity,
	notItalic,
	notUnderline,
	notBlinking,
	proportionalSpacing,
	notInverse,
	reveal,
	notCrossedOut, notStrike=notCrossedOut, notStrikeThrough=notCrossedOut,
	//...
	
	black=30,
	red,
	green,
	yellow,
	blue,
	magenta,
	cyan,
	white,
}

string tc(TC[] commands...) {
	import std.algorithm;
	import std.array;
	import std.conv;
	return "\033["~commands.map!(c=>(cast(int) c).to!string).join(';')~"m";
}