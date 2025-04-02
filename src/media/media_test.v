module main

import os
import net.http
import cli { Command }

struct TestData {
	name     string
	ext      string
	url      string
	expected string
}

fn (t TestData) file_name() string {
	return os.join_path(os.temp_dir(), '${t.name}.${t.ext}')
}

fn (t TestData) filename_with_postfix(postfix string) string {
	return os.join_path(os.temp_dir(), '${t.name}-${postfix}.${t.ext}')
}

fn (t TestData) filename_with_postfix_and_ext(postfix string, ext string) string {
	return os.join_path(os.temp_dir(), '${t.name}-${postfix}.${ext}')
}

fn (t TestData) filename_with_ext(ext string) string {
	return os.join_path(os.temp_dir(), '${t.name}.${ext}')
}

const test_data = [
	TestData{
		name:     '01_ocean_w_audio'
		ext:      'mkv'
		url:      'https://filesamples.com/samples/video/mkv/sample_960x400_ocean_with_audio.mkv'
		expected: '.mkv'
	},
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

		run_ffmpeg_command2(.convert, {
			'input':  input_filename
			'output': output_filename
		})!
		assert os.exists(output_filename)
		os.rm(output_filename)!
	}

	// cleanup_test_data()!
}

fn test_split_preserve_quotes() {
	inputs := [
		'ffmpeg -y -i "input filename" -c:v libx264 -crf 23 -preset medium -tune stillimage "output 123"',
	]
	exp_splits := [
		13,
	]

	for idx, input in inputs {
		res := extract_pgm_args(input)
		println(res)
		assert res.len == exp_splits[idx]
	}
}

struct FunctionTestData {
	func           FFMpegFunction
	input          string
	output         string
	expected_files []string
}

fn (f FunctionTestData) invoke() ! {
	cmd := Command{
		args: [f.input]
	}
	match f.func {
		.convert { convert(cmd)! }
		.resize { resize(cmd)! }
		.extract_audio { extract_audio(cmd)! }
		.strip_audio { strip_audio(cmd)! }
		.join { join(cmd)! }
		else { return error('unsupported function') }
	}
}

const function_tests = [
	FunctionTestData{
		func:           .convert
		input:          test_data[0].file_name()
		output:         ''
		expected_files: [
			test_data[0].filename_with_postfix_and_ext('converted', 'mp4'),
		]
	},
	FunctionTestData{
		func:           .resize
		input:          test_data[0].file_name()
		output:         ''
		expected_files: [
			test_data[0].filename_with_postfix('resized'),
		]
	},
	FunctionTestData{
		func:           .extract_audio
		input:          test_data[0].file_name()
		output:         ''
		expected_files: [
			test_data[0].filename_with_ext('mp3'),
		]
	},
	FunctionTestData{
		func:           .strip_audio
		input:          test_data[0].file_name()
		output:         ''
		expected_files: [
			test_data[0].filename_with_postfix('noaudio'),
		]
	},
]

fn test_all_media_commands() ! {
	setup_test_data()!
	for test in function_tests {
		test.invoke()!
		for file in test.expected_files {
			assert os.exists(file), 'case: ${test.func} expected file not found: ${file}'
			os.rm(file)!
		}
	}
	cleanup_test_data()!
}

fn test_filenames_without_exts() {
	tests := [
		'file_utils_test.v',
		'/path/to/home/test.v',
		'something_else',
	]
	asserts := [
		'file_utils_test',
		'/path/to/home/test',
		'something_else',
	]

	for i, test in tests {
		dump('testing ${test}')
		assert file_name_without_ext(test) == asserts[i]
	}
}
