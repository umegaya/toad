require "yaml"
require "google_drive"

module Toad
	class Util
		module Logger
			class Terminate < RuntimeError

			end
			def log_puts(*argv)
				puts(*argv)
			end
			def log_print(*argv)
				print(*argv)
			end
			def log_p(*argv)
				p(*argv)
			end
			def terminate(text = nil)
				raise Terminate, text
			end
		end
		module SpreadSheet2LuaHelper
			## sanitize and complete it if it is incomplete JSON
			def sanitizeString(value)
				begin
					i = Integer(value)
					return i.to_s
				rescue ArgumentError
				end
				if value.length <= 0 then
					return "''"
				end
				data = getYamlHash(value)
				# print as lua value
				return dumpLuaTable(data)
			end

			def getYamlHash(value)
				orgvalue = value
				# does value seems yaml string?
				value = value.gsub(/\n/, "")
				if value.match(/[\[\]\:\{\}]/) then
					# seems JSON string
					if not (value[0] == "{") then
						value = "{" + value + "}"
					end
					value = value.gsub(/([\[\]\:\,\{\}])/, "\\1 ")
				end
				# p "parse string:" + value
				begin
					data = YAML.load(value)
				rescue => e
					if e.is_a?(ArgumentError) then
						data = orgvalue # fall back to string
					else
						raise e
					end
				end
				return data
			end

			def getKeys(str)
				ret = str.split(/ *, */)
				return ret
			end


			## convert any ruby data structure into lua value (text expression)
			def dumpLuaTable(data)
				if data.is_a?(Array) then
					str = "{"
					data.each do |v|
						str = (str + dumpLuaTable(v) + ",")
					end
					str = (str + "}")
					return str
				elsif data.is_a?(Hash) then
					str = "{"
					data.each do |k, v|
						if k =~ /[a-zA-Z0-9]/ then
							str = (str + k + "=" + dumpLuaTable(v) + ",")
							else
							str = (str + "[" + dumpLuaTable(k) + "]=" + dumpLuaTable(v) + ",")
						end
					end
					str = (str + "}")
					return str
				elsif data.is_a?(String) then
					return "'" + data.gsub(/(\'+?)/, "\\\\\\1") + "'"
				else
					return data.to_s
				end
			end
		end
		

		class SpreadSheet2Lua
			include SpreadSheet2LuaHelper
			def initialize(spreadsheet_id, outdir, account_id, password, ignores, options = {})
				@sheet_id = spreadsheet_id
				@outdir = outdir
				@acc = account_id
				@pass = password
				@ignores = ignores
				@options = options
				p "in_init:" + @ignores
			end
			
			## read one spreadsheet and convert it to lua table
			def to_lua(ws, output, ignorelist)
				return false if ignorelist and ignorelist.include?(ws.title)
				first = true
				path = output + "/" + ws.title + ".lua"
				f = File.open(path, "w")
				if not f then
					raise "fail to open #{path}"
				end
				basename = ws.title.gsub(/_(\w)/) do |s| 
					$1.capitalize 
				end.sub(/^(\w)/) do |s|
					s.capitalize
				end
				f.write("return {\n")
				f.write("\"#{basename}\",\n")
				ws.rows.each do |row|
					if first then
						f.write("{")
						row.each do |val|
							f.write("#{sanitizeString val},")
						end
						f.write("},\n")
					else
					end
				end
				f.write("}\n")
				f.close
				return basename
			end
			
			# main convert to routine. it loads google spreadsheet and dump it as lua tables.
			def convert()
				# Logs in.
				# You can also use OAuth. See document of
				# GoogleDrive.login_with_oauth for details.
				session = GoogleDrive.login(@acc, @pass)
				p @ignores
				if @ignores.is_a?(String) then
					@ignores = @ignores.split(',')
				end
				p "ignores:" + @ignores.to_s
 
				if (dumpLuaTable({}) != "{}") then
					p "dumpLuaTable({}) is " + dumpLuaTable({}) + " should be {}"
				end
 
				@classes = {}
				sheet = session.spreadsheet_by_key(@sheet_id)
				sheet.worksheets.each do |ws|
					p "converting #{ws.title}"
					p ws.rows
					@classes[ws.title] = to_lua(ws, @outdir, @ignores)
				end
				return @classes
			end
		end
	end
end


