require 'rails_helper'
require 'open3'

RSpec.describe 'CreateMovies migration' do
  it 'creates a fresh table and preserves rows when the table already exists' do
    script = <<~RUBY
      require 'active_record'
      require #{Rails.root.join('db/migrate/20250702121840_create_movies.rb').to_s.inspect}
      ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
      ActiveRecord::Migration.verbose = false

      CreateMovies.new.migrate(:up)
      connection = ActiveRecord::Base.connection
      raise 'Missing movies table' unless connection.table_exists?(:movies)
      required = %w[title rating description release_date created_at updated_at]
      raise 'Missing columns' unless (required - connection.columns(:movies).map(&:name)).empty?

      connection.execute("INSERT INTO movies (title, rating, created_at, updated_at) VALUES ('Existing movie', 'R', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
      CreateMovies.new.migrate(:up)
      raise 'Existing row was changed' unless connection.select_value('SELECT title FROM movies') == 'Existing movie'
      raise 'Unexpected row count' unless connection.select_value('SELECT COUNT(*) FROM movies') == 1
    RUBY

    stdout, stderr, status = Open3.capture3(RbConfig.ruby, '-e', script)
    expect(status.success?).to be(true), "#{stdout}\n#{stderr}"
  end
end
