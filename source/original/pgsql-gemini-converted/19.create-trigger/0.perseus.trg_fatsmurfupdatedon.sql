CREATE TRIGGER trg_fatsmurfupdatedon AFTER UPDATE ON perseus.fatsmurf REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION perseus.trg_fatsmurfupdatedon();

