module main
import os
import net.http

struct TestData{
	name string
	ext string
	url string
	expected string
}

fn (t TestData) file_name() string {
	return os.join_path(os.temp_dir(), '${t.name}.${t.ext}')
}

const test_data := [
TestData{
	name: '01_ocean_w_audio',
	ext: 'mkv',
	url: 'https://filesamples.com/samples/video/mkv/sample_960x400_ocean_with_audio.mkv',
	expected: '.mkv'
}
]

fn setup_test_data() ! {
	for data in test_data {
		if !os.exists(data.file_name()) {
			http.download_file(data.url, data.file_name())!
		}
	}
}

fn cleanup_test_data() ! {
	for file in test_data.map(it.file_name()) {
		if os.exists(file) {
			os.rm(file)!
		}
	}
}

fn test_generic_ffmpeg_command() ! {
	setup_test_data()!

	for data in test_data {
		input_filename := data.file_name()
		output_filename := append_to_filename(input_filename, 'converted')

		run_ffmpeg_command(.convert, input_filename, output_filename)!
		assert os.exists(output_filename)
	}

	cleanup_test_data()!
}

fn ignore_test_split_preserve_quotes() {
	inputs := [
		'ffmpeg -y -i "input filename" -c:v libx264 -crf 23 -preset medium -tune stillimage "output 123"'
	]
	exp_splits := [
		12
	]

	for idx, input in inputs {
		res := extract_pgm_args(input)
		println(res)
		assert res.len == exp_splits[idx]
	}
}
