import std.process;
import std.algorithm;
import std.array;

import options_;

struct IPkg {
	string name;
	string ver;
}

auto getInstalled(Options options) {
	return executeShell(options.query.length?options.query:options.pacman~" -Qe"~(options.daemon?" --noconfirm":"")).output.split('\n').filter!(l=>l.length).map!(l=>l.split(' ')).map!((pp){IPkg pkg = IPkg(pp[0]); if (pp.length>1) pkg.ver=pp[1]; return pkg;});
}

