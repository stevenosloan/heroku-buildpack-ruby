require "language_pack"
require "language_pack/rack"

# Middleman Language Pack. Use to generate a middleman site on heroku
# extending the rack languagepack as we'll use it to serve the built site
class LanguagePack::Middleman < LanguagePack::Rack

  # detects if this is a Middleman app
  # @return [Boolean] true if it's a Middleman app
  def self.use?
    File.exist?("config.rb") && File.directory?('source')
  end

  def name
    "Ruby/Middleman"
  end

  def compile
    super
    allow_git do
      run_middleman_build_process
      run_php_compilation
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
  
  # check if a middleman:build rake task exists
  # or run the default middleman build
  def run_middleman_build_process

    if rake_task_defined?("middleman:build")
      task = "rake middleman:build"
    else
      puts "no middleman:build task detected"
      task = "middleman build --clean"
    end

    require 'benchmark'

    topic "Running: #{task}"
    time = Benchmark.realtime { pipe("env PATH=$PATH:bin bundle exec #{task} 2>&1") }
    if $?.success?
      puts "middleman:build process completed (#{"%.2f" % time}s)"
    else
      puts "middleman:build process failed"
    end

  end

  def run_php_compilation

    BUILDPACK_PATH = @build_path.gsub( 'build_', 'buildpack_' )

    pipe("echo $PATH 2>&1")
    pipe("cd #{BUILDPACK_PATH}; ls;")
    pipe("#{BUILDPACK_PATH}/lib/apache_and_php 2>&1")

  end

end