require "./scripts/common.rb"
require "./test/tester.rb"
require "./scripts/modules/config.rb"
require "./scripts/modules/project.rb"
require "./scripts/modules/cloud.rb"
require "./scripts/modules/operator.rb"

class TestOperator < Tester
	def initialize
		@operator = nil
	end
	def cleanup
		#@operator.cleanup if @operator
		@operator = nil
	end
	PACKAGE_NAME = "com.toad.test"
	PROJECT_PATH = "./toad_adventure"
	def exec
		sh "rm -rf #{PROJECT_PATH}"
		config = Toad::Config.new.open("./config/default/*").open("./config/common/*")
		Toad::Config.set_instance(config)
		@project = Toad::Project.open(config, PACKAGE_NAME, PROJECT_PATH)
		@operator = Toad::Operator.new(@project)
		
		@operator.deploy_server(config)

		ins = @operator.instances
		
		assert(ins, "fail to deploy")

		begin
			sh "luajit ./test/resource/ping.lua #{ins.public_ip}"
		rescue
			assert(false, "yue server not running correctly")
		end
	end
end

t = TestOperator.new
begin
	t.exec
ensure
	t.cleanup
end
