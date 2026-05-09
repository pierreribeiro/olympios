CREATE TRIGGER validatetransitionmaterial AFTER INSERT ON perseus.transition_material REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION perseus.validatetransitionmaterial();

