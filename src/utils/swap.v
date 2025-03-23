import os
import cli { Flag, Command }

fn main() {
	mut app := Command{
		name: "swap",
		description: "swaps two filenames",
		usage: "swap <file1> <file2>",
		execute: fn (cmd Command) ! {
			if cmd.args.len != 2 {
				return error('swap requires two arguments')
			}
			file1 := cmd.args[0]
			file2 := cmd.args[1]
			if !os.exists(file1) {
				return error("${file1} does not exist")
			}
			if !os.exists(file2) {
				return error("$file2 does not exist")
			}
			os.rename(file1, '${file1}.tmp')!
			os.rename(file2, file1)!
			os.rename('${file1}.tmp', file2)!
		}
	}

	app.setup()
	app.parse(arguments())
}
