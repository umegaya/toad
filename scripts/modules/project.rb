require 'digest/md5'
module Toad
	class Project
		ROOTPATH = "./projects"
		attr :path
		def initialize(path)
			@path = path
		end
		def self.system_path?(path)
			["submodules", "scripts", "config", "test"].each do |name|
				return true if path[-(name.length)] == name
			end
			false
		end
		def self.search_by_pkgname(pkgname)
			Dir.glob('#{ROOTPATH}/*') do |file|
				next if not File.directory?(file)
				next if system_path?(file)
				setting_file = "#{file}/config/*"
				c = Config.new.open(setting_file)
				if c.project.pkgname == pkgname then
					project = self.new(file)
					return project
				end
			end
			return nil
		end
		def self.open(config, pkgname, path = nil)
			project = self.search_by_pkgname(pkgname)
			if not project then
				path = ROOTPATH + "/" + (path or pkgname)
				raise "already exist #{path}" if File.exists?(path)
				project = self.new(path)
				project.create(config, pkgname)
			end
			Config.instance.open("#{project.path}/config/*")
			Config.instance.open("#{project.path}/config/local/*")
			return project
		end
		def self.init_server(config)
			if (File.exists?('/usr/local/bin/yue') and File.exists?('./submodules/yue/bin/yue')) then
				log "yue already installed and our yue already seems build"
				d1 = Digest::MD5.file('/usr/local/bin/yue').hexdigest()
				d2 = Digest::MD5.file('./submodules/yue/bin/yue').hexdigest()
				if d1 == d2
					log "yue already installed with same version as installed now"
					return
				end
			end
			sh "git submodule init"
			sh "git submodule update #{config.path.server_sdk}"
			Dir.chdir("#{config.path.server_sdk}") do |path|
				sh "git submodule update --init --recursive"
				sh "sudo rake install && rake test:unit && rake test:bench"
			end
			begin 
				sh "killall -9 yue" # assure all yue server is killed.
			rescue => e
				# maybe no process. ok.
			end
		end
		def android_dir()
			return @path + "/client/android"
		end
		def self.init_android_client(config, pkgname)
			arch = config.android.arch
			ndk = config.android.ndk
			Dir.chdir("#{config.path.client_sdk}/ant") do |path|
				sh "./make-host.sh -p #{pkgname} -a #{arch} -l #{ndk}"
			end
		end
		def configure_android_project(pkgname)
			appname = pkgname.split('.').last
			sdkdir = File.dirname(File.dirname `which adb`)
			
			global_setting = android_dir + "/settings-global.sh"
			replace_file(global_setting, "untitled", "#{appname}")
			# sdkdir contains /, so use | for sed command seperator.
			local_setting = android_dir + "/settings-local.sh"
			replace_file(local_setting, "android_sdk_root=\"\"", "android_sdk_root=\"#{sdkdir}\"", "|")
			replace_file(local_setting, "src_dirs=(.*)", "src_dirs=(\"../../src/client/\")", "|")
		end
		def copy_ios_files(config, update)
			sh "rsync -avzL --delete #{config.path.client_sdk}/xcode/ #{@path}/client/ios"
			Dir.chdir("#{@path}/client/") do |path|
				# TODO: ../../../ is @path dependent value. remove this. (at least derived from @path)
				if config.debug.develop_mode then
					if not update then
						sh "ln -s ../../../#{config.path.client_sdk}/src"
						sh "ln -s ../../../#{config.path.client_sdk}/3rdparty"
					end
				else
					sh "rsync -avzL --delete ../../../#{config.path.client_sdk}/src/ src"
					sh "rsync -avzL --delete ../../../#{config.path.client_sdk}/3rdparty/ 3rdparty"
				end
				sh "cp -f ios/ios/bootstrap/moai-target ios/ios/moai-target"
				sh "cp -f ios/ios/bootstrap/moai-target-stub-server ios/ios/moai-target-stub-server"
			end
		end
		def copy_server_files(config)
			deploy_tmpl = "./scripts/skel/deploy/"
			sh "cp -rv #{deploy_tmpl} ./#{@path}/server/"
			sh "cp #{Config.instance.cloud.keyfile} ./#{@path}/src/server/key.pem"
		end
		def copy_scafold_files
			scafold = "./scripts/skel/scafold"
			sh "cp -rv #{scafold}/* ./#{@path}/src/"
			["client", "server"].each do |path|
				Dir.chdir("./#{@path}/src/#{path}") do |p|
					sh "ln -s ../../config"
				end
			end
		end
		def update(config, pkgname)
			self.class.init_android_client config, pkgname
			sh "rsync -avzL --delete #{config.path.client_sdk}/ant/untitled-host/ ./#{@path}/client/android"
			sh "rm -rf #{config.path.client_sdk}/ant/untitled-host"
			copy_ios_files config, true
			copy_server_files config
			configure_android_project pkgname
			init_setting config,pkgname
			config.inspect
		end
		def create(config, pkgname)
			log "init module dependency"
				sh "git submodule update --init --recursive"

			log "init server"
				self.class.init_server config

			log "init android client"
				self.class.init_android_client config, pkgname

			log "init ios client"

			log "create directory"
				sh "mkdir -p ./#{@path}/client/"
				sh "mkdir -p ./#{@path}/server/"
				sh "mkdir -p ./#{@path}/src/"
				sh "mkdir -p ./#{@path}/config/local/"

			log "copy files"
				log "create scafold"
				copy_scafold_files

				log "copy android files"
				sh "mv #{config.path.client_sdk}/ant/untitled-host ./#{@path}/client/android"
				
				log "copy iOS files"
				copy_ios_files config, false
				
				log "copy server files"
				copy_server_files config
				
				# write setting
				init_setting(config, pkgname)

			log "auto configuration in progress"
				configure_android_project pkgname

			log "done!!"
			return self
		end
		def init_setting(config, pkgname)
			c = config["project"]
			if not c then
				c = Config.new(false)
			end
			c["toad_version"] = (sh "git show -s --format=%H", true).chop
			c["pkgname"] = pkgname
			config["project"] = c
			config.write "./#{@path}/config"
		end
		def add_setting(settings)
			c = Config.new.open("./#{@path}/config/*")
			settings.each do |k,v|
				c.project[k] = v
			end
			c.write "./#{@path}/config"
			Config.instance.open("./#{@path}/config/*")
		end
		def tarball(paths)
			tmppath = "/tmp/#{rand(0xFFFFFFFF).to_s + Process.pid.to_s}.tgz"
			command = "tar -czvf #{tmppath}"
			paths.each do |path|
				command = (command + " #{path}")
			end
			Dir.chdir(@path) do |path|
				sh command
			end
			return tmppath
		end
	end
end
