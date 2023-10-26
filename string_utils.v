module vutils
import datatypes { Stack }

const quot_chars := [`'`, `"`]
fn is_quote(inp u8) bool {
	return inp in quot_chars
}

// tokenize splits the input string into multiple tokens, splitting in spaces,
// while preserving spaces when a string is enclosed within quotes
pub fn tokenize(input string) []string {
	mut tokens := []string{}
	mut start := 0

	mut quotes := Stack[u8]{}
	for idx, i in input {
		if (is_quote(i)) && (quotes.peek() or {`0`}) == i {
			quotes.pop() or { continue }
			if idx == input.len - 1 {
				tokens << input[start .. idx]
			}
		} else if i in [`"`, `'`] {
			if idx >= start && quotes.len() == 0 {
				start = idx + 1
			}
			quotes.push(i)
		} else if i.is_space() && quotes.len() == 0 {
			tokens << input[start .. idx]
			start = idx + 1
		} else if idx == input.len - 1 {
			tokens << input[start .. idx + 1]
		}
	}

	return tokens.filter(it != '')
}
