CREATE PROCEDURE perseus.sp_move_node(IN _myid integer, IN _parentid integer)
    LANGUAGE plpgsql
    AS $$
  DECLARE
    _myformerscope VARCHAR(100);
    _myformerleft INTEGER;
    _myformerright INTEGER;
    _myparentscope VARCHAR(100);
    _myparentleft INTEGER;
  BEGIN
    SELECT
        tree_scope_key,
        tree_left_key
      INTO
        _myparentscope, _myparentleft
      FROM
        perseus.goo
      WHERE id = _parentid;

    SELECT
        tree_scope_key,
        tree_left_key,
        tree_right_key
      INTO
        _myformerscope, _myformerleft, _myformerright
      FROM
        perseus.goo
      WHERE id = _myid;

    UPDATE perseus.goo
    SET tree_left_key = tree_left_key + (_myformerright - _myformerleft) + 1
    WHERE tree_left_key > _myparentleft
    AND tree_scope_key = _myparentscope;

    UPDATE perseus.goo
    SET tree_right_key = tree_right_key + (_myformerright - _myformerleft) + 1
    WHERE tree_right_key > _myparentleft
    AND tree_scope_key = _myparentscope;

    UPDATE perseus.goo
    SET tree_scope_key = _myparentscope,
        tree_left_key = _myparentleft + (tree_left_key - _myformerleft) + 1,
        tree_right_key = _myparentleft + (tree_right_key - _myformerleft) + 1
    WHERE tree_scope_key = _myformerscope
    AND tree_left_key >= _myformerleft
    AND tree_right_key <= _myformerright;

    UPDATE perseus.goo
    SET tree_left_key = tree_left_key - (_myformerright - _myformerleft) - 1
    WHERE tree_left_key > _myformerright
    AND tree_scope_key = _myformerscope;

    UPDATE perseus.goo
    SET tree_right_key = tree_right_key - (_myformerright - _myformerleft) - 1
    WHERE tree_right_key > _myformerright
    AND tree_scope_key = _myformerscope;

  END;
  $$;


ALTER PROCEDURE perseus.sp_move_node(IN _myid integer, IN _parentid integer) OWNER TO perseus_owner;

