# frozen_string_literal: true

RSpec.describe TestDatabase do
  def insert_venue(name = 'Melkweg')
    described_class.connection.execute("INSERT INTO venues (name) VALUES ('#{name}');")
  end

  def insert_section(name = 'Balcony')
    described_class.connection.execute(
      "INSERT INTO sections (venue_id, name, price_cents) VALUES (
        (SELECT id FROM venues WHERE name = 'Melkweg'), '#{name}', 4500
      );"
    )
  end
  # Venues
  it 'enforces that venue name cannot be NULL' do
    expect do
      described_class.connection.execute('INSERT INTO venues (name) VALUES (NULL);')
    end.to raise_error(SQLite3::ConstraintException)
  end

  # Sections
  it 'enforces that price_cents cannot be less then 0' do
    insert_venue

    expect do
      described_class.connection.execute(
        'INSERT INTO sections (venue_id, name, price_cents) VALUES (1, "Balcony", -10);'
      )
    end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
  end

  # Seats
  it 'enforces unique combination of seat_number and row_label within one section' do
    insert_venue
    insert_section

    query = "INSERT INTO seats (section_id, row_label, seat_number) VALUES (
              (SELECT id FROM sections WHERE name = 'Balcony'), 'A', 25
            );"
    described_class.connection.execute(query)

    expect do
      described_class.connection.execute(query)
    end.to raise_error(SQLite3::ConstraintException, /UNIQUE constraint failed/)
  end
end
