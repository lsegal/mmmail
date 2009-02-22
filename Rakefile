require 'rubygems'
require 'rake/gempackagetask'

begin
require 'spec'
require 'spec/rake/spectask'
rescue LoadError; end

begin
require 'yard'
rescue LoadError; end
 
WINDOWS = (PLATFORM =~ /win32|cygwin/ ? true : false) rescue false
SUDO = WINDOWS ? '' : 'sudo'
 
task :default => :specs
 
load 'mmmail.gemspec'
Rake::GemPackageTask.new(SPEC) do |pkg|
  pkg.gem_spec = SPEC
  pkg.need_zip = true
  pkg.need_tar = true
end
 
desc "Install the gem locally"
task :install => :package do
  sh "#{SUDO} gem install pkg/#{SPEC.name}-#{SPEC.version}.gem --local"
  sh "#{SUDO} rm -rf pkg/#{SPEC.name}-#{SPEC.version}" unless ENV['KEEP_FILES']
end
 
begin 
desc "Run all specs"
Spec::Rake::SpecTask.new("specs") do |t|
  $DEBUG = true if ENV['DEBUG']
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.spec_files = Dir["spec/**/*_spec.rb"].sort
end
rescue LoadError; end
 
begin
YARD::Rake::YardocTask.new
rescue LoadError; end