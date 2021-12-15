import std.stdio;
import std.algorithm;
import std.range;
import std.string;
import std.traits;
import std.conv;
import std.regex;
import std.process;

struct IPkg {
	string name;
	string ver;
}

IPkg[] readInstalled() {
	IPkg[] pkgs;
	string p;
	while (true) {
		p = readln;
		if (p == "") {
			return pkgs;
	        }
		auto pp = p.strip.split(' ');
		IPkg pkg = IPkg(pp[0]);
		if (pp.length > 1)
			pkg.ver = pp[1];
		pkgs ~= pkg;
	}
	assert(false);
}

struct Tok {
	enum Type : ubyte {
		whitespace,
		newline,
		comment,
		grp,
		pkg,
		unpkg,
	}
	Type type;
	string code;
	
	string name;
	bool __install;
	string[] __grouping;
	
	string toString() {
		return code;
	}
}

Pkg* asPkg(Tok* Tok) {
	if (Tok.type == Tok.Type.pkg) {
		auto pkg = cast(Pkg*) Tok;
		pkg.install = true;
		return pkg;
	}
	else if (Tok.type == Tok.Type.unpkg) {
		auto pkg = cast(Pkg*) Tok;
		pkg.install = false;
		return pkg;
	}
	assert(false);
}

////Tok*[] takeWhite(S)(S line) {
////	if (line.length && line[0].isWhite) {
////		[new Tok(line.takeWhile!(l=>l.isWhite))];
////	}
////	return [];
////}
////
////Tok*[] takeToks(S)(S line) {
////	Tok*[] Toks;
////}

auto byTok(ByLine)(ByLine liner) {
	struct ByTok {
		ByLine byLine;
		typeof(ByLine.front) line;
		Tok* front;
		bool empty = false;
		void popFront() {
			assert(!empty);
			if (!line.length) {
				if (byLine.empty) {
					empty = true;
					return;
				}
				front = new Tok(Tok.Type.newline, "\n");
				byLine.popFront;
				line = byLine.front;
				return;
			}
			switch (line[0]) {
				case ' ': case '\t':
					front = new Tok(Tok.Type.whitespace, line.until!(c=>!(c==' '||c=='\t')).array.to!string);
					line = line[front.code.length..$];
					return;
				////case '\n':
				////	front = new Tok(Tok.Type.newline, "\n");
				////	assert(line == "\n");
				////	line.length = 0;
				////	return;
				case '#':
					front = new Tok(Tok.Type.comment, line.to!string);
					line.length = 0;
					return;
				case ':':
					auto code = line.until!(c=>c=='#').array.to!string;
					front = new Tok(Tok.Type.grp, code, code[1..$].strip);
					line = line[front.code.length..$];
					return;
				default:
					auto code = line.until!(c=>c==' '||c=='\t'||c=='#').array.to!string;
					
					if (code.startsWith('!'))
						front = new Tok(Tok.Type.unpkg, code, code[1..$]);
					else
						front = new Tok(Tok.Type.pkg, code, code);
					
					line = line[front.code.length..$];
					return;
			}
		}
	}
	auto byTok = ByTok(liner);
	byTok.popFront;
	return byTok;
}

struct Data {
	Tok*[] code;
	Pkg*[] install;
	Pkg*[] remove;
}
struct Pkg {
	ubyte type;// Must always be `Tok.Type.pkg` is `install` and `Tok.Type.unpkg` if `!install`.
	string code;
	
	string name;
	bool install;
	string[] grouping;
	
	@disable this();
	
	string toString() {
		return name~grouping.text;
	}
}


auto parse(string filename) {
	Data data;
	auto file = File(filename, "r");////.byLine.filter!(l=>l.split.length).map!(l=>l.split('#')[0]).filter!(l=>l.strip.length);
	data.code = file.byLine.byTok.array;
	parse(data, data.code, [], "");
	return data;
}
////
////string findMoreIndent(R)(ref R file) {
////	auto indent = file.front[0..$-file.front.stripLeft.length].idup;
////	file.popFront;
////	if (file.empty)
////		return "";
////	return findMoreIndent(file, indent);
////}
////string findMoreIndent(R)(ref R file, string preIndent) {
////	string indent;
////	if (!file.front.startsWith(preIndent))
////		return "";
////	auto lineLess = file.front[preIndent.length..$];
////	auto lineData = lineLess.stripLeft;
////	if (lineData.length == lineLess.length)
////		return "";
////	else
////		return file.front[0..$-lineData.length].idup;
////}
void parse(ref Data data, Tok*[] toks, string[] grouping, string indent) {
	string lineIndent = indent;
	while (true) {
		if (toks.empty) {
			return;
		}
		if (toks.front.type==Tok.type.comment) {
			toks.popFront;
			continue;
		}
		if (toks.front.type==Tok.type.newline) {
			toks.popFront;
			continue;
		}
		if (toks.front.type==Tok.Type.whitespace) {
			if (!toks.front.code.startsWith(indent))
				return;
			lineIndent = toks.front.code;
			toks.popFront;
			assert(toks.front.type!=Tok.Type.whitespace);
			continue;
		}
		if (toks.front.type == Tok.Type.grp) {
			auto name = toks.front.name;
			toks.popFront;
			if (toks.empty)
				return;
			assert(toks.front.type == Tok.Type.newline);
			toks.popFront;
			if (toks.empty)
				return;
			assert(toks.front.type == Tok.Type.whitespace);
			if (toks.front.code.startsWith(lineIndent) && toks.front.code.length > lineIndent.length) {
				parse(data, toks, grouping~name, toks.front.code);
			}
			continue;
		}
		/*pkg and unpkg*/ {
			auto pkg = toks.front.asPkg;
			pkg.grouping = grouping;
			if (pkg.install)
				data.install ~= pkg;
			else
				data.remove ~= pkg;
			toks.popFront;
			continue;
		}
	}
}


void writePkgs(string[] list, Data data) {
	foreach (p; list) {
		writeln("    ", p);
		foreach (k; data.install.filter!(k=>k.name==p))
			writeln("        ", k.grouping);
		foreach (d; data.remove.filter!(d=>d.name==p))
			writeln("       !", d.grouping);
	}
}

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
	return "\033["~commands.map!(c=>(cast(int) c).to!string).join(';')~"m";
}


TC[] tokTypeColor(Tok.Type type) {
	final switch (type) {
		case Tok.Type.whitespace:
			return [];
		case Tok.Type.newline:
			return [];
		case Tok.Type.comment:
			return [TC.faint];
		case Tok.Type.grp:
			return [TC.bold];
		case Tok.Type.pkg:
			return [TC.green];
		case Tok.Type.unpkg:
			return [TC.red];
	}
}

struct Info {
	string[] overlapping;
	string[] toInstall;
	string[] toRemove;
	string[] extra;
}

TC[] tokColor(Tok* tok, Info info) {
	if (tok.type == Tok.type.pkg || tok.type == Tok.Type.unpkg) {
		if (info.overlapping.canFind(tok.name))
			return [TC.magenta];
		if (info.toInstall.canFind(tok.name))
			return [TC.green];
		if (info.toRemove.canFind(tok.name))
			return [TC.red];
		return [];
	}
	return tok.type.tokTypeColor;
}

import args;

bool readConfirm(bool def, bool noAsk) {
	if (noAsk) {
		writeln(def?"[Y]":"[N]");
		return def;
	}
	write(def?"[Y/n] ":"[y/N] ");
	auto ans = readln.strip.toLower;
	return ans=="y"|| (def && ans!="n");
}

struct Options {
	@Arg("Specify pacman.txt file.",'f') string file = "/etc/pacman.txt";
	@Arg("Package Manager", 'm') string pacman = "pacman";
	@Arg("Install command prefix (Overrides --pacman)", 'i', Optional.yes) string install;
	@Arg("Remove command prefix (Overrides --pacman)", 'r', Optional.yes) string remove;
	@Arg("Query command (Overrides --pacman)", 'q', Optional.yes) string query;
	@Arg("Watch file for changes", 'w', Optional.yes) bool watch;
	@Arg("With pacman with --noconfirm", Optional.yes) bool noconfirm;
	@Arg("Run as daemon (--noconfirm and -w)", 'd', Optional.yes) bool daemon;
	@Arg("Remove extras", 'e', Optional.yes) bool removeExtras;
}

auto getInstalled(Options options) {
	return executeShell(options.query.length?options.query:options.pacman~" -Qe"~(options.daemon?" --noconfirm":"")).output.split('\n').filter!(l=>l.length).map!(l=>l.split(' ')).map!((pp){IPkg pkg = IPkg(pp[0]); if (pp.length>1) pkg.ver=pp[1]; return pkg;});
}

void handleTxt(IPkg[] installed, Options options) {
	Data data = parse(options.file);
	
	Info info;
	info.overlapping = data.install.filter!(k=>data.remove.canFind!(d=>d.name==k.name)).map!(p=>p.name).array;
	info.toInstall = data.install.filter!(k=>!installed.canFind!(i=>i.name==k.name)).map!(p=>p.name).array;
	info.toRemove = data.remove.filter!(d=>installed.canFind!(i=>i.name==d.name)).map!(p=>p.name).array;
	info.extra = installed.filter!(i=>!data.install.canFind!(k=>k.name==i.name)).map!(p=>p.name).array;
	
	foreach (t;data.code) {
		tc(TC.reset~t.tokColor(info)).write;
		t.code.write;
	}
	if (info.overlapping.length)
		writeln(tc(TC.reset, TC.magenta), `(Packages listed as "install" and "remove" are magenta.)`);
	if (info.toInstall.length)
		writeln(tc(TC.reset, TC.green), `(Packages to install are green.)`);
	if (info.toRemove.length)
		writeln(tc(TC.reset, TC.red), `(Packages to install are red.)`);
	foreach (pkg; info.extra) {
		writeln(tc(TC.reset, TC.bold), `Extra packages to remove:`);
		writeln("    ", tc(TC.reset, TC.yellow), pkg);
	}
	if (info.toInstall.length) {
		string command = (options.install.length?options.install:(options.pacman~" -S"~(options.noconfirm||options.daemon?" --noconfirm":"")))~' '~info.toInstall.join(' ');
		writeln(tc(TC.reset, TC.green), command);
		////write(tc(TC.reset), "Install?  ");
		////if (readConfirm(true,options.daemon))
		spawnShell(command).wait;
	}
	if (info.toRemove.length) {
		string command = (options.remove.length?options.remove:(options.pacman~" -R"~(options.noconfirm||options.daemon?" --noconfirm":"")))~' '~info.toRemove.join(' ');
		writeln(tc(TC.reset, TC.red), command);
		////write(tc(TC.reset), "Remove?  ");
		////if (readConfirm(true,options.daemon))
		spawnShell(command).wait;
	}
	if (info.extra.length) {
		string command = (options.remove.length?options.remove:(options.pacman~" -R"~(options.noconfirm||options.daemon?" --noconfirm":"")))~' '~info.extra.join(' ');
		writeln(tc(TC.reset, TC.yellow), command);
		////write(tc(TC.reset), "Remove extra? ");
		////if (readConfirm(options.removeExtras || !options.daemon, options.daemon))
		spawnShell(command).wait;
	}
	writeln("Done.");
}

void main(string[] args) {
	Options options;
	if (parseArgs(options, args)) {
		printArgsHelp(options, "PacTxtMan: Manage packages with a txt file!");
		return;
	}
	
	////auto installed = readInstalled;
	auto installed = getInstalled(options).array;
	handleTxt(installed, options);
	
	if (options.watch || options.daemon) {
		while (true) {
			writeln("Listening for changes...");
			if (!execute(["inotifywait","/etc/pacman.txt","-qq","-emodify","-ecreate"]).status) {
				installed = getInstalled(options).array;
				handleTxt(installed, options);
			}
		}
	}
	
	////auto overlapping = data.install.filter!(k=>data.remove.canFind!(d=>d.name==k.name)).map!(p=>p.name).array;
	////if (overlapping.length) {
	////	writeln(`Packages listed as "install" and "remove":`);
	////	writePkgs(overlapping, pkgs);
	////}
	////
	////if (toInstall.length) {
	////	writeln(`Packages to install:`);
	////	writePkgs(toInstall, data);
	////}
	////
	////if (toRemove.length) {
	////	writeln(`Packages to remove:`);
	////	writePkgs(toRemove, data);
	////}
	////
	////if (extraPackages.length) {
	////	writeln(`Extra packages to remove:`);
	////	writePkgs(extraPackages, data);
	////}
	
	////if (toInstall.length) {
	////	write("Install with? ");
	////	while (true) {
	////		auto command = readln.strip;
	////		if (command.length) {
	////			if (spawnShell(command~' '~toInstall.join(' ')).wait) {
	////				write("Try again with? ");
	////			}
	////			else {
	////				break;
	////			}
	////		}
	////	}
	////}
}
