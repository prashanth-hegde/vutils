module main

import os
import cli { Command, Flag }
import docgen { run_docgen, DocgenConfig }

fn main() {
	mut app := Command{
		name:        'docgen'
		description: 'generate outputs to generate output file to feed into LLMs. Works for projects, directories, files, etc'
		execute:     fn (cmd Command) ! {
			mut cli_dir := cmd.flags.get_string('dir') or {''}
			if cli_dir == '' {
				cli_dir = os.getwd()
			}

			mut config := DocgenConfig{
				verbose:   cmd.flags.get_bool('verbose') or { false }
				extension: cmd.flags.get_strings('extension') or { []string{} }
				output:    cmd.flags.get_string('output') or { '' }
				stat:      cmd.flags.get_bool('stat') or { false }
				dir:       cli_dir
				recurse:   cmd.flags.get_bool('recurse') or { false }
			}

			run_docgen(config)!
		}

		flags: [
			Flag{
				name:        'verbose'
				abbrev:      'v'
				description: 'set verbose logging'
				global:      true
				flag:        .bool
				required:    false
			},
			Flag{
				name:        'extension'
				abbrev:      'e'
				description: 'extension to process'
				flag:        .string_array
				required:    false
			},
			Flag{
				name:        'output'
				abbrev:      'o'
				description: 'output file'
				flag:        .string
				required:    false
			},
			Flag{
				name:        'stat'
				abbrev:      's'
				description: 'generate statistics for generated output'
				flag:        .bool
				required:    false
			},
			Flag{
				name:        'dir'
				abbrev:      'd'
				description: 'directory to process'
				flag:        .string
				required:    false
			},
			Flag{
				name:        'recurse'
				abbrev:      'r'
				description: 'recursively process directories'
				flag:        .bool
				required:    false
			},
		]
	}

	app.setup()
	app.parse(arguments())
}
