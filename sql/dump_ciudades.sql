
CREATE TABLE public.localidades (
    id serial NOT NULL,
    nombre character varying(60) NOT NULL,
    cp integer NOT NULL,
    id_provincia integer NOT NULL
);

CREATE TABLE public.paises (
    id serial NOT NULL,
    nombre character varying(60) NOT NULL,
    nacionalidad character varying(60) NOT NULL
);

CREATE TABLE public.provincias (
    id serial NOT NULL,
    nombre character varying NOT NULL,
    id_pais integer NOT NULL
);

INSERT INTO public.localidades VALUES (1, 'LUJAN', 3450, 7);
SELECT pg_catalog.setval('public.localidades_id_seq', 1, true);

INSERT INTO public.paises VALUES (1, 'Argentina', 'Argentino');
SELECT pg_catalog.setval('public.paises_id_seq', 1, true);

INSERT INTO public.provincias VALUES (1, 'Buenos Aires', 1);
INSERT INTO public.provincias VALUES (2, 'Capital Federal', 1);
INSERT INTO public.provincias VALUES (3, 'Catamarca', 1);
INSERT INTO public.provincias VALUES (4, 'Chaco', 1);
INSERT INTO public.provincias VALUES (5, 'Chubut', 1);
INSERT INTO public.provincias VALUES (6, 'Cordoba', 1);
INSERT INTO public.provincias VALUES (7, 'Corrientes', 1);
INSERT INTO public.provincias VALUES (8, 'Entre RÃ­os', 1);
INSERT INTO public.provincias VALUES (9, 'Formosa', 1);
INSERT INTO public.provincias VALUES (10, 'Jujuy', 1);
INSERT INTO public.provincias VALUES (11, 'La Pampa', 1);
INSERT INTO public.provincias VALUES (12, 'La Rioja', 1);
INSERT INTO public.provincias VALUES (13, 'Mendoza', 1);
INSERT INTO public.provincias VALUES (14, 'Misiones', 1);
INSERT INTO public.provincias VALUES (15, 'Neuquén', 1);
INSERT INTO public.provincias VALUES (16, 'Río Negro', 1);
INSERT INTO public.provincias VALUES (17, 'Salta', 1);
INSERT INTO public.provincias VALUES (18, 'San Juan', 1);
INSERT INTO public.provincias VALUES (19, 'San Luis', 1);
INSERT INTO public.provincias VALUES (20, 'Santa Cruz', 1);
INSERT INTO public.provincias VALUES (21, 'Santa Fé', 1);
INSERT INTO public.provincias VALUES (22, 'Santiago del Estero', 1);
INSERT INTO public.provincias VALUES (23, 'Tierra del Fuego', 1);
INSERT INTO public.provincias VALUES (24, 'Tucumán', 1);
SELECT pg_catalog.setval('public.provincias_id_seq', 24, true);


ALTER TABLE ONLY public.localidades ADD CONSTRAINT pk_localidad PRIMARY KEY (id);
ALTER TABLE ONLY public.paises ADD CONSTRAINT pk_paises PRIMARY KEY (id);
ALTER TABLE ONLY public.provincias ADD CONSTRAINT pk_provincias PRIMARY KEY (id);

ALTER TABLE ONLY public.localidades ADD CONSTRAINT fk_localidad_provincia FOREIGN KEY (id_provincia) REFERENCES public.provincias(id);
ALTER TABLE ONLY public.provincias ADD CONSTRAINT fk_provincias_pais FOREIGN KEY (id_pais) REFERENCES public.paises(id);
