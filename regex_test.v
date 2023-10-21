module vutils

struct FindFirstTestData {
	needle 	string 
	haystack string
	expected string 
	reason string 
	error bool
}

fn test_find_first() {
	tests := [
		FindFirstTestData{'needle', 'thisisaneedleinahaystack', 'needle', 'simple string match', false},
		FindFirstTestData{'n.*le', 'thisisaneedleinahaystack', 'needle', 'simple string match', false},
		FindFirstTestData{'ha.*ck', 'thisisaneedleinahaystack', 'haystack', 'simple string match', false},
		FindFirstTestData{'nothing', 'something', '', 'should not find anything', true},
	]
	for test in tests {
		actual := find_first(test.needle, test.haystack) or {
			if !test.error {
				assert false, '$err'
			}
			''
		}
		assert actual == test.expected
	}
}

fn test_find_all() ! {
	// all matches
	case_01 := find_all('f|t[eo]+', 'foobar boo steelbar toolbox foot tooooot')
	assert case_01 == ['foo', 'tee', 'too', 'foo', 'tooooo']

	// no match
	case_02 := find_all('non-exist', 'foobar boo steelbar toolbox foot tooooot')
	assert case_02 == []
}

fn test_matches() {
	case_01 := matches('a.*e', 'abcde')
	assert case_01 == true

	case_02 := matches('a.*e', 'abcdef')
	assert case_02 == true

	case_03 := matches('^a*e$', 'abcdef')
	assert case_03 == false
}

fn test_replace() {
	case_01 := replace('tooth', 'o*', 'ee')
	assert case_01 == 'teeth'

	// group replace
	case_02 := replace('input string', 'in', 'out')
	assert case_02 == 'output stroutg'
}

fn test_find_groups() {
	case_01 := find_groups(r'(\d+)', 'abc123abc123abc123')
	assert case_01 == ['123']

	case_02 := find_groups(r'(c(pa)+z ?)+', 'cpaz cpapaz cpapapaz')
	assert case_02 == ['cpapapaz', 'pa']
}