import time
import os
import cli { Command }
import io.util

fn join(cmd Command) ! {
	check_ffmpeg()!
	mut log := set_logger(cmd)
	// For example, ffmpeg -i "concat:video1.mp4|video2.mp4|video3.mp4" -c copy output.mp4
	if cmd.args.all(it.ends_with('.mp4')) || cmd.args.all(it.ends_with('.mp3')) {
		log.info('concatenating files')
		start := time.now()

		mut tmp_file, tmp_path := util.temp_file()!
		log.debug('tmp created in ${tmp_path}')
		defer {
			// delete temp file after exiting
			// os.rm(tmp_path) or { log.error('unable to delete tmp file ${tmp_path}') }
		}
		for line in cmd.args {
			abs_path := os.abs_path(line)
			tmp_file.writeln("file '${abs_path}'")!
		}
		tmp_file.close()
		outfile := cmd.flags.get_string('output') or { 'output.mp4' }
		if os.exists(outfile) {
			os.rm(outfile)!
		}
		cat_cmd := 'ffmpeg -f concat -safe 0 -i ${tmp_path} -c copy ${outfile}'
		log.debug(cat_cmd)
		cmd_out := os.execute(cat_cmd).output
		log.debug(cmd_out)
		log.info('finished in ${time.since(start)}')
	} else {
		return error('not all files are of the same type, use merge to merge formats')
	}
}

// merge combines audio and video formats of given files
fn merge(cmd Command) ! {
	check_ffmpeg()!
	mut log := set_logger(cmd)
	audio_file := cmd.flags.get_string('audio')!
	video_file := cmd.flags.get_string('video')!
	out_file := cmd.flags.get_string('output')!

	start := time.now()
	merge_cmd := 'ffmpeg -i "${video_file}" -i "${audio_file}" -c:v copy -c:a aac -shortest "${out_file}"'
	log.debug(merge_cmd)
	cmd_out := os.execute(merge_cmd).output
	log.debug(cmd_out)
	log.info('finished in ${time.since(start)}')
}

fn split_on_silence(cmd Command) ! {
	check_ffmpeg()!
	mut log := set_logger(cmd)
	infile := cmd.args[0]
	if !infile.ends_with('.mp3') || !os.exists(infile) {
		return error('not an audio file, aborting')
	}
	start := time.now()
	mut tmp_file, tmp_path := util.temp_file()!
	defer {
		os.rm(tmp_path) or { log.error('unable to remove tmp file ${tmp_path}') }
	}
	/* detect silences in first pass, and put the contents into a temp file
  [silencedetect @ 0x55ff80b857c0] silence_start: 269.44
  [silencedetect @ 0x55ff80b857c0] silence_end: 273.654 | silence_duration: 4.21342AA
  */
	silence_detect_cmd := 'ffmpeg -hide_banner -nostats -i "${infile}" -af silencedetect=noise=-30dB:d=1.0 -f null -'
	silence_detect_out := os.execute(silence_detect_cmd).output
	// log.debug(silence_detect_out)
	tmp_file.write(silence_detect_out.bytes())!

	// parse the temp file to fetch sequence start and end times
	seq_detect_cmd := r"rg --no-filename -o 'silence_end: (\d+.\d+)' -r '$1' $tmp_path | xargs | sed 's/ /,/g'"
	log.debug('${seq_detect_cmd}')
	seq_detect_out := os.execute(seq_detect_cmd).output.trim_space()
	log.debug('${seq_detect_out}')
	if seq_detect_out == '' {
		return error('no silence detected in the track, aborting')
	}

	cmd_split := 'ffmpeg -v warning -i ${infile} -f segment -segment_times "${seq_detect_out}" -reset_timestamps 1 -map 0:a -c:a copy "output-%02d.mp3"'
	log.debug(cmd_split)
	split_out := os.execute(cmd_split).output
	log.debug(split_out)
	log.info('completed in ${time.since(start)}')
}

// split_video splits a given video with the given splits file
// The splits file format is expected to be like this
//
// output_file_name1.mp4 | chunk_start | chunk_end
// output_file_name2.mp4 | chunk_start | chunk_end
fn split_video(cmd Command) ! {
	ffmpeg := check_ffmpeg()!
	mut log := set_logger(cmd)
	splits := cmd.args[0]
	infile := cmd.args[1]
	if !os.exists(splits) {
		return error('file ${splits} does not exist')
	} else if !os.exists(infile) {
		return error('file ${infile} does not exist')
	}

	for i, line in os.read_lines(splits)! {
		tokens := line.trim_space().split('|')
		if tokens.len < 3 {
			log.warn('line ${i + 1} is not correctly formatted, skipping')
			continue
		}
		outfile, start, end := tokens[0].trim_space(), tokens[1].trim_space(), tokens[2].trim_space()
		start_time := time.now()
		cmd_ := '${ffmpeg} -i "${infile}" -ss "${start}" -to "${end}" -c copy "${outfile}"'
		log.debug(cmd_)
		os.execute(cmd_).output
		log.info('finished splitting to ${outfile} in ${time.since(start_time)}')
	}
}
