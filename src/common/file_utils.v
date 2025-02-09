module common

import os

pub const bin_path = os.join_path(os.home_dir(), 'bin')
pub const cfg_path = os.join_path(os.home_dir(), '.config')

pub fn resolve_path(paths ...string) string {
	mut path := ''
	for p in paths {
		if path == '' {
			path = os.expand_tilde_to_home(p)
		} else {
			path = os.join_path(path, p)
		}
	}
	return path
}

pub fn check_for_installed_programs(pgms []string) ![]string {
	error_msg := 'you need to have ${pgms} installed to use this'
	return pgms.map(os.find_abs_path_of_executable(it) or {
		return error('${error_msg}, missing ${it}')
	})
}
