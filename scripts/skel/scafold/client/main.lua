----------------------------------------------------------------
-- Copyright (c) 2010-2011 Zipline Games, Inc. 
-- All Rights Reserved. 
-- http://getmoai.com
----------------------------------------------------------------

MOAISim.openWindow ( "test", 320, 480 )

viewport = MOAIViewport.new ()
viewport:setSize ( 320, 480 )
viewport:setScale ( 320, -480 )

layer = MOAILayer2D.new ()
layer:setViewport ( viewport )
MOAISim.pushRenderPass ( layer )

gfxQuad = MOAIGfxQuad2D.new ()
gfxQuad:setTexture ( "moai.png" )
gfxQuad:setRect ( -128, -128, 128, 128 )
gfxQuad:setUVRect ( 0, 0, 1, 1 )

prop = MOAIProp2D.new ()
prop:setDeck ( gfxQuad )
layer:insertProp ( prop )

prop:moveRot ( 360, 1.5 )

local config = require('share/config')
config:open('config/', config.client_generator):
	open('config/local/', config.client_generator)
local now = yue.util.time.now
local iter = 0
yue.client(function (cl)
	local addr = 'tcp://' .. config.project.dest_ip .. ':8888'
	print('connect to ' .. addr)
	local c = yue.open(addr)
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

