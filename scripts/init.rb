require './scripts/config.rb'
require './scripts/common.rb'

if ARGV.length < 1 or ARGV[0] == 'help' then
	puts "toad init (package name) [project directory name]"
	exit
end

pkgname = ARGV[0]
arch = (CONFIG.android.arch or 'armeabi')
ndk = (CONFIG.android.ndk or 'android-10')
destdir = ARGV.length > 1 ? ARGV[1] : pkgname
sdkdir = File.dirname(File.dirname `which adb`)
appname = pkgname.split('.').last
skelton = "./scripts/skel/basic"


log "initialize module dependency"
sh "git submodule update --init --recursive"
	
log "init android client"
android_d = destdir + "/client/android"
Dir.chdir("#{CONFIG.path.client_sdk}/ant") do |path|
	sh "bash ./make-host.sh -p #{pkgname} -a #{arch} -l #{ndk}"
end

log "copy files and configure autometically"
sh "mkdir -p ./#{destdir}/client/"
sh "mkdir -p ./#{destdir}/src/"
sh "mv #{CONFIG.path.client_sdk}/ant/untitled-host ./#{destdir}/client/android"
sh "cp -rv #{skelton}/* ./#{destdir}/src/"
replace_file android_d + "/settings-global.sh", "untitled", "#{appname}"
# sdkdir contains /, so use | for sed command seperator.
replace_file android_d + "/settings-local.sh", "android_sdk_root=\"\"", "android_sdk_root=\"#{sdkdir}\"", "|"
replace_file android_d + "/settings-local.sh", "src_dirs=(.*)", "src_dirs=(\"../../src/client/\")", "|"

log "init ios client"
log "copy to dest"
# TODO : implement

log "init server"
log "copy to dest"
# TODO

