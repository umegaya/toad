require './scripts/setup.rb'

if ARGV.length == 1 and ARGV[0] == 'help' then
	log "toad init (package name) [project directory name]"
	exit
end

project = Toad::Project.open(CONFIG, ARGV[0], ARGV[1])

