module updater

import json
import os

fn test_fetch_assets() {
	appname := 'rg'
	appurl := 'junegunn/fzf'

	get_binary(appname, appurl) or { assert false, 'Failed to fetch assets' }
}

fn test_curl_tar() {
	check_curl_tar() or { assert false, 'Failed to fetch assets' }
}

fn test_get_binary() ! {
	appname := 'rg'
	appurl := 'junegunn/fzf'
	release_url := 'https://api.github.com/repos/${appurl}/releases/latest?per_page=3'

	resp := os.execute('curl -s -H "Accept: application/vnd.github.v3+json" ${release_url}')
	release := json.decode(Release, resp.output)!

	oses := ['linux', 'darwin', 'macos']
	archs := ['amd64', 'arm64', 'x86_64']

	for os_ in oses {
		for arch in archs {
			asset := release.get_asset(os_, arch) or {
				assert false, 'Failed to fetch assets for ${os_}, ${arch}'
				continue
			}
		}
	}
}
