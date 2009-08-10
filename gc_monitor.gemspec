# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{gc_monitor}
  s.version = "0.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mitsunori Komatsu"]
  s.date = %q{2009-08-11}
  s.email = ["komamitsu@gmail.com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt"]
  s.files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "LICENSE", "Rakefile", "lib/gc_monitor.rb", "script/console", "script/destroy", "script/generate", "test/test_gc_monitor.rb", "test/test_helper.rb"]
  s.has_rdoc = true
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{gc_monitor}
  s.rubygems_version = %q{1.3.1}
  s.summary = "GcMonitor is Ruby library for monitoring GC."
  s.test_files = ["test/test_helper.rb", "test/test_gc_monitor.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 2.3.3"])
    else
      s.add_dependency(%q<hoe>, [">= 2.3.3"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 2.3.3"])
  end
end
