module logger 

import time

/******************************************************************************
*
* Poor man's logger. Having problems with built in logger sometimes not working
*
******************************************************************************/

enum LogLevel {
	trace
	debug
	info
	warn
	error
	disabled // should be the last option
}

struct Log {
mut:
	level LogLevel = .info
}

pub fn (l Log) debug(msg string) {
	if int(l.level) <= int(LogLevel.debug) {
		symbol := '[\033[94mDEBUG\33[0m]'
		println('${time.now()} ${symbol} ${msg}')
	}
}

pub fn (l Log) error(msg string) {
	if int(l.level) <= int(LogLevel.error) {
		symbol := '[\033[31mERROR\33[0m]'
		println('${time.now()} ${symbol} ${msg}')
	}
}

pub fn (l Log) info(msg string) {
	if int(l.level) <= int(LogLevel.info) {
		symbol := '[\033[32mINFO\33[0m ]'
		println('${time.now()} ${symbol} ${msg}')
	}
}

pub fn (l Log) trace(msg string) {
	if int(l.level) <= int(LogLevel.trace) {
		symbol := '[\033[94mTRACE\33[0m]'
		println('${time.now()} ${symbol} ${msg}')
	}
}

pub fn (l Log) warn(msg string) {
	if int(l.level) <= int(LogLevel.warn) {
		symbol := '[\033[33mWARN\33[0m ]'
		println('${time.now()} ${symbol} ${msg}')
	}
}

// pub const log = Log{.info}
