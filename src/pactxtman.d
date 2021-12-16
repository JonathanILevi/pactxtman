import std.stdio;
import std.algorithm;
import std.range;
import std.string;
import std.traits;
import std.conv;
import std.regex;
import std.process;

import tok_;
import installed_;
import options_;
import console_commands_;
import parse_;

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

struct Info {
	string[] overlapping;
	string[] toInstall;
	string[] toRemove;
	string[] extra;
}


bool readConfirm(bool def, bool noAsk) {
	if (noAsk) {
		writeln(def?"[Y]":"[N]");
		return def;
	}
	write(def?"[Y/n] ":"[y/N] ");
	auto ans = readln.strip.toLower;
	return ans=="y"|| (def && ans!="n");
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
	Options options = parseOptions(args);
	
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
}
