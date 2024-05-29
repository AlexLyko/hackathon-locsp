-- @author alexandre.liccardi@ofb.gouv.fr
-- Fonction permettant de produire les statistiques d'occupation des sols, selon OSO, sur les grilles INPN 10 km intersectant un périmètre donné 

create or replace function oso_2017.v_mos_ingrid10(geom_input geometry) returns setof oso_2017.v_mos_ingeom  language sql as $$
	select (a1.v_res).*	from (select (oso_2017.v_mos_ingeom(geom)) as v_res from ref_grids."L93_10X10" where st_intersects(geom, geom_input)) a1
$$;
select * from oso_2017.v_mos_ingrid10(st_buffer(st_setsrid(st_makepoint(489353.59,6587552.20),2154), 1000));

-- Fonction permettant de produire les statistiques d'occupation des sols, selon OSO, sur les communes Admin Express intersectant un périmètre donné

create or replace function oso_2017.v_mos_incommunes(geom_input geometry) returns setof oso_2017.v_mos_ingeom  language sql as $$
	select (a1.v_res).*	from (select (oso_2017.v_mos_ingeom(geom)) as v_res from ref_grids."commune_carto.geom2154" where st_intersects(geom, geom_input)) a1
$$;
select * from oso_2017.v_mos_incommunes(st_buffer(st_setsrid(st_makepoint(489353.59,6587552.20),2154), 1000));
