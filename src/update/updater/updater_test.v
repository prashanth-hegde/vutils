module updater

import json
import os

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

struct ArchNames {
	os_ string
	arch string
	name string
	err bool
}
fn test_release_names() ! {
	rel_names := [
		ArchNames{os_: 'linux', arch: 'amd64', name: 'f2_1.9.1_linux_amd64.tar.gz'},
	]

	for rel_name in rel_names {
		os_, arch_ := get_os_arch_from_release(rel_name.name)!
		assert rel_name.os_ == os_, 'Failed to get os from release'
		assert rel_name.arch == arch_, 'Failed to get arch from release'
	}
}
