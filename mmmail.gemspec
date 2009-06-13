SPEC = Gem::Specification.new do |s|
  s.name = "mmmail"
  s.version = "1.0.0"
  s.date = "2009-02-22"
  s.author = "Loren Segal"
  s.email = "lsegal@soen.ca"
  s.homepage = "http://github.com/lsegal/mmmail"
  s.platform = Gem::Platform::RUBY
  s.summary = "Mmmm, a Minimalist mail library for Ruby. Works with SMTP or sendmail."
  s.files = Dir.glob("{lib,spec}/**/*") + ['LICENSE', 'README.markdown', 'Rakefile']
  s.require_paths = ['lib']
  s.rubyforge_project = 'mmmail'
  s.has_rdoc = 'yard'
end