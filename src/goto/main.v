import cli { Command }
import os
import json

const config_path = os.join_path(os.home_dir(), '.config', 'goto.json')

fn cmd_parser() {
	mut config := json.decode([]Goto, os.read_file(config_path) or { '[]' }) or { []Goto{} }

	mut main_cmd := Command{
		name:        'goto'
		description: 'A simple tool to navigate to a directory'
		version:     '0.0.1'
		execute:     fn (cmd Command) ! {
			println('main command executed')
		}
		commands:    [
			Command{
				name:          'add'
				description:   'Adds current directory to the list with a preferred name'
				required_args: 1
				execute:       fn [mut config] (cmd Command) ! {
					name := cmd.args[0]
					path := os.getwd()
					config.add(name, path)!
				}
			},
			Command{
				name:          'ls'
				description:   'List all the bookmarked directories'
				required_args: 0
				execute:       fn [mut config] (cmd Command) ! {
					nm := 'name'
					println('${nm:15} | path')
					for c in config {
						println('${c.name:15} | ${c.path}')
					}
				}
			},
			Command{
				name:          'rm'
				description:   'Remove a directory from the list'
				required_args: 0
				execute:       fn [mut config] (cmd Command) ! {
					if cmd.args.len == 1 {
						config.remove_name(cmd.args[0])!
					} else {
						config.remove_path(os.getwd())!
					}
				}
			},
			Command{
				name:          'clean'
				description:   'Remove all the directories that do not exist'
				required_args: 0
				execute:       fn [mut config] (cmd Command) ! {
					config.clean()!
				}
			},
		]
	}
	main_cmd.setup()
	main_cmd.parse(arguments())
}

fn main() {
	cmd_parser()
}
