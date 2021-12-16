import std.algorithm;
import std.range;
import std.string;
import std.conv;


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
