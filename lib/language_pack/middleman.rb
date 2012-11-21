require "language_pack"
require "language_pack/ruby"

# Middleman Language Pack. Use to generate a middleman site on heroku
# extending the rack languagepack as we'll use it to serve the built site
class LanguagePack::Middleman < LanguagePack::Ruby

  # detects if this is a Middleman app
  # @return [Boolean] true if it's a Middleman app
  def self.use?
    super && File.exist?("config.ru")
  end

  def name
    "Ruby/Rack"
  end

  def default_config_vars
    super.merge({
      "RACK_ENV" => "production"
    })
  end

  def default_process_types
    # let's special case thin here if we detect it
    web_process = gem_is_bundled?("thin") ?
                    "bundle exec thin start -R config.ru -e $RACK_ENV -p $PORT" :
                    "bundle exec rackup config.ru -p $PORT"

    super.merge({
      "web" => web_process
    })
  end

private

  # sets up the profile.d script for this buildpack
  def setup_profiled
    super
    set_env_default "RACK_ENV", "production"
  end

end