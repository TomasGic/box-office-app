# frozen_string_literal: true

RSpec.describe 'db/schema.sql' do
  include_context 'with a schema database'
  # Venues
  describe 'venues' do
    it 'rejects a venue name that is NULL' do
      expect do
        db.execute('INSERT INTO venues (name) VALUES (NULL);')
      end.to raise_error(SQLite3::ConstraintException, /NOT NULL constraint failed/)
    end
  end

  describe 'sections' do
    it 'rejects a price that is negative' do
      insert_venue('Melkweg')

      expect do
        db.execute(
          'INSERT INTO sections (venue_id, name, price_cents) VALUES (1, "Balcony", -10);'
        )
      end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed: price_cents > 0/)
    end
  end

  describe 'seats' do
    it 'rejects two identical combinations of seat_number and row_label within one section' do
      insert_venue('Melkweg')
      insert_section(name: 'Balcony', venue: 'Melkweg')
      insert_seat(section: 'Balcony', row_label: 'A', number: 25)

      # Inserting the same seat inside the same section again will raise error
      expect do
        insert_seat(section: 'Balcony', row_label: 'A', number: 25)
      end.to raise_error(SQLite3::ConstraintException, /UNIQUE constraint failed/)
    end
  end

  describe 'events' do
    it 'rejects an event with non-existent venue_id' do
      query = "INSERT INTO events (name, starts_at, venue_id)
              VALUES ('Gojira World Tour 2027','2027-06-01 20:00:00', 9999)"
      expect do
        db.execute(query)
      end.to raise_error(SQLite3::ConstraintException, /FOREIGN KEY constraint failed/)
    end
  end

  context 'when examples require venues, sections, events and seats to contain some data' do
    before do
      insert_venue('Melkweg')
      insert_section(name: 'Balcony', venue: 'Melkweg')
      insert_event(name: 'Gojira World Tour 2027', venue: 'Melkweg')
      insert_seat(section: 'Balcony', row_label: 'A', number: 25)
    end

    describe 'event seats' do
      it 'rejects identical seat ids for the same event' do
        insert_event_seat(event: 'Gojira World Tour 2027', row_label: 'A', seat_number: 25)

        # we expect adding the same seat for the same event will raise error
        expect do
          insert_event_seat(event: 'Gojira World Tour 2027', row_label: 'A', seat_number: 25)
        end.to raise_error(SQLite3::ConstraintException, /UNIQUE constraint failed/)
      end
    end

    it 'enforces that event_seat with held status have a hold_token and held_until' do
      # Statement inserting a new held seat for a particular event without hold_token
      # and without held_until
      query = "INSERT INTO event_seats (event_id, seat_id, status) VALUES (
                  (SELECT id FROM events WHERE name = 'Gojira World Tour 2027'),
                  (SELECT id FROM seats WHERE row_label = 'A' AND seat_number = 25),
                  'held'
              )"

      # Inserting a seat with 'held' status and without hold_token and held_until will raise error
      expect do
        db.execute(query)
      end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
    end

    it 'enforces that event seat with available status and a hold_token is rejected' do
      # query inserting a new available seat with a hold_token
      query = "INSERT INTO event_seats (event_id, seat_id, status, hold_token) VALUES (
                  (SELECT id FROM events WHERE name = 'Gojira World Tour 2027'),
                  (SELECT id FROM seats WHERE row_label = 'A' AND seat_number = 25),
                  'available',
                  'xxxxxxxxxxxxxxxxxxxxxxxxx'
              )"
      expect do
        db.execute(query)
      end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
    end

    it 'rejects an event seat with an invalid status' do
      expect do
        insert_event_seat(event: 'Gojira World Tour 2027', row_label: 'A', seat_number: 25, status: 'invalid')
      end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
    end
  end

  describe 'promo codes' do
    it 'rejects the same promo code inserted twice' do
      query = "INSERT INTO promo_codes(code, percent_off) VALUES ('123456abcdef', 50);"

      db.execute(query)

      expect do
        db.execute(query)
      end.to raise_error(SQLite3::ConstraintException, /UNIQUE constraint failed/)
    end
  end

  it 'rejects percent_off value of 0' do
    query = "INSERT INTO promo_codes(code, percent_off) VALUES ('123456abcdef', 0);"

    expect do
      db.execute(query)
    end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
  end

  it 'rejects percent_off value of 101' do
    query = "INSERT INTO promo_codes(code, percent_off) VALUES ('123456abcdef', 101);"

    expect do
      db.execute(query)
    end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
  end

  it 'accepts percent_off value of 100' do
    query = "INSERT INTO promo_codes(code, percent_off) VALUES ('123456abcdef', 100);"

    expect do
      db.execute(query)
    end.not_to raise_error
  end

  describe 'orders' do
    it 'rejects an order with negative total_cents' do
      expect do
        insert_order(buyer_email: 'tomas.gic@example.com', price: -4500, transaction_id: '123456abdefg')
      end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
    end
  end

  it 'accepts an order with total_cents of 0' do
    expect do
      insert_order(buyer_email: 'tomas.gic@example.com', price: 0, transaction_id: '123456abdefg')
    end.not_to raise_error
  end

  describe 'order items' do
    it 'rejects the same event_seat_id for two different orders' do
      insert_venue('Melkweg')
      insert_section(name: 'Balcony', venue: 'Melkweg')
      insert_event(name: 'Gojira World Tour 2027', venue: 'Melkweg')
      insert_seat(section: 'Balcony', row_label: 'A', number: 25)
      insert_event_seat(event: 'Gojira World Tour 2027', row_label: 'A', seat_number: 25)
      insert_order(buyer_email: 'tomas.gic@example.com', price: 4500, transaction_id: '1234abcd')
      insert_order(buyer_email: 'lukas.rohac@example.com', price: 4500, transaction_id: '9876xyzt')

      insert_order_item(buyer_email: 'tomas.gic@example.com', event: 'Gojira World Tour 2027', price_cents: 4500)

      expect do
        insert_order_item(buyer_email: 'lukas.rohac@example.com', event: 'Gojira World Tour 2027', price_cents: 4500)
      end.to raise_error(SQLite3::ConstraintException, /UNIQUE constraint failed/)
    end
  end
end
