require "pp"
module Toad
	class Cloud
		INIT_FILE_PATH = "/tmp/toad.cloudinit"
		INIT_FILE_SIGN = "TOAD2013"
		class EC2
			require2 "AWS", "amazon-ec2"
			@@ec2 = AWS::EC2::Base.new({
				:access_key_id => ENV['AWS_ACCESS_KEY'], :secret_access_key => ENV['AWS_SECRET_KEY']
			})
			p "ec2_url : #{ENV['EC2_URL']}"
			p "default host : #{AWS::EC2::DEFAULT_HOST}"
			@@addresses = @@ec2.describe_addresses

			def self.log(str)
				p str
			end
			def self.pprint(obj)
				#pp obj
			end
			def self.find_available_ip
				return nil
			end
			
			def self.get(id)
				result = @@ec2.describe_instances({
					:instance_id => id
				})
				self.pprint result
				return nil if not result["reservationSet"] # strange. try again
				if result["reservationSet"]["item"].length < 1 then
					raise "instance #{id} not found"
				end
				data = result["reservationSet"]["item"][0]["instancesSet"]["item"][0]
				return nil if data["instanceState"]["name"] != 'running'
				return Instance.new(
					id,
					data["imageId"],
					data["instanceType"],
					data["ipAddress"],
					data["privateIpAddress"]
				)
			end
			def self.allocate_ip(id)
				ip = self.find_available_ip
				self.log "existing ip = #{ip}"
				if not ip
					result = @@ec2.allocate_address
					self.pprint result
					ip = result["publicIp"]
					self.log "allocated ip = #{ip}"
				end
				result = @@ec2.associate_address({
					:instance_id => id,
					:public_ip => ip,
				})
				self.pprint result
				self.log "associate #{id} and #{ip}"

			end
		        def self.run(image, type, keypair, security, userdata, timeout_sec = 60)
                		image = (image or 'ami-f8a813f9') # Ubuntu 12.10
                		type = (type or 't1.micro') # micro instance
				keypair = (keypair or Config.instance.cloud.keypair)
				id = nil
				ip = nil
				if userdata then
					userdata = IO.read(userdata) if File.exists?(userdata)
					userdata = userdata + <<FINISH_SH
#!/bin/sh
echo '#{INIT_FILE_SIGN}' > #{INIT_FILE_PATH}
FINISH_SH
					puts userdata
				end
				begin
					result = @@ec2.run_instances({
						:image_id => image,
						:instance_type => type,
						:user_data => userdata,
						:base64_encoded => true,
						:security_group => security,
						:key_name => keypair,
					})
					self.pprint result
					self.log "run_instance"
					id = result["instancesSet"]["item"][0]["instanceId"]
					#ip = self.allocate_ip
					wait_sec = 0
					while true do
						result = self.get(id)
						return result if result
						sleep 2
						wait_sec = wait_sec + 2
						self.log "wait #{id} start up... #{wait_sec}"
						if wait_sec >= timeout_sec then
							raise "instance creation timeout"
						end
					end
				rescue => e
					self.log "error raises: #{e}"
					self.log e.backtrace.join('\n')
					if id then
						self.log "stop instance: #{id}"
						self.stop(id)
					end
					if ip then
						self.log "release ip: #{ip}"
						@@ec2.release_address({
							:public_ip => ip
						})
					end
					return nil
				end	
			end
			def self.stop(instance)
				if instance.is_a?(Instance) then
					instance = instance.id
				end
				@@ec2.terminate_instances({
					:instance_id => instance,
				})
			end
        	end


		Backend = EC2
		
		class Instance
			attr :id
                        attr :image
                        attr :type
                        attr :public_ip
			attr :private_ip
                        def initialize(id, image, type, ip, private_ip)
				@id = id
                                @image = image
                                @type = type
                                @public_ip = ip
				@private_ip = private_ip
				@ssh_enable = false
                        end
			def stop
				Cloud.stop(self)
			end
			def self.get(id)
				Backend.get(id)
			end
			def wait_ssh_enable
				# amazon ec2 seems to take a time to enabling SSH
				return if @ssh_enable
				count = 0
				begin
					count = count + 1
					sleep 2
					log "try ssh access #{count}"
					sshraw("pwd", true)
					@ssh_enable = true
				rescue => e
					log e
					if count < 10 then
						retry
					else
						raise "ssh retry timeout"
					end
				end
					
			end
			def wait_cloud_init(timeout = 300)
				while true
					begin
						out = ssh "cat #{INIT_FILE_PATH}", true
						p "wait cloud init #{out}"
						break if INIT_FILE_SIGN == out.chop
					rescue CommandError => e
						log e
					end
					sleep 3
					timeout = (timeout - 3)
					raise "cloud init timeout" if timeout < 0
				end
				ssh "sudo rm -f #{INIT_FILE_PATH}"
				return self
			end
			SSH_OPT = "-o \"StrictHostKeyChecking no\""
			def cp(list, keyfile = nil)
				wait_ssh_enable
				keyfile = (keyfile or Config.instance.cloud.keyfile)
				user = Config.instance.cloud.user
				list.each do |k,v|
					Kernel.sh "scp #{SSH_OPT} -i #{keyfile} #{k} #{user}@#{public_ip}:#{v}"
				end
			end
			def ssh(command, output = false, keyfile = nil)
				wait_ssh_enable
				sshraw(command, output, keyfile)
			end
			def login
				ssh("")
			end
			def sshraw(command, output = false, keyfile = nil)
				keyfile = (keyfile or Config.instance.cloud.keyfile)
				user = Config.instance.cloud.user
				Kernel.sh "ssh #{SSH_OPT} -i #{keyfile} #{user}@#{public_ip} \"#{command}\"", output
			end
			def rsync(list, keyfile = nil)
				wait_ssh_enable
				keyfile = (keyfile or Config.instance.cloud.keyfile)
				user = Config.instance.cloud.user
				list.each do |k,v|
					Kernel.sh "rsync -avzL #{k} -e 'ssh #{SSH_OPT} -i #{keyfile}' #{user}@#{public_ip}:#{v}"
				end
			end
                end

		def self.run(image, type, keyname, security, userdata)
			Backend.run(image, type, keyname, security, userdata)
		end
		
		def self.stop(instance)
			Backend.stop(instance)
		end
	end
end

