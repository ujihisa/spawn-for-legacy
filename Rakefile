require 'spec/rake/spectask'
require "rake/gempackagetask"

task :default => :spec

desc "Run specs"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList['spec/*_spec.rb']
end

desc "Create the .gem package"
$gemspec = eval("#{File.read('sfl.gemspec')}")
Rake::GemPackageTask.new($gemspec) do |pkg|
	pkg.need_tar = true
end
