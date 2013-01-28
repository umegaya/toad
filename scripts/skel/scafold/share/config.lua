return {
	open = function (self, path)
		local dir = io.popen('ls ' .. path)
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
