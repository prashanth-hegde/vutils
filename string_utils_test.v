module vutils

struct TokenizerTestCase {
	input 		string 
	expected 	[]string 
	// reason 		string
}

fn test_tokenize() {
	test_cases := [
		TokenizerTestCase{'sample input', ['sample', 'input']},
		TokenizerTestCase{'with flags -f filename -o output', ['with', 'flags', '-f', 'filename', '-o', 'output']},
		TokenizerTestCase{"with 'single quotes'", ['with', 'single quotes']},
		TokenizerTestCase{"with -f 'single quotes'", ['with', '-f', 'single quotes']},
		TokenizerTestCase{"with  double  spaces", ['with', 'double', 'spaces']},

	]

	for test_case in test_cases {
		actual := tokenize(test_case.input)
		assert actual == test_case.expected, '${test_case.input}'
	}
}