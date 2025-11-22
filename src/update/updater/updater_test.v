module updater

import os

fn network_tests_enabled() bool {
	return os.getenv_opt('RUN_NETWORK_TESTS') or { '' } != ''
}

// test_update_all_valid_app verifies that when update_all is called with a valid app name,
// the dummy asset is “moved” into the $HOME/bin directory.
fn test_update_all_valid_app()! {
	if !network_tests_enabled() {
		eprintln('skipping updater tests: set RUN_NETWORK_TESTS=1 to enable')
		return
	}
	// Create a temporary directory to act as HOME - so that os.home_dir() returns this path
	home_dir := os.join_path(os.temp_dir(), 'updater_test_home')
	os.setenv('HOME', home_dir, true)

	// Also set the bin_dir while at it
	bin_dir := os.join_path(home_dir, 'bin')
	os.mkdir_all(bin_dir)!

	// Call update_all with a valid app name.
	update_all(['rg'])!

	// validate
	assert os.exists(os.join_path(bin_dir, 'rg')), 'rg is not present in ${bin_dir}'

	// cleanup
	os.rmdir_all(home_dir)!
}

// test_update_all_invalid_app verifies that calling update_all with an invalid app name
// does not install any files.
fn test_update_all_invalid_app() {
	if !network_tests_enabled() {
		eprintln('skipping updater tests: set RUN_NETWORK_TESTS=1 to enable')
		return
	}
	// Create a temporary directory to act as HOME - so that os.home_dir() returns this path
	home_dir := os.join_path(os.temp_dir(), 'updater_test_home')
	os.setenv('HOME', home_dir, true)

	// Also set the bin_dir while at it
	bin_dir := os.join_path(home_dir, 'bin')
	os.mkdir_all(bin_dir)!

	// Call update_all with a valid app name.
	update_all(['non-existent-app'])!

	// validate
	assert os.ls(bin_dir)!.len == 0, 'bin directory is not empty'

	// cleanup
	os.rmdir_all(home_dir)!
}
