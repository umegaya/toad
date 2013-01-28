require 'digest/md5'
module Toad
	class Project
		class Setting
			PATH = ".setting"
			PKGNAME = "pkgname"
			VERSION = "version"
			attr :path
			attr :pkgname
			attr :version
			def initialize(path)
				@path = path
				@pkgname = nil
				@version = nil
			end
			def create(pkgname, config)
				path = fullpath
				begin
					f = File.open(path, "r")
				rescue Errno::ENOENT
					f = File.open(path, "w")	
					@pkgname = pkgname
					@version = config.toad.version
					write_file(f)
                        		f.close
					return self
				else
					read_file(f)
					f.close
					return self
				end
			end
			def fullpath
				"#{path}/#{PATH}"
			end
			def read_file(f)
				f.rewind
				res = find_in_file(f, "#{PKGNAME}=(.*)")
				raise "invalid setting file (#{PKGNAME}) #{f} [#{res}]" if not res
				@pkgname = res[1]
				res = find_in_file(f, "#{VERSION}=(.*)")
				raise "invalid setting file (#{VERSION}) #{f} [#{res}]" if not res
				@version = res[1]
			end
			def method_missing(action, *args)
				res = find_in_file(fullpath, "#{action}=(.*)")
				return nil if not res
				return res[1]
			end
			def write_file(f)
				f.write("#{PKGNAME}=#{@pkgname}\n")
				f.write("#{VERSION}=#{@version}\n")
			end
			def write(k, v)
				raise "invalid setting path #{fullpath}" if not File.exists?(fullpath)
				f = File.open("#{fullpath}.tmp", "w")
				raise "fail to open tmp file" if not f
				replace = false
				File.open(fullpath).readlines().each do |l|
					if l[0..k.length] == k then
						f.write("#{k}=#{v}")
						replace = true
					else
						f.write l
					end
				end
				if not replace then
					f.write("#{k}=#{v}")
				end
				f.close
				sh "mv #{fullpath}.tmp #{fullpath}"
			end
		end
		attr :path
		#attr :setting
		def initialize(path)
			@path = path
			#@setting = Toad::Project::Setting.new(path)
		end
		def self.system_path?(path)
			["submodules", "scripts", "config", "test"].each do |name|
				return true if path[-(name.length)] == name
			end
			false
		end
		def self.search_by_pkgname(pkgname)
                        Dir.glob('./*') do |file|
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
				path = (path or pkgname)
				raise "already exist #{path}" if File.exists?(path)
				project = self.new(path)
				project.create(config, pkgname)
			end
			Config.instance.open("#{path}/config/*")
			Config.instance.open("#{path}/config/local/*")
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
                end
		def create(config, pkgname)
			arch = config.android.arch
			ndk = config.android.ndk
			sdkdir = File.dirname(File.dirname `which adb`)
			appname = pkgname.split('.').last
			scafold = "./scripts/skel/scafold"
			deploy_tmpl = "./scripts/skel/deploy/"


			log "init module dependency"
				sh "git submodule update --init --recursive"

			log "init server"
				self.class.init_server config

			log "init android client"
				android_dir = @path + "/client/android"
				Dir.chdir("#{config.path.client_sdk}/ant") do |path|
        				sh "./make-host.sh -p #{pkgname} -a #{arch} -l #{ndk}"
				end

			log "init ios client"
				# TODO

			log "create directory"
				sh "mkdir -p ./#{@path}/client/"
				sh "mkdir -p ./#{@path}/server/"
				sh "mkdir -p ./#{@path}/src/"
				sh "mkdir -p ./#{@path}/config/local/"

			log "copy files"
				sh "mv #{config.path.client_sdk}/ant/untitled-host ./#{@path}/client/android"
				sh "cp -rv #{scafold}/* ./#{@path}/src/"
				["client", "server"].each do |path|
					Dir.chdir("./#{@path}/src/#{path}") do |p|
						sh "ln -s ../../config"
					end
				end
				sh "cp -rv #{deploy_tmpl} ./#{@path}/server/"
				# write setting
				init_setting(config, pkgname)

			log "auto configuration in progress"
				global_setting = android_dir + "/settings-global.sh"
				replace_file(global_setting, "untitled", "#{appname}")
				# sdkdir contains /, so use | for sed command seperator.
				local_setting = android_dir + "/settings-local.sh"
				replace_file(local_setting, "android_sdk_root=\"\"", "android_sdk_root=\"#{sdkdir}\"", "|")
				replace_file(local_setting, "src_dirs=(.*)", "src_dirs=(\"../../src/client/\")", "|")

			log "done!!"
			return self
		end
		def init_setting(config, pkgname)
			c = Config.new(false)
			c["toad_version"] = sh "git show -s --format=%H", true
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
