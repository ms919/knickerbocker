# frozen_string_literal: true

require_relative "lib/nicker_pocker/version"

Gem::Specification.new do |spec|
  spec.name = "nicker_pocker"
  spec.version = NickerPocker::VERSION
  spec.authors = ["ms919"]
  spec.email = ["koushien.gem@gmail.com"]

  spec.summary = "Provides commands to create table definitions"
  spec.homepage = "https://github.com/ms919/nicker_pocker"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.3.7"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ms919/nicker_pocker"
  spec.metadata["changelog_uri"] = "https://github.com/ms919/nicker_pocker/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
