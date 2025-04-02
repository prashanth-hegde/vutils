import time
import os
import cli { Command }
import io.util
import log
import common

fn join(cmd Command) ! {
	if cmd.flags.get_bool('verbose') or { false } {
		log.set_level(.debug)
	}

	// For example, ffmpeg -i "concat:video1.mp4|video2.mp4|video3.mp4" -c copy output.mp4
	if cmd.args.all(it.ends_with('.mp4')) || cmd.args.all(it.ends_with('.mp3')) {
		mut tmp_file, tmp_path := util.temp_file()!
		log.info('tmp created in ${tmp_path}')
		defer {
			// delete temp file after exiting
			tmp_file.close()
			os.rm(tmp_path) or { log.error('unable to delete tmp file ${tmp_path}') }
		}

		file_lines := cmd.args.map('file ${it}') // no quotes around $it
		os.write_lines(tmp_path, file_lines)!
		outfile := cmd.flags.get_string('output') or { 'output.mp4' }
		run_ffmpeg_command2(.join, {
			'input':  tmp_path
			'output': outfile
		})!
	} else {
		return error('not all files are of the expected mp3,mp4 types, use merge to combine audio/video or concat to concat files')
	}
}

// merge combines audio and video formats of given files
fn merge(cmd Command) ! {
	audio_file := cmd.flags.get_string('audio')!
	video_file := cmd.flags.get_string('video')!
	out_file := cmd.flags.get_string('output')!

	run_ffmpeg_command2(.merge, {
		'audio':  audio_file
		'video':  video_file
		'output': out_file
	})!
}

struct SilenceDuration {
	start    string
	end      string
	duration string
}

/// split_on_silence splits an audio file on silence.
/// Silence is hard-coded to -30dB and duration of 1.0 seconds
fn split_on_silence(cmd Command) ! {
	ffmpeg := os.find_abs_path_of_executable('ffmpeg')!
	if cmd.flags.get_bool('verbose') or { false } {
		log.set_level(.debug)
	}
	mut input_files := os.glob(...cmd.args)!
		.filter(os.file_ext(it) == '.mp3')

	for input_file in input_files {
		/* detect silences in first pass, and put the contents into a temp file
  [silencedetect @ 0x55ff80b857c0] silence_start: 269.44
  [silencedetect @ 0x55ff80b857c0] silence_end: 273.654 | silence_duration: 4.21342AA
  */
		log.debug('detecting silence')
		silence_detect_cmd := '${ffmpeg} -hide_banner -nostats -i "${input_file}" -af silencedetect=noise=-30dB:d=1.0 -f null -'
		silence_detect_out := os.execute_opt(silence_detect_cmd)!.output
		mut silences := []SilenceDuration{}
		mut start := '-1'
		for line in silence_detect_out.split_into_lines() {
			if line.contains('silencedetect') {
				if line.contains('silence_start') {
					start = line.split('silence_start:')[1].trim_space()
				} else if line.contains('silence_end') && start != '-1' {
					pattern := r'silence_end: (\d+\.\d+) \| silence_duration: (\d+\.\d+)'
					groups := common.find_groups(pattern, line)

					if groups.len != 2 {
						log.error('unable to parse silence_end and silence_duration from line ${line}')
						continue
					}
					end, duration := groups[0], groups[1]
					silences << SilenceDuration{
						start:    start
						end:      end
						duration: duration
					}
					start = '-1'
				} else {
					log.error('unable to parse silence_start from line ${line}')
				}
			}
		}

		log.info('silences detected: ${silences.len}')
		log.debug('silences detected: ${silences}')

		// just concatenate silence_end times into a comma separated string,
		// and split on it
		split_times := silences.map(it.end).join(',')
		log.info('split_times: ${split_times}')

		run_ffmpeg_command2(.split_on_silence, {
			'input':    input_file
			'segments': split_times
			'output':   file_name_without_ext(input_file)
		})!
	}
}

// split_video splits a given video with the given splits file
// The splits file format is expected to be like this
//
// output_file_name1.mp4 | chunk_start | chunk_end
// output_file_name2.mp4 | chunk_start | chunk_end
fn split_video(cmd Command) ! {
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

		run_ffmpeg_command2(.split_video, {
			'input':  infile
			'output': outfile
			'start':  start
			'end':    end
		})!
	}
}
