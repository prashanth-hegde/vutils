module updater

import common { Log, download_assets_for_repo }
import os

pub const log = &Log{.info}
const apps = {
	'rg':         'BurntSushi/ripgrep'
	'bat':        'sharkdp/bat'
	'fd':         'sharkdp/fd'
	'fzf':        'junegunn/fzf'
	'zoxide':     'ajeetdsouza/zoxide'
	'vutils':     'prashanth-hegde/vutils'
	'f2':         'ayoisaiah/f2'
	'lazygit':    'jesseduffield/lazygit'
	'lazydocker': 'jesseduffield/lazydocker'
	'aichat':     'sigoden/aichat'
	'procs':      'dalance/procs'
	'gum':        'charmbracelet/gum'
	'ls':         'Equationzhao/g'
}

pub fn update_all(appnames []string)! {
	for app in appnames {
		if app !in apps {
			log.error('app "${app}" not found or configured')
			continue
		}
		path, exe := download_assets_for_repo(apps[app])!
		dest := os.join_path(os.home_dir(), 'bin')
		for item in exe {
			log.info('updating ${os.file_name(item)}')
			os.mv(item, dest) or { log.error('unable to move ${item}') }
			log.info('updated ${os.file_name(item)}')
		}
		os.rmdir_all(path) or { log.error('unable to remove ${path}') }
	}
}

pub fn print_available_apps() {
	println('Available apps:')
	keys := apps.keys()
	println(keys.sorted().join('\n'))
}
