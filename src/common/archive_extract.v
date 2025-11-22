module common

import archive.tar
import compress.szip
import os

fn extract_archive(asset_path string, asset_name string, extract_path string) ! {
	lower := asset_name.to_lower()
	match true {
		lower.ends_with('.zip') {
			szip.extract_zip_to_dir(asset_path, extract_path)!
		}
		lower.ends_with('.tar.gz') || lower.ends_with('.tgz') {
			extract_tar_gz(asset_path, extract_path)!
		}
		lower.ends_with('.tar') {
			extract_tar(asset_path, extract_path)!
		}
		lower.ends_with('.tar.xz') {
			os.execute_opt('tar -xf "${asset_path}" -C "${extract_path}"') or {
				return error('unable to extract archive: ${asset_name}: ${err}')
			}
		}
		else {
			return error('unsupported archive format: ${asset_name}')
		}
	}
}

fn extract_tar_gz(path string, dest string) ! {
	mut extractor := TarExtractor{
		base: dest
	}
	tar.read_tar_gz_file(path, extractor)!
	extractor.finish()!
}

fn extract_tar(path string, dest string) ! {
	mut extractor := TarExtractor{
		base: dest
	}
	mut untar := tar.new_untar(extractor)
	untar.read_all_blocks(os.read_bytes(path)!)!
	extractor.finish()!
}

struct TarExtractor implements tar.Reader {
	base string
mut:
	file os.File
	err  ?IError
}

fn (mut t TarExtractor) dir_block(mut read tar.Read, _ u64) {
	t.mkdir(os.join_path(t.base, read.get_path()), mut read)
}

fn (mut t TarExtractor) file_block(mut read tar.Read, size u64) {
	if !t.ensure(mut read) {
		return
	}
	t.close()
	path := os.join_path(t.base, read.get_path())
	t.mkdir(os.dir(path), mut read)
	if !t.ensure(mut read) {
		return
	}
	t.file = os.create(path) or { t.fail(err, mut read); return }
	if size == 0 {
		t.close()
	}
}

fn (mut t TarExtractor) data_block(mut read tar.Read, data []u8, pending int) {
	if !t.file.is_opened || !t.ensure(mut read) {
		return
	}
	t.file.write(data) or { t.fail(err, mut read); return }
	if pending <= 0 {
		t.close()
	}
}

fn (mut t TarExtractor) other_block(mut read tar.Read, _ string) {
	t.ensure(mut read)
}

fn (mut t TarExtractor) mkdir(path string, mut read tar.Read) {
	if !t.ensure(mut read) {
		return
	}
	os.mkdir_all(path) or { t.fail(err, mut read) }
}

fn (mut t TarExtractor) ensure(mut read tar.Read) bool {
	if t.err == none {
		return true
	}
	read.stop_early = true
	return false
}

fn (mut t TarExtractor) close() {
	if t.file.is_opened {
		t.file.close()
	}
}

fn (mut t TarExtractor) finish() ! {
	t.close()
	if err := t.err {
		return err
	}
}

fn (mut t TarExtractor) fail(err IError, mut read tar.Read) {
	if t.err == none {
		t.err = err
	}
	read.stop_early = true
	t.close()
}
