import os

fn file_ext(filename string) ?string {
	return filename[(filename.last_index('.')? + 1)..]
}

fn file_name_without_ext(filename string) string {
	last_index := filename.last_index('.') or { filename.len }
	return filename[..last_index]
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

// append_to_filename appends a postfix to the filename
// Preserves the file extension
fn append_to_filename(filename string, postfix string) string {
	file_ext := os.file_ext(filename)
	filename_only := filename.replace(file_ext, '')
	return '${filename_only}-${postfix}${file_ext}'
}
