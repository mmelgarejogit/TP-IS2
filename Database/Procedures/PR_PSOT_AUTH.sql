create or replace PROCEDURE          PR_POST_AUTH
IS
  v_user    CHAR(4) := f_user;
  v_query   VARCHAR2(4000);
  v_names   wwv_flow_global.vc_arr2;
  v_values  wwv_flow_global.vc_arr2;
BEGIN
  v_names(1) := 'v_user';
  v_values(1) := v_user;

  v_query := '
    SELECT
      u.cod_usuario,
      r.cod_rol,
      p.cod_permiso,
      p.codigo,
      p.descripcion
    FROM usuario u
    JOIN usuario_rol ur ON ur.usuario_id = u.cod_usuario
    JOIN rol r          ON r.cod_rol     = ur.rol_id
    JOIN rol_permiso rp ON rp.rol_id     = r.cod_rol
    JOIN permiso p      ON p.cod_permiso = rp.permiso_id
    WHERE u.username = :v_user
      AND u.estado = ''AC''
  ';

  apex_collection.create_collection_from_query_b(
    p_collection_name    => 'PERMISO',
    p_query              => v_query,
    p_names              => v_names,
    p_values             => v_values,
    p_truncate_if_exists => 'YES'
  );

EXCEPTION
  WHEN OTHERS THEN
--    NULL;
    raise_application_error(-20999,SQLERRM);
END;
/