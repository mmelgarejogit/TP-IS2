create or replace FUNCTION          F_AUTH_USUARIO (
  p_username  IN CHAR,
  p_password  IN VARCHAR2
) RETURN BOOLEAN
IS
  l_hash_db   VARCHAR2(200);
  l_hash_in   VARCHAR2(200);
  l_estado    CHAR(2);
  l_username  CHAR(4) := LOWER(p_username);
BEGIN
  l_hash_in := f_hash_password(p_password);

  SELECT hash_password, estado
  INTO l_hash_db, l_estado
  FROM usuario
  WHERE username = l_username;

  IF l_estado = 'AC' AND l_hash_db = l_hash_in THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN FALSE;
END;
/