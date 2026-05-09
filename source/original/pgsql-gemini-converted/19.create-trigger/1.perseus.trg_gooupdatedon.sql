CREATE TRIGGER trg_gooupdatedon AFTER UPDATE ON perseus.goo REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION perseus.trg_gooupdatedon();

