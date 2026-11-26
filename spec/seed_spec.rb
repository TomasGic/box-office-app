# frozen_string_literal: true

RSpec.describe 'db/seed.sql' do
  let(:db) { SQLite3::Database.new(':memory:') }

  before do
    db.execute('PRAGMA foreign_keys = ON;')
    db.execute_batch(File.read('db/schema.sql'))
    db.execute_batch(File.read('db/seed.sql'))
  end

  after do
    db&.close
  end

  it 'populates the seats table with 82 rows' do
    rows_count = db.get_first_value('SELECT COUNT(*) FROM seats')
    expect(rows_count).to eq(82)
  end

  it 'populates the event seats table with 246 rows' do
    rows_count = db.get_first_value('SELECT COUNT(*) FROM event_seats')
    expect(rows_count).to eq(246)
  end
end
