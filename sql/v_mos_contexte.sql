-- @author alexandre.liccardi@ofb.gouv.fr
-- Fonction se basant sur la table ref_grids.parametres, permettant de donner à partir du nom d'une espèce et de coordonnées son "aire de contexte"
-- -- sp_name_input : nom de l'espèce, insensible à casse
-- -- coord_x_input / coord_y_input : coordonnées géographiques
-- -- srid : système de projection des coordonnées renseignées
-- -- param_simplify : parmaètre de simplification pris en compte par le ST_simplify final

create or replace function oso_2017.v_mos_contexte(sp_name_input text, coord_x_input double precision,coord_y_input double precision, srid integer, param_simplify integer) returns geometry language sql as $$
with 
param_sp as (select * from ref_grids.parametres where "Espece" ilike sp_name_input),
mos_list_R as (select array_agg("ClasseOSOBase") as mos_list_R_arr  from param_sp where "GeneralisteOuSpecialiste" = 'S'),
mos_list_G as (select array_agg("ClasseOSOBase") as mos_list_G_arr  from param_sp where "GeneralisteOuSpecialiste" = 'G'),
param_sp_dist as (select st_buffer(st_transform(st_setsrid(st_makepoint(coord_x_input,coord_y_input),srid),2154), "Mobilite"*1000) as perim_rech from param_sp limit 1),
-- résolution cas communes
geom_ref_i as (select oso_2017.v_mos_incommunes(perim_rech) as oso_algo from param_sp_dist),
geom_ref as (select (oso_algo).* from geom_ref_i),
valuesset as (select geom, (jsonb_array_elements(classes::jsonb)->'classe')::integer as mos, (jsonb_array_elements(classes::jsonb)->'proportion')::double precision as prop from geom_ref),
-- résolution cas grid 10 km
geom_ref_i_grid as (select oso_2017.v_mos_ingrid10(perim_rech) as oso_algo from param_sp_dist),
geom_ref_grid as (select (oso_algo).* from geom_ref_i_grid),
valuesset_grid as (select geom, (jsonb_array_elements(classes::jsonb)->'classe')::integer as mos, (jsonb_array_elements(classes::jsonb)->'proportion')::double precision as prop from geom_ref_grid),
geom_vects as (
	select distinct geom from valuesset,mos_list_R  where prop > 0.1 and mos = any(mos_list_R_arr)
	UNION
	select distinct geom from valuesset,mos_list_G  where prop > 0 and mos = any(mos_list_G_arr)
	union
	select distinct geom from valuesset_grid,mos_list_R  where prop > 0.1 and mos = any(mos_list_R_arr)
	UNION
	select distinct geom from valuesset_grid,mos_list_G  where prop > 0 and mos = any(mos_list_G_arr)
	union
	select perim_rech from param_sp_dist
	
)
select st_simplify(st_union(geom),param_simplify) from geom_vects
$$;
create table test6 as
select oso_2017.v_mos_contexte('Tétras Lyre', 489353.59,6587552.20,2154, 100);

-- La fonction étant longue à exécuter, ajout d'une alternative qui rammène toutes les communes et les dalles 10 km recoupant le périmètre de mobilité, sans tenir compte de l'occupation des sols.

create or replace function oso_2017.v_mos_nocontexte(sp_name_input text, coord_x_input double precision,coord_y_input double precision, srid integer, param_simplify integer) returns geometry language sql as $$
with 
param_sp as (select * from ref_grids.parametres where "Espece" iLike sp_name_input),
param_sp_dist as (select st_buffer(st_transform(st_setsrid(st_makepoint(coord_x_input,coord_y_input),srid),2154), "Mobilite"*1000) as perim_rech from param_sp limit 1),
-- résolution cas communes
valuesset as (select geom from ref_grids."commune_carto.geom2154",  param_sp_dist where ST_INTERSECTS(geom, perim_rech)),
-- résolution cas grid 10 km
valuesset_grid as (select geom from ref_grids."L93_10X10",  param_sp_dist where ST_INTERSECTS(geom, perim_rech)),
geom_vects as (
	select geom from valuesset
	union
	select geom from valuesset_grid
	union
	select perim_rech from param_sp_dist
)
select st_simplify(st_union(geom),param_simplify) from geom_vects
$$;
create table test62 as
select oso_2017.v_mos_nocontexte('Tétras Lyre', 489353.59,6587552.20,2154, 100);

--- Variante dans laquelle le seuil de prise en compte du mode d'occupation des sols (proportion de représentation minimale du milieu d'intérêt) est modifiable
-- -- sp_name_input : nom de l'espèce, insensible à casse
-- -- coord_x_input / coord_y_input : coordonnées géographiques
-- -- srid : système de projection des coordonnées renseignées
-- -- param_simplify : parmaètre de simplification pris en compte par le ST_simplify final
-- -- seuil_mos : seuil en fraction - proportion de représentation minimale du milieu d'intérêt
create or replace function oso_2017.v_mos_contexte(sp_name_input text, coord_x_input double precision,coord_y_input double precision, srid integer, param_simplify integer,
seuil_mos double precision
) returns geometry language sql as $$
with 
param_sp as (select * from ref_grids.parametres where "Espece" iLike sp_name_input),
mos_list_R as (select array_agg("ClasseOSOBase") as mos_list_R_arr  from param_sp where "GeneralisteOuSpecialiste" = 'S'),
mos_list_G as (select array_agg("ClasseOSOBase") as mos_list_G_arr  from param_sp where "GeneralisteOuSpecialiste" = 'G'),
param_sp_dist as (select st_buffer(st_transform(st_setsrid(st_makepoint(coord_x_input,coord_y_input),srid),2154), "Mobilite"*1000) as perim_rech from param_sp limit 1),
-- résolution cas communes
geom_ref_i as (select oso_2017.v_mos_incommunes(perim_rech) as oso_algo from param_sp_dist),
geom_ref as (select (oso_algo).* from geom_ref_i),
valuesset as (select geom, (jsonb_array_elements(classes::jsonb)->'classe')::integer as mos, (jsonb_array_elements(classes::jsonb)->'proportion')::double precision as prop from geom_ref),
-- résolution cas grid 10 km
geom_ref_i_grid as (select oso_2017.v_mos_ingrid10(perim_rech) as oso_algo from param_sp_dist),
geom_ref_grid as (select (oso_algo).* from geom_ref_i_grid),
valuesset_grid as (select geom, (jsonb_array_elements(classes::jsonb)->'classe')::integer as mos, (jsonb_array_elements(classes::jsonb)->'proportion')::double precision as prop from geom_ref_grid),
geom_vects as (
	select distinct geom from valuesset,mos_list_R  where prop > seuil_mos and mos = any(mos_list_R_arr)
	UNION
	select distinct geom from valuesset,mos_list_G  where prop > 0 and mos = any(mos_list_G_arr)
	union
	select distinct geom from valuesset_grid,mos_list_R  where prop > seuil_mos and mos = any(mos_list_R_arr)
	UNION
	select distinct geom from valuesset_grid,mos_list_G  where prop > 0 and mos = any(mos_list_G_arr)
	union
	select perim_rech from param_sp_dist
	
)
select st_simplify(st_union(geom),param_simplify) from geom_vects
$$;
create table test64 as
select oso_2017.v_mos_contexte('Tétras Lyre', 489353.59,6587552.20,2154, 100, 0.25);



create or replace function oso_2017.v_mos_nocontexte(cd_ref_input int, coord_x_input double precision,coord_y_input double precision, srid integer, param_simplify integer) returns geometry language sql as $$
with 
param_sp as (select * from ref_grids.parametres where cd_ref = cd_ref_input),
param_sp_dist as (select st_buffer(st_transform(st_setsrid(st_makepoint(coord_x_input,coord_y_input),srid),2154), "Mobilite"*1000) as perim_rech from param_sp limit 1),
-- résolution cas communes
valuesset as (select geom from ref_grids."commune_carto.geom2154",  param_sp_dist where ST_INTERSECTS(geom, perim_rech)),
-- résolution cas grid 10 km
valuesset_grid as (select geom from ref_grids."L93_10X10",  param_sp_dist where ST_INTERSECTS(geom, perim_rech)),
geom_vects as (
	select geom from valuesset
	union
	select geom from valuesset_grid
	union
	select perim_rech from param_sp_dist
)
select st_simplify(st_union(geom),param_simplify) from geom_vects
$$;

-- Fonction similaire, mais mobilise le cd_ref de l'espèce plutôt que le nom.

create or replace function oso_2017.v_mos_contexte(cd_ref_input int, coord_x_input double precision,coord_y_input double precision, srid integer, param_simplify integer, seuil_mos double precision
) returns geometry language sql as $$
with 
param_sp as (select * from ref_grids.parametres where cd_ref = cd_ref_input),
mos_list_R as (select array_agg("ClasseOSOBase") as mos_list_R_arr  from param_sp where "GeneralisteOuSpecialiste" = 'S'),
mos_list_G as (select array_agg("ClasseOSOBase") as mos_list_G_arr  from param_sp where "GeneralisteOuSpecialiste" = 'G'),
param_sp_dist as (select st_buffer(st_transform(st_setsrid(st_makepoint(coord_x_input,coord_y_input),srid),2154), "Mobilite"*1000) as perim_rech from param_sp limit 1),
-- résolution cas communes
geom_ref_i as (select oso_2017.v_mos_incommunes(perim_rech) as oso_algo from param_sp_dist),
geom_ref as (select (oso_algo).* from geom_ref_i),
valuesset as (select geom, (jsonb_array_elements(classes::jsonb)->'classe')::integer as mos, (jsonb_array_elements(classes::jsonb)->'proportion')::double precision as prop from geom_ref),
-- résolution cas grid 10 km
geom_ref_i_grid as (select oso_2017.v_mos_ingrid10(perim_rech) as oso_algo from param_sp_dist),
geom_ref_grid as (select (oso_algo).* from geom_ref_i_grid),
valuesset_grid as (select geom, (jsonb_array_elements(classes::jsonb)->'classe')::integer as mos, (jsonb_array_elements(classes::jsonb)->'proportion')::double precision as prop from geom_ref_grid),
geom_vects as (
	select distinct geom from valuesset,mos_list_R  where prop > seuil_mos and mos = any(mos_list_R_arr)
	UNION
	select distinct geom from valuesset,mos_list_G  where prop > 0 and mos = any(mos_list_G_arr)
	union
	select distinct geom from valuesset_grid,mos_list_R  where prop > seuil_mos and mos = any(mos_list_R_arr)
	UNION
	select distinct geom from valuesset_grid,mos_list_G  where prop > 0 and mos = any(mos_list_G_arr)
	union
	select perim_rech from param_sp_dist
	
)
select st_simplify(st_union(geom),param_simplify) from geom_vects
$$;

create or replace function oso_2017.v_mos_nocontexte(cd_ref_input int, coord_x_input double precision,coord_y_input double precision, srid integer, param_simplify integer) returns geometry language sql as $$
with 
param_sp as (select * from ref_grids.parametres where cd_ref = cd_ref_input),
param_sp_dist as (select st_buffer(st_transform(st_setsrid(st_makepoint(coord_x_input,coord_y_input),srid),2154), "Mobilite"*1000) as perim_rech from param_sp limit 1),
-- résolution cas communes
valuesset as (select geom from ref_grids."commune_carto.geom2154",  param_sp_dist where ST_INTERSECTS(geom, perim_rech)),
-- résolution cas grid 10 km
valuesset_grid as (select geom from ref_grids."L93_10X10",  param_sp_dist where ST_INTERSECTS(geom, perim_rech)),
geom_vects as (
	select geom from valuesset
	union
	select geom from valuesset_grid
	union
	select perim_rech from param_sp_dist
)
select st_simplify(st_union(geom),param_simplify) from geom_vects
$$;
create or replace function oso_2017.v_mos_contexte(cd_ref_input int, coord_x_input double precision,coord_y_input double precision, srid integer, param_simplify integer) returns geometry language sql as $$
select * from oso_2017.v_mos_contexte(cd_ref_input, coord_x_input,coord_y_input, srid, param_simplify, 0.1)
$$;

select oso_2017.v_mos_contexte(4001, 489353.59,6587552.20,2154, 100, 0.25);
select oso_2017.v_mos_contexte(4001, 489353.59,6587552.20,2154, 100);
select oso_2017.v_mos_nocontexte(4001, 489353.59,6587552.20,2154, 100, 0.25);

-- Sortie en GeoJSON

create or replace function oso_2017.v_mos_contexte_geojson(cd_sp_input int, coord_x_input double precision,coord_y_input double precision, srid integer, param_simplify integer, seuil double precision) 
returns text language sql as $$
select st_asgeojson(st_transform(oso_2017.v_mos_contexte(cd_sp_input, coord_x_input,coord_y_input, srid, param_simplify, seuil),4326))
$$;

create or replace function oso_2017.v_mos_nocontexte_geojson(cd_sp_input int, coord_x_input double precision,coord_y_input double precision, srid integer, param_simplify integer) 
returns text language sql as $$
select st_asgeojson(st_transform(oso_2017.v_mos_nocontexte(cd_sp_input, coord_x_input,coord_y_input, srid, param_simplify),4326))
$$;

create or replace function oso_2017.v_mos_contexte_geojson(cd_sp_input int, coord_x_input double precision,coord_y_input double precision, srid integer, param_simplify integer) 
returns text language sql as $$
select st_asgeojson(st_transform(oso_2017.v_mos_contexte(cd_sp_input, coord_x_input,coord_y_input, srid, param_simplify),4326))
$$;

select oso_2017.v_mos_contexte_geojson(4001, 489353.59,6587552.20,2154, 100, 0.25);
select oso_2017.v_mos_contexte_geojson(4001, 489353.59,6587552.20,2154, 100);
select oso_2017.v_mos_nocontexte_geojson(4001, 489353.59,6587552.20,2154, 100);

-- Sortie en WKT

create or replace function oso_2017.v_mos_contexte_wkt(cd_sp_input int, coord_x_input double precision,coord_y_input double precision, srid integer, param_simplify integer, seuil double precision) 
returns text language sql as $$
select ST_AsEWkt(oso_2017.v_mos_contexte(cd_sp_input, coord_x_input,coord_y_input, srid, param_simplify, seuil))
$$;

create or replace function oso_2017.v_mos_nocontexte_wkt(cd_sp_input int, coord_x_input double precision,coord_y_input double precision, srid integer, param_simplify integer) 
returns text language sql as $$
select ST_AsEWkt(oso_2017.v_mos_nocontexte(cd_sp_input, coord_x_input,coord_y_input, srid, param_simplify))
$$;

create or replace function oso_2017.v_mos_contexte_wkt(cd_sp_input int, coord_x_input double precision,coord_y_input double precision, srid integer, param_simplify integer) 
returns text language sql as $$
select ST_AsEWkt(oso_2017.v_mos_contexte(cd_sp_input, coord_x_input,coord_y_input, srid, param_simplify))
$$;

select oso_2017.v_mos_contexte_wkt(4001, 489353.59,6587552.20,2154, 100, 0.25);
select oso_2017.v_mos_nocontexte_wkt(4001, 489353.59,6587552.20,2154, 100);
select oso_2017.v_mos_contexte_wkt(4001, 489353.59,6587552.20,2154, 100);
