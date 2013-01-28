require './scripts/setup.rb'

if ARGV.length == 1 and ARGV[0] == 'help' then
	log "toad deploy (package name) [server|android|ios]"
	exit
end

project = Toad::Project.open(CONFIG, ARGV[0])
Toad::Operator.new(project).deploy(CONFIG, ARGV.length > 1 ? ARGV[1] : nil)

