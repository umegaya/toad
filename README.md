toad
====

toad is king of yue!! this is all-in-one smartphone SDK for lua using MOAI SDK and yue (brand-new lua server framework), it make you forget most of network programming difficulty with super-fast and easy RPC framework. also you can develop complex server code with power of RPC.
for more details looking for
moai : http://getmoai.com
yue : https://github.com/umegaya/yue.git
lua : http://www.lua.org
luajit : http://luajit.org

directory structure
===================
toad
 +-toad			--> the toad command line tool
 +-submodules           --> required submodules for toad
    +-moai              --> moai SDK client framework (with patch to integrate with yue)
    +-yue               --> yue server framework
 +-scripts              --> toad $command actually executes $command.sh under this directory
 +-config		--> settings which is used by toad (AWS/github setting, ...)
    +-sample		--> sample configurations (copy these under config and edit)
 +-[package name]       --> created directory by toad init [package name] : please version control files under here
    +-client            --> files for client running infrastructure
       +-android        --> android related project (AndroidManifest, etc, ...) 
       +-ios            --> iOS related project (xcodeproj, etc ...)
    +-server            --> files for server running infrastructure
    +-src               --> your lua code and resources
       +-client		--> client source and resources
       +-server		--> server source and resources
       +-share		--> shared source and resources

commands
========

toad init [package name]			# create all files to run toad server and client
toad update 					# update toad (if available)
toad deploy [server|client (android|ios)]	# deploy server or client or both code

firststeps
==========
- git clone git@github.com/umegaya/toad.git
- into cloned directory
- ./toad init [package name] (caution: it will install scons,luajit,luarocks and yue if you dont have these installed)
- [edit] create config/cloud and edit like below:
	TYPE=aws # currently fixed to aws
	ACCOUNT=iam.toad@gmail.com
	PASSWORD=toad_is_beautiful
- [edit] create config/device and edit like below:
	TYPE=android # or ios, according to your phone type
- probe your mobile phone
- ./toad deploy
- now you can see running instance of toad server and your phone which pings to your toad server
- ./toad update (if you want to update toad)

FAQ
===
- I can't stand for lua's syntax nor no-standard OOP feature. so I'm ready to quit toad.
 - Don't give up and try moonscript (http://moonscript.org/). it looks like coffeescript but compiled to lua. it also has standard OOP feature but I have not checked that can get along with MOAI's one.

future
======
- support iOS (sorry, not yet but my 1st priority)
- deploy on the fly (no stop server and client process)
- more debugging feature by integrating yue and moai-sdk

