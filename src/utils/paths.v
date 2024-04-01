import os
import common { resolve_path }

const home = os.home_dir()

fn get_app_paths(app_root []string) []string {
	mut paths := []string{}
	for path in app_root {
		mut bin_path_found := false
		if os.exists('${path}/bin') {
			paths << '${path}/bin'
			bin_path_found = true
		}
		if os.exists('${path}/sbin') {
			paths << '${path}/sbin'
			bin_path_found = true
		}
		if !bin_path_found {
			for file in (os.ls('${path}') or { [] }) {
				if os.is_executable(file) {
					paths << '${app_root}'
					break
				}
			}
		}
	}
	return paths
}

fn get_custom_paths() []string {
	custom_path_config := resolve_path('~/.config/paths')
	return if os.exists(custom_path_config) {
		lines := os.read_lines(custom_path_config) or {[]}
		lines
			.map(it.trim_space())
			.filter(it != '' && os.exists(it))
	} else {
		[]string{}
	}
}

fn get_java_paths() []string {
	// using closure to capture changes
	add_java_path := fn () fn (path string) []string {
		mut java_paths := []string{}
		return fn [mut java_paths] (path string) []string {
			if path != '' {
				java_paths << path
			}
			return java_paths
		}
	}

	match os.user_os() {
		'macos' {
			java_root_path := '/Library/Java/JavaVirtualMachines'
			java_paths := add_java_path()
			os.walk(java_root_path, fn [java_paths] (path string) {
				if path.ends_with('java') && os.is_executable(path) {
					java_paths(os.dir(path))
				}
			})
			return java_paths('')
		}
		'linux' {
			// log.warn('TBD: linux java paths')
		}
		else {
			// log.error('not macos or linux, unable to determine java path')
		}
	}
	return []
}

fn main() {
	default_paths := [
		'/bin',
		'/usr/bin',
		'/sbin',
		'/usr/sbin',
		'/usr/local/bin',
		'/usr/local/sbin',
		'${home}/bin',
		'${home}/scripts',
	]

	app_paths := [
		'/opt/homebrew',
		'${home}/.local',
		'${home}/apps/go',
		'${home}/apps/kafka',
		'${home}/apps/node',
		'${home}/apps/python',
		'/usr/local/share/dotnet',
	]

	mut paths := default_paths.clone()
	paths << app_paths
	paths << get_java_paths()
	paths << get_custom_paths()

	println(paths.join('\n'))
}
