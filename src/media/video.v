import cli { Command }
import os
import time

fn resize(cmd Command) ! {
	ffmpeg := check_ffmpeg()!
	mut log := set_logger(cmd)
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
		log.info('"${file}" resizing...')
		out_file := replace_file_name(file, '-resized', true)
		ff_cmd := '${ffmpeg} -i "${file}" -vf scale="-1:${vid_resolution}" "${out_file}"'
		log.debug(ff_cmd)
		start := time.now()
		os.execute(ff_cmd)
		log.info('"${file}" resized in ${time.since(start)}')
	}
}

// TODO
// vertical flip
//
