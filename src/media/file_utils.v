fn file_ext(filename string) ?string {
	return filename[(filename.last_index('.')? + 1)..]
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
