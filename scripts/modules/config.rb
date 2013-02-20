require File.dirname(__FILE__) + "/../common.rb"

module Toad
	BasicObject = Object
	if class_exists?("::BasicObject") then
		BasicObject = ::BasicObject
	end
	class Config < BasicObject
		@@instance = nil
		def self.instance
			@@instance
		end
		def self.set_instance(c)
			@@instance = c
		end
		def initialize(root = true)
			@root = root
			@hash = {}
		end
		def open(path)
			::Kernel.raise ::ArgumentError, "no wild card in #{path}" unless path.match(/\*/)
			::Dir.glob(path) do |file|
				key = ::File.basename(file)
				next if ::File.directory?(file)
				c = (self[key] or (self[key] = Config.new(false)))
				c.instance_eval ::File.open(file).read.gsub /\=/, ' '
			end
			return self
		end
		def p(str)
			::Kernel.p str
		end
		def is_a?(klass)
			klass == Config
		end
		def method_missing(action, *args)
			k = action.to_sym
			if args.length < 1 then
				k = action.to_sym
				@hash[k] or (@root ? (@hash[k] = Config.new(false)) : nil)
			else
				@hash[k] = args[0]
			end
		end
		def [] (k)
			@hash[k.to_sym]
		end
		def []= (k, v)
			@hash[k.to_sym] = v
		end
		def each(&block)
			@hash.each(&block)
		end
		def inspect(depth = 0)
			tab = depth > 0 ? (" " * depth) : ""
			@hash.each do |k,v|
				if v.is_a?(Config) then
					::Kernel.puts "#{tab}#{k} => "
					v.inspect(depth + 1)
				else
					::Kernel.puts "#{tab}#{k} => #{v}"
				end
			end
		end
		def write(to)
			raise ArgumentError, "not root config" unless @root
			@hash.each do |name,config|
				::File.open("#{to}/#{name}", "w") do |f|
					config.each do |k,v|
						f.write("#{k}=#{v.inspect}\n")
					end	
				end
			end
		end
	end
end

