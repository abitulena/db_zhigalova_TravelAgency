INSERT INTO clients (email, full_name)
SELECT 'client' || g || '@example.com', 'Клиент ' || g
FROM generate_series(1, 2000) g;

INSERT INTO bookings (client_id, tour_id, seats, created_at)
SELECT
    (SELECT id FROM clients ORDER BY random() LIMIT 1),
    (SELECT id FROM tours   ORDER BY random() LIMIT 1),
    1 + (random() * 3)::int,
    now() - (random() * interval '365 days')
FROM generate_series(1, 2000);