-- Лаба 4. Row Level Security: клиент видит только свои брони

ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY bookings_own_rows ON bookings
    FOR SELECT
    USING (client_id = current_setting('app.client_id', true)::int);