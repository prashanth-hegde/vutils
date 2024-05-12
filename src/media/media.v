import cli { Command, Flag }
import os
import time
import io.util
import common { Log, run_parallel }

const logger = &Log{
	level: .info
}
const vid_file_types = ['avi', 'mp4', 'mkv', 'webm', 'mov']

fn set_logger(cmd Command) Log {
	if cmd.flags.get_bool('verbose') or { false } {
		(*logger).level = .debug
	}
	return *logger
}

fn file_ext(filename string) ?string {
	return filename[(filename.last_index('.')? + 1)..]
}

fn replace_file_extension(filename string, new_ext string) string {
	ext := file_ext(filename) or { return filename }
	return filename.replace('.${ext}', '.${new_ext}')
}

fn replace_file_name(filename string, new_name string, append_to_basename bool) string {
	basename := filename[..(filename.last_index('.') or { filename.len })]
	new_filename := if append_to_basename {
		basename + new_name
	} else {
		new_name
	}
	return filename.replace(basename, new_filename)
}

fn check_ffmpeg() !string {
	ff_path := os.execute('type -p ffmpeg 2>/dev/null').output
	return if ff_path.len > 0 {
		ff_path.trim_space()
	} else {
		error('ffmpeg not found, exiting')
	}
}

fn downloads(cmd Command) ! {
	check_ffmpeg()!
	mut log := set_logger(cmd)
	infile := cmd.flags.get_string('input')!
	lines := os.read_lines(infile)!
	loglevel := if log.level == .debug { 'warning' } else { 'quiet' }
	mut workers := cmd.flags.get_int('workers') or { 1 }
	if workers < 1 {
		workers = 1
	}

	execute_download := fn [mut log, loglevel] (line string) {
		if line.is_blank() {
			return
		}
		tokens := line.split('|').map(it.trim_space())
		outfile := tokens[0]
		if os.exists(os.abs_path(outfile)) {
			log.warn('${outfile} already exists, skipping...')
			return
		}
		url := tokens[1]
		cmd_download := 'ffmpeg -loglevel ${loglevel} -protocol_whitelist file,http,https,tcp,tls -allowed_extensions ALL -i ${url} -bsf:a aac_adtstoasc -c copy ${outfile}'
		log.debug(cmd_download)
		// fix: does not work if the output file name has whitespace in it
		log.debug('command = ${cmd_download}')
		log.info('${outfile} beginning to download')
		start := time.now()
		os.execute(cmd_download)
		log.info('${outfile} download completed in ${time.since(start)}')
	}

	run_parallel(lines, workers, execute_download)
}

// download downloads videos from weird streams that are not straightforward
// hls. Examples include where the chunks are encoded as jpg, the m3u8 files
// are encoded in .txt file etc. Use this
fn download(cmd Command) ! {
	check_ffmpeg()!
	mut log := set_logger(cmd)
	outfile := cmd.flags.get_string('output') or { 'out.mp4' }
	url := cmd.args[0]
	start := time.now()
	loglevel := if log.level == .debug { 'warning' } else { 'quiet' }
	cmd_download := 'ffmpeg -loglevel ${loglevel} -protocol_whitelist file,http,https,tcp,tls -allowed_extensions ALL -i ${url} -bsf:a aac_adtstoasc -c copy ${outfile}'
	log.debug(cmd_download)
	// fix: does not work if the output file name has whitespace in it
	os.execute(cmd_download)
	log.info('download completed in ${time.since(start)}')
}

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
			os.rm(tmp_path) or { log.error('unable to delete tmp file ${tmp_path}') }
		}
		for line in cmd.args {
			tmp_file.writeln("file '${line}'")!
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

// mp42mp3 extracts audio from video file
// usage - media mp42mp3 <filename>
// example - media mp42mp3 *.mp4 filename.mp4
// output filename will be the same as input filename, with mp3 extension
fn mp42mp3(cmd Command) ! {
	ffmpeg := check_ffmpeg()!
	mut log := set_logger(cmd)
	all_files_list := os.glob(...cmd.args)!
	if all_files_list.len == 0 {
		log.error('no files to convert, aborting')
		return
	}
	videos := all_files_list.filter((file_ext(it) or { '' }) in ['mp4', 'webm', 'avi', 'mkv'])

	log.info('converting ${videos.len} videos...')
	for video in videos {
		start := time.now()
		out_filename := replace_file_extension(video, 'mp3')
		log.info('converting ${video} ..., output=${out_filename}')
		ff_cmd := '${ffmpeg} -hide_banner -nostats -v warning -i "${video}" -vn -ab 128k -ar 44100 -y "${out_filename}"'
		os.execute(ff_cmd)
		log.info('finished in ${time.since(start)}')
	}
}

// strip-audio removes audio track from the specified video file
fn strip_audio(cmd Command) ! {
	ffmpeg := check_ffmpeg()!
	mut log := set_logger(cmd)
	vid_file := cmd.args[0]
	vid_ext := file_ext(vid_file) or { return error('unknown file extension') }
	log.debug('input video_file = ${vid_file}, ext=${vid_ext}')
	if vid_ext !in ['mp4', 'mkv', 'avi', 'webm'] {
		return error('input file is not a video file')
	}
	start := time.now()
	log.info('beginning to extract audio from ${vid_file}')
	ff_cmd := '${ffmpeg} -hide_banner -nostats -i "${vid_file}" -c copy -an "${vid_file}-noaudio.${vid_ext}"'
	log.debug(ff_cmd)
	os.execute(ff_cmd)
	log.info('stripped audio in ${time.since(start)}')
}

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

// ============= Command Parser ==================

fn cmd_parser() {
	mut main_cmd := Command{
		name: 'media'
		description: 'useful media editing commands for a simple human being'
		flags: [
			Flag{
				name: 'verbose'
				abbrev: 'v'
				description: 'print more info about commands and output'
				global: true
				flag: .bool
			},
		]
		commands: [
			Command{
				name: 'mp42mp3'
				required_args: 1
				description: 'extract audio from video files, mp3 from mp4 files'
				execute: mp42mp3
			},
			Command{
				name: 'split'
				required_args: 2
				description: 'split a given video into multiple chunks, as specified by a splits file'
				usage: '<splits_file> <video_file>
        example of a splits file looks like this:
        out_file_01.mp4 | 0:00:00 | 0:10:00 --> extracts 0 to 10 minutes of the video and puts into out_file_01.mp4
        out_file_02.mp4 | 0:10:00 | 0:15:00 --> extracts 10 to 15 minutes of the video and puts into out_file_02.mp4
        '
				execute: split_video
			},
			Command{
				name: 'join'
				required_args: 2
				description: 'join two or more files into a single file, works on both video and audio files'
				usage: '-o <out_file> <file1> <file2> ...'
				execute: join
				flags: [
					Flag{
						name: 'output'
						abbrev: 'o'
						description: 'output filename to store the joined files'
						flag: .string
						required: true
					},
				]
			},
			Command{
				name: 'download'
				required_args: 1
				description: 'download weird streams not downloadable by youtube-dl'
				usage: '-o <out_file> -f <in_file> -t <num_threads> <stream_url>
        example of in_file looks like this:
        out_file_01.mp4 | stream_url1
        out_file_02.mp4 | stream_url2
        '
				execute: download
				flags: [
					Flag{
						name: 'output'
						abbrev: 'o'
						description: 'output filename to store the joined files'
						flag: .string
						required: true
					},
				]
			},
			Command{
				name: 'downloads'
				required_args: 0
				description: 'downloads multiple streams in one shot given an input file'
				usage: '-i <in_file> -w 2
        example of in_file looks like this:
        Note: no whitespace in out_file
        Note: blank lines are allowed
        Note: comments are not supported
        out_file_01.mp4 | stream_url1
        out_file_02.mp4 | stream_url2
        '
				execute: downloads
				flags: [
					Flag{
						name: 'input'
						abbrev: 'i'
						description: 'input filename to read stream and output file from'
						flag: .string
						required: true
					},
					Flag{
						name: 'workers'
						abbrev: 'w'
						description: 'number of parallel workers'
						flag: .int
						required: false
					},
				]
			},
			Command{
				name: 'split-on-silence'
				required_args: 1
				description: 'split an audio file based upon silence'
				usage: 'audio_file'
				execute: split_on_silence
			},
			Command{
				name: 'strip-audio'
				required_args: 1
				description: 'strips audio track from the given video file'
				usage: 'video_file'
				execute: strip_audio
			},
			Command{
				name: 'resize'
				required_args: 1
				description: 'resizes a video file to lower its resolution'
				usage: '-r [sd|hd|fhd]'
				execute: resize
				flags: [
					Flag{
						name: 'resolution'
						abbrev: 'r'
						description: 'resoution type, options = sd(480p), hd(720p), fhd(1080p)'
						flag: .string
						required: true
					},
				]
			},
			Command{
				name: 'merge'
				required_args: 1
				description: 'video and audio together. Both video and audio are expected to be same length'
				usage: ''
				execute: merge
				flags: [
					Flag{
						name: 'video'
						abbrev: 'v'
						description: 'video input filename'
						flag: .string
						required: true
					},
					Flag{
						name: 'audio'
						abbrev: 'a'
						description: 'audio input filename'
						flag: .string
						required: true
					},
					Flag{
						name: 'output'
						abbrev: 'o'
						description: 'output filename'
						flag: .string
						required: true
					},
				]
			},
		]
	}

	main_cmd.setup()
	main_cmd.parse(os.args)
}

fn main() {
	cmd_parser()
}
