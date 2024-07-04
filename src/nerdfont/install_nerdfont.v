import os

fn install_nerdfont(keys []string) ! {
	font_dir := match os.user_os() {
		'linux' { '${os.home_dir()}/.local/share/fonts' }
		'macos' { '${os.home_dir()}/Library/Fonts' }
		else { return error('unsupported os: ${os.user_os()}') }
	}

	os.mkdir_all(font_dir) or {
		log.debug('font directory already exists: ${font_dir}, not creating any')
	}
	font_assets := search_nerdfont(keys) !
	for font in font_assets {
		log.info('installing font: ${font.name}')
		cmd := 'curl -L "${font.browser_download_url}" | tar -xf - -C "${font_dir}" --keep-newer-files'
		log.debug('curl: \n====\n${cmd}\n===\n')
		os.execute_opt(cmd) or {
			log.error('failed to download and extract font ${font.name}: $err')
		}
	}
}
