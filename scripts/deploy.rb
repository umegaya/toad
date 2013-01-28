require './scripts/setup.rb'

if ARGV.length < 1 or ARGV[0] == 'help' then
	log "toad deploy (package name)"
	exit
end

path = Toad::Util::find_project_from_package_name(ARGV[0])

# currently, I need to concentrate to run server instance which execute specified lua server code with yue.

