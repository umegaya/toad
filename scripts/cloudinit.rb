require './scripts/setup.rb'

if ARGV.length > 0 and ARGV[0] == 'help' then
	log "toad cloudinit"
	exit
end
Toad::Project.init_server Toad::Config.instance


