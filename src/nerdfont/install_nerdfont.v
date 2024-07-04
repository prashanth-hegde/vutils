import os

fn install_nerdfont(keys []string, partial_match bool) ! {
	if keys.len == 0 {
		return error('no font name provided')
	}
	font_dir := match os.user_os() {
		'linux' { '${os.home_dir()}/.local/share/fonts' }
		'macos' { '${os.home_dir()}/Library/Fonts' }
		else { return error('unsupported os: ${os.user_os()}') }
	}

	os.mkdir_all(font_dir) or {
		log.debug('font directory already exists: ${font_dir}, not creating any')
	}
	// this search is always partial match
	font_assets := search_nerdfont(keys) !

	filtered_assets := if partial_match {
		font_assets.filter(it.name.contains_any_substr(keys))
	} else {
		full_name_keys := keys.map('${it}.tar.xz')
		font_assets.filter(it.name in full_name_keys)
	}

	for font in filtered_assets {
		log.info('installing font: ${font.name}')
		cmd := 'curl -L "${font.browser_download_url}" | tar -xf - -C "${font_dir}" --keep-newer-files'
		log.debug('curl: \n====\n${cmd}\n===\n')
		os.execute_opt(cmd) or {
			log.error('failed to download and extract font ${font.name}: $err')
		}
	}
}
