local yue = require 'yue'
local config = require('./share/config'):
	open('./config/'):
	open('./config/local/')

yue.listen('tcp://0.0.0.0:8888', {
	ping = function (t)
		print('receive ping: at ' .. t)
		return t
	end,
})


