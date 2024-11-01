import cli { Command, Flag }
import os
import common { Log }

const logger = &Log{
	level: .info
}
const vid_file_types = ['avi', 'mp4', 'mkv', 'webm', 'mov', 'wmv']

fn set_logger(cmd Command) Log {
	if cmd.flags.get_bool('verbose') or { false } {
		(*logger).level = .debug
	}
	return *logger
}

fn check_ffmpeg() !string {
	return os.find_abs_path_of_executable('ffmpeg')
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
			Command{
				name: 'convert'
				required_args: 1
				description: 'video converter - convert to mp4'
				usage: '-e mp4 *.avi'
				execute: convert
				flags: [
					Flag{
						name: 'extension'
						abbrev: 'e'
						description: 'extension to convert to'
						flag: .string
						required: false
					},
				]
			},
		]
	}

	main_cmd.setup()
	main_cmd.parse(arguments())
}

fn main() {
	cmd_parser()
}
