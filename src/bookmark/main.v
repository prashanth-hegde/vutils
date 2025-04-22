import cli { Command, Flag }
import os
import json

const config_path = os.join_path(os.home_dir(), '.config', 'goto.json')

fn cmd_parser() {
	mut config := json.decode([]Bookmark, os.read_file(config_path) or { '[]' }) or { []Bookmark{} }

	mut main_cmd := Command{
		name:          'goto'
		description:   'A simple tool to navigate to a directory'
		version:       '0.0.1'
		required_args: 1
		execute:       fn [config] (cmd Command) ! {
			path := config.goto(cmd.args[0])!
			println(path)
		}
		commands:      [
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
				flags:         [
					Flag{
						name:        'short'
						abbrev:      's'
						description: 'print only (short) names of the shortcuts'
						flag:        .bool
					},
				]
				execute:       fn [mut config] (cmd Command) ! {
					short := cmd.flags.get_bool('short') or { false }
					nm := 'name'
					if short {
						println(config.map(it.name).join('\n'))
					} else {
						println('${nm:15} | path')
						for c in config {
							println('${c.name:15} | ${c.path}')
						}
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
			Command{
				name:          'setup'
				description:   'Shell completion scripts'
				required_args: 0
				flags:         [
					Flag{
						name:        'shell'
						abbrev:      's'
						description: 'Setup scripts for shell'
						flag:        .string
						required:    true
					},
				]
				execute:       fn (cmd Command) ! {
					shell := cmd.flags.get_string('shell') or { 'fish' }
					embed_data := match shell {
						'fish' { $embed_file('setup.fish') }
						else { $embed_file('setup.fish') }
					}
					println(embed_data.to_string())
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
