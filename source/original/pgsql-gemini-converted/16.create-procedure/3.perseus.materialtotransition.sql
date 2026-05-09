CREATE PROCEDURE perseus.materialtotransition(IN _materialuid character varying, IN _transitionuid character varying)
    LANGUAGE plpgsql
    AS $$
  BEGIN
    INSERT INTO perseus.material_transition (material_id, transition_id)
      VALUES (materialtotransition._materialuid, materialtotransition._transitionuid)
    ;
  END;
  $$;


ALTER PROCEDURE perseus.materialtotransition(IN _materialuid character varying, IN _transitionuid character varying) OWNER TO perseus_owner;

