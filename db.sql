--
--Crear una base de dades SQLite amb 2 taules: resource i tag
--
drop table if exists resources;
    CREATE TABLE resources (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            description      TEXT(128),
	    info	TEXT(256)
    );

drop table if exists resource_tag;
    CREATE TABLE resource_tag (
            resource_id     INTEGER REFERENCES resources(id) ON DELETE CASCADE ON UPDATE CASCADE,
            tag_id   TEXT(64) REFERENCES tag(id) ON DELETE CASCADE ON UPDATE CASCADE,
            PRIMARY KEY (resource_id, tag_id)
    );

drop table if exists tag;
  CREATE TABLE tag (
	    id		TEXT(64),
	    description TEXT(256),
	    PRIMARY KEY (id)
    );

drop table if exists tag_event;
   CREATE TABLE tag_event (
	id_tag	TEXT(64) REFERENCES tag(id) ON DELETE CASCADE ON UPDATE CASCADE,
	id_event INTEGER REFERENCES event(id) ON DELETE CASCADE ON UPDATE CASCADE,
	PRIMARY KEY (id_tag,id_event)
   );

drop table if exists event;
   CREATE TABLE event (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	info TEXT(256),
	description TEXT(128),
	starts DATETIME,
	ends DATETIME
   );

drop table if exists booking;
    CREATE TABLE booking(
	    id 		INTEGER PRIMARY KEY AUTOINCREMENT,
	    id_resource INTEGER REFERENCES resources(id) ON DELETE CASCADE ON UPDATE CASCADE,
	    id_event	INTEGER REFERENCES event(id) ON DELETE CASCADE ON UPDATE CASCADE,
	    starts	DATETIME,
	    ends	DATETIME,
            frequency   TEXT,
	    interval    INTEGER,
	    duration    DATETIME,
	    per_minuts  INTEGER, --0 to 59
	    per_hores   INTEGER, --0 to 23
	    per_dies    TEXT, 
	    per_mesos   TEXT,
	    per_dia_mes INTEGER
    );

-- Carreguem uns valors a les taules, sol per a provar
--

INSERT INTO resources VALUES (1,'Aula test 1','Estem de proves àáôïçÇ');
INSERT INTO resources VALUES (2,'Aula test 2','Estem de proves');
INSERT INTO resources VALUES (3,'Aula test 3','Estem de proves');
INSERT INTO resources VALUES (4,'Aula test 4','Estem de proves');
INSERT INTO resources VALUES (5,'Aula test 5','Estem de proves');

INSERT INTO tag VALUES ('projector','descr 1');
INSERT INTO tag VALUES ('pantalla','descr 2');
INSERT INTO tag VALUES ('videoconferencia','descr 3');
INSERT INTO tag VALUES ('acces adaptat','descr 4');
INSERT INTO tag VALUES ('punter laser','descr 5');
INSERT INTO tag VALUES ('microfons inalambrics','descr 6');
INSERT INTO tag VALUES ('isabel','descr 7');
INSERT INTO tag VALUES ('wireless','descr 8');

INSERT INTO resource_tag VALUES (1,'projector');
INSERT INTO resource_tag VALUES (1,'pantalla');

INSERT INTO resource_tag VALUES (2,'projector');
INSERT INTO resource_tag VALUES (2,'pantalla');
INSERT INTO resource_tag VALUES (2,'wireless');

INSERT INTO resource_tag VALUES (3,'acces adaptat');
INSERT INTO resource_tag VALUES (3,'wireless');

INSERT INTO resource_tag VALUES (4,'projector');
INSERT INTO resource_tag VALUES (4,'pantalla');
INSERT INTO resource_tag VALUES (4,'isabel');

INSERT INTO resource_tag VALUES (5,'projector');
INSERT INTO resource_tag VALUES (5,'pantalla');
INSERT INTO resource_tag VALUES (5,'punter laser');
INSERT INTO resource_tag VALUES (5,'microfons inalambrics');
INSERT INTO resource_tag VALUES (5,'videoconferencia');
INSERT INTO resource_tag VALUES (5,'wireless');

INSERT INTO event values(1,'Informació 1',"Descripció de l'event",'2010-02-16 04:00:00','2010-02-16 05:00:00');
INSERT INTO event values (2,'Informació 2',"Descripció de l'event",'2010-02-16 04:00:00','2010-02-16 05:00:00');
INSERT INTO event values(3,'Informació 3',"Descripció de l'event",'2010-02-16 04:00:00','2010-02-16 05:00:00');
INSERT INTO event values(4,'Informació 4',"Descripció de l'event",'2010-02-16 04:00:00','2010-02-16 05:00:00');

INSERT INTO booking values (1,3,1,'2010-02-16 04:00:00','2010-02-16 05:00:00','','','','','','','',-1);
INSERT INTO booking values (2,4,1,'2010-02-16 04:00:00','2010-02-16 05:00:00','','','','','','','',-2);
INSERT INTO booking values (3,5,2,'2010-02-16 04:00:00','2010-02-16 05:00:00','','','','','','','',0);
INSERT INTO booking values (4,2,3,'2010-02-16 04:00:00','2010-02-16 05:00:00','','','','','','','',1);
INSERT INTO booking values (5,1,4,'2010-02-16 04:00:00','2010-02-16 05:00:00','','','','','','','',2);

INSERT INTO tag_event values ('projector',1);
INSERT INTO tag_event values ('pantalla',1);

INSERT INTO tag_event values ('pantalla',2);

INSERT INTO tag_event values ('wireless',3);

INSERT INTO tag_event values ('isabel',4);
INSERT INTO tag_event values ('videoconferencia',4);
INSERT INTO tag_event values ('microfons inalambrics',4);
INSERT INTO tag_event values ('wireless',4);
