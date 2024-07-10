--
-- PostgreSQL database dump
--

-- Dumped from database version 16.0
-- Dumped by pg_dump version 16.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: Medya; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA "Medya";


ALTER SCHEMA "Medya" OWNER TO postgres;

--
-- Name: add_user(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_user(user_name character varying, user_email character varying, user_password character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO "Kullanici" ("adi", "e-posta", "sifre")
    VALUES (user_name, user_email, user_password);
END;
$$;


ALTER FUNCTION public.add_user(user_name character varying, user_email character varying, user_password character varying) OWNER TO postgres;

--
-- Name: check_password_strength(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_password_strength() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW."sifre" IS NOT NULL THEN
        IF LENGTH(NEW."sifre") < 8 OR NOT (
            (NEW."sifre" ~ '\d') AND   -- En az bir rakam içermeli
            (NEW."sifre" ~ '[A-Z]') AND  -- En az bir büyük harf içermeli
            (NEW."sifre" ~ '[a-z]')     -- En az bir küçük harf içermeli
        ) THEN
            RAISE EXCEPTION 'Şifre güvenlik kriterlerini karşılamıyor.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_password_strength() OWNER TO postgres;

--
-- Name: check_unique_director_name(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_unique_director_name() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW."director_name" IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM "Yonetmen" WHERE "director_name" = NEW."director_name") THEN
            RAISE EXCEPTION 'Bu yönetmen adı zaten kullanılmaktadır.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_unique_director_name() OWNER TO postgres;

--
-- Name: check_unique_username(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_unique_username() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- NEW kaydının içinde "username" alanı var mı kontrol et
    IF NEW IS NOT NULL AND NEW."username" IS NOT NULL THEN
        -- "Kullanici" tablosunda aynı kullanıcı adı var mı kontrol et
        IF EXISTS (SELECT 1 FROM "Kullanici" WHERE "username" = NEW."username") THEN
            RAISE EXCEPTION 'Kullanıcı adı zaten kullanılmakta';
        END IF;
    END IF;

    -- Tetikleyiciyi çağırdığımızda RETURN NEW kullanmamız gerekiyor
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_unique_username() OWNER TO postgres;

--
-- Name: delete_media_with_ratings(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_media_with_ratings() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM "MedyaYildizlari" WHERE "MedyaID" = OLD."id";
    RETURN OLD;
END;
$$;


ALTER FUNCTION public.delete_media_with_ratings() OWNER TO postgres;

--
-- Name: delete_media_with_ratings(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_media_with_ratings(media_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- "MedyaYildizlari" tablosundan ilişkili kayıtları sil
    DELETE FROM "MedyaYildizlari" WHERE "MedyaID" = media_id;

    -- "Medya" tablosundan kaydı sil
    DELETE FROM "Medya"."Medya" WHERE "id" = media_id;
END;
$$;


ALTER FUNCTION public.delete_media_with_ratings(media_id integer) OWNER TO postgres;

--
-- Name: delete_user(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_user(user_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM "Kullanici"
    WHERE "id" = user_id;
END;
$$;


ALTER FUNCTION public.delete_user(user_id integer) OWNER TO postgres;

--
-- Name: search_media_by_genre(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.search_media_by_genre(media_genre_id integer) RETURNS TABLE(id integer, isim character varying, yayintarihi date, medyatipi character varying, turid integer, yazarid integer, sirketid integer, yonetmenid integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        id,
        isim,
        yayinTarihi,
        MedyaTipi,
        TurID,
        YazarID,
        SirketID,
        YonetmenID
    FROM
        "Medya"."Medya"
    WHERE
        "Medya"."Medya".TurID = media_genre_id;
END;
$$;


ALTER FUNCTION public.search_media_by_genre(media_genre_id integer) OWNER TO postgres;

--
-- Name: search_user(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.search_user(user_name character varying) RETURNS TABLE(id integer, adi character varying, "e-posta" character varying, sifre character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT "id", "adi", "e-posta", "sifre"
    FROM "Kullanici"
    WHERE "adi" ILIKE '%' || user_name || '%';
END;
$$;


ALTER FUNCTION public.search_user(user_name character varying) OWNER TO postgres;

--
-- Name: unique_email_check(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.unique_email_check() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW."e-posta" IS NOT NULL THEN
        IF EXISTS (
            SELECT 1
            FROM "Kullanici"
            WHERE "e-posta" = NEW."e-posta"
            AND "id" <> NEW."id"  -- Mevcut kullanıcının güncellenmesi durumunda kendi e-postasını kontrol etme
        ) THEN
            RAISE EXCEPTION 'Bu e-posta zaten kullanımda.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.unique_email_check() OWNER TO postgres;

--
-- Name: update_media(integer, character varying, character, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_media(media_id integer, media_name character varying, media_type character, media_genre integer, media_author integer, media_sirket integer, media_director integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE "Medya"."Medya"
    SET
        "isim" = media_name,
        "MedyaTipi" = media_type,
        "TurID" = media_genre,
        "YazarID" = media_author,
        "SirketID" = media_sirket,
        "YonetmenID"= media_director

    WHERE
        "id" = media_id;
END;
$$;


ALTER FUNCTION public.update_media(media_id integer, media_name character varying, media_type character, media_genre integer, media_author integer, media_sirket integer, media_director integer) OWNER TO postgres;

--
-- Name: update_user(integer, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_user(user_id integer, new_name character varying, new_email character varying, new_password character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE "Kullanici"
    SET
        "adi" = new_name,
        "e-posta" = new_email,
        "sifre" = new_password
    WHERE "id" = user_id;
END;
$$;


ALTER FUNCTION public.update_user(user_id integer, new_name character varying, new_email character varying, new_password character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: Dizi; Type: TABLE; Schema: Medya; Owner: postgres
--

CREATE TABLE "Medya"."Dizi" (
    id integer NOT NULL,
    "bolumSayisi" integer,
    "sezonSayisi" integer DEFAULT 1 NOT NULL
);


ALTER TABLE "Medya"."Dizi" OWNER TO postgres;

--
-- Name: Film; Type: TABLE; Schema: Medya; Owner: postgres
--

CREATE TABLE "Medya"."Film" (
    id integer NOT NULL,
    suresi integer,
    "sezonSayisi" integer DEFAULT 1 NOT NULL
);


ALTER TABLE "Medya"."Film" OWNER TO postgres;

--
-- Name: Medya; Type: TABLE; Schema: Medya; Owner: postgres
--

CREATE TABLE "Medya"."Medya" (
    id integer NOT NULL,
    isim character varying(80) NOT NULL,
    "yayinTarihi" date,
    "MedyaTipi" character(1) NOT NULL,
    "TurID" integer NOT NULL,
    "YazarID" integer NOT NULL,
    "SirketID" integer,
    "YonetmenID" integer NOT NULL
);


ALTER TABLE "Medya"."Medya" OWNER TO postgres;

--
-- Name: Medya_id_seq; Type: SEQUENCE; Schema: Medya; Owner: postgres
--

CREATE SEQUENCE "Medya"."Medya_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "Medya"."Medya_id_seq" OWNER TO postgres;

--
-- Name: Medya_id_seq; Type: SEQUENCE OWNED BY; Schema: Medya; Owner: postgres
--

ALTER SEQUENCE "Medya"."Medya_id_seq" OWNED BY "Medya"."Medya".id;


--
-- Name: Degerlendirme; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Degerlendirme" (
    id integer NOT NULL,
    puan integer,
    "KullaniciID" integer NOT NULL,
    "MedyaID" integer NOT NULL
);


ALTER TABLE public."Degerlendirme" OWNER TO postgres;

--
-- Name: Degerlendirme_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Degerlendirme_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Degerlendirme_id_seq" OWNER TO postgres;

--
-- Name: Degerlendirme_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Degerlendirme_id_seq" OWNED BY public."Degerlendirme".id;


--
-- Name: Favorite; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Favorite" (
    id integer NOT NULL,
    "KullaniciID" integer NOT NULL,
    "MedyaID" integer NOT NULL
);


ALTER TABLE public."Favorite" OWNER TO postgres;

--
-- Name: Favorite_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Favorite_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Favorite_id_seq" OWNER TO postgres;

--
-- Name: Favorite_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Favorite_id_seq" OWNED BY public."Favorite".id;


--
-- Name: FilminOduller; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."FilminOduller" (
    "FilmID" integer NOT NULL,
    "OdulID" integer NOT NULL
);


ALTER TABLE public."FilminOduller" OWNER TO postgres;

--
-- Name: Kullanici; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Kullanici" (
    id integer NOT NULL,
    adi character varying(40) NOT NULL,
    "e-posta" character varying(40) NOT NULL,
    sifre character varying(15) NOT NULL
);


ALTER TABLE public."Kullanici" OWNER TO postgres;

--
-- Name: Kullanici_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Kullanici_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Kullanici_id_seq" OWNER TO postgres;

--
-- Name: Kullanici_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Kullanici_id_seq" OWNED BY public."Kullanici".id;


--
-- Name: MedyaYildizlari; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."MedyaYildizlari" (
    "OyuncuID" integer NOT NULL,
    "MedyaID" integer NOT NULL
);


ALTER TABLE public."MedyaYildizlari" OWNER TO postgres;

--
-- Name: Odul; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Odul" (
    id integer NOT NULL,
    isim character varying(40) NOT NULL,
    veren character varying(40)
);


ALTER TABLE public."Odul" OWNER TO postgres;

--
-- Name: Odul_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Odul_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Odul_id_seq" OWNER TO postgres;

--
-- Name: Odul_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Odul_id_seq" OWNED BY public."Odul".id;


--
-- Name: Oyuncu; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Oyuncu" (
    id integer NOT NULL,
    isim character varying(40) NOT NULL,
    soyadi character varying(40)
);


ALTER TABLE public."Oyuncu" OWNER TO postgres;

--
-- Name: Oyuncu_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Oyuncu_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Oyuncu_id_seq" OWNER TO postgres;

--
-- Name: Oyuncu_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Oyuncu_id_seq" OWNED BY public."Oyuncu".id;


--
-- Name: Turler; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Turler" (
    id integer NOT NULL,
    isim character varying(15) NOT NULL
);


ALTER TABLE public."Turler" OWNER TO postgres;

--
-- Name: Turler_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Turler_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Turler_id_seq" OWNER TO postgres;

--
-- Name: Turler_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Turler_id_seq" OWNED BY public."Turler".id;


--
-- Name: UretimSirketi; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."UretimSirketi" (
    id integer NOT NULL,
    isim character varying(40) NOT NULL,
    "KurulusTarihi" date
);


ALTER TABLE public."UretimSirketi" OWNER TO postgres;

--
-- Name: UretimSirketi_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."UretimSirketi_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."UretimSirketi_id_seq" OWNER TO postgres;

--
-- Name: UretimSirketi_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."UretimSirketi_id_seq" OWNED BY public."UretimSirketi".id;


--
-- Name: Yazar; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Yazar" (
    id integer NOT NULL,
    isim character varying(40) NOT NULL,
    soyadi character varying(40)
);


ALTER TABLE public."Yazar" OWNER TO postgres;

--
-- Name: Yazar_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Yazar_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Yazar_id_seq" OWNER TO postgres;

--
-- Name: Yazar_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Yazar_id_seq" OWNED BY public."Yazar".id;


--
-- Name: Yonetmen; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Yonetmen" (
    id integer NOT NULL,
    isim character varying(40) NOT NULL,
    soyadi character varying(40)
);


ALTER TABLE public."Yonetmen" OWNER TO postgres;

--
-- Name: Yonetmen_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Yonetmen_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Yonetmen_id_seq" OWNER TO postgres;

--
-- Name: Yonetmen_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Yonetmen_id_seq" OWNED BY public."Yonetmen".id;


--
-- Name: izlemeListesi; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."izlemeListesi" (
    id integer NOT NULL,
    "izlenildigiTarihi" date,
    "KullaniciID" integer NOT NULL,
    "MedyaID" integer NOT NULL
);


ALTER TABLE public."izlemeListesi" OWNER TO postgres;

--
-- Name: izlemeListesi_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."izlemeListesi_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."izlemeListesi_id_seq" OWNER TO postgres;

--
-- Name: izlemeListesi_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."izlemeListesi_id_seq" OWNED BY public."izlemeListesi".id;


--
-- Name: Medya id; Type: DEFAULT; Schema: Medya; Owner: postgres
--

ALTER TABLE ONLY "Medya"."Medya" ALTER COLUMN id SET DEFAULT nextval('"Medya"."Medya_id_seq"'::regclass);


--
-- Name: Degerlendirme id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Degerlendirme" ALTER COLUMN id SET DEFAULT nextval('public."Degerlendirme_id_seq"'::regclass);


--
-- Name: Favorite id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Favorite" ALTER COLUMN id SET DEFAULT nextval('public."Favorite_id_seq"'::regclass);


--
-- Name: Kullanici id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Kullanici" ALTER COLUMN id SET DEFAULT nextval('public."Kullanici_id_seq"'::regclass);


--
-- Name: Odul id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Odul" ALTER COLUMN id SET DEFAULT nextval('public."Odul_id_seq"'::regclass);


--
-- Name: Oyuncu id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Oyuncu" ALTER COLUMN id SET DEFAULT nextval('public."Oyuncu_id_seq"'::regclass);


--
-- Name: Turler id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Turler" ALTER COLUMN id SET DEFAULT nextval('public."Turler_id_seq"'::regclass);


--
-- Name: UretimSirketi id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UretimSirketi" ALTER COLUMN id SET DEFAULT nextval('public."UretimSirketi_id_seq"'::regclass);


--
-- Name: Yazar id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Yazar" ALTER COLUMN id SET DEFAULT nextval('public."Yazar_id_seq"'::regclass);


--
-- Name: Yonetmen id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Yonetmen" ALTER COLUMN id SET DEFAULT nextval('public."Yonetmen_id_seq"'::regclass);


--
-- Name: izlemeListesi id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."izlemeListesi" ALTER COLUMN id SET DEFAULT nextval('public."izlemeListesi_id_seq"'::regclass);


--
-- Data for Name: Dizi; Type: TABLE DATA; Schema: Medya; Owner: postgres
--

COPY "Medya"."Dizi" (id, "bolumSayisi", "sezonSayisi") FROM stdin;
111	20	3
112	40	1
\.


--
-- Data for Name: Film; Type: TABLE DATA; Schema: Medya; Owner: postgres
--

COPY "Medya"."Film" (id, suresi, "sezonSayisi") FROM stdin;
71	45	7
\.


--
-- Data for Name: Medya; Type: TABLE DATA; Schema: Medya; Owner: postgres
--

COPY "Medya"."Medya" (id, isim, "yayinTarihi", "MedyaTipi", "TurID", "YazarID", "SirketID", "YonetmenID") FROM stdin;
71	Yeni İsim	1990-09-09	F	2	1	2	3
112	Örnek Medya	2023-01-01	F	1	1	1	1
111	dizi11	\N	D	2	2	1	1
\.


--
-- Data for Name: Degerlendirme; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Degerlendirme" (id, puan, "KullaniciID", "MedyaID") FROM stdin;
\.


--
-- Data for Name: Favorite; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Favorite" (id, "KullaniciID", "MedyaID") FROM stdin;
\.


--
-- Data for Name: FilminOduller; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."FilminOduller" ("FilmID", "OdulID") FROM stdin;
\.


--
-- Data for Name: Kullanici; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Kullanici" (id, adi, "e-posta", sifre) FROM stdin;
2	John Doe	john@example.com	password123
5	Alice Smith	alice@example.com	password456
8	Charlie Brown	charlie@example.com	passwordXYZ
1	manar	yeniemail@example.com	mM4mmmmm
18	fatma	fatma@gmail.com	Fatmapassword1
20	kullanici	kullanici@hotmail.com	Pasword11
22	isim	isim@ima	sdA44444
\.


--
-- Data for Name: MedyaYildizlari; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."MedyaYildizlari" ("OyuncuID", "MedyaID") FROM stdin;
\.


--
-- Data for Name: Odul; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Odul" (id, isim, veren) FROM stdin;
\.


--
-- Data for Name: Oyuncu; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Oyuncu" (id, isim, soyadi) FROM stdin;
1	Daniel 	Stern
2	Joe	Pesci
3	Macaulay 	Culkin
4	Leonardo	DiCaprio
\.


--
-- Data for Name: Turler; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Turler" (id, isim) FROM stdin;
1	comedy
2	family
3	Adventure
4	Bilim Kurgu
\.


--
-- Data for Name: UretimSirketi; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."UretimSirketi" (id, isim, "KurulusTarihi") FROM stdin;
1	Paramount Pictures	\N
2	Warner Bros.	1923-04-04
\.


--
-- Data for Name: Yazar; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Yazar" (id, isim, soyadi) FROM stdin;
1	John 	Hughes
2	Jonathan	Nolan
3	Jonathan	Nolan
\.


--
-- Data for Name: Yonetmen; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Yonetmen" (id, isim, soyadi) FROM stdin;
1	Chris 	Columbus
2	Christopher	Nolan
3	Christopher	Nolan
\.


--
-- Data for Name: izlemeListesi; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."izlemeListesi" (id, "izlenildigiTarihi", "KullaniciID", "MedyaID") FROM stdin;
\.


--
-- Name: Medya_id_seq; Type: SEQUENCE SET; Schema: Medya; Owner: postgres
--

SELECT pg_catalog.setval('"Medya"."Medya_id_seq"', 112, true);


--
-- Name: Degerlendirme_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Degerlendirme_id_seq"', 1, false);


--
-- Name: Favorite_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Favorite_id_seq"', 1, false);


--
-- Name: Kullanici_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Kullanici_id_seq"', 22, true);


--
-- Name: Odul_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Odul_id_seq"', 1, false);


--
-- Name: Oyuncu_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Oyuncu_id_seq"', 4, true);


--
-- Name: Turler_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Turler_id_seq"', 4, true);


--
-- Name: UretimSirketi_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."UretimSirketi_id_seq"', 2, true);


--
-- Name: Yazar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Yazar_id_seq"', 3, true);


--
-- Name: Yonetmen_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Yonetmen_id_seq"', 3, true);


--
-- Name: izlemeListesi_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."izlemeListesi_id_seq"', 1, false);


--
-- Name: Dizi DiziPK; Type: CONSTRAINT; Schema: Medya; Owner: postgres
--

ALTER TABLE ONLY "Medya"."Dizi"
    ADD CONSTRAINT "DiziPK" PRIMARY KEY (id);


--
-- Name: Film FilmPK; Type: CONSTRAINT; Schema: Medya; Owner: postgres
--

ALTER TABLE ONLY "Medya"."Film"
    ADD CONSTRAINT "FilmPK" PRIMARY KEY (id);


--
-- Name: Medya MedyaPK; Type: CONSTRAINT; Schema: Medya; Owner: postgres
--

ALTER TABLE ONLY "Medya"."Medya"
    ADD CONSTRAINT "MedyaPK" PRIMARY KEY (id);


--
-- Name: Degerlendirme Degerlendirme_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Degerlendirme"
    ADD CONSTRAINT "Degerlendirme_pkey" PRIMARY KEY (id);


--
-- Name: Favorite Favorite_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Favorite"
    ADD CONSTRAINT "Favorite_pkey" PRIMARY KEY (id);


--
-- Name: Kullanici Kullanici_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Kullanici"
    ADD CONSTRAINT "Kullanici_pkey" PRIMARY KEY (id);


--
-- Name: Odul Odul_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Odul"
    ADD CONSTRAINT "Odul_pkey" PRIMARY KEY (id);


--
-- Name: Oyuncu Oyuncu_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Oyuncu"
    ADD CONSTRAINT "Oyuncu_pkey" PRIMARY KEY (id);


--
-- Name: Turler Turler_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Turler"
    ADD CONSTRAINT "Turler_pkey" PRIMARY KEY (id);


--
-- Name: UretimSirketi UretimSirketi_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UretimSirketi"
    ADD CONSTRAINT "UretimSirketi_pkey" PRIMARY KEY (id);


--
-- Name: Yazar Yazar_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Yazar"
    ADD CONSTRAINT "Yazar_pkey" PRIMARY KEY (id);


--
-- Name: Yonetmen Yonetmen_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Yonetmen"
    ADD CONSTRAINT "Yonetmen_pkey" PRIMARY KEY (id);


--
-- Name: izlemeListesi izlemeListesi_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."izlemeListesi"
    ADD CONSTRAINT "izlemeListesi_pkey" PRIMARY KEY (id);


--
-- Name: Medya on_delete_media_with_ratings; Type: TRIGGER; Schema: Medya; Owner: postgres
--

CREATE TRIGGER on_delete_media_with_ratings BEFORE DELETE ON "Medya"."Medya" FOR EACH ROW EXECUTE FUNCTION public.delete_media_with_ratings();


--
-- Name: Kullanici password_strength_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER password_strength_trigger BEFORE INSERT OR UPDATE ON public."Kullanici" FOR EACH ROW EXECUTE FUNCTION public.check_password_strength();


--
-- Name: Yonetmen unique_director_name_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unique_director_name_trigger BEFORE INSERT OR UPDATE ON public."Yonetmen" FOR EACH ROW EXECUTE FUNCTION public.check_unique_director_name();


--
-- Name: Kullanici unique_email_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unique_email_trigger BEFORE INSERT OR UPDATE ON public."Kullanici" FOR EACH ROW EXECUTE FUNCTION public.unique_email_check();


--
-- Name: Medya FK_Medya_Sirket; Type: FK CONSTRAINT; Schema: Medya; Owner: postgres
--

ALTER TABLE ONLY "Medya"."Medya"
    ADD CONSTRAINT "FK_Medya_Sirket" FOREIGN KEY ("SirketID") REFERENCES public."UretimSirketi"(id);


--
-- Name: Medya FK_Medya_Tur; Type: FK CONSTRAINT; Schema: Medya; Owner: postgres
--

ALTER TABLE ONLY "Medya"."Medya"
    ADD CONSTRAINT "FK_Medya_Tur" FOREIGN KEY ("TurID") REFERENCES public."Turler"(id);


--
-- Name: Medya FK_Medya_Yazar; Type: FK CONSTRAINT; Schema: Medya; Owner: postgres
--

ALTER TABLE ONLY "Medya"."Medya"
    ADD CONSTRAINT "FK_Medya_Yazar" FOREIGN KEY ("YazarID") REFERENCES public."Yazar"(id);


--
-- Name: Medya FK_Medya_Yonetmen; Type: FK CONSTRAINT; Schema: Medya; Owner: postgres
--

ALTER TABLE ONLY "Medya"."Medya"
    ADD CONSTRAINT "FK_Medya_Yonetmen" FOREIGN KEY ("YonetmenID") REFERENCES public."Yonetmen"(id);


--
-- Name: Dizi MedyaDizi; Type: FK CONSTRAINT; Schema: Medya; Owner: postgres
--

ALTER TABLE ONLY "Medya"."Dizi"
    ADD CONSTRAINT "MedyaDizi" FOREIGN KEY (id) REFERENCES "Medya"."Medya"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Film MedyaFilm; Type: FK CONSTRAINT; Schema: Medya; Owner: postgres
--

ALTER TABLE ONLY "Medya"."Film"
    ADD CONSTRAINT "MedyaFilm" FOREIGN KEY (id) REFERENCES "Medya"."Medya"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: FilminOduller FK_Film; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FilminOduller"
    ADD CONSTRAINT "FK_Film" FOREIGN KEY ("FilmID") REFERENCES "Medya"."Film"(id);


--
-- Name: izlemeListesi FK_Kullanici; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."izlemeListesi"
    ADD CONSTRAINT "FK_Kullanici" FOREIGN KEY ("KullaniciID") REFERENCES public."Kullanici"(id);


--
-- Name: Favorite FK_Kullanici; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Favorite"
    ADD CONSTRAINT "FK_Kullanici" FOREIGN KEY ("KullaniciID") REFERENCES public."Kullanici"(id);


--
-- Name: Degerlendirme FK_Kullanici; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Degerlendirme"
    ADD CONSTRAINT "FK_Kullanici" FOREIGN KEY ("KullaniciID") REFERENCES public."Kullanici"(id);


--
-- Name: izlemeListesi FK_Medya; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."izlemeListesi"
    ADD CONSTRAINT "FK_Medya" FOREIGN KEY ("MedyaID") REFERENCES "Medya"."Medya"(id);


--
-- Name: Favorite FK_Medya; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Favorite"
    ADD CONSTRAINT "FK_Medya" FOREIGN KEY ("MedyaID") REFERENCES "Medya"."Medya"(id);


--
-- Name: Degerlendirme FK_Medya; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Degerlendirme"
    ADD CONSTRAINT "FK_Medya" FOREIGN KEY ("MedyaID") REFERENCES "Medya"."Medya"(id);


--
-- Name: MedyaYildizlari FK_Medya; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MedyaYildizlari"
    ADD CONSTRAINT "FK_Medya" FOREIGN KEY ("MedyaID") REFERENCES "Medya"."Medya"(id);


--
-- Name: MedyaYildizlari FK_MedyaYildizlari_Medya; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MedyaYildizlari"
    ADD CONSTRAINT "FK_MedyaYildizlari_Medya" FOREIGN KEY ("MedyaID") REFERENCES "Medya"."Medya"(id) ON DELETE CASCADE;


--
-- Name: FilminOduller FK_Odul; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FilminOduller"
    ADD CONSTRAINT "FK_Odul" FOREIGN KEY ("OdulID") REFERENCES public."Odul"(id);


--
-- Name: MedyaYildizlari FK_Oyuncu; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MedyaYildizlari"
    ADD CONSTRAINT "FK_Oyuncu" FOREIGN KEY ("OyuncuID") REFERENCES public."Oyuncu"(id);


--
-- PostgreSQL database dump complete
--

