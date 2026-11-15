# frozen_string_literal: true

require 'sqlite3'

RSpec.shared_context 'with a schema database' do
  let(:db) do
    SQLite3::Database.new(':memory:').tap do |database|
      database.execute_batch(File.read('db/schema.sql'))
    end
  end

  def insert_venue(name)
    db.execute("INSERT INTO venues (name) VALUES ('#{name}');")
  end

  def insert_section(name:, venue:)
    db.execute(
      "INSERT INTO sections (venue_id, name, price_cents) VALUES (
        (SELECT id FROM venues WHERE name = '#{venue}'), '#{name}', 4500
      );"
    )
  end

  def insert_event(venue:, name:, start_time: '2027-06-01 20:00:00')
    db.execute(
      "INSERT INTO events (name, starts_at, venue_id) VALUES (?,
        ?,
        (SELECT id FROM venues WHERE name = ?)
      );",
      [name, start_time, venue]
    )
  end

  def insert_seat(section:, row_label:, number:)
    db.execute(
      "INSERT INTO seats (section_id, row_label, seat_number) VALUES (
              (SELECT id FROM sections WHERE name = '#{section}'),
              '#{row_label}',
              #{number}
            );"
    )
  end

  def insert_event_seat(event:, row_label:, seat_number:, status: 'available')
    query = "INSERT INTO event_seats (event_id, seat_id, status) VALUES (
                  (SELECT id FROM events WHERE name = '#{event}'),
                  (SELECT id FROM seats WHERE row_label = '#{row_label}' AND seat_number = #{seat_number}),
                  '#{status}'
              )"
    db.execute(query)
  end

  def insert_promo_code(percent_off:, code: '123456abcdef')
    db.execute("INSERT INTO promo_codes (code, percent_off)
              VALUES (?, ?);", [code, percent_off])
  end

  def insert_order(buyer_email:, price:, transaction_id:)
    db.execute(
      "INSERT INTO orders (buyer_email, total_cents, gateway, transaction_id) VALUES (?, ?, 'paypal', ?);",
      [buyer_email, price, transaction_id]
    )
  end

  def insert_order_item(buyer_email:, event:, price_cents:)
    query = "INSERT INTO order_items (order_id, event_seat_id, price_cents)
                VALUES (
                (SELECT id FROM orders WHERE buyer_email = '#{buyer_email}'),
                  (SELECT id FROM event_seats where event_id = (SELECT id FROM events WHERE name = '#{event}')),
                #{price_cents}
              );"

    db.execute(query)
  end
end
