module main

import os

fn test_list_all_globbed_files() ! {
	// setup
	os.mkdir_all('01/02/03')!
	mut f1 := os.create('01/image01.heic')!
	mut f3 := os.create('01/image01.jpg')!
	mut f2 := os.create('01/02/image02.jpg')!
	mut f4 := os.create('01/02/03/image03.jpeg')!
	f1.close()
	f2.close()
	f3.close()
	f4.close()

	defer {
		os.rmdir_all('01') or {
			println('error removing directory 01')
		}
	}

	file1_list := list_files_for_glob(['*'], true)!
	assert file1_list.len == 4

	file2_list := list_files_for_glob(['01/*.jpg'], true)!
	assert file2_list.len == 1

	file3_list := list_files_for_glob(['*/*.heic'], true)!
	assert file3_list.len == 1

	file4_list := list_files_for_glob(['*/*.jpg'], false)!
	assert file4_list.len == 1

	file5_list := list_files_for_glob(['*'], false)!
	assert file1_list.len == 4

	assert os.glob('*')!.len == 3
	println(os.glob('*')!)
}
