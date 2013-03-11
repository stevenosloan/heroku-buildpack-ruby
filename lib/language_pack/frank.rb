require "language_pack"
require "language_pack/rack"

# Frank Language Pack. Use to generate a frank site on heroku
# extending the rack languagepack as we'll use it to serve the built site
class LanguagePack::Frank < LanguagePack::Rack

  def initialize(build_path, cache_path=nil)
    super
    @buildpack_path = build_path.gsub( 'build_', 'buildpack_' )
  end

  # detects if this is a Frank app
  # @return [Boolean] true if it's a Frank app
  def self.use?
    File.exist?("setup.rb") && File.directory?('dynamic')
  end

  def name
    "Ruby/Frank"
  end

  def compile
    super
    allow_git do
      run_php_compilation
      run_frank_build_process
    end
  end

  # collection of values passed for a release
  # @return [String] in YAML format of the result
  def release
    setup_language_pack_environment

    {
      "addons" => default_addons,
      "config_vars" => default_config_vars,
      "default_process_types" => default_process_types
    }.to_yaml
  end

  def default_process_types
    super.merge({
      "web" => "sh boot.sh"
    })
  end

private

  # check if a frank:build rake task exists
  # or run the default frank build
  def run_frank_build_process

    if rake_task_defined?("frank:build")
      task = "rake frank:build"
    else
      puts "no frank:build task detected"
      task = "bundle exec frank export --production build"
    end

    require 'benchmark'

    topic "Running: #{task}"
    time = Benchmark.realtime { pipe("env PATH=$PATH:bin bundle exec #{task} 2>&1") }
    if $?.success?
      puts "frank:build process completed (#{"%.2f" % time}s)"
    else
      puts "frank:build process failed"
    end

  end

  def run_php_compilation

    topic "Bundling Apache & PHP"
    pipe("chmod +x #{@buildpack_path}/lib/apache_and_php 2>&1")
    pipe("#{@buildpack_path}/lib/apache_and_php #{@build_path} #{@cache_path} 2>&1")\

  end

end