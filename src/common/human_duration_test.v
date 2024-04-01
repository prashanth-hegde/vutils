module common 

fn test_parse_human_duration() {
	assert parse_human_duration('1s') == 1
	assert parse_human_duration('1m') == 60
	assert parse_human_duration('1h') == 60 * 60
	assert parse_human_duration('1d') == 60 * 60 * 24
	assert parse_human_duration('1s1m1h1d') == 1
	assert parse_human_duration('24') == 24
	assert parse_human_duration('24h') == 24 * 60 * 60
}