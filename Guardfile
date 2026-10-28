guard :rspec, cmd: 'bundle exec rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^app/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/views/movies/}) { 'spec/requests/tmdb_search_spec.rb' }
  watch('config/routes.rb') { 'spec/requests/tmdb_search_spec.rb' }
  watch('spec/spec_helper.rb') { 'spec' }
  watch('spec/rails_helper.rb') { 'spec' }
end
