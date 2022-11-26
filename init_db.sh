#!/bin/bash

sqlite3 climat_control.db 'CREATE TABLE climat_control (current_temp varchar(3), end_temp varchar(3));                                                                                                                                                                                                                                                
INSERT INTO "climat_control" VALUES('24','26');'