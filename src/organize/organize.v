module main

import os
import time
import cli { Command, Flag }
import common { Log }
import arrays { concat, flatten }

const log = &Log{}
const image_exts = ['jpg', 'jpeg', 'heic', 'webp']
const video_exts = ['mov', 'mp4', 'webm']
const media_exts = concat(image_exts, ...video_exts)

fn convert_heic_to_jpg(glob_patterns []string, recurse bool) ! {
	// Ensure ffmpeg is available
	ffmpeg := os.find_abs_path_of_executable('ffmpeg') or {
		return error('ffmpeg not installed, aborting...')
	}

	// Get all HEIC files from provided patterns
	filenames := list_files_for_glob(glob_patterns, recurse)!.filter(it.to_lower().ends_with('.heic'))
	if filenames.len == 0 {
		log.debug('No HEIC files found to convert')
		return
	}

	// Create backup directory if it doesn't exist
	dirname := os.join_path(os.getwd(), 'heic-bak')
	if !os.exists(dirname) {
		os.mkdir(dirname)!
	}

	// Convert each file and move original to backup
	for filename in filenames {
		base_name, _ := os.file_name(filename).rsplit_once('.') or { continue }
		output_file := '${base_name}.jpg'

		cmd := '${ffmpeg} -i "${filename}" "${output_file}"'
		log.debug('Converting ${filename}: ${cmd}')

		result := os.execute_opt(cmd) or {
			log.error('Failed to convert ${filename}, cmd=${cmd}')
			continue
		}

		if result.exit_code != 0 {
			log.error('Conversion failed with exit code ${result.exit_code}: ${result.output}')
			continue
		}

		os.mv(filename, os.join_path(dirname, os.file_name(filename))) or {
			log.error('Failed to move ${filename} to ${dirname}: ${err}')
		}
	}
}

// Organize files into directories based on their modification date
fn organize_by_date(glob_patterns []string, recurse bool, simulate bool) ! {
	// Get all media files matching the provided patterns
	all_files := list_files_for_glob(glob_patterns, recurse)!
	log.debug('Found ${all_files.len} files to organize')

	if all_files.len == 0 {
		return
	}

	// Track stats for feedback
	mut success_count := 0
	mut error_count := 0

	// Process each file
	for filename in all_files {
		file_stat := os.lstat(filename) or {
			log.error('Failed to get file info for ${filename}: ${err}')
			error_count++
			continue
		}

		// Create directory name based on file modification time
		epoch := time.unix(file_stat.mtime)
		dirname := os.join_path('${epoch.year}', '${epoch.year}${epoch.month:02}${epoch.day:02}')

		if !simulate && !os.exists(dirname) {
			os.mkdir_all(dirname) or {
				log.error('Failed to create directory ${dirname}: ${err}')
				error_count++
				continue
			}
		}

		destination := os.join_path(dirname, os.file_name(filename))
		log.debug('Moving ${filename} to ${destination}')

		if !simulate {
			os.mv(filename, destination) or {
				log.error('Failed to move ${filename} to ${dirname}: ${err}')
				error_count++
				continue
			}
			success_count++
		} else {
			success_count++
		}
	}

	log.info('Organized ${success_count} files successfully' +
		if error_count > 0 { ', ${error_count} errors occurred' } else { '' } +
		if simulate { ' (simulation mode)' } else { '' })
}

fn list_files(root_path string, recurse bool) []string {
	return if recurse {
		all_files_list := media_exts.map(os.walk_ext(root_path, it))
		flatten(all_files_list)
	} else {
		all_files_list := os.ls(root_path) or {
			log.warn('did not find any relevant files in ${root_path}')
			[]
		}
		mut relevant_files := []string{len: all_files_list.len}
		dot_exts := media_exts.map('.${it}')
		for file in all_files_list {
			full_path := os.join_path(root_path, file)
			if os.is_file(full_path) && dot_exts.any(os.file_ext(file).to_lower() == it) {
				relevant_files << full_path
			}
		}
		relevant_files
	}
}

fn list_files_for_glob(glob_patterns []string, recurse bool) ![]string {
	mut all_filenames := []string{cap: 5000}
	log.debug('glob_patterns = ${glob_patterns}')
	for path in os.glob(...glob_patterns)! {
		log.debug('path = ${path}')
		if os.is_dir(path) {
			all_filenames << list_files(path, recurse)
		} else {
			file_ext := os.file_ext(path).to_lower()
			dot_exts := media_exts.map('.${it}')
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
			Flag{
				name:          'output'
				abbrev:        'o'
				flag:          .string
				description:   'target directory to merge or put the organized files'
				default_value: [os.getwd()]
			},
			Flag{
				name:        'simulate'
				abbrev:      's'
				flag:        .bool
				description: 'only simulates the organization, does not change the filesystem'
			},
		]
		execute:     fn (cmd Command) ! {
			simulate := cmd.flags.get_bool('simulate') or { false }
			verbose := cmd.flags.get_bool('verbose') or { false }
			if verbose || simulate {
				(*log).level = .debug
			}
			file_glob := if cmd.args.len == 0 {
				media_exts
			} else {
				cmd.args
			}
			recurse := cmd.flags.get_bool('recurse') or { false }
			if cmd.flags.get_bool('convert') or { false } {
				convert_heic_to_jpg(file_glob, recurse)!
			}
			organize_by_date(file_glob, recurse, simulate)!
		}
	}

	app.setup()
	app.parse(arguments())
}
