
class Tester
	def cleanup
	end
	def assert(cond, msg = nil)
		if not cond
			puts (msg or "assertion fails")
			caller.each do |l|
				puts l
			end
			cleanup
			exit(127)
		end	
	end
end
