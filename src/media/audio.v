import cli { Command }
import os
import log

// extract_audio extracts audio from video file
// usage - media extract_audio <filename>
// example - media extract_audio *.mp4 filename.mp4
// output filename will be the same as input filename, with mp3 extension
fn extract_audio(cmd Command) ! {
	if cmd.flags.get_bool('verbose') or { false } {
		log.set_level(.debug)
	}

	all_files_list := os.glob(...cmd.args)!
	if all_files_list.len == 0 {
		return error('no files to convert, aborting')
	}

	videos := all_files_list
		.filter((file_ext(it) or { '' }) in vid_file_types)

	log.info('converting ${videos.len} videos...')
	for input in videos {
		output := replace_file_extension(input, 'mp3')
		run_ffmpeg_command2(.extract_audio, {
			'input':  input
			'output': output
		})!
	}
}

// strip_audio removes audio track from the specified video file
fn strip_audio(cmd Command) ! {
	if cmd.flags.get_bool('verbose') or { false } {
		log.set_level(.debug)
	}

	all_files_list := os.glob(...cmd.args)!
		.filter((file_ext(it) or { '' }) in vid_file_types)
	if all_files_list.len == 0 {
		return error('no video files to convert, aborting')
	}

	for input in all_files_list {
		output := append_to_filename(input, 'noaudio')
		run_ffmpeg_command2(.strip_audio, {
			'input':  input
			'output': output
		})!
	}
}
