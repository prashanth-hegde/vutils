module updater

import common { Log }
import os
import io.util
import json

pub const log = &Log{.info}
const apps = {
	'rg':         'BurntSushi/ripgrep'
	'bat':        'sharkdp/bat'
	'fd':         'sharkdp/fd'
	'fzf':        'junegunn/fzf'
	'zoxide':     'ajeetdsouza/zoxide'
	'exa':        'ogham/exa'
	'btm':        'clementsan/bottom'
	'neovim':     'neovim/neovim'
	'helix':      'helix-editor/helix'
	'vutils':     'prashanth-hegde/vutils'
	'f2':         'ayoisaiah/f2'
	'eza':        'eza-community/eza'
	'lazygit':    'jesseduffield/lazygit'
	'lazydocker': 'jesseduffield/lazydocker'
	'aichat':     'sigoden/aichat'
}

pub struct Asset {
pub mut:
	url  string
	id   string
	name string
}

pub struct Release {
pub mut:
	id           u64
	published_at string
	node_id      string
	assets       []struct {
	pub mut:
		url                  string
		name                 string
		browser_download_url string
	}
}

pub fn (rel Release) get_asset(asset_os string, arch string) !string {
	required_os, required_arch := get_os_arch_from_release(asset_os.to_lower() + arch.to_lower())!

	for asset in rel.assets {
		release_os, release_arch := get_os_arch_from_release(asset.name.to_lower()) or { continue }
		if release_os == required_os && release_arch == required_arch {
			return asset.browser_download_url
		}
	}
	return error('no asset found for ${asset_os} ${arch}')
}

fn get_os_arch_from_release(rel_name string) !(string, string) {
	mut os_ := ''
	mut arch_ := ''
	if rel_name.contains('linux') {
		os_ = 'linux'
	} else if rel_name.contains_any_substr(['darwin', 'mac']) {
		os_ = 'mac'
	} else if rel_name.contains('windows') {
		os_ = 'windows'
	} else {
		return error('unknown os')
	}

	if rel_name.contains_any_substr(['x86_64', 'x86-64', 'amd64', 'x64']) {
		arch_ = 'amd64'
	} else if rel_name.contains_any_substr(['aarch64', 'arm64']) {
		arch_ = 'arm64'
	} else if rel_name.contains('arm') {
		arch_ = 'arm'
	} else {
		return error('unknown arch')
	}

	return os_, arch_
}

fn get_asset_url(appname string, appurl string) !string {
	// github url for latest release
	release_url := 'https://api.github.com/repos/${appurl}/releases/latest?per_page=3'

	resp := os.execute_opt('curl -s -H "Accept: application/vnd.github.v3+json" ${release_url}') or {
		updater.log.error('unable to get releases for ${appname}: ${err}')
		return err
	}

	mut release := json.decode(Release, resp.output) or {
		updater.log.error('unable to decode releases for ${appname}: ${err}')
		return err
	}

	uname := os.uname()
	mut asset_url := ''
	if uname.sysname == 'Linux' && uname.machine == 'x86_64' {
		// linux x64
		updater.log.debug('os = linux x64')
		asset_url = release.get_asset('linux', 'x86_64')!
	} else if uname.sysname == 'Darwin' && uname.machine == 'arm64' {
		// mac
		updater.log.debug('os = mac arm64')
		asset_url = release.get_asset('mac', 'arm64')!
	} else if uname.sysname == 'Darwin' && uname.machine == 'x86_64' {
		updater.log.debug('os = mac x64')
		asset_url = release.get_asset('mac', 'x86_64')!
	} else if uname.sysname == 'Linux' && uname.machine == 'arm64' {
		updater.log.debug('os = linux arm64')
		asset_url = release.get_asset('linux', 'arm64')!
	} else {
		// log.error("unsupported os")
		return error('unsupported os')
	}

	updater.log.debug('asset_url = ${asset_url}')
	return asset_url
}

fn download_and_extract(asset_url string) ! {
	tmp_dir := util.temp_dir() or { return error('unable to create tmp dir, ${err}') }
	asset_name := os.join_path(tmp_dir, 'asset.tgz')
	updater.log.debug('downloading and extracting to ${tmp_dir}')
	os.execute_opt('curl -sL ${asset_url} -o "${asset_name}"') or {
		return error('unable to download ${asset_url}, ${err}')
	}
	os.execute_opt('tar -xzf "${asset_name}" -C "${tmp_dir}"') or {
		os.execute_opt('tar -xf "${asset_name}" -C "${tmp_dir}"') or {
			return error('unable to extract ${asset_name}, ${err}')
		}
	}
	updater.log.debug('extracted contents to ${tmp_dir}')

	// move to target dir
	target_dir := os.join_path(os.home_dir(), 'bin')
	os.walk(tmp_dir, fn [target_dir] (path string) {
		if os.is_executable(path) {
			updater.log.info('updated ${os.base(path)}')
			os.mv(path, target_dir) or {
				updater.log.error('unable to move ${path} to ${target_dir}, ${err}')
			}
		}
	})
	os.rmdir_all(tmp_dir)!
	updater.log.debug('removed temp dir ${tmp_dir}')
}

fn updater(appname string) ! {
	updater.log.debug('sysname = ${os.uname()}')
	if appname != '' {
		updater.log.info('updating ${appname}')
		appurl := updater.apps[appname]
		if appurl == '' {
			updater.log.error('app ${appname} not found')
		}
		asset_url := get_asset_url(appname, appurl)!
		download_and_extract(asset_url)!
	} else {
		updater.log.info('updating all apps')
	}
}

pub fn update_all(appnames []string) {
	all_apps := if appnames.len == 0 { updater.apps.keys() } else { appnames }
	for app in all_apps {
		updater(app) or { updater.log.error('unable to update ${app}, ${err}') }
	}
}

// ======= Helper functions ======

// check_curl_tar checks if curl and tar are installed
pub fn check_curl_tar() ! {
	updater.log.debug('checking curl and tar')
	os.execute_opt('which curl') or { return error('curl is not installed') }

	os.execute_opt('which tar') or { return error('tar is not installed') }
}

pub fn check_target_dir() ! {
	updater.log.debug('checking target directory')
	target_dir := os.join_path(os.home_dir(), 'bin')
	good := os.exists(target_dir) && os.is_dir(target_dir)
	if !good {
		return error('target directory ${target_dir} does not exist or is not a directory')
	}
}

pub fn print_available_apps() {
	println('Available apps:')
	keys := updater.apps.keys()
	println(keys.sorted().join('\n'))
}
