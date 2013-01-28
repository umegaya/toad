require 'pp'
module Toad
	class CommandError < RuntimeError
		attr :status
		def initialize(status)
			@status = status
		end
	end
end
module Kernel
	#TEST = true
	TEST = false #CONFIG.debug.test
	def sh(command, output = false)
		log "#{command}"
		if not TEST
			if output then
				out = `#{command}`
				raise Toad::CommandError.new($?), command unless $?.exitstatus == 0
				return out
			else
				raise Toad::CommandError.new($?), command if not system("#{command}")
			end
		end
		true
	end
	def replace_file(path, pattern, replace, sep = '/', backup = false)
		if backup === true then
			sh "cp #{path} #{path}.bk"
		end
		dest = (backup.is_a?(String) ? backup : path)
		sh "sed -e 's#{sep}#{pattern}#{sep}#{replace}#{sep}g' #{path} > #{path}.tmp"
		sh "mv #{path}.tmp #{dest}"
	end
	 def find_in_file(f, pattern)
		need_close = false
		if f.is_a?(String) then
                	return nil if not File.exists?(f)
			f = File.open(f)
			need_close = true
		elsif f.is_a?(File)
		else
			raise "invalid object passes as file #{f.class}"
		end
		if pattern.is_a?(String) then
			pattern = Regexp.new(pattern)
		end
		result = nil
                f.readlines().each do |l|
			#p "#{l} vs #{pattern}"
                        if l =~ pattern then
                                result = $~
				break;
                        end
                end
		if need_close then
			f.close
		else
			f.rewind
		end
                return result
        end
	def log(str)
		if str.is_a?(String) then
			puts str
		else
			pp str
		end
	end
	def require2(name, gem = nil, version = nil)
		begin
			require name
		rescue LoadError => e
			gem = (gem or name)
			version = (version ? " -v #{version}" : "")
			raise $? unless system "sudo gem install #{gem}#{version}"
			gem_dir = File.dirname File.dirname `gem which #{name}`
			$:.unshift "#{gem_dir}/bin"
			$:.unshift "#{gem_dir}/lib"
			retry
		end
	end
end
