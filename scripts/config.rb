# available config variable key
TYPE='type'
ACCOUNT = 'account'
PASSWORD = 'password'

# config path
CONFIG_PATH="./config/*"

# load all config files under config path
module Toad 
class Config
	def initialize(root = false)
		@root = root
		@hash = {}
	end
	def method_missing(action, *args)
		k = action.to_sym
		@hash[k] or (@root ? (@hash[k] = Config.new) : nil)
	end
	def [] (k)
		@hash[k.to_sym]
	end
	def []= (k, v)
		@hash[k.to_sym] = v
	end
end
end
config = Toad::Config.new(true)

# pre-defined configs
config.path['client_sdk'] = './submodules/moai'
config.path['server_sdk'] = './submodules/yue'

# custom configs
Dir.glob(CONFIG_PATH) do |file|
	key = File.basename(file)
	next if File.directory?(file)
	File.open(file).readlines().each do |line|
		line = line.chop
		next if line[0] == '#'
		a = line.split('=')
		next if a.length != 2
		config[key] = Toad::Config.new if not config[key]
		config[key][a[0]] = a[1]
	end
end

# store it as constant 'CONFIG'
CONFIG = config
