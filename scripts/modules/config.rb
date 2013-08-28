require_relative "../common.rb"
require 'json'

module Toad
	BasicObject = class_exists?("::BasicObject") ? ::BasicObject : Object
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
				fval = ::File.open(file).read
				load ::JSON.parse(fval), key
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
			::Kernel.raise ::NoMethodError, "undefined method `#{action}' for Toad::Config" unless action =~ /^\w+$/
			k = action.to_sym
			if args.length == 0 then
				@hash[k] or (@root ? (@hash[k] = Config.new(false)) : nil)
			elsif args.length == 1
				@hash[k] = args[0]
			else
				::Kernel.raise ::ArgumentError, "wrong number of arguments (#{args.count} for 1)"
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
			@hash.each do |name, config|
				fval = ::JSON.pretty_generate(::JSON.parse(config.to_json))
				f = ::File.open("#{to}/#{name}", "w")
				f.write(fval)
				f.close
			end
			return true
		end
		def load(data, key = nil)
			if data.is_a?(::Hash) then
				c = key ? (self[key] or (self[key] = Config.new(false))) : Config.new(false)
				data.each do | k, v |
					c.load v, k
				end
				data = c
			elsif data.is_a?(::Array) then
				a = ::Array.new
				data.each do | v |
					a.push(load v)
				end
				data = a
			end
			return data unless key
			self[key] = data
		end
		def dup()
			c = Config.new(false)
			self.each do | k, v |
				c[k] = v
			end
			return c
		end
		def respond_to?(type = nil)
			@respond_to = type if type
			return @respond_to
		end
		def to_json(js = nil)
			return @hash.to_json js
		end
	end
end

