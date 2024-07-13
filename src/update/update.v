module main

import cli { Command, Flag }
import updater

/**
While running the main function, use absolute path so that the compilation does not error
Example: from the directory vutils
v run $PWD/src/update
**/
fn main() {
	mut app := Command{
		name: 'update'
		description: 'updater for the most commonly used applications'
		flags: [
			Flag{
				name: 'verbose'
				abbrev: 'v'
				description: 'set verbose logging'
        global: true
        flag: .bool
			},
		]
		execute: fn (cmd Command) ! {
      if cmd.flags.get_bool('verbose') or { false } {
        (*updater.log).level = .debug
      }
			updater.check_curl_tar()!
      updater.check_target_dir()!
			updater.update_all(cmd.args)
		}
    commands: [
      Command{
        name: 'list'
        description: 'list available apps'
        execute: fn (cmd Command) ! {
          updater.print_available_apps()
        }
      }
    ]
	}

	app.setup()
	app.parse(arguments())
}
