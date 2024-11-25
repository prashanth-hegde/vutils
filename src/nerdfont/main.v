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
					install_nerdfont(cmd.args, cmd.flags.get_bool('partial') or { false })!
				}
				flags: [
					Flag{
						name: 'partial'
						abbrev: 'p'
						description: 'partial match. Installs all fonts that have the given search key in their name. Case insensitive'
						flag: .bool
					},
				]
			},
			Command{
				name: 'search'
				description: 'search for available fonts with the name'
				required_args: 0
				execute: fn (cmd Command) ! {
					set_logging(cmd)
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
	app.parse(arguments())
}

fn check_curl_tar() ! {
	if !os.exists_in_system_path('tar')
	|| !os.exists_in_system_path('xz')
	|| !os.exists_in_system_path('curl') {
		return error('nerdfont needs curl, tar and xz installed in system path.\ncould not find one ore more of these.\naborting')
	}
}
