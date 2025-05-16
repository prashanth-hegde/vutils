set __goto_subcommands ls add rm clean

function goto --description "navigate to the configured bookmarks"
	# if bookmark binary is not installed, return
	if ! command -v bookmark &> /dev/null
		echo "bookmark binary is not installed..."
		return
	end

	if contains -- $argv[1] $__goto_subcommands
		bookmark $argv
	else
		set -l path (bookmark "$argv[1]")
		cd $path
	end
end

function __goto_complete_path --description "add completion for a given path"
	for item in (bookmark ls)[2..]
		set -l tokens (string split '|' $item)
		complete -c goto --no-files -a $tokens[1] -d "$tokens[2]"
	end
end
__goto_complete_path
