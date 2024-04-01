module common 

pub fn parse_human_duration(duration string) u64 {
	mut seconds := u64(0)
	for d in duration {
		if d.is_digit() {
			seconds = seconds * 10 + u64(d - `0`)
		} else {
			match d {
				`m` { 
					seconds = seconds * 60 
					break
				}
				`h` { 
					seconds = seconds * 60 * 60 
					break
				}
				`d` { 
					seconds = seconds * 60 * 60 * 24 
					break
				}
				else { break }
			}
		}
	}
	return seconds
}