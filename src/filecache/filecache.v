module filecache

import common { Log, parse_human_duration }
import os
import time

pub const log = &Log{.info}

pub fn reload_cache(fd_path string) ! {
	cfg := parse_config()!
	exclude_list := cfg.ignore.map('--exclude "${it}"')
	exclude_expr := exclude_list.join(' ')

	os.rm(os.expand_tilde_to_home(cfg.target)) or {}
	for dir_ in cfg.dirs {
		dir := os.expand_tilde_to_home(dir_)
		filecache.log.debug('checking ${dir}')
		if !os.is_dir(dir) {
			continue
		}
		cmd := '${fd_path} --hidden --follow --absolute-path ${exclude_expr} . "${dir}" >> ${cfg.target}'
		filecache.log.debug('scanning ${dir}: ${cmd}')
		os.execute_opt(cmd) or {
			msg := '${time.now()}: failed to refresh cache, error: ${err}'
			mut log_file := os.open_append(cfg.log)!
			log_file.writeln(msg)!
			return error(msg)
		}
	}

	write_and_trim_log()!
}

pub fn run_forever(fd_path string) ! {
	for {
		reload_cache(fd_path)!
		cfg := parse_config()!
		interval := parse_human_duration(cfg.interval)
		time.sleep(interval * time.second)
	}
}

fn write_and_trim_log() ! {
	cfg := parse_config()!
	log_file := os.expand_tilde_to_home(cfg.log)
	msg := '${time.now()}: successfully written to fzf cache'
	mut lfile := os.open_file(log_file, 'a+')!
	lfile.writeln(msg)!
	lfile.close()
	os.execute_opt('tail -n 100 ${log_file} > /tmp/one && mv /tmp/one ${log_file}')!
}

// ======= Helper functions ========
pub fn check_fd() !string {
	log.debug('checking fd')
	exepath := os.find_abs_path_of_executable('fd') or {
		log.debug('did not find fd in PATH, checking in home directory')
		fd_path := os.join_path(os.home_dir(), 'bin', 'fd')
		return if os.exists(fd_path) && os.is_executable(fd_path) {
			log.debug('found fd in home directory')
			fd_path
		} else {
			error('fd is not installed')
		}
	}
	return exepath
}
