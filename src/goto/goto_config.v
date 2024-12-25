import os
import json

struct Goto {
	name string
	path string
}

fn (g []Goto) save() ! {
	mut config_file := os.home_dir() + '/.config/goto.json'
	encoded_config := json.encode(g)
	os.write_file(config_file, encoded_config)!
}

fn (mut g []Goto) add(name string, path string) ! {
	g << Goto{
		name: name
		path: path
	}
	g.save()!
}

fn (mut g []Goto) remove_path(path string) ! {
	for i, j in g {
		if j.path == path {
			g.delete(i)
			break
		}
	}
	g.save()!
}

fn (mut g []Goto) remove_name(name string) ! {
	for i, j in g {
		if j.name == name {
			g.delete(i)
			break
		}
	}
	g.save()!
}

fn (mut g []Goto) clean() ! {
	// remove non-existent paths
	for i, j in g {
		if !os.exists(j.path) {
			g.delete(i)
		}
	}

	// remove duplicate paths
	mut seen_paths := map[string]bool{}
	for i in g {
		seen_paths[i.path] = false
	}

	mut unique_gotos := []Goto{}
	for i in g {
		if seen_paths[i.path] == false {
			unique_gotos << i
			seen_paths[i.path] = true
		}
	}
	unique_gotos.save()!
}
