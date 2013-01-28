return {
	server_generator = function (path)
		return {
			source = io.popen('ls ' .. path),
			read = function (self)
				return self.source:read()
			end,
		}
	end,
	client_generator = function (path)
		return {
			source = MOAIFileSystem.listFiles(path),
			read = function (self)
				return self.source and table.remove(self.source, 1) or nil
			end,
		}
	end,
	open = function (self, path, generator)
		generator = (generator or self.server_generator)
		local dir = generator(path)
		while true do
			local name = dir:read()
			if not name then break end
			local filepath = (path .. '/' .. name)
			local f = loadfile(filepath)
			if f then
				local c = {}
				setfenv(f, c)
				local ok,r = pcall(f)
				if not ok then
					error('eval fails : ' .. r)
				end
				self[name] = c
			end
		end
		return self
	end
}
