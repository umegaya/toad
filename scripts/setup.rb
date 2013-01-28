# require all modules under modules directory
require "./scripts/common.rb"
Dir.glob("./scripts/modules/*.rb") do |file|
	require file
end

# load all config files under config path
config = Toad::Config.new
Toad::Config.set_instance(config)
config.open("./config/default/*")
config.open("./config/common/*")


# store it as constant 'CONFIG'
CONFIG = config

