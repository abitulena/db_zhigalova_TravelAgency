-- 1. Триггер: Отзыв только после завершённого тура
CREATE FUNCTION check_review_date() RETURNS trigger 
LANGUAGE plpgsql AS $$
DECLARE
    v_ends_at timestamptz;
BEGIN
    SELECT ends_at INTO v_ends_at FROM tours WHERE id = NEW.tour_id;
    IF v_ends_at > now() THEN
        RAISE EXCEPTION 'Нельзя оставить отзыв. Тур закончится только %', v_ends_at::date;
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_check_review_date 
BEFORE INSERT OR UPDATE ON reviews
FOR EACH ROW EXECUTE FUNCTION check_review_date();

-- 2. Служебный триггер: автоматически обновляет updated_at
CREATE FUNCTION set_updated_at() RETURNS trigger 
LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END $$;

CREATE TRIGGER trg_tours_updated_at 
BEFORE UPDATE ON tours
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 3. Журнал изменений
CREATE TABLE tours_audit (
    id serial PRIMARY KEY,
    operation text NOT NULL,
    old_data jsonb,
    new_data jsonb,
    changed_by text,
    changed_at timestamptz DEFAULT clock_timestamp()
);

CREATE FUNCTION log_tour_changes() RETURNS trigger 
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO tours_audit (operation, new_data, changed_by)
        VALUES ('INSERT', to_jsonb(NEW), session_user);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO tours_audit (operation, old_data, new_data, changed_by)
        VALUES ('UPDATE', to_jsonb(OLD), to_jsonb(NEW), session_user);
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO tours_audit (operation, old_data, changed_by)
        VALUES ('DELETE', to_jsonb(OLD), session_user);
    END IF;
    RETURN COALESCE(NEW, OLD);
END $$;

CREATE TRIGGER trg_tours_audit
AFTER INSERT OR UPDATE OR DELETE ON tours
FOR EACH ROW EXECUTE FUNCTION log_tour_changes();

CREATE FUNCTION tour_state_at(p_tour_id integer, p_time timestamptz)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_state jsonb;
BEGIN
    SELECT new_data INTO v_state
    FROM tours_audit
    WHERE (new_data->>'id')::int = p_tour_id 
      AND changed_at <= p_time
      AND new_data IS NOT NULL
    ORDER BY changed_at DESC
    LIMIT 1;

    IF v_state IS NULL THEN
        RETURN '{"status": "not_exists"}'::jsonb;
    END IF;

    RETURN v_state;
END;
$$;