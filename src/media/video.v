import cli { Command }
import os
import log

fn resize(cmd Command) ! {
	if cmd.flags.get_bool('verbose') or { false } {
		log.set_level(.debug)
	}
	vid_options := cmd.flags.get_string('resolution') or { 'sd' }
	vid_resolution := match vid_options {
		'fhd' { '1080' }
		'hd' { '720' }
		else { '480' }
	}

	input_files := os.glob(...cmd.args)!
	for file in input_files {
		if (file_ext(file) or { '' }) !in vid_file_types {
			continue
		}

		output := append_to_filename(file, 'resized')
		run_ffmpeg_command(.resize, {
			'input':      file
			'output':     output
			'resolution': vid_resolution
		})!
	}
}

fn convert(cmd Command) ! {
	if cmd.flags.get_bool('verbose') or { false } {
		log.set_level(.debug)
	}
	input_files := os.glob(...cmd.args)!
	mut output_extension := cmd.flags.get_string('extension') or { 'mp4' }
	if output_extension == '' {
		output_extension = 'mp4'
	}

	for file in input_files {
		if (file_ext(file) or { '' }) !in vid_file_types {
			continue
		}
		mut output := append_to_filename(file, 'converted')
		output = replace_file_extension(output, output_extension)
		run_ffmpeg_command(.convert, {
			'input':  file
			'output': output
		})!
	}
}

// TODO
// vertical flip
//
