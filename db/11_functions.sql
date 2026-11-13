-- 1. Функция: возвращает количество свободных мест на туре
CREATE FUNCTION free_seats(p_tour_id integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_booked integer;
    v_limit integer := 10;
BEGIN
    SELECT coalesce(sum(seats), 0) INTO v_booked FROM bookings WHERE tour_id = p_tour_id;
    RETURN v_limit - v_booked;
END;
$$;

-- 2. Бизнес-операция: Забронировать тур
CREATE FUNCTION book_tour(p_client_id integer, p_tour_id integer, p_seats integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_booking_id integer;
    v_free integer;
BEGIN
    v_free := free_seats(p_tour_id);
    
    IF v_free < p_seats THEN
        RAISE EXCEPTION 'Недостаточно мест. Свободно: %, запрошено: %', v_free, p_seats;
    END IF;

    INSERT INTO bookings (client_id, tour_id, seats)
    VALUES (p_client_id, p_tour_id, p_seats)
    RETURNING id INTO v_booking_id;

    RETURN v_booking_id;
END;
$$;

CREATE FUNCTION search_tours(p_country text DEFAULT NULL, p_min_price numeric DEFAULT NULL)
RETURNS TABLE (
    tour_id integer, 
    title text, 
    country text, 
    price numeric
)
LANGUAGE sql
AS $$
    SELECT t.id, t.title, c.name, t.price
    FROM tours t
    JOIN hotels h ON h.id = t.hotel_id
    JOIN countries c ON c.id = h.country_id
    WHERE (p_country IS NULL OR c.name = p_country)
      AND (p_min_price IS NULL OR t.price >= p_min_price);
$$;