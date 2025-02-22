module docgen

import os
import arrays

fn test_get_valid_ext_files() {
	file_list := [
		'/tmp/test1.txt',
		'/tmp/test2.v',
		'/tmp/test3.md',
		'/tmp/ignore/.git',
	]

	set_log_level(.debug)
	all_files := get_valid_ext_files(file_list, []string{})
	assert all_files.len == 3, 'did not filter out glob patterns'

	ext_files := get_valid_ext_files(file_list, ['v'])
	assert ext_files.len == 1, 'did not filter for .v files'
}

fn test_print_stats() ! {
	set_log_level(.debug)
	ext_files := [
		'/tmp/test1.txt',
		'/tmp/test2.v',
		'/tmp/test3.md',
	]

	raw_txt := '1\n\n2\n\n3\n'
	for f in ext_files {
		os.write_file(f, raw_txt)!
	}
	stats := print_stats(ext_files)
	assert stats.contains('files scanned: 3'), 'did not print correct file count'
	// assert stats.contains('')

	// cleanup
	for f in ext_files {
		os.rm(f)!
	}
}

fn test_uniqueness() {
	duplicate_list := [
		'/tmp/test1.txt',
		'/tmp/test2.v',
		'/tmp/test3.md',
		'/tmp/ignore/.git',
		'/tmp/test2.v', // duplicate
	]

	deduped := arrays.uniq(duplicate_list.sorted())
	assert deduped.len == 4, 'did not remove duplicates'
}
