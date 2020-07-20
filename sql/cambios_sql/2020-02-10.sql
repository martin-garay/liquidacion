CREATE OR REPLACE FUNCTION public.sp_volver_a_estado_liquidada(_id_liquidacion integer)
  RETURNS void AS
$BODY$
declare 
    _id_estado integer;
begin 
    select id_estado into _id_estado from liquidaciones where id=_id_liquidacion;
    IF _id_estado=3 THEN --si la liquidacion esta CERRADA

	/*borrado de historico de liquidacion*/
	delete from historico_recibos_acumuladores where id_recibo in (select id from historico_recibos where id_liquidacion=_id_liquidacion);
	delete from historico_recibos_conceptos where id_recibo in (select id from historico_recibos where id_liquidacion=_id_liquidacion);
	delete from historico_recibos where id_liquidacion=_id_liquidacion;
	delete from historico_liquidaciones_conceptos where id_liquidacion=_id_liquidacion;
	delete from historico_liquidaciones where id=_id_liquidacion;

	update liquidaciones set id_estado=2 where id=_id_liquidacion; --paso a estado LIQUIDADA
    
    END IF;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
