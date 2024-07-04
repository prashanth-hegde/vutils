import cli { Command, Flag }
import os
import common

const log = &common.Log{}

fn main() {
	mut app := Command{
		name: 'nerdfont'
		description: 'Utility to download and install nerd font into the system'
		flags: [
			Flag{
				name: 'verbose'
				abbrev: 'v'
				description: 'set verbose logging'
				global: true
				flag: .bool
			},
		]
		commands: [
			Command{
				name: 'install'
				description: 'install nerd font'
				required_args: 1
				execute: fn (cmd Command) ! {
					install_nerdfont(cmd.args)!
				}
			},
			Command{
				name: 'search'
				description: 'search for available fonts with the name'
				required_args: 0
				execute: fn (cmd Command) ! {
					search_nerdfont(cmd.args)!
				}
			},
		]
	}
	check_curl_tar() or {
		eprintln(err)
		return
	}
	app.setup()
	app.parse(os.args)
}

fn check_curl_tar() ! {
	if !os.exists_in_system_path('tar')
	|| !os.exists_in_system_path('xz')
	|| !os.exists_in_system_path('curl') {
		return error('curl or tar not found in system path, aborting')
	}
}
