module common

import time
import sync { Mutex, WaitGroup, new_mutex, new_waitgroup }

@[fields]
struct ProgressBarOpts {
	total        int  = 100
	bar_length   int  = 40
	bar_char     rune = `█`
	empty_char   rune = ` `
	show_percent bool = true
}

struct ProgressBar {
	opts       ProgressBarOpts
	start_time time.Time = time.now()
	ch         chan int
mut:
	mu       Mutex
	current  int
}

fn ProgressBar.new(opts ProgressBarOpts) ProgressBar {
	return ProgressBar{
		mu: new_mutex()
	}
}

fn (mut p ProgressBar) update_n(n int) {
	p.mu.@lock()
	p.current += n
	bar_length := f64(p.opts.bar_length)
	bar_completed := int(bar_length * (f64(p.current) / f64(p.opts.total)))
	bar_remaining := p.opts.bar_length - bar_completed
	bar := '${p.opts.bar_char.repeat(bar_completed)}${p.opts.empty_char.repeat(bar_remaining)}'
	elapsed := time.since(p.start_time)
	p.mu.unlock()

	if p.opts.show_percent {
		percent := f64(p.current) / f64(p.opts.total) * 100
		print('\r[${bar}][${percent:.2}%] ${elapsed.seconds():.2}s')
		flush_stdout()
	} else {
		print('\r[${bar}]')
		flush_stdout()
	}
}

fn (mut p ProgressBar) update() {
	p.update_n(1)
}

// fn main() {
// 	mut bar := ProgressBar.new(total: 100)
// 	for _ in 0 .. 100 {
// 		bar.update()
// 		time.sleep(100 * time.millisecond)
// 	}
// }
