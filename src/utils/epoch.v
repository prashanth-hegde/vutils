import time
import regex
import os

// to_epoch converts a relative duration to epoch
// Example:
//  epoch 2h --> returns the epoch for 2 hours ago
//  epoch 4m --> returns the epoch for 4 minutes ago
//  epoch 1d --> returns the epoch for 1 day ago
// All epoch values are returned in millisecond precision
fn to_epoch(num int, unit string) {
  delta := match unit {
    's' { num }
    'm' { num * 60 }
    'h' { num * 60 * 60 }
    'd' { num * 60 * 60 * 24 }
    else { num }
  }

  // get the epoch and subtract delta from it
  epoch_utc := time.utc().unix_time_milli()
  relative_epoch := epoch_utc - delta * 1000
  println(relative_epoch)
}

// from_epoch converts a given epoch timestamp to
// a human readable time
fn from_epoch(param string) {
  epoch_utc := param.i64()
  sec := if param.len > 10 { epoch_utc / 1000 }
         else { epoch_utc }

  epoch_time := time.unix(sec)
  println('$epoch_time utc')
  println('${epoch_time.local()} local')
}

fn main() {
  mut re_from_epoch := regex.regex_opt(r'^\d+$') or { panic(err) }
  mut re_to_epoch := regex.regex_opt(r'^(\d+)([smhd])$') or { panic(err) }

  if os.args.len == 2 && re_from_epoch.matches_string(os.args[1]) {
    from_epoch(os.args[1])
  } else if os.args.len == 2 && re_to_epoch.matches_string(os.args[1]) {
    num := re_to_epoch.get_group_by_id(os.args[1], 0).int()
    unit := re_to_epoch.get_group_by_id(os.args[1], 1)
    to_epoch(num, unit)
  } else {
    to_epoch(0, 's')
  }
}
