import std.algorithm;
import std.range;
import std.string;
import std.conv;
import std.stdio;

import tok_;


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


Data parse(string filename) {
	Data data;
	auto file = File(filename, "r");////.byLine.filter!(l=>l.split.length).map!(l=>l.split('#')[0]).filter!(l=>l.strip.length);
	data.code = file.byLine.byTok.array;
	parse(data, data.code, [], "");
	return data;
}
private void parse(ref Data data, Tok*[] toks, string[] grouping, string indent) {
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
			if (toks.front.type==Tok.type.comment) {
				toks.popFront;
			}
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