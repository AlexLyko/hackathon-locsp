-- @author alexandre.liccardi@ofb.gouv.fr
-- Fonction permettant de rammener les statistiques d'occupation des sols selon OSO, avec le détail de proportions par classe dans un JSON et conservant des scores pondérés par la proportion de surface, pour une géométrie entrante
create type oso_2017.v_mos_ingeom AS
(
	geom geometry,
	classes jsonb ,
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
create or replace function oso_2017.v_mos_ingeom(geom_input geometry) returns oso_2017.v_mos_ingeom language sql  as $$
with matref as (select *,st_area(geom) as st_a_geom, st_intersection(v_mos.geom, geom_input) as geom_inter from oso_2017.v_mos where st_intersects(v_mos.geom, st_transform(geom_input,2154))),
matref_score as (
select  
	jsonb_build_object('libelle',libelle, 'classe',classe, 'proportion',st_area(st_union(geom_inter))/st_area(st_transform(geom_input,2154)) ) as jb,
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
),
matref_score2 as (
SELECT
	geom_input,
	jsonb_agg(jb),
	sum(hiver) as hiver,
	sum(ete) as ete,
	sum(feuillus) as feuillus,
	sum(coniferes) as coniferes,
	sum(pelouse) as pelouse,
	sum(landes) as landes,
	sum(urbaindens) as urbaindens,
	sum(urbaindiff) as urbaindiff,
	sum(zoneindcom) as zoneindcom,
	sum(route) as route,
	sum(plagedune) as plagedune,
	sum(surfmin) as surfmin,
	sum(eau) as eau,
	sum(glaceneige) as glaceneige,
	sum(prairie) as prairie,
	sum(vergers) as vergers,
	sum(vignes) as vignes
	from matref_score group by geom_input)
select * from matref_score2 ;
$$;

select * from oso_2017.v_mos_ingeom(st_buffer(st_setsrid(st_makepoint(489353.59,6587552.20),2154), 1000));
