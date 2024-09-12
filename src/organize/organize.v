import os
import time
import cli { Command, Flag }
import common { Log }
import arrays.parallel

const log = &Log{}

fn convert_heic_to_jpg(glob_patterns []string) ! {
	ffmpeg := os.find_abs_path_of_executable('ffmpeg') or {
		return error('ffmpeg not installed, aborting...')
	}
	filtered_globs := glob_patterns.filter(it.contains('heic'))
	filenames := os.glob(...filtered_globs)!
	dirname := os.join_path(os.getwd(), 'heic-bak')
	if !os.exists(dirname) {
		os.mkdir(dirname)!
	}
	parallel.run(filenames, fn [ffmpeg] (filename string) {
		base_name := os.file_name(filename).rsplit_nth('.', 2)[1]
		cmd := '${ffmpeg} -i ${filename} ${base_name}.jpg'
		os.execute_opt(cmd) or {
			log.error('failed to convert ${filename}, cmd=${cmd}')
			return
		}
	})
}

fn organize_by_date(glob_patterns []string) ! {
	for filename in os.glob(...glob_patterns)! {
		file_stat := os.lstat(filename) or {
			log.error('failed to get file info for ${filename}')
			continue
		}
		epoch := time.unix(file_stat.mtime)
		dirname := os.join_path('${epoch.year}', '${epoch.month:02}')
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
				name:        'convert'
				abbrev:      'c'
				flag:        .bool
				description: 'convert heic to jpg before organizing'
			},
		]
		execute: fn (cmd Command) ! {
			if cmd.flags.get_bool('verbose') or { false } {
				(*log).level = .debug
			}
			file_glob := if cmd.args.len == 0 {
				['*.jpg', '*.heic']
			} else {
				cmd.args
			}
			if cmd.flags.get_bool('convert') or { false } {
				convert_heic_to_jpg(file_glob)!
			}
			organize_by_date(file_glob)!
		}
	}

	app.setup()
	app.parse(arguments())
}
