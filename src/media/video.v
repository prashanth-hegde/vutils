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
		// working command
		// ffmpeg -i input.mp4 -vf "scale=trunc((iw/ih)*480/2)*2:480" -c:v libx264 -preset slow -crf 23 -c:a aac -b:a 128k input-resized.mp4
		ff_cmd := '${ffmpeg} -i "${file}" -vf "scale=trunc((iw/ih)*$vid_resolution/2)*2:$vid_resolution" -c:v libx264 -preset slow -crf 23 -c:a aac -b:a 128k "${out_file}"'
		log.debug(ff_cmd)
		start := time.now()
		os.execute_opt(ff_cmd) or {
			log.error('Failed to resize "${file}"')
			log.error('===\n$err\n===')
			continue
		}
		log.info('"${file}" resized in ${time.since(start)}')
	}
}

fn convert(cmd Command) ! {
	ffmpeg := check_ffmpeg()!
	mut log := set_logger(cmd)

	input_files := os.glob(...cmd.args)!
	mut output_extension := cmd.flags.get_string('extension') or { 'mp4' }
	if output_extension == '' {
		output_extension = 'mp4'
	}
	for file in input_files {
		if (file_ext(file) or { '' }) !in vid_file_types {
			continue
		}
		log.info('"${file}" converting...')
		out_file := '${file[..(file.last_index('.') or { file.len })]}-converted.$output_extension'
		// working command
		// ffmpeg -i input.wmv -c:v libx264 -crf 23 -preset medium -tune stillimage output.mp4
		ff_cmd := '${ffmpeg} -i "${file}" -c:v libx264 -crf 23 -preset medium -tune stillimage "${out_file}"'
		log.debug(ff_cmd)
		start := time.now()
		os.execute_opt(ff_cmd) or {
			log.error('Failed to convert "${file}"')
			log.error('===\n$err\n===')
			continue
		}
		log.info('"${file}" converted in ${time.since(start)}')
	}
}

// TODO
// vertical flip
//
