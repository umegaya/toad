require "./scripts/common.rb"
require "./test/tester.rb"
require "./scripts/modules/config.rb"

class TestConfig < Tester
	def initialize
		@r =Toad::Config.new
	end
	def cleanup
		#sh "rm -rf ./test/resource/tmp/*"
	end
	def exec
		path = "./config/default/*"
		@r.open(path)
		@r.inspect
		Dir.glob(path) do |file|
			key = File.basename(file)
			next if File.directory?(file)
			File.open(file).readlines().each do |line|
				line = line.chop
				next if line[0] == '#'
				a = line.split('=')
				next if a.length != 2
				assert(@r[key][a[0]] == eval(a[1]), "value #{a[0]} in #{key} should same as #{eval(a[1])} but #{@r[key][a[0]]}")
			end
		end
		@r.open("./test/resource/config/*")
		assert(@r.cloud.keyfile == '/another/path/to/pem', "reload config not correct #{@r.cloud.keyfile}")
		@r.write "./test/resource/tmp"
		File.open("./test/resource/tmp/cloud").readlines().each do |line|
			line = line.chop
			next if line[0] == '#'
			a = line.split('=')
			next if a.length != 2
			if a[0] == 'image' then
				assert('ami-f8a813f9' == eval(a[1]), "config does not write correctly(#{a[1]})")
			end
		end
	end
end

t = TestConfig.new
t.exec
t.cleanup
