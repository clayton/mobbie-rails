# frozen_string_literal: true

require_relative "lib/mobbie/rails/version"

Gem::Specification.new do |spec|
  spec.name = "mobbie-rails"
  spec.version = Mobbie::Rails::VERSION
  spec.authors = ["Clayton Lengel-Zigich"]
  spec.email = ["6334+clayton@users.noreply.github.com"]

  spec.summary = "Rails engine providing backend support for Mobbie iOS framework"
  spec.description = "A mountable Rails engine that provides all the backend APIs, models, and controllers needed to support the Mobbie iOS framework including authentication, paywalls, and support tickets."
  spec.homepage = "https://github.com/clayton/mobbie-rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Rails engine dependencies
  spec.add_dependency "rails", ">= 7.1", "< 9"
  spec.add_dependency "jwt", "~> 2.7"
  spec.add_dependency "bcrypt", "~> 3.1"
  
  # Development dependencies
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "factory_bot_rails", "~> 6.2"
  spec.add_development_dependency "sqlite3", "~> 1.4"
end
