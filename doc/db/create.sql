--
--Crear una base de dades SQLite amb 2 taules: resource i tag
--
drop table if exists t_resource;
    CREATE TABLE t_resource (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            description      TEXT(128),
	    info	TEXT(256)
    );

drop table if exists t_tag;
  CREATE TABLE t_tag (
	    id		TEXT(64),
	    description TEXT(256),
	    PRIMARY KEY (id)
    );
  
drop table if exists t_resource_tag;
CREATE TABLE t_resource_tag (
      resource_id     INTEGER REFERENCES t_resource(id) ON DELETE CASCADE,
			      tag_id   TEXT(64) REFERENCES t_tag(id) ON DELETE CASCADE ON UPDATE CASCADE,
			      PRIMARY KEY (resource_id, tag_id)
);

drop table if exists t_event;
   CREATE TABLE t_event (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	info TEXT(256),
	description TEXT(128),
	starts DATETIME,
	ends DATETIME
   );

drop table if exists t_tag_event;
CREATE TABLE t_tag_event (
      id_tag	TEXT(64) REFERENCES t_tag(id) ON DELETE CASCADE ON UPDATE CASCADE,
			id_event INTEGER REFERENCES t_event(id) ON DELETE CASCADE,
			PRIMARY KEY (id_tag,id_event)
);
   
drop table if exists t_booking;
CREATE TABLE t_booking(
      id 		INTEGER PRIMARY KEY AUTOINCREMENT,
      info TEXT(256),
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

drop table if exists t_tag_booking;
CREATE TABLE t_tag_booking (
      id_tag	TEXT(64) REFERENCES t_tag(id) ON DELETE CASCADE ON UPDATE CASCADE,
      id_booking INTEGER REFERENCES t_booking(id) ON DELETE CASCADE,
      PRIMARY KEY (id_tag,id_booking)
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
