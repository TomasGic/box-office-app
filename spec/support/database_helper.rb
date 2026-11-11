# frozen_string_literal: true

require 'sqlite3'

class TestDatabase
  class << self
    attr_reader :connection
  end

  def self.setup
    @connection = SQLite3::Database.new(':memory:')
    @connection.execute_batch(File.read('db/schema.sql'))
  end
end
