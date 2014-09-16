require 'bundler'
Bundler::GemHelper.install_tasks


# See https://github.com/colszowka/simplecov/issues/171
desc "Set permissions on all files so they are compatible with both user-local and system-wide installs"
task :fix_permissions do
  system 'bash -c "find . -type f -exec chmod 644 {} \; && find . -type d -exec chmod 755 {} \;"'
end
# Enforce proper permissions on each build
Rake::Task[:build].prerequisites.unshift :fix_permissions

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test' << 'test/lib'
#  test.pattern = [ 'test/*_test.rb', 'spec/*_spec.rb']
  test.test_files = FileList['spec/*_spec.rb', 'test/*_test.rb']
  test.verbose = true
  test.warning = true
end

task :default => :test

namespace :assets do
  desc "Compiles all assets"
  task :compile do
    puts "Compiling assets"
    require 'sprockets'
    assets = Sprockets::Environment.new
    assets.append_path 'assets/javascripts'
    assets.append_path 'assets/stylesheets'
    assets['application.js'].write_to('public/application.js')
    assets['application.css'].write_to('public/application.css')
  end
end

begin
  require 'yard'
  require 'yard-minitest-spec'
rescue LoadError => x
  puts x
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.options += ['--title', "simplecov-simple-html #{ SimpleCov::Formatter::SimpleHTMLFormatter::VERSION } Documentation"]
  end
rescue LoadError
end
