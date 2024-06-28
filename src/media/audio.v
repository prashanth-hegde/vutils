import cli { Command }
import time
import os

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
