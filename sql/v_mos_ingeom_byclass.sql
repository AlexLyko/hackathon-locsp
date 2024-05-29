-- @author alexandre.liccardi@ofb.gouv.fr
-- Fonction permettant de rammener les vecteurs d'occupation des sols selon OSO, fusionnés par classe et conservant des scores pondérés par la proportion de surface, pour une géométrie entrante
create type oso_2017.v_mos_ingeom_byclass_type AS
(
	libelle varchar(100),
	classe int2 ,
	st_union geometry ,
	hiver float8 ,
	ete float8 ,
	feuillus float8 ,
	coniferes float8 ,
	pelouse float8 ,
	landes float8 ,
	urbaindens float8 ,
	urbaindiff float8 ,
	zoneindcom float8 ,
	route float8 ,
	plagedune float8 ,
	surfmin float8 ,
	eau float8 ,
	glaceneige float8 ,
	prairie float8 ,
	vergers float8 ,
	vignes float8 
);

drop function oso_2017.v_mos_ingeom_byclass(geom_input geometry);


create or replace function oso_2017.v_mos_ingeom_byclass(geom_input geometry) returns setof oso_2017.v_mos_ingeom_byclass_type language sql  as $$
with matref as (select *,st_area(geom) as st_a_geom, st_intersection(v_mos.geom, geom_input) as geom_inter from oso_2017.v_mos where st_intersects(v_mos.geom, st_transform(geom_input,2154))),
matref_score as (
select  libelle, classe, st_union(geom_inter),
	sum(hiver*st_area(geom_inter)/st_a_geom) as hiver,
	sum(ete*st_area(geom_inter)/st_a_geom) as ete,
	sum(feuillus*st_area(geom_inter)/st_a_geom) as feuillus,
	sum(coniferes*st_area(geom_inter)/st_a_geom) as coniferes,
	sum(pelouse*st_area(geom_inter)/st_a_geom) as pelouse,
	sum(landes*st_area(geom_inter)/st_a_geom) as landes,
	sum(urbaindens*st_area(geom_inter)/st_a_geom) as urbaindens,
	sum(urbaindiff*st_area(geom_inter)/st_a_geom) as urbaindiff,
	sum(zoneindcom*st_area(geom_inter)/st_a_geom) as zoneindcom,
	sum(route*st_area(geom_inter)/st_a_geom) as route,
	sum(plagedune*st_area(geom_inter)/st_a_geom) as plagedune,
	sum(surfmin*st_area(geom_inter)/st_a_geom) as surfmin,
	sum(eau*st_area(geom_inter)/st_a_geom) as eau,
	sum(glaceneige*st_area(geom_inter)/st_a_geom) as glaceneige,
	sum(prairie*st_area(geom_inter)/st_a_geom) as prairie,
	sum(vergers*st_area(geom_inter)/st_a_geom) as vergers,
	sum(vignes*st_area(geom_inter)/st_a_geom) as vignes
	from matref join oso_2017.bib_classes on code_classe = classe group by classe,libelle
)
select * from matref_score ;
$$;

select * from oso_2017.v_mos_ingeom_byclass(st_buffer(st_setsrid(st_makepoint(489353.59,6587552.20),2154), 1000));
