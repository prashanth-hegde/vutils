import os
import time
import cli { Command }
import arrays.parallel
import log

/// downloads videos from a list of urls in a file
fn downloads(cmd Command) ! {
	if cmd.flags.get_bool('verbose') or { false } {
		log.set_level(.debug)
	}

	infile := cmd.flags.get_string('input')!
	lines := os.read_lines(infile)!
	loglevel := if cmd.flags.get_bool('verbose') or { false } { 'warning' } else { 'quiet' }
	mut workers := cmd.flags.get_int('workers') or { 1 }
	if workers < 1 {
		workers = 1
	}

	execute_download := fn [loglevel] (line string) {
		if line.is_blank() {
			return
		}
		tokens := line.split('|').map(it.trim_space())
		outfile := tokens[0]
		url := tokens[1]
		if os.exists(os.abs_path(outfile)) {
			log.warn('${outfile} already exists, skipping...')
			return
		}

		run_ffmpeg_command(.download, {
			'loglevel': loglevel
			'input':    url
			'output':   outfile
		}) or { log.error('failed to download ${outfile}: url=${url}') }
	}

	parallel.run(lines, execute_download, workers: workers)
}

// download downloads videos from weird streams that are not straightforward
// hls. Examples include where the chunks are encoded as jpg, the m3u8 files
// are encoded in .txt file etc. Use this
fn download(cmd Command) ! {
	check_ffmpeg()!
	outfile := cmd.flags.get_string('output') or { 'out.mp4' }
	url := cmd.args[0]
	loglevel := if cmd.flags.get_bool('verbose') or { false } { 'warning' } else { 'quiet' }
	run_ffmpeg_command(.download, {
		'loglevel': loglevel
		'input':    url
		'output':   outfile
	})!
}
