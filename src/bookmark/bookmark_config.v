import os
import json

struct Bookmark {
	name string
	path string
}

fn (g []Bookmark) save() ! {
	mut config_file := os.join_path(os.home_dir(), '.config', 'goto.json')
	encoded_config := json.encode(g)
	os.write_file(config_file, encoded_config)!
}

fn (mut g []Bookmark) add(name string, path string) ! {
	g << Bookmark{
		name: name
		path: path
	}
	g.save()!
}

fn (mut g []Bookmark) remove_path(path string) ! {
	for i, j in g {
		if j.path == path {
			g.delete(i)
			break
		}
	}
	g.save()!
}

fn (mut g []Bookmark) remove_name(name string) ! {
	for i, j in g {
		if j.name == name {
			g.delete(i)
			break
		}
	}
	g.save()!
}

fn (mut g []Bookmark) clean() ! {
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

	mut unique_bookmarks := []Bookmark{}
	for i in g {
		if seen_paths[i.path] == false {
			unique_bookmarks << i
			seen_paths[i.path] = true
		}
	}
	unique_bookmarks.save()!
}

fn (g []Bookmark) goto(key string) !string {
	// first preference goes to keys
	for i in g {
		if key.to_lower() == i.name.to_lower() || i.name.to_lower().contains(key.to_lower()) {
			return i.path
		}
	}

	// if keys not found, search in paths
	for i in g {
		if i.path.to_lower().contains(key.to_lower()) {
			return i.path
		}
	}

	return error('path not found')
}
