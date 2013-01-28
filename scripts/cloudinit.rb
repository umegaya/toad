require './scripts/setup.rb'

if ARGV.length < 1 or ARGV[0] == 'help' then
	log "toad cloudinit"
	exit
end
Toad::Project.init_server


