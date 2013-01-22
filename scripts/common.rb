require 'pp'
module Kernel
	#TEST = true
	TEST = false
	def sh(command)
		log "#{command}"
		if not TEST
			throw $? if not system("#{command}")
		end
		true
	end
	def replace_file(path, pattern, replace, sep = '/', backup = false)
		if backup then
			sh "cp #{path} #{path}.bk"
		end
		sh "sed -e 's#{sep}#{pattern}#{sep}#{replace}#{sep}g' #{path} > #{path}.tmp"
		sh "mv #{path}.tmp #{path}"
	end
	def log(str)
		if str.is_a?(String) then
			puts str
		else
			pp str
		end
	end
end
