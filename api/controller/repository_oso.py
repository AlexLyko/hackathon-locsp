"""
    Service d'interrogation de la couche OSO
"""
from controller.DBController import DBController


class RepoOso:
    def __init__(self):
        self.dbc = DBController()


    def get_oso_intersects(self, x, y, distance=1):
        """
            Run query and return OSO data
        """
        sql  = """
            SELECT 
                gid, classe, validmean,
                validstd, confidence, hiver, ete, feuillus, coniferes, pelouse, landes,
                urbaindens, urbaindiff, zoneindcom, route, plagedune, surfmin, eau, glaceneige, prairie, vergers, vignes, aire,
                st_asgeojson(geom) as geom
            FROM oso_2017.v_mos vm  
            WHERE st_intersects(geom, ST_Buffer(st_transform(st_setsrid(st_makepoint(%s, %s), 4326), 2154), %s))
            LIMIT 10
        """

        data = self.dbc.run_query(sql, [x, y, distance])


        return self.dbc.processData(data)
