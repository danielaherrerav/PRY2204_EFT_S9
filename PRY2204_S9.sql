-- PRY2204 EFT Semana 9 - ANFP
-- Daniela Herrera

-- ===== BLOQUE 0: LIMPIEZA =====
DROP TABLE dominio_idioma  CASCADE CONSTRAINTS;
DROP TABLE historial_club  CASCADE CONSTRAINTS;
DROP TABLE jugador         CASCADE CONSTRAINTS;
DROP TABLE personal_planta CASCADE CONSTRAINTS;
DROP TABLE trabajador      CASCADE CONSTRAINTS;
DROP TABLE comuna          CASCADE CONSTRAINTS;
DROP TABLE region          CASCADE CONSTRAINTS;
DROP TABLE nacionalidad    CASCADE CONSTRAINTS;
DROP TABLE estado_civil    CASCADE CONSTRAINTS;
DROP TABLE asociacion      CASCADE CONSTRAINTS;
DROP TABLE club_futbol     CASCADE CONSTRAINTS;
DROP TABLE escuela_futbol  CASCADE CONSTRAINTS;
DROP TABLE puesto          CASCADE CONSTRAINTS;
DROP TABLE idioma          CASCADE CONSTRAINTS;
DROP SEQUENCE seq_club;

-- ===== BLOQUE 1: TABLAS SIN FK =====
CREATE TABLE region (
    id_region NUMBER(2)    NOT NULL,
    nombre    VARCHAR2(50) NOT NULL,
    CONSTRAINT region_pk PRIMARY KEY (id_region)
);

-- PK IDENTITY: Oracle genera el id solo: 210, 212, 214...
CREATE TABLE nacionalidad (
    id_nacion   NUMBER(3) GENERATED ALWAYS AS IDENTITY (START WITH 210 INCREMENT BY 2),
    descripcion VARCHAR2(30) NOT NULL,
    CONSTRAINT nacionalidad_pk PRIMARY KEY (id_nacion)
);

-- CHECK: tipo solo puede ser P (profesional) o A (amateur)
CREATE TABLE asociacion (
    id_asociacion     NUMBER(3)    NOT NULL,
    nombre_asociacion VARCHAR2(60) NOT NULL,
    fecha_creacion    DATE         NOT NULL,
    tipo_asociacion   CHAR(1)      NOT NULL,
    CONSTRAINT asociacion_pk PRIMARY KEY (id_asociacion),
    CONSTRAINT asociacion_tipo_ck CHECK (tipo_asociacion IN ('P', 'A'))
);

-- DEFAULT: si no se indica tipo_club, queda 'Profesional'
CREATE TABLE club_futbol (
    id_club         NUMBER(4)    NOT NULL,
    nombre_club     VARCHAR2(50) NOT NULL,
    patrimonio      NUMBER(12)   NOT NULL,
    ubicacion_calle VARCHAR2(50) NOT NULL,
    tipo_club       VARCHAR2(20) DEFAULT 'Profesional' NOT NULL,
    CONSTRAINT club_futbol_pk PRIMARY KEY (id_club),
    CONSTRAINT club_futbol_tipo_ck CHECK (tipo_club IN ('Profesional', 'Amateur'))
);

CREATE TABLE estado_civil (
    id_estado_civil NUMBER(2)    NOT NULL,
    descripcion     VARCHAR2(20) NOT NULL,
    CONSTRAINT estado_civil_pk PRIMARY KEY (id_estado_civil)
);

CREATE TABLE escuela_futbol (
    id_escuela      NUMBER(4)    NOT NULL,
    nombre_escuela  VARCHAR2(50) NOT NULL,
    capacidad       NUMBER(5)    NOT NULL,
    fecha_fundacion DATE         NOT NULL,
    CONSTRAINT escuela_futbol_pk PRIMARY KEY (id_escuela),
    CONSTRAINT escuela_futbol_capacidad_ck CHECK (capacidad > 0)
);

CREATE TABLE puesto (
    id_puesto   NUMBER(3)    NOT NULL,
    descripcion VARCHAR2(30) NOT NULL,
    CONSTRAINT puesto_pk PRIMARY KEY (id_puesto)
);

CREATE TABLE idioma (
    id_idioma     NUMBER(3)    NOT NULL,
    nombre_idioma VARCHAR2(30) NOT NULL,
    CONSTRAINT idioma_pk PRIMARY KEY (id_idioma)
);

-- SECUENCIA para el código del club: 703, 707, 711...
CREATE SEQUENCE seq_club START WITH 703 INCREMENT BY 4;

-- ===== BLOQUE 2: COMUNA Y TRABAJADOR =====
CREATE TABLE comuna (
    id_comuna NUMBER(4)    NOT NULL,
    nombre    VARCHAR2(50) NOT NULL,
    id_region NUMBER(2)    NOT NULL,
    CONSTRAINT comuna_pk PRIMARY KEY (id_comuna),
    CONSTRAINT comuna_region_fk FOREIGN KEY (id_region)
        REFERENCES region (id_region)
);

CREATE TABLE trabajador (
    nro_inscripcion  NUMBER(9)    NOT NULL,
    rut              NUMBER(8)    NOT NULL,
    dv               CHAR(1)      NOT NULL,
    nombres          VARCHAR2(50) NOT NULL,
    ap_paterno       VARCHAR2(30) NOT NULL,
    ap_materno       VARCHAR2(30) NOT NULL,
    sueldo_base      NUMBER(10)   NOT NULL,
    fecha_nacimiento DATE         NOT NULL,
    genero           CHAR(1)      NOT NULL,
    telefono         VARCHAR2(15) NOT NULL,
    email            VARCHAR2(60),
    direccion        VARCHAR2(80) NOT NULL,
    id_comuna        NUMBER(4)    NOT NULL,
    id_estado_civil  NUMBER(2)    NOT NULL,
    id_nacion        NUMBER(3)    NOT NULL,
    CONSTRAINT trabajador_pk PRIMARY KEY (nro_inscripcion),
    CONSTRAINT trabajador_rut_un UNIQUE (rut),
    CONSTRAINT trabajador_genero_ck CHECK (genero IN ('M', 'F')),
    CONSTRAINT trabajador_sueldo_ck CHECK (sueldo_base > 0),
    CONSTRAINT trabajador_comuna_fk FOREIGN KEY (id_comuna)
        REFERENCES comuna (id_comuna),
    CONSTRAINT trabajador_estado_civil_fk FOREIGN KEY (id_estado_civil)
        REFERENCES estado_civil (id_estado_civil),
    CONSTRAINT trabajador_nacionalidad_fk FOREIGN KEY (id_nacion)
        REFERENCES nacionalidad (id_nacion)
);

-- ===== BLOQUE 3: SUBTIPOS =====
-- La PK de cada subtipo es también FK a TRABAJADOR (relación 1 a 1 con el supertipo)
CREATE TABLE jugador (
    nro_inscripcion NUMBER(9)  NOT NULL,
    monto_premios   NUMBER(12) DEFAULT 0 NOT NULL,
    anio_egreso     NUMBER(4),
    id_puesto       NUMBER(3)  NOT NULL,
    id_asociacion   NUMBER(3)  NOT NULL,
    id_escuela      NUMBER(4),
    CONSTRAINT jugador_pk PRIMARY KEY (nro_inscripcion),
    CONSTRAINT jugador_premios_ck CHECK (monto_premios >= 0),
    CONSTRAINT jugador_trabajador_fk FOREIGN KEY (nro_inscripcion)
        REFERENCES trabajador (nro_inscripcion),
    CONSTRAINT jugador_puesto_fk FOREIGN KEY (id_puesto)
        REFERENCES puesto (id_puesto),
    CONSTRAINT jugador_asociacion_fk FOREIGN KEY (id_asociacion)
        REFERENCES asociacion (id_asociacion),
    CONSTRAINT jugador_escuela_futbol_fk FOREIGN KEY (id_escuela)
        REFERENCES escuela_futbol (id_escuela)
);

CREATE TABLE personal_planta (
    nro_inscripcion  NUMBER(9) NOT NULL,
    horas_trabajadas NUMBER(3),
    valor_hora_extra NUMBER(8),
    id_club          NUMBER(4) NOT NULL,
    CONSTRAINT personal_planta_pk PRIMARY KEY (nro_inscripcion),
    CONSTRAINT personal_planta_trabajador_fk FOREIGN KEY (nro_inscripcion)
        REFERENCES trabajador (nro_inscripcion),
    CONSTRAINT personal_planta_club_futbol_fk FOREIGN KEY (id_club)
        REFERENCES club_futbol (id_club)
);

-- ===== BLOQUE 4: TABLAS INTERMEDIAS =====
-- PK compuesta: un jugador puede volver al mismo club en otra fecha
CREATE TABLE historial_club (
    nro_inscripcion     NUMBER(9) NOT NULL,
    id_club             NUMBER(4) NOT NULL,
    fecha_incorporacion DATE      NOT NULL,
    fecha_fin_contrato  DATE,
    CONSTRAINT historial_club_pk PRIMARY KEY (nro_inscripcion, id_club, fecha_incorporacion),
    CONSTRAINT historial_club_fechas_ck CHECK (fecha_fin_contrato > fecha_incorporacion),
    CONSTRAINT historial_club_jugador_fk FOREIGN KEY (nro_inscripcion)
        REFERENCES jugador (nro_inscripcion),
    CONSTRAINT historial_club_club_futbol_fk FOREIGN KEY (id_club)
        REFERENCES club_futbol (id_club)
);

-- PK compuesta: un jugador no puede tener el mismo idioma dos veces
CREATE TABLE dominio_idioma (
    nro_inscripcion NUMBER(9)    NOT NULL,
    id_idioma       NUMBER(3)    NOT NULL,
    nivel           VARCHAR2(20) NOT NULL,
    CONSTRAINT dominio_idioma_pk PRIMARY KEY (nro_inscripcion, id_idioma),
    CONSTRAINT dominio_idioma_nivel_ck CHECK (nivel IN ('Basico', 'Intermedio', 'Avanzado')),
    CONSTRAINT dominio_idioma_jugador_fk FOREIGN KEY (nro_inscripcion)
        REFERENCES jugador (nro_inscripcion),
    CONSTRAINT dominio_idioma_idioma_fk FOREIGN KEY (id_idioma)
        REFERENCES idioma (id_idioma)
);

-- ===== BLOQUE 5: MODIFICACIONES DEL MODELO FÍSICO =====
-- El nombre del club debe ser único
ALTER TABLE club_futbol
    ADD CONSTRAINT club_futbol_nombre_un UNIQUE (nombre_club);

-- La fecha de creación debe ser igual o posterior al 31-12-1980
ALTER TABLE asociacion
    ADD CONSTRAINT asociacion_fecha_ck
    CHECK (fecha_creacion >= TO_DATE('31-12-1980', 'DD-MM-YYYY'));
    
    -- ===== BLOQUE 6: POBLAMIENTO =====
-- REGION (las 5 de la Figura 2)
INSERT INTO region (id_region, nombre) VALUES (1, 'ARICA Y PARINACOTA Y TARAPACA');
INSERT INTO region (id_region, nombre) VALUES (2, 'ANTOFAGASTA');
INSERT INTO region (id_region, nombre) VALUES (3, 'ATACAMA Y COQUIMBO');
INSERT INTO region (id_region, nombre) VALUES (5, 'VALPARAISO');
INSERT INTO region (id_region, nombre) VALUES (13, 'METROPOLITANA');
-- Regiones agregadas según anuncio del docente (las usan Concepción y Chillán)
INSERT INTO region (id_region, nombre) VALUES (8, 'BIOBIO');
INSERT INTO region (id_region, nombre) VALUES (16, 'NUBLE');

-- COMUNA
INSERT INTO comuna (id_comuna, nombre, id_region) VALUES (101, 'Santiago', 13);
INSERT INTO comuna (id_comuna, nombre, id_region) VALUES (102, 'Valparaíso', 5);
INSERT INTO comuna (id_comuna, nombre, id_region) VALUES (103, 'Concepción', 8);
INSERT INTO comuna (id_comuna, nombre, id_region) VALUES (104, 'Antofagasta', 2);
INSERT INTO comuna (id_comuna, nombre, id_region) VALUES (105, 'Chillán', 16);

-- ASOCIACION
INSERT INTO asociacion VALUES (25, 'Asociación de Fútbol de Santiago', TO_DATE('15-05-2001', 'DD-MM-YYYY'), 'P');
INSERT INTO asociacion VALUES (26, 'Asociación Nacional de Fútbol Amateur', TO_DATE('10-03-1998', 'DD-MM-YYYY'), 'A');
INSERT INTO asociacion VALUES (27, 'Asociación de Fútbol de Valparaíso', TO_DATE('21-07-1987', 'DD-MM-YYYY'), 'P');
INSERT INTO asociacion VALUES (28, 'Asociación de Fútbol de Concepción', TO_DATE('30-11-1995', 'DD-MM-YYYY'), 'A');
INSERT INTO asociacion VALUES (29, 'Asociación de Fútbol de Antofagasta', TO_DATE('25-06-2003', 'DD-MM-YYYY'), 'P');
INSERT INTO asociacion VALUES (30, 'Asociación de Fútbol de Temuco', TO_DATE('12-01-2010', 'DD-MM-YYYY'), 'A');
INSERT INTO asociacion VALUES (31, 'Asociación de Fútbol de Rancagua', TO_DATE('08-09-1999', 'DD-MM-YYYY'), 'P');
INSERT INTO asociacion VALUES (32, 'Asociación de Fútbol de Puerto Montt', TO_DATE('20-04-2005', 'DD-MM-YYYY'), 'A');
INSERT INTO asociacion VALUES (33, 'Asociación de Fútbol de La Serena', TO_DATE('14-08-2012', 'DD-MM-YYYY'), 'P');
INSERT INTO asociacion VALUES (34, 'Asociación de Fútbol de Chillán', TO_DATE('01-12-2018', 'DD-MM-YYYY'), 'A');

-- NACIONALIDAD: no se indica el id, lo genera el IDENTITY (210, 212, 214...)
INSERT INTO nacionalidad (descripcion) VALUES ('Chilena');
INSERT INTO nacionalidad (descripcion) VALUES ('Argentina');
INSERT INTO nacionalidad (descripcion) VALUES ('Peruana');
INSERT INTO nacionalidad (descripcion) VALUES ('Boliviana');
INSERT INTO nacionalidad (descripcion) VALUES ('Brasileña');

-- CLUB_FUTBOL: el id lo da la secuencia (703, 707...) y tipo_club lo completa el DEFAULT
INSERT INTO club_futbol (id_club, nombre_club, patrimonio, ubicacion_calle)
VALUES (seq_club.NEXTVAL, 'Colo-Colo', 500000000, 'Av. Marathon 5300');
INSERT INTO club_futbol (id_club, nombre_club, patrimonio, ubicacion_calle)
VALUES (seq_club.NEXTVAL, 'Universidad de Chile', 450000000, 'Av. El Parrón 0931');
INSERT INTO club_futbol (id_club, nombre_club, patrimonio, ubicacion_calle)
VALUES (seq_club.NEXTVAL, 'Deportes Antofagasta', 180000000, 'Avenida Angamos 01606');
INSERT INTO club_futbol (id_club, nombre_club, patrimonio, ubicacion_calle)
VALUES (seq_club.NEXTVAL, 'Huachipato', 220000000, 'Avenida Desiderio García 909');
INSERT INTO club_futbol (id_club, nombre_club, patrimonio, ubicacion_calle)
VALUES (seq_club.NEXTVAL, 'Ñublense', 170000000, 'Avenida Pedro Aguirre Cerda 1003');

COMMIT;

-- ===== BLOQUE 7: INFORMES =====
-- Informe 1: asociaciones profesionales creadas después del año 2000
SELECT 'ID:' || id_asociacion || ' * ' || nombre_asociacion AS "ASOCIACION",
       TO_CHAR(fecha_creacion, 'DD-MM-YYYY') AS "CREADA",
       tipo_asociacion AS "TIPO"
FROM asociacion
WHERE tipo_asociacion = 'P'
  AND EXTRACT(YEAR FROM fecha_creacion) > 2000
ORDER BY fecha_creacion DESC;

-- Informe 2: patrimonio de clubes en pesos y en dólares ($955 por dólar)
SELECT id_club AS "CLUB",
       nombre_club AS "NOMBRE CLUB",
       patrimonio AS "PATRIMONIO EN PESOS",
       patrimonio / 955 AS "PATRIMONIO EN DOLARES"
FROM club_futbol
WHERE nombre_club LIKE '%a%'
  AND patrimonio > 200000000
  AND tipo_club = 'Profesional'
ORDER BY id_club DESC;




