CREATE PROCEDURE perseus.transitiontomaterial(IN _transitionuid character varying, IN _materialuid character varying)
    LANGUAGE plpgsql
    AS $$
  BEGIN
    INSERT INTO perseus.transition_material (material_id, transition_id)
      VALUES (transitiontomaterial._materialuid, transitiontomaterial._transitionuid)
    ;
  END;
  $$;


ALTER PROCEDURE perseus.transitiontomaterial(IN _transitionuid character varying, IN _materialuid character varying) OWNER TO perseus_owner;

