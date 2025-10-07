create or replace PACKAGE          PKG_NOMINA AS
  PROCEDURE ejecutar_nomina(p_periodo_id IN NUMBER, p_usuario_id IN NUMBER);
  PROCEDURE calcular_empleado(p_proceso_id IN NUMBER, p_empleado_id IN NUMBER);
END PKG_NOMINA;
/