create or replace FUNCTION          FN_GET_NAVIGATION_MENU_SQL(
  p_app_id IN NUMBER DEFAULT 100
)
RETURN VARCHAR2
IS
  v_sql VARCHAR2(32767);
BEGIN
  
  -- App 100: Menú principal (cards de aplicaciones)
  IF p_app_id = 100 THEN
    v_sql := q'[
      SELECT 
        m.menu_level AS "level",
        m.label AS label,
  
        -- Target: Solo enlaces a otras apps o URLs
        CASE m.target_type
          WHEN 'APEX' THEN
            'f?p=' || m.target_app_id || ':1:' || :APP_SESSION || '::::'
          WHEN 'URL' THEN m.target_url
          WHEN 'JS' THEN 'javascript:' || m.target_js
          ELSE '#'
        END AS target,
  
        'NO' AS is_current_list_entry,
  
        COALESCE(m.image_icon, 'fa-cube') AS image,
        m.image_attribute AS image_attribute,
        COALESCE(m.image_alt_attribute, m.label) AS image_alt_attribute,
        m.attribute_01 AS attribute1,
        m.attribute_02 AS attribute2,
        m.attribute_03 AS attribute3,
        m.attribute_04 AS attribute4,
        m.attribute_05 AS attribute5,
        m.attribute_06 AS attribute6,
        m.attribute_07 AS attribute7,
        m.attribute_08 AS attribute8,
        m.attribute_09 AS attribute9,
        m.attribute_10 AS attribute10

      FROM INGESOFT.apx_navigation_menu m
      LEFT JOIN INGESOFT.collection_permiso cp 
        ON cp.codigo_permiso = m.codigo_permiso
        AND cp.session_id = :APP_SESSION

      WHERE m.is_visible = 'Y'
        AND m.is_active = 'Y'
        AND m.workspace = 'INGESOFT'
        AND m.menu_level = 1
        AND (m.codigo_permiso IS NULL OR cp.session_id IS NOT NULL)

      ORDER BY m.display_order, m.label
    ]';
    
  -- Otras apps: Menú interno jerárquico
  ELSE
    v_sql := q'[
      SELECT 
        m.menu_level - 1 AS "level",
        m.label AS label,
  
        -- Target dinámico según tipo
        CASE m.target_type
          WHEN 'APEX' THEN
            'f?p=' || m.target_app_id || ':' || m.target_page_id || ':' || :APP_SESSION ||
            CASE WHEN m.target_request IS NOT NULL THEN ':' || m.target_request ELSE '' END ||
            CASE WHEN :DEBUG IS NOT NULL THEN ':' || :DEBUG ELSE '' END ||
            CASE WHEN m.target_clear IS NOT NULL THEN ':' || m.target_clear ELSE '' END ||
            CASE WHEN m.target_items IS NOT NULL THEN ':' || m.target_items ELSE '' END ||
            CASE WHEN m.target_values IS NOT NULL THEN ':' || m.target_values ELSE '' END
          WHEN 'URL' THEN m.target_url
          WHEN 'JS' THEN 'javascript:' || m.target_js
          ELSE '#'
        END AS target,
  
        -- Detectar página actual
        CASE 
          WHEN m.target_type = 'APEX' 
              AND m.target_app_id = :APP_ID 
              AND m.target_page_id = TO_CHAR(:APP_PAGE_ID) 
          THEN 'YES'
          ELSE 'NO' 
        END AS is_current_list_entry,
  
        COALESCE(m.image_icon, 'fa-cube') AS image,
        m.image_attribute AS image_attribute,
        COALESCE(m.image_alt_attribute, m.label) AS image_alt_attribute,
        m.attribute_01 AS attribute1,
        m.attribute_02 AS attribute2,
        m.attribute_03 AS attribute3,
        m.attribute_04 AS attribute4,
        m.attribute_05 AS attribute5,
        m.attribute_06 AS attribute6,
        m.attribute_07 AS attribute7,
        m.attribute_08 AS attribute8,
        m.attribute_09 AS attribute9,
        m.attribute_10 AS attribute10

      FROM INGESOFT.apx_navigation_menu m
      LEFT JOIN INGESOFT.collection_permiso cp 
        ON cp.codigo_permiso = m.codigo_permiso
        AND cp.session_id = :APP_SESSION

      WHERE m.is_visible = 'Y'
        AND m.is_active = 'Y'
        AND m.workspace = 'INGESOFT'
        AND m.application_id = ]' || p_app_id || q'[
        AND m.menu_level > 1
        AND (m.codigo_permiso IS NULL OR cp.session_id IS NOT NULL)

      START WITH m.parent_menu_item_id = 0

      CONNECT BY PRIOR m.application_id = m.parent_application_id 
            AND PRIOR m.menu_item_id = m.parent_menu_item_id
            AND PRIOR m.menu_level < m.menu_level

      ORDER SIBLINGS BY m.display_order, m.label
    ]';
  END IF;

  RETURN v_sql;
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN 'SELECT ''Error en menú (App ' || p_app_id || '): ' || SQLERRM || ''' AS label FROM dual';
END FN_GET_NAVIGATION_MENU_SQL;
/