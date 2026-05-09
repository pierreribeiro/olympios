CREATE FUNCTION perseus.fn_diagramobjects() RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
      _id_upgraddiagrams INTEGER;
      _id_sysdiagrams INTEGER;
      _id_helpdiagrams INTEGER;
      _id_helpdiagramdefinition INTEGER;
      _id_creatediagram INTEGER;
      _id_renamediagram INTEGER;
      _id_alterdiagram INTEGER;
      _id_dropdiagram INTEGER;
      _installedobjects INTEGER;
    BEGIN
      SELECT
          coalesce(0, _installedobjects)
        INTO
          _installedobjects
        LIMIT 1
      ;
      SELECT
          coalesce(to_regclass('dbo.sp_upgraddiagrams')::oid, _id_upgraddiagrams),
          coalesce(to_regclass('dbo.sysdiagrams')::oid, _id_sysdiagrams),
          coalesce(to_regclass('dbo.sp_helpdiagrams')::oid, _id_helpdiagrams),
          coalesce(to_regclass('dbo.sp_helpdiagramdefinition')::oid, _id_helpdiagramdefinition),
          coalesce(to_regclass('dbo.sp_creatediagram')::oid, _id_creatediagram),
          coalesce(to_regclass('dbo.sp_renamediagram')::oid, _id_renamediagram),
          coalesce(to_regclass('dbo.sp_alterdiagram')::oid, _id_alterdiagram),
          coalesce(to_regclass('dbo.sp_dropdiagram')::oid, _id_dropdiagram)
        INTO
          _id_upgraddiagrams, _id_sysdiagrams, _id_helpdiagrams, _id_helpdiagramdefinition, _id_creatediagram, _id_renamediagram, _id_alterdiagram, _id_dropdiagram
        LIMIT 1
      ;
      IF _id_upgraddiagrams IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 1, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      IF _id_sysdiagrams IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 2, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      IF _id_helpdiagrams IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 4, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      IF _id_helpdiagramdefinition IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 8, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      IF _id_creatediagram IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 16, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      IF _id_renamediagram IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 32, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      IF _id_alterdiagram IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 64, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      IF _id_dropdiagram IS NOT NULL THEN
        SELECT
            coalesce(_installedobjects + 128, _installedobjects)
          INTO
            _installedobjects
          LIMIT 1
        ;
      END IF;
      RETURN _installedobjects;
    END;
  $$;


ALTER FUNCTION perseus.fn_diagramobjects() OWNER TO perseus_owner;

