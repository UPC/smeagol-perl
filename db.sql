--
--Crear una base de dades SQLite amb 2 taules: resource i tag
--
drop table if exists t_resource;
    CREATE TABLE t_resource (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            description      TEXT(128),
	    info	TEXT(256)
    );

drop table if exists t_resource_tag;
    CREATE TABLE t_resource_tag (
            resource_id     INTEGER REFERENCES resources(id) ON DELETE CASCADE,
            tag_id   TEXT(64) REFERENCES tag(id) ON DELETE CASCADE ON UPDATE CASCADE,
            PRIMARY KEY (resource_id, tag_id)
    );

drop table if exists t_tag;
  CREATE TABLE t_tag (
	    id		TEXT(64),
	    description TEXT(256),
	    PRIMARY KEY (id)
    );

drop table if exists t_tag_event;
   CREATE TABLE t_tag_event (
	id_tag	TEXT(64) REFERENCES t_tag(id) ON DELETE CASCADE ON UPDATE CASCADE,
	id_event INTEGER REFERENCES t_event(id) ON DELETE CASCADE,
	PRIMARY KEY (id_tag,id_event)
   );

drop table if exists t_event;
   CREATE TABLE t_event (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	info TEXT(256),
	description TEXT(128),
	starts DATETIME,
	ends DATETIME
   );

drop table if exists t_booking;
CREATE TABLE t_booking(
      id 		INTEGER PRIMARY KEY AUTOINCREMENT,
      id_resource INTEGER REFERENCES t_resource(id) ON DELETE CASCADE,
      id_event	INTEGER REFERENCES t_event(id) ON DELETE CASCADE,
      dtstart	DATETIME,
      dtend	DATETIME,
      duration    DURATION,
      frequency   TEXT,
      interval    INTEGER,
      until	DATETIME,
      by_minute  INTEGER, --0 to 59
      by_hour   INTEGER, --0 to 23
      by_day    TEXT,
      by_month   TEXT,
      by_day_month INTEGER
);

drop table if exists t_exception;
CREATE TABLE t_exception(
      id 		INTEGER PRIMARY KEY AUTOINCREMENT,
      id_booking	INTEGER REFERENCES t_booking(id) ON DELETE CASCADE,
      dtstart	DATETIME,
      dtend	DATETIME,
      duration    DURATION,
      frequency   TEXT,
      interval    INTEGER,
      until	DATETIME,
      by_minute  INTEGER, --0 to 59
      by_hour   INTEGER, --0 to 23
      by_day    TEXT,
      by_month   TEXT,
      by_day_month INTEGER
); 

-- Carreguem uns valors a les taules, sol per a provar
--

INSERT INTO t_resource VALUES (1,'Aula test 1','Estem de proves àáôïçÇ');
INSERT INTO t_resource VALUES (2,'Aula test 2','Estem de proves');
INSERT INTO t_resource VALUES (3,'Aula test 3','Estem de proves');
INSERT INTO t_resource VALUES (4,'Aula test 4','Estem de proves');
INSERT INTO t_resource VALUES (5,'Aula test 5','Estem de proves');

INSERT INTO t_tag VALUES ('projector','descr 1');
INSERT INTO t_tag VALUES ('pantalla','descr 2');
INSERT INTO t_tag VALUES ('videoconferencia','descr 3');
INSERT INTO t_tag VALUES ('acces adaptat','descr 4');
INSERT INTO t_tag VALUES ('punter laser','descr 5');
INSERT INTO t_tag VALUES ('microfons inalambrics','descr 6');
INSERT INTO t_tag VALUES ('isabel','descr 7');
INSERT INTO t_tag VALUES ('wireless','descr 8');

INSERT INTO t_resource_tag VALUES (1,'projector');
INSERT INTO t_resource_tag VALUES (1,'pantalla');

INSERT INTO t_resource_tag VALUES (2,'projector');
INSERT INTO t_resource_tag VALUES (2,'pantalla');
INSERT INTO t_resource_tag VALUES (2,'wireless');

INSERT INTO t_resource_tag VALUES (3,'acces adaptat');
INSERT INTO t_resource_tag VALUES (3,'wireless');

INSERT INTO t_resource_tag VALUES (4,'projector');
INSERT INTO t_resource_tag VALUES (4,'pantalla');
INSERT INTO t_resource_tag VALUES (4,'isabel');

INSERT INTO t_resource_tag VALUES (5,'projector');
INSERT INTO t_resource_tag VALUES (5,'pantalla');
INSERT INTO t_resource_tag VALUES (5,'punter laser');
INSERT INTO t_resource_tag VALUES (5,'microfons inalambrics');
INSERT INTO t_resource_tag VALUES (5,'videoconferencia');
INSERT INTO t_resource_tag VALUES (5,'wireless');

INSERT INTO t_event values(1,'Informació 1',"Descripció de l'event 1",'2010-02-16 04:00:00','2010-02-16 05:00:00');
INSERT INTO t_event values (2,'Informació 2',"Descripció de l'event 2",'2010-02-16 04:00:00','2010-02-16 05:00:00');
INSERT INTO t_event values(3,'Informació 3',"Descripció de l'event 3",'2010-02-16 04:00:00','2010-02-16 05:00:00');
INSERT INTO t_event values(4,'Informació 4',"Descripció de l'event 4",'2010-02-16 04:00:00','2010-02-16 05:00:00');

--|id|id_resource|id_event|dtstart|dtend|duration|frequency|interval|until|by_minute|by_hour|by_day|by_month|by_day_month

INSERT INTO t_booking values (1,3,1,'2010-12-25 08:00:00','2010-12-25 09:00:00','60','daily','1','2010-12-25 09:00:00','00','08','sa','12','25');
INSERT INTO t_booking values (6,3,1,'2010-12-23 09:00:00','2010-12-23 10:00:00','60','daily','2','2010-12-31 09:00:00','00','09','','','');
INSERT INTO t_booking values (7,3,1,'2010-12-23 10:00:00','2010-12-23 11:00:00','60','weekly','1','2010-12-31 09:00:00','00','10','th','','');
INSERT INTO t_booking values (8,3,1,'2010-12-23 11:00:00','2010-12-23 12:00:00','60','monthly','1','2011-03-31 09:00:00','00','11','','','23');
INSERT INTO t_booking values (9,3,1,'2010-12-23 12:00:00','2010-12-23 13:00:00','60','yearly','1','2012-12-31 09:00:00','00','12','','12','23');

INSERT INTO t_booking values (2,4,1,'2010-02-16 05:00:00','2010-02-16 06:00:00','60','daily','2','2011-01-01 00:00:00','00','05','mo,tu,we,th,fr','','');
INSERT INTO t_booking values (3,5,2,'2010-02-16 06:00:00','2010-02-16 07:00:00','60','weekly','2','2011-01-01 00:00:00','00','06','mo,tu,we,th,fr','','');
INSERT INTO t_booking values (4,2,3,'2010-02-16 07:00:00','2010-02-16 08:00:00','60','monthly','1','2011-01-01 00:00:00','00','07','mo,tu,we,th,fr','','');
INSERT INTO t_booking values (5,1,4,'2010-02-16 08:00:00','2010-02-16 09:00:00','60','yearly','1','2013-02-16 09:00:00','00','08','','02','16');

INSERT INTO t_tag_event values ('projector',1);
INSERT INTO t_tag_event values ('pantalla',1);

INSERT INTO t_tag_event values ('pantalla',2);

INSERT INTO t_tag_event values ('wireless',3);

INSERT INTO t_tag_event values ('isabel',4);
INSERT INTO t_tag_event values ('videoconferencia',4);
INSERT INTO t_tag_event values ('microfons inalambrics',4);
INSERT INTO t_tag_event values ('wireless',4);
