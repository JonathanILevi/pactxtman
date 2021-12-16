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


void doProcess(Options options) {
	// Step 1: Gets a list of explicitly installed packages.
	auto installed = getInstalled(options).array;
	
	// Step 2: Parse "pacman.txt" file.
	Data data = parse(options.file);
	
	// Step 3: Diff check.  Calculate packages needing installed and removed.
	Info info;
	info.overlapping = data.install.filter!(k=>data.remove.canFind!(d=>d.name==k.name)).map!(p=>p.name).array;
	info.toInstall = data.install.filter!(k=>!installed.canFind!(i=>i.name==k.name)).map!(p=>p.name).array;
	info.toRemove = data.remove.filter!(d=>installed.canFind!(i=>i.name==d.name)).map!(p=>p.name).array;
	info.extra = installed.filter!(i=>!data.install.canFind!(k=>k.name==i.name)).map!(p=>p.name).array;
	
	// Step 4: Log info.
	foreach (t;data.code) {
		tc(TC.reset~t.tokColor(info)).write;
		t.code.write;
	}
	if (info.overlapping.length)
		writeln(tc(TC.reset, TC.magenta), `(Packages listed as "install" and "remove" are magenta.)`);
	if (info.toInstall.length)
		writeln(tc(TC.reset, TC.green), `(Packages to install are green.)`);
	if (info.toRemove.length)
		writeln(tc(TC.reset, TC.red), `(Packages to remove are red.)`);
	if (info.extra.length) {
		writeln(tc(TC.reset, TC.bold), `Extra packages to remove:`);
		writeln("    ", tc(TC.reset, TC.yellow), info.extra.join(' '));
	}
	writeln;
	
	// Step 5: Run install.
	if (info.toInstall.length) {
		string command = (options.install.length?options.install:(options.pacman~" -S"~(options.noconfirm||options.daemon?" --noconfirm":"")))~' '~info.toInstall.join(' ');
		writeln(tc(TC.reset, TC.green), command);
		////write(tc(TC.reset), "Install?  ");
		////if (readConfirm(true,options.daemon))
		spawnShell(command).wait;
	}
	// Step 6: Run remove for packegs marked explicitly for exclution.
	if (info.toRemove.length) {
		string command = (options.remove.length?options.remove:(options.pacman~" -R"~(options.noconfirm||options.daemon?" --noconfirm":"")))~' '~info.toRemove.join(' ');
		writeln(tc(TC.reset, TC.red), command);
		////write(tc(TC.reset), "Remove?  ");
		////if (readConfirm(true,options.daemon))
		spawnShell(command).wait;
	}
	// Step 7: Run remove for installed packages not listed in file.
	if (info.extra.length) if (options.removeExtras || !options.daemon) {
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
	
	doProcess(options);
	
	if (options.watch || options.daemon) {
		while (true) {
			writeln("Watching file for changes...");
			if (!execute(["inotifywait","/etc/pacman.txt","-qq","-emodify","-ecreate"]).status) {
				doProcess(options);
			}
		}
	}
}
