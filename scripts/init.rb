require './scripts/setup.rb'

if ARGV.length < 1 or ARGV[0] == 'help' then
	log "toad init (package name) [project directory name]"
	exit
end

if true then

project = Toad::Project.open(CONFIG, ARGV[0], ARGV[1])

else

pkgname = ARGV[0]
arch = (CONFIG.android.arch or 'armeabi')
ndk = (CONFIG.android.ndk or 'android-10')
destdir = ARGV.length > 1 ? ARGV[1] : pkgname
sdkdir = File.dirname(File.dirname `which adb`)
appname = pkgname.split('.').last
skelton = "./scripts/skel/scafold"
deploy_tmpl = "./scripts/skel/deploy/"


log "init module dependency"
sh "git submodule update --init --recursive"

log "init server"
sh "ruby ./scripts/subcommands/init_server.rb"
	
log "init android client"
android_d = destdir + "/client/android"
Dir.chdir("#{CONFIG.path.client_sdk}/ant") do |path|
	sh "bash ./make-host.sh -p #{pkgname} -a #{arch} -l #{ndk}"
end

log "init ios client"

log "create directory"
sh "mkdir -p ./#{destdir}/client/"
sh "mkdir -p ./#{destdir}/server/"
sh "mkdir -p ./#{destdir}/src/"

log "copy files"
sh "mv #{CONFIG.path.client_sdk}/ant/untitled-host ./#{destdir}/client/android"
sh "cp -rv #{skelton}/* ./#{destdir}/src/"
sh "cp -rv #{deploy_tmpl} ./#{destdir}/server/"

log "auto configuration in progress"
replace_file android_d + "/settings-global.sh", "untitled", "#{appname}"
# sdkdir contains /, so use | for sed command seperator.
replace_file android_d + "/settings-local.sh", "android_sdk_root=\"\"", "android_sdk_root=\"#{sdkdir}\"", "|"
replace_file android_d + "/settings-local.sh", "src_dirs=(.*)", "src_dirs=(\"../../src/client/\")", "|"
Toad::Util::write_setting(destdir, pkgname, TOAD_VERSION)

log "done!!"

end
