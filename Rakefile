# frozen_string_literal: true

require 'riemann/tools/nut/version'

require 'bundler/gem_tasks'

require 'github_changelog_generator/task'

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.user = 'opus-codium'
  config.project = 'riemann-nut'
  config.exclude_labels = ['skip-changelog']
  config.future_release = Riemann::Tools::Nut::VERSION
  config.since_tag = 'v1.0.0'
end
