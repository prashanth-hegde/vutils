module filecache

import common { Log, parse_human_duration }
import os
import time

pub const log = &Log{.info}

pub fn reload_cache() ! {
	cfg := parse_config()!
	exclude_list := cfg.ignore.map('--exclude "${it}"')
	exclude_expr := exclude_list.join(' ')

	os.rm(os.expand_tilde_to_home(cfg.target))!
	for dir_ in cfg.dirs {
		dir := os.expand_tilde_to_home(dir_)
		filecache.log.debug('checking ${dir}')
		if !os.is_dir(dir) {
			continue
		}
		filecache.log.debug('scanning ${dir}')
		cmd := 'fd --hidden --follow --absolute-path ${exclude_expr} . "${dir}" >> ${cfg.target}'
		os.execute_opt(cmd) or {
			msg := '${time.now()}: failed to refresh cache, error: ${err}'
			mut log_file := os.open_append(cfg.log)!
			log_file.writeln(msg)!
			return error(msg)
		}
	}

	write_and_trim_log()!
}

pub fn run_forever() ! {
	for {
		reload_cache()!
		cfg := parse_config()!
		interval := parse_human_duration(cfg.interval)
		time.sleep(interval * time.second)
	}
}

fn write_and_trim_log() ! {
	cfg := parse_config()!
	log_file := os.expand_tilde_to_home(cfg.log)
	msg := '${time.now()}: successfully written to fzf cache'
	if !os.exists(log_file) {
		os.write_file(log_file, msg)!
	} else {
		mut lfile := os.open_append(log_file)!
		lfile.writeln(msg)!
	}
	os.execute_opt('tail -n 1000 ${log_file} > /tmp/one && mv /tmp/one ${log_file}')!
}

// ======= Helper functions ========
pub fn check_fd() ! {
	os.execute_opt('which fd') or { return error('fd is not installed') }
}
