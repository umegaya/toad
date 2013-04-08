require './scripts/setup.rb'

if (ARGV.length == 1 and ARGV[0] == 'help') then
	log "toad shell (package name) [server|android]"
	exit
end

project = Toad::Project.open(CONFIG, ARGV[0])
ARGV[1] = (ARGV[1] or (:server))
Toad::Operator.new(project).login(*(ARGV[1..-1]))

