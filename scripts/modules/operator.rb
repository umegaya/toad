module Toad
	class Operator
		def initialize(project)
			@project = project
		end
		def deploy(config, what = nil, kind = nil)
			[:server, :android, :ios].each do |type|
				next if (what and what.to_sym != type)
				case type
				when :server
					deploy_server config, kind
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
			else
				ins = instances(what)
				if ins then
					ins.login
				end
			end
		end
		def instances(kind = nil)
			key = (kind ? (kind.to_s + "_instance_id").to_sym : (:instance_id))
			id = Config.instance.project[key]
			return id ? Toad::Cloud::Instance.get(id) : nil
		end
		def extract_userdata(config, cloud_config = nil)
			if not cloud_config then
				cloud_config = config.cloud
			end
			data = IO.read(config.cloud.userdata)
			return data.
				gsub(/%REVISION%/, config.project.toad_version).
				gsub(/%DEPLOY_USER%/, (cloud_config.user or config.cloud.user)).
				gsub(/%AWS_ACCESS_KEY%/, (cloud_config.aws_access_key or config.cloud.aws_access_key or ENV['AWS_ACCESS_KEY'])).
				gsub(/%AWS_SECRET_KEY%/, (cloud_config.aws_secret_key or config.cloud.aws_secret_key or ENV['AWS_SECRET_KEY']))
		end
		def get_toad_version(ins)
			rev = ins.ssh "cd /toad && git show -s --format=%H", true
			p rev
			return rev.chop
		end
		def deploy_server(config, kind)
			p "deploy_server:" + kind.to_s
			ins = instances kind
			if (not ins) or (get_toad_version(ins) != config.project.toad_version) then
				if ins then
					ins.stop
				end
				cloud_config = (kind ? config[kind] : nil)
				p "running instance config:" + 
					((cloud_config and cloud_config.image) ? cloud_config.image : config.cloud.image) + "," +
					((cloud_config and cloud_config.instance_type) ? cloud_config.instance_type : config.cloud.instance_type) + "," +
					((cloud_config and cloud_config.keypair) ? cloud_config.keypair : config.cloud.keypair) + "," +
					((cloud_config and cloud_config.security) ? cloud_config.security : config.cloud.security) + ","
					
				ins = Toad::Cloud.run(
					(cloud_config and cloud_config.image) ? cloud_config.image : config.cloud.image, 
					(cloud_config and cloud_config.instance_type) ? cloud_config.instance_type : config.cloud.instance_type, 
					(cloud_config and cloud_config.keypair) ? cloud_config.keypair : config.cloud.keypair,
					(cloud_config and cloud_config.security) ? cloud_config.security : config.cloud.security,
					extract_userdata(config, cloud_config))

				key_instance_id = (kind ? (kind.to_s + "_instance_id") : (:instance_id))
				key_dest_ip = (kind ? (kind.to_s + "_dest_ip") : (:dest_ip))
				p "new keys:" + key_instance_id.to_s + "/" + key_dest_ip.to_s
				@project.add_setting({
					key_instance_id => ins.id,
					key_dest_ip => ins.public_ip
				})
			end
			if ins then
				update_server(ins)
			else
				raise "fail to create instance for #{@project.path}"
			end
		end
		def rsync(ins, list, option = nil)
			tmp = {}
			path = @project.path
			list.each do |k,v|
				tmp["#{path}/#{k}"] = v
			end
			ins.rsync(tmp, option)
		end
		def update_server(ins)
			first_deploy = false
			begin
				out = ins.ssh "ls ~/server"
			rescue CommandError => e
				first_deploy = true
			end
			rsync(ins, { "src/server" => "~/" }, "--delete")
			begin
				out = ins.ssh "which yue", true
			rescue CommandError => e
				if e.status.exitstatus == 1 then
					out = nil
				else
					raise e
				end
			end
			ins.wait_cloud_init if ((out == nil) or (out.chop != "/usr/local/bin/yue"))
			if first_deploy then
				begin
					ins.ssh "bash ~/server/init.sh"
                    ins.exec_until_success "bash ~/server/check.sh"
				rescue CommandError => e
					log e # no special initialization
				end
			end
			begin
				ins.ssh "sudo stop yue"
			rescue CommandError => e
				log e # maybe no such process
			end
			ins.ssh "sudo start yue"
		end
		def deploy_android(config)
			Dir.chdir("#{@project.path}/client/android/") do |path|
				sh "./run-host.sh"
			end
		end
		def deploy_ios(config)
			puts "iOS not supported yet"
		end
		def cleanup
			id = Config.instance.project.instance_id
			Toad::Cloud.stop(id) if id
		end
	end
end

