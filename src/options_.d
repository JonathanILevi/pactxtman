
import args;

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
	
	@property {
	}
}

Options parseOptions(string[] args) {
	Options options;
	if (parseArgs(options, args)) {
		printArgsHelp(options, "PacTxtMan: Manage packages with a txt file!");
		import core.stdc.stdlib : exit;
		exit(0);
	}
	return options;
}
