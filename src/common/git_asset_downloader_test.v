module common

import os

const apps = {
	'rg': 'BurntSushi/ripgrep'
	// 'bat': 'sharkdp/bat'
	// 'fd':  'sharkdp/fd'
	// 'fzf': 'junegunn/fzf'
	// 'zoxide':     'ajeetdsouza/zoxide'
	// 'neovim':     'neovim/neovim'
	// 'helix':      'helix-editor/helix'
	// 'vutils':     'prashanth-hegde/vutils'
	// 'f2':         'ayoisaiah/f2'
	// 'lazygit':    'jesseduffield/lazygit'
	// 'lazydocker': 'jesseduffield/lazydocker'
	// 'aichat':     'sigoden/aichat'
	// 'just':       'casey/just'
	// 'procs':      'dalance/procs'
	// 'gum':        'charmbracelet/gum'
}

fn test_downloader() {
	if os.getenv_opt('RUN_NETWORK_TESTS') or { '' } == '' {
		eprintln('skipping network tests: set RUN_NETWORK_TESTS=1 to enable')
		return
	}
	for k, v in apps {
		asset := get_asset_for_repo(v) or {
			assert false, 'failed to get asset for ${k}: ${err}'
			return
		}
		extract_dir, exe := asset.download_and_extract() or {
			assert false, 'failed to download and extract asset for ${k}: ${err}'
			return
		}

		// check that temp downloaded tar/zip file is no longer present
		dump(exe)
		assert exe.len > 0
		assert !os.exists(os.join_path(os.temp_dir(), asset.name))
		// remove extracted directory
		os.rmdir_all(extract_dir)!

		// check that temporary directories are cleaned up
		assert !os.exists(extract_dir)
	}
}
