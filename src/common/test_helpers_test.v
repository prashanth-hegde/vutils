module common

import os
import net.http

fn test_run_table_success() ! {
	cases := [
		TableCase[int, int]{
			name:   'double 2'
			input:  2
			expect: 4
		},
		TableCase[int, int]{
			name:   'double 5'
			input:  5
			expect: 10
		},
	]
	run_table[int, int](cases, fn (i int) !int {
		return i * 2
	})!
}

fn test_run_table_failure() {
	cases := [
		TableCase[string, string]{
			name:   'greet'
			input:  'v'
			expect: 'hi v'
		},
	]
	mut failed := false
	run_table[string, string](cases, fn (s string) !string {
		return 'hello ${s}'
	}) or {
		failed = true
		assert err.msg().contains('expected')
	}
	assert failed
}

fn test_golden_helpers_create_and_compare() ! {
	mut fs := new_fake_fs('golden_test')!
	defer {
		fs.cleanup()
	}
	path := fs.path('golden', 'sample.txt')

	// first call should fail because file is missing and update env not set
	mut missing := false
	assert_matches_golden(path, 'content', GoldenOptions{}) or {
		missing = true
	}
	assert missing, 'expected missing golden to fail'

	// enable update to create the golden
	os.setenv('UPDATE_GOLDEN', '1', true)
	defer {
		os.unsetenv('UPDATE_GOLDEN')
	}
	assert_matches_golden(path, 'content', GoldenOptions{})!
	// now matches
	assert_matches_golden(path, 'content', GoldenOptions{})!
}

fn test_fake_fs_basic_ops() ! {
	mut fs := new_fake_fs('fake_fs')!
	defer {
		fs.cleanup()
	}
	fs.write('nested/file.txt', 'data')!
	assert fs.read('nested/file.txt')! == 'data'
	assert os.exists(fs.path('nested/file.txt'))
}

fn test_fake_http_handler() ! {
	mut fake := FakeHTTP{
		responses: [
			FakeHTTPResponse{
				status: 200
				body:   'ok'
			},
		]
	}
	resp := fake.handler(http.FetchConfig{})!
	assert resp.status_code == 200
	assert resp.body == 'ok'
	assert fake.calls.len == 1
}
