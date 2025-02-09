module common

/*
This helper function is used to write beautiful shell scripts. It uses the popular `gum` module
https://github.com/charmbracelet/gum
*/
import os
import net.http
import json
import io.util

// ============ Public functions ============
// get_asset_for_repo fetches the latest release of the given repo and returns the asset that can be downloaded
// It is the caller's responsibility to delete the temporary directory and executables
// This function only downloads and returns the directory and executables
// No need to worry about cleanup if it returns an error
pub fn download_assets_for_repo(repo string) !(string, []string) {
	check_for_installed_programs(['tar', 'unzip'])!
	asset := get_asset_for_repo(repo)!
	return asset.download_and_extract()!
}

// ============ Constants & Structs ============
const allowed_asset_types_wave_1 = [
	'application/gzip',
	'application/x-gtar',
	'application/zip',
]

const allowed_asset_types_wave_2 = [
	'application/octet-stream',
	'binary/octet-stream',
]

struct Release {
	id           u64
	published_at string
	node_id      string
	assets       []ReleaseAsset
}

struct ReleaseAsset {
	url                  string
	name                 string
	content_type         string
	browser_download_url string
}

// ============ Main Functions ============

// get_downloadable_assets returns the list of downloadable assets from the release. The json contains sha, txt and other file formats.
// We are only interested in tar/gz, zip, etc
fn (r Release) get_asset_for_os_arch(allowed []string) !ReleaseAsset {
	allowed_assets := r.assets.filter(it.content_type.contains_any_substr(allowed))
	// dump(allowed_assets)

	// Step 1: Determine os and arch
	uname := os.uname()

	// Step 2: Filter only the assets for the current os
	os_mapping := {
		'linux':   ['linux']
		'darwin':  ['darwin', 'macos', 'mac']
		'windows': ['windows']
	}
	curr_os_names := os_mapping[uname.sysname.to_lower()]
	os_assets := allowed_assets.filter(it.name.to_lower().contains_any_substr(curr_os_names))
	// dump(os_assets)

	// Step 3: Filter only the assets for the current arch
	arch_mapping := {
		'x86_64':  ['amd64', 'x86_64', 'x86-64', 'x64']
		'aarch64': ['aarch64', 'arm64']
		'arm64':   ['aarch64', 'arm64']
		'arm':     ['arm']
	}
	curr_arch_names := arch_mapping[uname.machine.to_lower()]
	arch_assets := os_assets.filter(it.name.to_lower().contains_any_substr(curr_arch_names))

	trace := 'os=${uname.sysname}, arch=${uname.machine}, assets=${os_assets.map(it.name)}'
	return match arch_assets.len {
		0 {
			error('no assets found for ${trace}')
		}
		1 {
			arch_assets[0]
		}
		else {
			// This is a special case. One common scenario is the linux has `musl` and `glibc` versions. Handle it
			if uname.sysname.to_lower() == 'linux' {
				get_glibc_or_musl_asset(arch_assets) or {
					error('unable to determine glibc or musl asset for ${trace}')
				}
			} else {
				error('multiple assets found for ${trace}')
			}
		}
	}
}

// download_and_extract downloads the asset and extracts it to a temporary directory. Returns the extract directory and the list of executables in the extracted directory
// It is the responsibility of the caller to remove the extracted directory
fn (a ReleaseAsset) download_and_extract() !(string, []string) {
	// Step 1: Download the asset
	asset_path := os.join_path(os.temp_dir(), a.name)
	extract_path := util.temp_dir(pattern: 'updater')!

	defer {
		os.rm(asset_path) or { eprintln('unable to remove downloaded asset at ${asset_path}') }
	}

	http.download_file(a.browser_download_url, asset_path)!
	cmd := match true {
		a.name.ends_with('.tar.gz') || a.name.ends_with('.tgz') {
			'tar -xzf "${asset_path}" -C "${extract_path}"'
		}
		a.name.ends_with('.tar') || a.name.ends_with('.tar.xz') {
			'tar -xf ${asset_path} -C "${extract_path}"'
		}
		a.name.ends_with('.zip') {
			'unzip -o ${asset_path} -d "${extract_path}"'
		}
		else {
			// ensure to delete temp directory also
			os.rmdir_all(extract_path)!
			return error('unsupported archive format: ${a.name}')
		}
	}

	// execute the unzip or tar command to extract the archive
	os.execute_opt(cmd) or {
		os.rmdir_all(extract_path)!
		return error('unable to extract archive: ${a.name}, ${err}')
	}

	// find all executables in the extracted directory
	mut exe := &[]string{}
	os.walk(extract_path, fn [mut exe] (path string) {
		if os.is_executable(path) {
			exe << path
		}
	})

	return extract_path, *exe
}

/// get_asset_for_repo
/// This function does the following
/// 1. Fetches the latest release of `gum` from github
/// 2. Downloads the release tarball
/// 3. Extracts the tarball and puts it in /tmp/gum as executable
fn get_asset_for_repo(repo string) !ReleaseAsset {
	headers := http.new_header_from_map({
		.accept:     'application/vnd.github.v3+json'
		.user_agent: 'curl/8.7.1'
		.authority:  'github.com'
	})
	resp := http.fetch(
		method: .get
		url:    'https://api.github.com/repos/${repo}/releases/latest?per_page=1'
		header: headers
	)!

	if resp.status_code != 200 {
		return error('unable to fetch gum release from github. please check the url: code=${resp.status_code}, url=${repo}')
	}

	decoded := json.decode(Release, resp.body)!
	// dump(decoded.assets.map('\n${it.name} | ${it.content_type}'))

	// github releases are weird
	// There are some applications that mark `.tar.gz` as `application/octet-stream` and some as `application/gzip` and `application/x-gtar`
	// So we need to check for both
	// We need to make two passes unfortunately. One for wave 1 and another for wave 2
	// Example: `fzf` marks their `.tar.gz` as `application/octet-stream`
	// Example: `ripgrep` marks their `.tar.gz` as `application/x-gtar`
	// Example: `bat` marks their `.tar.gz` as `application/gzip`

	return decoded.get_asset_for_os_arch(allowed_asset_types_wave_1) or {
		decoded.get_asset_for_os_arch(allowed_asset_types_wave_2)!
	}
}

// ============ Helper Functions ============

/// get_glibc_or_musl_asset
/// This function is used to determine if the current system is using musl or glibc and return the appropriate asset from the given list
fn get_glibc_or_musl_asset(assets []ReleaseAsset) !ReleaseAsset {
	is_musl := os.walk_ext('/proc/self/map_files/', '')
		.map(os.real_path(it))
		.any(it.contains('musl'))

	return if is_musl {
		musl_assets := assets.filter(it.name.to_lower().contains('musl'))
		if musl_assets.len == 1 {
			musl_assets[0]
		} else {
			error('unknown musl assets found')
		}
	} else {
		glibc_assets := assets.filter(!it.name.to_lower().contains('musl'))
		if glibc_assets.len == 1 {
			glibc_assets[0]
		} else {
			error('unknown glibc assets found')
		}
	}
}
