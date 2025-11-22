module common

import net.http
import os
import time

fn test_extract_archive_tar_gz() ! {
	archive_url := 'https://github.com/prashanth-hegde/vutils/releases/download/0.4.7/vutils-x86_64-apple-darwin.tgz'
	archive_name := 'vutils-x86_64-apple-darwin.tgz'
	archive_path := os.join_path(os.temp_dir(), archive_name)
	extract_path := os.join_path(os.temp_dir(), 'archive_extract_test_${time.now().unix()}')

	// ensure a clean slate and cleanup after the test
	if os.exists(archive_path) {
		os.rm(archive_path)!
	}
	if os.exists(extract_path) {
		os.rmdir_all(extract_path)!
	}
	defer {
		if os.exists(archive_path) {
			os.rm(archive_path) or {}
		}
		if os.exists(extract_path) {
			os.rmdir_all(extract_path) or {}
		}
	}

	http.download_file(archive_url, archive_path)!
	os.mkdir_all(extract_path)!

	extract_archive(archive_path, archive_name, extract_path)!

	bookmark_path := os.join_path(extract_path, 'bin', 'bookmark')
	update_path := os.join_path(extract_path, 'bin', 'update')

	assert os.exists(bookmark_path)
	assert os.exists(update_path)
	assert os.stat(bookmark_path)!.size > 0
	assert os.stat(update_path)!.size > 0
}
