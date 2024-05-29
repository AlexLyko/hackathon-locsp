# OFB Hackathon


## Installation de l'API


* Cloner le repo dans /home/USER/api

* Création d'un venv
    python3 -m venv venv
    source venv/bin/activate
    
* Installation des dépendances
    pip install -r requirements.txt


## Configuration APACHE (mod_uwsgi)

Exemple de configuration (/etc/apache2/sites-enabled/ofb.conf)

```
WSGIScriptAlias /ofb /home/sbe/projects/hackathon_ofb/api/api.wsgi
WSGIPythonPath /home/sbe/projects/hackathon_ofb/venv/lib/python3.8/site-packages
<Directory /home/sbe/projects/hackathon_ofb/api>
    <Files api.wsgi>
        Require all granted
        Order deny,allow
        Allow from all
        WSGIScriptReloading On
        WSGIPassAuthorization On
    </Files>
</Directory>

```

## Utilisation

Exemple d'url :

```
http://localhost/ofb/test?start_with=Par

http://localhost/ofb/test2?nom=coucou
```
