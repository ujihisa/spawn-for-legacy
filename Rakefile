require "rspec/core/rake_task"
require "rake/gempackagetask"

task :default => :spec

desc "Run all examples"
RSpec::Core::RakeTask.new(:spec) do |t|
	t.rspec_opts = %w[--color]
	t.verbose = false
end

desc "Create the .gem package"
$gemspec = eval("#{File.read('sfl.gemspec')}")
Rake::GemPackageTask.new($gemspec) do |pkg|
	pkg.need_tar = true
end
