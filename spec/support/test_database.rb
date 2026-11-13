# frozen_string_literal: true

require 'sqlite3'

class TestDatabase
  class << self
    attr_reader :connection
  end

  def self.connect
    @connection = SQLite3::Database.new(':memory:')
  end

  def self.load_schema
    @connection.execute_batch(File.read('db/schema.sql'))
    @connection.execute('PRAGMA foreign_keys = ON;')
  end

  def self.setup
    connect
    load_schema
  end
end
