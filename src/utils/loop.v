import common 
import cli { Command, Flag, }
import os
import arrays { join_to_string }
import time

const log := &common.Log{.info}
const version := '0.0.1'

fn loop_until(cmd Command) ! {
  if cmd.flags.get_bool('verbose') or {false} {
    (*log).level = .debug
  }
  parse_duration := fn(dur string) !u32 {
    dur_tokens := common.find_groups(r'(\d+)([smh])', dur)
    if dur_tokens.len != 2 {
      return error('invalid duration $dur, please check your input')
    }
    num, unit := dur_tokens[0].u32(), dur_tokens[1]
    return match unit {
      's' { num }
      'm' { num * 60 }
      'h' { num * 3600 }
      else { num }
    }
  }

  times := cmd.flags.get_int('times') or {0}
  end_str := cmd.flags.get_string('end') or {'0s'}
  end := parse_duration(end_str) !
  sleep_str := cmd.flags.get_string('sleep') or {'1s'}
  sleep := parse_duration(sleep_str) !
  //fail := cmd.flags.get_bool('fail') or {false}
  //pass := cmd.flags.get_bool('fail') or {false}
  cmd_raw := join_to_string(cmd.args, ' ', fn (x string) string { 
    return if x.contains(' ')  { '"$x"' }
    else { x }
  })
  if times > 0 {
    log.debug('looping for $times times with sleep $sleep second(s), cmd = $cmd_raw')
    for i in 0..times {
      log.debug('executing iteration $i')
      println(os.execute_or_exit(cmd_raw).output)
      if i < times - 1 {
        time.sleep(sleep * time.second)
      }
    }
  } else if end > 0 {
    log.debug('looping for $end seconds with sleep $sleep second(s), cmd = $cmd_raw')
    start := time.now()
    mut iteration := 1
    for {
      log.debug('executing iteration ${iteration++}')
      println(os.execute_or_exit(cmd_raw).output)
      elapsed_seconds := time.since(start).seconds()
      if elapsed_seconds >= end {
        break
      }
      time.sleep(sleep * time.second)
    }
  } else {
    eprintln(cmd.help_message())
    return error('invalid command, check usage')
  }
}

fn loop_file(cmd Command) ! {
  // TODO: Implementation pending
  if cmd.flags.get_bool('verbose') or {false} {
    (*log).level = .debug
  }
  println(cmd)
}

fn main() {
  parse_cmd()
}

// =========== Command Line parser ========

fn parse_cmd() {
  mut main_cmd := Command {
    name: 'loop'
    description: 'rinse, repeat'
    disable_man: true
    flags: [
      Flag {
        name: 'verbose'
        abbrev: 'v'
        description: 'print more info about the commands and output'
        global: true
        flag: .bool
      },
    ],
    commands: [
      Command {
        name: 'until'
        required_args: 1
        description: 'loops until a specified time'
        execute: loop_until
        usage: '
        | "until" specifies and ending condition for the loop to terminate, always runs single threaded
        | loop until -end 10m ls -l # loops for 5 minutes with a default sleep of 1 second
        | loop until -sleep 2s 1h ls -l # loops for 1 hour with a sleep of 2 seconds, and executes the given command
        | loop until -fail ls -l # loops until the given command fails
        | loop until -pass ls -l # loops until the given command passes
        | loop until -times 10 echo \$N # loops for 10 times and prints the count every time with default sleep of 1 second
        '.strip_margin()
        flags: [
          Flag {
            name: 'times'
            abbrev: 't'
            description: 'number of times to repeat the given task'
            flag: .int
          },
          Flag {
            name: 'sleep'
            abbrev: 's'
            description: 'sleep duration between executions'
            flag: .string
            default_value: ['1s']
          },
          Flag {
            name: 'end'
            abbrev: 'E'
            description: 'loops until this time is lapsed'
            flag: .string
            default_value: ['1s']
          },
        ]
      },
      Command {
        name: 'file'
        required_args: 1
        description: 'loops over the lines of an input file'
        execute: loop_file
        usage: '
        | example input file: 
        | 01: ls -l
        | 02: wc -l
        | 
        | loop file input_file -d ":" -- $2 # splits each line by its delimiter(:), takes the second part and executes it
        | loop file input_file -d ":" -- echo "\$1"; \$2 # same as above, also printing the first part of delimited line
        | loop file input_file -d ":" -- echo $0 # prints the entire line on screen. In this case, echo is the command executed on every line 
        | loop file input_file -w 2 -- echo $0 # uses 2 workers in parallel 
        '.strip_margin()
        flags: [
          Flag {
            name: 'workers'
            abbrev: 'w'
            description: 'number of workers to run in parallel, order is not guaranteed if greater than 1'
            flag: .int
            default_value: ['1']
          },
          Flag {
            name: 'delimiter'
            abbrev: 'd'
            description: 'an awk like delimiter to split a line and use multiple values'
            flag: .string
          },
        ]
      },
      Command {
        name: 'test'
        description: 'executes test, internal use'
        execute: test_loop
      },
      Command {
        name: 'version'
        description: 'prints the version of the program'
        execute: fn (cmd Command) ! {
          println(version)
        }
      },
    ]
  }

  main_cmd.setup()
  main_cmd.parse(os.args)
}

// =========== Tests ==========

fn test_loop(cmd Command) ! {
  println('this is a test')
}