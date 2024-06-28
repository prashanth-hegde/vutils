import os
import time
import cli { Command }
import common { run_parallel }

/// downloads videos from a list of urls in a file
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
