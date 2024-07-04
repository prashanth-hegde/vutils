import net.http
import json

struct FontAsset {
	name string
	url string
	content_type string
	size int
	browser_download_url string
}

struct ReleaseArtifacts {
	assets []FontAsset
	tag_name string
}

/// search_nerdfont searches for all fonts in the given array of strings
/// and prints all fonts found. If there are no params, returns all fonts
fn search_nerdfont(keys []string) ![]FontAsset {
	log.info('Searching for Nerd Fonts...')
	all_fonts := list_all_fonts()!
	keys_lower := keys.map(it.to_lower())
	filtered_fonts := all_fonts.filter(it.name.to_lower().contains_any_substr(keys_lower))
	log.info('Found ${filtered_fonts.len} matching search criteria ${filtered_fonts}')
	log.debug('Filtered fonts: ${filtered_fonts}')
	for i in filtered_fonts {
		log.info('Name: ${i.name}, Size: ${i.size}')
	}

	return filtered_fonts
}

fn list_all_fonts() ![]FontAsset {
	release_url := 'https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest?per_page=1'
	release_data := http.fetch(
	method: .get
	url: release_url
	)!
	if release_data.status_code != 200 {
		return error('Failed to fetch latest release data: status=${release_data.status_code}')
	}
	artifacts := json.decode(ReleaseArtifacts, release_data.body)!
	log.info("Latest release tag: ${artifacts.tag_name}")
	tar_assets_only := artifacts.assets.filter(it.content_type == 'application/x-xz')
	log.info('Found ${tar_assets_only.len} fonts total for version ${artifacts.tag_name}')
	return tar_assets_only
}
