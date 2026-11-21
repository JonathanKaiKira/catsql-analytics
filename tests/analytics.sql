DO $$
BEGIN
    IF current_setting('server_version_num')::int NOT BETWEEN 170000 AND 179999 THEN
        RAISE EXCEPTION 'Expected PostgreSQL 17';
    END IF;
    IF (SELECT ARRAY_AGG(tablename::text ORDER BY tablename::text) FROM pg_tables WHERE schemaname = 'catdb')
      IS DISTINCT FROM ARRAY['activities','caregivers','cat_caregivers','cats','expenses','feedings','foods','medications','treatments','vaccinations','vaccines','vet_visits','weights']::text[] THEN
        RAISE EXCEPTION 'Unexpected CatDB base tables';
    END IF;
    IF (SELECT COUNT(*) FROM catdb.cats) <> 4 OR
       (SELECT COUNT(*) FROM catdb.cats WHERE birth_date IS NULL) <> 1 THEN
        RAISE EXCEPTION 'Unexpected base data';
    END IF;
    IF (SELECT total_clp FROM analytics.expenses_by_cat WHERE cat_code = 'LUNA') IS DISTINCT FROM 47000::bigint OR
       (SELECT total_clp FROM analytics.expenses_by_cat WHERE cat_code = 'PIPA') IS DISTINCT FROM 0::bigint THEN
        RAISE EXCEPTION 'Unexpected spending by cat';
    END IF;
    IF (SELECT total_clp FROM analytics.expenses_monthly WHERE month = DATE '2030-05-01') IS DISTINCT FROM 70000::bigint THEN
        RAISE EXCEPTION 'Unexpected monthly spending';
    END IF;
    IF (SELECT delta_grams FROM analytics.weight_history WHERE cat_code = 'LUNA' AND measured_on = DATE '2030-05-01') IS DISTINCT FROM -50 OR
       (SELECT COUNT(*) FROM analytics.weight_history WHERE delta_grams IS NULL) <> 3 THEN
        RAISE EXCEPTION 'Unexpected weight history';
    END IF;
    IF (SELECT activity_type FROM analytics.latest_activity WHERE cat_code = 'LUNA') IS DISTINCT FROM 'play' OR
       EXISTS (SELECT FROM analytics.latest_activity WHERE cat_code = 'PIPA') THEN
        RAISE EXCEPTION 'Unexpected latest activities';
    END IF;
END
$$;
