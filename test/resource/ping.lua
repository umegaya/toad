local yue = require 'yue'
local now = yue.util.time.now
local iter = 0
local ok, r = yue.client(function (cl)
	print "client"
	local c =  yue.open('tcp://' .. arg[1] .. ':8888').procs
	while true do
        	local t = now()
        	local df = c.ping(t) - now()
        	print('latency:' .. (-df))
        	iter = iter + 1
        	if iter > 10 then
                	cl:exit(true, iter)
        	end
	end
end)

print('finish', ok, r)
