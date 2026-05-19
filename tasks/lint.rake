namespace :lint do
  desc "Run RuboCop"
  task :ruby do
    sh "bundle exec rubocop"
  end

  desc "Ruby Biome"
  task :js do
    sh "npx --yes @biomejs/biome format"
    sh "npx --yes @biomejs/biome lint"
  end
end
