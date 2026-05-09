CREATE PROCEDURE perseus.getmaterialbyrunproperties(IN _runid character varying, IN _hourtimepoint numeric, INOUT return_value integer)
    LANGUAGE plpgsql
    AS $$
  DECLARE
    _creatorid INTEGER;
    _secondtimepoint INTEGER;
    _originalgoo VARCHAR(50);
    _starttime TIMESTAMP;
    _timepointgoo VARCHAR(50);
    _maxgooidentifier INTEGER;
    _maxfsidentifier INTEGER;
    _split VARCHAR(50);
  BEGIN
    _secondtimepoint := _hourtimepoint * 60 * 60;

    SELECT
        g.added_by,
        g.uid,
        r.start_time
      INTO
        _creatorid, _originalgoo, _starttime
      FROM
        hermes.run AS r
        JOIN perseus.goo AS g ON g.uid = r.resultant_material
      WHERE r.experiment_id::TEXT || '-' || r.local_id::TEXT = _runid;

    IF _originalgoo IS NOT NULL THEN
      SELECT
          replace(g.uid, 'm', '')
        INTO
          _timepointgoo
        FROM
          perseus.mcgetdownstream(_originalgoo) AS d
          JOIN perseus.goo AS g ON d.end_point = g.uid
        WHERE g.added_on = _starttime + (_secondtimepoint * interval '1 second')
         AND g.goo_type_id = 9;

      IF _timepointgoo IS NULL THEN
        SELECT
            COALESCE(max(CAST(substr(uid, 2, 100) AS INTEGER)), 0) + 1
          INTO
            _maxgooidentifier
          FROM
            perseus.goo
          WHERE uid LIKE 'm%';

        SELECT
            COALESCE(max(CAST(substr(uid, 2, 100) AS INTEGER)), 0) + 1
          INTO
            _maxfsidentifier
          FROM
            perseus.fatsmurf
          WHERE uid LIKE 's%';

        _timepointgoo := 'm' || _maxgooidentifier;
        _split := 's' || _maxfsidentifier;

        INSERT INTO perseus.goo (uid, name, original_volume, added_on, added_by, goo_type_id)
          VALUES (_timepointgoo, 'Sample TP: ' || _hourtimepoint, 0.00001, _starttime + (_secondtimepoint * interval '1 second'), _creatorid, 9);

        INSERT INTO perseus.fatsmurf (uid, added_on, added_by, smurf_id, run_on)
          VALUES (_split, localtimestamp, _creatorid, 110, _starttime + (_secondtimepoint * interval '1 second'));

        CALL perseus.materialtotransition(_originalgoo, _split);
        CALL perseus.transitiontomaterial(_split, _timepointgoo);
      END IF;
    END IF;

    return_value := CAST(replace(_timepointgoo, 'm', '') AS INTEGER);
    RETURN;
  END;
  $$;


ALTER PROCEDURE perseus.getmaterialbyrunproperties(IN _runid character varying, IN _hourtimepoint numeric, INOUT return_value integer) OWNER TO perseus_owner;

