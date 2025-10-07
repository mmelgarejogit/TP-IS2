create or replace PACKAGE BODY          PKG_NOMINA AS

  --------------------------------------------------------------------
  -- Procedimiento principal
  --------------------------------------------------------------------
  PROCEDURE ejecutar_nomina(p_periodo_id IN NUMBER, p_usuario_id IN NUMBER) IS
    v_proceso_id NUMBER;
  BEGIN
    INSERT INTO proceso_nomina (periodo_id, ejecutado_por, fecha_ejecucion, estado)
    VALUES (p_periodo_id, p_usuario_id, SYSDATE, 'PROCESADO')
    RETURNING cod_proceso_nomina INTO v_proceso_id;

    FOR r IN (SELECT id_empleado FROM empleado WHERE activo = 'S') LOOP
      calcular_empleado(v_proceso_id, r.id_empleado);
    END LOOP;

    COMMIT;
  END ejecutar_nomina;

  --------------------------------------------------------------------
  -- Cálculo individual del empleado
  --------------------------------------------------------------------
  PROCEDURE calcular_empleado(p_proceso_id IN NUMBER, p_empleado_id IN NUMBER) IS
    v_total_ingresos   NUMBER := 0;
    v_total_descuentos NUMBER := 0;
    v_neto             NUMBER := 0;
    v_recibo_id        NUMBER;
    v_salario_minimo   NUMBER := 2900000;
    v_salario_base     NUMBER := 0;
    v_bonif_hijos      NUMBER := 0;
    v_ips_base         NUMBER := 0;
    v_ips_monto        NUMBER := 0;
    v_hijos_validos    NUMBER := 0;
  BEGIN
    ------------------------------------------------------------------
    -- 1. Buscar salario base del empleado
    ------------------------------------------------------------------
    SELECT NVL(MAX(monto_fijo_gs),0)
      INTO v_salario_base
      FROM empleado_concepto ec
      JOIN concepto c ON ec.concepto_id = c.cod_concepto
     WHERE ec.empleado_id = p_empleado_id
       AND c.codigo = 'SB'
       AND (ec.vigente_hasta IS NULL OR ec.vigente_hasta >= SYSDATE)
       AND ec.vigente_desde <= SYSDATE;

    ------------------------------------------------------------------
    -- 2. Insertar salario base
    ------------------------------------------------------------------
    INSERT INTO nomina_detalle (
      proceso_id, empleado_id, concepto_id, cantidad, monto_unit_gs,
      monto_total_gs, imponible_ips, afecta_aguinaldo)
    SELECT p_proceso_id, p_empleado_id, c.cod_concepto, 1,
           v_salario_base, v_salario_base, c.afecta_ips, c.afecta_aguinaldo
      FROM concepto c
     WHERE c.codigo = 'SB';

    v_total_ingresos := v_total_ingresos + v_salario_base;
    v_ips_base := v_ips_base + v_salario_base;

    ------------------------------------------------------------------
    -- 3. Bonificación por hijo (máx 4, menores de 18, residente PY)
    ------------------------------------------------------------------
    SELECT COUNT(*)
      INTO v_hijos_validos
      FROM hijo
     WHERE id_empleado = p_empleado_id
       AND TRUNC(MONTHS_BETWEEN(SYSDATE, fecha_nac) / 12) < 18
       AND reside_py = 'S';

    IF v_hijos_validos > 4 THEN
      v_hijos_validos := 4;
    END IF;

    IF v_salario_base < (3 * v_salario_minimo) AND v_hijos_validos > 0 THEN
      v_bonif_hijos := v_hijos_validos * (v_salario_minimo * 0.05);

      INSERT INTO nomina_detalle (
        proceso_id, empleado_id, concepto_id, cantidad, monto_unit_gs,
        monto_total_gs, imponible_ips, afecta_aguinaldo)
      SELECT p_proceso_id, p_empleado_id, c.cod_concepto, v_hijos_validos,
             v_salario_minimo * 0.05, v_bonif_hijos, 'N', 'N'
        FROM concepto c
       WHERE c.codigo = 'BON_HIJO';

      v_total_ingresos := v_total_ingresos + v_bonif_hijos;
    END IF;

    ------------------------------------------------------------------
    -- 4. Calcular IPS (9% sobre base imponible)
    ------------------------------------------------------------------
    v_ips_monto := ROUND(v_ips_base * 0.09, 0);

    INSERT INTO nomina_detalle (
      proceso_id, empleado_id, concepto_id, cantidad, monto_unit_gs,
      monto_total_gs, imponible_ips, afecta_aguinaldo)
    SELECT p_proceso_id, p_empleado_id, c.cod_concepto, 1,
           v_ips_monto, v_ips_monto, 'N', 'N'
      FROM concepto c
     WHERE c.codigo = 'IPS';

    v_total_descuentos := v_total_descuentos + v_ips_monto;

    ------------------------------------------------------------------
    -- 5. Totales y recibo
    ------------------------------------------------------------------
    v_neto := v_total_ingresos - v_total_descuentos;

    INSERT INTO recibo (
      proceso_id, empleado_id, total_ingresos, total_descuentos,
      neto_cobrar, fecha_emision, estado)
    VALUES (p_proceso_id, p_empleado_id,
            v_total_ingresos, v_total_descuentos, v_neto,
            SYSDATE, 'EMITIDO')
    RETURNING cod_recibo INTO v_recibo_id;

    INSERT INTO recibo_detalle (recibo_id, concepto_id, descripcion, monto_gs)
    SELECT v_recibo_id, nd.concepto_id, c.descripcion, nd.monto_total_gs
      FROM nomina_detalle nd
      JOIN concepto c ON nd.concepto_id = c.cod_concepto
     WHERE nd.proceso_id = p_proceso_id
       AND nd.empleado_id = p_empleado_id;

    COMMIT;
  END calcular_empleado;

END PKG_NOMINA;
/