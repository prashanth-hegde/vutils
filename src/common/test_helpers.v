module common

import os
import net.http
import time

// TableCase represents a single entry in a table-driven test.
pub struct TableCase[I, E] {
	pub:
	name   string
	input  I
	expect E
}

// run_table executes the runner for each case and compares the result with the expected value.
// A readable error is returned with the failing case name.
pub fn run_table[I, E](cases []TableCase[I, E], runner fn (I) !E) ! {
	for c in cases {
		got := runner(c.input) or { return error('${c.name}: ${err}') }
		if got != c.expect {
			return error('${c.name}: expected ${c.expect}, got ${got}')
		}
	}
}

// GoldenOptions configures golden-file assertions.
pub struct GoldenOptions {
	pub:
	update_env string = 'UPDATE_GOLDEN'
}

fn should_update_golden(env string) bool {
	return os.getenv_opt(env) or { '' } != ''
}

// assert_matches_golden asserts that `actual` matches the golden file at `path`.
// If the golden is missing or different and UPDATE_GOLDEN is set, it rewrites the golden.
pub fn assert_matches_golden(path string, actual string, opts GoldenOptions) ! {
	env := if opts.update_env.len > 0 { opts.update_env } else { 'UPDATE_GOLDEN' }
	if os.exists(path) {
		expected := os.read_file(path)!
		if expected == actual {
			return
		}
		if should_update_golden(env) {
			write_golden(path, actual)!
			return
		}
		return error('golden mismatch at ${path}\nexpected:\n${expected}\nactual:\n${actual}')
	}
	if should_update_golden(env) {
		write_golden(path, actual)!
		return
	}
	return error('golden file missing: ${path} (set ${env}=1 to create/update)')
}

// write_golden writes a golden file, creating parent directories as needed.
pub fn write_golden(path string, contents string) ! {
	dir := os.dir(path)
	if dir.len > 0 && !os.exists(dir) {
		os.mkdir_all(dir)!
	}
	os.write_file(path, contents)!
}

// FakeFS is a lightweight file-system shim rooted in a temp directory.
pub struct FakeFS {
	pub:
	root string
}

// new_fake_fs creates a temporary workspace with automatic cleanup via `cleanup`.
pub fn new_fake_fs(prefix string) !FakeFS {
	root := os.join_path(os.temp_dir(), '${prefix}_${time.now().unix()}')
	os.mkdir_all(root)!
	return FakeFS{
		root: root
	}
}

// path joins the root with provided segments.
pub fn (fs FakeFS) path(parts ...string) string {
	return os.join_path(fs.root, ...parts)
}

// write writes content to a file relative to the fake root.
pub fn (fs FakeFS) write(rel_path string, content string) !string {
	full := fs.path(rel_path)
	parent := os.dir(full)
	if parent.len > 0 {
		os.mkdir_all(parent)!
	}
	os.write_file(full, content)!
	return full
}

// read reads a file relative to the fake root.
pub fn (fs FakeFS) read(rel_path string) !string {
	return os.read_file(fs.path(rel_path))!
}

// cleanup removes the fake root directory.
pub fn (fs FakeFS) cleanup() {
	if fs.root.len > 0 && os.exists(fs.root) {
		os.rmdir_all(fs.root) or {}
	}
}

// FakeHTTPResponse represents a canned HTTP response.
pub struct FakeHTTPResponse {
	pub mut:
	status  int    = 200
	body    string
	headers map[http.CommonHeader]string = map[http.CommonHeader]string{}
}

// FakeHTTP is a simple queue-based HTTP stub. Use handler as a drop-in for http.fetch.
pub struct FakeHTTP {
pub mut:
	responses []FakeHTTPResponse
	calls     []http.FetchConfig
}

// handler returns the next queued response or an error if exhausted.
pub fn (mut f FakeHTTP) handler(cfg http.FetchConfig) !http.Response {
	f.calls << cfg
	if f.responses.len == 0 {
		return error('fake http: no responses left')
	}
	resp := f.responses[0]
	if f.responses.len > 1 {
		f.responses = f.responses[1..]
	} else {
		f.responses = []
	}
	return http.Response{
		status_code: resp.status
		body: resp.body
		header: http.new_header_from_map(resp.headers)
	}
}

// reset clears recorded calls and queued responses.
pub fn (mut f FakeHTTP) reset() {
	f.calls.clear()
	f.responses.clear()
}
