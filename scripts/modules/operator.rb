module Toad
	class Operator
		def initialize(project)
			@project = project
		end
		def deploy(config, what = nil)
			[:server, :android, :ios].each do |type|
				next if (what and what.to_sym != type)
				case type
				when :server
					deploy_server config
				when :android
					deploy_android config
				when :ios
					deploy_ios config
				end
			end
		end
		def login(what)
			case what.to_sym
			when :server
				instances.login
			when :android
				sh "adb shell"
			when :ios
				raise ArgumentError, "ios login not supports"
			end
				
		end
		def instances
			id = Config.instance.project.instance_id
			return id ? Toad::Cloud::Instance.get(id) : nil
		end
		def extract_userdata(config)
			data = IO.read(config.cloud.userdata)
			return data.
				gsub(/%REVISION%/, config.project.toad_version).
				gsub(/%DEPLOY_USER%/, config.cloud.user).
				gsub(/%AWS_ACCESS_KEY%/, ENV['AWS_ACCESS_KEY']).
				gsub(/%AWS_SECRET_KEY%/, ENV['AWS_SECRET_KEY'])
		end
		def deploy_server(config)
			ins = instances
			if not ins then
				ins = Toad::Cloud.run(
					config.cloud.image, 
					config.cloud.type, 
					config.cloud.keypair,
					config.cloud.security,
					extract_userdata(config))
				@project.add_setting({
					:instance_id => ins.id,
					:dest_ip => ins.public_ip
				})
			end
			if ins then
				update_server(ins)
			else
				raise "fail to create instance for #{@project.path}"
			end
		end
		def rsync(ins, list)
			tmp = {}
			path = @project.path
			list.each do |k,v|
				tmp["#{path}/#{k}"] = v
			end
			ins.rsync(tmp)
		end
		def update_server(ins)
			rsync(ins, { "src/server" => "~/" })
			begin
				out = ins.ssh "which yue", true
			rescue CommandError => e
				if e.status.exitstatus == 1 then
					out = nil
				else
					raise e
				end
			end
			ins.wait_cloud_init if out != "/usr/local/bin/yue"
			begin
				ins.ssh "sudo stop yue"
			rescue CommandError => e
				log e # maybe no such process
			end
			ins.ssh "sudo start yue"
		end
		def deploy_android
			Dir.chdir("#{@project.path}/client/android/") do |path|
				sh "./run_host.sh"
			end
		end
		def deploy_ios
			puts "iOS not supported yet"
		end
		def cleanup
			id = Config.instance.project.instance_id
			Toad::Cloud.stop(id) if id
		end
	end
end

