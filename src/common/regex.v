module common

import regex

// find_first finds the first match of the given regex pattern in the text
// This is a utility function if you're looking for a one-time find. For repeated usage of 
// find_first for the same regex string, use the original library
pub fn find_first(needle string, haystack string) ?string {
	mut re := regex.regex_opt(needle) or { return none }
	start, end := re.find(haystack)
	return if start < 0 || end < 0 { 
		none // error('no match found') 
	} else { 
		haystack[start..end] 
	}
}

pub fn find_all(needle string, haystack string) []string {
	mut re := regex.regex_opt(needle) or { return [] }
	return re.find_all_str(haystack)
}

// matches matches the input string with the provided regex
// returns true inly if the full input string matches with the given regex
// false if error or not full match
pub fn matches(needle string, haystack string) bool {
	mut re := regex.regex_opt(needle) or { return false }
	return re.matches_string(haystack)
}

// replace finds from the input txt a regex expression, and replaces with the provided replace string
// Supports groups
pub fn replace(input string, find string, replace string) string {
	mut re := regex.regex_opt(find) or { return input }
	return re.replace(input, replace)
}

// find_groups finds regex groups in the specified input string
pub fn find_groups(needle string, haystack string) []string {
	mut re := regex.regex_opt(needle) or { return []string{} }
	re.find(haystack)
	return re.get_group_list()
		.filter(it.start >= 0 && it.end >= 0)
		.map(haystack[it.start .. it.end])
}
