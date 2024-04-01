module filecache

import toml
import os

struct Config {
	interval string = '4h'
	target   string = '~/.cache/fzf'
	log      string = '~/.cache/fzf.log'

	dirs []string = [
	'~/dev',
	'/mnt/passport/Series',
	'/mnt/passport/Movies',
]
	ignore []string = [
	'build',
	'out',
	'bin',
	'node_modules',
	'.git',
	'.idea',
	'.gradle',
	'.DS_Store',
	'.vscode',
	'.venv',
]
}

fn parse_config() !Config {
	override_config_path := os.join_path(os.home_dir(), '.config', 'filecache.toml')
	return if os.exists(override_config_path) {
		doc := toml.parse_file(override_config_path)!
		doc.decode[Config]()!
	} else {
		Config{}
	}
}
