import os
import time
import log

pub fn run_ffmpeg_command(func FFMpegFunction, input string, output string) ! {
	start := time.now()
	log.info('operation: ${func} started')
	run_cmd := ffmpeg_cmds[func] or { return error('invalid command: ${func}') }
	raw_cmd := run_cmd
		.replace('input', input)
		.replace('output', output)
	execute(raw_cmd)!
	time_taken := time.since(start)
	log.info('operation: ${func} completed in ${time_taken}')
}

enum FFMpegFunction {
	convert
	resize
	extract_audio
	strip_audio
	join
}

const ffmpeg_cmds = {
	FFMpegFunction.convert: 'ffmpeg -y -loglevel warning -hide_banner -i "input" -c:v libx264 -crf 23 -preset medium -tune stillimage "output"'
	.resize:                'ffmpeg -y -loglevel warning -hide_banner -i "input" -vf "scale=trunc((iw/ih)*resolution/2)*2:resolution" -c:v libx264 -preset slow -crf 23 -c:a aac -b:a 128k "output"'
	.extract_audio:         'ffmpeg -y -hide_banner -nostats -v warning -i "input" -vn -ab 128k -ar 44100 -y "output"'
	.strip_audio:           'ffmpeg -y -hide_banner -nostats -i "input" -c copy -an "output"'
	.join:                  'ffmpeg -y -hide_banner -nostats -f concat -safe 0 -i "input" -c copy "output"'
}

// ====== Helpers ======

fn extract_pgm_args(input string) []string {
	mut result := []string{}
	mut current := ''
	mut in_quotes := false

	for ch in input {
		if ch == `"` {
			in_quotes = !in_quotes
			// current += ch.ascii_str()
		} else if ch == ` ` && !in_quotes {
			if current.len > 0 {
				result << current
				current = ''
			}
		} else {
			current += ch.ascii_str()
		}
	}
	if current.len > 0 {
		result << current
	}

	return result
}

fn execute(cmd string) ! {
	if cmd.len <= 0 {
		return error('please check your cli command: ${cmd}')
	}

	pgm_name := cmd.split_by_space()[0]
	pgm := os.find_abs_path_of_executable('${pgm_name}')!
	pgm_args := extract_pgm_args(cmd.replace(pgm_name, '').trim_space())
	log.debug('cmd: ${cmd}')

	mut proc := os.new_process(pgm)
	proc.set_redirect_stdio()
	proc.set_work_folder(os.getwd())
	proc.set_args(pgm_args)
	proc.run()

	for proc.is_alive() {
		out := proc.pipe_read(.stdout) or { '' }
		err := proc.pipe_read(.stderr) or { '' }
		if out.len > 0 {
			log.debug(out)
		}
		if err.len > 0 {
			log.debug(err)
		}
		time.sleep(100 * time.millisecond)
	}

	proc.wait()
}
