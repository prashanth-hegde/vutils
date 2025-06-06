import os
import time
import log

pub fn run_ffmpeg_command(func FFMpegFunction, replacers map[string]string) ! {
	start := time.now()
	log.info('operation: ${func} started')
	mut raw_cmd := ffmpeg_cmds[func] or { return error('invalid function provided: ${func}') }
	for k, v in replacers {
		raw_cmd = raw_cmd.replace(k, v)
	}
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
	merge
	split_on_silence
	split_video
	download
}

const ffmpeg_cmds = {
	FFMpegFunction.convert: 'ffmpeg -y -loglevel warning -hide_banner -i "input" -c:v libx264 -crf 23 -preset medium -tune stillimage "output"'
	.resize:                'ffmpeg -y -loglevel warning -hide_banner -i "input" -vf "scale=trunc((iw/ih)*resolution/2)*2:resolution" -c:v libx264 -preset slow -crf 23 -c:a aac -b:a 128k "output"'
	.extract_audio:         'ffmpeg -y -hide_banner -nostats -v warning -i "input" -vn -ab 128k -ar 44100 -y "output"'
	.strip_audio:           'ffmpeg -y -hide_banner -nostats -i "input" -c copy -an "output"'
	.join:                  'ffmpeg -y -hide_banner -nostats -f concat -safe 0 -i "input" -c copy "output"'
	.merge:                 'ffmpeg -y -hide_banner -nostats -i "video" -i "audio" -c:v copy -c:a aac -shortest "output"'
	.split_on_silence:      'ffmpeg -v warning -i "input" -f segment -segment_times "segments" -reset_timestamps 1 -map 0:a -c:a copy "output-%02d.mp3"'
	.split_video:           'ffmpeg -i "input" -ss "start" -to "end" -c copy "output"'
	.download:              'ffmpeg -loglevel loglevel -hide_banner -protocol_whitelist file,http,https,tcp,tls -allowed_extensions ALL -i "input" -bsf:a aac_adtstoasc -c copy "output"'
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
