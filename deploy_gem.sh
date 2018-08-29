bump patch --no-commit
gem build peatio.gemspec
gem push peatio-$(bump current) -K $API_KEY