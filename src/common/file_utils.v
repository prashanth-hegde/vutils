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

pub fn choose_fzf(items []string) !string {
	// Find fzf in PATH
	fzf_exe := os.find_abs_path_of_executable('fzf')!

	// Create a new process and set up stdio redirection
	mut p := os.new_process(fzf_exe)
	p.set_redirect_stdio()

	// Start the fzf process
	p.run()

	// Write each item (one per line) to fzf's stdin
	for item in items {
		p.stdin_write(item + '\n')
	}

	// Wait for the process to finish
	p.wait()

	// Read all output from stdout
	mut output := ''
	for {
		line := p.stdout_read()
		if line.len == 0 {
			break
		}
		output += line
	}

	// Trim and return the chosen item
	return output.trim_space()
}
