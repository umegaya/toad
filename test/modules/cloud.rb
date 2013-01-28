require "./scripts/common.rb"
require "./test/tester.rb"
require "./scripts/modules/config.rb"
require "./scripts/modules/cloud.rb"

class TestCloud < Tester
	def initialize
		@r = nil
	end
	def is_ip(str)
		#p str
		return str =~ /[0-9]*?\.[0-9]*?\.[0-9]*?\.[0-9]*?/
	end
	def cleanup
		@r.stop if @r
	end
	def exec
		c = Toad::Config.new.open("./config/default/*").open("./config/common/*")
		Toad::Config.set_instance(c)
		assert(c.cloud.keyfile == '/home/iyatomi/Downloads/gsg-keypair.pem', "keyfile config not reloaded [#{c.cloud.keyfile}]")
		assert(is_ip("10.0.0.1"), "is_ip impl is not correct")
		@r = Toad::Cloud.run('ami-f8a813f9', 't1.micro', nil, 'default', './test/resource/userdata.sh')
		assert(@r.is_a?(Toad::Cloud::Instance), "return value type is not correct")
		assert(@r.image == 'ami-f8a813f9', "image not correct: #{@r.image}")
		assert(@r.type == 't1.micro', "type not correct: #{@r.type}")
		assert(is_ip(@r.public_ip), "#{@r.public_ip} is not IP address")
		assert(is_ip(@r.private_ip), "#{@r.private_ip} is not IP address")

		id = @r.id

		@r.rsync({"./test/resource/" => "~/rsc/"})
		out = @r.ssh "cat ~/rsc/test.rb", true
		assert(out.chop == "p \"hello toad!\"", "file copy and ssh not run correctly [#{out.chop}]")
		@r.wait_cloud_init
		out = @r.ssh "cat /tmp/hello.txt", true
		assert(out.chop == "this is toad instance", "userdata.sh not executed [#{out.chop}]")

		return
		begin
			Toad::Cloud.stop(@r)
			@r = Toad::Cloud.get(id)
		rescue
			@r = nil
		else
			assert(@r.nil?, "Tolad::Cloud.get should return nil for shutdowned instance")
		end
	end
end

t = TestCloud.new
begin
	t.exec
rescue => e
	puts e
	e.backtrace.each do |l|
		puts l
	end
ensure
	t.cleanup
end
