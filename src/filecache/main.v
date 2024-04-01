module main

import cli { Command, Flag }
import os
import filecache

fn main() {
	mut app := Command{
		name: 'filecache'
		description: 'find out files and directories in given paths for fzf cache'
		flags: [
			Flag{
				name: 'verbose'
				abbrev: 'v'
				description: 'set verbose logging'
				global: true
				flag: .bool
			},
			Flag{
				name: 'forever'
				abbrev: 'f'
				description: 'run forever'
				flag: .bool
			},
		]
		execute: fn (cmd Command) ! {
			if cmd.flags.get_bool('verbose') or { false } {
				(*filecache.log).level = .debug
			}

			fd_path := filecache.check_fd()!

			if cmd.flags.get_bool('forever') or { false } {
				filecache.run_forever(fd_path)!
			} else {
				filecache.reload_cache(fd_path)!
			}
		}
	}

	app.setup()
	app.parse(os.args)
}
