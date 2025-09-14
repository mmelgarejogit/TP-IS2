create or replace FUNCTION          F_PERMISO(
  p_permiso IN VARCHAR2
) RETURN BOOLEAN
IS
  v_dummy NUMBER;
BEGIN
  SELECT 1
  INTO v_dummy
  FROM collection_permiso
  WHERE codigo_permiso = p_permiso
    AND session_id = v('APP_SESSION')
  FETCH FIRST 1 ROW ONLY;

  RETURN TRUE;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN FALSE;
END;
/