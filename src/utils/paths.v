import os

const max_depth_for_bin_search = 2

fn abs_path(it string) string {
	return if it.starts_with('~') {
		os.expand_tilde_to_home(it)
	} else {
		it
	}
}

fn find_bin_dirs_in_path(path string, depth int) []string {
	return match true {
		depth > max_depth_for_bin_search || !os.is_dir(path) {
			[]
		}
		os.is_dir(path) && path.ends_with('bin') {
			[path]
		}
		else {
			subdirs := os.ls(path) or { [] }
			mut paths := []string{cap: 10}
			for s in subdirs {
				subdir := os.join_path(path, s)
				paths << find_bin_dirs_in_path(subdir, depth + 1)
			}
			paths
		}
	}
}

// find binary paths for one and two levels deep
fn get_app_paths(app_root []string) []string {
	mut paths := []string{}
	for path in app_root {
		paths << find_bin_dirs_in_path(abs_path(path), 0)
	}
	return paths
}

fn get_custom_paths() []string {
	custom_path_config := abs_path('~/.config/paths')
	return if os.exists(custom_path_config) {
		lines := os.read_lines(custom_path_config) or { [] }

		lines
			.map(it.trim_space())
			.map(abs_path(it))
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
	app_paths := [
		'~',
		'~/apps',
		'/',
		'/usr/local',
		'/opt/homebrew/bin'
	]

	mut paths := []string{cap: 20}
	paths << get_app_paths(app_paths)
	paths << get_java_paths()
	paths << get_custom_paths()

	println(paths.join('\n'))
}
