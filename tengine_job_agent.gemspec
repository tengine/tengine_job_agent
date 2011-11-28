# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "tengine_job_agent"
  s.version = "0.3.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["saishu", "w-irie", "taigou", "totty", "hiroshinakao", "g-morita", "guemon", "aoetk", "hattori-at-nt", "t-yamada", "y-karashima", "akm"]
  s.date = "2011-11-28"
  s.description = "tengine_job_agent works with tengine_job"
  s.email = "tengine@nautilus-technologies.com"
  s.executables = ["tengine_job_agent_kill", "tengine_job_agent_run", "tengine_job_agent_watchdog"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Gemfile",
    "Gemfile.lock",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "bin/tengine_job_agent_kill",
    "bin/tengine_job_agent_run",
    "bin/tengine_job_agent_watchdog",
    "lib/tengine_job_agent.rb",
    "lib/tengine_job_agent/command_utils.rb",
    "lib/tengine_job_agent/run.rb",
    "lib/tengine_job_agent/watchdog.rb",
    "spec/.gitignore",
    "spec/config/tengine_job_agent.yml.erb",
    "spec/log/.gitignore",
    "spec/spec_helper.rb",
    "spec/tengine_job_agent/command_utils_spec.rb",
    "spec/tengine_job_agent/run_spec.rb",
    "spec/tengine_job_agent/scripts/echo_foo.sh",
    "spec/tengine_job_agent/scripts/sleep.sh",
    "spec/tengine_job_agent/watchdog_spec.rb",
    "tengine_job_agent.gemspec"
  ]
  s.homepage = "http://github.com/tengine/tengine_job_agent"
  s.licenses = ["MPL/LGPL"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.11"
  s.summary = "tengine_job_agent invoke job, watches it and notify its finish to tengine server"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<tengine_support>, ["~> 0.3.0"])
      s.add_runtime_dependency(%q<tengine_event>, ["~> 0.3.3"])
      s.add_development_dependency(%q<rspec>, ["~> 2.6.0"])
      s.add_development_dependency(%q<yard>, ["~> 0.7.2"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.18"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.5.3"])
      s.add_development_dependency(%q<ZenTest>, ["~> 4.6.2"])
      s.add_development_dependency(%q<ci_reporter>, ["~> 1.6.5"])
    else
      s.add_dependency(%q<tengine_support>, ["~> 0.3.0"])
      s.add_dependency(%q<tengine_event>, ["~> 0.3.3"])
      s.add_dependency(%q<rspec>, ["~> 2.6.0"])
      s.add_dependency(%q<yard>, ["~> 0.7.2"])
      s.add_dependency(%q<bundler>, ["~> 1.0.18"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<simplecov>, ["~> 0.5.3"])
      s.add_dependency(%q<ZenTest>, ["~> 4.6.2"])
      s.add_dependency(%q<ci_reporter>, ["~> 1.6.5"])
    end
  else
    s.add_dependency(%q<tengine_support>, ["~> 0.3.0"])
    s.add_dependency(%q<tengine_event>, ["~> 0.3.3"])
    s.add_dependency(%q<rspec>, ["~> 2.6.0"])
    s.add_dependency(%q<yard>, ["~> 0.7.2"])
    s.add_dependency(%q<bundler>, ["~> 1.0.18"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<simplecov>, ["~> 0.5.3"])
    s.add_dependency(%q<ZenTest>, ["~> 4.6.2"])
    s.add_dependency(%q<ci_reporter>, ["~> 1.6.5"])
  end
end

