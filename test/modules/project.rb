require "./scripts/common.rb"
require "./test/tester.rb"
require "./scripts/modules/config.rb"
require "./scripts/modules/project.rb"

class TestProject < Tester
	def initialize
		@r = nil
	end
	def cleanup
		if @r then
			sh "rm -rf #{@r.path}"
		end
	end
	PACKAGE_NAME = "com.toad.test"
	PROJECT_NAME = "toad_adventure"
	PROJECT_PATH = "./#{PROJECT_NAME}"	
	def exec
		sh "rm -rf #{PROJECT_PATH}"
		config = Toad::Config.new.open("./config/default/*")
		Toad::Config.set_instance(config)
		@r = Toad::Project.open(config, PACKAGE_NAME, PROJECT_PATH)
		assert(@r, "fail to create project")

		# file system check here
		assert(File.directory?("#{PROJECT_PATH}"), "#{PROJECT_PATH} should exist")
		assert(@r.path == "#{PROJECT_PATH}", "project path attr not correct [#{@r.path}]")
		
		# setting file check
		setting_file = "#{PROJECT_PATH}/config/project"
		assert(File.exists?(setting_file), "#{setting_file} not exist")
		assert(config.project.pkgname == PACKAGE_NAME, "#{config.project.pkgname} and #{PACKAGE_NAME} should be same")
		rev = (`git show -s --format=%H`).chop
		assert(config.project.toad_version == rev, "#{config.project.toad_version} and #{rev} should be same")
		@r.add_setting({:instance_id => 'i-abcdefgh'})
		assert(config.project.instance_id == 'i-abcdefgh', 
			"cannot load correct value written in setting file [#{config.project.instance_id}]")

		
		# android config file check
		global = "#{PROJECT_PATH}/client/android/settings-global.sh"
		local = "#{PROJECT_PATH}/client/android/settings-local.sh"
		assert(File.exists?(global), "global config missing at #{global}")
		assert(File.exists?(local), "local config missing at #{local}")
		res = find_in_file(global, "project_name=\"(.*)\"")
		assert((res and res[1] == "test"), "global config not correctly configured")
		res = find_in_file(global, "app_name=\"(.*)\"")
		assert((res and res[1] == 'test'), "global config not correctly configured")
		res = find_in_file(local, "android_sdk_root=\"(.*)\"")
		assert((res and res[1] == File.dirname(File.dirname(`which adb`))), "local config not correctly configured")
		res = find_in_file(local, "src_dirs=(.*)")
		assert((res and res[1] == "(\"../../src/client/\")"), "local config not correctly configured")
		
		# src dir check
		["src", "src/client", "src/server", "src/share", "src/client/share", "src/server/share",
		 "src/client/config", "src/server/config"].each do |path|
			assert(File.exists?("#{PROJECT_PATH}/#{path}"), "path not exist #{path}")
		end

		rr = Toad::Project.open(config, PACKAGE_NAME, "toad_adventure")
		assert((rr and @r.path == rr.path), "reload project fails")
	end
end

t = TestProject.new
t.exec
t.cleanup
