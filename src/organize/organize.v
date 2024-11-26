module main

import os
import time
import cli { Command, Flag }
import common { Log }
import arrays { flatten }

const log = &Log{}
const image_exts = ['jpg', 'jpeg', 'heic', 'webp', 'mov', 'mp4']

fn convert_heic_to_jpg(glob_patterns []string, recurse bool) ! {
	ffmpeg := os.find_abs_path_of_executable('ffmpeg') or {
		return error('ffmpeg not installed, aborting...')
	}
	filenames := list_files_for_glob(glob_patterns, recurse)!.filter(it.ends_with('.heic'))
	dirname := os.join_path(os.getwd(), 'heic-bak')
	if !os.exists(dirname) {
		os.mkdir(dirname)!
	}
	for filename in filenames {
		base_name := os.file_name(filename).rsplit_nth('.', 2)[1]
		cmd := '${ffmpeg} -i ${filename} ${base_name}.jpg'
		log.debug('converting ${filename}: ${cmd}')
		os.execute_opt(cmd) or {
			log.error('failed to convert ${filename}, cmd=${cmd}')
			continue
		}
		os.mv(filename, dirname) or {
			log.error('failed to move ${filename} to ${dirname}')
		}
	}
}

fn organize_by_date(glob_patterns []string, recurse bool) ! {
	// for all the glob patterns, get the list of files
	all_files := list_files_for_glob(glob_patterns, recurse)!
	for filename in all_files {
		file_stat := os.lstat(filename) or {
			log.error('failed to get file info for ${filename}')
			continue
		}
		epoch := time.unix(file_stat.mtime)
		dirname := os.join_path('${epoch.year}', '${epoch.year}${epoch.month:02}${epoch.day:02}')
		if !os.exists(dirname) {
			os.mkdir_all(dirname) or {
				log.error('failed to create directory ${dirname}')
				continue
			}
		}
		log.debug('moving ${filename} to ${dirname}')
		os.mv(filename, dirname) or { log.error('failed to move ${filename} to ${dirname}') }
	}
}

fn list_files(root_path string, recurse bool) []string {
	return if recurse {
		all_files_list := image_exts.map(os.walk_ext(root_path, it))
		flatten(all_files_list)
	} else {
		all_files_list := os.ls(root_path) or {
			log.warn('did not find any relevant files in ${root_path}')
			[]
		}
		mut relevant_files := []string{len: all_files_list.len}
		dot_exts := image_exts.map('.${it}')
		for file in all_files_list {
			if os.is_file(file) && dot_exts.contains(os.file_ext(file)) {
				relevant_files << file
			}
		}
		relevant_files
	}
}

fn list_files_for_glob(glob_patterns []string, recurse bool) ![]string {
	mut all_filenames := []string{cap: 5000}
	for path in os.glob(...glob_patterns)! {
		if os.is_dir(path) {
			all_filenames << list_files(path, recurse)
		} else {
			file_ext := os.file_ext(path)
			dot_exts := image_exts.map('.${it}')
			if file_ext != '' && dot_exts.contains(file_ext) {
				all_filenames << path
			}
		}
	}
	return all_filenames.filter(it.len > 0)
}

fn main() {
	mut app := Command{
		name:        'organize'
		description: 'organized files by creating directories based on the file creation year and month'
		flags:       [
			Flag{
				name:        'verbose'
				abbrev:      'v'
				flag:        .bool
				description: 'print verbose output'
			},
			Flag{
				name:        'recurse'
				abbrev:      'R'
				flag:        .bool
				description: 'recursively search and convert'
			},
			Flag{
				name:        'convert'
				abbrev:      'c'
				flag:        .bool
				description: 'convert heic to jpg before organizing'
			},
		]
		execute:     fn (cmd Command) ! {
			if cmd.flags.get_bool('verbose') or { false } {
				(*log).level = .debug
			}
			file_glob := if cmd.args.len == 0 {
				image_exts
			} else {
				cmd.args
			}
			recurse := cmd.flags.get_bool('recurse') or { false }
			if cmd.flags.get_bool('convert') or { false } {
				convert_heic_to_jpg(file_glob, recurse)!
			}
			organize_by_date(file_glob, recurse)!
		}
	}

	app.setup()
	app.parse(arguments())
}
