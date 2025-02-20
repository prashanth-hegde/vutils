module docgen

import os
import log
import common
import arrays
import strings

const ignore_patterns := ['.git', '.vscode', '.idea', '.DS_Store', 'venv', 'node_modules', 'build',
			'dist', 'LICENSE']
pub struct DocgenConfig {
	pub:
	verbose   bool
	extension []string
	output    string
	stat      bool
	dir       string
	recurse   bool
}

pub fn set_log_level(level log.Level) {
	log.use_stdout()
	log.set_level(level)
}

pub fn run_docgen(cfg DocgenConfig) ! {
	if cfg.verbose {
		log.set_level(.debug)
	} else {
		log.set_level(.info)
	}

	// Step 1: get list of files
	mut file_list := []string{}
	mut fl := &file_list
	log.debug('cfg: ${cfg}')

	// Step 2: handle recursion
	if cfg.recurse {
		os.walk(cfg.dir, fn [mut fl] (f string) {
			if os.is_dir(f) || f.contains_any_substr(ignore_patterns) {
				return
			}
			fl << f
		})
	} else {
		file_list << os.ls(cfg.dir)!
	}
	log.debug('file_list: ${file_list}')

	// Step 3: filter files by extension
	ext_files := get_valid_ext_files(file_list, cfg.extension)

	// Step 5: generate output or print stats depending on the config
	output := if cfg.stat {
		print_stats(ext_files)
	} else {
		generate_output(ext_files)
	}

	// Step 6: write output to file or print to stdout
	if cfg.output == '' {
		println(output)
	} else if os.is_writable(cfg.output) {
		os.write_file(cfg.output, output)!
	} else {
		return error('output file is not writable: ${cfg.output}')
	}
}

fn print_stats(ext_files []string) string {
	file_count := ext_files.len

	// count lines
	mut line_count := 0
	mut empty_line_count := 0
	mut non_empty_line_count := 0
	for file in ext_files {
		lines := os.read_lines(file) or {
			log.warn('could not read file: ${file}')
			continue
		}
		non_empty, empty := arrays.partition[string](lines, |l| l.trim_space() != '')
		non_empty_line_count += non_empty.len
		empty_line_count += empty.len
		line_count += lines.len
	}

	// generate statistics
	return $tmpl('./output_template.txt')
}

// if no extension is provided, return all files
// if extension is provided (non-zero), filter by extensions
fn get_valid_ext_files(file_list []string, exts []string) []string {
	if exts.len == 0 {
		log.debug('no extensions provided, returning all files, after ignoring glob patterns')
		log.debug('file_list: ${file_list}')
		return file_list.filter(!it.contains_any_substr(ignore_patterns))
	}

	log.debug('filtering files by extensions: ${exts}')
	ext_files := file_list.filter(fn [exts] (it string) bool {
		_, ext := common.file_extension(it) or { return false }
		return exts.contains(ext)
	})
	log.debug('ext_files: ${ext_files}')
	return ext_files
}

fn generate_output(ext_files []string) string {
	mut output_builder := strings.new_builder(100 * 1024)
	for file in ext_files {
		// print file header
		output_builder.write_string('====== File: ${file} =====\n')

		lines := os.read_lines(file) or {
			log.warn('could not read file: ${file}')
			continue
		}
		for line in lines {
			if line.trim_space().len > 0 {
				output_builder.write_string(line)
				output_builder.write_string('\n')
			}
		}
		output_builder.write_string('====== End of File ${file} =====\n\n')
	}

	return output_builder.str()
}
