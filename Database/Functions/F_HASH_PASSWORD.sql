create or replace FUNCTION          F_HASH_PASSWORD (
  p_password IN VARCHAR2
) RETURN VARCHAR2
IS
  l_raw   RAW(2000);
  l_hash  RAW(2000);
BEGIN
  l_raw  := utl_i18n.string_to_raw(p_password, 'AL32UTF8');
  l_hash := dbms_crypto.hash(l_raw, dbms_crypto.hash_sh256);
  RETURN RAWTOHEX(l_hash);
END;
/