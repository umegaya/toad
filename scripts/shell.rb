require './scripts/setup.rb'

if (ARGV.length == 1 and ARGV[0] == 'help') then
	log "toad shell (package name) [server|android]"
	exit
end

project = Toad::Project.open(CONFIG, ARGV[0])
what = (ARGV.length > 1 ? ARGV[1] : :server)
Toad::Operator.new(project).login(what)

