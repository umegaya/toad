category = (ARGV.length > 0 ? ARGV[0].to_sym : nil)
CHARGED_TEST = [:cloud, :operator]
Dir.glob("./test/modules/*.rb") do |file|
	name = File.basename(file, ".rb").to_sym
	charged = CHARGED_TEST.include? name
	if category then
		if category != :all then
			next if category != name
		end
	else
		next if charged 
	end
	p "running test #{file} (#{charged ? "charged" : "free"})"
	system("ruby #{file}")
	throw $? if $?.exitstatus != 0
end

