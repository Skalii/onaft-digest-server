--
-- PostgreSQL database dump
--

-- Dumped from database version 12.0
-- Dumped by pg_dump version 12.0

-- Started on 2019-10-23 00:45:27

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
-- TOC entry 582 (class 1247 OID 16842)
-- Name: publication_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.publication_type AS ENUM (
    'Стаття'
);


ALTER TYPE public.publication_type OWNER TO postgres;

--
-- TOC entry 216 (class 1255 OID 16845)
-- Name: array_to_table(anyarray); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.array_to_table(_array anyarray) RETURNS SETOF anyelement
    LANGUAGE plpgsql
    AS $$
begin
    return query select id from unnest(_array) as id;
end;
$$;


ALTER FUNCTION public.array_to_table(_array anyarray) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 202 (class 1259 OID 16846)
-- Name: authors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.authors (
    id_author integer NOT NULL,
    full_name character varying DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.authors OWNER TO postgres;

--
-- TOC entry 217 (class 1255 OID 16853)
-- Name: author_delete(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.author_delete(_id_author integer DEFAULT NULL::integer) RETURNS SETOF public.authors
    LANGUAGE plpgsql
    AS $$
declare
    rec authors%rowtype;
begin

    delete
    from authors
    where id_author = _id_author
      and id_author != 0 returning * into rec;

    if rec isnull then
        select into rec (author_delete()).*;
    end if;

    return next rec;

end;
$$;


ALTER FUNCTION public.author_delete(_id_author integer) OWNER TO postgres;

--
-- TOC entry 252 (class 1255 OID 16854)
-- Name: author_insert(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.author_insert(_full_name character varying DEFAULT NULL::character varying) RETURNS SETOF public.authors
    LANGUAGE plpgsql
    AS $$
declare
    rec authors%rowtype;
begin

    begin

        insert into authors (full_name)
        values (_full_name)
        returning * into rec;

    exception

        when sqlstate '23505' then
            begin
                raise notice 'Запис вже існує';
                select into rec (author_search(_full_name => _full_name)).*;
            end;

        when sqlstate '23502' then
            begin
                raise notice 'Нульове значення';
                select into rec (author_search()).*;
            end;

    end;

    return next rec;

end;
$$;


ALTER FUNCTION public.author_insert(_full_name character varying) OWNER TO postgres;

--
-- TOC entry 258 (class 1255 OID 17017)
-- Name: author_search(integer, character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.author_search(_id_author integer DEFAULT NULL::integer, _full_name character varying DEFAULT NULL::character varying, all_record boolean DEFAULT false) RETURNS SETOF public.authors
    LANGUAGE plpgsql
    AS $$
declare
    rec authors%rowtype;
begin

    if all_record then
        <<all_records>>
        begin

            for rec in select *
                       from authors
                       where id_author <> 0
                       order by full_name asc
                loop

                    exit all_records when rec isnull;
                    return next rec;

                end loop;

        end;

    elseif _id_author notnull then
        <<one_record>>
        begin

            select *
            into rec
            from authors
            where id_author = _id_author;

            exit one_record when rec isnull;
            return next rec;

        end;

    else
        <<some_records>>
        begin

            _full_name = trim(_full_name);
            if _full_name isnull then _full_name = ''; end if;

            exit some_records when _full_name = '';

            for rec in select *
                       from authors
                       where full_name ~~* concat('%', _full_name, '%')
                         and id_author <> 0
                       order by full_name asc
                loop

                    exit some_records when rec isnull;
                    return next rec;

                end loop;

        end;

    end if;

    if rec isnull then
        return query select * from authors where id_author = 0;
    end if;

    return;

end;
$$;


ALTER FUNCTION public.author_search(_id_author integer, _full_name character varying, all_record boolean) OWNER TO postgres;

--
-- TOC entry 256 (class 1255 OID 16856)
-- Name: author_update(character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.author_update(new_full_name character varying DEFAULT NULL::character varying, _id_author integer DEFAULT NULL::integer) RETURNS SETOF public.authors
    LANGUAGE plpgsql
    AS $$
declare
    rec authors%rowtype;
begin

    begin

        update authors
        set full_name = compare(new_full_name :: varchar, full_name :: varchar)
        where id_author = _id_author
        returning * into rec;

    exception

        when sqlstate '23505'
            then
                begin
                    raise notice 'Запис вже існує';
                    select into rec (author_search(_full_name => new_full_name)).*;
                end;

    end;

    return next rec;

end;
$$;


ALTER FUNCTION public.author_update(new_full_name character varying, _id_author integer) OWNER TO postgres;

--
-- TOC entry 220 (class 1255 OID 16857)
-- Name: cast_bool(anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cast_bool(parameter anyelement) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
begin
    return parameter :: character varying :: boolean;
end
$$;


ALTER FUNCTION public.cast_bool(parameter anyelement) OWNER TO postgres;

--
-- TOC entry 221 (class 1255 OID 16858)
-- Name: cast_date(anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cast_date(parameter anyelement) RETURNS date
    LANGUAGE plpgsql
    AS $$
declare
    elem character varying;
begin
    --     return cast(cast(case
--                          when pg_typeof(parameter) = 'double precision' :: regtype
--                              then to_timestamp(parameter)
--                          else parameter end
--         as character varying) as date);

    elem = parameter :: character varying;

    return case elem
               when ''
                   then null
               else elem :: date
        end;

end
$$;


ALTER FUNCTION public.cast_date(parameter anyelement) OWNER TO postgres;

--
-- TOC entry 234 (class 1255 OID 16859)
-- Name: cast_dp(anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cast_dp(parameter anyelement) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
declare
    elem double precision;
begin

    elem = parameter :: character varying :: double precision;

    return case elem
               when 0
                   then null
               else elem
        end;

end
$$;


ALTER FUNCTION public.cast_dp(parameter anyelement) OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 16860)
-- Name: cast_int(anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cast_int(parameter anyelement) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
    elem integer;
begin

    elem = parameter :: character varying :: integer;

    return case elem
               when 0
                   then null
               else elem
        end;

end
$$;


ALTER FUNCTION public.cast_int(parameter anyelement) OWNER TO postgres;

--
-- TOC entry 236 (class 1255 OID 16861)
-- Name: cast_text(anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cast_text(parameter anyelement) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
    elem character varying;
begin

    elem = parameter :: character varying;

    return case elem
               when ''
                   then null
               else elem
        end;

end
$$;


ALTER FUNCTION public.cast_text(parameter anyelement) OWNER TO postgres;

--
-- TOC entry 237 (class 1255 OID 16862)
-- Name: cast_text_array(anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cast_text_array(parameter anyelement) RETURNS character varying[]
    LANGUAGE plpgsql
    AS $$
declare
    elem character varying[];
begin

    elem = parameter :: character varying[];

    return case elem
               when array ['']
                   then null
               else elem
        end;

end
$$;


ALTER FUNCTION public.cast_text_array(parameter anyelement) OWNER TO postgres;

--
-- TOC entry 238 (class 1255 OID 16863)
-- Name: cast_ts(anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cast_ts(parameter anyelement) RETURNS timestamp with time zone
    LANGUAGE plpgsql
    AS $$
begin
    return parameter :: character varying :: timestamp with time zone at time zone 'Europe/Kiev';
end
$$;


ALTER FUNCTION public.cast_ts(parameter anyelement) OWNER TO postgres;

--
-- TOC entry 239 (class 1255 OID 16864)
-- Name: cast_type(anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cast_type(parameter anyelement) RETURNS public.publication_type
    LANGUAGE plpgsql
    AS $$
declare
    elem character varying;
begin

    elem = parameter :: character varying;

    return case elem
               when ''
                   then null
               else elem :: publication_type
        end;

exception
    when sqlstate '22P02'
        then begin
            raise notice 'Такого значення не існує';
            return 'Невідома основа навчання';
        end;

end
$$;


ALTER FUNCTION public.cast_type(parameter anyelement) OWNER TO postgres;

--
-- TOC entry 240 (class 1255 OID 16865)
-- Name: compare(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.compare(new_value anyelement DEFAULT NULL::unknown, old_value anyelement DEFAULT NULL::unknown) RETURNS anyelement
    LANGUAGE plpgsql
    AS $$
begin
    return coalesce(nullif(new_value, old_value), nullif(old_value, new_value), new_value);
end ;
$$;


ALTER FUNCTION public.compare(new_value anyelement, old_value anyelement) OWNER TO postgres;

--
-- TOC entry 241 (class 1255 OID 16866)
-- Name: dont_delete_null_record(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.dont_delete_null_record() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin

    raise exception 'Неможливо видалити нульовий запис';

    return old;

end;
$$;


ALTER FUNCTION public.dont_delete_null_record() OWNER TO postgres;

--
-- TOC entry 242 (class 1255 OID 16867)
-- Name: dont_update_null_record(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.dont_update_null_record() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin

    return old;

end;
$$;


ALTER FUNCTION public.dont_update_null_record() OWNER TO postgres;

--
-- TOC entry 203 (class 1259 OID 16868)
-- Name: journals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.journals (
    id_journal integer NOT NULL,
    title character varying NOT NULL,
    title_en character varying NOT NULL
);


ALTER TABLE public.journals OWNER TO postgres;

--
-- TOC entry 244 (class 1255 OID 16874)
-- Name: journal_delete(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.journal_delete(_id_journal integer DEFAULT NULL::integer) RETURNS SETOF public.journals
    LANGUAGE plpgsql
    AS $$
declare
    rec journals%rowtype;
begin

    delete
    from journals
    where id_journal = _id_journal
      and id_journal != 0
    returning * into rec;

    if rec isnull then
        select into rec (journal_search()).*;
    end if;

    return next rec;

end;
$$;


ALTER FUNCTION public.journal_delete(_id_journal integer) OWNER TO postgres;

--
-- TOC entry 243 (class 1255 OID 16875)
-- Name: journal_insert(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.journal_insert(_title character varying DEFAULT NULL::character varying, _title_en character varying DEFAULT NULL::character varying) RETURNS SETOF public.journals
    LANGUAGE plpgsql
    AS $$
declare
    rec journals%rowtype;
begin

    begin

        insert into journals (title, title_en)
        values (_title, _title_en)
        returning * into rec;

    exception

        when sqlstate '23505' then
            begin
                raise notice 'Запис вже існує';
                select into rec (journal_search(
                        _title => _title,
                        _title_en => _title_en
                    )).*;
            end;

        when sqlstate '23502' then
            begin
                raise notice 'Нульове значення';
                select into rec (journal_search()).*;
            end;

    end;

    return next rec;

end;
$$;


ALTER FUNCTION public.journal_insert(_title character varying, _title_en character varying) OWNER TO postgres;

--
-- TOC entry 257 (class 1255 OID 17018)
-- Name: journal_search(integer, character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.journal_search(_id_journal integer DEFAULT NULL::integer, _title character varying DEFAULT NULL::character varying, _title_en character varying DEFAULT NULL::character varying, all_record boolean DEFAULT false) RETURNS SETOF public.journals
    LANGUAGE plpgsql
    AS $$
declare
    rec journals%rowtype;
begin

    if all_record then
        <<all_records>>
        begin

            for rec in select *
                       from journals
                       where id_journal <> 0
                       order by id_journal asc
                loop

                    exit all_records when rec isnull;
                    return next rec;

                end loop;

        end;

    elseif _id_journal notnull then
        <<one_record>>
        begin

            select *
            into rec
            from journals
            where id_journal = _id_journal;

            exit one_record when rec isnull;
            return next rec;

        end;

    else
        <<trim_process>>
        begin

            _title = trim(_title);
            _title_en = trim(_title_en);

            if _title isnull then _title = ''; end if;
            if _title_en isnull then _title_en = ''; end if;

            exit trim_process when _title = '' and _title_en = '';

            if _title = _title_en then
                <<same_record>>
                begin

                    select *
                    into rec
                    from journals
                    where title = _title
                       or title_en = _title_en;

                    exit same_record when rec isnull;
                    return next rec;

                end;
            else
                <<some_records>>
                begin
                    for rec in select *
                               from journals
                               where (case
                                          when _title notnull and _title_en notnull
                                              then title ~~* concat('%', _title, '%')
                                              and title_en ~~* concat('%', _title_en, '%')
                                          else title ~~* concat('%', _title, '%')
                                              or title_en ~~* concat('%', _title_en, '%')
                                   end)
                                 and id_journal <> 0
                        loop

                            exit some_records when rec isnull;
                            return next rec;

                        end loop;
                end;
            end if;

        end;

    end if;

    if rec isnull then
        return query select * from journals where id_journal = 0;
    end if;

    return;

end ;
$$;


ALTER FUNCTION public.journal_search(_id_journal integer, _title character varying, _title_en character varying, all_record boolean) OWNER TO postgres;

--
-- TOC entry 247 (class 1255 OID 16877)
-- Name: journal_update(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.journal_update(new_title character varying DEFAULT NULL::character varying, new_title_en character varying DEFAULT NULL::character varying, _id_journal integer DEFAULT NULL::integer) RETURNS SETOF public.journals
    LANGUAGE plpgsql
    AS $$
declare
    rec journals%rowtype;
begin

    begin

        update journals
        set title    = compare(new_title :: varchar, title :: varchar),
            title_en = compare(new_title_en :: varchar, title_en :: varchar)
        where id_journal = _id_journal
        returning * into rec;

    exception

        when sqlstate '23505'
            then
                begin
                    raise notice 'Запис вже існує';
                    select into rec (journal_search(
                            _title => new_title,
                            _title_en => new_title_en
                        )).*;
                end;

    end;

    return next rec;

end;
$$;


ALTER FUNCTION public.journal_update(new_title character varying, new_title_en character varying, _id_journal integer) OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 16878)
-- Name: keywords; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.keywords (
    id_keyword integer NOT NULL,
    word character varying NOT NULL
);


ALTER TABLE public.keywords OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 16884)
-- Name: keyword_delete(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.keyword_delete(_id_keyword integer DEFAULT NULL::integer) RETURNS SETOF public.keywords
    LANGUAGE plpgsql
    AS $$
declare
    rec keywords%rowtype;
begin

    delete
    from keywords
    where id_keyword = _id_keyword
      and id_keyword != 0 returning * into rec;

    if rec isnull then
        select into rec (keyword_delete()).*;
    end if;

    return next rec;

end;
$$;


ALTER FUNCTION public.keyword_delete(_id_keyword integer) OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 16885)
-- Name: keyword_insert(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.keyword_insert(_word character varying DEFAULT NULL::character varying) RETURNS SETOF public.keywords
    LANGUAGE plpgsql
    AS $$
declare
    rec keywords%rowtype;
begin

    begin

        insert into keywords (word)
        values (_word)
        returning * into rec;

    exception

        when sqlstate '23505' then
            begin
                raise notice 'Запис вже існує';
                select into rec (keyword_search(_word => _word)).*;
            end;

        when sqlstate '23502' then
            begin
                raise notice 'Нульове значення';
                select into rec (keyword_search()).*;
            end;

    end;

    return next rec;

end;
$$;


ALTER FUNCTION public.keyword_insert(_word character varying) OWNER TO postgres;

--
-- TOC entry 259 (class 1255 OID 17020)
-- Name: keyword_search(integer, character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.keyword_search(_id_keyword integer DEFAULT NULL::integer, _word character varying DEFAULT NULL::character varying, all_record boolean DEFAULT false) RETURNS SETOF public.keywords
    LANGUAGE plpgsql
    AS $$
declare
    rec keywords%rowtype;
begin

    if all_record then
        <<all_records>>
        begin

            for rec in select *
                       from keywords
                       where id_keyword <> 0
                       order by word asc
                loop

                    exit all_records when rec isnull;
                    return next rec;

                end loop;

        end;

    elseif _id_keyword notnull then
        <<one_record>>
        begin

            select *
            into rec
            from keywords
            where id_keyword = _id_keyword;

            exit one_record when rec isnull;
            return next rec;

        end;

    else
        <<some_records>>
        begin

            _word = trim(_word);
            if _word isnull then _word = ''; end if;

            exit some_records when _word = '';

            for rec in select *
                       from keywords
                       where word ~~* concat('%', _word, '%')
                         and id_keyword <> 0
                       order by word
                loop

                    exit some_records when rec isnull;
                    return next rec;

                end loop;

        end;

    end if;

    if rec isnull then
        return query select * from keywords where id_keyword = 0;
    end if;

    return;

end;
$$;


ALTER FUNCTION public.keyword_search(_id_keyword integer, _word character varying, all_record boolean) OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 16887)
-- Name: keyword_update(character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.keyword_update(new_word character varying DEFAULT NULL::character varying, _id_keyword integer DEFAULT NULL::integer) RETURNS SETOF public.keywords
    LANGUAGE plpgsql
    AS $$
declare
    rec keywords%rowtype;
begin

    begin

        update keywords
        set word = compare(new_word :: varchar, word :: varchar)
        where id_keyword = _id_keyword
        returning * into rec;

    exception

        when sqlstate '23505'
            then
                begin
                    raise notice 'Запис вже існує';
                    select into rec (keyword_search(_word => new_word)).*;
                end;

    end;

    return next rec;

end;
$$;


ALTER FUNCTION public.keyword_update(new_word character varying, _id_keyword integer) OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 16888)
-- Name: publications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.publications (
    id_publication integer NOT NULL,
    type public.publication_type DEFAULT 'Стаття'::public.publication_type NOT NULL,
    abstract text,
    date date,
    id_rating integer NOT NULL,
    doi character varying,
    title character varying DEFAULT 'Публікація'::character varying NOT NULL,
    id_journal integer
);


ALTER TABLE public.publications OWNER TO postgres;

--
-- TOC entry 219 (class 1255 OID 16896)
-- Name: load_data_from_doaj_xml(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.load_data_from_doaj_xml(path text) RETURNS SETOF public.publications
    LANGUAGE plpgsql
    AS $$
declare
    file                 xml;
    doaj_record          xml;
    ids_author           int[];
    _id_author           int;
    _id_journal          int;
    ids_keyword          int[];
    _id_keyword          int;
    _id_rating           int;
    author_name          varchar;
    journal_title        varchar;
    keyword              varchar;
    publication_title    varchar;
    publication_abstract text;
    publication_date     date;
    publication_doi      varchar;
    publication_record   publications%rowtype;
begin

    file = pg_read_file(path) :: xml;

    -- processing records start

    for i in 1..array_length(xpath('//record', file), 1)
        loop
            begin

                with x(item) AS (select file),
                     records as (
                         select xpath('//record', item) as val1
                         from x
                     )
                select into doaj_record val1[i]
                from records;

                <<record_read>>
                begin

                    --                     raise notice ' ';
--                     raise notice ' record[%]: ', i;
--                     raise notice ' ';
--                     raise notice ' ---------- ---------- ---------- ';

                    publication_title = null;
                    publication_abstract = null;
                    publication_date = null;
                    publication_doi = null;

                    author_name = null;
                    ids_author = '{}';
                    _id_author = null;

                    journal_title = null;
                    _id_journal = null;

                    keyword = null;
                    ids_keyword = '{}';
                    _id_keyword = null;

                    _id_rating = null;
                    publication_record = null;

                    -- processing publication start

                    <<publication_read>>
                    begin

                        with x(col) AS (select doaj_record),
                             _publication_title as (
                                 select xpath('//record/title[@language=//record/language/text()]/text()', col) AS val1
                                 from x
                             ),
                             _publication_abstract as (
                                 select xpath('//record/abstract[@language=//record/language/text()]/text()',
                                              col) AS val2
                                 from x
                             ),
                             _publication_date as (
                                 select xpath('//record/publicationDate/text()', col) AS val3
                                 from x
                             ),
                             _publication_doi as (
                                 select xpath('//record/doi/text()', col) AS val4
                                 from x
                             )
                        select into
                            publication_title,
                            publication_abstract,
                            publication_date,
                            publication_doi trim(both E'\n ' from val1[1] :: varchar),
                                            trim(both E'\n ' from substring(val2[1] :: text from 1 for 250)),
                                            val3[1],
                                            trim(both E'\n ' from concat('https://doi.org/', val4[1]) :: varchar)
                        from _publication_title _pt,
                             _publication_abstract _pa,
                             _publication_date _pdate,
                             _publication_doi _pdoi;

                        exit record_read when exists(
                                select *
                                from publication_search(_doi => publication_doi)
                                where id_publication <> 0);

                        --                         raise notice ' ';
--                         raise notice 'Publication: ';
--                         raise notice ' ';
--                         raise notice 'publication_title = %', publication_title;
--                         raise notice 'publication_abstract = %', publication_abstract;
--                         raise notice 'publication_date = %', publication_date;
--                         raise notice 'publication_doi = %', publication_doi;
--                         raise notice ' ';
--                         raise notice ' ---------- ---------- ---------- ';

                    end;

                    -- processing publication end

                    -- processing authors start

--                     raise notice ' ';
--                     raise notice 'Authors:';

                    <<authors_read>>
                    begin

                        for i in 1..15
                            loop

                                with x(col) AS (select doaj_record),
                                     authors as (
                                         select xpath('//record/authors/author/name/text()', col) as val1
                                         from x
                                     )
                                select into author_name trim(both E'\n ' from val1[i] :: varchar)
                                from authors;

                                exit authors_read when author_name isnull;

                                ids_author =
                                            ids_author || (select (author_insert(_full_name => author_name)).id_author);

                                --                                 raise notice ' ';
--                                 raise notice 'author_name = %', author_name;
--                                 raise notice 'id_author = %', ids_author[i];

                            end loop;

                    end;

                    --                     raise notice ' ';
--                     raise notice 'ids_author = %', ids_author;
--                     raise notice ' ';
--                     raise notice ' ---------- ---------- ---------- ';

                    -- processing authors end

                    -- processing journal start

                    <<journal_read>>
                    begin

                        with x(col) AS (select doaj_record),
                             journal as (
                                 select xpath('//record/journalTitle/text()', col) AS val1
                                 from x
                             )
                        select into journal_title/*_en*/ trim(both E'\n ' from val1[1] :: varchar)
                        from journal;

                        /*journal_title = case journal_title_en
                                            when 'Automation of technological and business processes'
                                                then 'Автоматизація технологічних i бізнес-процесів'
                                            when 'Food Industry Economics'
                                                then 'Економіка харчової промисловості'
                                            when 'Grain Products and Mixed Fodder’s'
                                                then 'Зернові продукти і комбікорми'
                                            when 'Scientific Works'
                                                then 'Наукові праці'
                                            when 'Proceedings of the International Geometry Center'
                                                then 'Праці міжнародного геометричного центру'
                                            when 'Food Science and Technology'
                                                then 'Харчова наука і технологія'
                                            when 'Refrigeration Engineering and Technology'
                                                then 'Холодильна техніка та технологія'
                            end;*/

                        exit journal_read when journal_title/*_en*/ isnull;

                        _id_journal = (select (journal_search(
                                _title => journal_title,
                                _title_en => journal_title/*_en*/
                            )).id_journal);

--                         raise notice ' ';
--                         raise notice 'Journal: ';
--                         raise notice ' ';
--                         raise notice 'journal = %', journal_title;
--                         raise notice 'journal_en = %', journal_title_en;
--                         raise notice 'id_journal = %', _id_journal;
--                         raise notice ' ';
--                         raise notice ' ---------- ---------- ---------- ';

                    end;

                    -- processing journal end

                    -- processing keywords start

--                     raise notice ' ';
--                     raise notice 'Keywords: ';

                    <<keywords_read>>
                    begin

                        for i in 1..15
                            loop
                                with x(col) AS (select doaj_record),
                                     keywords as (
                                         select xpath(
                                                        '//record/keywords[@language=//record/language/text()]/keyword/text()',
                                                        col) as val1
                                         from x
                                     )
                                select into keyword trim(both E'\n ' from val1[i] :: varchar)
                                from keywords;

                                exit keywords_read when keyword isnull;

                                ids_keyword = ids_keyword || (select (keyword_insert(_word => keyword)).id_keyword);

                                --                                 raise notice ' ';
--                                 raise notice 'keyword = %', keyword;
--                                 raise notice 'id_keyword = %', ids_keyword[i];

                            end loop;

                    end;

                    --                     raise notice ' ';
--                     raise notice 'ids_keyword = %', ids_keyword;
--                     raise notice ' ';
--                     raise notice ' ---------- ---------- ---------- ';

                    -- processing keywords end

                    -- insert new records
                    <<create_new_publication>>
                    begin

                        select into _id_rating (rating_insert()).id_rating;

                        --                         raise notice ' ';
--                         raise notice 'Rating: ';
--                         raise notice ' ';
--                         raise notice 'id_rating = %', _id_rating;
--                         raise notice ' ';
--                         raise notice ' ---------- ---------- ---------- ';

                        select into publication_record (publication_insert(
                                publication_title,
                                'Стаття' :: publication_type,
                                publication_abstract,
                                publication_date,
                                publication_doi,
                                _id_rating,
                                _id_journal
                            )).*;

                        foreach _id_author in array ids_author
                            loop
                                <<publication_author_ids>>
                                begin

                                    exit publication_author_ids when _id_author isnull;

                                    insert into publications_authors (id_publication, id_author)
                                    values (publication_record.id_publication, _id_author);
                                end;
                            end loop;

                        foreach _id_keyword in array ids_keyword
                            loop
                                <<publication_keyword_ids>>
                                begin

                                    exit publication_keyword_ids when _id_keyword isnull;

                                    insert into publications_keywords (id_publication, id_keyword)
                                    values (publication_record.id_publication, _id_keyword);
                                end;
                            end loop;

                        return next publication_record;

                        --                         raise notice ' ';
--                         raise notice 'Publication: ';
--                         raise notice ' ';
--                         raise notice 'publication = %', publication_record;
--                         raise notice ' ';
--                         raise notice ' ---------- ---------- ---------- ';

                    end;

                end;

            end;
        end loop;

    -- processing records end

    if publication_record isnull then
        return query select * from publications where id_publication = 0;
    end if;

    return;

end;
$$;


ALTER FUNCTION public.load_data_from_doaj_xml(path text) OWNER TO postgres;

--
-- TOC entry 246 (class 1255 OID 16898)
-- Name: publication_delete(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.publication_delete(_id_publication integer DEFAULT NULL::integer) RETURNS SETOF public.publications
    LANGUAGE plpgsql
    AS $$
declare
    rec publications%rowtype;
begin

    delete
    from publications
    where id_publication = _id_publication
      and id_publication != 0 returning * into rec;

    if rec isnull then
        select into rec (publication_delete()).*;
    end if;

    return next rec;

end;
$$;


ALTER FUNCTION public.publication_delete(_id_publication integer) OWNER TO postgres;

--
-- TOC entry 254 (class 1255 OID 17016)
-- Name: publication_insert(character varying, public.publication_type, text, date, character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.publication_insert(_title character varying DEFAULT NULL::character varying, _type public.publication_type DEFAULT NULL::public.publication_type, _abstract text DEFAULT NULL::text, _date date DEFAULT NULL::date, _doi character varying DEFAULT NULL::character varying, _id_rating integer DEFAULT NULL::integer, _id_journal integer DEFAULT NULL::integer) RETURNS SETOF public.publications
    LANGUAGE plpgsql
    AS $$
declare
    rec publications%rowtype;
begin

    begin

        insert into publications (title, "type", abstract, date, id_rating, doi, id_journal)
        values (_title, _type, _abstract, _date, _id_rating, _doi, _id_journal)
        returning * into rec;

    exception

        when sqlstate '23505' then
            begin
                raise notice 'Запис вже існує';
                select into rec (publication_search(
                        _title => _title,
                        _doi => _doi
                    )).*;
            end;

        when sqlstate '23502' then
            begin
                raise notice 'Нульове значення';
                select into rec (publication_search()).*;
            end;

    end;

    return next rec;

end;
$$;


ALTER FUNCTION public.publication_insert(_title character varying, _type public.publication_type, _abstract text, _date date, _doi character varying, _id_rating integer, _id_journal integer) OWNER TO postgres;

--
-- TOC entry 255 (class 1255 OID 17013)
-- Name: publication_search(integer, character varying, public.publication_type, text, character varying, character varying, character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.publication_search(_id_publication integer DEFAULT NULL::integer, _title character varying DEFAULT NULL::character varying, _type public.publication_type DEFAULT NULL::public.publication_type, _abstract text DEFAULT NULL::text, _date character varying DEFAULT NULL::character varying, _doi character varying DEFAULT NULL::character varying, _authors character varying DEFAULT NULL::character varying, _keywords character varying DEFAULT NULL::character varying, all_record boolean DEFAULT false) RETURNS SETOF public.publications
    LANGUAGE plpgsql
    AS $$
declare
    rec        publications%rowtype;
    __authors  varchar[];
    __keywords varchar[];
begin

    if all_record then
        <<all_records>>
        begin

            for rec in select *
                       from publications
                       where id_publication <> 0
                       order by title asc
                loop

                    exit all_records when rec isnull;
                    return next rec;

                end loop;

        end;

    elseif _id_publication notnull
        or (_doi notnull and _doi <> '') then
        <<one_record>>
        begin

            select *
            into rec
            from publications
            where id_publication = _id_publication
               or doi = _doi;

            exit one_record when rec isnull;
            return next rec;

        end;

    else
        <<some_records>>
        begin

            _title = trim(_title);
            _abstract = trim(_abstract);
            _date = trim(_date);
            _authors = trim(_authors);
            _keywords = trim(_keywords);

            if _title isnull then _title = ''; end if;
            if _abstract isnull then _abstract = ''; end if;
            if _date isnull then _date = ''; end if;
            if _authors isnull then _authors = ''; end if;
            if _keywords isnull then _keywords = ''; end if;

            exit some_records
                when _title = '' and _type isnull and _abstract = ''
                    and _date = '' and _authors = '' and _keywords = '';

            __authors = concat('{', _authors, '}') :: varchar[];
            __keywords = concat('{', _keywords, '}') :: varchar[];

            if __authors isnull or __authors[1] isnull then __authors[1] = ''; end if;
            if __keywords isnull or __keywords[1] isnull then __keywords[1] = ''; end if;
            if _type isnull then _type = 'Стаття' :: publication_type; end if;

            for rec in select distinct p.*
                       from publications p,
                            authors a,
                            keywords k,
                            publications_authors pa,
                            publications_keywords pk,
                            array_to_table(__authors) _a,
                            array_to_table(__keywords) _k
                       where p.id_publication = pa.id_publication
                         and p.id_publication = pk.id_publication
                         and a.id_author = pa.id_author
                         and k.id_keyword = pk.id_keyword
                         and p.title ~~* concat('%', _title, '%')
                         and p.type = _type
                         and p.abstract ~~* concat('%', _abstract, '%')
                         and p.date :: varchar ~~* concat('%', _date, '%')
                         and a.full_name ~~* concat('%', _a, '%')
                         and k.word ~~* concat('%', _k, '%')
                         and p.id_publication <> 0
                       order by p.title
                loop
                    begin

                        exit some_records when rec isnull;
                        return next rec;

                    end;
                end loop;

        end;

    end if;

    if rec isnull then
        return query select * from publications where id_publication = 0;
    end if;

    return;

end;
$$;


ALTER FUNCTION public.publication_search(_id_publication integer, _title character varying, _type public.publication_type, _abstract text, _date character varying, _doi character varying, _authors character varying, _keywords character varying, all_record boolean) OWNER TO postgres;

--
-- TOC entry 253 (class 1255 OID 17015)
-- Name: publication_update(character varying, character varying, text, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.publication_update(new_title character varying DEFAULT NULL::character varying, new_type character varying DEFAULT NULL::character varying, new_abstract text DEFAULT NULL::text, new_date character varying DEFAULT NULL::character varying, new_doi character varying DEFAULT NULL::character varying, _id_publication integer DEFAULT NULL::integer) RETURNS SETOF public.keywords
    LANGUAGE plpgsql
    AS $$
declare
    rec publications%rowtype;
begin

    begin

        update publications
        set title    = compare(new_title :: varchar, title :: varchar),
            "type"   = compare(new_type :: publication_type, type :: publication_type),
            abstract = compare(new_abstract :: text, abstract :: text),
            date     = compare(new_date :: date, date :: date),
            doi      = compare(new_doi :: varchar, doi :: varchar)
        where id_publication = _id_publication
        returning * into rec;

    exception

        when sqlstate '23505'
            then
                begin
                    raise notice 'Запис вже існує';
                    select into rec (publication_search(
                            _title => new_title,
                            _doi => new_doi
                        )).*;
                end;

    end;

    return next rec;

end;
$$;


ALTER FUNCTION public.publication_update(new_title character varying, new_type character varying, new_abstract text, new_date character varying, new_doi character varying, _id_publication integer) OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 16903)
-- Name: ratings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ratings (
    id_rating integer NOT NULL,
    stars double precision DEFAULT 0 NOT NULL,
    seen integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.ratings OWNER TO postgres;

--
-- TOC entry 250 (class 1255 OID 16908)
-- Name: rating_delete(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rating_delete(_id_rating integer DEFAULT NULL::integer) RETURNS SETOF public.ratings
    LANGUAGE plpgsql
    AS $$
declare
    rec ratings%rowtype;
begin

    delete
    from ratings
    where id_rating = _id_rating
      and id_rating != 0 returning * into rec;

    if rec isnull then
        select into rec (rating_delete()).*;
    end if;

    return next rec;

end;
$$;


ALTER FUNCTION public.rating_delete(_id_rating integer) OWNER TO postgres;

--
-- TOC entry 251 (class 1255 OID 16909)
-- Name: rating_insert(double precision, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rating_insert(_stars double precision DEFAULT (0.0)::double precision, _seen integer DEFAULT 0) RETURNS SETOF public.ratings
    LANGUAGE plpgsql
    AS $$
declare
    rec ratings%rowtype;
begin

    begin

        insert into ratings (stars, seen)
        values (_stars, _seen)
        returning * into rec;

    exception

        when sqlstate '23502' then
            begin
                raise notice 'Нульове значення';
                select into rec (rating_search()).*;
            end;

    end;

    return next rec;

end;
$$;


ALTER FUNCTION public.rating_insert(_stars double precision, _seen integer) OWNER TO postgres;

--
-- TOC entry 260 (class 1255 OID 17021)
-- Name: rating_search(integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rating_search(_id_rating integer DEFAULT NULL::integer, all_record boolean DEFAULT false) RETURNS SETOF public.ratings
    LANGUAGE plpgsql
    AS $$
declare
    rec ratings%rowtype;
begin

    if all_record then
        <<all_records>>
        begin

            for rec in select *
                       from ratings
                       where id_rating <> 0
                       order by seen asc
                loop

                    exit all_records when rec isnull;

                    return next rec;

                end loop;

        end;

    else
        <<one_record>>
        begin

            select *
            into rec
            from ratings
            where id_rating = _id_rating;

            exit one_record when rec isnull;

            return next rec;

        end;

    end if;

    if rec isnull then
        return query select * from ratings where id_rating = 0;
    end if;

    return;

end;
$$;


ALTER FUNCTION public.rating_search(_id_rating integer, all_record boolean) OWNER TO postgres;

--
-- TOC entry 218 (class 1255 OID 16911)
-- Name: rating_update(double precision, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rating_update(new_stars double precision DEFAULT NULL::double precision, new_seen integer DEFAULT NULL::integer, _id_rating integer DEFAULT NULL::integer) RETURNS SETOF public.ratings
    LANGUAGE plpgsql
    AS $$
declare
    rec ratings%rowtype;
begin

    begin

        update ratings
        set stars = compare(new_stars :: varchar, stars :: varchar),
            seen  = compare(new_seen :: varchar, seen :: varchar)
        where id_rating = _id_rating returning * into rec;

    end;

    return next rec;

end;
$$;


ALTER FUNCTION public.rating_update(new_stars double precision, new_seen integer, _id_rating integer) OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 16912)
-- Name: authors_id_author_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.authors_id_author_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.authors_id_author_seq OWNER TO postgres;

--
-- TOC entry 2967 (class 0 OID 0)
-- Dependencies: 207
-- Name: authors_id_author_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.authors_id_author_seq OWNED BY public.authors.id_author;


--
-- TOC entry 208 (class 1259 OID 16914)
-- Name: journals_id_journal_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.journals_id_journal_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.journals_id_journal_seq OWNER TO postgres;

--
-- TOC entry 2968 (class 0 OID 0)
-- Dependencies: 208
-- Name: journals_id_journal_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.journals_id_journal_seq OWNED BY public.journals.id_journal;


--
-- TOC entry 209 (class 1259 OID 16916)
-- Name: keywords_id_keyword_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.keywords_id_keyword_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.keywords_id_keyword_seq OWNER TO postgres;

--
-- TOC entry 2969 (class 0 OID 0)
-- Dependencies: 209
-- Name: keywords_id_keyword_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.keywords_id_keyword_seq OWNED BY public.keywords.id_keyword;


--
-- TOC entry 210 (class 1259 OID 16918)
-- Name: publications_authors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.publications_authors (
    id_publication_author integer NOT NULL,
    id_publication integer NOT NULL,
    id_author integer NOT NULL
);


ALTER TABLE public.publications_authors OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 16921)
-- Name: publications_authors_id_publication_author_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.publications_authors_id_publication_author_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.publications_authors_id_publication_author_seq OWNER TO postgres;

--
-- TOC entry 2970 (class 0 OID 0)
-- Dependencies: 211
-- Name: publications_authors_id_publication_author_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.publications_authors_id_publication_author_seq OWNED BY public.publications_authors.id_publication_author;


--
-- TOC entry 212 (class 1259 OID 16923)
-- Name: publications_id_publication_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.publications_id_publication_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.publications_id_publication_seq OWNER TO postgres;

--
-- TOC entry 2971 (class 0 OID 0)
-- Dependencies: 212
-- Name: publications_id_publication_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.publications_id_publication_seq OWNED BY public.publications.id_publication;


--
-- TOC entry 213 (class 1259 OID 16925)
-- Name: publications_keywords; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.publications_keywords (
    id_publication_keyword integer NOT NULL,
    id_publication integer NOT NULL,
    id_keyword integer NOT NULL
);


ALTER TABLE public.publications_keywords OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 16928)
-- Name: publications_keywords_id_publication_keyword_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.publications_keywords_id_publication_keyword_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.publications_keywords_id_publication_keyword_seq OWNER TO postgres;

--
-- TOC entry 2972 (class 0 OID 0)
-- Dependencies: 214
-- Name: publications_keywords_id_publication_keyword_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.publications_keywords_id_publication_keyword_seq OWNED BY public.publications_keywords.id_publication_keyword;


--
-- TOC entry 215 (class 1259 OID 16930)
-- Name: ratings_id_rating_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ratings_id_rating_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ratings_id_rating_seq OWNER TO postgres;

--
-- TOC entry 2973 (class 0 OID 0)
-- Dependencies: 215
-- Name: ratings_id_rating_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ratings_id_rating_seq OWNED BY public.ratings.id_rating;


--
-- TOC entry 2764 (class 2604 OID 16932)
-- Name: authors id_author; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authors ALTER COLUMN id_author SET DEFAULT nextval('public.authors_id_author_seq'::regclass);


--
-- TOC entry 2765 (class 2604 OID 16933)
-- Name: journals id_journal; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.journals ALTER COLUMN id_journal SET DEFAULT nextval('public.journals_id_journal_seq'::regclass);


--
-- TOC entry 2766 (class 2604 OID 16934)
-- Name: keywords id_keyword; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.keywords ALTER COLUMN id_keyword SET DEFAULT nextval('public.keywords_id_keyword_seq'::regclass);


--
-- TOC entry 2769 (class 2604 OID 16935)
-- Name: publications id_publication; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publications ALTER COLUMN id_publication SET DEFAULT nextval('public.publications_id_publication_seq'::regclass);


--
-- TOC entry 2773 (class 2604 OID 16936)
-- Name: publications_authors id_publication_author; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publications_authors ALTER COLUMN id_publication_author SET DEFAULT nextval('public.publications_authors_id_publication_author_seq'::regclass);


--
-- TOC entry 2774 (class 2604 OID 16937)
-- Name: publications_keywords id_publication_keyword; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publications_keywords ALTER COLUMN id_publication_keyword SET DEFAULT nextval('public.publications_keywords_id_publication_keyword_seq'::regclass);


--
-- TOC entry 2772 (class 2604 OID 16938)
-- Name: ratings id_rating; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings ALTER COLUMN id_rating SET DEFAULT nextval('public.ratings_id_rating_seq'::regclass);


--
-- TOC entry 2948 (class 0 OID 16846)
-- Dependencies: 202
-- Data for Name: authors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.authors (id_author, full_name) FROM stdin;
0	Unknown
2	Т. И. Сулейманов
3	Н. Х. Мустафазаде
4	Р. К. Гулузаде
5	М. М. Гаджиев
6	Л. В. Иванова
7	А. К. Сандлер
8	Ю. М. Ковриго
9	П. В. Новіков
10	Д. А. Ковальчук
11	О. В. Мазур
12	В. А. Хобін
13	Н. В. Захарченко
16	Ю. Ю. Сулима
17	Д. М. Шпак
18	В. В. Гордийчук
19	О. А. Жученко
20	О. В. Дрозд
22	S. A. Voinova
25	П. М. Тишин
26	Б. В. Бутов
27	В. О. Шапорин
28	A. Antonova
29	O. Оnoshenko
30	T. Snigur
31	Е. Г. Киркопуло
32	В. А. Шевченко
33	И. Н. Кирьязов
34	М. Т. Степанов
35	C. B. Шестопалов
36	В. А. Хобин
37	П. Голубков
38	Д Путников
39	В. Егоров
40	Н. Похлебина
41	К. Габуєв
42	В. Гонгало
43	S Voinova
44	В. Г. Муратов
45	В. М. Левінський
46	Л. А. Осипова
47	В. Н. Осипов
48	А. Любека
49	Я. Корнієнко
56	Д. Путников
57	П. С. Голубков
58	В. Б. Егоров
59	V. A. Khobin
60	V. M. Levinskyi
61	M. V. Levinskyi
62	В. М. Марчевський
63	Я. В. Гробовенко
64	В. П. Лисенко
65	І. С. Чернова
67	М. Г. Волощук
68	В. Э. Волков
69	Ю. Г. Лобода
70	Н. А. Макоед
71	І. О. Леонтьєва
73	Д. А. Каврин
74	С. А. Субботин
75	Ю. М. Скаковський
76	А. В. Бабков
77	О. Ю. Мандро
78	В. І. Сахаров
79	С. В. Сахарова
80	Я. Б. Волянська
81	В. В. Голіков
82	О. М. Мазур
83	О. А. Онищенко
85	A. Bohdanov
86	V. M. Plotnikov
87	K. V. Smirnova
88	I. I. Zinchenko
89	Т. М. Моспан
90	Е. В. Савьолова
91	В. Я. Ярмолович
92	С. М. Огінська
93	В. Ю. Гнатенко
94	П. В. Ступень
95	К. В. Дікусар
96	Е. І. Шутєєв
97	Д. О. Скалій
98	М. В. Джиджула
99	Ю. К. Корнієнко
100	O. С. Бойцова
101	O. О. Лівенцова
102	O. Klymenko
103	E. Krong
104	V. Tregub
105	В. А. Зозуля
106	С. І. Осадчий
107	Ю. Б. Бєляєв
108	Paweł Pawłowski
109	A. Ivanova
110	K. Kharash
111	O. Olshevska
112	Y. Bortsova
115	С. С. Гудзь
119	О. М. Жигайло
120	В. В. Борис
121	V. Solovei
125	B. Shanovskiy
126	К. В. Смирнова
127	А. О. Смирнов
128	В. М. Плотников
129	А. В. Шишак
130	О. М. Пупена
131	А. А. Гурский
132	С. М. Дубна
133	M. Melnichuk
134	Yu. Kornienko
135	O. Boytsova
138	І. М. Світий
139	A. Pavlov
140	С. О. Субботін
141	О. В. Корнієнко
142	D. Salskyi
143	A. Kozhukhar
145	N. Povarova
146	Ф. Д. Матіко
147	В. І. Роман
148	О. Я. Масняк
150	О. В. Степанець
151	Р. П. Саков
152	В. И. Мещеряков
153	Д. В. Мещеряков
154	Е. В. Черепанова
156	С. В. Шестопалов
159	К. О. Габуев
160	В. О. Гонгало
161	Н. А. Кучеренко
162	А. И. Шипко
163	А. Ф. Арабаджи
164	А. А. Стопакевич
166	Д. В. Дец
167	К. Шейда-Голбад
170	А. В. Гончаров
171	К. О. Куширець
173	С. И. Лагерная
174	А. А. Процишен
175	Е. О. Улицкая
176	S. Voinova
177	O. Maksymovа
178	M. Maksymov
179	V. Silina
180	A. Orischenko
181	Г. Ангєлов
182	В. Волков
183	О. Кананихіна
184	А. Соловей
185	О. Тітлова
186	Ф. Трішин
187	Yu. G. Loboda
188	E. U. Orlova
189	V. E. Volkov
190	С. Великодний
191	О. Тимофєєва
192	S. Ihnatiev
193	V. Yehorov
194	V. Makarenko
197	K. Smirnova
198	A. Smirnov
199	V. Plotnikov
200	С. Шестопалов
201	В. Хобiн
202	А. Лысюк
203	К. Беглов
204	Y. Skakovsky
205	A. Babkov
206	E. Mandro
208	D. Kovalchuk
209	A. Mazur
210	S. Hudz
212	A. Proydenko
213	A. Bodnia
214	A. A. Shpinkovski
215	M. I. Shpinkovska
216	D. I. Korobova
217	М. С. Юхимчук
218	Т. Н. Манглієва
219	О. В. Мелентьєва
221	V. Levinskyi
222	M. Levinskyi
223	А. В. Ухина
224	Т. П. Яценко
225	В. С. Ситников
226	О. Lysiuk
227	А. Brunetkin
228	М. Maksymov
229	I. Slobodyan
230	V. Lozhechny`kov
231	A. Stopakevy`ch
233	А. Е. Гончаренко
235	O. Titlova
236	V. Khobin
237	O. Titlov
238	А. І. Лісовенко
239	О. В. Бісікало
240	A. M. Silvestrov
241	A. I. Sorokovyi
242	A. I. Laktionov
243	O. Yu. Sakaliuk
246	A. A. Gurskiy
247	A. E. Goncharenko
248	S. M. Dubna
249	E. I. Kobysh
250	A. I. Simkin
251	Д. А. Шумигай
252	А. П. Ладанюк
253	Я. В. Смітюх
254	В. О. Кондратець
255	А. М. Мацуй
257	Л. Л. Бевзюк
258	A. Рupena
259	I. Elperin
260	R. Mirkevich
262	Л. Н. Блохин
263	С. И. Осадчий
265	S. N. Pelykh
266	E. A. Odrehovska
267	O. B. Maksymova
268	N. Shcherbakov
269	F. Trishyn
274	V. Petrenko
276	К. Молодецька-Гринчук
281	А. В. Лысюк
282	А. В. Бондаренко
283	М. М. Максимов
284	А. И. Брунеткин
286	А.Ф. Арабаджи
287	A. A. Стопакевич
290	D. V. Dets
294	T. Foshch
295	S. Pelykh
297	D. Putnikov
299	A. S. Tityapkin
301	A. I. Pavlov
302	K. Kolesnikova
303	D. Monova
304	Ye. Naumenko
305	I. Kheblov
306	I. Gurjev
308	N. Dzyuba
309	A. Volodin
310	L. Kryvoplias-Volodina
311	S. Velykodniy
312	O. Tymofieieva
317	N. Fil’
318	Y. M. Skakovsk
319	A. V. Babkov
320	E. V. Mandro
321	A. S. Popov
322	E. V. Lukyanchuk
325	V. Kudry
326	O. A. Zhuchenko
327	A. V. Khobin
329	A. M. Kulia
330	A. V. Denisenko
331	A. A. Gursky
333	O. F. Vynakov
334	E. V. Savolova
335	A. I. Skrynnyk
336	N. A. Belova
337	G. P. Lisiuk
338	В. М. Стефаник
339	А. И. Брунеткин,
340	А. В. Гусак
341	C. А. Воинова
342	А. И. Павлов
343	A. L. Nikiforo
344	I. A. Menejlju
345	К. О. Водолазкіна
349	І. М. Голінко
350	П. П. Червоненко
351	В. А. Болтенков,
352	О. С. Тарахтий
353	А. Н. Бундюк
356	В. М. Калич
357	Ю. М. Кочерженко
359	I. Sedikova
360	Y. Diachenko
361	П. О. Антонюк
362	О. П. Антонюк
363	Т. М. Ступницька
364	Л. М. Головаченко
365	О. І. Лайко
366	В. В. Торган
367	V. Samofatova
368	О. В. Нікішина
369	О. М. Муратов
370	S. Didukh
371	V. Aoun
372	O. Kalaman
373	O. Kananykhina
374	A. Solovey
375	P. Beznis
376	К. Б. Козак
377	К. Г. Бойчук
379	Б. В. Мироненко
380	Н. М. Корсікова
381	В. М. Череватий
382	І. В. Мунтян
383	В. Л. Горбаневич
384	П. В. Іванюта
385	H. Nemchenko
386	T. Markova
387	K. Vaskovska
388	G. Pchelianska
389	O. Volodina
393	Н. М. Купріна
394	О. А. Тофаніло
395	І. О. Котобан
396	Р. Є. Скіпор
398	К. В. Апостолов
399	А. В. Шаталова
400	О. В. Бачинська
401	В. А. Шалений
402	K. Kozak
403	A. Mokan
404	V. Nemchenko
406	I. Ageieva
407	A. Rynkova
409	І. М. Бамбуляк
410	Т. Д. Маркова
411	Н. М. Кулік
413	В. В. Лємєшева
414	І. І. Савенко
415	Д. В. Седіков
416	Т. В. Свистун
417	М. О. Бєлошапко
418	О. П. Ощепков
419	М. М. Чебан
420	С. О. Магденко
421	T. Stupnytska
423	L. Holovachenko
424	Yu. Vasylieva
427	М. М. Стрепенюк
428	Г. А. Римар
429	Л. В. Іванченкова
430	Г. О. Ткачук
431	Л. Б. Скляр
432	К. О. Васьковська
433	Г. Б. Пчелянська
434	О. О. Кохан
435	О. В. Коліщук
436	В. М. Фомішина
437	Н. Є. Федорова
438	В. В. Лагодієнко
439	О. М. Голодонюк
440	В. В. Мільчева
441	M. Braiko
442	O. Solodova
443	O. Golubyonkova
444	А. Braiko
445	В. І. Колесник
446	С. Ю. Вігуржинська
448	О. С. Магденко
449	O. Nikoliuk
452	O. Yevtushevska
453	V. Pryimak
454	К. В. Стасюкова
456	А. В. Ткачук
458	В. В. Тройніна
459	С. В. Чорна
463	О. В. Дишкантюк
464	Д. О. Харенко
465	Л. М. Івичук
468	В. М. Лисюк
469	L. Vasytynska
470	G. Nemchenko
473	D. Mandrikin
474	Г. В. Ангєлов
475	Є. Р. Петракова
476	А. В. Черкаський
477	І. М. Агеєва
478	О. В. Агаркова
479	А. Г. Драбовський
481	М. І. Петренко
483	О. П. Зарудна
484	О. О. Криницька
485	Т. І. Ткачук
493	І. Рудюк
494	О. О. Євтушевська
495	А. Б. Хамардюк
496	О. В. Тарасова
499	Д. П. Пчелянський
501	Н. О. Бібікова
502	І. О. Павлова
503	О. В. Євтушок
504	О. Л. Ліпова
505	В. В. Бахчиванжи
506	N. Basіurkina
507	V. Shaleny
509	Т. М. Черевата
510	N. Kuprina
511	I. Chernenko
512	Н. А. Добрянська
513	С. С. Стоянова - Коваль
514	О. В. Ніколюк
518	O. Martynovska
520	К. В. Євсєєва
521	В. О. Приймак
523	В. Ф. Шкепу
524	В. І. Хрип’юк
525	С. В. Селіхов
528	І. О. Седікова
531	D. Zborshik
532	Ю. В. Дьяченко
536	Y. Melnyk
538	O. Lantsman
540	Kh. Baraniuk
541	С. А. Бондаренко
542	В. В. Руммо
543	В. Р. Нізяєва
545	О. Б. Каламан
546	О. М. Кананихіна
547	А. О. Соловей
549	S. Polish
551	С. П. Кустурова
555	I. Savenko
556	О. Ф. Удовиця
557	Г. П. Пасчина
559	K. I. Gulavska
561	I. Rudiuk
563	Н. Й. Басюркіна
564	Л. В. Шарапанюк
565	S. Magdenko
569	A. Luk’yanov
570	С. М. Дідух
571	В. О. Мініна
572	Т. С. Федорова
574	G. Тkachuk
576	A. Zhigovska
579	K. Zhidkova
580	K. Stasiukova
586	В. О. Бузинський
593	Youcef Kaouane
594	Г. В. Ангелов
595	А. В. Черкасский
596	V Samofatova
597	В. О. Кушнір
598	K. Fomichova
600	А. С. Лянна
603	K. Babenko
606	Н. А. Петрочко
612	В. С. Мартиновський
613	Л. С. Бурага
616	Ю. В. Небеснюк
617	А. В. Коверга
618	Ю. О. Буренко
619	І. В. Крупіца
620	О. А. Стретович
621	Каріне Саркісівна Дойчева
624	Х. О. Баранюк
625	Т. I. Ткачук
626	Г. М. Павленко
627	В. А. Самофатова
629	Г. А. Черняк
632	А. А. Шевченко
636	К. С. Дойчева
641	В. С. Мартыновский
642	Т. А. Кулаковская
643	Д. Ф. Фарзетдинов
644	О. О. Голубьонкова
645	М. Г. Брайко  старший викладач
646	О В Нікішина
650	С. А. Дмитрашко
651	О О. Евтушевская
652	Е. В. Тарасова
655	О. І. Мельничук
657	Ю. П. Паньків
659	М. В. Рожнатова
662	А. С. Молчановська
664	О. А. Стояно
665	В. О. Янковий
666	Н. В. Мельник
670	Г. В. Немченко
671	Р. А. Чернякова
672	О. Б. Ткаченко
674	В. М. Беркгаут
675	И. А. Седикова
677	Ю. Г. Неустроєв
678	Н. Р. Кордзая
679	А. М. Іванов
680	С. Є. Саламатіна
683	О. Є. Килинчук
685	O. KARUNKYI
686	T. REZNIK
687	Ye KULIDZHANOV
688	A. MAKARYNSKA
689	N. VORONA
690	B. IEGOROV
691	L. FIHURSKA
692	М. TERZI
693	O. RUHLENKO
694	O. SHAPOVALENKO
695	L. KUSTOV
696	D. ZHYGYNOV
697	V. KOVALOVA
698	A. DRAGOMYR
699	H. ZHYHUNOVA
700	К. ZHANABAYEVA
701	S. SOTS
702	O. BUNYAK
703	A. BABKOV
704	М. ZHELOBKOVA
705	A. BOCHKOVSKYI
706	N. SAPOZHNIKOVA
707	O. FESENKO
708	V. LYSYUK
709	Z. SAKHAROVA
710	L. S. SOLDATENKO
711	O. V. HORNISHNYI
712	A. V. MAKARYNSKA
713	L. M. YARMAK
714	O. M. PIDDUBNYAK
715	O. Y. KARUNSKYI
716	S. O. TSIKHOVSKYI
717	KAPRELYANTS L. V.
718	E. D. ZHURLOVA
719	O. S. KOVALOVA
720	Yu. O. CHURSINOV
721	D. D. KOFAN
722	G. STANKEVYCH
723	H. НONCHARUK
724	I. SHIPKO
725	A. LIPIN
726	N. KHORENGHY
727	A. LAPINSKA
728	O. O. FESENKO
729	Л.В. ФАДЕЕВ
730	Б.В. ЄГОРОВ
731	О.Г. ЦЮНДИК
732	І.С. ЧЕРНЕГА
733	В.П. ФЕДОРЯКА
734	T.V. SAKHNO
735	P.V. PISARENKO
736	I.V. KOROTKOVA
737	O. M. OMELIAN
738	N. N. BARASHKOV
739	А.В. А.В. МАКАРИНСЬКА
741	О.Й КАРУНСЬКИЙ
742	О.Є ВОЄЦЬКА
743	К.С. ГАРБАДЖІ
744	О.В. ЛАКІЗА
745	М.В. ЩЕРБИНА
746	К.Ю. ІЩЕНКО
747	Н.Ю. СОКОЛОВА
748	О.М. КОТУЗАКИ
749	Л.Г. ПОЖИТКОВА
750	С.П. КРАЄВСЬКА
751	Н.О. СТЕЦЕНКО
752	Г.М. БАНДУРЕНКО
753	Д.О. ЖИГУНОВ
754	О.С. ВОЛОШЕНКО
755	Н.В. ХОРЕНЖИЙ
756	A.P. BOCHKOVSKYI
757	Р. В. АМБАРЦУМЯНЦ
758	С. С. ОРЛОВА
759	А. В. МАКАРИНСЬКА
760	А. В. ЄГОРОВА
761	Г. Й. ЄВДОКИМОВА
762	А. Г. КУЧЕРУК
763	B. YEGOROV
764	E. VOYETSKA
765	A. TCIUNDYK
766	Б. В. ЄГОРОВ
767	О. Є. ВОЄЦЬКА
768	О. Г. ЦЮНДИК
769	С. М. СОЦ
770	В. Т. ГУЛАВСЬКИЙ
771	І. О. КУСТОВ
772	Г. В. КРУСІР
773	Heinz LEUENBERGER
774	О. О. ЧЕРНИШОВА
775	Н. Я. КИРПА
776	С. А. СКОТАР
777	О. И. ЛУПИТЬКО
778	А. А. РОСЛИК
779	С. В. ВАСИЛЬЄВ
780	Л. В. ФАДЕЕВ
781	Л. С. Л.С. СОЛДАТЕНКО
782	А. П. ЛЕВИЦЬКИЙ
783	А. П. ЛАПІНСЬКА
784	В. І. СІЧКАР
785	О. Й. КАРУНСЬКИЙ
787	A. В. Макаринская
788	S. M. SOTS
789	O. V. BNYIAK
790	О. В. ЛАКІЗА
791	К. П. МАСЛІКОВА
792	М. В. ІЩЕНКО
793	D. O. TYMCHAK
794	Y. Y. KUIANOV
795	L. K OVSIANNYKOVA
796	A. P. BOCHKOVSKYI
797	N. Yu. SAPOZHNIKOVA
798	Г. А. ГОНЧАРУК
799	О. В. ОПРИШКО
800	І. М. ШИПКО
803	І. Є. ДУБОВЕНКО
804	ВОЄЦЬКА О.. Є.
805	І. С. ЧЕРНЕГА
807	М. О. МОГИЛЯНСЬКИЙ
808	І. В. ТЕПЛИХ
809	LIUDMYLA V. FIHURSKA
810	л. к. Овсянникова
811	О. Г. СОКОЛОВСЬКА
812	Л. О. ВАЛЕВСЬКА
813	Л ФАДЕЕВ
816	Л. С. СОЛДАТЕНКО
817	О. П. КАРПОВА
819	Д. О. Жигунов
820	Л. К. ОВСЯННИКОВА
821	В. Д. ОРЕХІВСЬКИЙ
823	O. D. ZHURLOVA
824	А. А. GONCHARUK
825	А. В. Макаринська
826	B. V. YEGOROV
827	N. O. BATIEVSKAYA
828	І. О. РОМАНЧУК
829	Д. О. ЖИГУНОВ
830	Л. К. Овсянникова
831	Л. В. Фадеев
832	F. A. TRISHYN
833	А. В. Макаринская
836	Т. В. САХНО
837	Т. В. РУДАКОВА
838	А. М. ГРИЩЕНКО
839	Е. Д. ЖУРЛОВА
844	В. В. ВОЗІЯН
848	A. P. BOCHKOVSKY
850	О. Г. БУРДО
851	Н. В. ХОРЕНЖИЙ
852	І. Ф. РІЗНИЧУК
853	К. G. IORGACHOVA
854	E. N. KOTUZAKI
855	O. V. MAKAROVA
859	А. Ю. ДРОЗДОВ
860	С. Ю. МИКОЛЕНКО
861	В. Ю. СОКОЛОВ
862	В. В. ПЕНЬКОВА
863	О. В. МАКАРОВА
864	А. С. ИВАНОВА
865	Н. Ю. СОКОЛОВА
866	Irina Melnik
867	Віра Браженко
868	Олена Фесенко
869	Николай БАРАШКОВ
870	Павел ПИСАРЕНКО
871	Богдан Вікторович ЄГОРОВ
872	Ілона Савелівна ЧЕРНЕГА
873	Ігор РІЗНИЧУК
874	Николай СЫЧЕВСЬКИЙ
875	Володимир Гулавський
876	Петро Пивоваров
877	Леонид Фадеев
879	І. В. НІКОЛЕНКО
880	Б. в. ЄГОРОВ
883	А. П. ЛЕВИЦКИЙ
884	И. В. ХОДАКОВ
885	А. П. ЛАПИНСКАЯ
886	Н. А. ТКАЧЕНКО
887	О. О. КУРЕНКОВА
889	П. О. НЕКРАСОВ
890	Л. В. БАЛЯ
891	C. Ю. МИКОЛЕНКО
892	Ю. С. ЧУРСІНОВ
894	А. М. ПУГАЧ
895	С. Ю. ДІДЕНКО
897	Вадим Михайлович Пазюк
898	Валентина Миколаївна Бандура
899	Ігор Іванович Яровий
900	Олена Іванівна Маренченко
901	Євген Олександрович Пилипенко
902	Надія Михайлівна Кушніренко
903	Анна Станіславівна Паламарчук
904	Вікторія Миколаївна Лисюк
905	Ірина Семенівна Калмикова
906	Вікторія Володимирівна Юрковська
907	Людмила Костянтинівна Овсянникова
908	Галина Йосипівна Євдокимова
909	Людмила Олександрівна Валевська
910	Олена Григоріївна Соколовська
911	Надія Григорівна Азарова
912	Галина Всеволодівна Шлапак
913	Людмила Миколаївна Пономарьова
914	Роман Анатолійович Ярощук
915	Ігор Миколайович Коваленко
916	Оксана Іванівна Гузь
917	Любов Миколаївна Тележенко
918	Алла Костянтинівна Бурдо
919	Марина Миколаївна Чебан
920	Микола Георгійович Бужилов
921	Леонід Вікторович Капрельянц
922	Лілія Георгіївна Пожіткова
923	Оксана Сергіївна Шульга
924	Сергій Олександрович Іванов
925	Володимир Васильович Листопад
926	Олександр Григорович Мазуренко
927	Анатолій Тимофійович Безусов
928	Тетяна Анатоліївна Манолі
929	Тетяна Іванівна Нікітчіна
930	Яна Олегівна Баришева
931	Анатолій Павлович Левицький
932	Алла Петрівна Лапінська
933	Ігор Володимирович Ходаков
934	Наталія Василівна Хоренжий
935	Ірина Олександрівна Селіванська
936	Алла Василівна Макаринська
937	Ніна В'ячеславівна Ворона
938	Дмитро Олександрович Жигунов
939	Ольга Сергіївна Волошенко
941	Богдан Вікторович Єгоров
942	Наталія Олександрівна Батієвська
943	Георгій Миколайович Станкевич
944	Алла Василівна Борта
945	Анна Андріївна Пенаки
946	Андрій Валентинович Бабков
947	Марина Валентинівна Желобкова
948	Ганна Ігорівна Палвашова
951	Олена Миколаївна Кананихіна
952	Тетяна Михайлівна Турпурова
953	Ліна Олександрівна Іванова
954	Віктор Петрович Малих
955	Людмила Миколаївна Сагач
956	Наталя Миколаївна Поварова
957	Людмила Анатоліївна Мельник
958	Лина Александровна Иванова
959	Виктор Петрович Малых
960	Игорь Иванович Шофул
961	Ігор Павлович Паламарчук
962	С. В. Крючев
963	Валентина О. Верхоланцева
964	Юлия Олеговна Левтринская
965	Юсеф Альхурі
966	Яна Андріївна Голінська
967	Сергій Георгійович Терзієв
968	А. В. Гаврилов
969	Ігор Віталійович Безбах
970	Всеволод Петрович Мордынский
971	Олег Григорьевич Бурдо
972	Федір Анатолійович Трішин
973	Павло Іванович Светлічний
974	Олександр Романович Трач
975	Юлія Віталіївна Орловська
977	Александр Викторович Зыков
979	Павел Иванович Светличный
980	Давар Ростамі Пур
981	Наталя Володимирівна Ружицька
982	Тетяна Анатолїївна Різниченко
983	Олександр Кирилович Войтенко
984	К. А. Ковалевський
985	М. І. Валько
986	О. І. Мамай
987	Т. О. Кузьмина
988	Т. О. Яковенко
989	О. О. Ляпощенко
990	В. О. Іванов
991	І. В. Павленко
992	М. М. Дем’яненко
993	О. Є. Старинський
994	В. В. Ковтун
995	Дмитрий Николаевич Корінчук
996	Юрій Федорович Снєжкін
997	В. О. Бунецький
998	Антоніна Іванівна Капустян
999	Наталля Кирилівна Черно
1000	Наталія В. Дмитренко
1001	Петро Ігорович Осадчук
1002	Іван І. Дударев
1003	Галина Всеволодівна Крусір
1004	О. А. Сагдєєва
1005	Олеся О. Чернишова
1006	Марія Михайлівна Мадані
1007	Олексій Леонтійович Гаркович
1008	Юрий Анатольевич Селихов
1009	Виктор Алексеевич Коцаренко
1010	Віра Василівна Сабадаш
1011	Ярослав Михайлович Гумницький
1012	Василь Володимирович Дячок
1013	Вікторія Катишева
1014	Сергій Іванович Гуглич
1015	Сергій Мандрик
1016	Ірина Борисівна Рябова
1017	Олена Анатоліївна Петухова
1018	Стелла Анатоліївна Горносталь
1019	Сергій Миколайович Щербак
1020	Наталья Николаевна Сороковая
1021	Дмитрий Николаевич Коринчук
1022	Олег Михайлович Данилюк
1023	Володимир Михайлович Атаманюк
1025	Ірина Олександрівна Гузьова
1027	Тетяна Володимирівна Корінчевська
1029	Володимир А. Михайлик
1030	Олена Анатолівна Бєляновська
1031	Роман Дмитрович Литовченко
1032	Костянтин Михайлович Сухий
1033	Михайло Порфирович Сухий
1034	Михайло Володимирович Губинський
1035	Дмитро Миколайович Симак
1036	В. І. Склабінський
1037	Іван Федорович Малежик
1038	Ігор Володимирович Дубковецький
1039	Л. В. Стрельченко
1040	Леся Юріївна Авдєєва
1041	Е. К. Жукотський
1042	А. А. Макаренко
1043	Жанна Олександрівна Петрова
1044	К. С. Слободянюк
1045	В. О. Туз
1046	Н. Л. Лебедь
1047	Любов Петрівна Гоженко
1048	Анна Євгенівна Недбайло
1049	Георгій Костянтинович Іваницький
1050	Леонід Леонідович Товажнянський
1051	Валерій Євгенович Ведь
1052	Антон Миколайович Миронов
1053	Ф. А. Трішин
1054	О. Р. Трач
1055	Ю. В. Орловська
1056	Л. О. Іванова
1057	О. П. Соколова
1058	В. Х. Кириллов
1059	В. М. Кузаконь
1060	Г. Н. Станкевич
1061	С. Й. Ткаченко
1062	К. О. Іщенко
1063	О. Г. Бурдо
1065	Давар Ростами Пур
1066	Ю. О. Левтринська
1067	Н. А. Ткаченко
1068	С. І. Вікуль
1069	О. В. Севастьянова
1070	О. А. Кручек
1071	Я. А. Гончарук
1072	Н. О. Дец
1073	Л. О. Ланженко
1075	І. А. Дюдіна
1076	Д. М. Скрипніченко
1078	О. П. Чагаровський
1079	Є. О. Ізбаш
1081	Є. О. Котляр
1084	А. В. Копійко
1085	Г. Р. Рамазашвілі
1086	Л. А. Тітомир
1087	О. І. Данилова
1088	О. А. Пацела
1089	Т. В. Маковська
1092	Є. С. Дрозд
1093	І. В. Мельник
1094	С. А. Чуб
1095	Д. О. Гнатовська
1097	В. П. Ковальова
1098	Д. С. Жиронкіна
1099	О. С. Шульга
1100	І.М. Калугіна
1101	Н.А. Дзюба
1102	Ю. В. Грищук
1104	Г. Й. Євдокимова
1105	А.І. Капустян
1106	Н.К. Черно
1107	В. В. Зуб
1110	М. Р. Мардар
1111	І. А. Устенко
1113	А. Макарь
1115	Л. А. Иванова
1116	С. А. Смирнова
1117	Л. Н. Сагач
1119	Н. О. Косицын
1121	С. В. Котлик
1122	М. А. Помазенко
1123	О. В. Ватренко
1124	С. Н. Федосов
1125	А. Е. Сергеева
1126	М. В. Левинский
1131	Э. Ж. Иукуридзе
1133	Т. С. Лозовская
1134	Е. О. Ливенцова
1135	Л. Г. Віннікова
1136	Г. В. Шлапак
1137	І. О. Прокопенко
1138	О. А. Глушков
1139	А. В. Кишеня
1141	К. В. Пронькіна
1143	Ю. С. Українцева
1144	А. С. Авершина
1145	Л. В. Капрельянц
1146	Л. В. Труфкати
1147	Л. А. Крупицкая
1148	І. М. Калугіна
1149	О. О. Килименчук
1150	М. І. Охотська
1152	З М. Романова
1153	М. С. Романов
1155	Л. С. Гураль
1156	О. І Данилова
1157	С. П. Решта
1158	С. Ю. Попова
1159	А. С. Герасим
1160	В. В. Паламарчук
1161	С. А. Памбук
1162	Н. М. Кушніренко
1163	Г. І. Палвашова
1164	Т. А. Маноли
1166	Я. О. Барышева
1167	Н. В. Чибич
1168	А. Т. Безусов
1169	Т. І. Нікітчіна
1170	Л. М. Тележенко
1171	В. В. Атанасова
1172	А. В. Егорова
1174	Г. И. Евдокимова
1175	Т. В. Шпырко
1176	М. І. Бойко
1177	В. Л. Прибильський
1178	Г. В. Крусир
1179	И. П. Кондратенко
1181	Г. П. Хомич
1182	О. М. Горобець
1183	Л. О. Положишникова
1184	И. В. Солоницкая
1185	Г. Ф. Пшенишнюк
1186	Н. С. Ткаченко
1189	О. С. Волошенко
1190	І. В. Брославцева
1191	М. С. Статєва
1192	І. М. Колесніченко
1193	Марина Ромиківна Мардар
1194	Рафаела Рафаелівна Значек
1195	Максим Борисович Ребезов
1196	Юлія Олегівна Левтринська
1197	Олександр Вікторович Зиков
1200	Наталия Владимировна Ружицкая
1201	Татьяна Резниченко
1202	Віктор Миколайович Козін
1203	Богдан Олексійович Вінниченко
1204	Іван ФФедорович Малежик
1205	Т. В. Бурлака
1207	Ольга Петрівна Остапенко
1208	Тарас Григорович Мисюра
1209	Володимир Леонідович Зав'ялов
1210	Олексій Петрович Лобок
1211	Наталія Вікторівна Попова
1212	Юлія Владиславівна Запорожець
1213	Юрий Федорович Снежкин
1216	Сергей Георгиевич Терзиев
1217	Георгій Костянтинович Иваницкий
1218	Жанна Александровна Петрова
1219	Катерина Сергіївна Слободянюк
1222	Олег Григорович Бурдо
1223	Всеволод Петрович Мординський
1224	Ростами Пур Давар
1226	Олена Іванівна Маренчеко
1227	Євген Олександровчи Пилипенко
1228	Олексій Володимирович Катасонов
1230	Олена Віталіївна Гусарова
1231	Раїса Олексіївна Шапар
1233	Дмитро Миколайович Різниченко
1235	Федор Анатольевич Тришин
1236	Александр Романович Трач
1237	Юлия Витальевна Орловская
1238	Олександр Михайлович Ободович
1239	Віталій Володимирович Сидоренко
1241	Альхурі Юсеф
1242	Едуард Юрійович Ананійчук
1243	Денис Сергійович Гончаров
1245	Аліна Василівна Коник
1246	Наталля Леонидівна Радченко
1247	Богдан Ярославович Целень
1251	Катерина Катишева
1257	Дмитро Михайлович Симак
1258	Олександр Михайлович Данилюк
1259	Игорь Витальевич Безбах
1260	Николай Иванович Кепин
1264	Леогид Михайлович Ульев
1265	А. Маатоук
1266	Наталля Василівна Хоренжий
1268	Сергій Миколайович Перетяка
1269	Г. Г. Дєтков
1270	Юрій Петрович Морозов
1271	Джамалутдін Муршидович Чалаєв
1272	Владимир Владимирович Величко
1273	Владимир Яковлевич Керш
1274	А. В. Колесников
1275	С. И. Гедулян
1276	С. А. Твердохлеб
1277	Юрий анатольевич Селихов
1278	Коцаренко Виктор Алексеевич
1279	Давыдов Вячеслав Александрович
1280	Анатолій Андрійович Долінський
1284	Наталія Леонідівна Радченко
1285	Анатолій Петрович Гартвіг
1286	Елена Анатольевна Беляновская
1287	Константин Михайлович Сухой
1288	Елена Викторовна Коломиец
1289	Михаил Порфирьевич Сухой
1290	І І Яровий
1291	О В Катасонов
1292	Д А Харенко
1293	Р Й Мусій
1294	О І Демчина
1295	С В Сиротюк
1296	В П Гальчак
1297	Н О Шаркова
1298	Е К Жукотський
1299	Г В Декуша
1300	Л Ю Авдєєва
1301	Т Я Турчина
1302	С Н Перетяка
1303	П И Осадчук
1304	Ю Ф Снєжкін
1305	Д М Корінчук
1308	М М Безгін
1309	І В Степчук
1310	Д П Кіндзера
1311	В М Атаманюк
1312	Р Р Госовський
1313	Ж О Петрова
1314	Р Б Косів
1315	Н І Березовська
1316	Л Я Паляниця
1317	Т В Харандюк
1318	И В Безбах
1319	О В Коломієць
1320	О А Бєляновська
1321	К М Сухий
1322	О М Прокопенко
1323	Я М Козлов
1324	М П Сухий
1325	Ю А Селихов
1326	В А Коцаренко
1327	К А Горбунов
1328	В А Давыдов
1329	Г Ф Смирнов
1330	А В Зыков
1331	Д Н Резниченко
1336	О П Остапенко
1337	А В Ляшенко
1338	М Л Шит
1339	А К Бурдо
1340	Г К Іваницький
1341	О І Чайка
1342	Л П Гоженко
1343	В А Потапов
1344	Е Н Якушенко
1345	О Ю Гриценко
1346	В М Бандура
1347	М П Швед
1348	Д М Швед
1349	Н Г Воробей
1352	І І Овчарук
1353	С І Бухкало
1354	О Г Бурдо
1355	Юсеф Альхури
1356	Д А Головко
1357	И Д Головко
1358	Б Я Целень
1359	О В Гаращенко
1360	В І Гаращенко
1361	В И Крутякова
1362	М Ю Белоусов
1363	Т Н Осипенко
1364	Т И Бурденко
1365	Н В Шалова
1367	Д Ю Демчук
1368	Н Н Сороковая
1369	Ю Ф Снежкин
1370	Р А Шапарь
1371	Р Я Сороковой
1372	М К Кошелева
1373	С П Рудобашта
1374	С Г Терзиев
1376	С Г Бурдо
1377	Т М Погорілий
1378	А В Рибачок
1379	В М Чорний
1380	Т Г Мисюра
1381	Н В Попова
1383	Ю Ю Прищепа
1384	Н В Лапіна
1385	Г В Ляшко
1389	Ю В Запорожець
1391	Н В Ружицкая
1392	Т А Макаренко
1393	С А Малашевич
1394	Т Ю Дементьева
1395	А В Солодкая
1396	А В Ковальов
1397	И М Мыколив
1398	Л М Коляновська
1399	Н В Дмитренко
1400	І О Гузьова
1402	Б М Микичак
1403	Ю Зейналієва
1404	М М Жеплінська
1405	О С Бессараб
1406	О В Бендерська
1407	І Р Лазарів
1408	В Л Зав’ялов
1410	В С Бодров
1413	В Є Деканський
1416	К М Самойленко
1418	В М Пазюк
1420	О Д Пазюк
1422	Е В Гусарова
1424	Л В Декуша
1425	Л Й Воробйов
1426	Л В Стрельченко
1427	І В Дубковецький
1428	І М Страшинський
1429	І М Малежик
1430	В М Пасічний
1431	Р А Коломієць
1433	І Ф Малежик
1435	Т В Бурлака
1436	Я В Євчук
1440	А Н Поперечный
1441	С А Боровков
1442	А А Долінський
1445	А А Макаренко
1446	М І Мосюк
1447	Ю Я Псюк
1448	І А Рудей
1449	К В Москаленко
1450	В С Ведмедера
1451	А Е Артюхов
1452	В Н Покотыло
1453	А Г Попович
1454	А Р Степанюк
1458	С О Марушевський
1459	І О Дубовкіна
1460	Д В Гиренко
1461	Е А Демянчук
1462	В В Анісімов
1463	П П Єрмаков
1464	Я М Корнієнко
1465	Р В Сачок
1466	С С Гайдай
1467	О В Мартинюк
1468	О В Куріньовський
1469	А М Любека
1470	І Р Барна
1472	І Р Матківська
1473	Н Я Цюра
1475	Л М Ульєв
1476	О О Яценко
1477	В М Шпилька
1478	С Й Ткаченко
1479	С В Дишлюк
1480	Н В Пішеніна
1483	Я М Гумницький
1484	А М Гивлюд
1485	В В Сабадаш
1487	Д М Симак
1488	О А Нагурський
1489	Л М Ульев
1490	М В Ильченко
1491	Б В Косой
1493	Саид Ахмед Омар
1494	А В Коник
1495	Г В Дейниченко
1496	З А Мазняк
1497	В В Гузенко
1498	В П Янаков
1500	І А Зозуляк
1501	О В Зозуляк
1502	И Л Бошкова
1503	Н В Волгушева
1504	І М Берник
1507	В В Дячок
1509	О Б Левко
1512	К О Самойчук
1513	О О Ковальов
1514	О О Ляпощенко
1515	І В Павленко
1516	Р Ю Усик
1517	М М Дем'яненко
1519	Е В Воскресенская
1520	Н Л Радченко
1521	І М Петрушка
1522	М С Мальований
1523	Ю Й Ятчишин
1524	К І Петрушка
1526	Ф А Тришин
1527	А Н Герега
1530	О М Кержакова
1532	Яків М. Корнієнко
1533	Анатолій Р. Степанюк
1534	Леонід Михайлович Ульєв
1535	А Маатоук
1536	М А Васильев
1538	Антонина Васильевна Солодкая
1539	Наталья Александровна Колесниченко
1540	Наталья Викторовна Волгушева
1541	Ирина Леонидовна Бошкова
1542	Ванда Валерьевна Милованова
1543	Валерий Михайлович Яроошенко
1544	Валерій Михайлович Ярошенко
1545	Ванда Валерійовна Мілованова
1546	Дмитро Андрійович Ковальчук
1547	Олександр Васильович Мазур
1548	Сергій Сергійович Гудзь
1550	Сергій Сергійович Стамікосто
1551	Лариса Володимирівна Агунова
1552	Наталія Андріївна Ткаченко
1553	Олександр Петрович Чагаровський
1554	Євгенія Олександрівна Ізбаш
1555	Аліна Валерійовна Копійко
1556	Тетяна Євгенівна Шарахматова
1557	Ганна Сергіївна Танасова
1559	Ірина Анатоліївна Дюдіна
1560	Людмила Андріївна Грегуль
1561	Олександр Віталійович Ватренко
1562	Світлана Юріївна Вігуржинська
1563	Ірина Василівна Мельник
1564	Світлана Анатоліївна Чуб
1566	Ігор Федорович Різничук
1567	Елена Алексеевна Антипина
1568	Світлана Андріївна Памбук
1569	Ганна Станіславівна Герасим
1571	Юлія Вікторівна Левченко
1572	Галина Панасівна Хомич
1573	Наталія Вікторівна Олійник
1574	Олександра Михайлівна Горобець
1576	Надія Іванівна Ткач
1577	Галина Михайлівна Ряшко
1579	Тамара Петрівна Новічкова
1582	Ганна Овсепівна Саркісян
1584	Яків Григорович Верхівкер
1585	Олена Михайлівна Мірошніченко
1586	Кирило Олегович Самойчук
1587	Валерія Валеріївна Паніна
1588	Ольга Володимирівна Полудненко
1589	Микола Іванович Кепін
1590	Станіслав Йосипович Ткаченко
1591	Дмитро Іванович Денесяк
1592	Ксенія Олександрівна Іщенко
1593	Віктор Петрович Куц
1595	Орест Михайлович Марціяш
1596	Олександр Миколайович Гавва
1597	Людмила Олександрівна Кривопляс-Володіна
1598	Анастасія Василівна Деренівська
1599	Микола Володимирович Якимчук
1600	Сергій Володимирович Токарчук
1601	Анна Миколаївна Гивлюд
1604	H. F. Smirnov
1605	A. V. Zykov
1606	D. N. Reznichenko
1607	З. Я. Гнатів
1608	Ірена Євгенівна Никулишин
1610	Ірина Ярославівна Матківська
1611	Ирина Борисовна Рябова
1614	Константин Александрович Горбунов
1615	Сергей Николаевич Быканов
1616	Татьяна Геннадьевна Бабак
1617	Е. В. Сиренко
1618	Ольга Владимировна Горбунова
1619	O. V. Kolomiyets
1620	К. М. Sukhyy
1621	E. A. Belyanovskaya
1622	V. I. Tomilo
1623	O. M. Prokopenko
1624	M. P. Sukhyy
1626	Олександр Олександрович Ковальов
1630	Богдан Сергійович Пащенко
1631	Євгеній Васильович Штефан
1632	Володимир Олексійович Потапов
1633	Станіслав Миколайович Костенко
1637	Віктор Семенович Бодров
1641	Наталия Николаевна Сороковая
1643	Олена Володимирівна Воскресенська
1646	Татьяна Анатольевна Резниченко
1647	Валентина Николаевна Бандура
1649	А. К. Бурдо
1651	Илья Вадимович Сиротюк
1655	Олексій Сергійович Парняков
1656	Ф. Барба
1657	Н. Грімі
1658	Микола Іванович Лебовка
1659	E. Воробьев
1660	Сергій Олексійович Володін
1661	Валерій Григорович Мирончук
1662	Євген Михайлович Семенишин
1663	Надія Ярославівна Цюра
1664	Т. І. Римар
1665	А. С. Крвавич
1666	Діана Петрівна Кіндзера
1668	Р. Р. Госовський
1671	К. М. Самойленко
1672	В'ячеслав Аврамович Михайлик
1673	Ярослав Микитович Корнієнко
1674	Роман Володимирович Сачок
1675	Анна Олександрівна Черемисінова
1680	Леонид Михайлович Ульев
1681	Т. З. Зебешев
1683	Михаил Анатольевич Васильев
1690	Володимир Іванович Щепкін
1691	Dmytry Bolotov
1692	Anna Kravchenko
1693	Sergiy Maksymenko
1694	Antonio Kumpera
1695	Надежда Григорьевна Коновенко
1696	Ирина Николаевна Курбатова
1697	Vladimir Kisil
1698	Koji Matsumoto
1699	Любовь Михайловна Пиджакова
1700	Александр Михайлович Шелехов
1701	Віталій Станіславович Шпаківський
1702	Claire David
1703	Volodymyr Lyubashenko
1704	Leonid Plachta
1705	Олена В'ячеславівна Ноздрінова
1706	Ольга Віталіївна Починка
1707	Ірина Миколаївна Курбатова
1708	Дар'я Віталівна Лозієнко
1709	Евгений Владимирович Черевко
1710	Елена Евгеньевна Чепурная
1711	Томас Уотерс
1712	Olena Karlova
1713	Tomáš Visnyai
1714	Nadiia Konovenko
1715	Irina Kurbatova
1716	Katya Tsventoukh
1717	Marina Grechneva
1718	Polina Stegantseva
1719	Злата Кибалко
1720	Олександр Олегович Пришляк
1721	Roman Shchurko
1722	Kaveh Eftekharinasab
1723	Lyudmila Romakina
1725	Mariia Stefanchuk
1726	Сергей Иванович Максименко
1727	Евгений Александрович Полулях
1729	Ігор Володимирович Протасов
1730	Полина Георгиевна Стеганцева
1731	Марина Александровна Гречнева
1733	Андрій Анатолійович Прус
1734	Сергій Іванович Максименко
1735	Євген Олександрович Полулях
1736	Юлія Юріївна Сорока
1737	Джон Р. Паркер
1738	Лі-Джі Сан
1739	Yuri Zelinskii
1740	Irina Vygovskaya
1741	Hayjaa Kudhair Dakhil
1742	Vadym Myronyk
1743	Volodymyr Mykhaylyuk
1749	Mariia Losieva
1750	Oleksandr Prishlyak
1751	Александр Григорьевич Савченко
1752	Михаил Михайлович Заричный
1755	О. А. Рахула
1756	Н. Г. Коновенко
1757	Є. В. Черевко
1758	О. Є. Чепурна
1759	В. М. Пропкін
1760	О. О. Пришляк
1761	Д. М. Скочко
1762	T. V. Obikhod
1763	A. V. Glushkov
1764	O. Yu. Khetselius
1765	V. V. Buyadzhi
1766	Vasfiye Hazal Özyur
1767	Ayşegül Erdoğan
1768	Zeliha Zeliha Demirel
1769	Meltem Conk Dalay
1770	Semih Ötleş
1771	E. Ghanbari Shendi
1772	D. Sivri Ozay
1773	M.T. Ozkaya
1774	N.F. Ustunel
1775	Asiye Ahmadi-Dastgerdi
1776	Hamid Ezzatpanah
1777	Sedighe Asgary
1778	Shahram Dokhani
1779	Ebrahim Rahimi
1780	Majid Gholami-Ahangaran
1781	L. Peshuk
1782	O. Gorbach
1783	O. Galenko
1784	L. Vovk
1785	A. Hryshchenko
1786	O. Bilyk
1787	Yu. Bondarenko
1788	V. Kovbasa
1789	V. Drobot
1790	B. Yegorov
1791	Т. Turpurova
1792	E. Sharabaeva
1793	Y. Bondar
1794	M. Mardar
1795	M. Stateva
1796	А. Yegorova
1797	G. Evdokimova
1798	I. Ustenko
1799	S. Masanski
1800	І. Piliugina
1801	M. Artamonova
1802	N. Murlykina
1803	О. Shidakova-Kamenyuka
1804	O. Pivovarov
1805	O. Kovaliova
1806	М. Bilko
1807	М. Ishchenko
1808	О. Tsyhankova
1809	Т. Yakovenko
1810	Т. Кyrpel
1811	V. Skliar
1812	G. Krusir
1813	V. Zakharchuk
1814	I. Kovalenko
1815	T. Shpyrko
1816	L. Ovsiannykova
1817	L. Valevskaya
1818	V. Yurkovska
1819	S. Orlova
1820	O. Sokolovskaya
1821	T. Nosenko
1822	T. Koroluk
1823	S. Usatuk
1824	G. Vovk
1825	T. Kostinova
1826	E. Iorgachev
1827	H. Korkach
1828	T. Lebedenko
1829	O. Kotuzaki
1830	J. Kozonova
1831	L. Telegenko
1832	A. Salavelis
1833	G. Sarkisian
1835	P. Golubkov
1837	V. Honhalo
1838	K. Habuiev
1839	O. Burdo
1841	L. Melnyk
1842	I. Shevchenko
1843	E. Aliiev
1844	M. Paska
1845	L. Bal-Prylypko
1846	O. Masliichuk
1847	M. Lychuk
1848	V. Pasichnyi
1849	N. Bozhko
1850	V. Tischenko
1851	Ye. Kotliar
1852	M. Holovko
1853	T. Holovko
1854	А. Gelikh
1855	M. Zherebkin
1857	A. Makarynska
1858	I. Cherneha
1859	A. Oganesian
1860	O. Bunyak
1861	S. Sots
1862	A. Egorova
1865	M. Aider
1866	E. Olkhovatov
1867	L. Pylypenko
1868	T. Nikitchina
1869	G. Kasyanov
1870	V. Yukalo
1871	K. Datsyshyn
1874	V. Kozhevnikova
1875	T. Novichkova
1876	A. Dubinina
1877	T. Letuta
1878	T. Frolova
1879	H. Seliutina
1880	O. Hapontseva
1881	N. Cherno
1882	S. Ozolina
1883	T. Bytka
1884	N. Tkachenko
1885	L. Lanzhenko
1886	D. Skripnichenko
1888	А. Hanicheva
1889	Zahra Rasouli
1890	Mahdi Parsa
1891	Hossein Ahmadzadeh
1892	L. Levandovsky
1893	М. Kravchenko
1894	N. Kigel
1895	I. Melnik
1896	O. Naumenko
1897	A. Kapustian
1898	O. Antipina
1899	R. Budiak
1900	A. Shevchenko
1901	O. Stepanets
1902	A. Sokolenko
1904	М. Malovanyy
1906	О. Holodovska
1907	A. Masikevych
1908	О. Savinok
1909	N. Azarova
1910	О. Arsiriy
1911	А. Nikolenko
1912	D. Zhygunov
1913	V. Kovalova
1914	M. Kovalov
1915	A. Donets
1916	К. Iorgachova
1917	O. Makarova
1919	K. Avetisіan
1921	Usef Alhurie
1922	I. Syrotiuk
1923	Ju. Levtrynskaya
1924	Davar Rosmami Pur
1925	O. Gorodyska
1926	N. Grevtseva
1927	O. Samokhvalova
1928	O. Savchenko
1929	A. Grygorenko
1930	O. O. Bondarchuk
1931	A. Soletska
1932	K. Nistor
1933	V. Hevryk
1934	E. Ghanbari Shend
1936	M . T. Ozkaya
1937	N. F. Ustunelc
1938	N. Коndratjuk
1939	Ye. Pyvovarov
1940	Т. Stepanova
1941	Yu. Matsuk
1942	S. Belinska
1943	S. Levitskaya
1944	N. Каmienieva
1945	А. Roskladka
1946	O. Kitayev
1947	О. Kochubei-Lytvynenko
1948	O. Nikitina
1951	N. Stankova
1952	T. Gogova
1953	L. Paramonenko
1958	T. Cherevaty
1959	T. Brykova
1960	O. Samohvalova
1962	K. Kasabova
1965	H. Selyutina
1969	A. Pivovarov
1970	S. Mykolenko
1971	Y. Hez’
1972	S. Shcherbakov
1973	O. Kupchyk
1974	V. Koltunov
1975	K. Kalaida
1976	A. Zabolotna
1977	T. Volkova
1978	V. Derevenko
1981	O. Fursik
1982	I. Strashynskiy
1983	V. Pasichny
1987	О. Nikulina
1990	M. Polumbryk
1992	V. Litvyak
1993	E. Malinka
1994	S. Beltyukova
1995	V. Boychenko
1997	L. Storozh
1999	O. Krupa
2000	T. Mudrak
2001	A. Kuts
2002	S. Kovalchuk
2003	R. Kyrylenko
2004	N. Bondar
2005	L. Krupytska
2006	L. Kaprelyants
2007	L. Trufkati
2008	T. Velichko
2009	V. Kirilov
2014	S. Bondar
2015	O. Chabanova
2016	T. Sharakhmatova
2017	A. Trubnikova
2018	N. Kordzaia
2020	N. Penkina
2021	L. Tatar
2022	А. Оdаrchеnco
2023	V. Demchenko
2024	N. Shmatchenko
2026	O. Aksonova
2027	S. Oliinyk
2028	О. Kovalenko
2029	V. Novoseltseva
2030	N. Kovalenko
2031	O. Benderska
2032	А. Bessarab
2033	V. Shutyuk
2034	О. Sagdeeva
2036	A. Tsykalo
2037	Т. Shpyrко
2038	H. Leuenberger
2039	O. Cherevko
2040	V. Mykhaylov
2041	A. Zahorulko
2043	A. Borysova
2044	I. Bilenka
2045	Ya. Golinskaya
2047	H. Martirosian
2048	Ali Aberoumand
2049	Saeed Ziaei nejad
2050	Frideh Baesi
2051	Zahrah Kolyaee
2054	I. Kolomiіets
2056	Ju. V. Nazarenko
2057	N. Dets
2058	E. Izbash
2059	I. Klymentieva
2061	M. Khrupalo
2064	І. Grуshоva
2065	T. Shеstаkоvskа
2067	O. Chagarovskyi
2069	E. Sevastyanova
2071	I. Slyvka:
2072	O. Tsisaryk
2073	L. Musiy
2074	M. Pogozhikh
2075	T. Golovko
2076	A. Pak
2077	A. Dyakov
2078	А.П. Палій
2079	К.О. Родіонова
2082	E. Bilyk
2083	I. Kyryliuk
2084	Ye. Kyryliuk
2085	O. Priss
2086	V. Yevlash
2087	V. Zhukova
2088	I. Ivanova
2091	T. Khromenko
2092	Z. Shuliakevych
2093	V. Atamanyuk
2094	I. Huzova
2095	Z. Gnativ
2096	O. Tovchiga
2097	O. Koyro
2098	S. Stepanova
2099	S. Shtrygol’
2100	V. Evlash
2101	V. Gorban’,
2102	T. Yudkevich
2103	K. Mikhaylova
2104	L. Telezhenko
2105	E. Shtepa
2106	Л.О. Кривопляс-Володіна
2107	О.М. Гавва
2108	С.В. Токачук
2110	P. Nekrasov
2111	A. Avershina
2112	Ju. Ukrainceva
2113	I. Pylypenko
2115	G. Yamborko
2116	I. Marinova
2117	I. Kuznecova
2118	K. Janchenko
2119	I. Kalugina
2120	S. Vikul
2121	Yu. Novik
2122	A. Dyakonova
2123	V. Stepanova
2125	Д.В. Федорова
2126	М.П. Головко
2127	Т.М. Головко
2128	Л.О. Крикуненко
2130	O. Zhurlova
2132	L. Pozhitkova
2133	N. A. Tkachenko
2134	O. A. Kruchek
2135	A. V. Kopiyko
2136	G. R. Ramazashvili
2137	О.І. Потемська О.І.
2138	Н.Ф. Кігель
2139	С.Г. Даниленко
2140	К.В. Копилова
2141	Н.Ye. Dubova
2142	B.V. Yegorov
2143	A.T. Bezusov
2144	V.I. Voskoboinyk
2145	A. Pogrebnyak
2146	V. Pogrebnyak
2147	М. І. Погожих
2148	Д. М. Одарченко
2149	Є. Б. Соколова
2150	І. М. Павлюк
2151	І. В. Пилипенко
2152	Л.М. Пилипенко
2153	О.С. Ільєва
2154	Г.В. Ямборко
2155	L. Osipova
2156	V. Kirillov
2157	N. Khudenko
2158	T. Sugachenko
2159	А.Т. Безусов
2160	О.В. Тоценко
2161	O. Tkachenko
2162	A. Pashkovskiy
2165	Ie. Cherednychenko
2166	С.С. Андрєєва
2167	М.Б. Колеснікова
2168	N. Tregub
2169	A. Zykov
2170	L. Kapreluants
2173	L. Trufkti
2174	V. Ostapenko
2176	E. Iukuridze
2177	G. Didukh
2178	Н. Гринченко
2179	Д. Тютюкова
2180	П. Пивоваров
2181	М. Кепін
2185	Ya. Honcharuk
2187	T. Davydenko
2188	О. Дишкантюк
2189	А. Андріянова
2190	O. Bocharova
2192	D. Hnatovskaya
2193	S. Chub
2194	A. Kapustyan
2200	J. Kalugina
2202	M. Hkrupalo
2204	G. Krutovyi
2205	A. Zaparenko
2209	N. Stavnicha
2210	М. I. Kepin
2211	О.М. Нікіпелова
2212	N.V. Мriachenko
2213	S.L. Iurchenko
2214	T.V. Cheremska
2215	М.Ф. Кравченко
2216	Н. Ю Ярошенко
2217	O. Kovalenko
2218	K. Kormosh
2219	K. Iorgachova
2221	K. Khvostenko
2222	M. Ianchyk
2223	O. Niemirich
2224	A. Gavrysh
2225	Y. Kotlyar
2226	Т. Goncharenko
2227	O. Topchiy
2228	А.А. Дубініна
2229	С.О. Ленерт
2230	Т.М. Попова
2231	O. Glushkov
2232	О. Shulga
2233	А. Chorna
2234	L. Аrsenieva
2237	A. Lilishentseva
2238	H. Burlaka
2239	V.V. Shutyuk
2240	М.І. Кепін
2241	В.Х. Кирилов
2245	Л. Эланидзе
2246	В.І. Дробот
2247	О.П. Іжевська
2248	Ю. В. Бондаренко
2249	О.А. Глушков
2250	А.І. Українець
2251	В.М. Пасічний
2252	Ю.В. Желуденко
2253	М.М. Полумбрик
2254	М.О. Полумбрик
2255	Є.О. Котляр
2256	Х.В. Омельченко
2259	Р.Б. Косів
2260	Л.Я. Паляниця
2261	Н.І. Березовська
2262	Т.В. Харандюк
2263	С.В Бельтюкова
2264	Е.В. Малинка
2265	Е.О. Ливенцова
2266	М.П. Сичевський
2267	В.Ю. Лизова
2268	Л.І. Войцехівська
2269	К.О. Данілова
2270	А. Petrosyants
2271	А. Kapustyan
2275	В. А. Хомічук,
2276	О. І. Бескровний
2277	В. В. Макаринський
2278	М. І. Кепін
2279	Т. М. Поп,
2280	I. R. Belenkaya
2281	Ya. A. Golinskaya
2282	О. А. Коваленко
2283	В. М. Ковбаса
2284	Б. В. Гребень
2285	В. Ю. Нагорний
2286	Т. М. Купріянова
2287	Н. К. Черно
2288	С. О. Озоліна
2289	О. В. Нікітіна
2290	Т. А. Овсянникова
2291	Л. В. Кричковская
2292	Ю. П. Звягінцева-Семенець
2293	Ю. В. Камбулова
2294	І. О. Соколовська
2295	О. Б. Кобилінська,
2296	М Колесник,
2297	L. G. Vinnikova,
2298	K. V. Pronkina
2299	С. В. Бельтюкова,
2300	Е. В. Малинка
2301	В. Д. Бойченко
2302	Ю. С. Ситникова
2303	L. Vinnikova,
2304	A. Kishenya
2305	I. Strashnova
2306	A. Gusaremko
2307	Н. К. Черно,
2309	К. І. Науменко
2310	А. В. Антоненко
2311	В. С. Михайлик
2312	Е. Г. Иоргачева
2313	Л. В. Гордиенко
2314	А. В. Макарова
2315	А. Н. Котузаки
2316	Н. А. Дзюба
2317	А. Р. Антонова
2318	О. В. Землякова
2319	Н. П. Худенко
2320	Л Ю. Філіпова,
2321	Н. А. Ракуленко
2322	Т. А. Сильчук
2323	В. І. Зуйко
2324	В. В. Цирульнікова
2325	А. М. Дорохович
2326	О.С С. Божок
2327	Л. С. Мазур
2328	А. В. Георгиева
2329	С. Г. Олійник
2330	Г. В. Запаренко
2331	О. Г. Дьяков
2333	О. О. Лівенцова
2334	Н. С. Трегуб
2337	Г. М. Лозовська
2340	І. М. Силка
2341	Н. Е. Фролова
2342	В. С. Гуць
2343	А. Forsiuk
2344	О. Pylypenko
2345	A. Golub
2346	Ya. Zasiadko
2347	V. Voznyy
2348	R. Gryshchenko
2349	В. В. Горін
2350	В. В. Середа
2351	П. О. Барабаш
2352	O. Ya. Khliyeva
2353	D. A. Ivchenko
2354	K. Yu. Khanchych
2355	I. V. Motovoy
2356	V. P. Zhelezny
2357	A. M. Radchenko
2358	Y. Zongming
2359	B. S. Portnoi
2360	V. S. Kornienko
2361	R. Radchenko
2362	M. Pyrysunko
2363	M. Bogdanov
2364	Yu. Shcherbak
2365	С. М. Ванєєв
2366	Д. В. Мірошниченко
2367	В. О. Журба
2368	Я. В. Знаменщиков
2369	В. М. Бага
2370	Т. С. Родимченко
2371	O. Chekh
2372	S. Sharapov
2373	V. Arsenyev
2375	D. Konovalov
2377	M. Radchenko
2378	І.О. Константинов
2379	М. Г. Хмельнюк
2380	О. Ю. Яковлева
2381	С. А. Русанов
2382	К. В. Луняка
2383	Д. В. Коновалов
2384	Н. Б. Андрєєва
2385	Н. В. Жихаpєва
2386	Є. О. Бабой
2387	А. М. Басов
2388	М. А. Пирисунько
2389	А. М. Радченко
2390	Я. Зонмін
2391	С. А. Кантор
2392	Б. С. Портной
2393	Ю. В. Байдак
2394	І. А. Вереітіна
2395	С. А. Коробко
2396	Є. І. Трушляков
2397	М. І. Радченко
2399	В. С. Ткаченко
2400	П. Ф. Стоянов
2401	А. Є. Денисова
2402	Л. І. Морозюк
2403	Альхемірі Саад Альдін
2404	Г. В. Лужанська
2406	Т. В. Кунуп
2407	Б. Л. Пустовий
2408	В. Л. Бондаренко
2409	Ю. М. Симоненко
2410	Л. Н. Цветковская
2411	Д. П. Тишко
2412	И. В. Мотовой
2413	В. П. Железный
2414	О. Я. Хлиева
2415	Т. В. Лук'янова
2416	О. Я. Хлієва
2417	Ю. В. Семенюк
2418	В. П. Желєзний
2419	С.Г. Корнієвич
2420	E. I. Альтман
2421	І. Л. Бошкова
2422	Н. В. Волгушева
2423	Л. З. Бошков
2424	О. С. Бодюл
2425	А. С. Титлов
2426	О.Б. Васылив
2427	Д. Б. Адамбаев
2428	В. А. Арсірій
2429	Б. А. Савчук
2430	M.B. Kravchenko
2431	О.С. Подмазко
2432	І.О. Подмазко
2433	Н.О. Піщанська
2436	Н. А. Прусенков
2437	Ю.А. Козонова
2439	В.Г. Приймак
2440	І. М. Іщенко
2441	О. С. Тітлов
2442	Д.О. Івченко
2443	І.В. Мотовий
2444	О.Я. Хлієва
2445	В.П. Желєзний
2446	В.И. Милованов
2447	Д.А. Балашов
2448	В.Л. Бондаренко
2449	Ю.М. Симоненко
2451	Б.О. Пилипенко
2452	С.А. Бигун
2453	M. Kalinkevych
2454	V. Ihnatenko
2455	O. Bolotnikova
2456	O. Obukhov
2457	О. М. Томчик
2459	М. І. Гоголь
2460	І.О. Константінов
2462	О. Г. Федоров
2463	М.М. Лук'янов
2465	О.Ю. Мельник
2468	A. V. Doroshenko
2469	V. F. Khalak
2474	Г. О. Кобалава
2475	В. В. Соколовська-Єфименко
2476	С. В. Гайдук
2477	А. В. Мошкатюк
2478	В. Ю. Єрема
2483	Е. І. Трушляков
2485	А. А. Зубарєв
2487	М. Г. Глава
2488	Є. В. Малахов
2489	И. Л. Бошкова
2490	А. В. Солодкая
2491	Е. С. Бодюл
2492	Э. И. Альтман
2495	М. Petrenko
2496	S. Artemenko
2497	D. Nikitin
2498	Г. В. Лужанськa
2499	Н.В. Жихарєва
2502	О. Бурдо
2507	К. Габуев
2509	Л. М. Якуб
2511	Т.В. Лук'янова
2512	Ю.В. Семенюк
2516	Р.М. Радченко
2517	М.А. Пирисунько
2518	Б.В. Косой
2519	Н. О. Князєва
2522	Yurii Baidak
2523	Iryna Vereitina
2525	Т. С. Снігур
2526	A. О. Стукаленко
2527	І. С. Бобрікова
2528	Т. Н. Барабаш
2529	В.І. Сахаров
2530	С.В. Сахарова
2532	Е.А. Осадчук
2533	Н.А. Биленко
2534	С. О. Бігун
2535	М. С. Хорольський
2536	A. Gerasim
2537	S. Patyukov
2538	N. Patyukova
2539	К.М. Сухий
2540	Я.М. Козлов
2541	О.А. Бєляновська
2542	О.М. Прокопенко
2543	І.В. Суха
2544	О.В. Дорошенко
2545	И.Л. Бошкова
2546	Н.В. Волгушева
2548	M.A. Petrenko
2549	V. A. Mazur
2554	Р. В. Грищенко
2555	Я. І. Засядько
2556	О. Ю. Пилипенко
2557	А. В. Форсюк
2558	М. А. Петренко
2559	C. В. Артеменко
2560	С. А. Задорожный
2561	С. Г. Потапов
2563	С. А. Бигун
2564	B. V. Kosoy
2565	Y. Utaka
2566	M. B. Kravchenko
2569	Т. А. Сагала
2570	В. Н. Артюх
2571	Т. В. Дьяченко
2572	В .Й. Лабай
2573	О .М. Довбуш
2574	В. Ю. Ярослав
2575	О. В. Омельчук
2576	O.Y. Yakovleva
2577	M.G. Khmelniuk
2578	O.V. Ostapenko
2579	П.Ф. Стоянов
2580	Н.О. Біленко
2581	Я.О. Стоянов
2582	П. Б. Ломовцев
2583	С. В. Болтач
2584	Н. Ф. Митрофанова
2585	Б. Г. Шинко
2586	Ю. И. Журавлев
2587	С. Л. Жуковецька
2590	В.А. Мазур
2591	Л.Ф. Смирнов
2593	М.Г. Хмельнюк
2594	А. В. Лужанская
2596	А. О. Холодков
2598	О. А. Титлова
2599	Д. М. Попков
2600	А. В. Луняка
2601	В. С. Кржевицький
2602	Е. В. Смирнова
2604	О. В. Ольшевская
2605	Н. В. Жихарєва
2607	Б. А. Кутний
2608	А. М. Павленко
2609	Н. М. Абдуллах
2610	А.С. Титлов
2611	А.О. Холодков
2613	В. В. Соколовська
2616	О.С. Бодюл
2620	В. Б. Владимирова
2621	Л.М. Зіменко
2622	С.М. Дубна
2623	А.А. Гурский
2624	А.Е. Гончаренко
2625	Н.А. Пантелюк
2626	И. С. Козаченко
2627	S. Petushenko
2628	Н.В. Жихаpєва
2629	Є.О. Бабой
2630	Р.Е. Талибли
2631	Н.О. Жихарєва
2632	V. Rogankov
2633	M. Shvets
2634	O. Rogankov
2635	C.А. Мороз
2636	Н. Н. Лукьянов
2639	Т.В. Дьяченко
2640	В.Н. Артюх
2642	А.А. Климчук
2643	А.В. Лужанская
2644	А.Н. Шраменко
2645	А.В. Солодкая
2647	В. А. Матухно
2649	П. Томлейн
2651	И.Н. Ищенко
2652	О.А. Титлова
2654	Ю. A. Очеретяный
2655	M. Khmelniuk
2656	D. Vazhinskyi
2657	O. Ostapenko
2658	V. V. Trandafilov
2659	M. G. Khmelniuk
2660	Л. И. Морозюк
2662	Б. Г. Грудка
2663	Д. В. Коржук
2665	В.В. Горін
2668	Л. Ф. Смирнов
2669	ХуиЮй Чжоу
2670	А. В. Kоролев
2671	C. А. Мороз
2674	А. А. Петрик
2675	И. Г. Яковлева
2676	Ю.В Байдак
2677	М. Масарік
2678	В.А Матухно
2679	В.В. Афтанюк
2680	С. К. Бандуркин
2681	С. Е. Жолудь
2682	М. М. Аль-Даби
2683	А. В. Дрозд
2684	М. О. Дрозд
2685	И. Н. Николенко
2686	A. E. Denysova
2687	G. V. Luzhanska
2688	I. O. Bodnar
2689	A. S. Denysova
2692	Н.А. Колесниченко
2693	О. Б. Васылив
2696	Е. А. Осадчук
2697	В. Х. Кирилов
2702	М. А. Дрозд
2707	І. М. Ніколенко
2708	В. О. Мазур
2711	P. Tomlein
2712	T. Manoli
2714	N. Kushnirenko
2716	Д. О. Івченко
2718	І. В. Мотовий
2719	К. О. Шестопалов
2722	Д. І. Гарасим
2723	В. Й. Лабай
2725	Ю. О. Очеретяний
2727	О. В. Остапенко
2729	В. М. Галкін
2730	V. О. Bedrosov
2732	O. Yu. Yakovleva
2734	O. Zimin
2735	I. Podmazko
2737	И.Н. Николенко
2739	Д.Г. Паску
2741	Н.А. Князева
2742	В. Е. Когут
2743	Е. Д. Бутовский
2744	В. М. Бушманов
2746	А.В. Овсянник
2747	Д.С. Трошев
2748	Д. О. Пупков
2750	Н. А. Колесниченко
2751	N. V. Волгушева
2753	A. Doroshenko
2754	K. Shestopalov
2755	I. Mladionov
2757	Ю. А. Очеретяный
2758	А. В. Королев
2761	Ю. С. Федченко
2764	Д. И. Важинский
2770	А. В. Дорошенко
2773	К. В. Людницкий
2774	В. В. Мелехин
2775	А. С. Мных
2777	М. Ю. Пазюк
2778	А. А. Вассерман
2779	А. С. Бойчук
2782	Olga V. Olshevska
2783	N. O. Kniazieva
2784	S. V. Shestopalov
2785	V. Z. Geller
2786	N. I. Lapardin
2788	A. S. Nikulina
2789	M. P. Polyuganich
2790	S. S. Ryabikin
2792	I. Butovskyi
2793	V. Kogut
2794	N. Zhikhareva
2796	Alexander Doroshenko
2797	Kostyantyn Shestopalov
2798	Ivan Mladionov
2799	Vladimir Goncharenko
2800	Paul Koltun
2801	Y. Zasiadko
2802	O. Pylypenko
2803	A. Forsiuk
2807	O. Y. Yakovleva
2808	В. П. Кравченко
2809	Є. В. Кравченко
2811	В. І. Перепека
2813	С. О. Шарапов
2814	В. М. Арсеньев
2816	М. П. Полюганич
2817	С. С. Рябикин
2818	А. С. Никулина
2823	С. Г. Сиромля
2824	Хасан Весам Анвар Али
2829	В. А. Гончаренко
2830	И. Ю. Младенов
2831	А. Н. Цапушел
2832	Н. А. Борисов
2833	В. В. Мирошниченко
2835	О. Г. Голубков
2836	Yu. Baidak
2837	V. Matukhno
2838	V. Chaikovskiy
2840	М. Б. Кравченко
2841	Т. Л. Лозовский
2842	Н. А. Шимчук
2845	L. N. Yakub
2846	O. S. Bodiul
2847	М. І. Лапардін
2848	В. З. Геллер
2850	О. Ю. Розіна
2851	В. Б. Роганков
2853	К. А. Розов
2855	Б. О. Усенко
2856	Г В. Кошлак
2858	Е. В. Кравченко
2860	Е. Н. Ткачева
2864	Ю. И. Демьяненко
2867	A. V. Ostapenko
2871	В. А. Смик
\.


--
-- TOC entry 2949 (class 0 OID 16868)
-- Dependencies: 203
-- Data for Name: journals; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.journals (id_journal, title, title_en) FROM stdin;
0	Unknown	Unknown
3	Зернові продукти і комбікорми	Grain Products and Mixed Fodder’s
4	Наукові праці	Scientific Works
2	Економіка харчової промисловості	Food Industry Economics
5	Харчова наука і технологія	Food Science and Technology
1	Автоматизація технологічних i бізнес-процесів	Automation of technological and business processes
7	Холодильна техніка та технологія	Refrigeration Engineering and Technology
6	Праці міжнародного геометричного центру	Proceedings of the International Geometry Center
\.


--
-- TOC entry 2950 (class 0 OID 16878)
-- Dependencies: 204
-- Data for Name: keywords; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.keywords (id_keyword, word) FROM stdin;
0	Unknown
2	загрязнение атмосферы
3	мониторинг
4	моделирование
5	прогнозирование
6	электронная карта
7	объектная модель
8	модифікатор
9	паливо
10	гідравлічний удар
11	нечітка логіка
12	нестаціонарність
13	запас стійкості
14	система керування
15	робастність
16	дослідження
17	тепловий насос
18	утилізація тепла
19	статичні характеристики
20	динамічні характеристики
21	методы передачи информации
22	цифровая связь
23	позиционные коды
24	кодовое слово
25	кодовые конструкции
26	таймерные сигнальные конструкции
27	найквистовый элемент
28	найквистовый интервал
29	математична модель
30	розподілені параметри
31	ідентифікація
32	технологічний процес
33	прогнозувальна модель
34	балкер
35	судновий стрічковий конвеєр
36	стрічка
37	ролик
38	експлуатація
39	ремонт
40	обслуговування
41	control
42	ecological efficiency
43	technical object
44	automatic control system (ACS)
45	boiler-furnace system
46	environment
53	Искусственный интеллект
54	NPC
55	нечеткое множество
56	нечеткая логика
57	компьютерные игры
58	принятие решения
59	постортогональное пространство
60	modeling
61	software
62	automation of engineering calculations
63	comparative analysis
64	Человеко-машинный интерфейс
65	компьютерная система автоматизации
66	ионно-плазменная установка
67	Синхронизация генераторов
68	дуальное управление
69	адаптивная система
70	подгонка частоты
71	алгоритмы управления
72	перегрузка зерна
73	поточно-транспортные линии
74	производительность
75	энергозатраты
76	автоматизированная система оптимизации загрузки
77	синтез САУ процессом нагрева пельменя кубической формы
78	САР температуры нагрева теста пельменя
79	САО температуры нагрева теста пельменя
80	полуфабрикаты пельменной продукции
82	regulatory conditions
83	wear-out
85	technological efficiency
86	automation
87	renovation
88	схема переробки виноградних вичавків
89	інфрачервона сушарка
90	система автоматичного регулювання з компенсацією зовнішніх збурень
91	механічний диспергатор
92	температурне поле
93	неоднорідне псевдозрідження
94	розподілення
100	аймерные сигнальные конструкции
103	экзоскелет
104	андроид
105	Honda
106	Boston Dynamycs
107	НАСА
108	Asimo
109	робот
110	Atlas
111	DURUS
112	FEDOR
113	self-tuning automatic control system
114	hammer mill mathematical model
115	simulation
116	semi-industrial trials
117	сушіння
118	моделювання
119	теплоносій
120	діоксид титану
121	сушильний апарат
122	вологовміст
123	кінетика
124	виробництво ентомофагів
125	метод
126	енергоефективне керування
128	графітування
129	піч Ачесона
130	температурні режими
131	температура
132	нагрівання
133	охолодження
134	ступінь графітування
137	оптимальное управление
138	взрыв
139	взрывоопасность
140	потенциально взрывоопасный объект
141	длина преддетонационного участка
142	час вистоювання
143	заміс тіста
144	спиртове бродіння
145	об’єм тістової заготовки
146	выборка
147	диагностирование
148	классификация
149	класс
150	кластер
151	метрика
152	экземпляр
153	Система автоматичного керування
154	автоматизоване робоче місце оператора
155	мікропроцесорний контролер
156	турбінний цех
157	цукровий завод
158	Інтернет-речей
159	мікроконтролерний пристрій
160	стиглість винограду
161	виноробство
162	інваріантний
163	збурення
165	автокермовий
166	курсовий кут
168	динаміка судна
169	web
170	web application
171	repository
172	information management system.
173	педагогічні інновації
174	сучасні технології
175	процес навчання
176	інтуїтивне мислення
177	асоціативне та логічне мислення
178	мотивація
179	электрическая модель
180	взвешенный ориентированный граф
181	кратчайший путь
182	метод узловых потенциалов
183	метод установления
184	веб
185	веб-додаток
186	REST
187	API
188	сервер
189	архітектура клієнт-сервер
190	односторінковий додаток
191	клієнтська частина
192	серверна частина
193	programmer
194	automatic control system
195	non-linear time areas.
196	системи
197	управління
198	об'єкт
199	гексапод
200	функціональні схеми
201	ORM
202	client-server
203	HTML
204	CSS
205	python
206	MVC
207	автоматизоване робоче місце
208	автоматизований експеримент
215	випарна станція
217	якість сировини
218	автоматизована система
219	інтелектуальний аналіз даних
220	кластеризація.
223	client-server architecture
224	MPA
225	SPA.
226	Tests
228	testing
229	Web Application
230	automation testing
231	Front-End
232	PhantomJS
233	Selenium
234	Web Driver
235	Нейронная сеть
236	машинное обучение
237	система обнаружения вторжений
238	защита веб-приложений
239	информационная безопасность
240	токенизация.
241	Індустрія 4.0
242	промисловий інтернет речей
243	SCADA-програма
244	PLC
245	хмарна платформа
246	інтеграція
247	OPC UA
248	програмний шлюз
249	апаратний шлюз.
251	сеть Петри
252	координирующая система
253	обучение с подкреплением
254	интеллектуальная система
255	автоматический синтез сети Петри
256	HTTP
257	SOAP
258	REST API
259	URI
260	HATEAOS
261	JSON
262	XML
263	безконтактний двигун постійного струму
264	автономний плавальний апарат
265	електрорух.
266	запаси зерна
267	зерновий елеватор
268	система масового обслуговування
269	модель.
271	adjustable object (AO)
272	model.
273	Ознака
274	навчання
275	нейрон
276	нейронна мережа
277	помилка
278	градієнт.
279	dependency injection
282	html
283	css
284	javascript
285	MVC.
286	computational fluid dynamics
287	three-dimensional layout
288	flowmeter
289	mass flow
290	CFD-simulation.
291	fuzzy logic
292	fuzzy controller
293	discomfort index
294	microclimate
295	HVAC
296	temperature
297	humidity.
298	infrared radiators
299	biological feedback
300	symptoms
301	research methodology
302	grain reloading
303	flow-transport lines
304	productivity
305	energy consumption
306	automated loading optimization system.
307	robot
308	drone
309	robotics
312	mathematical model.
313	Human-machine interface
314	HMI
315	explosive production
316	gas processing
317	situational awareness
318	design problems
319	feeder
320	weight continuous dosing
321	conveyor belt scales
322	simulation modeling
323	multi-agent systems
324	ontology OWL
325	object protection
326	energy efficiency
327	agent-based approach.
328	controlled variable spectral density
329	automatic control systems
330	spectral density model
331	parameters of the object model
332	formal model
333	informative model
334	technological type control objects
335	identification
336	heating
338	solar collector
339	heat pump.
340	Environmental friendliness
342	worn-out equipment
343	partial renewal
344	technological efficiency of functioning
345	ecological compatibility
346	environmental environment
348	management.
349	thermal power plant
350	operating efficiency
351	target optimization function
352	marginal energy costs.
353	механіка
354	інженерна механіка
355	механізація
356	автоматизація
357	робототехніка
358	комп’ютерні науки.
359	computer system
360	computer technologies
361	individual learning pathway individual student card
362	motivation tasks for laboratory training.
363	програмна система
364	генеративна лінгвістика
365	мова програмування
366	граматика
367	продукція
368	аксіома
369	алфавіт
370	ланцюжок
371	символ.
372	mobile robots
373	control systems
374	traffic guidance
375	android
376	architecture
377	clean architecture
378	architecture components
379	model-view-presenter
380	architecture layers
381	dependency rule
382	dependency injection.
383	Neural network
384	machine learning
385	intrusion detection system
386	protection of web applications
387	information security
388	перевантаження зерна
389	потоково-транспортні лінії
390	продуктивність
391	енергоефективність
392	безаварійність
393	оптимізація
394	система автоматичного керування
395	каскадна структура
396	що комутується.
397	автоматическая система управления
398	котел
399	нагрузка
400	оптимизация
401	оперативное управление.
402	Production
403	technological process
405	enhancement
408	expenditure
409	resource of working capacity.
410	condensation gas boiler
411	efficiency
412	heat pump
413	tests
416	verification
417	validation
418	automated testing system
419	powerlifting
420	information system
421	sports competitions.
422	-
423	Business process
424	description
425	notation
426	methodology
427	diagram.
428	Automatic control system
429	simulation model
430	executive mechanism.
431	Model-oriented method
432	design
433	development
434	filtration
436	core ARM Cortex M4
437	STM32F4 discovery.
438	linearization
439	control parameter
440	correction coefficient
441	the coefficients of the transfer function.
443	Carbon products
444	optimization problem
445	optimization criterion
446	cost
448	product quality
449	Координирующее управление
450	манипуляционный робот
451	движение по заданной траектории.
452	Absorption refrigerating unit
453	dephlegmator
455	automatic control systems.
456	Автоматизована діалогова система
457	експертна оцінка
458	навчальний контент
459	ревалентність відповіді.
460	Model synthesis
461	competence
462	technical specialists
463	knowledge control
464	automated mechanisms
465	machines
466	computer numerical control.
468	process model
469	BPMN notation
470	automated information system
471	webcam
472	social impact development.
473	Free motion
474	filter
475	self-tuning
476	band pass filtering
477	automatic control system.
478	incidence matrix
479	Petri net
480	discrete-continuous net
481	automatic generation of Petri nets
482	formation or searching an algorithm
483	parametric synthesis
484	coordinating control system
485	robot manipulator
486	hot blast stove
487	structural identification
488	parametric identification
489	fuzzy knowledge base
490	multi-criteria optimization
491	decision tree.
492	Adaptation
494	statistical analysis
495	PI controller
496	efficiency of the control system.
497	Spiral classifier
498	sand body
499	the lower part
500	modeling patterns.
501	Graphitization
502	carbon electrodes
503	mathematical model
504	energy.
505	ISA-88
506	ISA-95
507	Manufacturing Operations Management
508	MES
509	Оптимальный
510	управление
511	объект
512	матрица
513	факторизация
514	дисперсия
515	стохастический
516	Power control program
517	the gradient method
518	the objective optimization function.
519	Computer simulator
520	virtual simulator
521	3D simulator
522	simulator of technological process of pelleting feed
523	Thermoelectric vacuum crock-pot
524	vacuum evaporator
525	thermoelectric converters.
526	Dynamic subsystem
527	sterilizer
528	autoclave with counter-pressure
529	heat balance.
530	Інформаційна безпека
531	соціальні інтернет-сервіси
532	актори
533	загрози
534	нелінійна схема компромісів
535	Thermal power plant
539	Углеводородный  газ
540	модель  сжигания
541	метод  сжигания  несертифицированного  топлива
542	теплоэнергетическая установка
543	максимальная температура горения.
544	Частотно-зависимый компонент
545	нормированный фильтр
546	коэффициенты  числителя  и  знаменателя
547	частота среза
548	центральная частота.
549	Ректификационная  колонна
550	попутный  нефтяной  газ
551	пропан
552	бутан
553	система  автоматического  управления
554	двухуровневая
555	линейно-квадратический
556	ПИД
557	регулятор
558	Environment
559	environmental  friendlines
560	harmful  impact
561	power  engineering
562	energy saving
563	technological  efficiency
565	functioning
567	control.
568	Neural  network
569	machine  learning
570	intrusion  detection  system
571	protection  of  web  applications
572	information  security
573	method of automated control
574	control models and methods
576	235U
577	239Pu
578	three control loops
580	VVER-1000
581	Robot-manipulator
582	education process
583	laboratory working
584	controlled object
585	MT-11
586	computer vision library
587	laboratory of mechatronics and robotics
588	pneumatic
594	adaptive layout
595	effectiveness of development
596	neural network
597	The detonation wave
598	the width of the stationary detonation wave
599	ZND model
600	software complex
602	Control system
603	object
604	model
605	MatLab
606	Simulink
607	Reengineering of building structures
608	rebuilding
609	completion
610	creative project activities
611	Objective function
612	optimization criteria
613	chemical composition
614	physiological standart
615	gluten
616	aminoacid
617	recipes
618	Regulators
619	pressure
620	accuracy
621	roll
622	material
623	feedback
624	reengineering
625	recoding
626	software component
627	Supervisory Control And Data Acquisition (SCADA-system)
628	Computer-Aided Software Engineering (CASE-means)
629	Balance
633	offset
634	updating
636	Программа расчета
637	информационные технологии
638	низкотемпературная техника
639	микроканальные воздушные конденсаторы
640	Methodology
642	decomposition
643	processes
644	management
645	operations
646	trunk road
647	Boiler
648	mode optimization
649	criterions
650	calorific fuel capacity
651	microprocessor-based controller
652	program
653	Grain processing enterprise
654	explosion
655	secondary explosion
656	decision support system
657	control system
658	graph
659	fuzzy estimation
660	the shortest path in the graph
661	Automation
662	system akratofor
664	task
666	Inductance
667	coil
668	transformer
669	high-frequency microelectronics
670	electricity
677	Varying transmission coefficient
678	offset absence order increase
679	non-stationary control objects
681	Pumping station
682	water supply
683	residential building
685	automatic control
686	dynamic precision control
687	Discrete-continuous net
688	programming environment
689	xml
690	DCNET
691	Flash
692	Ecological efficiency
693	functioning of technical object
695	negative factors
697	progressive approach
698	Electric vehicles
699	company Tesla Motors
700	Tesla Roadster
701	Tesla Model S
702	Tesla Model Х
703	Optimization
704	single-dimensional cutting
705	genetic algorithm
706	КИСУ
707	твэл
708	алгоритм
709	эффективность
710	поврежденность
711	Нагрев тела
712	переходный процесс
713	модель в сосредоточенной постановке
714	критерий подобия
715	число подобия
716	число гомохронности
717	Часткове оновлення
719	технологічна ефективність функціонування
720	ресурс
721	зношене устаткування
722	технічний об'єкт
723	Cистема регулирования
725	модель
726	Experimental statistical modeling
727	reconstruction
728	high-rise engineering structures
729	numerical methods of optimization
730	Оцінювання та атестація персоналу
731	підтримка прийняття рішень
732	управління персоналом
733	багатокритеріальна оптимізація за Парето
734	Аппроксимация
735	первичная обработка сигналов
736	метод «трубы»
737	метод «веера»
738	коэффициенты передаточной функции
739	Промисловий кондиціонер
740	динамічна модель
741	простір стану
742	автоматична система керування
744	лінійно-квадратичний цифровий регулятор
745	Автоматизація блоку очищення
746	установка розділення повітря середнього тиску
747	управляючий обчислювальний комплекс
748	адсорбер
749	Когенерационная энергетическая установка
750	несертифицированные виды топлива
751	энергетические характеристики
752	изменение низшей теплоты сгорания топлива
753	Управление
755	движение
758	сепарация
759	минимум
760	траектория
761	Flame
762	combustion
763	vibratory combustion
764	instability
765	laminarity
766	turbulence
767	fire-chamber
768	food products
769	safety
770	social and economic policy
771	safety factors
772	агропродовольча продукція
773	товарна структура
774	експорт
775	імпорт
776	сальдо
777	органічна продукція
778	гастрономія,
779	гастрономічний туризм,
780	садівницькі (садівничі) товариства,
781	гастрономічні атракції,
782	туристичні дестинації
783	сталий розвиток територіальних громад,
784	зелена економіка.
785	sustainable development
786	inclusive development
787	cluster
788	agri-food sphere (AFS)
789	strategic directions
790	ринок
792	відтворювальний механізм
793	інститути
794	суб’єкти ринку
795	зв’язки
796	інклюзивність
797	заходи державної підтримки
798	wine
799	winemaking industry
800	strategic outline
801	strategic curve
802	the DPM matrix
803	competitiveness
804	leadership
805	leadership potential
806	students
807	education
809	social responsibility
811	навчання персоналу
812	працівники
813	сторітеллінг
814	стеження
815	відрядження
817	людські ресурси
818	аутсорсинг
819	аутстафінг
820	лізинг персоналу
821	партнерські відносини
822	особиста ефективність
823	керівник
824	компетенції
825	самоменеджмент
826	особистий розвиток
827	тайм-менеджмент
828	комплекс маркетингових комунікацій
829	реклама
830	ринок реклами
831	рекламна діяльність
832	тенденції розвитку ринку реклами
833	цінні папери
834	акції
835	банки
836	фондовий ринок
837	економіка
838	financial decentralization
839	food industry
840	food industry support regional fund
841	regional policy
842	enterprise management
843	information systems and technologies
845	evaluation activity
846	моніторинг
847	«зелене» зростання
848	сталий розвиток
849	індикатори
850	оцінка
851	діагностика
852	«зелена» трансформація
853	інституційний дисбаланс
855	зовнішньоекономічна інтеграція
857	додана вартість
858	заходи держави
859	ланцюг вартості
860	оборотні активи
861	елементи оборотних активів
862	запаси
863	дебіторська заборгованість
864	грошові кошти
865	оборотний капітал
866	аналіз
867	фінансові результати
868	прибуток
869	збиток
870	доходи
871	витрати
872	види діяльності підприємства
873	факторний аналіз
874	адитивна факторна модель
875	ризик
876	оцінка ризиків
877	управління ризиками
878	відносні та абсолютні показники
879	статистичні показники
880	систематизація
881	administration
883	management functions
884	management principles
885	management criteria
886	management technology
887	competencies
888	personnel efficiency
889	enterprises
890	coaching
891	management style
892	management methods
893	tourism
894	tourist enterprises
895	land and natural resources assessment
896	land market
897	land market moratorium
898	державна підтримка
899	скриньки
900	агропромислове виробництво
901	державне регулювання
902	Європейська аграрна політика (ЄАП)
903	державний бюджет
904	субсидії
905	кредиторська заборгованість
906	економічний зміст категорії «кредиторська заборгованість»
907	етапи аналізу кредиторської заборгованості
910	стратегія
911	розвиток
912	принципи стратегічного планування
913	стратегічні альтернативи
914	готельні послуги
915	ефективність
916	соціальна відповідальність
917	бізнес
918	концепції
919	глобальна та географічна моделі
920	суспільна відповідальність
921	харчування
922	здоров’я
923	студенти
924	здорове харчування
925	споживачі
926	збалансоване харчування
927	основні засоби
928	методика аналізу зносу
929	придатності та оновлення основних засобів
930	коефіцієнт динаміки
931	коефіцієнт реальної вартості основних засобів
932	debts receivable
933	analysis of debts receivable
934	financial stableness
935	внутрішньогосподарський контроль
936	система внутрішньогосподарського контролю
937	контроль розрахунків з покупцями та замовниками
938	контроль готової продукції
939	облікова політика
940	бухгалтерський облік
941	суттєвість
942	критерії суттєвості
943	контроль
944	корпоративна політика
945	облік
946	заробітна плата
947	витрати на оплату праці
948	внутрішня управлінська звіт- ність
949	мотивація працівників
950	автоматизація процесу
951	системний підхід
952	класифікація інновацій
953	класифікаційна ознака
954	базові інновації
955	по- ліпшуючі інновації
956	псевдоінновації
957	адаптація
958	рівень адаптації
959	комунікативна складова
960	маркетингові комунікації
961	комплекс маркетингу
962	зовнішнє середовище
963	внутрішнє середовище
964	виноробна промисловість
967	інноваційний продукт
968	сироп
969	ПрАТ «Одесавинпром»
970	вторинна сировина виноробства
971	Ukrainian enterprises
972	consumer value
973	local wines
974	business model of chateau
975	competitive
977	принципи мотивації
978	мотиваційна функція менеджменту
979	методи менеджменту
980	проблеми мотивації
982	агропродовольчий комплекс
983	підприємство
985	експортна стратегія
989	model of public-private partnership
990	state support
991	agribusiness
992	innovative development
994	індивідуальні господарства
995	багатофункціональні коопера- тиви
996	інтеграційні взаємодії
997	селективні заходи
998	fixed assets
999	classification of fixed assets
1000	group of fixed assets
1001	classes of fixed assets
1002	normative-legal acts.
1003	малі підприємства
1005	звітність підприємств
1006	особливості організації
1007	фактори впливу.
1009	витрати на 1 грн
1010	витрати діяльності
1011	собівартість
1012	до- ходи діяльності
1014	збиток.
1015	маркетингова стратегія
1016	диверсифікація
1019	медіа- план.
1020	ресторанний бізнес
1021	ресторани
1022	гастрономічний туризм
1023	гастрономічні фести- валі.
1024	головний торговий партнер
1026	товарна диверсифікація
1027	до- датне сальдо
1028	регіональні ринки.
1029	revenues of local budgets
1030	local self-government bodies
1031	public-private partnership
1033	financial resources.
1034	knowledge economy
1035	innovative economy
1036	innovations
1037	innovation system
1038	world economy
1039	formation of development strategy
1040	global index of innovations
1041	theory of strategic management.
1042	лідерство
1043	керівництво
1044	управлінські команди
1045	наділ повноваженнями
1046	групова згуртованість
1047	соціальна ідентифікація.
1048	стратегія розвитку
1049	стратегічний аналіз
1050	стратегічний набір
1051	виноробна галузь
1053	конкурентоспроможність.
1054	реінжиніринг
1055	бізнес-процеси
1057	організаційна структура
1058	продук- ція
1059	споживач.
1060	локалізація
1061	товарний ринок
1063	глокалізація
1064	зернові і хлібні продукти
1066	інтеграційна політика держави.
1067	капіталізація
1068	ринок землі
1069	продовольча політика
1071	зе- мельні відносини.
1072	indebtedness
1073	liabilities
1074	debtors
1076	comparative analysis of the aspects of debts receivable accounting
1077	international standards of accounting
1078	national standards of accounting.
1080	облік розрахунків з покупцями та замовниками
1081	готова продукція
1082	безнадійна дебіторська заборгованість.
1083	управлінський облік
1084	стратегічних управлінський облік
1085	етапи розвитку
1086	підп- риємство
1087	зовнішні фактори
1092	операційні витрати
1095	ви- трати на збут
1096	адміністративні витрати
1097	фінансова політика
1098	фінансова система
1100	бюджетна безпека
1101	економічне зростання.
1102	інформація
1103	інформаційні технології
1104	управлінське рішення
1105	інтегроване інфо- рмаційне середовище
1106	система підтримки прийняття рішень
1107	бізнеc-процес
1108	управління підприємст- вом.
1109	хлібний ринок
1110	легальний і «тіньовий» сегменти
1111	інтеграційні тенденції
1112	міжсек- торні зв’язки
1113	ринкові інтеграційні механізми.
1114	бренд
1115	брендинг
1116	Південний регіон
1117	сільські території
1118	теоретичні основи
1119	те- риторіальний маркетинг.
1120	маркетинг
1122	розвиток підприємства
1123	менеджмент
1124	мар- кетингова діяльність
1125	risk assessment
1126	risk management
1127	industry
1128	risk-generating factor
1129	risk matrix
1131	адаптивність і адаптованість підприємства
1132	адаптаційний процес
1133	адаптаційний механізм
1134	конкурентоспроможність підприємства.
1135	current assets
1136	working capital
1137	current funds
1138	flow assets
1139	reserves
1140	accounts receivable
1141	monetary funds
1142	liquidity of current assets.
1143	туризм
1144	туристична галузь
1145	туристична сфера
1146	внутрішній туризм
1147	іноземні ту- ристи.
1150	region
1151	competition
1152	cooperation
1153	export potential.
1154	monetary means
1155	assets
1156	the most available assets
1157	classification of monetary means.
1161	калькуляція
1163	виробництво.
1164	податки
1165	Державний бюджет України
1166	податкові надходження
1167	податок на додану вартість
1168	ставка податку
1169	адміністрування податку.
1171	інноваційна активність
1419	reasons of crisis
1172	глобальний інноваційний індекс
1173	харчова промисловість
1174	продовольча безпека.
1176	інноваційний розвиток
1177	підприємства виноробної галузі
1178	стратегічний аналіз.
1179	revenue bonds
1180	innovative and green friendly.
1182	професійно-кваліфікаційний розвиток
1184	персонал.
1185	стартап
1187	ефективність стартапів
1188	проблеми стартап-діяльності
1189	перспективи стартапів в Україні.
1190	gross grape harvest
1191	grape parcel area
1192	grape processing
1193	wine production
1194	winemaking enterprises.
1195	м’ясопереробна галузь
1196	конкурентоспроможність
1198	безпека продукції
1199	система НАССР
1200	державне регулювання.
1202	стратегія управління
1204	стратегічне планування
1210	промисловість
1211	ризикоутворюючиий чинник
1212	чинник-симптом
1213	рівень ризику.
1214	intangible assets
1215	out-of-balance intangible assets
1216	non-monetary factors
1217	estimation of the enterprise market value.
1219	system of indicators
1220	effictiveness of activity of enterprises
1221	unprofitable enterprises
1222	evaluation of the activity efficiency
1223	transformation of enterprises activities.
1224	експортно-імпортна діяльність
1225	підприємства виноробної промисловості
1226	ємність ринку
1227	ступінь відкритості ринку вина
1228	антикризове регулювання.
1229	академія
1230	інститут
1231	економічний напрям
1232	випускники
1233	підготовка фахівців еко- номічного профілю
1234	історичний опис.
1235	supplies
1236	productive supplies
1237	classification
1239	R(S)A
1240	products.
1243	порівняння
1245	оцінка.
1246	wine market
1247	AOC
1248	Ukraine
1249	new world
1250	old world
1251	vineyard
1252	wine region
1253	strategy
1254	positioning.
1255	grain logistics
1256	logistic system
1257	agroholding
1258	exports
1259	agricultural
1260	персонал
1262	методи та засоби мотивації персоналу
1263	ви- норобне підприємство
1264	організаційна структура.
1266	classification of the fixed assets
1267	analysis of the fixed assets of the enterprise
1268	indices of motion of the fixed assets
1269	indices of technical state of the fixed assets
1270	indices of efficiency of the fixed assets.
1271	account receivable
1274	floating capital
1276	заморозка
1277	напівфабрикати
1278	лідери ринку
1279	основні виробники
1280	розвиток галузі.
1281	комбікормова промисловість
1282	структура ринку
1283	ринок комбікормової продукції
1284	обсяг виробництва
1285	посівні площі.
1286	tendency
1287	innovation
1288	enterprise
1290	sector
1292	development.
1293	валова додана вартість
1294	макросистема
1295	секторальна структура
1296	витратоємність доданої вартості
1420	strategy of development.
1297	глобальні ланцюги вартості.
1298	energy of environment
1299	economic environmental problems
1300	alternative energy saving technologies
1301	alternative renewable energy.
1302	operational leasing
1303	financial leasing
1304	lessor
1305	lessee.
1306	агрохолдинг
1307	власний капітал
1308	позиковий капітал
1309	структура капіталу
1310	Kernel Holding S.A.
1311	MHP S.A.
1312	фінансовий стан
1313	WACC
1314	CAPM.
1315	фінансово-економічна безпека
1316	кадрова безпека
1317	обліково-аналітичне забез- печення
1318	кадрові загрози
1319	кадрова політика
1320	інформаційно-кадрове забезпечення.
1321	intraeconomic control
1322	commodity – material values
1323	functions of control
1324	tasks of control
1325	management of efficiency.
1327	the problems of management
1328	stages of development of management mechanism.
1330	analysis
1331	evaluation
1332	production
1333	food industry.
1334	привабливість харчового бізнесу
1335	фактори привабливості бізнесу
1336	конкурен- тоспроможність персоналу
1337	параметри конкурентоспроможності персоналу.
1338	management accounting
1339	strategic management accounting
1340	methods of management accounting
1341	efficiency of activity
1342	competitiveness of the enterprise.
1344	мезосистема
1345	ефективність інтегрованих товарних ринків
1346	ко- лообіг секторної доданої вартості
1347	управління вартістю.
1348	коньяк
1351	SWOT-аналіз
1352	PEST-аналіз
1353	новий продукт
1354	новизна.
1356	готові продукти харчування
1357	товарна структура експорту
1358	географія експортних потоків
1359	диверсифікація експорту
1360	експортна виручка.
1362	the concept of sustainable development
1364	the principles of sustainable development
1365	strategy.
1366	income and financial results
1367	bankruptcy
1368	Improved sanitation audit.
1369	управленческие команды
1370	социальная идентификация
1371	социальные репре- зентации
1372	групповая сплочённость
1373	неформальная структура
1374	управленческие инновации
1375	социальная ответственность.
1377	environmental component
1378	agri-food sphere
1379	natural resource potential
1380	the region.
1381	облік витрат
1382	технологія виробництва
1383	основна продукція
1384	супутня продукція
1385	побічна продукція.
1386	agriculture
1387	grain market
1389	export potential
1390	global market of cereals.
1391	організація харчування
1392	шкільне харчування
1393	діти
1394	здоров’я.
1395	ціновий моніторинг та аналіз
1396	вертикально суміжні ринки
1397	логістичний ланцюг
1398	ринок хлібопродуктів
1399	селективні регуляторні заходи.
1400	competitive ability
1401	wine industry
1402	wineries
1403	winemaking
1404	processing of wine materials
1405	viticulture
1408	фінансова реструктуризація
1409	дер- жавне регулювання
1410	фінансові інструменти
1411	бюджетна децентралізація.
1413	стратегія диверсифікації
1415	портфе- льний аналіз.
1416	crisis management
1417	food security
1418	food enterprises
1421	Competitiveness
1422	competitiveness factors of enterprises
1423	small business enterprises
1425	обліково-аналітична інформація
1426	експертиза
1427	судово-бухгалтерська експерти- за
1428	методичні прийоми експертизи
1429	фінансові правопорушення.
1430	малий та середній бізнес
1431	банківські кредити
1432	статистика НБУ
1433	відсотки
1434	фі- нансування
1435	державна підтримка.
1436	макаронні вироби
1437	система вертикально суміжних ринків
1439	інтеграційні зв’язки
1440	латентна дезінтеграція
1442	стратегічне управління
1444	виноградарство
1445	стратегічний аналіз виноробства.
1446	ресурси підприємства
1448	ресурсна стратегія
1449	граничний дохід
1450	гранична продуктивність чинників виробництва.
1451	ринкові відносини
1452	економіка зернопереробних підприємств
1453	продукти переробки зерна.
1454	оцінювання ефективності
1455	EVA
1456	критерії оцінювання ефективності
1457	«норма доданої вартості на активи компанії»
1458	«активоємність доданої вартості»
1459	ранжування
1460	система управ- ління підприємствами
1461	функції управління підприємством.
1462	Конкурентоспроможність
1463	рівні конкурентоспроможності
1464	об’єкти конкурентоспроможності
1465	конкурентоспроможність підприємства
1466	підприємство малого бізнесу
1467	харчова промисловість.
1468	Продовольча безпека
1469	повноцінне харчування
1470	АПК
1471	сфери АПК
1472	переробна промисловість
1473	технології переробки.
1475	кластерний підхід
1477	агропродовольча сфера
1478	регіон
1479	SWOT-аналіз.
1480	економіка вражень
1481	гостинність
1482	кінцеві та проміжні послуги
1483	продукт гостинності
1485	зелена логістика.
1486	менеджерский потенциал
1487	психологические и педагогические знания
1488	студенты вузов
1489	межличностное общение
1490	гармонизация межличностных отношений
1491	поведенческая регуляция
1492	коммуникативный потенциал
1493	уровень морально-нравственной нормативности
1494	гуманизм
1495	парадигма
1496	социотехническая деятельность
1497	инженерия
1500	податковий облік
1502	фактори впливу
1503	автоматизована інформаційна система
1505	комп’ютерний аудит
1506	комп’ютерна обробка даних
1507	комп’ютерне середовище
1508	програмні засоби аудиту
1509	інформаційне суспільство
1511	комп’ютерна система
1514	інвестиційна привабливість
1515	шляхи підвищення інвестиційної привабливості
1516	управлінський консалтинг
1518	управління факторами інвестиційної привабливості
1522	адаптивне управління
1524	налоговая система
1525	экономика
1526	государственный бюджет
1527	налог на добавленную стоимость
1528	конкуренція
1529	модель п’яти конкурентних сил
1530	роздрібна торгівля
1531	алкогольні напої
1532	стратегія диференціації
1533	зернові обслуговуючі кооперативи
1535	додана вар-тість
1536	відтворювальна ефективність
1537	кооперативний і корпоративний збутові канали
1538	агрологістична система
1539	социально-психологическая адаптация
1540	механизмы социально-психологической адаптации
1541	процедуры адаптации персонала
1542	кадровая политика
1543	инструменты адаптации
1544	организационная культура предприятия
1545	ділове спілкування
1546	моделі ділового спілкування
1547	менеджер
1548	група
1549	бесіда
1550	соціоніка
1551	сучасна ділова комунікація
1552	бюджетування
1553	витрати на підготовку та освоєння виробництва продукції
1554	взаємозв’язок між різними бюджетами підприємства
1555	фінансовий механізм
1556	фінансова стійкість
1557	фінансові важелі
1558	фінансові відносини
1559	фінансові методи
1560	мотивація персоналу
1561	інноваційні технології мотивації персоналу
1562	виноробні підприємства
1563	система мотивації персоналу
1567	управлінська праця
1568	організація управлінської праці
1569	регламентація
1570	риба
1571	рибна продукція
1572	виробництво риби
1573	споживання риби
1574	вилов риби
1575	продовольча безпека
1576	загроза
1577	внутрішні загрози
1578	зовнішні загрози
1580	ринки зерна та продуктів його переробки
1581	система суміжних ринків
1582	деформації відтворювальних процесів
1583	ресурсоутворювальні сектори
1584	оптимізація товарних потоків
1585	селективне регулювання
1588	галузь
1590	виробництво
1593	лідер
1594	особистісні якості керівника-лідера
1596	емпатія
1597	фасилятивність
1600	фондоозброєність
1601	виробнича функція
1602	норма заміщення ресурсів
1603	фінансова децентралізація
1604	витрати та доходи місцевих бюджетів
1605	ефективність фінансової децентралізації
1606	інноваційна діяльність
1607	інновації
1610	управління інноваціями
1611	підприємницька діяльність
1613	стратегічний розвиток
1614	винний туризм
1615	бюро з маркетингу
1616	вина КНП
1617	місткість ринку
1618	инновации
1620	рынок зерна
1621	предприятия хранения зерна
1622	бизнес-процессы
1623	організація ремонту
1624	технічного обслуговування
1625	агротехнічне сервісне обслу-говування
1626	закон розподілення випадкових величин.
1627	Інтернет
1628	мікроблогінг
1629	Twitter
1630	просування
1631	проникнення
1633	маркетинговий підхід в управлінні
1634	державна політика туризму
1635	управління туризмом
1636	модель державної політики управління туризмом
1637	функція управління
1638	метод управління
1639	ефективність праці
1641	внутрішній контроль
1643	стимулювання
1644	мотиваційний механізм
1645	етапи контролю
1647	об’єднання підприємств
1648	власна діяльність
1649	об’єднана діяльність
1650	система показників
1651	ефективність діяльності
1652	оцінювання ефективності діяльності
1654	гудвіл
1656	туристичний бізнес
1658	конкуренці.
1659	суміжний ринок
1662	внутрішня інтеграція
1663	інтеграційна політика держави
1665	внутрішні і зовнішні товарні потоки
1666	chlorella suspension,
1667	chemical composition of chlorella,
1668	proteins,
1669	vitamins,
1670	minerals.
1671	extruded feed additive (EFA) with algae,
1672	biotesting,
1673	organicity,
1674	biocrystalogram,
1675	the oxidation-reduction potential (ORP).
1676	compound feed for Clarias Gariepinus or African sharptooth catfish,
1677	feed manufacture technology for Clarias Gariepinus’s feeds,
1678	requirements for Clarias Gariepinus feeds.
1679	groat industry,
1680	corn,
1681	chemical composition,
1682	technological properties
1683	processing.
1684	flour quality,
1685	wheat flour,
1686	quality indicators,
1687	gluten,
1688	protein,
1689	Falling Number,
1690	Starch Damage.
1691	grain processing,
1693	water absorption,
1694	hydrothermal grain processing.
1695	corn grain
1696	silobags,
1697	hermetic storage conditions,
1698	oxygen absorption,
1699	carbon dioxide,
1700	heat generation,
1701	loss of dry matter.
1702	labour safety,
1703	human factor,
1704	sustainable development,
1705	man-machine-environment
1706	industrial safety
1707	labor protection,
1708	labor protection management system,
1709	risk-oriented approach,
1710	identification of hazards,
1711	operational risk.
1712	power calculations,
1713	determination of power to sieve separators’ engine,
1714	power for the engine in motion,
1715	power for overclocking of the product,
1716	power to overcome gravity;
1717	power for deformation of suspension brackets;
1718	power to overcome the resistance of the environment
1719	snails,
1720	snail breeding,
1721	growing volumes,
1722	recipe,
1723	technology,
1724	feed
1725	feeding,
1726	pig,
1727	productivity,
1728	premix,
1729	enzyme preparation
1730	cereals,
1731	probiotics,
1732	prebiotics,
1733	modified polysaccharides,
1734	functional products
1735	barley,
1736	malt,
1737	germinated grains,
1738	moisture,
1739	hydrothermal processing,
1740	the degree of swelling
1741	the rate of swelling,
1742	hydro moduleт
1743	after harvesting residues of corn,
1744	biofuels,
1745	pneumatic separating,
1746	separated machines,
1747	plant raw materials as fuel,
1748	clearing straw from mineral impurities
1749	Secondary raw materials,
1751	husk,
1752	flour,
1753	pressing,
1754	binder,
1755	starch,
1756	paste,
1757	granules,
1758	pellets
1759	certification,
1760	workplaces,
1761	working conditions,
1762	production environment,
1763	hazardous and harmful production factors,
1765	labor severity,
1766	labor intensity
1767	Точная агротехнология
1768	точный сев
1769	фракции семян
1770	конярство,
1771	поголів’я,
1772	комбікорм-концентрат,
1773	рецепт комбікорму,
1774	зоотехнічна ефективність,
1775	жива маса,
1776	біохімічні показники
1777	feed certification,
1778	ferromagnetic microtracers,
1779	Poisson distribution,
1780	chi-squared
1781	білкові рослинні концентрати,
1782	класифікація,
1783	методи отримання,
1784	соєвий концентрат,
1785	комбікорм
1786	органічне сільське господарство,
1788	кондитерські вироби,
1789	бісквіти,
1790	цукрозамінник,
1791	екстракт стевії,
1792	тростинний цукор,
1793	органолептичні показники,
1794	піноутворення,
1795	стійкість піни,
1796	дисперсна система
1797	ринок хлібобулочних виробів України,
1798	хлібобулочні вироби пониженої вологості,
1799	технологічні рішення,
1800	якість
1801	DIAAS,
1802	пророщування
1803	льон,
1804	якість білка,
1805	незамінні амінокислоти,
1806	біологічна цінність,
1807	функціональне харчування
1808	цільнозернове пшеничне борошно,
1809	зерновий хліб,
1810	показники якості,
1811	гранулометричний склад,
1812	хлібопекарські властивості,
1813	харчова цінність
1814	Labor protection,
1815	occupational risk,
1817	danger,
1818	industrial injuries,
1819	occupational diseases,
1820	actualization,
1822	скребковий конвеєр
1823	жолоб
1824	площа
1827	барабан
1829	мікробіота
1830	загальне обсіменіння
1831	плісеневі гриби
1832	мезофільні аеробні і факультативно-анаеробні мікроорганізми (МАФАнМ)
1833	санітарна якість
1834	мідійна мука
1835	крилева мука
1836	водорості
1837	дріжджі кормові
1838	калоген
1839	білково- вітамінно-мінеральна добавка (БВД)
1840	horse
1841	apple pomace
1842	feed additive
1843	extruding
1844	feed concentrate
1845	recipe
1846	конярство
1847	яблучні вичавки
1848	кормова добавка
1849	екструдування
1850	комбікорм-концентрат
1851	рецепт
1852	крупа вівсяна
1853	воднотеплова обробка
1854	очищення зерна від домішок
1855	пропарювання
1856	плющені продукти
1857	вівсяне борошно
1858	голозерний овес
1859	скорочена структура технологічного процесу
1860	підвищення харчової цінності
1861	анаеробне зброджування
1862	відходи
1863	рисова лузга
1864	гній ВРХ
1865	біогаз
1866	кукуруза
1867	семена
1868	качество и выход
1869	способы сепарирования
1870	СОТОЧНАЯ АГРОТЕХНОЛОГИЯ БУДУЩЕГО НАЧИНАЕТСЯ СЕГОДНЯ
1871	ПОДЛНЕЧНИК
1872	фотоелектронний сепаратор
1873	оптичне сепарування
1874	сепарування за ознакою кольору
1875	оптична система
1876	оптичне сортування
1877	інспекційна система
1878	ежекторне вилучення домішок
1879	фотоелектронні сепаратори модель- ного ряду «Зоркий»
1880	фотосепаратори «Sortex»
1881	фотоелект
1882	горохова солома
1884	дисбіоз
1885	пребіотик.
1886	ферменти
1887	«Клерізим гранульований»
1888	лізоцим
1889	кров
1890	резистентність
1891	курчата.
1892	школа кормов
1893	пятая юбилейная сессия
1894	corn
1896	processing
1898	corn grits.
1899	льняний шрот
1900	гарбузовий шрот
1901	високобілкові продукти
1902	булочки
1903	органолептичні показники
1904	вологість
1905	пористість
1906	sorghum
1907	popped grains
1908	microwave treatment
1909	technology of popping sorghum
1910	moisture content of grain
1911	small-seeded cultures
1912	post-harvesting processing
1913	heat treatment
1914	drying
1915	human factors
1916	risk
1917	sustainability
1918	Technosphere
1919	danger
1921	лущення ячменю
1922	лущильно-шліфувальна машина
1923	машина типу А1-ЗШН-3
1924	продуктивність утво- рення відходів лущення-шліфування
1925	ефективність лущення-шліфування
1926	закономірності лущення-шліфування.
1927	білково-вітамінно-мінеральна добавка (БВМД)
1928	собаки
1929	біологічна оцінка
1930	біохімічні маркери запа- лення
1931	жива маса
1932	зоотехнічна оцінка
1933	показником загального стану артриту (ЗСА)
1934	візуальна оцінка стану
1935	суглоби
1936	м’язи.
1938	буряковий жом
1939	утилізація
1940	переробка
1941	комбікорм.
1942	compound feed for shrimp
1943	feed manufacture technology for shrimp feed
1944	requirements for shrimp feed.
1945	дрібнонасіннєві культури
1946	гігроскопічні властивості
1947	рівноважна вологість
1948	показники якості
1949	ре- жими зберігання.
1951	labour protection
1953	occupational diseases
1954	incidents rate
1955	dangerous and harmful production effects
1956	risks of occupational hazards
1957	hazard
1959	автоматизована система обліку
1960	поточний контроль маси
1961	електронно-тензометричні ваги
1962	аналого-цифровий перетворювач
1963	автомобільні
1964	вагонні та бункерні автоматичні ваги.
1965	енергозбереження
1966	енергоємність
1967	раціональне використання електроенергії
1968	норми електроспоживання
1969	економія електроенергії.
1970	яєчні кури
1972	обмінна енергія
1973	протеїн
1974	клітковина
1975	жир
1977	кальцій
1978	фосфор
1979	концентрат кукурудзяно-фосфатидний кормовий
1980	економічність.
1981	борошно
1983	клейковина
1984	білість
1985	зольність
1986	седиментація
1987	Міксолаб
1988	реологічні властивості
1989	сочевиця
1990	насіння
1991	урожайність
1992	стандарти
1993	хімічний склад
1994	рослинний білок
1995	очищення.
1996	Бобовые
1997	спрос
1998	чечевица
1999	prebiotics
2000	arabinoxylans
2001	cereals
2002	oligosaccharides
2003	xylooligosaccharides
2004	Lactic acid bacteria
2005	Bifidobacteria
2006	grain
2007	small-capacity unit
2008	production of flour
2009	panification.
2010	білково-вітамінно-мінеральна добавка для собак «Мобікан»
2011	технологія
2012	технологічні режими
2014	technology of granulation
2015	pharmaceutical industry
2016	production of polymer and polypropylene
2017	production of biofuel
2018	production of fertilizers
2019	chemical industry
2020	manufacture of metal
2021	feed industry
2022	reduce energy consumption
2023	mixed fodder
2024	молочні продукти з комбінованим складом сировини
2025	рисове борошно
2026	пшеничний зернопродукт
2027	кукурудзяний зернопродукт
2028	консистенція
2029	кисломолочний згусток
2030	стабілізатори
2031	органолептичні характеристики.
2032	зерно
2033	пшениця
2034	кількість клейковини
2035	якість клейковини
2036	методи визначення клейковини
2037	система Глютоматик
2039	очищення
2040	теплофізичні характеристики
2042	активне вентилювання
2043	післязбиральна обробка
2045	фракции
2046	traceability
2048	grain terminal
2050	traceability system
2051	Международная школа кормов
2052	комбікормова продукція
2053	суха пивна дробина
2054	молодняк курчат-бройлерів
2056	премікс
2057	збагачення
2058	годівля
2059	сільськогосподарська птиця
2060	зоотехнічний експеримент
2061	сегрегация
2062	ферромагнитные микротрейсеры
2063	премикс
2064	ситовой анализ
2065	стандартное отклонение
2066	коэффициент вариации
2067	біологічна цінність
2068	молочні продукти для дитячого харчування
2070	ферментативний метод
2071	перетравлюваність
2072	безглютеновий хліб
2073	целіакія
2074	кукурудзяне борошно
2075	гречане борошно
2076	якість хліба
2077	черствіння хліба
2078	злаковые и бобовые культуры
2079	свободные и связанные полифенолы
2080	гречиха
2081	здоровая пища
2082	эффективность обработки гречихи
2085	поживність
2086	екструдована кормова добавка
2087	комбікорм-концентра
2088	рецепт комбікорму
2095	кури-несучки
2096	пшениця спельта
2098	відволожування
2099	лущення
2100	крупа плющена
2102	полба
2103	біологічні властивості зерна
2104	фізико-технологічні властивості зерна
2105	хімікотехнологічні властивості зерна
2107	помел зерна
2108	полб’яне борошно
2109	спельта
2111	с/х культура
2113	фізико-технологічні властивості
2114	гранулометричний склад
2115	аеродинамічні властивості
2119	regulatory framework
2120	Association with EU
2121	legislation
2123	danger and technical system
2125	електроенергія
2127	паливно-енергетичні ресурси
2130	трав'яна мука
2131	годівля молодняку свиней
2132	повнораціонний комбікорм
2133	конверсія комбікорму
2134	буферна ємність
2135	хлорид натрію
2138	треонін
2139	biscuit semi-finished product
2140	flour from by-products of processing cereal crops
2141	viscosity
2142	composite mixtures
2143	optimization
2144	растительное масло
2145	соя
2147	крупа
2148	гречка
2149	ядриця
2151	переробка зерна
2152	зерно пшениці
2153	вода
2154	диспергована зернова маса
2155	споживчі якості хліба
2156	Safety
2157	brewery
2158	safe working conditions
2160	getting the wort
2161	комбікормові агрегати
2162	технологічні процеси
2163	обладнання
2165	правила пожежної безпеки
2166	смешивание
2167	комбикорм
2168	качество
2169	микротрейсеры
2170	маркеры
2172	вращательный детектор
2173	банка Мейсона
2174	томатні вичавки
2175	крейда кормова
2177	томатна кормова добавка
2179	куринесучки
2188	Аграрний сектор
2192	комбикорма
2193	додаткова вартість
2194	олія соняшникова високоолеїнового типу
2195	напівфабрикат із заварного тіста
2196	структурно-механічні властивості
2197	фізико-хімічні показники
2200	годування
2201	свині
2202	ферментний препарат Лізоцим
2209	годівля поросят
2217	кокосовое масло
2218	безжировой рацион
2219	жировой обмен
2220	гепатостеатоз
2221	холестерин
2222	дисбиоз
2223	системное воспаление
2224	спред низькожирний
2225	борошно вівсяне
2228	водопоглинальна здатність
2229	розчинність
2230	кислотність
2231	дисперсність
2232	комбінований йогуртовий напій
2233	математичне моделювання
2234	сироватка сирна
2235	борошно рисове
2236	гарбузовий наповнювач з цукром
2238	амінокислотний склад
2239	зернова квасоля
2241	ботанічні сорти
2243	вологотеплова обробка
2244	вуглеводно-амілазний комплекс
2246	піддана дії контактної нерівноважної плазми
2247	ГРОТЕХНОЛОГИЯ
2248	КУКУРУЗА
2249	класифікація, сушіння, конвективний стенд, схожість насіння, кінетика, температура насіння, тепломасообмін
2250	електромагнітні джерела енергії, комбіновані способи сушіння, мікрохвильове сушіння, інфрачервоне сушіння, сушіння рослинної сировини, енергоефективність
2251	безпечність, харчова цінність, удосконалення, теплова стерилізація, термостабілізація, летальність, рибні консерви, гідробіонти, кісткова тканина
2252	wine, quality, automatic control, sensor-based device
2253	просо, зберігання, якість, нові сорти
2255	ламінарія
2256	м’ясо кролів
2257	м’ясні фаршеві системи
2258	вологозв’язуюча здатність
2259	граничне напруження зсуву
2260	втрати при термообробці
2261	екстракт листя Ginkgo biloba
2262	екстракція
2263	екстрагент
2264	фенольні сполуки
2265	параметри екстракції
2266	спектрофотометрія
2267	метод Фоліна-Чокальтеу
2268	фітоконцентрат
2269	барвні властивості
2270	столовий буряк
2271	бетанін
2272	буряковий екстракт
2273	екстрагування
2274	пшеничні висівки, біотехнологія, фракційонування, рослинна клітина
2275	їстівне покриття/плівка
2276	питома теплота випаровування
2277	теплоємність
2278	полівініловий спирт
2279	крохмаль
2280	желатин
2281	біогенні аміни
2282	ферментовані продукти
2283	гістамін
2284	декарбоксилазна активність
2285	отруєння гістаміном
2286	амінокислоти
2287	функціональні добавки, виноградні вичавки,  комбікорм
2288	шлунково-кишковий тракт, генетичний потенціал, кури-несучки, бройлери, система травлення, повноцінна годівля, комбікорм
2289	хлібопекарське пшеничне борошно, показники якості борошна, технологічні добавки, хлібопекарські властивості
2290	комбікормова промисловість, технологія гранулювання, зниження споживання електроенергії, комбікорм.
2291	пшениця, білок, клейковина, методи відмивання клейковини
2292	зерно, кукурудза, гібриди, якість, зберігання, агротехнологічні властивості
2293	капуста білоголова, сік, пророщені зерна злакових культур, цитолітичні і пекто-літичні ферменти, попередня обробка, вихід соку, ступінь пошкодження.
2294	меляса
2295	дріжджі
2296	дріжджування
2298	білково-вітамінна добавка
2300	технологічна схема
2301	інтелектуальна промислова власність
2302	винаходи
2303	корисні моделі
2304	методи вартісного оцінювання
2305	алгоритми
2306	простежуваність
2307	харчові продукти
2308	безпечність
2309	від поля до споживача
2311	відстеження
2312	экономическая безопасность
2313	предприятие
2314	активы
2315	капитал
2316	зберігання
2317	параметри
2320	інфрачервоне опромінювання
2323	віброхвильова інфрачервона сушарка.
2325	випаровування
2326	фітопрепарати
2327	мікрохвильове поле
2328	кріоконцентрат
2329	процессы обезвоживания
2330	энергетическая эффективность
2331	термомеханический агрегат
2332	ротационный термосифон
2333	микроволновые аппараты
2335	кристалізація
2337	концентрація
2339	теплопередача
2340	вакуумная сушилка
2341	энергетика обезвоживания
2342	режимы сушки
2343	морепродукты
2344	растительное сырье
2346	вакуум-випарні апарати
2347	цукрові розчини
2348	стевія
2349	виноградне насіння
2350	сусло
2351	обертовий активатор
2352	ефект розподілу
2353	нафта
2354	сепараційний пристрій
2356	розділення
2357	бензосепаратор
2359	очистка
2360	фазні розділювачі
2361	біомаса
2362	композиційне біопаливо
2363	барабанна сушарка
2364	енергоефективний режим
2365	дієтична добавка
2366	пробіотичні культури
2367	пептидоглікани
2368	муропептиди
2369	автоліз
2370	ферментоліз
2371	панкреатин
2372	рослинні тканини
2373	стан води
2374	розчинні речовини
2376	агровиробництво
2377	олія рослинна
2381	компостування
2383	суміш
2384	що компостується
2385	мінеральна добавка
2386	мезофільний і термофільний режими компостування
2387	интеграция
2388	солнечные установки
2389	двух контурные установки
2390	возобновляемые источники энергии
2391	солнечный коллектор
2392	стічні води
2393	білок
2394	денатурація
2395	НВЧ – випромінювання
2396	теплообмін
2397	вуглекислий газ (CO2)
2398	діоксид сульфуру (SO2)
2399	діоксид нітрогену (NO2)
2400	мікроводорості Сhlorella
2401	інгібітори
2402	активатори
2403	константа нестійкості
2404	пожежний кран-комплект
2405	тиск
2406	витрати води
2407	рукав
2408	розпорошувач
2409	биомасса
2410	сушка
2411	термодеструкция
2565	пшеничне борошно
2412	математическое моделирование
2413	цилиндрическая частица
2414	барабанная сушилка
2415	энергия активации
2416	рух бульбашок
2417	розчинення
2418	пневматичне перемішування
2419	енергія
2420	барботер
2421	реактор для насичення
2422	бульбашковий
2423	ізотермічний
2424	режим змішування
2426	цукат
2427	акумулювання теплоти
2428	теплоакумулюючі матеріали
2429	фазовий перехід
2430	теплообмін.
2431	adsorptive heat and moisture regenerator
2432	temperature efficiency coefficient.
2433	купруму сульфат
2435	інтенсифікація
2436	вакуумування
2437	коефіцієнт дифузії
2438	снеки
2439	бланшування
2440	сировина
2442	швидкість повітря
2445	гідродинамічна кавітація
2446	інтенсифікація масообмінних процесів
2447	гідродинамічний змішувач статичного типу
2448	сопло Вентурі
2449	теплотехнологія
2453	зберігання.
2454	гідродинаміка
2455	плівка рідини
2456	капілярно-пориста структура
2457	границя захлинання
2458	кавитация
2459	экстракция
2460	стерилизация
2461	биологические клетки
2462	деревне вугілля
2463	піроліз
2464	конвекційний теплообмін
2465	коефіцієнт теплопровідністі
2466	композитна пористость
2467	газовий прошарок.
2474	упаковка
2476	дизайн
2477	оцінювання
2478	комплексні естетичні показники
2479	бали
2480	ціннісна градація показників
2481	множественные данные
2482	корреляционная матрица
2483	факторный анализ
2484	латентные переменные
2485	вращение факторной структуры
2486	регрессионное моделирование
2488	економія води
2490	тверді відходи
2491	переробне підприємство
2493	харчові технології
2495	концентрування соків
2496	екстракт
2497	випарювання
2498	електромагнітне підведення енергії
2499	косметика
2500	тонік
2501	суха шкіра
2502	пробіотик
2504	Tagetes patula
2505	кисла сироватка
2506	водорозчинна олія паростків пшениці
2508	функція відклику
2509	косметичні засоби
2511	плоди Fructus Rosae
2512	молочна сироватка
2514	етиловий спирт
2515	антиоксидантна активність
2517	вітамін С
2518	натуральна косметика
2519	органічна косметика
2520	косметичний інгредієнт
2522	концентрат сироваткових білків
2523	коротколанцюговий пептид
2524	ультрафільтраційний фільтрат
2525	ферментація
2526	біфідобактерії
2527	лактобактерії
2528	харчування військовослужбовців
2529	радіопротекторні властивості
2530	пробіотичні властивості
2531	збалансований хімічний склад
2532	молочно—рослинна система
2533	біфідобактерія
2534	лактобактерія
2535	комбінований харчовий продукт
2536	індустрія гостинності
2538	готельно—ресторанний бізнес
2540	економічні показники розвитку
2541	майонезний соус
2542	емульсія
2543	біокоректор
2544	гідроколоїд
2545	рецептурний склад
2547	нерівномірність емульсії
2548	агломерація
2549	вагітність
2553	йогуртний напій
2555	в’язкість
2558	водопідготовка
2559	демінералізація
2560	зворотній осмос
2561	іонообмінний метод
2562	пиво
2568	число падіння
2569	амілолітична активність
2572	їстівна плівка
2575	картопляний крохмаль
2576	паропроникність
2577	активність води
2578	динамічна в’язкість
2579	заморожений напівфабрикат
2580	млинці
2581	йодовмісна добавка
2582	профілактичне харчування
2584	седиментаційний аналіз
2587	льон олійний
2588	льон—довгунець
2590	мікрофлора
2592	Lactobacillus acidophilus K 3111
2593	дезінтеграція
2594	пептидоглікан
2595	низькомолекулярні пептиди
2596	імунотропні властивості
2597	эритроцит
2598	площадь поверхности
2599	объём
2600	нормальное распределение
2601	гематологический анализатор
2602	НАССР — план
2603	безпечність продуктів харчування
2605	критичні точки контролю
2606	булочні вироби
2607	готелі
2608	сервіс
2609	культура обслуговування
2612	стиль
2614	виды и объекты дизайн
2615	художественное творчество
2616	конкурентоспособность
2617	композиционный материал
2618	формообразование
2619	шликерный метод
2620	диаграмма
2622	технологическое оборудование
2623	оценивание
2624	показатели
2625	патент на про- мышленный образец
2626	мембрана
2627	втрата стійкості
2628	критичний тиск
2629	початковий прогин
2630	вакуум
2632	поляризация
2633	сегнетоэлектрический гистерезис
2634	ПВДФ
2635	система автоматического регулирования
2636	самонастройка коэффициента передачи
2637	частотные характеристики
2638	переходные токи
2639	полимерные электреты
2640	гомозаряд
2641	гетерозаряд
2642	ПТФЭ
2643	ультрафиолетовое облучение
2644	фототоки
2647	ароматические соединения
2648	терруар Шабо
2649	спирты
2650	альдегиды
2651	эфиры
2652	кетоны
2653	люминесценция
2654	тонкослойная хроматография
2655	тербий
2656	галловая кислота
2657	шинка з м'яса птиці
2658	високий гідростатичний тиск
2659	атермічне оброблення
2660	плівкоутворюючі покриття
2661	полісахариди
2662	білки
2663	ліпіди
2664	електроактивована вода
2665	католіт
2666	аноліт
2667	електроліз
2668	санітарно-показна мікрофлора
2669	м’ясо
2670	яловичина
2671	свинина
2672	дитяче харчування
2673	білкова паста
2674	медико-біологічні дослідження
2675	приріст маси
2676	гематологічні показники крові
2677	склад індигенної мікрофлори
2678	культивирование
2680	соевая сыворотка
2681	питательная среда
2683	Bifidobacterium bifidum
2684	желе
2685	радіопротектор
2686	спіруліна
2687	гарбуз
2688	кефір
2689	оптимізація технології
2690	функціональні продукти харчування
2691	олія амаранту
2692	лактобацили
2693	пробіотики
2694	солодовий екстракт
2695	стійкість
2697	нетрадиційна сировина
2698	гідроколоїди
2699	біополімери
2701	гуміарабік
2702	фізіологічно-функціональний харчовий інгредієнт
2703	антиоксидантні та пребіотичні властивості
2704	β-глюкани
2706	олігосахариди
2707	суха картопляна добавка
2848	сушіння соняшнику та сої
2709	органолептичні та мікробіологічні показники
2710	микробиальная обсеменённость
2711	раствор хлористого кальция
2712	пектиновые вещества
2713	замораживание
2714	холодильное хранение
2716	товарознавча оцінка
2717	заморожені морепродукти
2718	нормативний документ
2719	морепродукти
2720	капуста білоголова
2722	термостабілізація
2723	тиндалізація
2724	летальність
2725	лосось
2726	имитированные рыбные продукты
2727	пиленгас
2728	толстолобик
2729	реологія
2730	розчин цитрусового пектину
2731	ступінь етерифікації
2732	іони кальцію
2733	біотехнологія
2737	вуглеводи
2738	антипоживні речовини
2739	семена сои
2740	показатели качества
2741	хранение
2742	режимы
2743	жиры
2744	окисление
2745	микрофлора
2746	зерновий екстракт із тритікале
2747	реологічні властивості затору
2748	мука
2749	биотестирование
2750	токсичность
2751	фитотестирование
2752	сырье
2753	водоростева кормова добавка (ВКД)
2758	середньодобові прирости маси тіла
2759	хеномелес
2760	вироби з дріжджового тіста
2762	L-аскорбінова кислота
2763	крихкість
2764	хліб
2765	подрібнений корінь лопуха
2766	органолептичні
2767	фізико-хімічні
2768	мікробіологічні показники
2769	отложенное выпекание
2771	замороженные полуфабрикаты
2772	крахмал
2773	добавки
2774	асортимент
2775	зернові пластівці
2777	органолептичні та фізико-хімічні властивості
2778	балова шкала
2779	зернові хлібці
2780	рослинні добавки
2781	дегустація
2782	профілограми
2784	цільова функція
2785	теорія подібності
2786	мікрохвильовий екстрактор
2787	аналіз розмірностей
2788	масообмін
2789	микроволновое поле
2790	вакуум-выпарные аппараты
2791	сахарные растворы
2792	стевия
2793	геліопанель
2794	сонячна енергетика
2796	альтернативне джерело енергії
2797	система теплопостачання
2798	сонячна радіація
2799	орієнтація панелі
2800	теплонадходження
2801	коефіцієнт масовіддачі
2802	тепловіддача
2805	культивовані гриби
2806	методичні основи
2807	енергоекономічна ефективність
2808	система енергозабезпечення
2809	когенераційно-теплонасосна установка
2810	пікове джерело теплоти
2812	структура потоків
2813	зворотний потік
2814	комірчаста модель
2815	віброекстрагування
2816	розподілення речовини
2817	биотопливо
2819	торф
2821	математическая модель
2822	квазистационарный режим
2823	экстрагирование
2824	волновые технологии
2825	массообмен
2826	микроволновый экстрактор
2827	кофепродукты
2828	пищеконцентраты
2829	гидродинамическая кавитация
2830	парогазовые пузырьки
2831	кавитационный кластер
2832	обезвоживание
2833	белок
2835	сушение
2836	число Ребиндера
2840	електрохімічні властивості
2841	кріоконцентрування
2842	балансові моделі
2843	блокове виморожування
2844	кріоскопічна лінія
2845	кінетика кристалізації та сепарування
2846	гранатовий сік
2847	електромагнітні джерела енергії
2850	фруктово-овочеві чипси
2851	вологовидалення
2852	теплотехнології
2853	цукрово-кислотний індекс
2854	конвективно-конденсаційний метод сушіння сировини
2855	енергоефективність процесу
2856	boiling
2857	heat exchange
2858	evaporation
2859	concentration
2860	vacuum
2862	кристаллизация
2863	пористость
2864	концентрация
2867	перколяция
2868	фракталы
2869	знезалізнення
2870	аерація
2871	дискретно-імпульсне введення енергії
2872	аератор-окиснювач
2875	екстракти рослинної сировини
2877	мікрохвильовий вакуумний випарний апарат
2878	кавітація
2880	пульсаційний апарат
2881	рослинна сировина
2882	фотосинтез
2883	вуглекислий газ (СО2)
2885	мікроводорості
2886	дифузія
2889	ферментативний каталіз
2890	інгібітор
2891	важкі метали
2892	купрум
2893	динаміка адсорбції
2895	хімічна взаємодія
2898	температура поверхні
2899	термомеханическая обработка
2900	энергия
2901	пищевые технологии
2902	плоды
2903	модели
2904	вращающийся термосифон
2905	Олійне виробництво
2906	енергетичний аудит
2908	інноваційні проекти
2909	энергоэффективность
2910	реконструкция
2911	сеть теплообменников
2912	пинч анализ
2913	біопаливо
2914	відходи крупозаводів
2915	лузга круп’яних культур
2916	зв’язуюча речовина
2917	пелети
2918	брикети
2919	геотермальна енергія
2920	свердловинний теплообмінник
2921	термосифон
2922	теплова труба
2924	теплопостачання
2925	энергоэффективные строительные композиты
2927	структурная оптимизация
2928	ветроэлектрогенератор
2929	солнечная установка
2930	тепловой насос
2932	конденсат димових газів
2933	нейтралізація
2934	вугільна кислота
2935	діоксид вуглецю
2936	heat storage device
2937	composite sorbent
2938	sorption.
2939	мікрохвильовий нагрів
2943	вимірювання температури
2944	надвисокочастотне електромагнітне поле
2945	неконвективні способи сушіння
2947	энергетический аудит
2948	рестораны и гостиницы
2949	сонячні теплові повітряні колектори
2951	незамінні амінокислоти
2953	гідроліз білків
2955	виноградные выжимки
2956	дробление
2957	прессование
2960	гумінові речовини
2961	теплота згоряння
2962	пресування
2965	технологічні лінії
2966	брикетування
2967	термовологісна обробка
2968	парогенератор
2969	відновлювані джерела енергії
2971	подрібнені стебла соняшника
2973	теплотворна здатність
2977	раси пивних дріжджів
2978	бродильна активність
2979	зброджування
2980	висококонцентроване сусло
2981	термосифоны
2982	дисперсные материалы
2983	рекуперация
2984	сорбція
2985	композитний сорбент «силікагель/Na2SO4»
2986	адсорбційний холодильник
2987	холодильний коефіцієнт
2988	коэффициент полезного действия
2989	удельная плотность теплового потока
2991	концентрирование
2992	выпаривание
2993	энергосбережение
2996	Эксергия
2997	эксергия-нетто
3001	енергетична ефективність
3002	теплонасосна станція
3003	безрозмірний критерій енергетичної ефективності
3004	електричний привод
3005	когенераційний привод
3008	ресурсозбереження
3012	пастеризационно-охладительная установка
3013	молоко
3014	термодинамический цикл
3015	диоксид углерода
3016	биологически-активные вещества
3017	экстракт
3018	СВЧ-энергия
3019	криоконцентрирование
3025	тепло-массообменный модуль
3026	повышенное давление
3027	энергоэфективность
3028	ІЧ-обробка
3029	соняшник
3031	оболонка
3032	термодеструкція
3033	реологічна модель
3034	каскадний екструдер
3035	шестеренний насос
3036	ресурсо-енергозаощадження
3037	екструзія
3038	полімерна плівка
3039	каскадний дисково-шестеренний екструдер
3041	полимерные отходы
3042	энерго и ресурсосберегающие процессы
3043	технология идентификации
3044	утилизация
3045	твердые бытовые отходы
3046	комплексные инновационные проекты
3047	плоды шиповника
3049	выпарка
3051	электромагнитные генераторы энергии
3052	синтез ферратов(VI)
3053	гипохлоритный способ
3054	комбинированный способ
3055	чистота ферратов
3056	способи нейтралізації
3057	безреагентна нейтралізація
3058	кислий конденсат
3059	вода для живлення котлів
3060	магнітне очищення
3061	феритова фільтруюча загрузка
3062	магнітний фільтр
3063	ефективність очищення
3064	микробиологические средства защиты
3066	энергосберегающие технологии
3067	ферментер
3069	інфрачервоне випромінювання
3070	термолабільні матеріали
3071	непрерывная ленточная сушилка
3072	коллоидные капиллярно-пористые тела
3073	термолабильные материалы
3074	интенсивность испарения
3318	сепарація
3076	текстильные материалы
3077	химическая отделка
3078	эффективность. ресурсосбережение
3080	Экстрагирование
3081	микроволновые технологии
3082	кофе
3084	бародиффузия
3086	сталі теплофізичні коефіцієнти
3087	змінні теплофізичні коефіцієнти
3089	пряно-ароматична сировина
3090	гірка настоянка
3091	настоювання
3092	дисперсний аналіз
3094	диференціальна крива
3095	інтегральна крива
3096	вакуум-випарные аппараты
3099	теплообмен
3100	неподвижный слой
3101	внутренние источники теплоты
3102	хлебопекарная печь
3103	конвективный обогрев
3104	теплопоглощение
3105	пекарная камера
3106	тестовая заготовка
3110	гексан
3111	гідромодуль
3112	питоме енергоспоживання
3113	питома потужність
3114	паренхімні тканини яблука
3116	технологічні параметри сушіння
3117	теплота випаровування
3123	тепловий баланс
3125	топінамбуровий екстракт
3126	вапняне молоко
3127	високомолекулярні сполуки
3129	витрати енергії
3132	пульсуючий потік
3133	масоперенесення
3134	розділення фаз
3135	режимні параметри
3136	проектування
3140	зневоднення
3142	насіння пшениці
3144	схожість насіння
3145	яблочный сок
3147	затраты на испарение
3148	інфрачервоне сушіння
3149	білковмісні наповнювачі для м'ясних і м'ясомістких продуктів
3150	комбінації білкових препаратів
3151	комбінований метод
3152	опромінення
3153	енергозатрати
3155	глід
3158	енерговитрати
3159	терморадіаційне сушіння
3161	гриби
3162	радіаційно-конвективнй спосіб
3168	интенсификация
3169	экстрактор
3171	вибрация
3172	колебания
3175	фосфоліпіди
3176	в'язкість
3178	подрібнена деревина
3179	тирса
3180	стаціонарний шар
3182	динаміка
3183	тепловий агент
3184	фільтраційне сушіння
3185	гранулятор
3186	вихревой взвешенный слой
3187	дезінтегратор
3188	органо-мінеральні гумінові добрива
3189	ретурн
3192	ретур
3193	гумат
3194	комплексне добриво
3195	мінерально-органічне добриво
3196	кісткове борошно
3197	високочастотні гідродинамічні коливання
3199	водно-етанольні суміші
3200	асоціат
3201	гідратація
3202	ацетальдегід
3203	2-пропанол
3204	гипохлорит натрия
3205	электролиз
3206	медицина
3207	ветеринария
3208	кавітаційне сопло
3210	інтенсивність кавітації
3211	органо-мінерально-гумінові добрива
3212	грануляція
3213	дисперсний склад
3214	лінійна швидкість росту гранул
3215	ефективний коефіцієнт внутрішньої дифузії
3216	кінетика сушіння
3218	шлак ТЕС
3219	залізний купорос
3223	карбамід
3225	енергоспоживання
3226	пінч-аналіз
3227	сіткова діаграма
3228	система резервуарів
3229	гліцерин-дистилят
3230	гліцерин-сирець
3231	детермінована інформація
3232	невизначена інформація
3235	експериментально-розрахунковий метод
3236	багатошарові гуміново-мінеральні тверді композити
3237	функція нових центрів грануляції
3238	компенсаційна функція
3239	еквівалентний діаметр
3240	дисперсний склад продукту
3241	альбумін
3242	статика
3243	кінетика адсорбції
3247	коефіцієнти масовіддачі
3248	вакуумування системи
3249	пинч-интеграция
3252	пинч-анализ
3253	сеточная диаграмма
3254	микроканал
3255	пористая среда
3256	фазовый переход
3260	неньютоновские жидкости
3262	безреагентна обробка
3263	відновлення
3266	водневий показник
3267	титрована і активна кислотність
3269	молочное сырье
3270	ультрафильтрация
3273	анализ
3274	тесто
3275	критерий
3276	симплекс
3277	процесс
3278	структура
3280	сушарка
3281	вібрація
3282	константа
3283	критерії подібності
3284	биостимуляция
3286	растительная клетка
3287	семена зерновых
3288	допустимое время
3289	насекомые-вредители
3290	контактна сила
3291	енергетика
3293	амплітуда коливань
3294	потужність
3295	ультразвукова обробка
3298	перемішування
3300	вуглекислий газ
3309	капиллярное торможение
3310	теплоперенос
3311	ефективність гомогенізації
3312	струминна гомогенізація
3313	роздільна гомогенізація
3314	диспергування
3316	трифазний сепаратор
3317	газодинамічний краплевловлювач
3319	дегазація
3322	вуглеводневий газ
3323	сушка пшеницы
3325	нейтрализация
3326	окислительные процессы
3327	ультразвуковая очистка
3328	фотокаталитические процессы
3329	озонирование
3330	электрохимические процессы
3331	ферратная и персульфатная очистка
3332	адсорбент
3333	барвник
3338	блочное вымораживание
3339	фрактальная поверхность
3340	покрытия
3341	адекватность меры
3342	размерность Хаусдорфа-Безиковича
3343	энтропия меры
3344	эффективная размерность
3345	стабілізація нафти
3346	пинч-метод
3348	складові криві
3349	теплотехнология
3352	переработка отходов
3353	микроволновой экстрактор
3354	тепломассоутилизатор
3358	подрібнення
3359	углеводороды
3362	составные кривые
3363	утилиты
3364	рекуперация.
3365	энерготехнологии
3369	экспериментальное исследование
3370	теплоутилизатор
3371	межкомпонентный теплообмен
3373	время релаксации
3374	число Фурье
3375	безразмерная температура
3376	гиперболическое уравнение
3377	теплопроводность
3379	охлаждение
3380	газотурбина
3381	лопатка
3382	энергомашиностроение
3383	Карно
3384	тепловий двигун
3385	енергетичні перетворювання
3386	реверсивний цикл
3387	конденсационный газовый котел
3389	м'ясо індика
3391	вівсяні висівки
3392	рецептура
3395	молочно—рисова суміш
3397	йогуртові культури
3401	морозиво
3402	рослинні олії
3403	жири
3404	жирні кислоти
3407	білковий кисломолочний продукт
3411	гомогенізація
3412	пастеризація
3414	ультрафільтрація
3417	виноградне сусло
3418	бродіння
3419	газова суміш
3420	цукор
3421	пивоварні сухі дріжджі
3422	пивне сусло
3423	ступінь зброджування
3424	головне бродіння
3426	сорбенти біологічного походження
3427	хітозан
3428	залізний кас
3429	деметалізація вина
3435	сіль
3437	монокальційфосфат
3438	фітаза
3440	функциональные ингредиенты
3441	кофейный шлам
3442	свойства пищевых волокон
3445	рибні пресерви
3447	фаршеві вироби
3448	рослинні текстурати
3449	складний сировинний склад
3450	функціональні властивості
3451	органолептична оцінка
3453	топінамбур
3454	пюре
3455	поліфенолоксидаза
3456	солодкий соус
3457	структуроутворювачі
3460	вичавки
3466	енергоефективні технології
3469	драглі
3470	модифіковані пектинові речовини
3471	кверцетин
3472	плодоовочева сировина
3473	пероксидаза
3475	агар-агар
3477	фізико-хімічні та мікробіологічні показники
3478	Всесвітня торговельна організація
3479	структура технологічної нормативної документації
3480	експеримент
3481	напої
3482	форсунка
3483	змішування
3484	струминний змішувач
3485	цукровий сироп
3487	залежність
3490	плоди
3492	холодний спосіб
3493	перфорована оболонка
3494	напівфабрикат
3495	кісточки
3500	когенерація
3501	переробна галузь
3502	системи аспірації
3503	реконструкція
3505	економічна  вигода
3506	компоновка
3507	просторова
3509	пакувальні
3510	лінії
3511	технологічні
3513	-- оксіпропіонова кислота
3520	vacuum evaporation
3522	power supply
3523	фракція С9
3524	катіонна коолігомеризація
3525	коолігомери
3526	нафтополімерні смоли
3841	tocopherols
3527	побічні продукти піролізу
3528	ректификация
3532	технологическая схема
3534	heat regeneration coefficient
3535	жирова кулька
3536	сили
3537	дисперсна фаза
3538	механізм
3539	руйнування
3540	струменева гомогенізація
3541	теорія
3543	рівновага
3544	міжклітинний об’єм
3545	йонний обмін
3546	зміна концентрації
3547	мембранне фільтрування
3549	системний аналіз
3550	імітаційна модель
3551	інфрачервоне жарення
3552	відбивач
3553	біфштекс
3556	застійна зона
3557	коміркова модель
3561	динамика сушки
3562	сферическая частица
3563	кипящий слой
3565	термомеханічна обробка
3570	микроволновый интенсификатор
3574	Лекарственное растительное сырье
3577	экспериментальное моделирование
3584	імпульсне електричне поле
3585	електричні розряди високої напруги
3588	біологічно активні речовини
3590	запірно-регулююча
3591	трубопровідна
3592	арматура
3593	електропневматика
3605	швидкість сушіння
3606	зональний механізм сушіння
3607	дериватографія
3608	теплота зневоднення
3609	термічна стійкість
3611	ревінь
3612	Псевдозрідження
3613	гранулоутворення
3614	добрива
3615	кінетика.
3616	«повітряна» окалина
3617	полімерні фосфати
3618	натрій пірофосфат
3619	рентгенофазовий аналіз
3620	калію сульфат
3621	розчинення полідисперсної твердої фази
3630	глибока утилізація теплоти димових газів
3633	Foliations
3634	B-foliations
3635	non-negative curvature
3636	3-dimensional manifolds
3637	Cohn-Vossen theorem
3638	Morse function
3639	Kronrod-Reeb graph
3640	Partial differential equations
3641	Pfaffian system
3642	contact structures
3643	local equivalence
3644	f-структура; 2F-планарное отображение
3645	Lie--Mobius geometry
3646	Locally conformal Kaehler manifold,
3647	slant distribution,
3648	semi-slant submanifold,
3649	warped product semi-slant submanifold
3650	плюригармоническая функция,
3651	регулярная ткань
3652	комутативна асоціативна алгебра,
3653	моногенна функція,
3654	розширення алгебри
3655	Classical Weierstrass function
3656	box dimension
3657	Rankin-Cohen brackets
3658	deformation
3659	nonplanar graphs
3660	cubic graphs
3661	genus
3662	edge deletion number
3663	connected sum of graphs
3664	minimal graphs
3665	periodic data
3666	surface
3667	Параболическая структура
3668	квази-геодезическое отображение
3669	Ермітові многовиди
3670	конформно келерові мнговиди
3671	форма Лі
3672	конформно голоморфно-проективні перетворення
3673	geodesic
3674	integrable
3675	Jacobi field
3676	tube
3677	strongly separately continuous function
3678	Baire classification
3679	2F-планарне відображення
3680	f-структура
3681	Minkowski space
3682	Grassman image
3683	timelike surface
3684	Morse
3685	topological classification
3686	flow
3687	chord diagram
3688	The Palais-Smale condition
3689	Fr\\’{e}chet-Finsler manifold
3690	Ekelend's variational principle
3691	гиперболическое пространство положительной кривизны
3692	объем ортогонального h-конуса
3693	объем ортогональной h-пирамиды
3694	уравнение в частных производных
3695	криволинейная три-ткань
3696	регулярная три-ткань
3697	конфигурация Томсена на три-ткани
3698	шестиугольная конфигурация
3699	Багатозначна функція
3700	афінна функція
3701	лінійно опукла функція
3702	спряжена функція
3703	Шарування
3704	смугаста поверхня.
3705	Locally conformal Kaehler manifold
3706	slant distribution
3707	semi-slant submanifold
3709	Isometric coloring
3710	isometric Ramsey theorem
3711	metrically Ramsey ultrafilters.
3712	пространство Минковского
3713	грассманов образ
3714	поле Морса-Смейла
3715	потік Морса-Смейла
3716	тор з діркою
3717	топологічна класифікація
3719	striped surface
3720	complex hyperbolic triangle groups
3721	discreteness
3722	Евклидово пространство
3723	сфера
3724	шар
3725	выпуклость
3726	обобщенная выпуклость
3727	Часткова метрика
3728	частково метричний простір
3729	напівнеперервність
3730	регулярність
3731	метризовність.
3732	Слабкий склеювач
3733	теорема Лебеґа—Гаусдорфа
3734	класифікація Бера
3735	фрагментовне відображення
3736	кривизноподобный тензор
3737	почти контактное риманово многообразие
3738	многообразие Кенмоцу
3739	Сасакиево многообразие
3740	Сасакиева пространственная форма
3741	тензор контактно-голоморфной римановой кривизны
3742	Риманово пространство
3743	кватернионная структура
3744	келерова структура
3746	грассманово многообразие
3747	секционная кривизна
3748	Топологічна класифікація
3749	потік
3750	поверхня з межею.
3751	max-плюс опукла множина
3752	гіперпростір
3753	гільбертів куб
3754	шарування
3755	некомпактна поверхня
3756	розшарування
3757	селекція
3758	Леонид Евгеньевич Евтушик
3759	геометр
3760	Аффинная геометрия
3761	дифференциальные инварианты
3762	аффинные геометрические величины
3763	Локально конформно-келеровій многовид
3764	Похідна Лі
3765	голоморфно-проективне перетворення
3766	Рімановий простір
3767	Інфінітезимальні перетворення
3768	Тензор Ейнштейна
3769	f-атоми
3770	функцій Морса
3771	орієнтовані двовимірні многовиди
3772	M-theory
3773	vector bundles
3774	K-theory
3775	Geometry of chaos
3776	non-linear analysis
3777	radioactivity systems
3778	fucoxanthin
3779	gallic acid
3780	rutin
3781	Nitzschia thermalis
3782	response surface methodology
3783	Olive oil
3784	Uslu
3785	Phenolic Compounds
3786	Tocopherol
3787	Storage
3788	Achillea millefolium
3789	auto-oxidation
3790	essential oil
3791	food emulsion
3792	cooked sausages
3793	wieners
3794	protein
3795	protein-carbohydrate-mineral supplement
3796	animal proteins
3797	amino acid composition
3798	dried carrot pomace
3799	β-carotene
3800	special-purpose bread
3801	elderly people
3802	sunflower oil
3803	sunflower press cake
3804	sunflower oil meal
3805	quality
3806	coefficient of variation
3807	microbiota
3808	instant cereals
3809	military
3810	storage
3811	marshmallow
3812	gelatin
3815	foaming ability
3816	foam stability
3817	density
3819	germination,
3820	growth stimulant
3821	organic acids
3822	flouriness
3824	oenological tannins
3825	anthocyanins
3827	model solutions
3828	ecological biotechnology
3829	oilseed fat industry
3830	waste
3831	lipase Rhizopus japonicus
3832	enzymatic hydrolysis
3833	stability
3834	millet
3835	flour
3837	organoleptic estimation
3839	walnut oil
3840	pumpkin-seed oil
3842	antioxidants
3843	oxidative stability
3844	encapsulatio
3845	bifidobacteria and lactobacilli
3846	inulin
3847	lactulose
3848	synbiotic complex
3849	fatty filling
3850	waffles
3851	pregnant women’s nutrition
3852	sweet ice
3853	sweet products
3854	fatty acid composition
3855	sugar/acid index
3856	grape marc
3858	oenotherapy
3859	wine therapy
3860	Spa and Wellness industry
3861	polyphenols
3863	samplers
3864	grain mixtures
3865	multispectral analysis
3866	microwave-vacuum drying
3867	dried meat
3868	functional and technological properties
3869	residual moisture
3870	seeds
3871	sunflower
3872	vibrating sieve
3873	calibration
3874	numerical simulation
3875	histology
3876	lupin flour
3877	elecampane
3878	meat
3879	ready-to-cook chopped meat
3880	muscovy duck
3881	meat-containing cooked smoked sausage
3882	functional-technological indicators
3883	semi-finished freshwater mussels
3884	forcemeat systems
3885	cutlet
3887	orthogonal central composite design
3888	protein plant concentrates
3889	soybean
3890	peas
3892	additive
3893	compound feed
3894	microbiological characteristics
3895	sugar maize
3896	extruded products
3897	herbal supplements
3898	microbiological safety
3899	pectin substances
3900	fruit membranes
3901	seed membranes
3902	soy beans
3903	mustard
3904	rape
3905	esparset
3907	gel filtration
3908	milk whey protein
3909	bioactive peptides
3910	rosehips
3911	hawthorn
3912	phytomaterials
3913	extract
3915	structural and mechanical properties
3916	weak flour
3917	tomato
3918	bacteria
3919	fungi
3921	specific microflora
3922	fungicidal action
3923	antibacterial properties
3924	arabinoxylan
3925	papain
3926	complex
3927	activity
3928	maize
3930	cosmetics
3931	short chain peptide
3932	free amino acid
3933	serum protein concentrate
3934	peptidase
3935	fermentolysis
3937	response surface
3938	microalgae continuous cultivation
3939	glucose
3940	autotrophic and mixotrophic conditions
3941	biochemical composition
3942	gradient-continuous yeast generation
3943	fermentation
3944	yeasts Saccharomyces cerevisiae
3945	aeration intensity
3946	alcohol
3947	secondary metabolic products
3948	selection
3949	bacteriophage-insensitive mutants
3950	biotechnological potential
3951	functional nutrition
3952	lactic acid bacteria
3953	magnesium
3954	chelate complexes
3955	probiotic bacteria
3956	metabolites
3957	muropeptides
3958	gas-holding capacity
3959	mass exchange
3960	gas phase
3961	solubility
3962	pulse
3963	saturation
3964	sodium hypochlorite
3965	oxidation
3966	reagent methods
3967	fruit and vegetable juices
3968	organic contamination
3969	effluents
3970	beef
3971	color image processing
3972	color characteristics
3973	functional properties
3974	wheat flour
3975	water absorption capacity
3976	falling number
3977	gluten content
3978	semi-finished sponge-cake products
3979	nutritional value
3980	quality parameters
3981	glucan-containing raw materials
3982	oat and barley flour
3983	microwave extraction
3984	mass transfer
3985	intensification
3986	mechanodiffusion
3988	safety characteristics
3989	xenobiotics
3990	grapeseed powders
3991	natural and alkalized cocoa powder
3992	sour-cream butter
3993	temperature regimes for ripening
3994	crystallization of milk fat
3995	volatile organic acids
3996	diacetyl
3997	acidity
3998	semi-finished meat products
3999	edible coatingedible coating
4000	CO2-extracts of plants
4001	Olive oil; Sarı Ula; Phenolic Compounds; Tocopherol; Storage
4002	food films; uronate polysaccharide;, ionotropic gelation; differential scanning calorimetry
4003	cabbage broccoli; formation of crystals; quick-frozen cabbage broccoli
4004	milk whey; lactobionic acid; electrical discharge; magnesium;  manganese
4005	glucan; conformation; mushroom; enzymatic hydrolysis
4006	einkorn wheat
4007	Jerusalem artichoke
4008	freezing
4009	defrosting
4010	final fermentation
4011	baking
4012	breakfast cereals
4013	instant porridge and quick cooking
4014	map of strategic groups
4015	differentiation method
4016	rational motives
4017	emotional and social motives
4018	grapes
4019	powders
4020	dough
4021	butter biscuits
4022	rheological properties
4023	organoleptic characteristics
4024	specific volume
4025	wetting ability
4026	radish root vegetables
4028	polyethylene liner
4029	sanding
4030	container
4032	commodity losses
4033	wheat sprouted bread
4034	plasma-chemically activated water
4035	differential-thermal analysis
4036	staling
4037	crumbling
4038	crumb swelling
4039	bonded water
4040	free water
4042	mushrooms
4043	heavy metals
4044	stripping voltammetry
4045	nitric acid
4046	hydrogen peroxide
4047	sweet pepper
4048	cooling and warming rate
4049	physical and thermophysical parameters of the sweet pepper
4050	heat capacity
4051	enthalpy
4052	grape pomace
4053	convective drying
4054	regression equations
4055	moisture yield characteristics
4056	biosafety
4057	microbiological stability
4058	protein preparations
4059	protein-containing composition
4061	protein quality
4063	degree of digestibility in vitro
4064	calcium
4066	bioligands
4071	morphology
4072	scanning electron microscopy
4073	texture
4074	collagen
4075	tartrate ions
4076	luminescence
4077	ion of yttrium (III)
4079	preparative electrophoresis
4080	milk proteins
4083	high concentrated wort
4084	starch
4085	dry matter
4087	bifidobacteria
4088	propionibacteria
4089	consortium
4090	biologically active additive
4093	hydrodynamics
4098	buttermilk
4099	lactose
4100	diafiltration
4101	nanofiltration
4102	buttermilk concentrate
4103	nanofiltration membranes
4104	ultrafiltration membranes
4106	food markets
4108	technology
4111	beer
4112	malt barley
4113	hops
4114	brewer’s yeas
4115	quality indicators
4116	marmalade
4117	plant additives
4118	cryogenic technology
4119	cryopowder
4120	cryopaste
4121	antioxidant capacity
4122	wastewater
4123	heavy metal ions
4124	biosorption
4125	technologies
4126	mechanisms
4127	efficiency indicators
4130	sauces
4131	blueberry
4132	antioxidant
4133	composting
4135	compostable mixture
4136	mineral additive
4137	mesophilic and thermophilic modes of composting
4138	color
4139	fruit and berry raw material
4140	paste
4141	IR-dryin
4142	spectrum' change
4144	pre-treatment
4145	celery and parsnip roots
4146	darkening of root crops
4147	enzyme activity
4148	peroxidase
4149	polyphenol oxidase
4150	ascorbate oxidase
4151	L-ascorbic acid
4152	blanching
4153	microwave processing
4154	Frozen
4155	Oil physicochemical properties
4156	Pampus argenteus
4157	Sparidentex hasta
4158	Iranian fish species
4159	probiotics
4160	biomass
4161	autolysis
4162	peptidoglycan
4165	lysozyme
4166	low molecular weight peptides
4168	immunotropic properties
4169	Milk product
4171	probiotic
4172	Lactococcus sp.
4173	Bifidobacterium sp.
4175	quality aggregated index
4177	surface response
4178	marketing research
4180	military service people
4181	dry product package
4182	consumer benefits
4183	оrgаnіс prоduсtіоn
4184	prоduсts
4185	fооd іndustry
4186	есоlоgісаl sаfеty
4187	quаlіty fооd prоduсts
4188	сеrtіfісаtіоn
4189	skin
4190	microbiome
4192	"living cosmetics"
4193	"probiotic cosmetics"
4195	lactobacteria
4196	brynza
4198	starter Herobakterin
4199	starter RSF-742
4200	organoleptic parameters
4201	physical and chemical parameters
4202	number of viable cells
4204	м’ясо птиці
4205	мікробна контамінація
4206	МАФАнМ
4207	П3-оксонія актив 150
4208	м’ясопереробне підприємство
4209	milk whey
4210	bio-elemental particles of magnesium and manganese
4211	electrical discharge
4212	biological test-objects in vitro
4213	cell cultures
4214	cytotoxicity
4215	bakery products
4216	state control (supervision)
4219	livestock production
4220	state veterinary inspector
4221	accredited laboratory
4222	storage of cucumbers
4223	phenolic substances
4224	ascorbic acid
4225	carotenoids
4226	chlorophylls
4229	cereal cultures
4230	growth stimulator
4231	succinic acid
4232	3-pyridinecarboxylic acid
4233	pteroylglutamic acid
4234	germination energy
4235	germination ability
4236	grain flour content
4237	diffusion
4239	internal surface
4240	pumpkin fruit
4241	sucrose
4242	kinetics
4243	mass transfer coefficient
4244	goutweed (Aegopodium podagraria L.)
4245	herbal raw material
4246	herbal drugs
4247	lipid metabolism
4248	functional foods
4249	magnetized water
4250	magnetic field
4251	device for electromagnetic treatment of water
4252	freezing of water
4253	apple juice
4254	carrot juice
4255	beat juice
4256	ash berry juice
4257	линейный асинхронный двигатель
4258	конструктивные параметры
4260	рациональные значения
4261	функциональный модуль
4262	транспортные системы
4263	infant food
4264	sour-milk drink «Biolakt»
4268	biochemical indicators
4270	probiotic properties
4271	toxin-producing Bacillus cereus
4272	enterotoxins
4273	emetic toxin
4274	molecular genetic diagnosis
4275	polymerase chain reaction
4276	food safety
4277	metal packaging canning
4278	aggressive mediums
4279	an organic acid
4280	corrosion
4281	anticorrosive coatings
4282	pancakes
4283	stuffing
4284	iodine deficiency
4285	pre-cooked semi-product
4286	Laminarium
4287	seaweed
4288	biological activity
4289	nut
4291	fatty acids
4292	dispersion
4293	proteins
4294	fats
4295	drink
4297	жирнокислотний склад
4298	біологічна ефективність ліпідів
4299	рибо-рослинні напівфабрикати
4300	ω-3 поліненасичені жирні кислоти
4301	прісноводна риба
4304	короп
4305	лящ
4306	товстолоб
4308	жирно кислотний
4309	амінокислотний та мінеральний склад
4311	xylan
4314	yoghurt drinks
4315	combined contents of raw materials
4316	rice flour
4317	spelt flour
4318	balanced chemical composition
4320	lactobacterium
4321	biotechnology
4323	кисломолочний продукт
4324	лактоза
4325	β-галактозидазна активність
4326	заквашувальний препарат
4327	aromatization
4328	nanotechnology
4330	factors
4331	food
4332	polymer solution
4334	polyethyleneoxide
4335	velocity
4336	hydrodynamic field
4337	velocity gradient
4338	deformation effects
4339	смузі
4340	функціональні напої
4341	заморожування
4344	Bacillus cereus
4345	характеристика
4346	біологічна дія
4348	підготовка зразків
4349	прискорене визначення
4350	micromycetes
4351	osmotically active substance
4352	mold fungi
4353	canning
4354	syrups
4355	regression model
4356	томати
4357	виробництво томатопродуктів
4358	томатна паста
4359	томатні кубики
4360	томати очищені від шкірки
4361	пектинметилестераза
4362	лікопен
4363	planting scheme
4364	training system
4365	carbohydrate-acid complex
4366	phenolic complex
4367	oxidative properties
4370	ion of terbium (III)
4372	dietetic additives
4373	крохмалі фізичної модифікаці
4374	крохмальні суспензії
4375	оклейстеризовані крохмальні дисперсії
4377	sodium selenite
4378	inoculums
4379	dietary supplement
4380	culture liquid
4381	supernatant
4382	propionic acid bacteria
4383	metabiotic
4384	icewine
4385	dessert wines
4386	alternative methods
4387	price
4389	immunomodulators
4390	whey protein
4391	sweet whey
4392	lactoferrin
4393	lactoperoxidase
4394	chromatography
4395	казеїн
4396	казеїнові міцели
4397	білки молока
4398	функціонально-технологічні властивості
4400	модифікація
4401	декальцинування
4402	плоди кісточкових культур
4404	діаметри отворів
4405	колова швидкість
4406	whey
4407	strawberry filler
4408	Tagetes
4409	bioactivity
4410	organoleptic assessment
4411	complex quality index
4416	cream of tartar
4417	CO2-extract
4418	grape juice
4419	плівки для продуктів харчування
4420	комбіновані плівкові комбінаці
4421	вакуумне упакування
4422	приготування у вакуумі
4423	безпека харчових продуктів
4424	технологія Sous-Vide
4426	туристів
4427	експедиторів
4430	the profile method
4431	organoleptic testing method
4432	biometals
4433	bioavailability
4438	immunotropic substances
4439	jelly
4440	jost
4441	spirulina
4442	preventive nutrition foods
4443	radio protector
4445	diet
4446	field ration
4447	military ration
4448	nutrition ration
4449	military personnel
4450	nutritional standards of nutrition
4451	nutrient composition
4452	nutrition systems
4453	mathematical models
4454	targeted functions
4455	linear programming problems
4456	functionals of balancing groups of nutrients
4457	aggregated restrictions
4458	tasks of integral mathematical programming with Boolean variables
4459	diabetes type II
4460	insulin resistance
4461	metabolic syndrome
4462	minerals
4463	chia seeds
4464	food rations
4465	stone fruit crops
4466	perforated surface
4468	semi-product
4470	природна мінеральна вода
4471	свердловина № 14/7832
4472	макрокомпоненти
4473	мінералізація
4474	концентрації
4475	апроксимаційні лінії
4476	санітарно-мікробіологічний стан
4477	mousse
4478	wheat starch
4479	innovative idea
4480	innovative strategy
4481	foamy structure
4482	foaming capacity
4484	пряники
4486	черствіння
4488	лужність
4490	water
4491	air
4493	epidemic safety
4494	sanitary and chemical indicators
4495	waxy wheat flour
4496	yeast-containing cakes
4497	porosity
4501	vegetable powders
4502	cold spray drying
4505	water absorption coefficient
4506	ability to hold fat
4507	fat-protein emulsion (FPE)
4508	fortified blending of vegetable oils (FBoVO)
4509	meat pates
4510	функціональні продукти
4511	оздоровче призначення
4513	пшоно
4514	закваски
4515	ферментний препарат
4517	quick-frozen semi-finished products
4518	polysaccharides
4519	lipids
4520	acid value
4522	edible coating
4523	gingerbread products
4524	biological value
4525	shelf life
4526	market
4527	new product
4528	yoghurt drink
4530	product positioning
4534	метод кінетостатики
4536	водосховище
4537	рибні ресурси
4538	динаміка вилову та споживання
4539	сосна (Pinus Sylvestris) (sosnowskyi)
4540	фенольные вещества
4541	липиды
4542	лигнин
4543	проантоцианидины
4544	шрот насіння льону
4545	борошно пшеничне
4547	харчові волокна
4548	інтенсивність бродіння' в’язкість
4549	полуфабрикаты
4550	криопротекторы
4551	мясное сырьё
4554	фаршева система
4555	стабілізатор
4556	колаген
4557	кремнезем
4558	білкозин
4559	зразок
4560	комплекс “гість-хазяїн”
4561	циклодекстрини
4562	йод
4563	збагачення харчових продуктів
4564	сосиски
4565	есенційні мікроелементи
4566	високогустинне пивоваріння
4568	пивні дріжджі
4569	інтенсифікація бродіння
4570	вітаміни
4571	оптимальне дозування
4572	метилпарабен
4574	ион тербия (III)
4575	2
4576	2' –дипиридил
4577	бактеріальний препарат
4578	сирокопчені продукти з яловичини
4579	hydrolytic enzymatic agent with α-D-galactosidase activity
4580	soya олигосахариды
4582	enzymatic agent Galactolongin G10x
4584	bacterias
4585	teichoic acids
4587	muramildipeptyd
4588	destruction
4589	enzymes
4590	type II diabetes
4593	body mass index
4594	glycemic load
4595	diets
4596	пластифікатор ВВ-ПМЛ
4597	параметри процесу
4598	математичне і чисельне моделювання
4599	пластифікація
4600	кондитерська маса
4603	будова плодів
4605	м’якоть
4608	порошок з листя волоського горіха
4609	борошно «Здоров’я»
4610	борошняні кондитерські вироби
4611	пісочний напівфабрикат
4614	candied products
4616	Gantt diagram
4617	organoleptic indicators
4618	чіпси
4619	картопля
4620	питома поверхня
4621	вміст жиру
4622	температура обсмаження
4626	залізо
4627	комплекс
4628	анемія
4629	хлебопекарные дрожжи
4631	селен
4632	микроэлементы
4633	молочная кислота
4634	хлебобулочные изделия
4635	термическая обработка
4637	альгінат натрію
4638	йота-карагінан
4639	агар
4640	вершкові креми
4641	набухання полісахаридів
4642	емульсійно-пінні системи
4644	gourmet meat
4646	yield
4647	catholyte
4648	anolyte
4649	brine
4650	цитрат - ионы
4652	ион иттрия (III)
4653	рутин.
4654	microbiota of meat
4655	Lactobacillus
4656	storage life
4657	antagonistic action
4658	Saccharomyces cerevisiae
4659	полісахарид
4660	глюкан
4661	зимозан
4662	надвисокочастотне випромінювання
4663	шроти
4664	пісочне печиво
4665	модельні композиції
4666	олійні культури
4667	бисквитные полуфабрикаты
4668	альбумин сухой и модифицированный
4669	амарантовая мука
4670	черствение
4671	гидрофильная способность
4672	діаграма Ісікава
4673	глютин
4674	борошняний кондитерський виріб
4675	мафін
4678	сільськогосподарська сировина
4679	статистичний аналіз
4680	критерій Кохрена
4681	житнє борошно
4683	підкислювач
4684	ферментні препарати
4685	жувальна карамель
4686	цукровий діабет
4687	тагатоза
4688	мальтитол
4689	гліцерол
4690	калорійність
4691	глікемічність
4692	цветы Hibiscus rosa-sinensis
4693	лекарственные растения
4694	экстракты
4695	степень этерификации
4696	пектин
4697	аминокислоты
4698	напитки функционального назначения
4699	зерновий хліб
4700	композиція ферментних препаратів
4707	натрію селеніт
4708	оптична щільність
4711	низькокалорійний майонез
4712	маркетингові дослідження
4713	позиціонування продукту
4715	класифікація
4717	строк придатності
4719	натуральні ароматизатори
4720	кінетична модель
4721	controller
4723	refrigeration system
4724	Arduino
4726	algorithm
4727	конденсація
4729	теплообмінник
4730	гладка труба
4731	стратифікований режим
4732	Nanofluid
4733	Surface Tension
4734	Saturated Vapor Pressure
4735	Experiment
4736	Predicting Method
4737	Cooling
4738	Ambient air
4739	Inlet air
4740	Gas turbine unite
4741	Temperature depression
4742	Climate
4743	Water-fuel emulsion
4744	Exhaust gas boiler
4745	Condensing heating surface
4746	Waste Heat Recovery Chiller
4747	Cooling, Intake Air
4748	Scavenge Air
4749	Exhaust Gas
4750	Ship Main Engine
4752	турбогенератор
4753	вихрова розширювальна машина
4754	стенд
4755	інформаційно-вимірювальна система
4756	Energy efficiency
4757	; Thermocompressor jet unit
4758	Liquid-vapor compressor
4759	Laval nozzle
4760	CFD-modeling
4761	Ejector
4762	Chiller
4763	Recirculation
4764	Exhaust gases
4765	Specific fuel consumption
4766	Ship
4767	Internal combustion engine
4768	Harmful emissions
4769	Холодильне обладнання
4770	Температура
4771	Теплопритоки
4772	Навантаження
4773	Потужність
4774	Віброкипіння
4775	Віброзрідження
4776	Математичне моделювання
4777	Сипкі матеріали
4778	Гідродинаміка
4779	Системи автоматизованого моделювання
4782	кондиціювання повітря
4787	Викиди
4788	Оксиди азоту
4789	Рециркуляція
4790	Судновий дизель
4791	Відпрацьовані гази
4792	Охолодження повітря
4793	Холодильна машина
4794	Газотурбінна установка
4795	Клімат
4796	Побутовий холодильник
4797	Схема заміщення
4798	Чотириполюсник
4799	Температурний напір
4800	Тепловий потік
4801	Коефіцієнт корисної дії
4802	Коефіцієнт навантаження
4803	Кондиціювання
4804	Зовнішнє повітря
4805	Теплове навантаження
4809	повітряний конденсатор
4812	щільність теплового потоку
4813	холодильний агент
4815	тригенерація
4816	компресорна холодильна машина
4817	кондиціювання
4818	опалення
4819	регулювання роботи системи
4820	тропічний клімат
4821	NGN
4822	інтелектуальний сервіс
4823	ефективність управління
4824	; показники якості
4825	самоподібність
4826	GPSS
4827	NS-2
4829	Криогенная техника
4830	Редкие газы
4831	Вихревая труба
4832	Масштабный фактор
4833	Эксперимент
4834	Нанофлюид
4835	Изопропанол
4836	Наночастицы Al2O3
4837	Давление насыщенных паров
4838	Холодоагент
4839	Нанофлюїд
4840	Кипіння у вільному об'ємі
4841	Коефіцієнт тепловіддачі
4842	Інтенсифікація тепловіддачі
4843	Микроволновое поле
4844	Диэлектрический материал
4845	Математическая модель
4846	Нагрев
4847	Сушка
4849	абсорбционные холодильные агрегаты
4850	ручейковое безнапорное течение
4852	расчет
4854	Турбіни
4855	Моделюванняї
4856	Структура потоку
4857	Удосконалення геометрії
4858	Adsorption
4859	Oxygen
4860	Short-cycle adsorption
4861	PSA
4862	VPSA
4863	Охолодження
4864	Середньооб'ємна температура тіла
4865	Температурне поле продукту
4866	Критерії Фур'є, Біо
4867	Системи кондиціювання повітря
4868	Зволожувальні пристрої
4869	Регулярні насадки
4870	Дозування
4871	Тепловологістні навантаження
4872	Взаимодействие
4873	Выброс
4874	Замкнутый и подвижный слои
4875	Переход тепловых потоков
4876	Регулирование потерь
4877	Теплоноситель
4878	Теплообмен
4879	Тектология
4880	Эксплуатационный режим
4881	бытовая техника
4883	комбинированный абсорбционный холодильный прибор
4884	дополнительная тепловая камера
4885	водоаміачні абсорбційні холодильні агрегати; моделювання процесів тепло масообміну; термодинамічні цикли; енергозбереження; широкий діапазон температур навколишнього середовища
4886	Триетиленгліколь
4887	Диметиловий ефір
4888	Адіабатичний калориметр
4889	Модельна система
4890	Теплоємність
4891	Ентальпія
4892	Ентропія
4893	холодильная машина
4894	наночастица
4895	нанодобавка
4896	коэффициент теплопередачи
4897	коэффициент теплоотдачи
4898	конденсатор
4899	изобутан
4900	кріогенна техніка
4901	рідкісні гази
4902	газові суміші
4903	вихровий охолоджувач
4904	вакуум-насос
4905	ежектор
4906	узлы стыковки
4907	система термостатирования
4908	космическая ракета
4909	Centrifugal compressor
4910	Stage
4911	Impeller
4912	Diffuser
4913	Зберігання соковитої рослинної продукції
4914	Зниження витрат енергії
4915	Коливання температури
4916	Акумуляція холоду
4917	Упаковка з підвищеною тепловою інерційністю
4920	Енергоспоживання
4921	Теплоносій
4922	Теплофізичні властивості
4923	Густина
4924	В'язкість
4925	Теплопровідність
4927	Solar energy capture system
4928	polymeric solar collector
4929	heat absorber
4930	transparent cover
4931	summary heat losses
4932	Тригенерація
4933	Мала енергетика
4934	країни Близького Сходу
4935	географія
4936	клімат
4937	Модель аналізу
4938	Аеротермопресор
4939	Газотурбінні установки
4940	Проміжне охолодження
4941	Питома витрата палива
4942	Каскадна холодильна машина
4943	Термодинамічний аналіз
4944	Ентропійно-цикловий метод
4945	Рефрижераторний контейнер
4949	Газотурбінний двигун
4951	зовнішнє повітря
4952	теплове навантаження
4953	холодильна машина
4954	кліматичні умови
4955	база даних, предметна область, модель предметної області, інформаційна система, властивості об’єктів, статистичні характеристики
4957	Теплообмін
4958	Гранулированный слой
4959	Одномерное приближение
4960	Температурные зависимости
4961	Внутренние источники
4962	Расчет температурных полей
4966	кут затоплення труби
4968	коефіцієнт тепловіддачі
4969	fullerene
4970	carbon nanotubes
4971	carbon dioxide
4972	Joule – Thomson effects
4973	nanofluids
4974	saturation curve
4975	thermodynamic properties
4976	повітряно-теплова завіса
4977	плоский повітряний струмінь
4979	швидкість
4980	теплова енергія
4982	ккондиціювання повітря
4983	теплова хвиля
4984	холодопродуктивність
4985	нестаціонарний теплообмін
4987	запізнювання
4989	Centrifugal Compressor
4991	Elementwise Analysis
4992	Performance
4995	пищевая промышленность
4997	пельмени
4998	производство
4999	робототехника
5000	метан
5001	рівняння стану
5002	термодинамічні властивості
5003	лінія плавлення
5004	високий тиск
5007	Поверхнево-активна речовина
5008	Колоїдна стабільність
5009	Розмір наночастинок у нанофлюїді
5015	кипение
5016	терморегулирование
5017	микроканалы
5018	пористые среды
5020	мультисервісна мережа
5021	показник Херста
5022	R/S метод
5023	аналітична модель
5024	Efficiency
5025	Refrigerators
5026	Smart Systems
5028	Pressure swing adsorption
5029	Adsorbent grain
5030	Periodic process
5031	Fourier series.
5032	сонячний колектор
5034	тепло-масообмінний аппарат
5035	програмне забезпечення
5036	графічний ін-терфейс
5037	Маршрутизатор
5038	Протокол маршрутизації
5039	Складні мережі
5040	Cisco Packet Tracer
5041	Протокол OSPF
5042	Інтернет речей
5043	мікроконтролер
5044	інтерфейс
5045	Ethernet
5046	контроль температури.
5047	абсорбционные водоаммиачные холодильные установки
5048	абсорбционно-диффузионные холодильные агрегаты
5049	эксергетический анализ
5051	Системи термостатування
5052	Вузли стикування
5053	Ракети космічного призначення
5054	Protective coating
5055	Low-esterified pectin
5056	Freezing
5057	Refrigerated storage
5058	Lipids
5059	PUFA
5060	Hydrolytic decomposition
5061	Oxidative damage
5062	Hypophthalmichthys molitrix
5063	адсорбційна холодильна геліосистема
5064	полімерний сонячний колектор
5065	стільниковий полікарбонатний пластик
5066	Отходящие газы
5067	Утилизация
5068	Теплообменник
5069	Гранулированная насадка
5070	Методика расчета
5071	Эффективность.
5072	Refrigeration systems
5073	Energy  efficiency
5074	Smart working fluid
5075	Холодильна машина; ODP; GWP; Холодоагент
5078	Zeolite
5080	Nitrogen
5085	тривимірне моделювання
5086	граничні умови
5088	акумулятори холоду
5089	водний лід
5090	танення водного льоду
5091	ANSYS CFX
5092	Холодильные системы
5093	Энергоэффективность
5094	Облачный компьютинг
5095	Интеллектуальные сети электроснабжения
5096	Тепловий насос
5097	бак-акумулятор
5098	бойлер
5099	термічний опір теплопередачі.
5100	Системы термостатирования
5101	Ракеты космического назначения
5102	Flow
5103	Microchannel
5104	Model
5105	Velocity Scaling Law
5106	Knudsen Flow Regime
5107	Flowrate Scaling
5108	Microelectronics Thermal Control Systems
5110	Wave
5111	Gas Chromatography
5112	Van Deemter Equation
5113	Выброс энергии
5114	Подача тепла
5115	Перемещение среды
5116	Подвижный и замкнутый слои
5117	Температура поверхности
5118	Теплоотдача
5119	Тепловосприятие
5120	Термическое сопротивление
5121	Утилизация бросовой теплоты
5122	Теплоиспользующие холодильные машины
5123	Пароэжекторные
5124	Абсорбционные
5125	Водоаммиачные
5126	Сравнительный анализ расчетных циклов
5127	Ексергетичний баланс
5128	Split-кондиціонер
5129	Ексергетична ефективність
5130	Холодильний агент
5131	Втрати ексергії
5132	Sustainable Development
5133	Green Economy
5134	Energy Policy
5135	Energy Efficiency Projects
5136	Regulatory Framework
5137	Profits Formation
5138	Financial-Economic System
5139	Cross-Sectoral Governance and Finance
5140	Economic-Social-Ecological Analysis
5141	Моделювання
5142	повітроохолоджувач
5143	іней
5144	відтайка
5145	відносна вологість повітря
5146	щільність теплового потоку.
5147	Методы автоматизации проектирования
5148	AutoCAD
5149	Принципиальная схема
5150	Блок
5151	Библиотека элементов
5152	Сценарий
5153	Макрокоманда
5154	Интенсивность отказов
5155	Термоэлементы
5156	Каскады
5157	Перепад температуры
5158	комп'ютерна анімація
5159	рідинне моделювання
5160	технології реалістичного моделювання і рендеринга
5161	холодильные системы
5163	интеллектуальные сети электроснабжения
5164	Опреснение
5165	Вымораживание
5166	Соли
5167	Тяжелая вода
5168	Электростанция
5174	теплоізоляція
5175	рекуператор
5176	воздушно-тепловая завеса
5177	плоская воздушная струя
5178	компактная воздушная струя
5179	начальная температура истечения
5180	эффективный температурный интервал
5181	Тепловой аккумулятор
5183	Плотный слой
5184	Температурные кривые
5185	Тепловой баланс
5186	абсорбционный холодильный агрегат
5187	дефлегматор
5189	тепломассообмен
5191	влияние температуры воздуха окружающей среды
5192	Автоматизована система
5193	Облік електроенергії
5194	Енергомережа підприємства
5195	Оптовий ринок електричної енергії
5196	Вартість електричної енергії
5197	Лічильники електричної енергії
5198	Споживачі електричної енергії.
5199	Информационная безопасность
5200	АСУ ТП
5201	SCADA
5202	Электроэнергетика
5203	Оптимізація
5204	Енергозбереження
5205	Кондиціювання повітря
5207	Нестаціонарне навантаження
5208	Інверторний привід
5209	Компресор
5210	Вентилятор
5212	Переход тепла
5213	Система
5217	Математична модель
5218	Бульбашка
5220	Газовий гідрат
5221	Тиск
5223	Энергетическая эффективность
5224	Абсорбционный холодильный агрегат
5225	Влияние форсажа тепловой нагрузки генератора
5226	Влияние температуры воздуха окружающей среды
5227	Транспорт аммиака в зону испарения
5228	Повітряний конденсатор
5229	Експериментальний стенд
5230	Теплообмінна поверхня
5231	Відклади
5233	Технічно важливі речовини
5234	Програмний модуль
5236	Рівняння стану
5237	Октуполь-октупольна взаємодія
5238	интернет вещей
5239	интеллектуальна техника
5240	умный дом
5242	уязвимости программного обеспечения
5243	структурна живучість
5244	інтелектуальна надбудова
5245	верхня межа живучості
5246	нижня межа живучості
5247	децентралізований принцип управління.
5248	Туннельная камера
5249	Холодильная установка
5250	Согласованное регулирование
5253	Динамическая точность
5254	Моделирование
5255	Воздухоохладитель
5256	Формирование инея
5257	Теплопроводность инея
5258	Плотность инея
5259	Тепло- и массообмен
5260	Refrigeration Systems
5261	Systems of Primary Refrigeration
5262	Storage of Small  Fractioned Cultures
5263	Heat Exchange of a Fixed Layer
5265	басейн
5267	бай пасування
5268	нестаціонарний тепло масообмін
5270	Thin Porous Media
5271	Non-Stationary Gradient Model
5272	Transport Process Of Fractal Fluid Phases
5273	Non-Gibbsian Heterogeneous Structures
5275	Нанофлюиды
5276	Растворы хладагент-масло-фуллерены С60
5278	Поверхностное натяжение
5279	Природный газ
5280	Сланцевый газ
5281	Рынок природного газа
5282	Сжиженный природный газ
5283	аккумулятор теплоты
5284	нестационарная теплопроводность
5285	регулярный тепловой режим
5286	системы теплоснабжения.
5288	Дисперсный материал
5289	Прямоток
5290	Противоток
5292	Температура компонентов
5294	Розподільчий трансформатор
5295	Моделювання теплообміну конвекцією
5296	Поле швидкості
5297	Поле температур
5298	Теплова підсистема
5299	холодильная камера
5300	технико-экономический расчет
5301	магазиностроениe
5302	cooling chamber
5303	techno-economic calculation
5304	shop building
5305	Rotary-vane gas refrigerating machine
5306	Plate-fin heat exchanger
5307	Numerical model
5308	Helium
5309	Энергетический анализ
5310	Компрессорная теплоиспользующая холодильная машина
5311	Термодинамическая эффективность
5312	R744
5313	Heat engines
5314	Zero emission vehicles
5315	Liquid nitrogen
5316	Liquid air
5317	Cryogenic
5318	Stirling engine
5319	Конденсація
5320	Мініканали
5323	Міжфазне тертя
5324	Поверхневий натяг
5325	абсорбционный холодильный прибор
5326	экспериментальные исследования
5327	генераторный узел
5330	влияние температуры окружающей среды
5331	Дейтерий
5335	колебания давления
5336	резонанс
5337	демпфирующий колпак
5338	передаточная функция
5339	гармонический сигнал
5340	Растворы
5341	Хладагент
5342	Фуллерены
5344	Плотность
5345	Вязкость
5346	Концентрация
5347	Тепловой поток
5349	Кислородный режим
5350	Теплофизические параметры
5351	Интенсификация
5352	Коэффициент теплоотдачи
5355	Тепловий баланс
5356	Часові діаграми температур
5357	Графік навантаження
5359	горелки отопительных котлов
5360	лопатки завихрителей
5361	остаточные напряжения в лопатках завихрителей
5362	Системы критического применения
5363	Поразрядные конвейеры
5364	Рабочее диагностирование
5365	Контроль по неравенствам
5366	Границы результата
5367	Доступ к данным
5368	Heating Loading
5369	Freon
5370	Two Stages Heat Pump Installation
5371	Low-Potential Source of Heat
5372	Energy Efficiency
5375	Спекание
5377	Керамика
5378	тепловые режимы
5380	абсорбционный холодильник
5382	тепловая изоляция
5383	пленочное течение по вертикальной стенке дефлегматора
5384	абсорбционный водоаммиачный холодильный агрегат
5385	гелиоколлектор
5386	Эксергетический анализ
5387	Абсорбционно-резорбционная холодильная машина
5388	Деструкция эксергии
5389	Система критического применения
5390	Матричный умножитель и делитель
5391	Контролепригодность схемы
5393	Модель результата
5394	Контроль мантисс по неравенствам
5395	Достоверность контроля результатов
5396	Режим работы
5397	Холодопроизводительность
5402	Теплоприпливи
5403	Тепловтрати
5404	Тепловиділення
5405	Запізнювання
5407	Радіаційна температура.
5408	Датчик
5409	Преобразователь
5410	Система автогенераторного типа
5411	Измерение деформации
5412	Высокая точность
5419	Solutions of organic acids
5420	Pectin
5421	Mesopelagic fish
5423	Water yielding
5424	Organoleptic prop-erties.
5425	Диметиловый эфир
5426	Триэтиленгликоль
5427	Экспериментальное исследование
5428	Адиабатный калориметр
5429	Теплоёмкость
5430	Повітряно-теплова завіса
5431	Плоский повітряний струмінь
5432	Початкова температура витікання
5433	Ефективний температурний інтервал
5435	Cистеми кондиціювання повітря
5436	Чисті приміщення
5438	Температура і вологовміст навколишнього середовища
5439	Абсорбционный холодильник
5440	Горелочное устройство
5441	Интенсификаторы горения
5443	Конденсация
5444	Гладкая горизонтальная труба
5445	Бинарные смеси
5446	Равновесие жидкость–пар
5447	Неон
5448	Ксенон
5449	Криптон
5450	Уравнения фазового равновесия
5451	Associated petroleum gas
5452	Cascade refrigeration system
5453	Environmentally friendly refrigerant
5455	Energy saving potential
5456	Ethane re-condensing. .
5457	Refrigeration system
5458	Three band tariff
5459	Cold accumulation system
5461	Dairy plant
5462	формирователь временных интервалов
5463	схема сравнения кодов
5464	двойная память
5465	инструментальная динамическая погрешность.
5469	функциональная живучесть
5470	интеллектуальная надстройка
5471	децентрализованное управление
5472	интеллектуальный сервис
5473	Дымовые газы
5474	Эффект Коанда
5475	Канцерогены
5476	Скоростное ядро потока
5477	Полициклические ароматические смолы
5478	теплоснабжение
5479	конденсационные котлы
5480	тепловые насосы
5481	снижение температурного графика
5482	Параболоциліндричний рефлектор
5483	Апертура
5484	Сонячна інсоляція
5485	Короткофокусні
5486	середньофокусні
5487	довгофокусні дзеркала.
5488	Взаимодействие составляющих
5489	Нормы
5490	Потоки замкнутые и подвижные
5491	Цель
5492	Время релаксации
5493	Число Фурье
5494	Безразмерная температура
5495	Гиперболическое уравнение
5496	Теплопроводность
5497	Evaporative cooler
5498	Multichannel packing
5499	Solar water collector
5500	Polymeric materials
5501	Coupled heat and mass transfer
5502	Recondensation
5503	Абсорбционный холодильный прибор
5505	Транспортные усло-вия
5506	Качка
5507	Тряска
5508	Дифферент.
5509	Поршневой насос
5510	Срыв подачи
5511	Датчик срыва
5513	Осциллограммы
5514	Дистанційне навчання
5515	Інформатизація освіти
5516	Комп’ютеризаціяосвіти
5517	Тестовий контроль
5518	СистемаMoodle
5519	Аналіз структури тесту
5520	Идеальный газ
5521	Maple
5522	OpenMaple
5525	Витрата повітря
5527	Повна теплота
5528	Вологість
5529	Витрата холоду
5530	Оптимізація.
5532	Полициклические ароматические углеводороды
5533	канцерогены
5534	Эжекторный фильтр
5535	Газовый поршень
5536	Непрямое испарительное охлаждение
5537	Тепломассообменная аппаратура
5538	Пленочные течения
5539	Задержка жидкости
5540	Эффективность процесса
5541	Агломерация
5542	Спекательная тележка
5543	Бокситы
5544	Средний диаметр
5546	Температурное поле
5548	Смесь R125/R134а
5551	Уравнения
5552	Малая энергетика
5553	Тригенерация
5555	Энергетическая эффективность.
5556	Microchannel condenser
5557	Heat transfer
5558	Hydrodynamics
5559	Aerodynamics
5561	Entropy-cycle method
5562	Irreversibility
5563	Entropy generation minimization
5564	Techno-economic analysis.
5566	Intellectual Superstructure
5567	Intellectual Services
5568	Quality Criterion
5569	Weighting Coefficients.
5570	Solubility
5571	Miscibility
5572	Refrigerant
5573	Polyolester Lubricant
5574	Refrigerant/Lubricant Mixture
5575	Measurements
5576	Equation.
5577	Secondary сoolant
5578	Kinematic viscosity
5579	Ternary solutions
5580	Propylene glycol
5581	Water
5582	Ethanol
5584	Modelling
5585	Annual losses of petroleum products
5586	System of vapor recovery of oil products
5587	Price of ton of oil product
5588	Ejector heat interchanger
5589	High-grade petrol
5590	Economic benefit.
5592	Solar collector
5593	Test rig
5594	Hot water supply system
5595	Environment.
5596	Ice
5597	Differential equation
5598	Ice build-up time rate
5599	Ice water
5600	Melting
5601	Experimental rig.
5602	Stirling gas refrigerating machine
5604	Mathematical model
5606	Air.
5607	Річні приведені витрати
5608	Екологічна складова експлуатаційних витрат
5609	Плата за використання кисню.
5611	Вентиляція
5613	Повітроводи
5615	Повіт-ророзподілення
5616	"Робоча точка"
5617	Швидкість повітря.
5618	Жидкостно-паровой эжектор
5619	Цилиндрическая камера смешения
5620	Численное моделирование
5622	Эксергетичекая эффективность.
5623	Промежуточный хладоноситель
5624	Пропиленгликоль
5625	Этинегликоль
5626	Вода
5627	Этанол
5629	Экспери-мент
5630	Методы расчета.
5631	Динамическая библиотека
5633	OpenMaple.
5634	Параболоциліндричний
5635	Рефлектор
5639	середньофо-кусні
5641	Мультиагентная система
5642	Виртуальное предприятие
5643	Технологическая подготовка предприятия
5644	Архитектура многоагентной системы.
5645	Криохирургический аппарат
5646	Криозонд
5647	Рабочее тело
5648	Этиловый спирт
5649	Теплопроводность.
5650	тепловикористальна компресорна холодильна машина – регенерація тепла – R744 – термодинамічний аналіз – ексергетична ефективність.
5651	Тепло-массообменный апарат
5652	Псевдоожиженный слой насадки
5653	Испарительный охладитель
5654	Охлади-тель непрямого типа
5655	Абсорбер
5656	Десорбер
5657	Солнечная система
5658	Холодильная система
5659	Система конди-ционирования воздуха.
5660	Газотурбинная установка
5661	Газомасляный теплообменник
5662	Биметаллическая оребренная труба
5663	Безопасный канал
5664	Подогрев топливного газа.
5665	Transformer
5666	Power consumption
5667	Load
5668	Capacity
5669	Distribution networks.
5670	Эжекторный теплообменник
5671	Контактный теплообмен
5672	Фазовый переход
5673	Вспомогательный поток
5674	Коэффициент теплового расширения.
5676	Смесь
5677	Теплообменник.
5678	Теплоемкость – Нанофлюиды – Наночастицы Al2O3 – Изопропиловый спирт – Экспери-мент – Модель прогнозирования
5679	Methane  Equation of State  Sublimation Line  Thermal Expansion Coefficient  Heat Capacity
5680	Cмесь – Температура – Плотность – Вязкость – Смазочное масло – Хладагент
5681	Микроволновая сушка – Влагосодержание – Температура – Полезный тепловой поток – Ско-рость сушки
5682	Перенос тепла Капіляр Ультразвукова кавітація  Фазове перетворення пара-рідина.
5683	переход теплового потока – слой – фундаментальная система – эволюционная система.
5684	Тепломасообмін – Аморфна структура – Інокулятор – Теплопровідність  – Математична мо-дель – Охолодження – Плавлення
5685	АХП – Дефлегматор – Энергетическая эффективность – САУ – Объект управления – Автомати-зированный эксперимент – Статические и динамические характеристики.
5686	Cолнечный коллектор - Угол наклона - Максимальное количество переданной потребителю теп-лоты
5687	тепло-массообменный аппарат – псевдоожиженный слой насадки – испарительный охладитель – градирня – охладитель воздуха непрямого типа – абсорбер – десорбер – солнечная система  – холодильная система – система кондиционирование воздуха
5688	Stirling gas refrigerating machine – Rotary-vane machine – Conversion mechanism – Mass and size characteristics
5689	каскадная холодильная машина – R744 – надкритический цикл – объемные и энергетические хара-ктеристики машины
5690	Моделювання – Рефрижераторний контейнер – Холодильна установка – Випарник – Примусова конвекція – Поле температур
\.


--
-- TOC entry 2951 (class 0 OID 16888)
-- Dependencies: 205
-- Data for Name: publications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.publications (id_publication, type, abstract, date, id_rating, doi, title, id_journal) FROM stdin;
0	Стаття	Unknown	1970-01-01	0	Unknown	Unknown	0
18	Стаття	В статті розглядаються результати праці над грантовим проектом ЄС № 83263440 «Розвиток українсько-молдавського транскордонного виробничо-науково-освітнього кластера з переробки вторинних продуктів виноробства». Роботи направлені на зниження собіварто	2018-12-24	18	https://doi.org/10.15673/atbp.v10i4.1227	АВТОМАТИЗАЦІЯ ПРОЦЕСІВ ПЕРЕРОБКИ ВТОРИННОЇ СИРОВИНИ ВИНОРОБСТВА	1
2	Стаття	В работе описана новая программа для автоматизации обработки данных мониторинга, моделирования и прогнозирования атмосферного загрязнения. Предложена модель системы мониторинга атмосферного загрязнения, которая позволяет выразить зависимость концент	2019-04-26	2	https://doi.org/10.15673/atbp.v11i1.1330	АВТОМАТИЗАЦИЯ МОДЕЛИРОВАНИЯ И ПРОГНОЗИРОВАНИЯ АТМОСФЕРНОГО ЗАГРЯЗНЕНИЯ	1
3	Стаття	Зменшення витрат усіх видів палив може значно поліпшити екологічну ситуацію за рахунок зменшення викиду в атмосферу забруднюючих і токсичних продуктів згоряння палива і зменшення споживання кисню з повітря. Це, в свою чергу, повинно зменшити економі	2019-04-26	3	https://doi.org/10.15673/atbp.v11i1.1329	Модифікатор важких паливних сумішів	1
4	Стаття	Розглянуто схему системи автоматичного керування з двоканальним нечітким контролером при регулюванні технологічних параметрів в умовах нестаціонарності динамічних характеристик об’єкта керування. Актуальність даного дослідження полягає у використанн	2019-04-26	4	https://doi.org/10.15673/atbp.v11i1.1328	Двоканальний нечіткий контролер для регулювання технологічних параметрів в умовах нестаціонарності динамічних характеристик об’єкта керування	1
5	Стаття	У статті розглянуто актуальність і необхідність застосування систем, що дозволяють утилізувати тепло пароповітряних сумішей як енергетичних відходів. Розглянуто різні варіанти утилізації на прикладі газових котлів, як джерела великої кількості енерг	2019-04-26	5	https://doi.org/10.15673/atbp.v11i1.1327	Дослідження процесів утилізації тепла пароповітряних сумішей: результати експериментів, структурна та параметрична ідентифікація основних каналів об’єкту	1
54	Стаття	For microclimate control systems is proposed a control algorithm based on maintaining the desired discomfort index using a fuzzy logic controller. To assess the influence of the environment on humans, it is necessary to determine not only the quantit	2018-02-05	54	https://doi.org/10.15673/atbp.v10i4.824	FUZZY-КОНТРОЛЕР ПІДТРИМАННЯ МІКРОКЛІМАТУ В ПРИМІЩЕННІ ЗА ЗНАЧЕННЯМИ ІНДЕКСУ ДИСКОМФОРТУ	1
6	Стаття	В статье представлены результаты исследования влияния увеличения мощности используемого ансамбля таймерных сигнальных конструкций при постоянной длительности кодовых конструкций на скорость передачи информации в цифровых системах связи. Обоснована ц	2019-04-26	6	https://doi.org/10.15673/atbp.v11i1.1326	АНАЛИЗ ВЛИЯНИЯ УВЕЛИЧЕНИЯ МОЩНОСТИ ИСПОЛЬЗУЕМОГО АНСАМБЛЯ ТАЙМЕРНЫХ СИГНАЛЬНЫХ КОНСТРУКЦИЙ ПРИ ПОСТОЯННОЙ ДЛИТЕЛЬНОСТИ КОДОВЫХ КОНСТРУКЦИЙ НА СКОРОСТЬ ПЕРЕДАЧИ ИНФОРМАЦИИ В ЦИФРОВЫХ СИСТЕМАХ СВЯЗИ	1
7	Стаття	Використання сучасних технічних засобів не вирішують проблему складності розв’язання систем нелінійних, а іноді і нестаціонарних диференціальних рівнянь у частинних похідних, які описують технологічні об’єкти з розподіленими параметрами. Один з варі	2019-04-26	7	https://doi.org/10.15673/atbp.v11i1.1325	Параметрична ідентифікація прогнозувальної моделі у системі керування об’єктів з розподіленими параметрами	1
8	Стаття	Розглянуто стрічкові транспортери у складі вантажної системи балкара. Визначено причини відмов вантажного обладнання і їх позапланового ремонту. Наведено економічні складові технічного використання транспортерів і виявлені сучасні проблеми в їх експ	2019-04-26	8	https://doi.org/10.15673/atbp.v11i1.1324	Проблеми технічної експлуатації суднових стрічкових транспортерів	1
9	Стаття	Traditional automatic control systems do not solve the task of limiting the harmful effects of technical objects on the environment. The problem is to increase the effectiveness of means of its protection against the harmful effects of industry. Rel	2019-04-26	9	https://doi.org/10.15673/atbp.v11i1.1322	Technical objects' ecological efficiency indicators control	1
10	Стаття	Розглянуті відомі конструкції роликових опор стрічкових транспортерів, як елементу вантажної системи судна. Визначені недоліки та шляхи вдосконалення. Запропоновано нове схемотехнічне рішення роликової опори.	2018-12-24	10	https://doi.org/10.15673/atbp.v10i4.1237	РОЛИКОВИЙ ВУЗОЛ СТРІЧКОВОГО  ТРАНСПОРТЕРА	1
111	Стаття	We consider business process automation publishing scientific journals. It describes the focal point of publishing houses Odessa National Academy of Food Technology and the automation of business processes. A complex business process models publishin	2017-06-12	111	https://doi.org/10.15673/atbp.v9i1.503	IMPROVEMENT OF AIS FOR CONTROL OF THE BUSINESS PROCESS OF PUBLISHING SCIENTIFIC JOURNALS	1
11	Стаття	В статье описывается использование нечеткой логики для решения задач искусственного интеллекта в играх. Представлены основные проблемы в создании искусственного интеллекта, а также основные методы реализации искусственного интеллекта в играх. Основно	2018-12-24	11	https://doi.org/10.15673/atbp.v10i4.1236	ИССЛЕДОВАНИЕ ИСПОЛЬЗОВАНИЯ НЕЧЕТКОЙ ЛОГИКИ ДЛЯ ИСКУССТВЕННОГО ИНТЕЛЛЕКТА В ИГРАХ	1
12	Стаття	The article deals with the issues of technology and methodology for the automation of the process of searching for and developing new ways of using modern computer modeling technologies and modern computing methods, and then developing software for t	2018-12-24	12	https://doi.org/10.15673/atbp.v10i4.1235	RESEARCH AND ANALYSIS THE DISPLAY METHODS FOR ALGORITHMS IN COMPUTING TASKS ON THE STRUCTURE OF COMPUTER SYSTEMS	1
13	Стаття	Показана актуальность проблемы повышения качества работы ионно-плазменных установок. Одной из важных задач для таких установок является разработка эффективного компьютерного интерфейса их систем автоматизации. Приведены недостатки имеющихся интерфейс	2018-12-24	13	https://doi.org/10.15673/atbp.v10i4.1234	РАЗРАБОТКА ИНТЕРФЕЙСА ОПЕРАТОРА КОМПЬЮТЕРНОЙ СИСТЕМЫ АВТОМАТИЗАЦИИ УСТАНОВКИ ИОННО-ПЛАЗМЕННОГО НАПЫЛЕНИЯ	1
14	Стаття	Процесс управления синхронизацией генераторов является одним из наиболее сложных процессов в судовых электроэнергетических установках. Разработке методов абстрактного и структурного синтеза устройств автоматической синхронизации с применением послед	2018-12-24	14	https://doi.org/10.15673/atbp.v10i4.1233	ОПТИМИЗАЦИЯ ПРОЦЕССА АВТОМАТИЧЕСКОЙ СИНХРОНИЗАЦИИ СУДОВЫХ ДИЗЕЛЬ-ГЕНЕРАТОРОВ ПРИ ДЕТЕРМИНИРОВАННОЙ ПОСТАНОВКЕ ЗАДАЧИ	1
15	Стаття	Компания S-engineering входящая в холдинг SE Group International занимает лидирующие позиции в области автоматизации технологических процессов зерноперерабатывающей отрасли включая в свои проекты инновационные разработки. В частности компания занимае	2018-12-24	15	https://doi.org/10.15673/atbp.v10i4.1232	ИДЕНТИФИКАЦИЯ МОДЕЛЕЙ ИСТЕЧЕНИЯ ЗЕРНА ИЗ ПОДСИЛОСНЫХ ЗАДВИЖЕК ДЛЯ АСОЗ ПТЛ ПЕРЕГРУЗКИ ЗЕРНА	1
16	Стаття	В работе рассматривается синтез системы автоматического управления нагревом теста в процессе приготовления пельменной продукции сложной труднореализуемой кубической формы. Так как, в процессе производства продукта необходимо поддерживать заданную пол	2018-12-24	16	https://doi.org/10.15673/atbp.v10i4.1231	СИНТЕЗ СИСТЕМЫ АВТОМАТИЧЕСКОГО УПРАВЛЕНИЯ РОБОТОТЕХНИЧЕСКИМ УСТРОЙСТВОМ ДЛЯ ПРИГОТОВЛЕНИЯ ПОЛУФАБРИКАТОВ ПЕЛЬМЕННОЙ ПРОДУКЦИИ ОСОБЫХ ФОРМ	1
17	Стаття	The operation of technical objects is subject to the regulatory conditions established by their manufacturer. Regime of regulatory conditions keeping needs to be controlled. A new technical object at the time of commissioning has an initial, maximum	2018-12-24	17	https://doi.org/10.15673/atbp.v10i4.1228	FEATURES OF THE TECHNICAL OBJECTS CONTROL WITH REGISTRATION THEIR WEAR-OUT	1
19	Стаття	Авторами наведенні результати експериментальних досліджень процесів гранулоутворення складних гетерогенних систем для одержання гуміно-мінеральних композитів з пошаровою структурою. При застосуванні оригінальної конструкції відцентрового механічного	2018-12-24	19	https://doi.org/10.15673/atbp.v10i4.1226	МАТЕМАТИЧНЕ МОДЕЛЮВАННЯ  ТЕМПЕРАТУРНОГО ПОЛЯ В АПАРАТІ З  ПСЕВДОЗРІДЖЕНИМ ШАРОМ	1
20	Стаття	В статье представлены результаты исследования влияния увеличения мощности используемого ансамбля таймерных сигнальных конструкций при постоянной длительности кодовых конструкций на скорость передачи информации в цифровых системах связи. Обоснована це	2018-12-24	20	https://doi.org/10.15673/atbp.v10i4.1225	АНАЛИЗ ВЛИЯНИЯ УВЕЛИЧЕНИЯ МОЩНОСТИ ИСПОЛЬЗУЕМОГО АНСАМБЛЯ ТАЙМЕРНЫХ СИГНАЛЬНЫХ КОНСТРУКЦИЙ ПРИ ПОСТОЯННОЙ ДЛИТЕЛЬНОСТИ КОДОВЫХ КОНСТРУКЦИЙ НА СКОРОСТЬ ПЕРЕДАЧИ ИНФОРМАЦИИ В ЦИФРОВЫХ СИСТЕМАХ СВЯЗИ	1
21	Стаття	С давних лет писатели фантасты в своих произведениях создавали многоцелевые машины, выполняющие задачи вместе с людьми, либо за них. Позднее чешским писателем Карелом Чапеком и его братом Йозефом было придумано слово робот и впервые использовано в п	2018-11-14	21	https://doi.org/10.15673/atbp.v10i3.1092	ЭВОЛЮЦИЯ ЧЕЛОВЕКОПОДОБНЫХ РОБОТИЗИРОВАННЫХ СИСТЕМ: ВЗГЛЯД ИЗ ПРОШЛОГО В БУДУЩЕЕ	1
22	Стаття	Mixed fodder components milling process is quite energy-consuming. Dependence of specific energy consumption on the hammer mill productivity is extremal and the minimum of this extremum drifts with changing composition and qualities of the raw mater	2018-11-14	22	https://doi.org/10.15673/atbp.v10i3.1091	HAMMER MILL LOAD CURRENT ADAPTIVE CONTROL SYSTEM TRIALS	1
61	Стаття	Two groups of the mathematical models, which describe changes in the regulated variables of closed automatic control systems as stochastic processes, are considered in the article. The first group is the informative models, obtained on the basis of a	2018-02-05	61	https://doi.org/10.15673/atbp.v10i4.820	СПЕКТРАЛЬНЫЕ ПЛОТНОСТИ РЕГУЛИРУЕМЫХ ПЕРЕМЕННЫХ ТИПОВЫХ САР И ИХ АППРОКСИМАЦИЯ МАЛОПАРАМЕТРОВЫМИ МОДЕЛЯМИ	1
23	Стаття	Авторами статті обґрунтовано фізичну модель процесу сушіння пасти діоксиду титану та досушування тонкодисперсного порошку TiO2 до залишкової вологості 0,3%, на основі якої розвинена математична модель процесу сушіння. Результатом розв’язку математич	2018-11-13	23	https://doi.org/10.15673/atbp.v10i3.1089	ЗАДАЧА ЕФЕКТИВНОГО УПРАВЛІННЯ ПРОЦЕСОМ ОТРИМАННЯ ТОНКОДИСПЕРСНОГО ПОРОШКУ ДІОКСИДУ ТИТАНУ В ХОДІ ВИХРОВОЇ СУШКИ	1
24	Стаття	Стаття присвячена енергоефективному вирощуванню ентомофагів. Об’єктом дослідження були процеси керування лабораторним виробництвом млинової вогнівки (Ephestia kuehniella), комахи-хазяїна ентомофага бракон (Habrobracon hebetor).\n&#x0d;\n\nМетою дослідж	2018-11-13	24	https://doi.org/10.15673/atbp.v10i3.1088	ІНТЕЛЕКТУАЛЬНИЙ АЛГОРИТМ КЕРУВАННЯ ДЛЯ ЕНЕРГОЕФЕКТИВНОГО ВИРОЩУВАННЯ ЕНТОМОФАГІВ	1
25	Стаття	Виробництво графітованої продукції складне, багатостадійне та дуже енергоємне. На процес графітування впливає цілий ряд факторів, та головним чинником, який визначає якість готової продукції є температурний режим обробки. Ця обставина зумовлює необх	2018-11-13	25	https://doi.org/10.15673/atbp.v10i3.1087	ДОСЛІДЖЕННЯ ТЕМПЕРАТУРНИХ ПОЛІВ ПРОЦЕСУ ГРАФІТУВАННЯ ВУГЛЕЦЕВИХ ВИРОБІВ	1
26	Стаття	Рассмотрен вопрос об оптимальном управлении уровнем взрывоопасности потенциально взрывоопасного объекта. Задача поставлена математически в общем виде и решена для одного частного случая (в этом случае уровень взрывоопасности объекта полностью опреде	2018-11-13	26	https://doi.org/10.15673/atbp.v10i3.1086	ЗАДАЧА ОПТИМАЛЬНОГО УПРАВЛЕНИЯ УРОВНЕМ ВЗРЫВООПАСНОСТИ ПОТЕНЦИАЛЬНО ВЗРЫВООПАСНОГО ОБЪЕКТА	1
27	Стаття	Процес вистоювання тістових заготовок складається з багатьох фізико-механічних та біохімічних процесів, що ускладнює управління та отримання оптимальних показників якості на виході готового продукту. Велика кількість регульованих змінних та інформац	2018-11-13	27	https://doi.org/10.15673/atbp.v10i3.1085	ПРОЦЕС ВИСТОЮВАННЯ ТІСТОВИХ ЗАГОТОВОК ЯК ОБЄ’КТ УПРАВЛІННЯ	1
28	Стаття	Решена актуальная задача редукции размеченных выборок данных большого размера путем извлечения подвыборок меньшего размера для построения диагностических и распознающих моделей по прецедентам.\n&#x0d;\n\nПредложен детерминированный метод редукции разме	2018-11-13	28	https://doi.org/10.15673/atbp.v10i3.1084	АДАПТИВНЫЙ МЕТОД РЕДУКЦИИ РАЗМЕЧЕННЫХ ВЫБОРОК ДАННЫХ ДЛЯ ПОСТРОЕНИЯ ДИАГНОСТИЧЕСКИХ МОДЕЛЕЙ	1
29	Стаття	Розглядаються технічні рішення з розробки інформаційно-керуючої системи турбінного цеху, яка,\n&#x0d;\n\nсумісно з раніше розробленої інформаційної системи котельного відділення, є складовою частиною системи\n&#x0d;\n\nкерування теплової електростанції цу	2018-11-13	29	https://doi.org/10.15673/atbp.v10i3.1083	ІНФОРМАЦІЙНА СИСТЕМА ТУРБІННОГО ЦЕХУ У СКЛАДІ СИСТЕМИ КЕРУВАННЯ ТЕПЛОВОЇ ЕЛЕКТРОСТАНЦІЇ ЦУКРОВОГО ЗАВОДУ	1
30	Стаття	Робота присвячена вирішенню задачі підвищення якості продуктів виноробства за рахунок розробки мікроконтролерного пристрою для визначення стиглості винограду та побудови алгоритму його роботи. Представлена розробка є одним з варіантів елементу Інтерн	2018-07-17	30	https://doi.org/10.15673/atbp.v10i2.977	РОЗРОБКА АЛГОРИТМУ РОБОТИ МІКРОКОНТРОЛЕРНОГО ПРИСТРОЮ ДЛЯ ВИЗНАЧЕННЯ СТИГЛОСТІ ВИНОГРАДУ	1
31	Стаття	У статті показана можливість застосування у сучасних системах стабілізації курсу морського судна принципів частково-інваріантного керування до вітро-хвильових навантажень. Метою статті є встановлення можливостей підвищення точності стабілізації судна	2018-07-17	31	https://doi.org/10.15673/atbp.v10i2.980	СИСТЕМА СТАБІЛІЗАЦІЇ КУРСУ МОРСЬКОГО СУДНА, ЧАСТКОВО-ІНВАРІАНТНА ДО ВІТРО–ХВИЛЬОВИХ НАВАНТАЖЕНЬ	1
32	Стаття	An effective solution to the tasks of preserving and accessing electronic documentation requires software applications, namely an electronic archive within the information management system of the organization. The information management system is a	2018-07-17	32	https://doi.org/10.15673/atbp.v10i2.979	Implementation of a standardized information management system into activity of scientific and technical library	1
33	Стаття	Динаміка розвитку сучасного суспільства ставить перед викладачем непросте завдання викладу навчального матеріалу таким чином, щоб студенти за короткі терміни могли засвоювати максимально можливу кількість знань разом з набуттям навичок їх творчого за	2018-07-17	33	https://doi.org/10.15673/atbp.v10i2.978	ВИКОРИСТАННЯ СУЧАСНИХ ТЕХНОЛОГІЙ У ВИКЛАДАННІ ТЕХНІЧНИХ ДИСЦИПЛІН	1
77	Стаття	In recent years become a popular healthy lifestyle. Sport is an activity that serves the public interest by implementing educational, preparatory and communicative function, but not a constant specialty (profession) person. The development of current	2017-09-19	77	https://doi.org/10.15673/atbp.v8i4.585	THE AUTOMATION SYSTEM OF ACCOUNTING SPORTING ACTIVITIES	1
34	Стаття	Рассмотрена проблема определения кратчайшего пути во взвешенном ориентированном графе с применением электрической модели с идеальными диодами, источниками напряжения и тока. Проведены теоретические исследования в области математического моделирования	2018-07-17	34	https://doi.org/10.15673/atbp.v10i2.976	Электрическая модель с идеальными элементами для поиска кратчайшего пути на взвешенном ориентированном графе	1
35	Стаття	Веб-технології постійно розвиваються, відкриваються нові можливості створення сценарію іншими підходами. Веб-додаток можна розробляти як самостійно – fullstack, або по частинах – frontend (клієнтська частина) та backend (серверна частина) [1]. Клієнт	2018-07-17	35	https://doi.org/10.15673/atbp.v10i2.974	АРХІТЕКТУРА КЛІЄНТ-СЕРВЕР на основі додатка відділу аспірантури та докторантури ОНАХТ	1
36	Стаття	Not a few devices of food production work periodically and programmers are widely used to control these devices. Using logical devices that transfer between program sections can significantly improve the quality of control, but these methods are not	2018-07-17	36	https://doi.org/10.15673/atbp.v10i2.975	RESEARCH OF THE PROGRAMMERS FOR CONTROL OF THE PERIODIC ACTION OBJECTS WITH  NON-LINEAR TIME PROGRAM	1
37	Стаття	Наведено класифікацію механізмів паралельної кінематичної структури на основі платформи Стюарта (гексапод) за видами робіт, що виконуються. Це оброблювальні центри (верстати), координаційно-вимірювальні центри, вібраційні платформи (стенди для випроб	2018-07-17	37	https://doi.org/10.15673/atbp.v10i2.973	КЛАСИФІКАЦІЯ ЗАВДАНЬ І ПРИНЦИПІВ УПРАВЛІННЯ МЕХАНІЗМОМ ПАРАЛЕЛЬНОЇ КІНЕМАТИЧНОЇ СТРУКТУРИ ДЛЯ ВИРІШЕННЯ РІЗНИХ ЗАВДАНЬ	1
38	Стаття	Applications that provide online services are becoming more popular every day and a part of desktop apps respectively decrease. The search of information, processing documents, creating images and even user games find their place on the Internet. All	2018-07-17	38	https://doi.org/10.15673/atbp.v10i2.971	OVERVIEW OF PROBLEMS IN TEXT-DATA PROCESSING AND CREATING A CLIENT-SERVER APPLICATION DEVOTED TO REFERENCES MANAGERS	1
39	Стаття	У статті розглянуті деякі шляхи підвищення енергоефективності виробництва. Обґрунтовано актуальність і необхідність застосування систем, що дозволяють утилізувати тепло пароповітряних сумішей як енергетичних відходів. Розглянуто різні варіанти утиліз	2018-07-17	39	https://doi.org/10.15673/atbp.v10i2.981	ДОСЛІДЖЕННЯ ПРОЦЕСІВ УТИЛІЗАЦІЇ ТЕПЛА ПАРОПОВІТРЯНИХ СУМІШЕЙ: ЛАБОРАТОРНА УСТАНОВКА, ВИМІРЮВАНІ ЗМІННІ, АВТОМАТИЗАЦІЯ ЕКСПЕРИМЕНТІВ	1
40	Стаття	Розглядаються технічні рішення з модернізації структури комплексу технічних засобів керуючої системи випарної станції цукрового заводу. Система керування побудована як автоматизоване робоче місце (АРМ) оператора на базі комп’ютера, мережі мікропроцес	2018-07-17	40	https://doi.org/10.15673/atbp.v10i2.972	МОДЕРНІЗАЦІЯ СТРУКТУРИ СИСТЕМИ КЕРУВАННЯ ВИПАРНОЇ СТАНЦІЇ БУРЯКОЦУКРОВОГО ЗАВОДУ НА БАЗІ МІКРОПРОЦЕСОРНИХ ТЕХНІЧНИХ ЗАСОБІВ І ПРОГРАМ УКРАЇНСЬКОГО ВИРОБНИЦТВА	1
55	Стаття	There were analyzed reactions of the human body under the influence of infrared radiation of a different spectral range as applied to the development of an automatic control system with biological feedback. It was shown that the informative heat tran	2018-02-05	55	https://doi.org/10.15673/atbp.v10i4.823	ОПРЕДЕЛЕНИЕ ЗНАЧИМЫХ ПОКАЗАТЕЛЕЙ ПЕРВИЧНОЙ ИНФОРМАЦИИ ДЛЯ СИСТЕМЫ С БИОЛОГИЧЕСКОЙ ОБРАТНОЙ СВЯЗЬЮ	1
41	Стаття	Важливою особливістю технологічних процесів харчових виробництв є істотний вплив характеристик сировини, що переробляється, на показники якості готової продукції. Тому при виділенні об'єкта управління пропонується розглядати разом: певний етап техно	2018-04-09	41	https://doi.org/10.15673/atbp.v10i1.879	КЛАСТЕРНИЙ АНАЛІЗ ДАНИХ В АВТОМАТИЗОВАНИХ СИСТЕМАХ ПРОСТЕЖУВАНОСТІ	1
42	Стаття	Today most of desktop and mobile applications have analogues in the form of web-based applications.  With evolution of development technologies and web technologies web application increased in functionality to desktop applications. The Web applicat	2018-04-09	42	https://doi.org/10.15673/atbp.v10i1.874	THE DIFFERENCE BETWEEN DEVELOPING SINGLE PAGE APPLICATION AND TRADITIONAL WEB APPLICATION BASED ON MECHATRONICS ROBOT LABORATORY ONAFT APPLICATION	1
43	Стаття	The article discusses the issues of technology and methodology for automating the process of testing Web applications. Currently, developers and automation professionals are moving to popular developing development environments. In the process of de	2018-04-09	43	https://doi.org/10.15673/atbp.v10i1.882	RESEARCH AND ANALYSIS OF APPLICATION OF AUTOMATED TESTING IN WEB APPLICATIONS	1
44	Стаття	Рассмотрена возможность применения машинного обучения для задач классификации вредоносных запросов к веб-приложению. Рассматриваемый подход исключает использование детерминированных систем анализа (например, экспертных), и строится на применении кас	2018-04-09	44	https://doi.org/10.15673/atbp.v10i1.880	ПРИМЕНИМОСТЬ МАШИННОГО ОБУЧЕНИЯ ДЛЯ ЗАДАЧ КЛАССИФИКАЦИИ АТАК НА ВЕБ-СИСТЕМЫ. ЧАСТЬ 3	1
78	Стаття	-	2017-09-19	78	https://doi.org/10.15673/atbp.v8i4.583	АНАЛІЗ МАТЕМАТИЧНИХ МОДЕЛЕЙ АВТОКОЛИВАНЬ ПРИ ВПЛИВІ НЕКОНТРОЛЬОВАНИХ ПАРАМЕТРИЧНИХ ЗБУРЕНЬ У СИСТЕМІ	1
45	Стаття	Сучасний світ прямує в напрямку побудови гнучкого виробництва, яке передбачає задоволення потреб кожного клієнта, виготовлення якісного продукту, високоефективне використання всіх ресурсів підприємства. Під час дослідження, результати якого наведені	2018-04-09	45	https://doi.org/10.15673/atbp.v10i1.878	НА ШЛЯХУ ДО ІНДУСТРІЇ 4.0: ІНТЕГРАЦІЯ ІСНУЮЧИХ АСУТП З ХМАРНИМИ СЕРВІСАМИ	1
46	Стаття	В настоящей работе представлен определенный этап разработки интеллектуальной системы, связанной с автоматическим синтезом сетей Петри. Рассматривается определенная архитектура искусственной нейронной сети, которая положена в основу интеллектуальной	2018-04-09	46	https://doi.org/10.15673/atbp.v10i1.877	НАСТРОЙКА НЕЙРОННОЙ СЕТИ ПРИ АВТОМАТИЧЕСКОМ СИНТЕЗЕ СЕТЕЙ ПЕТРИ	1
47	Стаття	Network technology for interaction between two applications via the HTTP protocol was considered in article.When client works with REST API - it means it works with "resources", and in SOAP work is performed with operations. To build REST web servic	2018-04-09	47	https://doi.org/10.15673/atbp.v10i1.876	WEB-SERVICE. RESTFUL ARCHITECTURE	1
48	Стаття	Обґрунтовано вибір та показані переваги вентильних безконтактних двигунів постійного струму (БДПС) зі збудженням від високоенергетичних рідкісноземельних постійних магнітів при використанні їх у автоматизованих електроприводах (АЕП) автономних плавал	2018-04-09	48	https://doi.org/10.15673/atbp.v10i1.884	СПРОЩЕНА МОДЕЛЬ БЕЗКОНТАКТНОГО ВЕНТИЛЬНОГО ЕЛЕКТРОПРИВОДУ ТА ЙОГО ТЕХНІЧНА РЕАЛІЗАЦІЯ ДЛЯ АВТОНОМНОГО ПЛАВАЛЬНОГО АПАРАТА	1
49	Стаття	Проаналізовано сучасні перспективи України як зернової держави в контексті зовнішньої та внутрішньої торгівлі. Означено неефективне використання наявних потужностей зернових підприємств як основу нестачі потужностей. Обґрунтовано необхідність підвищ	2018-04-09	49	https://doi.org/10.15673/atbp.v10i1.883	МОДЕЛЮВАННЯ ДИНАМІКИ ЗАПАСІВ ЗЕРНА НА ХЛІБОПРИЙМАЛЬНОМУ ПІДПРИЄМСТВІ: КОНЦЕПТУАЛЬНА, МАТЕМАТИЧНА ТА ІМІТАЦІЙНА МОДЕЛІ	1
50	Стаття	Many objects automatic control unsteady. This is manifested in the change of their parameters. Therefore, periodically adjust the required parameters of the controller. This work is usually carried out rarely. For a long time, regulators are working	2018-04-09	50	https://doi.org/10.15673/atbp.v10i1.881	AUTOMATIC CONTROL OF PARAMETERS OF A NON-STATIONARY OBJECT WITH CROSS LINKS	1
51	Стаття	Роботу присвячено вирішенню актуального завдання створення математичного забезпечення для побудови моделей кількісних залежностей на основі багатошарових нейронних мереж та вирішенню за його допомогою практичної задачі моделювання залежностей параме	2018-04-09	51	https://doi.org/10.15673/atbp.v10i1.875	НЕЙРОМЕРЕЖЕВЕ МОДЕЛЮВАННЯ ЗАЛЕЖНОСТЕЙ РЕЗУЛЬТАТІВ ВИПРОБУВАНЬ ГАЗОТУРБІННИХ АВІАДВИГУНІВ	1
52	Стаття	Most of the currently developed systems are based on the client-server architecture. This architecture is used\neverywhere, from mobile-native development to Web applications.\nHowever implementing an application based on this architectural solution r	2018-02-05	52	https://doi.org/10.15673/atbp.v10i4.833	OVERVIEW OF POPULAR APPROACHES IN CREATING CLIENT-SERVER APPLICATIONS BASED ON SCIENTOMETRICS ONAFTS’ PLATFORM	1
53	Стаття	In this paper, the authors conducted study of a number of parameters configuring the CFD-program Flow Simulations of the CAD SolidWorks for increasing the efficiency of modelling of ultrasonic flowmeters and orifice flowmeters. According to the resul	2018-02-05	53	https://doi.org/10.15673/atbp.v10i4.827	ОСОБЛИВОСТІ НАЛАШТУВАННЯ CFD-ПРОГРАМ ДЛЯ ПІДВИЩЕННЯ ЕФЕКТИВНОСТІ МОДЕЛЮВАННЯ ВИТРАТОМІРІВ	1
56	Стаття	In the article the results of functioning in the production conditions of the automated loading optimization system (ALOS) grain of the elevator are considered. The system is designed to generate grain flow simultaneously from several sources, increa	2018-02-05	56	https://doi.org/10.15673/atbp.v10i4.822	ИССЛЕДОВАНИЕ ЭФФЕКТИВНОСТИ ФУНКЦИОНИРОВАНИЯ АСОЗ ПТЛ НА МОРСКОМ ЗЕРНОВОМ ТЕРМИНАЛЕ В Г. НИКОЛАЕВЕ	1
57	Стаття	The article deals with the use of unmanned aerial vehicles as in industry in general and as in individual branches. The operation of unmanned aerial vehicles in the agricultural sector is described in more detail. The problems existing for today in t	2018-02-05	57	https://doi.org/10.15673/atbp.v10i4.821	СИСТЕМА АВТОМАТИЧЕСКОГО УПРАВЛЕНИЯ БЕСПИЛОТНОГО ЛЕТАТЕЛЬНОГО АППАРАТА	1
58	Стаття	The relevance of the development of industrial human-machine interfaces is shown, since 35-58% of errors of process operators are associated with their incorrect organization. The development of a HMI for the associated petroleum gas processing techn	2018-02-05	58	https://doi.org/10.15673/atbp.v10i4.819	РАЗРАБОТКА СОВРЕМЕННОГО ЧЕЛОВЕКОМАШИННОГО ИНТЕРФЕЙСА В АСУТП НА ОСНОВЕ МЕЖДУНАРОДНЫХ СТАНДАРТОВ	1
59	Стаття	In the article simulation modeling of conveyor weight meters of continuous batchers in MATLAB \\ Simulink environment is considered. Such batchers are certified by metrological services as measuring devices. It requires an accurate reflection of the s	2018-02-05	59	https://doi.org/10.15673/atbp.v10i4.826	ІМІТАЦІЙНА МАТЕМАТИЧНА МОДЕЛЬ КОНВЕЄРНИХ ВАГОВИМІРЮВАЧІВ ДОЗАТОРІВ БЕЗПЕРЕРВНОЇ ДІЇ	1
60	Стаття	The article describes a multi-agent system based on the OWL ontology, taking into account the FIPA standards for the object security system. The given data on the work of intellectual agents and communication between them, as well as proposals for so	2018-02-05	60	https://doi.org/10.15673/atbp.v10i4.825	РОЗРОБКА ТА ДОСЛІДЖЕННЯ МУЛЬТИАГЕНТНОЇ СИСТЕМИ ДЛЯ ОХОРОНИ ОБ’ЄКТА	1
62	Стаття	The study analyzed the heating system and hot water supply with  using renewable energy sources. To design an automatic control system for heating and hot water supply, which includes a solar collector, a heat pump and a centralized heating source, t	2018-02-05	62	https://doi.org/10.15673/atbp.v10i4.818	РАЗРАБОТКА АЛГОРИТМА УПРАВЛЕНИЯ СИСТЕМОЙ ОТОПЛЕНИЯ И ГОРЯЧЕГО ВОДОСНАБЖЕНИЯ С ИСПОЛЬЗОВАНИЕМ ВОЗОБНОВЛЯЕМЫХ ИСТОЧНИКОВ ЭНЕРГИИ	1
63	Стаття	The current state of worn industrial equipment and the resulting low performance indicators of its functioning, in particular, low environmental friendliness, are considered. It is shown that the normalization of the complex situation that has develo	2018-02-05	63	https://doi.org/10.15673/atbp.v10i4.815	INCREASING  OF  ECOLOGICAL  EFFICIENCY OF WORN EQUIPMENT BY PARTIAL UPDATES. ANALYTICAL AND CONTROL ASPECT	1
64	Стаття	Currently methods of efficiency analysis are being developed and applied, based on optimization tasks for various types and modes. Usually, the optimization criterion for these objectives is efficiency that can be calculated in various ways, for whic	2018-02-05	64	https://doi.org/10.15673/atbp.v10i4.814	ANALYSIS OF THE ENERGY SYSTEM BALANCE EFFICIENCY PROVIDED WITH THE DIFFERENT GROUPS OF GENERATING PLANTS	1
65	Стаття	Розглянуто основні напрямки та перспективи наукового розвитку інженерної механіки, автоматизації\nта комп’ютерних наук в їх взаємозв’язку. Показано як світові тенденції знаходять своє відображення в історії\nОдеської національної академії харчових тех	2017-11-26	65	https://doi.org/10.15673/atbp.v9i3.723	ОСНОВНІ НАПРЯМКИ ТА ПЕРСПЕКТИВИ НАУКОВОГО РОЗВИТКУ ИНЖЕНЕРНОЇ МЕХАНІКИ, АВТОМАТИЗАЦІЇ ТА КОМП’ЮТЕРНИХ НАУК В ОДЕСЬКІЙ НАЦІОНАЛЬНІЙ АКАДЕМІЇ ХАРЧОВИХ ТЕХНОЛОГІЙ	1
66	Стаття	The article is concerned with the increasing importance of computer technologies and the need to educate\nan engineer at the level of modern advances in science and technology. New methods and technologies of learning based on the training of competi	2017-11-26	66	https://doi.org/10.15673/atbp.v9i3.722	VOCATIONAL TRAINING OF COMPETITIVE ENGINEERS THROUGH THE USE OF COMPUTER TECHNOLOGIES	1
67	Стаття	В статті розглянуто створення системи понять, що формують парадигму реінжинірингу інформаційних технологій, який необхідний у випадку їх еволюційного розвитку. Лінгвістичне забезпечення \n\nінформаційних технологій розглядає побудову програмної систем	2017-11-26	67	https://doi.org/10.15673/atbp.v9i3.720	ПАРАДИГМА ПОДАННЯ ЛІНГВІСТИЧНОГО ЗАБЕЗПЕЧЕННЯ ЗА ДОПОМОГОЮ ПОРОДЖУВАЛЬНИХ ГРАМАТИК	1
68	Стаття	The article is devoted to mobile robots. Mobile robots are devices that can move autonomously to accomplish\ntheir goals. As the title implies the article describes traffic guidance systems for the mobile robots. A generalized scheme of the\nmobile ro	2017-11-26	68	https://doi.org/10.15673/atbp.v9i3.718	FEATURES OF THE MOBILE ROBOTS CONTROL SYSTEMS	1
69	Стаття	Developing a proper system architecture is a critical factor for the success of the project. After the analysis\nphase is complete, system design begins. For an effective solution developing it is very important that it will be flexible and\nscalable.	2017-11-26	69	https://doi.org/10.15673/atbp.v9i3.714	AN ARCHITECTURAL APPROACH FOR QUALITY IMPROVING OF ANDROID APPLICATIONS DEVELOPMENT WHICH IMPLEMENTED TO COMMUNICATION APPLICATION FOR MECHATRONICS ROBOT LABORATORY ONAFT	1
70	Стаття	The possibility of applying machine learning for the classification of malicious requests to a\nWeb application is considered. This approach excludes the use of deterministic analysis systems (for example, expert systems),\nand is based on the applica	2017-11-26	70	https://doi.org/10.15673/atbp.v9i3.713	MACHINE LEARNING IMPLEMENTATION FOR THE CLASSIFICATION OF ATTACKS ON WEB SYSTEMS. PART 2	1
71	Стаття	Практика показує, що у логістичному ланцюгу руху зерна від виробника до споживача задіяно, у\nсередньому, три – чотири елеватори різного призначення та обсягу збереження. На елеваторах, у ході процесів\nприймання, підробітки та відвантаження, зерно пе	2017-11-26	71	https://doi.org/10.15673/atbp.v9i3.721	ОПТИМІЗАЦІЯ ЗАВАНТАЖЕННЯ ПТЛ ЕЛЕВАТОРІВ ЗЕРНОМ: ФОРМАЛІЗАЦІЯ ТА ПІДВИЩЕННЯ ЕФЕКТИВНОСТІ АЛГОРИТМУ КЕРУВАННЯ	1
72	Стаття	Рассмотрен синтез поисковой процедуры для оптимизации распределения нагрузки между параллельно работающими котлами в режиме реального времени. Предложен критерий оптимальности работы котла, учитывающий не только коэффициент полезного действия, но и	2017-11-26	72	https://doi.org/10.15673/atbp.v9i3.719	АВТОМАТИЗАЦИЯ РАСПРЕДЕЛЕНИЯ НАГРУЗКИ МЕЖДУ ПАРАЛЛЕЛЬНО РАБОТАЮЩИМИ КОТЛАМИ	1
73	Стаття	The results of laboratory and industrial researches made it possible to propose efficiency improvement method\nfor sugar plant boiler department work. As a partial work efficiency criterion for each boiler unit, its efficiency factor is\nconsidered. I	2017-11-26	73	https://doi.org/10.15673/atbp.v9i3.717	EFFICIENCY IMPROVEMENT FOR SUGAR PLANT BOILER DEPARTMENT WORK BASED ON BOILER UNITS OPTIMAL LOADS DISTRIBUTION	1
74	Стаття	The most part of the operating technological equipment in Ukraine has spent the estimated resource of working\ncapacity, has passed in a limiting condition, therefore works with low technological indicators of efficiency of functioning of a\ntechnical	2017-11-26	74	https://doi.org/10.15673/atbp.v9i3.716	WAYS OF EFFICIENCY IMPROVING OF MODERN PRODUCTION	1
75	Стаття	The main part of heating systems and domestic hot water systems are based on the natural gas boilers. For\nincreasing the overall performance of such heating system the condensation gas boilers was developed and are used. However\neven such type of bo	2017-11-26	75	https://doi.org/10.15673/atbp.v9i3.715	THE MODEL FOR POWER EFFICIENCY ASSESSMENT OF CONDENSATION HEATING INSTALLATIONS	1
76	Стаття	The focus of this article has been about automated testing in practice. Using testing tools is quite common phenomenon in software companies. The article studied the use of software testing tools. Testing software is enough ordinary things in the IT	2017-09-19	76	https://doi.org/10.15673/atbp.v8i4.586	INVESTIGATION AND ANALYSIS OF AUTOMATIC TESTING SYSTEMS OF APPLICATIONS	1
79	Стаття	This article considers the main methods of the description and creation of charts of business processes. The main methods are the notation of BPMN, languages of the description of BPEL and UML, methodologies of IDEF and ARIS. In article the main char	2017-09-19	79	https://doi.org/10.15673/atbp.v8i4.581	ФОРМАЛЬНІ МЕТОДИ ПОБУДОВИ ДІАГРАМ ЛОГІСТИЧНИХ БІЗНЕС-ПРОЦЕСІВ	1
80	Стаття	In the structure of automatic regulators are still widely used astatic electrical constant speed actuators. An alternative solution is the use of electrical constant speed actuators, but the proportional action. The comparative evaluation of the both	2017-09-19	80	https://doi.org/10.15673/atbp.v8i4.580	A WORD IN DEFENSE OF THE DISCRETE CONTROL SIGNAL	1
81	Стаття	This article discusses the example of model-oriented method of design and development of digital low-pass filters (LPF) for automatic control systems (ACS). Typically, high frequency noise and disturbance attenuation is carried out by analogue LPF. H	2017-09-19	81	https://doi.org/10.15673/atbp.v8i4.579	MODEL-ORIENTED METHOD OF DESIGN IMPLEMENTATION WHEN CREATING DIGITAL FILTERS	1
82	Стаття	dependencies that could be used to obtain linear characteristic of frequency response control are defined. The possibility of such control is shown.	2017-09-19	82	https://doi.org/10.15673/atbp.v8i4.577	ЛИНЕАРИЗАЦИЯ В ЗАДАЧЕ УПРАВЛЕНИЯ ХАРАКТЕРИСТИКОЙ ЦИФРОВОГО ФИЛЬТРА ДЛЯ СПЕЦИАЛИЗИРОВАННОЙ КОМПЬЮТЕРНОЙ СИСТЕМЫ	1
83	Стаття	The general concept of the automatic control systems constructing for increasing the efficiency of the artificial cold production process in the absorption refrigerating units is substantiated. The described automatic control systems provides necessa	2017-09-19	83	https://doi.org/10.15673/atbp.v8i4.584	DETERMINING THE TRANSIENT PROCESS TIME BY THE EXAMPLE OF BODIES HEATING USING A MODIFIED HOMOCHRONICITY NUMBER	1
84	Стаття	The paper formulated optimization problem formulation production of carbon products. The analysis of technical and economic parameters that can be used to optimize the production of carbonaceous products had been done by the author. To evaluate the e	2017-09-19	84	https://doi.org/10.15673/atbp.v8i4.582	IMPROVEMENT OF MANAGEMENT OF STEAM GENERATORS IN NUCLEAR AND THERMAL POWER PLANTS	1
85	Стаття	The control system providing the movement of the gripper of the robot manipulator along the predetermined trajectory is considered in this article. This control system is coordinated. The system provides a concerted change of the control variables un	2017-09-19	85	https://doi.org/10.15673/atbp.v8i4.578	КООРДИНИРУЮЩАЯ СИСТЕМА АВТОМАТИЧЕСКОГО УПРАВЛЕНИЯ ПРИВОДАМИ РОБОТА-МАНИПУЛЯТОРА	1
86	Стаття	The general concept of the automatic control systems constructing for increasing the efficiency of the artificial cold production process in the absorption refrigerating units is substantiated. The described automatic control systems provides necessa	2017-09-19	86	https://doi.org/10.15673/atbp.v8i4.576	CONCEPT OF AUTOMATIC CONTROL SYSTEM FOR IMPROVING THE EFFICIENCY OF THE ABSORPTION REFRIGERATING UNITS	1
103	Стаття	It has been proposed the application of an optimization criterion based on properties of target functions, taken from the elements of technical, economic and thermodynamic analyses. Marginal costs indicators of energy for different energy products h	2017-08-14	103	https://doi.org/10.15673/atbp.v9i2.559	DEVELOPMENT OF THE METHOD OF DETERMINING THE  TARGET FUNCTION OF OPTIMIZATION OF POWER  PLANT	1
87	Стаття	В статті представлено опис та аналіз існуючих методів експертної оцінки ревалентності відповідей автоматизованої діалогової системи, наведено переваги та недоліки кожного з них, а також обґрунтовано метод, що найбільше підходить для оцінки ревалентно	2017-09-19	87	https://doi.org/10.15673/atbp.v8i3.574	ЕКСПЕРТНА ОЦІНКА РЕВАЛЕНТНОСТІ ВІДПОВІДЕЙ АВТОМАТИЗОВАНОЇ СИСТЕМИ ПІДТРИМКИ ДІАЛОГУ ДЛЯ ДИСТАНЦІЙНОГО НАВЧАННЯ	1
88	Стаття	There are topical issues of development of the automated system intended for assessment of level of competence of industrial enterprises divisions for planning of training actions of specialists in automation of engineering processes are determined i	2017-09-19	88	https://doi.org/10.15673/atbp.v8i3.569	TRAINING OF NUMERICAL CONTROL MACHINES OPERATORS: MODEL OF SYNTHESIS	1
89	Стаття	We consider business process automation publishing scientific journals. It describes the focal point of publishing houses Odessa National Academy of Food Technology and the automation of business processes. A complex business process models publishin	2017-09-19	89	https://doi.org/10.15673/atbp.v8i3.568	AUTOMATION OF CONTROL OF THE BUSINESS PROCESS OF PUBLISHING SCIENTIFIC JOURNALS	1
90	Стаття	Technological type control objects specific feature, which distinguish them among many mobile or electro technical types, is more low-frequency parametric disturbances spectral composition than spectral composition of coordinate disturbances. Most of	2017-09-19	90	https://doi.org/10.15673/atbp.v8i3.566	FILTERS RESEARCH FOR FREE MOTION EXTRACTION IN SELF-TUNING AUTOMATIC CONTROL SYSTEMS	1
91	Стаття	The coordinating control system by drives of the robot-manipulator is presented in this article. The purpose of the scientific work is the development and research of the new algorithms for parametric synthesis of the coordinating control systems. To	2017-09-19	91	https://doi.org/10.15673/atbp.v8i3.565	FORMATION OF THE SYNTHESIS ALGORITHMS OF THE COORDINATING CONTROL SYSTEMS BY MEANS OF THE AUTOMATIC GENERATION OF PETRI NETS	1
92	Стаття	In this paper was developed the control system of group of hot blast stoves, which operates on the basis of the packing heating control subsystem and subsystem of forecasting of modes duration in the hot blast stoves APCS of iron smelting in a blast	2017-09-19	92	https://doi.org/10.15673/atbp.v8i3.564	SITUATIONAL CONTROL OF HOT BLAST STOVES GROUP BASED ON DECISION TREE	1
93	Стаття	Quality of the automatic control is the basis of economic effect of industrial control systems. The appropriate regulator settings should be found to improve the quality of automated control systems, but improved accuracy results in the reduction of	2017-09-19	93	https://doi.org/10.15673/atbp.v8i3.575	ШВИДКИЙ АЛГОРИТМ АДАПТАЦІЇ ПІ- РЕГУЛЯТОРА	1
94	Стаття	Improving the quality of automatic control of the first stage of grinding feed ore to ore-dressing plants is constrained due to disregard of regularities the location of the material along the sand body (between turns two filar spiral) mechanical spi	2017-09-19	94	https://doi.org/10.15673/atbp.v8i3.573	МОДЕЛЮВАННЯ ЗАКОНОМІРНОСТЕЙ РОЗТАШУВАННЯ МАТЕРІАЛУ ВЗДОВЖ НИЖНЬОЇ ЧАСТИНИ ПІСКОВОГО ТІЛА МЕХАНІЧНОГО СПІРАЛЬНОГО КЛАСИФІКАТОРА	1
95	Стаття	Production of carbon electrodes characterized by considerable resource and energy consumption, so important is the task of improving the efficiency of production through the introduction of optimal modes of its component processes. Developed and stud	2017-09-19	95	https://doi.org/10.15673/atbp.v8i3.572	СПРОЩЕНА МАТЕМАТИЧНА МОДЕЛЬ ПРОЦЕСУ ГРАФІТУВАННЯ ВУГЛЕЦЕВИХ ЕЛЕКТРОДІВ	1
96	Стаття	The article deals with modern international standards ISA-95 and ISA-88 on the development of computer inegreted manufacturing. It is shown scope of standards in the context of a hierarchical model of the enterprise. Article is built in such a way to	2017-09-19	96	https://doi.org/10.15673/atbp.v8i3.571	COMPUTER INTEGRATED MANUFACTURING: OVERVIEW OF MODERN STANDARDS	1
97	Стаття	This article is devoted to the development of a new method of synthesis a regulators’ transfer functions matrix of an optimal multivariable open-loop control system. The regulator is designed to maximize an accuracy of a nonlinear multivariable contr	2017-09-19	97	https://doi.org/10.15673/atbp.v8i3.570	АНАЛИТИЧЕСКОЕ КОНСТРУИРОВАНИЕ РАЗОМКНУТЫХ СИСТЕМ СТОХАСТИЧЕСКОГО УПРАВЛЕНИЯ МНОГОМЕРНЫМ НЕЛИНЕЙНЫМ ОБЪЕКТОМ	1
98	Стаття	This article is regarded to the search for the best power control program at nuclear power plant (NPP) with VVER- 1000 by gradient descent method for the objective function, which includes the criteria of efficiency, safety and damage. Criteria norma	2017-09-19	98	https://doi.org/10.15673/atbp.v8i3.567	SEARCH FOR THE BEST POWER CONTROL PROGRAM AT NPP WITH VVER-1000 USING GRADIENT DESCENT METHOD	1
99	Стаття	The process of developing a virtual 3D simulator of the process of granulation of mixed fodders is considered. The consequences of errors in the operation of press granulator operators are considered. The difficulties associated with the training of	2017-08-14	99	https://doi.org/10.15673/atbp.v9i2.563	DEVELOPMENT OF A VIRTUAL 3D-SIMULATOR OF THE  FEED PELLETING TECHNOLOGICAL PROCESS	1
100	Стаття	The technologies of thermal treatment in vacuum are widely used in various fields of production, in particular in the food industry, but their application at farms, hotels or a for domestic purposes is limited because of the big sizes, high cost of	2017-08-14	100	https://doi.org/10.15673/atbp.v9i2.562	THE THERMOELECTRIC VACUUM CROCK-POT AND THE  AUTOMATED WORKPLACE FOR ITS RESEARCH AS A  CONTROL OBJECT	1
101	Стаття	The article describes the construction of dynamic subsystem logical and dynamic model for batch sterilizer with counter-pressure needed for the construction of programmer. To describe the dynamics of counter-pressure autoclave is used mathematical m	2017-08-14	101	https://doi.org/10.15673/atbp.v9i2.561	DYNAMICS OF CHANGES IN TEMPERATURE OF BATCH  STERILIZERS WITH BACKPRESSURE	1
102	Стаття	На сучасному етапі соціальні інтернет-сервіси перетворилися на дієвий інструмент комунікації учасників віртуальних спільнот – акторів. Також соціальні інтернет-сервіси використовуються для самоорганізації громадянського суспільства, координації з ме	2017-08-14	102	https://doi.org/10.15673/atbp.v9i2.560	МЕТОД ОЦІНЮВАННЯ ОЗНАК ЗАГРОЗ  ІНФОРМАЦІЙНІЙ БЕЗПЕЦІ ДЕРЖАВИ У СОЦІАЛЬНИХ  ІНТЕРНЕТ-СЕРВІСАХ	1
104	Стаття	Определение условной формулы газообразного углеводородного топлива основано на модельных представлениях в соответствии с законами сохранения вещества, Дальтона, химического равновесия по \nпарциальным давлениям. Определение динамических характеристик	2017-08-14	104	https://doi.org/10.15673/atbp.v9i2.558	МОДЕЛЬ И МЕТОД СЖИГАНИЯ В  ТЕПЛОЭНЕРГЕТИЧЕСКОЙ   УСТАНОВКЕ УГЛЕВОДОРОДНОГО ГАЗА  ПЕРЕМЕННОГО СОСТАВА	1
105	Стаття	При проектировании компонент специализированных компьютерных систем возникают задачи, связанные с уменьшением объема вычислений при проектировании и ускорении процесса настройки. В работе проведен анализ и получены соотношения коэффициентов передато	2017-08-14	105	https://doi.org/10.15673/atbp.v9i2.557	АНАЛИЗ ПЕРЕДАТОЧНЫХ ФУНКЦИЙ  ЦИФРОВЫХ ЧАСТОТНО-ЗАВИСИМЫХ КОМПОНЕНТ  НИЗКОГО ПОРЯДКА	1
106	Стаття	Показана актуальность разработки технологических процессов переработки попутного нефтяного газа для обеспечения энергетической независимости Украины. Основным элементом схемы переработки нефтяного газа является ректификационная колонна. Качество раз	2017-08-14	106	https://doi.org/10.15673/atbp.v9i2.556	СИНТЕЗ ДВУХУРОВНЕВОЙ СИСТЕМЫ УПРАВЛЕНИЯ РЕКТИФИКАЦИОННОЙ КОЛОННОЙ В ТЕХНОЛОГИЧЕСКОМ ПРОЦЕССЕ ПЕРЕРАБОТКИ ПОПУТНЫХ НЕФТЯНЫХ ГАЗОВ	1
107	Стаття	The modern complex state of the natural environment, caused by the harmful impact of the rapidly developing world industry on it, is considered. It is pointed out the acute urgency of the utmost reduction of the harmful effects of industry.  It is n	2017-08-14	107	https://doi.org/10.15673/atbp.v9i2.555	INCREASING THE LEVEL OF ENVIRONMENTAL  EFFICIENCY OF INDUSTRY IS THE IMPORTANT RESULT  OF ITS FUNCTIONING CONTROL	1
108	Стаття	The possibility of applying machine learning is considered for the classification of malicious requests to a Web application. This approach excludes the use of deterministic analysis systems (for example, expert systems), and based on the applicatio	2017-08-14	108	https://doi.org/10.15673/atbp.v9i2.554	MACHINE LEARNING IMPLEMENTATION FOR THE  CLASSIFICATION OF ATTACKS ON WEB SYSTEMS.  PART 1	1
109	Стаття	This study represents the improved mathematical and imitational allocated in space multi-zone model of VVER-1000 which differs from the known one. It allows to take into account the energy release of 235U nuclei fission as well as 239Pu . Moreover, t	2017-06-12	109	https://doi.org/10.15673/atbp.v9i1.505	IMPROVED MODELS AND METHOD OF POWER CHANGE OF NPP UNIT WITH VVER-1000	1
110	Стаття	Studying of technical disciplines in higher education institution as a rule consists of 2 parts – theories and practice. Practice, is a type of educational process which allows to realize theoretical knowledge to the applied sphere. In particular it	2017-06-12	110	https://doi.org/10.15673/atbp.v9i1.504	USING OF ROBOTS-MANIPULATORS IN LABORATORY WORKS IN HIGHER EDUCATION INSTITUTES	1
112	Стаття	The models of Chapman-Jouget and Zel'dovich-Neumann-Döring are considered to estimate the width of a detonation wave in gas mixtures. Improved software package was developed earlier. The calculations of stationary detonation wave width are in good ag	2017-06-12	112	https://doi.org/10.15673/atbp.v9i1.502	ESTIMATION OF THE WIDTH OF THE STATIONARY DETONATION WAVE IN THE MODEL OF ZEL'DOVICH-NEUMANN-DÖRING	1
113	Стаття	Many objects automatic control unsteady. This is manifested in the change of their parameters. Therefore, periodically adjust the required parameters of the controller. This work is usually carried out rarely. For a long time, regulators are working	2017-06-12	113	https://doi.org/10.15673/atbp.v9i1.501	AUTOMATIC REGULATOR FOR NON-STATIONARY OBJECTS WITH AN INCREASED RANGE OF NORMAL OPERATION	1
114	Стаття	Creative element fate of any activity may not fall to zero because of the turbulent environment in which these activities are carried out, always prevents this. Environment that makes each building unique, that is, provides the main basis of the proj	2017-06-12	114	https://doi.org/10.15673/atbp.v9i1.500	THE PROJECT MANAGEMENT OF INDUSTRIAL BUILDINGS REENGINEERING (RECONSTRUCTION AND COMPLETION)	1
115	Стаття	The article is concerned with the analysis of recipes of confectionary products on the basis of essential indicators of chemical composition meeting the demands of definite group of consumers (corresponding the physiological norms of feeding the diff	2017-06-12	115	https://doi.org/10.15673/atbp.v9i1.499	OPTIMIZATION OF THE COMPOSITION OF MUFFINS ON THE BASIS OF ESSENTIAL INDICATORS OF CHEMICAL COMPOUND OF THE CONFECTIONARY PRODUCT "VUPI PAI"	1
116	Стаття	On many industrial objects regulators of pressure are used. Following initial data are necessary for proper selection of a regulator and calculation of throughput: a working environment, entrance and target pressure, expense, temperature of a workin	2017-06-12	116	https://doi.org/10.15673/atbp.v9i1.498	THE INTEGRATED LAYOUT DECISIONS FOR AUTOMATIC CONTROL OF PACKING SYSTEMS	1
117	Стаття	The article discusses a new approach to upgrade the software for SCADA-systems. A distinctive feature of this method is the ability to support more than ten most popular programming languages. By applying this method it’s possible to automate the pro	2017-06-12	117	https://doi.org/10.15673/atbp.v9i1.497	MULTILINGUAL RECODING METHOD DESIGNED FOR SCADA-SYSTEM’S SOFTWARE UPGRADE	1
118	Стаття	The content, meaning and methodological possibilities of use of the developed and proposed balance of technological efficiency of operation of a technical object are considered. The methodological basis for offset in different conditions and modes of	2017-06-12	118	https://doi.org/10.15673/atbp.v9i1.496	ASSESSMENT OF THE STATE OF A TECHNICAL OBJECT USING THE BALANCE OF ITS TECHNOLOGICAL EFFICIENCY OF OPERATION	1
171	Стаття	Nowadays one of the most important questions of the financial accounting is not only accounting but\nthe analysis of debts receivable as well. The results of the analysis can influence the financial condition,\ncompetitiveness, volume and structure of	2018-10-18	171	https://doi.org/10.15673/fie.v10i3.1066	METHODS OF THE ANALYSIS OF THE DEBTS RECEIVABLE: MODERN ASPECT	2
119	Стаття	Наведено основні етапи розвитку інформаційних технологій та низькотемпературної техніки. Визначені основні функції інформаційних технологій і низькотемпературної техніки в сучасній промисловості. Окрему увагу приділено їх впливу на етапі проектування	2017-06-12	119	https://doi.org/10.15673/atbp.v9i1.495	ВПРОВАДЖЕННЯ ЗАСОБІВ ІНФОРМАЦІЙНИХ ТЕХНОЛОГІЙ В ПРОЦЕС ПРОЕКТУВАННЯ ТЕПЛООБМІННИХ АПАРАТІВ	1
120	Стаття	A functional model of the information technology for management of natural emergency situations on trunk roads has been developed on the basis of the IDEF0 notation. The functional model of the information technology for management of natural emergen	2016-08-31	120	https://doi.org/10.15673/atbp.v8i2.172	A FUNCTIONAL MODEL OF THE INFORMATION TECHNOLOGY FOR MANAGEMENT OF NATURAL EMERGENCY SITUATIONS ON TRUNK ROADS	1
121	Стаття	Results of laboratory and industrial research allowed offering a way to improve the accuracy of estimation the optimal criterion of boilers' operation depending on fuel quality. Criterion is calculated continuously during boiler operation as heat rat	2016-08-31	121	https://doi.org/10.15673/atbp.v8i2.171	INCREASING OF PRECISE ESTIMATION OF OPTIMAL CRITERIA BOILER FUNCTIONING	1
122	Стаття	Mathematical model for the possible development of the primary explosion at the grain processing enterprise is created. It is proved that only instability is possible for the combustion process. This model enables to estimate possibility of the secon	2016-08-31	122	https://doi.org/10.15673/atbp.v8i2.170	GRAPH MODELING OF THE GRAIN PROCESSING ENTERPRISE FOR SECONDARY EXPLOSION ESTIMATIONS	1
123	Стаття	The wine industry is now successfully solved the problem for the implementation of automation receiving points of grapes, crushing and pressing departments installation continuous fermentation work, blend tanks, production lines ordinary Madeira cont	2016-08-31	123	https://doi.org/10.15673/atbp.v8i2.169	AUTOMATION OF CHAMPAGNE WINES PROCESS IN SPARKLING WINE PRESSURE TANK	1
124	Стаття	In this paper proved the possibility of developing passive electronic inductive elements based replace metal wire that is wound inductor, the wire is made of electret. The relative permeability of the electret S  10 000, several orders of magnitud	2016-08-31	124	https://doi.org/10.15673/atbp.v8i2.168	EVALUATION OF INDUCTANCE WITH ELECTRICAL WIRES	1
125	Стаття	The paper formulated optimization problem formulation production of carbon products. The analysis of technical and economic parameters that can be used to optimize the production of carbonaceous products had been done by the author. To evaluate the e	2016-08-31	125	https://doi.org/10.15673/atbp.v8i2.167	STATEMENT OF THE OPTIMIZATION PROBLEM OF CARBON PRODUCTS PRODUCTION	1
126	Стаття	Non-stationary control objects, especially with varying transmission coefficient, are fairly common in practice. Creation of automatic control systems (ACS) for them is topical issue. This task of creating ACS for these kind of control objects is mor	2016-08-31	126	https://doi.org/10.15673/atbp.v8i2.166	PROBLEM TOPICALITY OF OFFSET ABSENCE ORDER INCREASE IN CONTROLLERS DURING CONTROL OF OBJECTS WITH VARYING TRANSMISSION COEFFICIENT	1
127	Стаття	Essence of process of water-supply of apartment dwelling house is considered. The existent state over of automation of the pumping stations is brought. The task of development of the effective system of automatic control is put by them. Possibility o	2016-08-31	127	https://doi.org/10.15673/atbp.v8i2.165	AUTOMATION OF THE RESIDENTIAL BUILDING WATER SUPPLY SYSTEM PUMPING STATION	1
128	Стаття	The question of implementation of the interface between the DCNET and Flash media is examined. Usage of the interface-based DCNET environment allows to reduce time and material costs for the development t and study of complicated technological system	2016-08-31	128	https://doi.org/10.15673/atbp.v8i2.164	DEVELOPMENT OF PRINCIPLES OF DCNET AND FLASH ENVIRONMENTS INTERACTION	1
129	Стаття	It's noted the current stress state of the natural environment due to the increasing harmful effects of the developing global production. It's indicated on the urgency to fully reduce the harmful effects of production. It's shown the control operatio	2016-08-31	129	https://doi.org/10.15673/atbp.v8i2.163	ABOUT SIGNIFICANCE OF THE CONTROL PROBLEM OF ECOLOGICAL EFFICIENCY OF FUNCTIONING OF TECHNICAL OBJECTS	1
130	Стаття	This overview article shows the advantages of a modern electric car as compared with internal combustion cars by the example of the electric vehicles of Tesla Motors Company. It (в смысле- статья) describes the history of this firm, provides technic	2016-08-31	130	https://doi.org/10.15673/atbp.v8i2.162	MODERN ELECTRIC CARS OF TESLA MOTORS COMPANY	1
131	Стаття	This paper considers an example of solving the problem of  single-dimensional cutting optimization. It is  shown that  elements of the theory of genetic algorithms can be used successfully for its solution. A distinctive feature of this task is the n	2016-08-31	131	https://doi.org/10.15673/atbp.v8i2.161	GENETIC ALGORITHMS APPLICATION TO DECIDE THE  ISSUE OF SINGLE-DIMENSIONAL CUTTING  OPTIMIZATION	1
132	Стаття	Методика расчета повреждения оболочек твэлов ВВЕР- 1000 основана на энергетическом варианте теории ползучести, который является экспериментально подтвержденным. Результаты расчета, которые позволяют\nнаходить алгоритмы перестановок ТВЗ с минимизацией	2016-07-20	132	https://doi.org/10.21691/atbp.v8i1.28	КОМПЬЮТЕРНО-ИНТЕГРИРОВАННАЯ СИСТЕМА УПРАВЛЕНИЯ ПЕРЕСТАНОВКАМИ ТВС В АКЗ ВВЭР-1000 С УЧЕТОМ ПОВРЕЖДЕННОСТИ ОБОЛОЧЕК ТВЭЛОВ	1
133	Стаття	Приведена приближенная модель в сосредоточенной постановке, описывающая процесс нагрева бесконечной пластины, цилиндра, шара, позволяющая определить момент его окончания. Полученные результаты\nсравнены с известными точными решениями на основе распре	2016-07-20	133	https://doi.org/10.21691/atbp.v8i1.27	МАТЕМАТИЧНА МОДЕЛЬ ДИНАМІКИ УСТАНОВКИ ПІДГОТОВКИ ВУГЛЕКИСЛОГО ГАЗУ У ТЕХНОЛОГІЧНОМУ ПРОЦЕСІ ВИРОБНИЦТВА КАРБАМІДУ	1
196	Стаття	In Ukraine, since the beginning of formation of market relations and so far, a lot of urgent and important questions, connected with debts receivable accounting, have been existed. Therefore, it stipulates constant considering of normative acts and r	2018-04-03	196	https://doi.org/10.15673/fie.v10i1.873	THE PECULIARITIES OF DEBTS RECEIVABLE ACCOUNTING ACCORDING TO THE NATIONAL AND INTERNATIONAL STANDARDS: A COMPARATIVE ASPECT	2
134	Стаття	Обернена увага на загострення проблеми оновлення технологічного устаткування, що витратило ресурс працездатності. Відмічено, що основна частина виробничих фондів країни складається з подібного, зношеного\nустаткування. Вказано на те, що подібне полож	2016-07-20	134	https://doi.org/10.21691/atbp.v8i1.26	ЧАСТКОВЕ ОНОВЛЕННЯ – ІННОВАЦІЙНИЙ ІНСТРУМЕНТ УПРАВЛІННЯ ЕФЕКТИВНІСТЮ ФУНКЦІОНУВАННЯ УСТАТКУВАННЯ, ЩО ВІДРОБИЛО РЕСУРС	1
135	Стаття	Многие объекты автоматического регулирования являются нестационарными. Проявляется это в изменении\nих параметров. Поэтому периодически требуется корректировать и параметры регуляторов. Такая работа осуществляется обычно редко. Поэтому значительную ч	2016-07-20	135	https://doi.org/10.21691/atbp.v8i1.25	ПРОСТОЙ ПИ–ПОДОБНЫЙ РЕГУЛЯТОР С КОНТИНУАЛЬНОЙ ЛОГИКОЙ ДЛЯ НЕСТАЦИОНАРНЫХ ОБЪЕКТОВ	1
136	Стаття	The article presents the results of experimental and statistical modeling and the search for effective organizational\nsolutions for reconstruction of high-rise engineering structures by the example of the Ostankino television tower. The\ndependences	2016-07-20	136	https://doi.org/10.21691/atbp.v8i1.24	EFFICIENT RECONSTRUCTION OF ENGINEERING BUILDINGS IN CONDITIONS OF ORGANIZATIONAL CONSTRAINTS	1
137	Стаття	Розглянуто проблему збору та аналізу даних для HR менеджерів в ІТ-компанії. Запропоновано розробити автоматизовану система аналізу даних персоналу і відстеження професійної майстерності співробітників\nкомпанії. Система виконує збереження та аналіз о	2016-07-20	137	https://doi.org/10.21691/atbp.v8i1.23	АВТОМАТИЗАЦІЯ АНАЛІЗУ КАР’ЄРНОГО РОЗВИТКУ ТА ПІДТРИМКА ПРИЙНЯТТЯ РІШЕНЬ ЩОДО АТЕСТАЦІЇ РОЗРОБНИКІВ ПРОГРАМНОГО ЗАБЕЗПЕЧЕННЯ	1
138	Стаття	Определены зависимости, которые можно использовать для получения линейной характеристики управления АЧХ при аппроксимации характеристики. Показана возможность такого управления.	2016-07-20	138	https://doi.org/10.21691/atbp.v8i1.22	АППРОКСИМАЦИЯ В ЗАДАЧЕ УПРАВЛЕНИЯ ХАРАКТЕРИСТИКОЙ ЦИФРОВОГО ФИЛЬТРА ДЛЯ СПЕЦИАЛИЗИРОВАННОЙ КОМПЬЮТЕРНОЙ СИСТЕМЫ	1
139	Стаття	Розглянуто основні принципи синтезу багатовимірних систем автоматичного керування для промислових комплексів штучного мікроклімату. Отримано комплексну динамічну модель промислового кондиціонера із\nпаровим зволожувачем у просторі стану. Запропонован	2016-07-20	139	https://doi.org/10.21691/atbp.v8i1.21	ПРИНЦИПИ СИНТЕЗУ АВТОМАТИЧНИХ СИСТЕМ КЕРУВАННЯ ПРОМИСЛОВИМИ КОНДИЦІОНЕРАМИ	1
140	Стаття	У статті розглянуто автоматизація блоку очищення установок розділення повітря середнього тиску, яким враховуючи сучасні вимоги ринку, необхідно підвищити рівень автоматизації. Проведено аналіз існуючих\nвимог до установок середнього тиску. Поставлена	2016-07-20	140	https://doi.org/10.21691/atbp.v8i1.19	ПІДВИЩЕННЯ РІВНЯ АВТОМАТИЗАЦІЇ БЛОКУ ОЧИЩЕННЯ УСТАНОВКИ РОЗДІЛЕННЯ ПОВІТРЯ	1
141	Стаття	Из-за несовершенства технологических производств многие промышленные предприятия имеют побочные газообразные продукты, которые относятся к вторичным энергоресурсам. Использование таких газов в\nкачестве топлива для энергетических установок данных пре	2016-07-20	141	https://doi.org/10.21691/atbp.v8i1.17	ИССЛЕДОВАНИЕ ЭНЕРГЕТИЧЕСКИХ ХАРАКТРЕИСТИК КОГЕНЕРАЦИОННОЙ ЭНЕРГЕТИЧЕСКОЙ УСТАНОВКИ В УСЛОВИЯХ ИЗМЕНЕНИЯ КАЧЕСТВА ТОПЛИВА	1
142	Стаття	Работа посвящена разработке нового метода расчета матриц передаточных функций трактов управления\nоптимального многомерного регулятора. Регулятор предназначен для максимизации точности перехода\nлинейного многомерного объекта управления из одного уста	2016-07-20	142	https://doi.org/10.21691/atbp.v8i1.16	АНАЛИТИЧЕСКОЕ КОНСТРУИРОВАНИЕ ОПТИМАЛЬНЫХ СИСТЕМ УПРАВЛЕНИЯ ДВИЖЕНИЕМ ЛИНЕЙНОГО ОБЪЕКТА ПО ЗАДАННОЙ ТРАЕКТОРИИ ПРИ СТОХАСТИЧЕСКИХ ВОЗДЕЙСТВИЯХ	1
143	Стаття	The flame stability with regard to two-dimensional exponential perturbations both for the combustion in the half-open fire-chamber and the flame propagating in half-open channels is investigated. It is proved that only instability is\npossible for th	2016-07-20	143	https://doi.org/10.21691/atbp.v8i1.18	TWO-DIMENSIONAL FLAME INSTABILITY AND CONTROL OF BURNING IN THE HAlF-OPEN FIRECHAMBER	1
144	Стаття	In this study, on the basis of a comprehensive review of scientific publications, the definition of "food\nsecurity" is defined. The level of safety is determined on the basis of the structure of consumption of food by\nthe population, gross output by	2019-06-06	144	https://doi.org/10.15673/fie.v11i1.1291	THE MAIN VECTORS OF THE DEVELOPMENT OF FOOD SECURITY	2
145	Стаття	В статті розглянуто сучасній стан торгівлі агропродовольчими товарами України та ЄС. Вста-\nновлено, що в останні роки країни ЄС стають одними із важливих імпортерів продукції сільського гос-\nподарства та харчової промисловості, що пов’язується з діє	2019-03-12	145	https://doi.org/10.15673/fie.v11i1.1292	СТАН ТА РЕЗУЛЬТАТИ ТОРГІВЛІ АГРОПРОДОВОЛЬЧИМИ ТОВАРАМИ МІЖ УКРАЇНОЮ І ЄВРОПЕЙСЬКИМ СОЮЗОМ	2
146	Стаття	Садівництво, як і будь яка інша праця на землі є не тільки пріоритетним сектором економіки, але\nі захоплюючим хобі, яке у поєднанні з самобутньою місцевою культурою та кухнею здатне створити\nунікальну туристичну пропозицію та привернути увагу значно	2019-03-12	146	https://doi.org/10.15673/fie.v11i1.1289	РОЛЬ САДІВНИЦЬКИХ ТОВАРИСТВ В ЗАБЕЗПЕЧЕННІ РОЗВИТКУ ГАСТРОНОМІЧНИХ АТРАКЦІЙ І ФОРМУВАННІ ТУРИСТИЧНИХ ДЕСТИНАЦІЙ НА ЗАСАДАХ ЗЕЛЕНОЇ ЕКОНОМІКИ	2
147	Стаття	It has been noted that despite the important role of the agri-food sphere both in the domestic and in\nthe world market, it requires systemic transformations on the basis of sustainability and inclusiveness. The\nessence of the concepts of "sustainabl	2019-03-12	147	https://doi.org/10.15673/fie.v11i1.1290	STRATEGIC DIRECTIONS OF SUSTAINABLE AND INCLUSIVE DEVELOPMENT OF THE AGRI-FOOD SPHERE	2
148	Стаття	У статті обґрунтовано сутність та складові відтворювального механізму стимулювання розвитку\nвітчизняного органічного ринку. Досліджено взаємопов’язаність інституційних заходів підтримки органіч-\nного виробництва у площині забезпечення розширеного ві	2019-03-12	148	https://doi.org/10.15673/fie.v11i1.1293	ВІДТВОРЮВАЛЬНИЙ МЕХАНІЗМ СТИМУЛЮВАННЯ РОЗВИТКУ УКРАЇНСЬКОГО РИНКУ ОРГАНІЧНОЇ ПРОДУКЦІЇ	2
149	Стаття	The research examines the nature and characteristics of the "blue ocean" strategy application in a\nhighly competitive environment, the theoretically grounded the necessity and sequence of the implement\ntion of the Blue Ocean Strategy in the wine ind	2019-03-12	149	https://doi.org/10.15673/fie.v11i1.1294	APPLICATION OF THE "BLUE OCEAN" STRATEGY IN UKRAINIAN WINEMAKING INDUSTRY	2
150	Стаття	The relevance of this topic is determined by the need for the formation of students’ leadership skills\nand their personal social responsibility that will allow graduates to master the skills to work in a team, to be\nan effective manager of enterpris	2019-03-12	150	https://doi.org/10.15673/fie.v11i1.1295	FORMATION OF LEADERSHIP QUALITIES AND SOCIAL RESPONSIBILITY OF THE MODERN MANAGER IN ODESSA NATIONAL ACADEMY OF FOOD TECHNOLOGIES	2
151	Стаття	Більшість підприємств використовують звичайні технології управління та навчання персоналу,\nпри цьому підприємства прагнуть швидкого розвитку та виходу на нові світові ринки. Це неможливо,\nякщо використовувати застарілі технології щодо управління в ц	2019-03-12	151	https://doi.org/10.15673/fie.v11i1.1296	ІННОВАЦІЙНІ ТЕХНОЛОГІЇ НАВЧАНЯ ПЕРСОНАЛУ	2
152	Стаття	За останні роки все більша кількість організацій в Україні та світі у своїй роботі віддає перевагу\nаутсорсинговим партнерським відносинам, а також інструментам аутстафінгу та лізінгу персоналу. Д\nна стаття присвячена дослідженню специфіки інноваційн	2019-03-12	152	https://doi.org/10.15673/fie.v11i1.1297	СПЕЦИФІКА ЗАСТОСУВАННЯ ІНСТРУМЕНТІВ АУТСОРСИНГУ, АУТСТАФІНГУ ТА ЛІЗИНГУ В СИСТЕМІ УПРАВЛІННЯ ПЕРСОНАЛОМ	2
189	Стаття	The problems of formation of revenues of local budgets are investigated in the article. It has been established that significant centralization has affected the reduction of financial independence of local selfgovernment bodies. Changes in the manage	2018-07-08	189	https://doi.org/10.15673/fie.v10i2.964	FINANCIAL INSTRUMENTS FOR PROVISION OF SUSTAINABLE ECONOMIC GROWTH OF TERRITORIAL DEVELOPMENTS	2
153	Стаття	В статі розглянуто актуальність та основні аспекти роботи сучасного керівника, його місце та\nзначущість в суспільстві. Виділено особливі проблеми, які значною мірою впливають на поведінку, а\nвідповідно, і на рішення, які повинен приймати керівник. У	2019-03-12	153	https://doi.org/10.15673/fie.v11i1.1298	СИСТЕМНИЙ ПІДХІД ДО ПІДВИЩЕННЯ ОСОБИСТОЇ ЕФЕКТИВНОСТІ СУЧАСНОГО КЕРІВНИКА	2
154	Стаття	В статті досліджуються сучасні тенденції українського рекламного ринку. Виявлено, що се-\nред найбільш впливових та пріоритетних каналів рекламних комунікацій залишаються Інтернет-\nреклама та реклама на телебаченні. Окреслені види та дана характерист	2019-03-12	154	https://doi.org/10.15673/fie.v11i1.1299	ОСОБЛИВОСТІ ТА ПЕРСПЕКТИВ РОЗВИТКУ РИНКУ РЕКЛАМИ В УКРАЇНІ	2
155	Стаття	Обґрунтована необхідність дослідження ринку цінних паперів, що полягає у розкритті процесів\nфункціонування ринкових відносин в економіці держави, де основна увага приділяється зміні відсотко-\nвих ставок, вартості грошей та цінних паперів, кредитної	2019-03-12	155	https://doi.org/10.15673/fie.v11i1.1300	РОЛЬ РИНКУ ЦІННИХ ПАПЕРІВ В ЕКОНОМІЦІ ДЕРЖАВИ (НА ПРИКЛАДІ США)	2
156	Стаття	Ukrainian sustainable development envisages the food industry reforming and the formation of a\nmodern structure of the national economy. Regional financial decentralization should help to solve this problem. Fiscal decentralization should optimize t	2019-03-12	156	https://doi.org/10.15673/fie.v11i1.1301	THE INNOVATIVE WAY OF OVERCOMING OF FOOD INDUSTRY ENTERPRISES PROBLEMS	2
157	Стаття	The article examines the essence of the concept of «evaluation activity» and approaches to its definition. The study shows the six main types of evaluation methodologies: methodology without calculations,\ntarget methodology of formation, methodology	2019-03-12	157	https://doi.org/10.15673/fie.v11i1.1302	INFORMATION SYSTEMS AND TECHNOLOGIES IN THE PROCESS OF EVALUATION ACTIVITIES	2
158	Стаття	У статті обґрунтовано методологічний підхід до моніторингу «зелених» індикаторів на засадах\nсталого розвитку у двоєдності концептуального та методичного базисів, визначено наукові принципи\nмоніторингу прогресу «зеленого» зростання. Автором запропоно	2018-12-23	158	https://doi.org/10.15673/fie.v10i4.1129	МЕТОДИЧНІ ПОЛОЖЕННЯ ЩОДО МОНІТОРИНГУ ІНДИКАТОРІВ «ЗЕЛЕНОГО» ЗРОСТАННЯ У КОНТЕКСТІ СТАЛОГО РОЗВИТКУ УКРАЇНИ	2
159	Стаття	У статті досліджено природу інституційних дисбалансів та практичні форми їх прояву в сфері зо-\nвнішньоекономічної інтеграції вітчизняного ринку борошномельно-круп’яної продукції. Показано транс-\nформаційних вплив інституційних дисбалансів на розвито	2018-12-23	159	https://doi.org/10.15673/fie.v10i4.1130	ЗАХОДИ ПОДОЛАННЯ ІНСТИТУЦІЙНИХ ДИСБАЛАНСІВ ЗОВНІШНЬОЕКОНОМІЧНОЇ ІНТЕГРАЦІЇ УКРАЇНСЬКОГО РИНКУ БОРОШНОМЕЛЬНО-КРУП’ЯНОЇ ПРОДУКЦІЇ	2
160	Стаття	Досліджено понятійно-категоріальний апарат сутності категорій «оборотні активи» підприєм-\nства та їх важливих елементів – «запасів», «дебіторської заборгованості», «грошових коштів» в пу-\nблікаціях вчених та П(С)БО, обґрунтовано взаємозв'язок між ни	2018-12-23	160	https://doi.org/10.15673/fie.v10i4.1131	ОСОБЛИВОСТІ АНАЛІЗУ ОБОРОТНИХ АКТИВІВ ПІДПРИЄМСТВА В СУЧАСНИХ УМОВАХ	2
161	Стаття	В статті проведено дослідження підходів до класифікації фінансових результатів діяльності пі-\nдприємства в наукових працях та відповідно до НП(С)БО 1. Досліджено підходи до проведення еко-\nномічного аналізу фінансових результатів діяльності підприєм	2018-12-23	161	https://doi.org/10.15673/fie.v10i4.1132	АНАЛІЗ ФІНАНСОВИХ РЕЗУЛЬТАТІВ ДІЯЛЬНОСТІ ПІДПРИЄМСТВА: ТЕОРЕТИЧНИЙ ТА ПРАКТИЧНИЙ АСПЕКТ	2
162	Стаття	У статті розглядаються основні теоретико-методичні аспекти оцінки рівня ризикованості діяль-\nності підприємств. Кількісна оцінка ризиків в цілому передбачає розв’язання двох завдань: вибір мето-\nду оцінки ризиків та визначення міри та ступеня ризику	2018-12-23	162	https://doi.org/10.15673/fie.v10i4.1135	КІЛЬКІСНИЙ АНАЛІЗ РІВНЯ РИЗИКОВАНОСТІ ДІЯЛЬНОСТІ ПІДПРИЄМСТВ: КЛЮЧОВІ ПОКАЗНИКИ	2
163	Стаття	The article explores the essence and features of tourist enterprises management, as well as the\nmost important competencies of the personnel which influence the efficiency of these enterprises. The\nsearch for new opportunities in achieving a higher	2018-12-23	163	https://doi.org/10.15673/fie.v10i4.1136	RESEARCH ON THE INFLUENCE OF PERSONNEL COMPETENCIES ON THE EFFICIENCY OF TOURIST ENTERPRISES MANAGEMENT	2
164	Стаття	The issues of formation of the land market and the role of the state in its regulation have been studied in the article. The great importance of the agrarian business (APC)’s reforming is placed on the land\nmarket. Its formation was carried out in a	2018-12-23	164	https://doi.org/10.15673/fie.v10i4.1128	PROBLEMS OF THE LAND MARKET FORMATION AND THE ASSESSMENT OF NATURAL RESOURCES	2
190	Стаття	The article analyzes the concept of innovation and innovation development. Separately the importance of innovative development for the formation of the strategy of a modern enterprise has been shown.\nThe analysis of world innovative processes and the	2018-07-08	190	https://doi.org/10.15673/fie.v10i2.963	INNOVATIVE DEVELOPMENT STRATEGY FORMATION OF THE MODERN ENTERPRISE	2
165	Стаття	У статті розглянуто класифікацію субсидій СОТ та їх вплив на виробництво й торгівлю. Пред-\nставлено обсяги державної підтримки агропромислового виробництва країн ЄС та України. Вивчено\nдосвід участі у СОТ країн ЄС, їх ідеї та принципи стосовно єдино	2018-12-22	165	https://doi.org/10.15673/fie.v10i4.1127	ДЕРЖАВНА ПІДТРИМКА АГРОПРОМИСЛОВОГО ВИРОБНИЦТВА УКРАЇНИ ТА КРАЇН ЄС В УМОВАХ СОТ	2
166	Стаття	У статті розглянуто економічний зміст та підходи до визначення категорії «кредиторська заборгова-\nність» за нормативно-правовими актами та в економічній літературі. Проведено дослідження теоретичних під-\nходів та їх практичного використання щодо про	2018-12-22	166	https://doi.org/10.15673/fie.v10i4.1134	КРЕДИТОРСЬКА ЗАБОРГОВАНІСТЬ ПІДПРИЄМСТВА: ОЦІНКА ТА МЕХАНІЗМИ УПРАВЛІННЯ	2
167	Стаття	В статті обґрунтовано значення готельного бізнесу в економіці України та необхідність підви-\nщення уваги менеджменту підприємств готельної сфери до питання удосконалення стратегічного\nуправління. Визначено що не вміння керівників застосовувати сучас	2018-12-22	167	https://doi.org/10.15673/fie.v10i4.1137	ДОСЛІДЖЕННЯ СУЧАСНИХ АЛЬТЕРНАТИВ ТА ПРИНЦИПІВ СТРАТЕГІЧНОГО УПРАВЛІННЯ ЯК ФАКТОРУ РОЗВИТКУ ПІДПРИЄМСТВ У СФЕРІ ГОТЕЛЬНИХ ПОСЛУГ	2
168	Стаття	В статті розкрито сутність глобальної та географічної моделі соціальної відповідальності. Від-\nмічено, що глобальна модель соціальної відповідальності базується на етичній поведінці бізнесу, гео-\nграфічна модель представлена трьома теоріями: корпора	2018-12-22	168	https://doi.org/10.15673/fie.v10i4.1138	УКРАЇНСЬКІ РЕАЛІЇ ЩОДО СОЦІАЛЬНОЇ ВІДПОВІДАЛЬНОСТІ БІЗНЕСУ У СУЧАСНИХ УМОВАХ	2
169	Стаття	Важливою складовою здорового способу життя є раціональне харчування, яке допомагає підт-\nримувати високий рівень життєдіяльності. Стаття присвячена аналізу харчування студентів вищої\nшколи, визначення акцентів формування свідомого ставлення до харчу	2018-12-22	169	https://doi.org/10.15673/fie.v10i4.1139	УПРАВЛІННЯ ХАРЧОВИМ ВИБОРОМ СТУДЕНТСЬКОЇ МОЛОДІ	2
170	Стаття	У статті розглянуто організаційно-методичні умови до проведення аналізу стану, руху та дина-\nміки основних засобів на прикладі м'ясопереробних підприємств України. Розглянуто різні підходи до\nвизначення сутності основних засобів та їх зв’язок з осно	2018-12-22	170	https://doi.org/10.15673/fie.v10i4.1133	ОРГАНІЗАЦІЯ І МЕТОДИКА ПРОВЕДЕННЯ АНАЛІЗУ СТАНУ ТА РУХУ ОСНОВНИХ ЗАСОБІВ НА М'ЯСОПЕРЕРОБНИХ ПІДПРИЄМСТВАХ	2
172	Стаття	У статті розглядається сутність поняття «внутрішньогосподарський контроль», «система внут-\nрішньогосподарського контролю», теоретичні та практичні особливості контролю готової продукції та\nрозрахунків з покупцями та замовниками на підприємстві. На б	2018-10-18	172	https://doi.org/10.15673/fie.v10i3.1065	ОСОБЛИВОСТІ ВНУТРІШНЬОГОСПОДАРСЬКОГО КОНТРОЛЮ РОЗРАХУНКІВ З ПОКУПЦЯМИ ТА РЕАЛІЗАЦІЇ ГОТОВОЇ ПРОДУКЦІЇ	2
173	Стаття	Проведено аналіз нормативно-методичного забезпечення організації обліку та контролю, сис-\nтематизовано обов’язкові розділи (складові) облікової політики підприємств харчової промисловості.\nВиділено п’ять розділів облікової політики залежно від завда	2018-10-18	173	https://doi.org/10.15673/fie.v10i3.1064	ПРОБЛЕМИ ФОРМУВАННЯ ОБОВ’ЯЗКОВИХ КОМПОНЕНТІВ ОБЛІКОВОЇ ПОЛІТИКИ ПІДПРИЄМСТВА	2
174	Стаття	У статті викладено та розглянуто особливості бухгалтерського обліку розрахунків з оплати\nпраці працівникам підприємства з метою удосконалення системи обліку, а саме поліпшення організації\nобліку розрахунків з оплати праці з метою вирішення актуальни	2018-10-18	174	https://doi.org/10.15673/fie.v10i3.1063	ОБЛІК РОЗРАХУНКІВ З ОПЛАТИ ПРАЦІ В СИСТЕМІ УПРАВЛІННЯ ПІДПРИЄМСТВОМ	2
175	Стаття	У статті розглянуті види класифікацій інновацій в залежності від рівня новизни. Проаналізовано\nосновні підходи класифікації інновацій вітчизняними і зарубіжними дослідниками. Зокрема, розглянуто\nкласифікації інновацій за роллю в реалізації цілей, за	2018-10-18	175	https://doi.org/10.15673/fie.v10i3.1062	АНАЛІЗ КЛАСИФІКАЦІЙ ІННОВАЦІЙ ЗА РІВНЕМ НОВИЗНИ	2
176	Стаття	У статті обґрунтовано важливість пристосування підприємства до мінливого зовнішнього сере-\nдовища його функціонування. Висвітлено категорію «адаптація комунікативної складової комплексу\nмаркетингу» підприємства. Дано методику визначення рівня адапта	2018-10-18	176	https://doi.org/10.15673/fie.v10i3.1061	ВИЗНАЧЕННЯ РІВНЯ АДАПТАЦІЇ КОМУНІКАТИВНОЇ СКЛАДОВОЇ КОМПЛЕКСУ МАРКЕТИНГУ ВИНОРОБНОГО ПІДПРИЄМСТВА (НА ПРИКЛАДІ ПРАТ «КНЯЗЯ ТРУБЕЦЬКОГО»)	2
177	Стаття	В даній статті розглянуто процес формування стратегічних рішень просування на ринок інно-\nваційного продукту зі вторинної сировини виноробства на прикладі ПрАТ «Одесавинпром», розробле-\nно чотири функціональні стратегії згідно з кожним елементом ком	2018-10-18	177	https://doi.org/10.15673/fie.v10i3.1060	СТРАТЕГІЧНІ РІШЕННЯ ПРОСУВАННЯ НА РИНОК ІННОВАЦІЙНОГО ПРОДУКТУ ЗІ ВТОРИННОЇ СИРОВИНИ ВИНОРОБСТВА	2
178	Стаття	The article proves the practicability of producing wine from local grapes for Ukrainian wineries. The\nsubstantiation is based on the construction of five levels of goods and consumer values. The fifth level is a\nwine that has a unique style: its cha	2018-10-18	178	https://doi.org/10.15673/fie.v10i3.1059	CREATION OF LOCAL WINES AS A METHOD OF FORMATION OF COMPETITIVE ADVANTAGES OF THE WINERY	2
179	Стаття	В статті розглянуто проблеми теорії та практики мотивації персоналу на підприємствах харчо-\nвої промисловості. Визначаються проблеми сьогодення, що пов’язані з науково-практичною інтерпре-\nтацією сутності мотивації, з впливом галузевої специфіки на	2018-10-18	179	https://doi.org/10.15673/fie.v10i3.1058	ПРОБЛЕМИ МОТИВАЦІЇ ПЕРСОНАЛУ НА ПІДПРИЄМСТВАХ ХАРЧОВОЇ ПРОМИСЛОВОСТІ	2
180	Стаття	В статті розглядаються питання розвитку підприємств агропродовольчого комплексу, та ви-\nзначення передумов розробки експортної стратегії подальшого їх розвитку. На підставі дослідження\nрізних понять і підходів до формування стратегій розвитку, автор	2018-10-18	180	https://doi.org/10.15673/fie.v10i3.1057	ФОРМУВАННЯ ПЕРЕДУМОВ ЕКСПОРТНОЇ СТРАТЕГІЇ РОЗВИТКУ ПІДПРИЄМСТВ АГРОПРОДОВОЛЬЧОГО КОМПЛЕКСУ УКРАЇНИ	2
181	Стаття	In the article the author's model of public-private partnership, which was developed based on its key\nprinciples and functions of the subjects of state-agricultural partnership in the agrarian sphere has been proposed. The factors that affect the ef	2018-10-18	181	https://doi.org/10.15673/fie.v10i3.1056	FORMATION OF THE MODEL OF THE PUBLIC-PRIVATE PARTNERSHIPS AS AN INSTRUMENT FOR REGULATION OF THE SOCIO-ECONOMIC DEVELOPMENT OF AGRICULTURAL SECTOR	2
182	Стаття	У статті досліджено проблемні аспекти дії формальних інститутів у сфері зернової кооперації,\nвизначено причини їх інституційної неспроможності в українських реаліях. Доведено необхідність зміни\nметодологічного підходу до формування програмних докуме	2018-10-18	182	https://doi.org/10.15673/fie.v10i3.1067	ІНТЕГРАЦІЙНИЙ ПІДХІД ДО ФОРМУВАННЯ ПРОГРАМИ РОЗВИТКУ ЗЕРНОВИХ БАГАТОФУНКЦІОНАЛЬНИХ КООПЕРАТИВІВ В УКРАЇНІ	2
183	Стаття	Effectiveness of use of fixed assets depends on the organization of timely receipt of reliable and sufficiently complete accounting and economic information. In this regard, the role and significance of accounting as one of the most important managem	2018-07-08	183	https://doi.org/10.15673/fie.v10i2.967	THE ANALYSIS OF APPROACHES TO THE ESSENCE AND CLASSIFICATION OF FIXED ASSETS	2
184	Стаття	Облік є незамінною частиною діяльності будь-якого підприємства. Керівництво компанії повин-\nно суворо дотримуватися вимог українського законодавства. Бухгалтерський облік є майже самим ва-\nжливим з джерел інформації про господарську діяльність підпри	2018-07-08	184	https://doi.org/10.15673/fie.v10i2.966	ОСОБЛИВОСТІ СПРОЩЕНОЇ СИСТЕМИ БУХГАЛТЕРСЬКОГО ОБЛІКУ НА МАЛИХ ПІДПРИЄМСТВАХ В УКРАЇНІ	2
185	Стаття	У статті розглядається сутність поняття «витрати», «собівартість», «доходи», «фінансовий ре-\nзультат», теоретичні та практичні аспекти організації обліку витрат і доходів діяльності та фінансових\nрезультатів на підприємстві. Враховуючи складний фінан	2018-07-08	185	https://doi.org/10.15673/fie.v10i2.965	ОЦІНКА ВПЛИВУ ВИТРАТ І ДОХОДІВ НА ФІНАНСОВІ РЕЗУЛЬТАТИ НА ПРИКЛАДІ ПП ФІРМА «ГАРМАШ»	2
186	Стаття	В даній статті розглянуто теоретичні аспекти формування маркетингової стратегії підприєм-\nства. Проаналізовано мікро- та макросередовище ПрАТ «Одесавинпром», проаналізовано конкурент-\nне середовище підприємства, проведено портфельний аналіз стратегіч	2018-07-08	186	https://doi.org/10.15673/fie.v10i2.959	МАРКЕТИНГОВА СТРАТЕГІЯ ВИВЕДЕННЯ НА РИНОК ІННОВАЦІЙНОГО ПРОДУКТУ	2
187	Стаття	У статті проведений аналіз динаміки туристичних потоків одеського регіону та показано, що\nрозвиток туризму в Одеському регіоні має позитивну динаміку, але достатньо низькі темпи розвитку і\nна погляд авторів, одним із способів вирішення цієї проблеми	2018-07-08	187	https://doi.org/10.15673/fie.v10i2.958	ПОТЕНЦІАЛ РЕСТОРАННОГО ГОСПОДАРСТВА ОДЕЩИНИ В РОЗВИТКУ ГАСТРОНОМІЧНОГО ТУРИЗМУ	2
188	Стаття	У статті досліджено динаміку та географічну структуру товарного експорту України. Встанов-\nлено, що по причині згортання торгівлі з країнами СНД, основними торговими партнерами стають кра-\nїни ЄС та Азії. Товарна структура українського експорту свідч	2018-07-08	188	https://doi.org/10.15673/fie.v10i2.957	КРАЇНИ АЗІЇ – ГОЛОВНИЙ ПАРТНЕР УКРАЇНИ В ТОРГІВЛІ АГРОПРОДОВОЛЬЧИМИ ТОВАРАМИ	2
191	Стаття	У статті розглядаються організаційно-управлінські особливості командного лідерства у сфері\nвиробництва, аналізуються основні теорії лідерства в сучасній науці. Головна увага приділяється тим\nмоделям лідерства, які найбільш відповідають командній робо	2018-07-08	191	https://doi.org/10.15673/fie.v10i2.962	ОРГАНІЗАЦІЙНО-УПРАВЛІНСЬКІ ОСОБЛИВОСТІ КОМАНДНОГО ЛІДЕРСТВА У СФЕРІ ВИРОБНИЦТВА	2
192	Стаття	У статті розглянуто сучасний стан виноробної галузі, а саме порівняння України з країнами-\nлідерами, світове споживання вина та виробництво вина в Україні. Наведено відмінні характеристики\nта етапи стратегій розвитку виноробних підприємств. Визначено	2018-07-08	192	https://doi.org/10.15673/fie.v10i2.961	ПЛАНУВАННЯ РОЗВИТКУ ПІДПРИЄМСТВА НА ОСНОВІ РОЗРОБКИ СТРАТЕГІЧНОГО НАБОРУ	2
193	Стаття	У статті розкрита сутність реінжинірингу бізнес-процесів, що полягає у забезпеченні високої\nефективності діяльності підприємства, і спрямоване на задоволення потреб споживачів. Слід зазначи-\nти, що необхідність проведення реінжинірингу для кожного пі	2018-07-08	193	https://doi.org/10.15673/fie.v10i2.960	РЕІНЖИНІРИНГ БІЗНЕС-ПРОЦЕСІВ ЯК НАПРЯМ УСПІШНОГО РОЗВИТКУ ДІЯЛЬНОСТІ ПІДПРИЄМСТВ	2
194	Стаття	У статті шляхом декомпозиції та аналізу компонентів категорії «ринкова глокалізація» визначено\nїї природу, форми та концептуальну сутність, обґрунтовано доцільність використання даної дефініції в\nсучасних ринкових дослідженнях для оцінки динамічних п	2018-07-08	194	https://doi.org/10.15673/fie.v10i2.955	ГЛОКАЛІЗАЦІЯ ТОВАРНИХ РИНКІВ: ТЕОРЕТИЧНІ Й ПРИКЛАДНІ АСПЕКТИ	2
195	Стаття	В статті розглядаються процеси розвитку земельних відносин та становлення ринку землі в\nконтексті формування продовольчої політики України. Обґрунтовується необхідність капіталізації рин-\nку землі для забезпечення сталого розвитку нашої країни. Зазна	2018-07-08	195	https://doi.org/10.15673/fie.v10i2.954	КАПІТАЛІЗАЦІЯ РИНКУ ЗЕМЛІ ЯК ФАКТОР ПРОДОВОЛЬЧОЇ ПОЛІТИКИ УКРАЇНИ	2
197	Стаття	У статті розглядається сутність поняття «дебіторська заборгованість», «готова продукція», те-\nоретичні та практичні аспекти організації обліку розрахунків з вітчизняними покупцями та замовниками\nза реалізацію готової продукції на підприємстві. На баз	2018-04-03	197	https://doi.org/10.15673/fie.v10i1.872	АСПЕКТИ ОБЛІКУ РОЗРАХУНКІВ З ПОКУПЦЯМИ ТА ЗАМОВНИКАМИ ЗА ГОТОВУ ПРОДУКЦІЮ В СУЧАСНИХ УМОВАХ	2
198	Стаття	В статті проведено аналіз сучасних підходів щодо визначення сутності категорій «управлін-\nський облік», «стратегічних управлінський облік», підходів в наукових працях іноземних і українсь-\nких вчених щодо етапів розвитку управлінського обліку в істор	2018-04-03	198	https://doi.org/10.15673/fie.v10i1.871	РОЗВИТОК УПРАВЛІНСЬКОГО ОБЛІКУ: ІСТОРИЧНИЙ ТА ПРАКТИЧНИЙ АСПЕКТ	2
199	Стаття	У статті викладено та розглянуто особливості обліку і аналізу витрат діяльності на підприємст-\nвах виноробної галузі, досліджено теоретичні аспекти обліку витрат діяльності, методики аналізу ви-\nтрат діяльності. Також досліджено особливості обліку ви	2018-04-03	199	https://doi.org/10.15673/fie.v10i1.870	ОСОБЛИВОСТІ ОБЛІКУ І АНАЛІЗУ ВИТРАТ ДІЯЛЬНОСТІ НА ПІДПРИЄМСТВАХ ВИНОРОБНОЇ ГАЛУЗІ	2
200	Стаття	У статті досліджуються проблеми забезпечення бюджетної безпеки України, яка відіграє над-\nзвичайно важливу роль у розвитку суспільства. Розглянуто зміст фінансової політики як частини\nекономічної політики держави. Визначені методологічні принципи, на	2018-04-03	200	https://doi.org/10.15673/fie.v10i1.869	ФІНАНСОВА ПОЛІТИКА І БЮДЖЕТНА БЕЗПЕКА УКРАЇНИ	2
201	Стаття	У статті досліджено роль інформаційних технологій в управлінні підприємством, розкрито сут-\nність та перспективи впровадження інформаційних технологій в управлінні сучасними підприємствами.\nВідображено тенденції впровадження інформаційних технологій	2018-04-03	201	https://doi.org/10.15673/fie.v10i1.868	РОЛЬ ІНФОРМАЦІЙНИХ ТЕХНОЛОГІЙ В УПРАВЛІННІ ПІДПРИЄМСТВОМ	2
202	Стаття	Визначено інтеграційні тенденції та проблеми розвитку вітчизняного ринку хліба та хлібобулоч-\nних виробів у розрізі офіційного та «тіньового» сегментів. Показано трансформаційний вплив «тіньово-\nго» сегменту на відтворювальний розвиток хлібного ринку	2018-04-03	202	https://doi.org/10.15673/fie.v10i1.862	ІНТЕГРАЦІЙНІ МЕХАНІЗМИ РОЗВИТКУ УКРАЇНСЬКОГО РИНКУ ХЛІБА ТА ХЛІБОБУЛОЧНИХ ВИРОБІВ	2
228	Стаття	Ukraine is one of the biggest wine producing countries in Europe. The purpose of this chapter is to\nshow the dynamics of evolution of world wine making, comparing the categories of Old World wines and New\nWorld wines. And, mainly, to determine place	2017-10-12	228	https://doi.org/10.15673/fie.v9i2.644	GLOBAL STRATEGY OF POSITIONING OF UKRAINE WINE PRODUCTION IN UKRAINE	2
203	Стаття	На основі творчого використання міждисциплінарного і маркетингового підходів, методів аналі-\nзу і синтезу, дедукції та індукції, структурно-функціонального, SWOT-аналізу здійснено позиціонування\nсільських територій як агроекосистемами, економічного п	2018-04-03	203	https://doi.org/10.15673/fie.v10i1.867	ТЕОРЕТИЧНІ ЗАСАДИ БРЕНДИНГУ СІЛЬСЬКИХ ТЕРИТОРІЙ ПІВДЕННОГО РЕГІОНУ	2
204	Стаття	У статті доведено, що маркетингові стратегії в управлінні діяльністю і розвитком підприємств є\nневід’ємною складовою системи аграрного менеджменту. Здійснено оцінку політичних, економічних,\nсоціальних, технологічних факторів макроекономічного середов	2018-04-03	204	https://doi.org/10.15673/fie.v10i1.866	ОБГРУНТУВАННЯ МАРКЕТИНГОВОЇ СТРАТЕГІЇ РОЗВИТКУ АГРАРНОГО ПІДПРИЄМСТВА РИНКОВОГО ТИПУ	2
205	Стаття	The article deals with the main theoretical aspects of risk assessment of industrial enterprises in the\nshort-and long-term periods. The main features of short-term and long-term risks inherent to industrial enterprises have been determined. Comprehe	2018-04-03	205	https://doi.org/10.15673/fie.v10i1.865	FEATURES OF RISK ASSESSMENT OF INDUSTRIAL ENTERPRISES ACTIVITIES	2
206	Стаття	В статті розглянуто та обґрунтовано закономірний взаємозв’язок ринкових категорій «адапти-\nвність підприємства» та «конкурентоспроможність підприємства», досліджено прикладний аспект що-\nдо етапів адаптаційного процесу підприємства.\nВ статті визначен	2018-04-03	206	https://doi.org/10.15673/fie.v10i1.864	АДАПТИВНІСТЬ ЯК КЛЮЧОВИЙ ФАКТОР КОНКУРЕНТОСПРОМОЖНОСТІ ПІДПРИЄМСТВА	2
207	Стаття	In the article the concepts and categories of nature of the categories "current assets", "working\ncapital", "current funds" have been examined and investigated the relationship between these categories\nand approaches to classification of current asse	2018-04-03	207	https://doi.org/10.15673/fie.v10i1.863	CURRENT ASSETS OF THE ENTERPRISE: THEORETICAL AND PRACTICAL ASPECTS	2
208	Стаття	В статті наведено результати аналізу сучасного стану туристичної галузі Одеської області. Ро-\nзглянуто питому вагу туристів регіону. У 2016 р. серед громадян Одеської області існує великий попит\nна закордонні подорожі, оскільки люди вирішили витрачат	2018-04-03	208	https://doi.org/10.15673/fie.v10i1.861	РЕАЛІЇ СЬОГОДЕННЯ ТА ПЕРСПЕКТИВИ РОЗВИТКУ ТУРИСТИЧНОГО БІЗНЕСУ ОДЕСЬКОЇ ОБЛАСТІ	2
209	Стаття	The article has analyzed the "cluster" category, the expected positive effects of the creation and development of clusters in the agri-food sphere of the Southern region have been grounded and the European clustering experience has been considered. T	2018-04-03	209	https://doi.org/10.15673/fie.v10i1.859	CLUSTER DEVELOPMENT OF THE AGRI-FOOD SPHERE OF THE SOUTHERN REGION: THE FOREIGN ECONOMIC ACTIVITY ASPECT	2
210	Стаття	The analysis of theoretical approaches concerning determination of “monetary means” concept and\ntheir classification in the economic literature and according to the accounting standards, has been considered in the article. Monetary means are the most	2017-12-21	210	https://doi.org/10.15673/fie.v9i4.751	THE ANALYSIS OF THEORETICAL APPROACHES CONCERNING DETERMINATION OF MONETARY MEANS ACCORDING TO THE ACCOUNTING STANDARDS	2
211	Стаття	У статті викладено та розглянуто особливості обліку собівартості продукції на підприємствах\nвиноробної галузі, досліджено теоретичні аспекти обліку собівартості продукції, розглянуті сутність та\nскладові собівартості продукції. Виконано порівняльний	2017-12-21	211	https://doi.org/10.15673/fie.v9i4.750	ОСОБЛИВОСТІ ОБЛІКУ СОБІВАРТОСТІ ПРОДУКЦІЇ У ВИНОРОБНІЙ ГАЛУЗІ	2
212	Стаття	У статті досліджено сутність категорії «податок на додану вартість», якій є непрямим видом\nподатку, котрий включається в ціну товарів, робіт та послуг на стадії їх реалізації. Визначено його роль\nу формуванні дохідної частини Державного бюджету Украї	2017-12-21	212	https://doi.org/10.15673/fie.v9i4.749	ПОДАТОК НА ДОДАНУ ВАРТІСТЬ ТА ЙОГО РОЛЬ У ФОРМУВАННІ ДОХОДІВ ДЕРЖАВНОГО БЮДЖЕТУ УКРАЇНИ	2
213	Стаття	У статті розглянуто теоретичні засади композиції державного регуляторного механізму активізації інноваційних процесів у визначених інституційних ланках харчової промисловості України. Визначені «сильні» та «слабкі» регуляторні важелі (через критеріал	2017-12-21	213	https://doi.org/10.15673/fie.v9i4.748	ДЕРЖАВНЕ РЕГУЛЮВАННЯ ІННОВАЦІЙНО-ОРІЄНТОВАНОГО РОЗВИТКУ ХАРЧОВОЇ ПРОМИСЛОВОСТІ УКРАЇНИ	2
214	Стаття	У статті розглянуті заходи щодо впровадження інноваційних розробок на виноробних підприємствах Одеської області. Проведено порівняльний аналіз використання управлінських, технологічних\nта товарних інновацій на підприємствах виноробної галузі. проведе	2017-12-21	214	https://doi.org/10.15673/fie.v9i4.747	АНАЛІЗ НАПРЯМКІВ ІННОВАЦІЙНОГО РОЗВИТКУ ПІДПРИЄМСТВ ВИНОРОБНОЇ ГАЛУЗІ	2
215	Стаття	The article states that Ukraine doesn’t have an opportunity to attract investments for economic development. At the same time, attracting infrastructure bonds and improving lending will allow to find additional investments and ensure GDP growth.	2017-12-21	215	https://doi.org/10.15673/fie.v9i4.746	INVESTMENT POTENTIAL OF UKRAINE AND THE POSSIBILITIES OF ITS USE	2
216	Стаття	Проведене дослідження присвячено удосконаленню системи управління професійнокваліфікаційним розвитком працівників виноробних підприємств Розкрито основні етапи управління\nкваліфікаційним розвитком працівників, визначено шляхи підвищення кваліфікації.	2017-12-21	216	https://doi.org/10.15673/fie.v9i4.745	УПРАВЛІННЯ ПРОФЕСІЙНО-КВАЛІФІКАЦІЙНИМ РОЗВИТКОМ ПРАЦІВНИКІВ НА ПІДПРИЄМСТВАХ ВИНОРОБНОЇ ГАЛУЗІ	2
217	Стаття	В статті розглянуто особливості теорії та практики управління стартапами в Україні. Визначаються проблеми сьогодення, які пов’язані з функціонуванням стартапів, окреслюються шляхи подолання вказаних проблем. Запропоновано системний підхід до підвищен	2017-12-21	217	https://doi.org/10.15673/fie.v9i4.744	УПРАВЛІННЯ СТАРТАПАМИ В УКРАЇНІ: ПРОБЛЕМИ ТА ПЕРСПЕКТИВИ	2
218	Стаття	The article analyzes the condition, the development dynamics and the main problems of the viticulture and winemaking industry in Ukraine and in the world. The particular attention is paid to the causes of the\nemerging situation in the industry and th	2017-12-21	218	https://doi.org/10.15673/fie.v9i4.743	THE ANALYSIS OF VITICULTURE AND WINEMAKING PROBLEMS IN UKRAINE MANAGEMENT OF THE INDUSTRY DEVELOPMENT	2
219	Стаття	В статті розглянуто структуру експорту агропромислової продукції та зміни в географії експортних потоків з України. Проаналізовано можливість вітчизняних підприємств харчової промисловості, в\nтому числі м’ясопереробної галузі, бути конкурентоспроможн	2017-12-21	219	https://doi.org/10.15673/fie.v9i4.742	ПРАВОВЕ ЗАБЕЗПЕЧЕННЯ КОНКУРЕНТОСПРОМОЖНОСТІ ПРОДУКЦІЇ МЯСОПЕРЕРОБНИХ ПІДПРИЄМСТВ УКРАЇНИ НА ЄВРОПЕЙСЬКОМУ РИНКУ	2
220	Стаття	У статті розглянуто та проаналізовано основні базові стратегії розвитку підприємств: стратегія\nконцентрованого зростання, інтегрованого зростання та диверсифікованого зростання. Розглянуто\nсучасний стан виноробної галузі України, її позитивні та нега	2017-12-21	220	https://doi.org/10.15673/fie.v9i4.741	ДОСЛІДЖЕННЯ СТРАТЕГІЙ РОЗВИТКУ НА ПІДПРИЄМСТВАХ ВИНОРОБНОЇ ГАЛУЗІ	2
235	Стаття	In the article the modern state and basic trends in development of meat processing industry are considered within the limits of food industry of Ukraine. The possible prospects of steady development of enterprises of meat processing industry are stud	2017-10-12	235	https://doi.org/10.15673/fie.v9i2.637	MODERN STATE AND TRENDS OF STEADY DEVELOPMENT OF FOOD INDUSTRY ON THE EXAMPLE OF MEAT PROCESSING SECTOR	2
221	Стаття	Проаналізовані підходи до оцінки ризикованості діяльності підприємств та запропонований авторський підхід до проведення оцінки рівня довгострокового ризику на основі аналізу системи показників групи підприємств. Апробація методики була проведена на о	2017-12-21	221	https://doi.org/10.15673/fie.v9i4.740	ОЦІНКА РІВНЯ РИЗИКОВАНОСТІ ДІЯЛЬНОСТІ ПІДПРИЄМСТВ ХЛІБОПЕКАРСЬКОЇ ПРОМИСЛОВОСТІ В ДОВГОСТРОКОВОМУ ПЕРІОДІ	2
222	Стаття	The aim of this article is investigation of the factors of influence of out-of-balance intangible assets\nand other non-monetary factors on the general market value of the enterprises of small, middle-sized and big\nbusiness with the aim of providing t	2017-12-21	222	https://doi.org/10.15673/fie.v9i4.739	THE ESTIMATION OF INFLUENCE OF OUT-OF-BALANCE INTANGIBLE ASSETS ON THE ENTERPRISE MARKET VALUE	2
223	Стаття	The state and efficiency of functioning of food industry in Ukraine on the example of Odessa region\nas an important industry that provides food security of state and affects the state of economy of Ukraine\nhave been considered. The conclusions were m	2017-12-21	223	https://doi.org/10.15673/fie.v9i4.738	ACTIVITY OF FOOD INDUSTRY ENTERPRISES OF ODESSA REGION: STATE AND TRENDS OF DEVELOPMENT	2
224	Стаття	У статті досліджено стан експортно-імпортної діяльності підприємств виноробної промисловості. На основі отриманих результатів виділено сучасні ризики, які необхідно враховувати при антикризовому регулюванні для забезпечення належного рівня експортної	2017-12-21	224	https://doi.org/10.15673/fie.v9i4.737	АНТИКРИЗОВЕ РЕГУЛЮВАННЯ ЕКСПОРТНО-ІМПОРТНОЇ ДІЯЛЬНОСТІ УКРАЇНСЬКОГО ВИНОРОБСТВА	2
225	Стаття	В статті розглянуто основні етапи становлення економічної науки в Одеській національній ака-\nдемії харчових технологій. Зображено процес відкриття спеціальностей економічного профілю, вихо-\nвання висококваліфікованих економічних фахівців, створення е	2017-10-12	225	https://doi.org/10.15673/fie.v9i2.647	ПРО ПЕРСПЕКТИВНІ НАПРЯМИ РОЗВИТКУ ЕКОНОМІЧНОЇ НАУКИ В ОДЕСЬКІЙ НАЦІОНАЛЬНІЙ АКАДЕМІЇ ХАРЧОВИХ ТЕХНОЛОГІЙ: ІСТОРІЯ І СУЧАСНІСТЬ	2
226	Стаття	In the article the analysis of modern approaches is conducted in relation to determination of essence of category "supplies" and their classification with the aim of further implementation of their effective\nadministrative account. It’s underlined, t	2017-10-12	226	https://doi.org/10.15673/fie.v9i2.646	ESSENCE AND CLASSIFICATION OF SUPPLIES OF ENTERPRISE: THEORETICAL AND PRACTICAL ASPECT	2
227	Стаття	У статті досліджено сутність, мету та порядок формування аналізу дебіторської і кредиторської\nзаборгованостей. Встановлено, що дуже велике значення для підприємств мають аналіз і управління\nдебіторською і кредиторською заборгованістю, що функціонують	2017-10-12	227	https://doi.org/10.15673/fie.v9i2.645	ПОРІВНЯЛЬНА ОЦІНКА ДЕБІТОРСЬКОЇ ТА КРЕДИТОРСЬКОЇ ЗАБОРГОВАНОСТІ ПІДПРИЄМСТВ	2
229	Стаття	The article analyzes some aspects of the development of vertically integrated structure of the grain\nsub analyzed national experience of these sub grain structures are considered the most common model of\nintegrated units of the grain market. In moder	2017-10-12	229	https://doi.org/10.15673/fie.v9i2.643	ANALYSIS OF LEGAL FORMS STRUCTURAL ELEMENTS OF GRAIN LOGISTICS	2
230	Стаття	У статті проведено системний аналіз існуючих технологій мотивування персоналу виноробних\nпідприємств, на прикладі ПрАТ «Одесавинпром», запропоновано методику удосконалення системи\nуправління персоналом підприємств виноробної галузі із використанням ч	2017-10-12	230	https://doi.org/10.15673/fie.v9i2.642	УДОСКОНАЛЕННЯ СИСТЕМИ МОТИВАЦІЇ ПЕРСОНАЛУ НА ВІТЧИЗНЯНИХ ПІДПРИЄМСТВАХ ВИНОРОБНОЇ ГАЛУЗІ (НА ПРИКЛАДІ ПрАТ «ОДЕСАВИНПРОМ»)	2
231	Стаття	In the article economic publications on the issues of a concept, classification and efficiency of use of\nthe fixed assets of the enterprise have been considered. The essence of the category "fixed assets" and their\nclassification in the economic lite	2017-10-12	231	https://doi.org/10.15673/fie.v9i2.641	FIXED ASSETS OF THE ENTERPRISE: ASPECTS OF THEORETICAL APPROACHES TO DETERMINATION OF CONCEPT AND EFFICIENCY OF THEIR USE	2
232	Стаття	In the article the analysis of modern approaches has been conducted in relation to determination of\nessence of category "account receivable" and their classification with the aim of further realization of their\neffective administrative accounting and	2017-10-12	232	https://doi.org/10.15673/fie.v9i2.640	ANALYSIS OF APPROACHES TO ESSENCE AND CLASSIFICATION OF ACCOUNT RECEIVABLE OF ENTERPRISE	2
233	Стаття	В статті розглянуто основні тенденції споживання і асортимент зморожених напівфабрикатів\nУкраїні. Під час проведення аналізу були визначені: лідери ринку України, основні проблеми виробни-\nків, чинники, що впливають на розвиток.	2017-10-12	233	https://doi.org/10.15673/fie.v9i2.639	АНАЛІЗ РИНКУ ЗАМОРОЖЕНИХ НАПІВФАБРИКАТІВ УКРАЇНИ	2
234	Стаття	В статті відображено стан комбікормової промисловості, надана характеристика динаміці\nвиробництва комбікормів, проаналізовано зв’язок між поголів’ям худоби та обсягом виготовлення\nкомбікормів. Також обґрунтовані шляхи подальших перспектив розвитку га	2017-10-12	234	https://doi.org/10.15673/fie.v9i2.638	ОГЛЯД РИНКУ КОМБІКОРМОВОЇ ПРОМИСЛОВОСТІ УКРАЇНИ	2
236	Стаття	Досліджено природу доданої вартості у площині чотирьох наукових підходів (відтворювального,\nстатистичного, бухгалтерського та логістичного) з акцентом на її соціально-економічні функції. Розроб-\nлено методику аналізу валової доданої вартості в макрос	2017-10-12	236	https://doi.org/10.15673/fie.v9i2.648	МЕТОДИКА АНАЛІЗУ ВАЛОВОЇ ДОДАНОЇ ВАРТОСТІ В МАКРОСИСТЕМАХ	2
237	Стаття	The article deals with economic ecological problems of energy supply of Ukraine, prospects and\nadvantages of using alternative technologies of heat supply on the base of technologies use of environment\nenergy.	2017-10-04	237	https://doi.org/10.15673/fie.v9i3.633	ALTERNATIVE ENERGY IN THE SYSTEM OF ECONOMIC ECOLOGICAL SAFETY OF THE STATE	2
238	Стаття	The article compares operating and financial leasing, identifies their advantages and also analyzes\nthe stages of the development of leasing. The correspondent accounts of operational and financial leasing\nare provided to lessor and lessee.	2017-10-04	238	https://doi.org/10.15673/fie.v9i3.632	FEATURES OF ACCOUNTING FOR OPERATIONAL AND FINANCIAL LEASING ON ENTERPRISES	2
239	Стаття	Дана стаття присвячена дослідженню фінансових результатів та особливостей формування\nкапіталу провідних агрохолдингів України в сучасних умовах. Проведено аналіз структури капіталу аг-\nрохолдингів України на прикладі Kernel Holding S.A. («Кернел») і	2017-10-04	239	https://doi.org/10.15673/fie.v9i3.631	ОЦІНКА ОПТИМАЛЬНОЇ СТРУКТУРИ КАПІТАЛУ АГРОХОЛДИНГІВ УКРАЇНИ (KERNEL HOLDING S.A., MHP S.A.)	2
240	Стаття	Проведена систематизація наукових підходів до визначення категорії «кадрова безпека». На\nпідставі аналізу джерел визначено поняття склад основних кадрових загроз. Систематизовано види та\nосновні напрямки кадрової політики. Виділено види обліково-анал	2017-10-04	240	https://doi.org/10.15673/fie.v9i3.629	ОБЛІКОВО-АНАЛІТИЧНЕ ЗАБЕЗПЕЧЕННЯ КАДРОВОЇ БЕЗПЕКИ ПІДПРИЄМСТВА	2
241	Стаття	The essence of intraeconomic control has been discovered in the article, the scientists’ points of\nviews have been systematized, the peculiarities and main tasks of this type of control have been considered.\nThe problematic questions, the solving of	2017-10-04	241	https://doi.org/10.15673/fie.v9i3.627	INTRAECONOMIC CONTROL OF THE OPERATION WITH COMMODITY – MATERIAL VALUES	2
242	Стаття	The existing problems of management of debts receivable, which economic entities deal with, have\nbeen considered in the article and the mechanism of management of debts receivable has been stated and\nthe stages of its implementation have been charact	2017-10-04	242	https://doi.org/10.15673/fie.v9i3.626	THE DIRECTIONS OF MANAGEMENT OF THE COMMODITY DEBTS RECEIVABLE	2
243	Стаття	Competitiveness of a product is a main factor for its commercial success in the market with a large\nnumber of manufacturers of similar products. The article describes features of assessment and analysis of\nfood enterprises products. It offers an eval	2017-10-04	243	https://doi.org/10.15673/fie.v9i3.625	COMPETITIVENESS OF UKRAINIAN FOOD ENTERPRISES. FEATURES OF ASSESSMENT.	2
257	Стаття	The world experience of viticulture development and winemaking is analyzed in this article. It is established that the experience of Italy is the most acceptable example for Ukrainian winegrowers. The analysis of wine industry development in Ukraine	2017-05-29	257	https://doi.org/10.15673/fie.v9i1.451	THE DEVELOPING TRENDS OF THE ITALIAN AND UKRAINIAN VITICULTURE AND WINERIES	2
244	Стаття	У статті розглянуто та обґрунтовано закономірний і безумовний взаємозв’язок таких ринкових\nкатегорій, як «привабливість харчового бізнесу» та «конкурентоспроможність персоналу». Персонал,\nщо є задіяним у цьому виді бізнесу, формує певні рівні іміджу,	2017-10-04	244	https://doi.org/10.15673/fie.v9i3.624	ВПЛИВ КОНКУРЕНТОСПРОМОЖНОСТІ ПЕРСОНАЛУ НА ПРИВАБЛИВІСТЬ ХАРЧОВОГО БІЗНЕСУ	2
245	Стаття	Approaches to the definition of essence of strategic management accounting in scientific works of\nnational and foreign scientists are considered. The objective necessity of its application at the enterprises of\nUkraine in the current conditions of th	2017-10-04	245	https://doi.org/10.15673/fie.v9i3.623	STRATEGIC MANAGEMENT ACCOUNTING AS A TOOL TO PROMOTE COMPETITIVENESS AND EFFICIENCY OF THE ACTIVITY OF THE ENTERPRISE	2
246	Стаття	Досліджено природу доданої вартості у секторному та ринковому вимірі, розроблено теорію ко-\nлообігу секторної доданої вартості в мезосистемі з акцентом на головні етапи її руху (процеси форму-\nвання й використання), міжсекторний перерозподіл та проти	2017-10-04	246	https://doi.org/10.15673/fie.v9i3.621	ВІДТВОРЮВАЛЬНИЙ МЕТОДИЧНИЙ ПІДХІД ДО ОЦІНКИ ЕФЕКТИВНОСТІ ІНТЕГРОВАНИХ ТОВАРНИХ РИНКІВ	2
247	Стаття	Проаналізовано маркетингові підходи дослідження ринку при розробці та впровадженні това-\nру, досліджено ринок алкогольних напоїв на прикладі коньяку, проаналізовано мікро- та макросередо-\nвище ПрАТ «Одесавинпром», проведено аналіз конкурентного серед	2017-10-04	247	https://doi.org/10.15673/fie.v9i3.620	МАРКЕТИНГОВІ АСПЕКТИ РОЗВИТКУ ВІТЧИЗНЯНОГО КОНЬЯЧНОГО ВИРОБНИЦТВА В УМОВАХ КРИЗИ	2
248	Стаття	У статті досліджено питання товарної та географічної структури експорту агропродовольчих\nтоварів, які останніми роками становляться головними в загальному експорті. Розглянуто основні на-\nпрями експортних потоків агропродовольчих товарів в розрізі чо	2017-10-04	248	https://doi.org/10.15673/fie.v9i3.619	АНАЛІЗ ДИНАМІКИ ТА СТРУКТУРИ ЕКСПОРТУ АГРОПРОДОВОЛЬЧОЇ ПРОДУКЦІЇ	2
249	Стаття	The article highlights the historical preconditions and principles of sustainable development of the\nagri-food sphere. The analysis of the evolution of the categorical content of sustainable development is\ncarried out. It has been noted that the main	2017-10-04	249	https://doi.org/10.15673/fie.v9i3.618	THEORETICAL FOUNDATIONS OF SUSTAINABLE DEVELOPMENT OF THE AGRI-FOOD SPHERE	2
250	Стаття	The article deals with the procedure for determining the structure of the financial results of\nenterprises, search for sources of increasing profits. It is shown that the economic policy of the government\nleads to the bankruptcy of small and medium-s	2017-05-29	250	https://doi.org/10.15673/fie.v9i1.493	SANITATION  AUDIT AS A TOOL FOR MANAGING THE FINANCIAL RESULTS OF THE COMPANY	2
251	Стаття	В статье рассматриваются психологические механизмы деятельности управленческих команд, основные этапы их становления и развития. Особое внимание уделено особенностям их функционирования на предприятиях пищевой отрасли, подчёркивается их взаимосвязь с	2017-05-29	251	https://doi.org/10.15673/fie.v9i1.492	ПСИХОЛОГИЧЕСКИЕ ОСОБЕННОСТИ ФУНКЦИОНИРОВАНИЯ УПРАВЛЕНЧЕСКИХ КОМАНД НА ПРЕДПРИЯТИЯХ ПИЩЕВОЙ ОТРАСЛИ	2
252	Стаття	The article describes the importance and scientific approaches to the essence of the environmental\ncomponent of sustainable development of agricultural sphere of the region. The main environmental problems in the agri-food sphere of the Southern regi	2017-05-29	252	https://doi.org/10.15673/fie.v9i1.491	THE ECOLOGICAL COMPONENT OF SUSTAINABLE DEVELOPMENT IN THE AGRI-FOOD SPHERE OF THE SOUTHERN REGION	2
253	Стаття	Досліджено економічні категорії: витрати виробництва, об’єкти обліку витрат, собівартість продукції, основна продукція, супутня продукція, побічна продукція та безповоротні відходи. Висвітлено\nтехнологію і організацію забою тварин у забійному цеху та	2017-05-29	253	https://doi.org/10.15673/fie.v9i1.489	ПСИХОЛОГИЧЕСКИЕ ОСОБЕННОСТИ ФУНКЦИОНИРОВАНИЯ УПРАВЛЕНЧЕСКИХ КОМАНД НА ПРЕДПРИЯТИЯХ ПИЩЕВОЙ ОТРАСЛИ	2
254	Стаття	This article explores the current state of the grain industry in Ukraine, the main problems and trends\nof its development in the current economic conditions. The export potential of grain production has been investigated, economic feasibility and pro	2017-05-29	254	https://doi.org/10.15673/fie.v9i1.483	TRENDS IN THE GRAIN MARKET OF UKRAINE	2
255	Стаття	У статті розглянута необхідність організації шкільного харчування як одного з основних чинників підтримки здоров'я дітей. Наведені приклади організації харчування школярів за кордоном. Проаналізовано стан організації харчування школярів в Україні та	2017-05-29	255	https://doi.org/10.15673/fie.v9i1.482	ДОСЛІДЖЕННЯ РИНКУ ГРОМАДСЬКОГО ХАРЧУВАННЯ УКРАЇНИ НА ПРИКЛАДІ ОРГАНІЗАЦІЇ ХАРЧУВАННЯ ШКОЛЯРІВ	2
256	Стаття	Обґрунтовано методологічний підхід до цінового моніторингу товарного ринку, що поєднав концептуальний і методичний базиси, циклічну природу системи цінового моніторингу та її складові. Запропоновано методичний підхід до цінового моніторингу ринку з а	2017-05-29	256	https://doi.org/10.15673/fie.v9i1.481	МЕТОДИЧНИЙ ПІДХІД ДО ЦІНОВОГО МОНІТОРИНГУ ТОВАРНОГО РИНКУ (НА ПРИКЛАДІ РИНКУ ХЛІБОПРОДУКТІВ)	2
258	Стаття	У статті досліджуються проблеми ефективності функціонування фінансової системи України,\nяка відіграє надзвичайно важливу роль у розвитку суспільства. Сформульовані завдання, вирішення\nяких дозволить оптимізувати фінансову систему держави. Обґрунтован	2017-05-29	258	https://doi.org/10.15673/fie.v9i1.488	ПРОБЛЕМИ ЕФЕКТИВНОСТІ ФУНКЦІОНУВАННЯ ФІНАНСОВОЇ СИСТЕМИ	2
259	Стаття	В роботі проведено системне дослідження напрямів впровадження стратегії диверсифікації та\nкомплексу заходів щодо впровадження даної стратегії на підприємствах виноробної галузі, а також її\nефективного використання для забезпечення конкурентоспроможно	2017-05-29	259	https://doi.org/10.15673/fie.v9i1.487	ДОСЛІДЖЕННЯ НАПРЯМІВ ВПРОВАДЖЕННЯ СТРАТЕГІЇ ДИВЕРСИФІКАЦІЇ НА ПІДПРИЄМСТВАХ ВИНОРОБНОЇ ГАЛУЗІ	2
260	Стаття	In the article the essence of crisis management of Ukrainian food enterprises is considered in the conditions of economic transformations, the features of display of crisis and influence of factors of external and internal environment are certain on	2017-05-29	260	https://doi.org/10.15673/fie.v9i1.486	CRISIS MANAGEMENT OF FOOD ENTERPRISES	2
261	Стаття	The article describes the main factors that affect the competitiveness and efficiency of enterprises including small business enterprises in the food industry. The study of the stages of regular activities of the\nenterprise was made and the classific	2017-05-29	261	https://doi.org/10.15673/fie.v9i1.484	ANALYSIS AND STRUCTURING OF EXTERNAL AND INTERNAL FACTORS OF INFLUENCE ON COMPETITIVENESS OF ENTERPRISE	2
262	Стаття	В даній статті виділено напрями організації експертних досліджень на підприємстві. Узагальнено інформацію щодо видів експертиз для ідентифікації фінансово-економічних правопорушень з\nвизначенням очікуваного результату від експертизи. Проведена систем	2017-05-21	262	https://doi.org/10.15673/fie.v8i4.463	ЕКСПЕРТНЕ ПІДТВЕРДЖЕННЯ ОБЛІКОВО-АНАЛІТИЧНОЇ ІНФОРМАЦІЇ	2
307	Стаття	The animal husbandry cannot develop successfully without complete balanced feed and optimal forage supply. This article deals with the chemical composition of chlorella suspension. The ration is balanced with seaweeds as well as premixes, vitamins a	2019-04-26	307	https://doi.org/10.15673/gpmf.v19i1.1321	CHLORELLA SUSPENSION AND ITS USAGE IN FINISHING PIGS’ RATIONS	3
263	Стаття	Статтю присвячено дослідженню ефективності банківського кредитування малого та середньо-\nго бізнесу в Україні. Проаналізовано кількість та якість наданих кредитів суб’єктам господарювання;\nрозглянуто суми наданих кредитів в розрізі областей та сектор	2017-05-21	263	https://doi.org/10.15673/fie.v8i4.462	ЕФЕКТИВНІСТЬ БАНКІВСЬКОГО КРЕДИТУВАННЯ МАЛОГО ТА СЕРЕДНЬОГО БІЗНЕСУ В УКРАЇНІ	2
264	Стаття	Здійснено аналіз динаміки відтворювальних процесів у секторах вітчизняного ринку макаронних виробів, визначено вектори сучасних інтеграційних процесів у системі вертикально суміжних до макаронного ринку, ідентифіковано прояви латентної дезінтеграції	2017-05-21	264	https://doi.org/10.15673/fie.v8i4.456	ІНТЕГРАЦІЙНІ ТЕНДЕНЦІЇ ТА ПРОБЛЕМИ РОЗВИТКУ УКРАЇНСЬКОГО РИНКУ МАКАРОННИХ ВИРОБІВ	2
265	Стаття	В даній статті розглянуті теоретико-методичні основи щодо вдосконалення стратегічного\nуправління у виноробній галузі України. У зв’язку з помилками, яки були допущені в аграрній політиці\nУкраїни, виноградарство із високорентабельної галузі перетворил	2017-05-21	265	https://doi.org/10.15673/fie.v8i4.461	ДОСЛІДЖЕННЯ СУЧАСНОГО СТАНУ ТА НАПРЯМІВ ПОБУДОВИ СТРАТЕГІЇ ВІДНОВЛЕННЯ ВИНОГРАДАРСТВА ТА ВИНОРОБСТВА В УКРАЇНІ	2
266	Стаття	У статті запропоновано ресурсний підхід як основа реалізації функціональних стратегій підприємств харчової промисловості. На основі мікроекономічної теорії розроблені критерії та послідовність реалізації функціональних стратегій підприємств.	2017-05-21	266	https://doi.org/10.15673/fie.v8i4.460	ФОРМУВАННЯ РЕСУРСНОЇ СТРАТЕГІЇ ПІДПРИЄМСТВА	2
267	Стаття	У статті проаналізовано тенденції роботи зернопереробних підприємств України. Розглянуто економічні та організаційні умови в яких працюють великі підприємства по переробці зерна та мінімлини. Акцентовано увагу на негативних явищах, що впливають на ро	2017-05-21	267	https://doi.org/10.15673/fie.v8i4.459	ТЕНДЕНЦІЇ РОБОТИ ЗЕРНОПЕРЕРОБНИХ ПІДПРИЄМСТВ УКРАЇНИ	2
268	Стаття	В статті розглянуто сутність та теоретичні основи комплексних систем управління підприємства.\nЗдійснено аналіз концептуальних підходів щодо оцінювання ефективності - EVA (Economic Value Added,\nEVA). Запропоновано показник «норма доданої вартості на а	2017-05-21	268	https://doi.org/10.15673/fie.v8i4.458	СУЧАСНІ КОМПЛЕКСНІ СИСТЕМИ ОЦІНЮВАННЯ ЕФЕКТИВНОСТІ ГОСПОДАРСЬКОЇ ДІЯЛЬНОСТІ ПІДПРИЄМСТВА	2
318	Стаття	The high efficiency of poultry and pigs is based on high-yielding breeds, balanced high-yielding mixed fodders and appropriate animal holding conditions. Recently, the tendency of increasing the efficiency of the nutritional potential of mixed fodde	2019-01-17	318	https://doi.org/10.15673/gpmf.v18i4.1194	USE OF BIOLOGICALLY ACTIVE SUBSTANCES OF THE HYDROLASE CLASS IN COMPOUND FEED FOR PIGS	3
269	Стаття	В статті було розглянуто сутність категорії «конкурентоспроможність», яка представлена в публікаціях вітчизняних та іноземних вчених, об’єктів та рівнів дослідження, при дослідженні зроблено акцент саме на «конкурентоспроможність підприємства». Підкр	2017-05-21	269	https://doi.org/10.15673/fie.v8i4.457	КОНКУРЕНТОСПРОМОЖНІСТЬ: СУТНІСТЬ ТА ОБ’ЄКТИ ДОСЛІДЖЕННЯ	2
270	Стаття	В статті розглянуто роль i значення переробної та зберігаючої галузей в забезпеченні продовольчої безпеки країни, внесок третьої сфери АПК у вирішення продовольчої проблеми, забезпечення\nнаселення повноцінною та здоровою їжею у відповідності до загал	2017-05-21	270	https://doi.org/10.15673/fie.v8i4.455	ЗНАЧЕННЯ ПЕРЕРОБНОЇ ПРОМИСЛОВОСТІ В ЗАБЕЗПЕЧЕННІ ПРОДОВОЛЬЧОЇ БЕЗПЕКИ КРАЇНИ	2
271	Стаття	В статті визначено сутність і передумови формування кластерів. Здійснено аналіз концептуальних підходів до формування і розвитку кластерів. Зосереджено увагу на доцільності створення і функціонування кластерів у агропродовольчій сфері Південного регі	2017-05-21	271	https://doi.org/10.15673/fie.v8i4.454	СТАЛИЙ РОЗВИТОК АГРОПРОДОВОЛЬЧОЇ СФЕРИ РЕГІОНУ НА ОСНОВІ КЛАСТЕРНОГО ПІДХОДУ	2
272	Стаття	В статті розглянуто передумови розвитку економіки вражень як сучасного етапу суспільного виробництва; визначено сутність кінцевих та проміжних послуг сфери гостинності та кінцевого її продукту; досліджено логістичні ланцюги сфери гостинності, що форм	2017-05-21	272	https://doi.org/10.15673/fie.v8i4.453	ЕКОНОМІКА ВРАЖЕНЬ – СУЧАСНИЙ ЕТАП РОЗВИТКУ СУСПІЛЬНОГО ВИРОБНИЦТВА	2
273	Стаття	В статье рассматривается актуальная роль психолого-педагогических знаний, в модернизируемом образовательном процессе высшей школы, при формировании менеджерского потенциала будущих специалистов. Описаны подходы гармонизирующие межличностные отношени	2016-09-30	273	https://doi.org/10.15673/fie.v8i3.211	ПСИХОЛОГИЧЕСКИЕ АСПЕКТЫ МЕНЕДЖЕРСКОГО ПОТЕНЦИАЛА СТУДЕНТОВ ТЕХНИЧЕСКОГО ВУЗА	2
350	Стаття	Despite successes, many problems are encountered with small-seed crops (sorghum, turnip, mustard, linen, etc.), for many of them there are not enough recommendations of regulations and other normative and technological documentation. The article is	2018-07-09	350	https://doi.org/10.15673/gpmf.v18i2.949	FEATURES OF THE TECHNOLOGICAL LINE OF THERMAL PROCESSING OF SMALL-SEEDED CROPS	3
274	Стаття	С гуманистических позиций анализируются проблемы современных парадигм социотехнической деятельности и подготовки инженерно-экономических кадров. Установлена теоретическая и практическая возможность рационального формирования парадигм социотехнической	2016-09-30	274	https://doi.org/10.15673/fie.v8i3.210	ПАРАДИГМЫ СОЦИОТЕХНИЧЕСКОЙ ДЕЯТЕЛЬНОСТИ И ПОДГОТОВКА ИНЖЕНЕРНО-ЭКОНОМИЧЕСКИХ КАДРОВ В XXI ВЕКЕ	2
275	Стаття	Надана характеристика підприємств малого та середнього бізнесу, представлені їх класифіка-ційні ознаки. Систематизовано основні фактори впливу на ведення бухгалтерського обліку на малих підприємствах. Виділено основні проблеми та напрями удосконаленн	2016-09-30	275	https://doi.org/10.15673/fie.v8i3.209	ПРОБЛЕМИ ОРГАНІЗАЦІЇ БУХГАЛТЕРСЬКОГО ОБЛІКУ НА ПІДПРИЄМСТВАХ МАЛОГО БІЗНЕСУ	2
276	Стаття	У статті досліджено можливості використання комп’ютерних інформаційних систем в аудиті. Визначено суть комп’ютерного аудиту в системі обробки бухгалтерської інформації. Проаналізовано переваги та недоліки застосування інформаційних систем в аудиті. З	2016-09-30	276	https://doi.org/10.15673/fie.v8i3.208	ОСОБЛИВОСТІ АУДИТУ В КОМП’ЮТЕРНОМУ СЕРЕДОВИЩІ	2
277	Стаття	У статті досліджено особливості використання комп’ютерних інформаційних технологій в сис-темі обліку та контролю в сфері підприємницької діяльності. Проаналізовано переваги та недоліки їх застосування в процесі ведення та прийняття рішень щодо управл	2016-09-30	277	https://doi.org/10.15673/fie.v8i3.207	ОСОБЛИВОСТІ ВИКОРИСТАННЯ ІНФОРМАЦІЙНИХ СИСТЕМ І ТЕХНОЛОГІЙ В СИСТЕМІ ОБЛІКУ ТА КОНТРОЛЮ	2
278	Стаття	Cтаттю присвячено розгляду шляхів підвищення інвестиційної привабливості підприємств хар-чової промисловості. Визначаються проблеми сьогодення при залученні інвестицій до сектору харчо-вої промисловості. Обґрунтовано доцільність застосування управлін	2016-09-30	278	https://doi.org/10.15673/fie.v8i3.206	ПРО ШЛЯХИ ВДОСКОНАЛЕННЯ УПРАВЛІННЯ ІНВЕСТИЦІЙНОЮ ПРИВАБЛИВІСТЮ ПІДПРИЄМСТВ ХАРЧОВОЇ ПРОМИСЛОВОСТІ	2
301	Стаття	У статті наведено характеристики мікроблогінгу Twitter як частини загальної системи інтернет-маркетингу: його особливості, інструменти та методи. Приведені дані стану проникнення Twitter у жит-тя населення України та характерні риси його функціонуван	2016-07-29	301	https://doi.org/10.21691/fie.v8i1.57	TWITTER ЯК ЕЛЕМЕНТ ІНТЕРНЕТ-МАРКЕТИНГУ	2
279	Стаття	У статті акцентовано увагу на низці важливих питань, пов’язаних з з процесом адаптації до но-вих та постійно мінливих умов господарювання підприємств харчової промисловості. В роботі проана-лізовані завдання подальшого удосконалення управління потенц	2016-09-30	279	https://doi.org/10.15673/fie.v8i3.205	АДАПТИВНЕ УПРАВЛІННЯ ПОТЕНЦІАЛОМ СТАЛОГО РОЗВИТКУ ПІДПРИЄМСТВ ХАРЧОВОЇ ПРОМИСЛОВОСТІ	2
280	Стаття	В данной статье рассмотрены проблемы налоговой системы Украины и высоких ставок налогов, что приводит к увеличению доли теневой экономики. Рассмотрены налог на добавленную стоимость и налог на доходы физических лиц. Также были описаны методы по оптим	2016-09-30	280	https://doi.org/10.15673/fie.v8i3.204	ПРОБЛЕМЫ НАЛОГОВОЙ СИСТЕМЫ УКРАИНЫ	2
281	Стаття	В статті розглянуто основні тенденції у споживанні вина у світі та в Україні. Розглянуто види спеціалізованих торговельних підприємств, що пропонують алкогольну продукцію. Визначено основні сили впливу на них за методикою п’яти конкурентних сил М.Пор	2016-09-30	281	https://doi.org/10.15673/fie.v8i3.202	СТАН КОНКУРЕНЦІЇ НА РОЗДРІБНОМУ РИНКУ АЛКОГОЛЬНИХ НАПОЇВ	2
282	Стаття	Визначено вплив суб’єктів корпоративного та індивідуального секторів на відтворювальний роз-виток стратегічного зернового ринку України. Обґрунтовано методичний підхід до оцінки відтворюваль-ної ефективності збутових каналів, що базується на порівнял	2016-09-30	282	https://doi.org/10.15673/fie.v8i3.201	Визначено вплив суб’єктів корпоративного та індивідуального секторів на відтворювальний роз-виток стратегічного зернового ринку України. Обґрунтовано методичний підхід до оцінки відтворюваль-ної ефективності збутових каналів, що базується на порівняльному	2
283	Стаття	В статье рассматриваются основные проблемы социально-психологической адаптации лич-\nности, проанализированы еѐ механизмы и особенности на предприятиях пищевой промышленности.\nОтмечено, что первоочередной задачей руководители предприятий пищевой промы	2016-08-21	283	https://doi.org/10.15673/fie.v8i2.135	СОЦИАЛЬНО-ПСИХОЛОГИЧЕСКИЕ МЕХАНИЗМЫ АДАПТАЦИИ СПЕЦИАЛИСТОВ НА ПРЕДПРИЯТИЯХ ПИЩЕВОЙ ОТРАСЛИ	2
284	Стаття	У статті розглянута специфіка ділового спілкування. Ділове спілкування підкорено інтересам\nсправи, успішність якої залежить від дотримання правил правового характеру і правил міжособистіс-\nного спілкування. Авторами визначено моделі ділового спілкува	2016-08-21	284	https://doi.org/10.15673/fie.v8i2.134	ДІЛОВЕ СПІЛКУВАННЯ: ОСОБЛИВОСТІ СУЧАСНОЇ КОМУНІКАЦІЇ	2
285	Стаття	Основною метою статті є розробка теоретичних та практичних рекомендацій, щодо вдоскона-\nлення застосування системи бюджетування як інструменту управління витратами на підприємстві.\nПредставлено метод бюджетування як інструмент для формування бюджетів	2016-08-21	285	https://doi.org/10.15673/fie.v8i2.132	ТЕОРЕТИЧНІ АСПЕКТИ ВПРОВАДЖЕННЯ МЕТОДУ БЮДЖЕТУВАННЯ ВИТРАТ НА ВИРОБНИЦТВО	2
286	Стаття	У статті досліджується роль фінансового механізму забезпечення стійкого розвитку підприємс-\nтва, обґрунтовується необхідність забезпечення збалансованості між цілями підприємства й умовами\nзовнішнього і внутрішнього середовища. Визначено складові під	2016-08-21	286	https://doi.org/10.15673/fie.v8i2.131	ФІНАНСОВИЙ МЕХАНІЗМ СТІЙКОГО РОЗВИТКУ ПІДПРИЄМСТВА	2
287	Стаття	У статті розглядаються основні аспекти використання інноваційних технологій мотивації пер-\nсоналу. Пропонується системний підхід до формування мотивації персоналу, виділено основні прин-\nципи формування ефективної системи мотивації персоналу з урахув	2016-08-21	287	https://doi.org/10.15673/fie.v8i2.130	ФОРМУВАННЯ СИСТЕМИ МОТИВАЦІЇ ПЕРСОНАЛУ ВИНОРОБНИХ ПІДПРИЄМСТВ НА ЗАСАДАХ ІННОВАЦІЙНИХ ТЕХНОЛОГІЙ	2
288	Стаття	Узагальнено наукові підходи до визначення сутності категорій «управлінська праця» та «орга-\nнізація управлінської праці», в результаті чого сформульовано їх авторське визначення. Проаналізо-\nвано систему організації управлінської праці в державному п	2016-08-21	288	https://doi.org/10.15673/fie.v8i2.129	УПРАВЛІНСЬКА ПРАЦЯ ТА УДОСКОНАЛЕННЯ ЇЇ ОРГАНІЗАЦІЇ В АГРАРНИХ ПІДПРИЄМСТВАХ	2
289	Стаття	У статті розглянуто основні тенденції виробництва і споживання риби та рибної продукції в Україні. Під час проведення аналізу були визначені основні проблемні моменти функціонування ри-бопереробних підприємств України. Виявлено перспективи подальшого	2016-08-21	289	https://doi.org/10.15673/fie.v8i2.127	ОСНОВНІ ТЕНДЕНЦІЇ ВИРОБНИЦТВА І СПОЖИВАННЯ РИБИ ТА РИБНОЇ ПРОДУКЦІЇ В УКРАЇНІ	2
290	Стаття	В статті виділено внутрішні та зовнішні загрози продовольчої безпеки України та запропонова-ні напрями забезпечення продовольчої безпеки країни. Охарактеризовані основні загрози продоволь-чої безпеки України, визначено особливості їх впливу	2016-08-21	290	https://doi.org/10.15673/fie.v8i2.126	ЗОВНІШНІ ТА ВНУТРІШНІ ЗАГРОЗИ ПРОДОВОЛЬЧОЇ БЕЗПЕКИ	2
291	Стаття	Визначено змістовну сутність категорії «стійкий відтворювальний розвиток». Обґрунтовано кон-цептуальний підхід до селективного регулювання відтворювальних процесів у системі вертикально су-міжних ринків зерна та продуктів його переробки, що органічно	2016-08-21	291	https://doi.org/10.15673/fie.v8i2.125	КОНЦЕПТУАЛЬНИЙ ПІДХІД ДО СЕЛЕКТИВНОГО РЕГУЛЮВАННЯ ВІДТВОРЮВАЛЬНИХ ПРОЦЕСІВ У СИСТЕМІ СУМІЖНИХ РИНКІВ ЗЕРНА ТА ПРОДУКТІВ ЙОГО ПЕРЕРОБКИ	2
292	Стаття	озглянуті сучасні проблеми та тенденції світового та українського ринків продукції виноробст-ва. Показані зміни площ виноградних насаджень у світі. Виділені та проаналізовані нові лідери в світо-вій виноробній галузі. Зображений стан розвитку виногра	2016-08-21	292	https://doi.org/10.15673/fie.v8i2.124	ЕНДЕНЦІЇ РОЗВИТКУ СВІТОВОГО ТА УКРАЇНСЬКОГО РИНКУ ПРОДУКЦІЇ ВИНОРОБСТВА В СУЧАСНИХ УМОВАХ	2
293	Стаття	Закони ринкової економіки, що увійшли в останні десятиліття в наше життя, багато в чому змі-\nнили психологію людей, сформувавши нові погляди, нові типи відносин і нові установки в свідомості\nлюдей – коли вірні, а коли і ні. В країнах, які пішли далек	2016-08-21	293	https://doi.org/10.15673/fie.v8i2.133	СУЧАСНИЙ КЕРІВНИК-ЛІДЕР – ЦЕ ПСИХОЛОГ І ВМІЛИЙ ПЕДАГОГ	2
294	Стаття	У статті досліджується можливість оптимізації випуску продукції в рамках виробничої функції Кобба-Дугласа і функції з постійною еластичністю заміщення ресурсів. Визначається оптимальна фо-ндоозброєність, що забезпечує максимізацію випуску продукції.	2016-08-21	294	https://doi.org/10.15673/fie.v8i2.128	ПТИМІЗАЦІЯ ФОНДООЗБРОЄНОСТІ НА ПІДПРИЄМСТВАХ ХАРЧОВОЇ ПРОМИСЛОВОСТІ НА ОСНОВІ ВИРОБНИЧИХ ФУНКЦІЙ	2
295	Стаття	Надана розгорнута характеристика внутрішньогосподарської звітності підприємства. Дослі-джено та проаналізовано її різні категорії з авторським узагальненням. Систематизовано звітну внут-рішню інформацію промислового підприємства. Виділено категорії р	2016-07-29	295	https://doi.org/10.21691/fie.v8i1.69	ВНУТРІШНЬОГОСПОДАРСЬКА ЗВІТНІСТЬ В СИСТЕМІ УПРАВЛІННЯ БІЗНЕСОМ	2
296	Стаття	У статті розглянуті проблеми фінансової децентралізації. Визначені джерела фінансування мі-сцевих бюджетів та з’ясовані шляхи покращення соціального розвитку регіонів. Запропоновано розра-хунок доходів регіонального бюджету на кількість населення, за	2016-07-29	296	https://doi.org/10.21691/fie.v8i1.68	ПРОБЛЕМИ ФІНАНСОВОЇ ДЕЦЕНТРАЛІЗАЦІЇ В УКРАЇНІ	2
297	Стаття	У статті досліджується сучасний стан та основні тенденції інноваційної діяльності підприємств харчової промисловості та її місце в промисловості України, розкриваються основні проблеми іннова-ційного розвитку. Також виявляються задачі, вирішення яких	2016-07-29	297	https://doi.org/10.21691/fie.v8i1.67	РОЗВИТОК ІННОВАЦІЙНОЇ ДІЯЛЬНОСТІ НА ПІДПРИЄМСТВАХ ХАРЧОВОЇ ПРОМИСЛОВОСТІ	2
298	Стаття	У статті розглянуто окремі аспекти стратегії розвитку виноробної галузі України, необхідність створення бюро з маркетингу винограду і вина України, вплив розвитку винного туризму на підвищен-ня культури споживання вина та на розвиток виноробної галуз	2016-07-29	298	https://doi.org/10.21691/fie.v8i1.66	ІННОВАЦІЙНІ СКЛАДОВІ СТРАТЕГІЧНОГО РОЗВИТКУ ВИНОРОБНИХ ПІДПРИЄМСТВ УКРАЇНИ	2
299	Стаття	В статье проанализированы основные научные работы, касающиеся сферы инноваций и ин-новационного развития. Доказана необходимость введения методов бизнес-процессов на предпри-ятиях хранения зерна в современных условиях, определены основные бизнес-проц	2016-07-29	299	https://doi.org/10.21691/fie.v8i1.65	УПРАВЛЕНЧЕСКИЕ ИННОВАЦИИ И ОСОБЕННОСТИ ИХ ПРИМЕНЕНИЯ НА ПРЕДПРИЯТИЯХ ХРАНЕНИЯ И ПЕРЕРАБОТКИ ЗЕРНА	2
300	Стаття	У статті досліджено теоретико-правові основи організації технічного обслуговування та ремон-ту техніки. Розглянуто еволюцію розвитку сфери агротехнічного сервісного обслуговування в Україні та визначено шляхи розвитку названої сфери	2016-07-29	300	https://doi.org/10.21691/fie.v8i1.61	У статті досліджено теоретико-правові основи організації технічного обслуговування та ремон-ту техніки. Розглянуто еволюцію розвитку сфери агротехнічного сервісного обслуговування в Україні та визначено шляхи розвитку названої сфери.	2
302	Стаття	В статті розглянуто теоретичні основи державної політики розвитку туризму з використанням маркетингу в управлінні цією галуззю економіки. Запропоновано створення на основі специфічних фу-нкцій, методів, інструментів комплексної моделі реалізації держ	2016-07-29	302	https://doi.org/10.21691/fie.v8i1.55	ТЕОРЕТИЧНІ ОСНОВИ ДЕРЖАВНОЇ ПОЛІТИКИ РОЗВИТКУ ТУРИЗМУ НА ОСНОВІ МАРКЕТИНГОВОГО ПІДХОДУ В УПРАВЛІННІ	2
303	Стаття	У статті досліджено сутність ефективності праці як складової ефективності виробництва, а та-кож шляхи її підвищення. Для досягнення мети підприємством необхідно, з одного боку, створювати та застосовувати мотиваційний механізм для кожного працівника,	2016-07-29	303	https://doi.org/10.21691/fie.v8i1.54	ВНУТРІШНІЙ КОНТРОЛЬ ЕФЕКТИВНОСТІ ПРАЦІ НА ПІДПРИЄМСТВАХ ХАРЧОВОЇ ПРОМИСЛОВОСТІ	2
304	Стаття	Розглянуто підходи до щодо оцінювання ефективності діяльності, як окремого підприємства, так й їх об’єднань, а також доцільності створення агропромислового формування, як механізму забез-печення ефективності та конкурентоспроможності підприємств харч	2016-07-29	304	https://doi.org/10.21691/fie.v8i1.51	ЕФЕКТИВНІСТЬ ДІЯЛЬНОСТІ ПІДПРИЄМСТВ ТА ЇХ ОБ’ЄДНАНЬ: АНАЛІЗ, МОНІТОРИНГ, ЗАБЕЗПЕЧЕННЯ	2
305	Стаття	Устаттірозглянутоосновніпоказники,якіформуютьпозитивнийгудвілтуристичногопідприєм-стватаїхвпливнаконкурентоспроможність.Обґрунтованопотенціалгудвілу,яксукупністьхарактер-нихповедінковихристуристичноїкомпанії,напрацьованихзачасїїперебуваннянатуристичн	2016-07-29	305	https://doi.org/10.21691/fie.v8i1.38	ВЛИВ ГУДВІЛУ НА ПІДВИЩЕННЯ  КОНКУРЕНТОСПРОМОЖНОСТІ У ТУРИЗМІ	2
306	Стаття	Визначеноконцептуальнусутністьдефініцій«суміжнийринок»і«системавертикальносуміжних ринків».Розробленорозширенукласифікаціюсистемвертикальносуміжнихринківзернатапродуктів йогопереробки.Побудованоструктурнумодельвідтворювальноїсистемисуміжнихдозерновог	2016-07-29	306	https://doi.org/10.21691/fie.v8i1.33	ТЕОРЕТИЧНІ ЗАСАДИ РОЗВИТКУ СИСТЕМ ВЕРТИКАЛЬНО СУМІЖНИХ РИНКІВ ЗЕРНА ТА ПРОДУКТІВ ЙОГО ПЕРЕРОБКИ (ІНТЕГРАЦІЙНИЙ ПІДХІД)	2
308	Стаття	The article is devoted to the problems of determining quality and safety of extruded feed additive (EFA) with algae. It is used in the production of mixed feed and premixes. It is proved that the safety of finished food products depends on the safet	2019-04-26	308	https://doi.org/10.15673/gpmf.v19i1.1320	USING OF BIOTESTING IN SAFTY ASSESMENT OF THE EXTRUDED FEED ADDITIVE WITH ALGAE	3
309	Стаття	The article states that industrial fish farming in inland waters has become increasingly important in the recent years and it is one of the sources for satisfying the needs of people in the high-protein foods. The fish meat is an extremely rich sour	2019-04-26	309	https://doi.org/10.15673/gpmf.v19i1.1319	THE CHARACTERISTIC OF COMPOUND FEEDS FOR CLARIAS GARIEPINUS	3
310	Стаття	This paper presents the features of corn as raw material for groat industry. Corn is used in many segments of the food and\nprocessing industry. corn is processed for traditional food products — groats, flakes, flour, extruded foods, and other corn b	2019-04-24	310	https://doi.org/10.15673/gpmf.v19i1.1318	FEATURES OF CORN CONSUMPTION IN THE FOOD PRODUCTION INDUSTRY	3
311	Стаття	Research in the article is aimed to determining the quality of flour from different systems of the technological process of a wheat milling. Samples of flour were obtained at the mill "Rivne Boroshno". Private enterprise "Rivne Boroshno" is one of t	2019-04-24	311	https://doi.org/10.15673/gpmf.v19i1.1317	ANALYSIS OF THE QUALITY OF FLOUR FROM DIFFERENT SYSTEMS OF THE TECHNOLOGICAL PROCESS OF A FLOUR MILL	3
312	Стаття	In Ukraine, as the raw material for the production of cereals, flour, flakes, the following main crops are used: wheat,\nbarley, buckwheat, oats, corn, rice, millet, peas. The volume of world grain production has grown significantly in recent\nyears.	2019-04-24	312	https://doi.org/10.15673/gpmf.v19i1.1316	STUDY OF MOISTURE ABSORPTION OF SWEET CORN GRAIN OF DIFFERENT FRACTIONS	3
313	Стаття	In recent decades, in addition to the traditional grain storage in dry conditions, the technology of grain storage without access of air - in hermetic conditions has gained a widespread in polymeric grain bags (silobags). The aim of the research was	2019-04-24	313	https://doi.org/10.15673/gpmf.v19i1.1315	STUDY OF PHYSIOLOGICAL PROCESSES IN CORN GRAIN DURING STORAGE UNDER HERMETIC CONDITIONS	3
314	Стаття	The article analyzes well-known semantic interpretations of the term "human factor" in the context of the evolutionary development of the safety component in "man-machine-environment" systems. It has been ascertained that single, recognized by law t	2019-04-24	314	https://doi.org/10.15673/gpmf.v19i1.1314	ASPECT OF MINIMIZATION AREAS OF «HUMAN FACTOR» IN LABOR SAFETY	3
315	Стаття	The article focuses on the introduction of a risk-oriented approach to labor protection at the enterprises of the grain processing industry. Such an approach is imperative in modern conditions in accordance with the Concept of reforming the system o	2019-04-24	315	https://doi.org/10.15673/gpmf.v19i1.1313	RISK-ORIENTED APPROACH TO LABOR PROTECTION AT GRAIN PROCESS ENTERPRISES	3
316	Стаття	Calculation of sieve separators power is usually done during their development. The goal of such calculations is to determine the power of driven electric motors. The imperfection of existing methods for calculating power of some types of sieve sepa	2019-01-17	316	https://doi.org/10.15673/gpmf.v18i4.1197	CLARIFICATION OF THE METHODS USED FOR CALCULATING POWER OF SIEVE SEPARATORS	3
317	Стаття	The article deals with the issues of modern snail breeding in Ukraine, problems and prospects for their cultivation. The main areas of use of snails are classified. With the proper cultivation of snails, the business is profitable, because meat and	2019-01-17	317	https://doi.org/10.15673/gpmf.v18i4.1196	SCIENTIFIC AND TECHNOLOGICAL SUBSTANTIATION OF PRODUCTION OF MIXED FODDERS FOR SNAILS	3
319	Стаття	The development of new physiologically functional food products is a prospective direction for world food products market. The inclusion of functional ingredients in food can increase the biological value of products that are already familiar to the	2019-01-17	319	https://doi.org/10.15673/gpmf.v18i4.1191	PROSPECTS FOR THE USE OF GRAIN RAW MATERIALS IN THE PRODUCTION OF FUNCTIONAL PRODUCTS	3
320	Стаття	Functional properties of food products with the addition of germinated grain raw materials have become the object of increased attention of scientists and specialists in the food industry. In addition to the nutritional ingredients, food products wi	2019-01-17	320	https://doi.org/10.15673/gpmf.v18i4.1190	RESEARCH OF HYDROTHERMAL PROCESSING OF DRY BARLEY MALT	3
321	Стаття	Due to the energy crisis, special attention is paid to the production and use of biofuels. After-harvesting residues of corn (AHRC) may become a perspective source of energy for grain dryers. The following components of the AHRC are distinguished: s	2019-01-17	321	https://doi.org/10.15673/gpmf.v18i4.1187	REMOVAL OF MINERAL IMPURITIES FROM AFTER - HARVESTING RESIDUES OF CORN	3
322	Стаття	The article analyzes the structure of production of cereals in the country, it is established that during the processing of grain into grains a significant part of secondary material resources (flour and husk) is formed. Therefore, it is important t	2019-01-17	322	https://doi.org/10.15673/gpmf.v18i4.1192	INTEGRATED PROCESSING TECHNOLOGY OF WASTES FROM CEREAL PRODUCTION	3
323	Стаття	The article analyzes one of the opportunities for the enhancement of the efficiency of grain processing production - improvement of working conditions through the certification of the workplaces. Such action is the component of the sectorial program	2019-01-14	323	https://doi.org/10.15673/gpmf.v18i4.1173	THE CONCERNS OF WORKPLACE CERTIFICATION FOR WORKING CONDITIONS AT THE GRAIN PROCESSING ENTERPRISES	3
324	Стаття	Динамика прогресса в агробизнесе позволяет утверждать, что в первой половине XXI века точная агротехнология станет абсолютной нормой на всех континентах по той простой причине, что она позво- ляет повысить эффективность использования земли. Точная а	2018-10-25	324	https://doi.org/10.15673/gpmf.v18i3.1080	ТОЧНАЯ АГРОТЕХНОЛОГИЯ БУДУЩЕГО НАЧИНАЕТСЯ СЕГОДНЯ	3
325	Стаття	У статті проаналізовано сучасний стан конярства в Україні. Конярство розвивається за наступними напрямками: продуктивне, спортивне, племінне. Розвиток конярства – це пошук шляхів правильної годівлі, яка заснована на знанні анатомічних і фізіологічни	2018-10-25	325	https://doi.org/10.15673/gpmf.v18i3.1079	ОЦІНКА ЗООТЕХНІЧНОЇ ЕФЕКТИВНОСТІ КОМБІКОРМІВ-КОНЦЕНТРАТІВ ДЛЯ КОНЕЙ	3
326	Стаття	The GMP+FSA Feed Certification scheme is considered and analyzed which was developed in 1992 by the Dutch feed industry in response to various incidents involving contamination in feed materials. Currently it is an international scheme that is manag	2018-10-25	326	https://doi.org/10.15673/gpmf.v18i3.1078	THE APPLICATION OF STATISTICAL METHODS OF QUALITY MANAGEMENT BY GMP+ STANDARDS USING FERROMAGNETIC MICROTRACERS	3
327	Стаття	У тваринництві, головним є організація раціональної годівлі. Хороша кормова база є запорукою повноцінного розвитку цієї галузі. Тому, велике значення відводиться виробництву комбікормів, які повинні повністю задовольняти організм тварин в усіх пожив	2018-10-24	327	https://doi.org/10.15673/gpmf.v18i3.1077	ПЕРЕВАГИ ВИКОРИСТАННЯ БІЛКОВИХ РОСЛИННИХ КОНЦЕНТРАТІВ ПРИ ВИРОБНИЦТВІ КОМБІКОРМОВОЇ ПРОДУКЦІЇ	3
328	Стаття	У статті представлено огляд літературних даних про питання органічного методу ведення сільського господарства. Викладено поняття ʺорганічне сільське господарствоʺ і ʺорганічна продукціяʺ. Розглянуто рівень світового розвитку органічного напрямку вед	2018-10-24	328	https://doi.org/10.15673/gpmf.v18i3.1076	РОЗВИТОК ОРГАНІЧНОГО НАПРЯМКУ СІЛЬСЬКОГО ГОСПОДАРСТВА У СВІТІ ТА ЙОГО СТАН В УКРАЇНІ	3
329	Стаття	Кондитерські вироби користуються широким попитом у дорослого населення та дітей. Однак, наявність високого вмісту цукру в рецептурі кондитерських виробів не дозволяє людям хворим на діабет та ожиріння вживати їх в їжу. Особам з такими захворюваннями	2018-10-24	329	https://doi.org/10.15673/gpmf.v18i3.1075	РОЗРОБКА БІСКВІТНИХ НАПІВФАБРИКАТІВ ДІЄТИЧНОГО ПРИЗНАЧЕННЯ	3
330	Стаття	Хлібопекарська промисловість України має велике соціальне значення, вона є підтримкою стабільності у суспільстві, а підприємства, що виробляють такий значимий для кожного пересічного українця продукт харчування, як хліб, прагнуть задовольнити потреб	2018-10-24	330	https://doi.org/10.15673/gpmf.v18i3.1074	АНАЛІЗ ПРОБЛЕМ ХЛІБОПЕКАРСЬКОЇ ГАЛУЗІ, СТАН РИНКУ ТА АКТУАЛЬНІ ШЛЯХИ РОЗШИРЕННЯ АСОРТИМЕНТУ	3
331	Стаття	Розробка нових харчових продуктів та раціонів підвищеної біологічної цінності, а також удосконалення вже існуючих виробів неможливо без наявності точних критеріїв оцінки отриманого результату. Білкова складова в харчуванні переважної більшості людей	2018-10-24	331	https://doi.org/10.15673/gpmf.v18i3.1073	ОЦІНЮВАННЯ ЯКОСТІ БІЛКА НАСІННЯ ЛЬОНУ МЕТОДОМ DIAAS	3
449	Стаття	Европейские страны демонстрируют высокие возможности простого преоб­разования солнечной энергии в тепловую энергию, которая может успешно использо­ваться для обеспечения различного рода технологических, отопительных и бытовых потребностей. Кроме тог	2018-08-23	449	https://doi.org/10.15673/swonaft.v82i1.1012	ИНТЕГРАЦИЯ ПРОЦЕССА ТЕПЛООБМЕНА  СОЛНЕЧНОЙ УСТАНОВКИ	4
332	Стаття	Стаття присвячена обґрунтуванню необхідності розширення асортименту борошняної продукції та підвищення її харчової і біологічної цінності за рахунок виробництва цільнозернового пшеничного борошна. У статі описані основні завдання та проблеми, що сто	2018-10-24	332	https://doi.org/10.15673/gpmf.v18i3.1071	ПОРІВНЯЛЬНЕ ДОСЛІДЖЕННЯ ПОКАЗНИКІВ ЯКОСТІ ЦІЛЬНОЗЕРНОВОГО ПШЕНИЧНОГО ТА СПЕЛЬТОВОГО БОРОШНА ВІТЧИЗНЯНОГО ВИРОБНИЦТВА	3
333	Стаття	The article analyzes a semantic meaning of the term "sustainable development" followed by its proper interpretation. It has been determined that in recent years, the number of natural and man-made disasters has increased rapidly due to the processes	2018-10-23	333	https://doi.org/10.15673/gpmf.v18i3.1070	MODERN ISSUES OF LABOR SAFETY DEVELOPMENT AND PROMISING WAYS OF THEIR SOLUTION	3
334	Стаття	В даній статті наведена конструкція скребкового конвеєра, яка передбачає, істотне зменшення енергоємності і виключення кришіння часток вантажу при переміщенні за рахунок відсутності між вантажем і жолобом відносного руху.\nЗапропонована методика для	2018-09-11	334	https://doi.org/10.15673/gpmf.v62i2.146	ЕНЕРГОЕФЕКТИВНОСТІ СКРЕБКОВОГО КОНВЕЄРА З РУХОМИМ ДНОМ	3
335	Стаття	В матеріалах статі на основі потреб домашніх тварин (собак) в поживних і біологічно-активних речовинах (БАР) науково обґрунтовано вибір кормової сировини для виробництва білково-вітамінно-мінеральної добавки (БВМД). Наведено характеристику отриманої	2018-09-11	335	https://doi.org/10.15673/gpmf.v62i2.144	ОЦІНКА САНІТАРНОЇ ЯКОСТІ БІЛКОВО- ВІТАМІННО-МІНЕРАЛЬНОЇ ДОБАВКИ ДЛЯ ДОМАШНІХ ТВАРИН	3
336	Стаття	The article deals with the overall situation of horse breeding in Ukraine and dynamics of the problem of reducing herd of horses. Also considered distribution of population of horses on farms of different ownership structure and the production of fe	2018-09-11	336	https://doi.org/10.15673/gpmf.v62i2.143	FEATURES OF APPLE POMACE PROCESSING IN THE PRODUCTION OF FEED FOR HORSES	3
337	Стаття	У статті розглянута загальна ситуація розвитку конярства в Україні та проблеми зниження динаміки поголів’я коней. Також розглянуто розподіл поголів'я коней по господарствам різних форм власності та структура виробництва комбікормів для сільськогоспо	2018-09-11	337	https://doi.org/10.15673/gpmf.v62i2.142	ОСОБЛИВОСТІ ПЕРЕРОБКИ ЯБЛУЧНИХ ВИЧАВКІВ ПРИ ВИРОБНИЦТВІ КОМБІКОРМІВ ДЛЯ КОНЕЙ	3
338	Стаття	Аналіз існуючих в Україні традиційних технологій переробки зернових і бобових культур в крупи і круп’яні продукти показує, що на сьогоднішній день переважна більшість діючих технологій була розроблена 20-30 років тому і передбачає використання значно	2018-09-11	338	https://doi.org/10.15673/gpmf.v62i2.141	БОРОШНО ТА ВИСІВКИ - НОВІ ПРОДУКТИ ІЗ ГОЛОЗЕРНОГО ВІВСА	3
339	Стаття	Основні положення стратегії політики з охорони навколишнього середовища та забезпечення сталого розвитку країни передбачають комплексне вирішення проблем збалансованого розвитку економіки країни та поліпшення стану навколишнього середовища. Сучасні	2018-09-11	339	https://doi.org/10.15673/gpmf.v62i2.140	ДОСЛІДЖЕННЯ СУМІСНОЇ УТИЛІЗАЦІЇ РИСОВОЇ ЛУЗГИ ТА ВІДХОДІВ М’ЯСОПЕРЕРОБНИХ ВИРОБНИЦТВ МЕТОДОМ АНАЕРОБНОГО ЗБРОДЖУВАННЯ	3
340	Стаття	Сепарирование семян относится к основным технологическим процессам послеуборочной обработки и выполняется с целью очистки, сортирования, калибрования, обогащения посевного материала. Известны различные способы сепарирования в зависимости от состояни	2018-09-11	340	https://doi.org/10.15673/gpmf.v62i2.139	АЭРОДИНАМИЧЕСКОЕ СЕПАРИРОВАНИЕ ОДНОКОМПОНЕНТНЫХ СЕМЕННЫХ СМЕСЕЙ НА ПРИМЕРЕ КУКУРУЗЫ	3
341	Стаття	тикале та визначення його місця в агропромисловій сфері України. Показано, що сучасні сорти тритикале, зокрема української селекції, відзначаються збалансованістю незамінних амінокислот, підвищеним вмістом білка, каротиноїдів, завдяки чому зерно і з	2018-09-11	341	https://doi.org/10.15673/gpmf.v62i2.138	НАРОДНОГОСПОДАРСЬКЕ ЗНАЧЕННЯ ТРИТИКАЛЕ ТА ПЕРСПЕКТИВИ ЙОГО ВИКОРИСТАННЯ ДЛЯ РОЗШИРЕННЯ СИРОВИННОЇ БАЗИ ХАРЧОВИХ ВИРОБНИЦТВ	3
342	Стаття	ТОЧНАЯ АГРОТЕХНОЛОГИЯ БУДУЩЕГО НАЧИНАЕТСЯ СЕГОДНЯ. ПОДСОЛНЕЧНИК	2018-09-11	342	https://doi.org/10.15673/gpmf.v62i2.137	ТОЧНАЯ АГРОТЕХНОЛОГИЯ БУДУЩЕГО НАЧИНАЕТСЯ СЕГОДНЯ. ПОДСОЛНЕЧНИК	3
343	Стаття	Фотоелектронне сепарування застосовують для сортування різноманітних сипких продуктів, у тому числі – зерна і деяких продуктів його переробки.\nФотоелектронні сепаратори використовують для очищення зерна від важковідділюваних домішок, які досить скла	2018-07-09	343	https://doi.org/10.15673/gpmf.v18i2.970	ОСОБЛИВОСТІ КОНСТРУКЦІЇ І ЗАСТОСУВАННЯ ФОТОЕЛЕКТРОННОГО ОБЛАДНАННЯ ДЛЯ РОЗДІ- ЛЕННЯ ЗЕРНА І ЗЕРНОПРОДУКТІВ НА ФРАКЦІЇ ЗА ОЗНАКОЮ КОЛЬОРУ	3
344	Стаття	В роботі наведено аналіз ринку гороху у світі та Україні, показано тенденцію зростання обсягів вирощування, що зумовлене зростанням попиту на харчовий і кормовий білок. Проаналізовано поживну цінність, переваги використання зерна гороху у харчовій і	2018-07-09	344	https://doi.org/10.15673/gpmf.v18i2.968	ПЕРСПЕКТИВИ ВИКОРИСТАННЯ ГОРОХОВОЇ СОЛОМИ ПРИ ВИРОБНИЦТВІ КОМБІКОРМОВОЇ ПРОДУКЦІЇ	3
345	Стаття	У роботі наведені результати впливу різних концентрацій ферментного препарату «Клерізим гранульований» в годівлі курчат віком 30 та 120 діб.\nВстановлено, що ферментний препарат в годівлі курчат позитивно впливає на гематологічні та біохімічні показн	2018-07-09	345	https://doi.org/10.15673/gpmf.v18i2.953	ДИНАМІКА ПОКАЗНИКІВ КРОВІ КУРЧАТ ПРИ ВИКОРИСТАННІ ФЕРМЕНТНОГО ПРЕПАРАТУ “КЛЕРІЗИМ ГРАНУЛЬОВАНИЙ” В ЇХ ГОДІВЛІ	3
346	Стаття	Идея создания Международной Школы Кормов - обобщение мирового опыта в области научных исследований и практики производства и использования премиксов и комбикормов, проведение профессиональных тренингов, направленных на овладение современными знаниям	2018-07-09	346	https://doi.org/10.15673/gpmf.v18i2.952	ПЯТАЯ ЮБИЛЕЙНАЯ СЕССИЯ МЕЖДУНАРОДНОЙ ШКОЛЫ КОРМОВ	3
347	Стаття	In Ukraine, the following basic crops are used as raw materials for the production of cereals, flour, flakes: wheat, barley, buckwheat, oats, corn, rice, millet, peas. The volume of world grain production in recent years has grown significantly. In	2018-07-09	347	https://doi.org/10.15673/gpmf.v18i2.969	USE OF CORN GRAIN IN PRODUCTION OF FOOD PRODUCTS	3
348	Стаття	Хлібобулочні вироби є важливим продуктом харчування для більшості населення України. Потреба в хлібобулоч-них виробах притаманна людям будь-якого віку, соціального статусу і рівня доходів. Хлібопекарська галузь покликана забезпечувати споживачів кра	2018-07-09	348	https://doi.org/10.15673/gpmf.v18i2.951	ЕФЕКТИВНІСТЬ ЗАСТОСУВАННЯ ВИСОКОБІЛКОВИХ ФУНКЦІОНАЛЬНИХ ПРОДУКТІВ У ВИРОБНИЦТВІ БУЛОЧОК	3
349	Стаття	This article describes main methods of using the method of microwave treatment in food industry and in grain processing in particular. Main principles of this technology as well as using this technological approach for popping grain have been consid	2018-07-09	349	https://doi.org/10.15673/gpmf.v18i2.950	PRODUCTION OF POPPED SORGHUM WITH USING MICROWAVE TREATMENT	3
351	Стаття	In the paper, on the basis of the conducted analysis of the dynamics of the spread of dangers in the context of evolutionary development of society, it is determined that the global problems have become complex, which appears in interdependence of n	2018-07-09	351	https://doi.org/10.15673/gpmf.v18i2.948	THE THEORY AND PRACTICE OF RISK ASSESSMENT OF PROFESSIONAL DANGERS	3
352	Стаття	На підприємствах по виробництву крупів широко застосовуються лущильно-шліфувальні машини типу А1-ЗШН-3\nта їх аналоги, що відрізняються розмірами робочої зони та відповідно продуктивністю. Основними недоліками цих машин\nє низька ефективність лущення-	2018-04-17	352	https://doi.org/10.15673/gpmf.v18i1.894	РЕЗУЛЬТАТИ ЛУЩЕННЯ-ШЛІФУВАННЯ ЯЧМЕНЮ В АБРАЗИВНО-ДИСКОВІЙ МАШИНІ А1-ЗШН-3	3
353	Стаття	В матеріалах статті розглянуті проблеми захворювання домашніх тварин (собак) на дисплазію тазостегнового\nсуглоба та шляхи їх вирішення за рахунок застосування в раціоні білково-вітамінно-мінеральної добавки (БВМД) «Мобі-\nкан». Наведені рецептури БВМ	2018-04-17	353	https://doi.org/10.15673/gpmf.v18i1.891	БІОЛОГІЧНА ТА ЗООТЕХНІЧНА ОЦІНКА БВМД ДЛЯ ДОМАШНІХ ТВАРИН (СОБАК)	3
354	Стаття	В умовах постійних економічних спадів, нестабільного розвитку економічних процесів та загальнополітичної не-\nстабільності актуальним завданням для країни є забезпечення населення необхідними продуктами харчування та продово-\nльством у цілому. Важлив	2018-04-17	354	https://doi.org/10.15673/gpmf.v18i1.892	ПЕРСПЕКТИВИ ВИКОРИСТАННЯ ПОБІЧНИХ ПРОДУКТІВ ЦУКРОВОГО ВИРОБНИЦТВА	3
355	Стаття	Aquaculture is food sector, which is growing rapidly in the last 25 years with annual growth rate 8,2 . One of the most\nperspective branches of aquaculture is shrimp farming. The cost of feeds is up to 80% of the cost of shrimp breeding, so providi	2018-04-17	355	https://doi.org/10.15673/gpmf.v18i1.893	TENDENCIES AND PECULIARITIES OF SHRIMP FEED PRODUCTION	3
356	Стаття	В статті проведено дослідження зміни кислотного, перекисного та йодного чисел дрібнонасіннєвих олійних куль-\nтур у діапазоні температури зберігання 5…25 °С та тривалості зберігання до 12 місяців. Встановлено, що з факторів, що\nвпливають на величину	2018-04-17	356	https://doi.org/10.15673/gpmf.v18i1.889	ВИЗНАЧЕННЯ ФАКТОРІВ, ЩО ВПЛИВАЮТЬ НА ОРГАНІЗАЦІЮ ПРОЦЕСУ ЗБЕРІГАННЯ ДРІБНОНАСІННЄВИХ ОЛІЙНИХ КУЛЬТУР	3
357	Стаття	-	2018-04-17	357	https://doi.org/10.15673/gpmf.v18i1.886	ЗЕРНОБОБОВЫЕ КУЛЬТУРЫ – СПРОС РАСТЕТ. Часть 2.	3
358	Стаття	I\nn the paper, according to the analysis of statistical data, correlation between the amount of occupational injuries and occupational\ndiseases in Ukraine within last 5 years is defined. Also, using methodology of the International Labor Organization	2018-04-17	358	https://doi.org/10.15673/gpmf.v18i1.895	IMPROVING METHODOLOGY OF RISK IDENTIFICATION OF OCCUPATIONAL DANGEROUS	3
359	Стаття	Автоматизовану систему обліку продуктів переробки комбінату хлібопродуктів розроблено НВУ «ТОМ», м. Одеса, Україна.  Система здійснює поточний контроль маси зерна, борошна, побічних продуктів і відходів, а також забезпечує оперативне надання результа	2017-12-25	359	https://doi.org/10.15673/gpmf.v17i4.767	АВТОМАТИЗОВАНА СИСТЕМА ОБЛІКУ ПРОДУКТІВ ПЕРЕРОБКИ КОМБІНАТУ ХЛІБОПРОДУКТІВ	3
360	Стаття	Раціональне використання електроенергії на зернопунктах, оснащених енергоємним технологічним обладнанням, особливо актуально тепер, коли прийнята Національна енергетична програма України з енергозбереження. Відомо, що 1 одиниця зекономленої електроен	2017-12-25	360	https://doi.org/10.15673/gpmf.v17i4.766	ЕНЕРГОЄМНІСТЬ ЯК ЕНЕРГЕТИЧНА  ХАРАКТЕРИСТИКА ТЕХНОЛОГІЧНОГО ПРОЦЕСУ ОЧИЩЕННЯ ЗЕРНА	3
361	Стаття	У статті розглянуто сучасні напрями розширення сировинної бази у виробництві комбікормів для яєчних курей. Однією з найважливіших умов сучасного виробництва високоякісних комбікормів, білкових концентратів і преміксів є пошук і  використання нової си	2017-12-25	361	https://doi.org/10.15673/gpmf.v17i4.765	РОЗШИРЕННЯ СИРОВИННОЇ БАЗИ У  ВИРОБНИЦТВІ КОМБІКОРМІВ ДЛЯ ЯЄЧНИХ КУРЕЙ	3
362	Стаття	В статті наведено результати досліджень показників якості борошна з різних етапів технологічного процесу при сортовому помелі пшениці: зольність, білість, кількість клейковини та її якість, седиментація, водопоглинальна здатність та реологічні власти	2017-12-25	362	https://doi.org/10.15673/gpmf.v17i4.763	ВИЗНАЧЕННЯ ПОКАЗНИКІВ ЯКОСТІ БОРОШНА З РІЗНИХ СИСТЕМ ТЕХНОЛОГІЧНОГО ПРОЦЕСУ ПРИ СОРТОВОМУ ПОМЕЛІ ПШЕНИЦІ	3
363	Стаття	Стаття присвячена збільшенню виробництва насіння сочевиці в Україні, як джерела кормового і харчового білка. Станом на перше десятиліття XXІ століття найбільші площі вирощування сочевиці зосереджено в Індії, Канаді, Туреччині, Непалі, Ірані. У Центра	2017-12-25	363	https://doi.org/10.15673/gpmf.v17i4.762	СОЧЕВИЦЯ - ДЖЕРЕЛО РОСЛИННОГО БІЛКА	3
364	Стаття	Бобовые – это растения, плоды которых вызревают в стручках. Зернобобовые относятся к семейству бобовых, используются только для обозначения сухих семян. Зернобобовые культуры занимают в мировой агротехнологии заметную роль. Под них отводится не менее	2017-12-25	364	https://doi.org/10.15673/gpmf.v17i4.761	ЗЕРНОБОБОВЫЕ КУЛЬТУРЫ - СПРОС РАСТЕТ. ЧЕЧЕВИЦА. Часть 1.	3
365	Стаття	The development of new physiologically functional ingredients allows us to expand the range of these additives and to attract additional non-traditional sources of raw materials. Prebiotics are non-digestible food ingredients that stimulate the growt	2017-12-25	365	https://doi.org/10.15673/gpmf.v17i4.760	THE CURRENT TRENDS AND FUTUREPERSPE C TIVES  OF ARABINOXYLANS PREBIOTICS RESEARCH: A REVIEW	3
366	Стаття	Providing the population of small settlements with flour and bread in modern conditions requires energy expenditure on the transportation of grain to the mills, and then to the bakeries and bread itself to the settlements. Therefore, the organization	2017-10-22	366	https://doi.org/10.15673/gpmf.v17i3.661	SMALL - CAPACITY UNIT FOR FLOUR PRODUCTION AND PANIFICATION	3
367	Стаття	В матеріалах статті наведені проблеми прояву дисплазії у  домашніх тварин (собак) та шляхи її усунення за допомогою введення в раціон  білково-вітамінно-мінеральних добавок. Представлені наукові та практичні результати розробки ТУ У 10.9-2574413678-0	2017-10-22	367	https://doi.org/10.15673/gpmf.v17i3.660	«МОБІКАН » - Б ІЛКОВО - ВІТАМІННО - МІНЕРАЛЬНА ДОБАВКА ДЛЯ ДОМАШНІХ ТВАРИН	3
368	Стаття	Science and practice proved the high efficiency of granulated mixed fodders. This article presents an overview of granulation technologies for various industries. This article discusses the application of granulation technologies in various industrie	2017-10-22	368	https://doi.org/10.15673/gpmf.v17i3.659	APPLICATION OF GRANULATION TECHNOLOGY IN VARIOUS INDUSTRIES	3
369	Стаття	У раціоні людей різних вікових груп  молочні продукти традиційно займають суттєву частку. Особливо користуються попитом кисломолочні продукти. Технології виробництва резервуарним способом передбачають механічне оброблення кисломолочного згустку, а те	2017-10-22	369	https://doi.org/10.15673/gpmf.v17i3.658	ВИКОРИСТАННЯ ЗЕРНОВИХ ДОБАВОК У  ВИРОБНИЦТВІ МОЛОЧНИХ ПРОДУКТІВ З  КОМБІНОВАНИМ СКЛАДОМ С И РОВИНИ	3
370	Стаття	Товарне зерно пшениці класифікується за різними ознаками, нормами якості та системами його оцінки, прийнятими і чинними в конкретній країні. Універсальних класифікацій зерна не існує, тому визначальними є показники якості. Одним з показників якості з	2017-10-22	370	https://doi.org/10.15673/gpmf.v17i3.657	ДОСЛІДЖЕННЯ ПЕРЕВАГ І НЕДОЛІКІВ ПРИ В И ЗНАЧЕННІ КЛЕЙКОВИНИ АВТОМАТИЗОВАНИМ І РУЧНИМ СПОСОБОМ	3
755	Стаття	. In the article the conditions of enzymatic hydrolysis of fat fraction of waste from production of hydrogenated fat by the lipase Rhizopus japonicus are considered, namely, the influence of pH of the medium (pH-optimum, pH-stability) and temperatur	2019-05-02	755	https://doi.org/10.15673/fst.v13i1.1332	INVESTIGATION OF THE FAT FRACTION ENZYMATIC HYDROLYSIS OF THE WASTE FROM PRODUCTION OF HYDROGENATED FAT BY THE LIPASE RHIZOPUS JAPONICUS	5
371	Стаття	Виробники зернопереробної галузі все частіше стали звертати увагу на дрібнонасіннєві культури такі як сорго, амарант, ріпак, гірчиця, льон, мак та ін. Оскільки виробництво дрібнонасіннєвих культур зростає, то для визначення ефективних режимів їх післ	2017-10-22	371	https://doi.org/10.15673/gpmf.v17i3.656	ОСОБЛИВОСТІ ТЕХНОЛОГІЇ ПІСЛЯЗБИРАЛЬНОЇ ОБРОБКИ ДРІБНОНАСІННЄВИХ КУЛЬТУР	3
372	Стаття	Необходимость получения высокого урожая, снижение затрат на производство с/х продукции побуждает повышать культуру земледелия. Высокое качество семян – обязательная составляющая современной культуры земледелия. Сегодня на рынке семян Украины качество	2017-10-22	372	https://doi.org/10.15673/gpmf.v17i3.655	ЧТО МЫ СЕЕМ??!	3
373	Стаття	A positive trend of growth in both grain production and export is indicated. In the current marketing year the export potential of the Ukrainian grain market is close to the record level. However, the high positions in the rating of world exporters a	2017-07-30	373	https://doi.org/10.15673/gpmf.v17i2.531	AUTOMATION OF TRACEABILITY PROCESS AT GRAIN TERMINAL LLC “ UKRTRANSAGRO"	3
374	Стаття	29 мая - 04 июня 2017 г. в рамках IV-ой сессии Международной школы кормов, организованной Одесской национальной академией пищевых технологий (ОНАПТ), проведено два тренинга:  - Тренинг 1: «Искусство создания высокоэффективных рецептов комбикормов»; -	2017-07-30	374	https://doi.org/10.15673/gpmf.v17i2.530	IV-я СЕССИЯ МЕЖДУНАРОДНОЙ ШКОЛЫ КОРМОВ	3
375	Стаття	У статті проаналізовано сучасний стан комбікормової промисловості та перспективи використання побічних кормових продуктів пивоварної промисловості, що отримуються при переробці сусла ячменю та солоду, зокрема суху пивну дробину. За аналізом теоретичн	2017-07-30	375	https://doi.org/10.15673/gpmf.v17i2.529	ВИКОРИСТАННЯ СУХОЇ ПИВНОЇ ДРОБИНИ У ГОДІВЛІ КУРЧАТ - БРОЙЛЕРІВ	3
376	Стаття	В статті представлено обґрунтування доцільності використання преміксів у годівлі сільськогосподарських тварин та птиці, наведені переваги введення преміксів до складу комбікормів та їх класифікація. Наведено призначення розробленого універсального ко	2017-07-30	376	https://doi.org/10.15673/gpmf.v17i2.528	ЄГОРОВ Б.В., д-р техн. Наук, професор, МАКАРИНСЬКА А.В., канд. техн. Наук, доцент, ВОРОНА Н.В., канд. техн. Наук, ст. Викладач Одеська національна академія харчових технологій, Одеса  ОЦІНКА ЗООТЕХНІЧНОЇ ЕФЕКТИВНОСТІ ВИКОРИСТАННЯ УНІВЕРСАЛЬНОГО КОМПЛЕКСНО	3
377	Стаття	Рассмотрены теоретические аспекты определения однородности омбикормовой продукции и условий проявления сегрегации. Цель работы \n аключается в проведении исследования возможной сегрегации частиц ферромагнитных микротрейсеров и премикса в процессе хра	2017-07-30	377	https://doi.org/10.15673/gpmf.v17i2.527	ИЗУЧЕНИЕ СЕГРЕГАЦИИ ФЕРРОМАГНИТНЫХ  МИ К РОТРЕЙСЕРОВ ОТ ПРЕМИКСОВ: РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ В МОДЕЛЬНЫХ УСЛОВИЯХ И  У С ЛОВИЯХ ТРАНСПОРТИРОВКИ И ХРАНЕНИЯ	3
378	Стаття	Під час створення продуктів для дитячого харчування визначальне значення має адекватна біологічна цінність. Саме вона є одним з головних критеріїв оцінювання доцільності використання тих або інших компонентів. Біологічну цінність продуктів визначають	2017-07-30	378	https://doi.org/10.15673/gpmf.v17i2.525	ФЕРМЕНТАТИВНИЙ МЕТОД ВИЗНАЧЕННЯ  БІОЛОГІЧНОЇ ЦІННОСТІ МОЛОЧНИХ ПРОДУКТІВ ІЗ ЗЕРНОВИМ ІНГРЕДІЄНТОМ ДЛЯ  ДИТЯЧОГО ХАРЧУВАННЯ	3
379	Стаття	Стаття присвячена дослідженню якості безглютенового хліба з використанням гречаного та кукурудзяного борошна. Наведено результати досліджень деяких технологічних властивостей борошна кукурудзяного тонкого помелу та гречаного, крохмалю кукурудзяного і	2017-07-30	379	https://doi.org/10.15673/gpmf.v17i2.524	ДОСЛІДЖЕННЯ ЯКОСТІ ТА ЧЕРСТВІННЯ  БЕЗГЛЮТЕНОВОГО ХЛІБА З ГРЕЧАНИМ І  КУКУРУДЗЯНИМ БОРОШНОМ	3
380	Стаття	Тема антиоксидантов фенольной природы злаковых и бобовых культур находится под пристальным вниманием зарубежных и отечественных учёных, которые изучают не только их качественный и количественный состав, но и фармакологическое действие на макроорганиз	2017-07-30	380	https://doi.org/10.15673/gpmf.v17i2.523	СОДЕРЖАНИЕ СВОБОДНЫХ И СВЯЗАННЫХ ПОЛИФЕНОЛОВ ЗЛАКОВЫХ И БОБОВЫХ КУЛЬТУР	3
381	Стаття	Тренд «здоровая пища» уверенно набирает популярность. Прогресс профилактической медицины, диетологии, развитие пищевых технологий убедительно показывают зависимость качества жизни от рациона питания человека. Высокое качество жизни – это продолжитель	2017-07-30	381	https://doi.org/10.15673/gpmf.v17i2.522	ГРЕЧИХА - ЗОЛУШКА НА ПУТИ К ПРИНЦЕССЕ	3
756	Стаття	The article proves how practical it is to use whole-milled millet grain to improve the quality of bakery products. Samples of bread with the addition of different amounts of milled millet grain before and after microwave treatment have been evaluate	2019-04-11	756	https://doi.org/10.15673/fst.v13i1.1312	NEW ASPECTS OF USING MILLET GRAIN IN BREAD MANUFACTURING	5
382	Стаття	Конярство – це перспективна галузь тваринництва, яка займається розведенням і використанням коней в різних напрямках. Розвиток конярства передбачає пошук шляхів правильної годівлі, яка заснована на знанні анатомічних і фізіологічних особливостей кон	2017-04-15	382	https://doi.org/10.15673/gpmf.v17i1.314	БІОЛОГІЧНА ОЦІНКА КОМБІКОРМІВ-КОНЦЕНТРАТІВ ДЛЯ ТРЕНОВАНИХ І СПОРТИВНИХ КОНЕЙ	3
383	Стаття	В статті представлено огляд літературних даних про фермент лізоцим та його використання в годівлі тварин. Викладено методику досліду з вивчення використання ферменту лізоцим, що випускається у вигляді ферментного препарату під торговою назвою «Клері	2017-04-15	383	https://doi.org/10.15673/gpmf.v17i1.313	ФЕРМЕНТНИЙ ПРЕПАРАТ “КЛЕРІЗИМ ГРАНУЛЬОВАНИЙ” В ГОДІВЛІ РЕМОНТНОГО МОЛОДНЯКУ КУРЕЙ-НЕСУЧОК	3
384	Стаття	В результаті проведених досліджень встановлено, що вихід крупи плющеної найбільше залежав від тривалості лущення. Найбільший вихід плющеної крупи із пшениці спельти отримано за лущення зерна протягом 20 хв., який за 5хвилинного пропарювання змінювавс	2017-04-15	384	https://doi.org/10.15673/gpmf.v17i1.310	ВПЛИВ ПАРАМЕТРІВ ЛУЩЕННЯ ТА ВОДОТЕПЛОВОЇ ОБРОБКИ ЗЕРНА НА ВИХІД І КУЛІНАРНУ ОЦІНКУ ПЛЮЩЕНОЇ КРУПИ ІЗ ПШЕНИЦІ СПЕЛЬТИ	3
385	Стаття	У статті здійснено огляд наукових праць, спрямованих на вивчення біологічних, фізико-технологічних і хімікотехнологічних властивостей зерна полби та визначення можливостей застосування продуктів його перероблення як сировини в харчовому виробництві.	2017-04-15	385	https://doi.org/10.15673/gpmf.v17i1.309	ХАРАКТЕРИСТИКА ПОЛБИ ЯК ПЕРСПЕКТИВНОЇ  ЗЕРНОВОЇ КУЛЬТУРИ ТА ОСНОВНІ ПРОБЛЕМИ ЇЇ ПІСЛЯ ЗБИРАЛЬНОГО ОБРОБЛЕННЯ	3
386	Стаття	Вызовы времени. Уважаемый читатель, к нам обратился руководитель фирмы, производящий муку из зерна спельты и макароны из нее. Просьба звучала просто – можем ли мы обрушить спельту. Опыта обрушивания спельты у нас не было, но поскольку мы выпускаем ун	2017-04-15	386	https://doi.org/10.15673/gpmf.v17i1.308	СПЕЛЬТА – ПРИШЛО ЕЕ ВРЕМЯ	3
387	Стаття	Забезпечити якісне зберігання зерна можливе лише при глибокому розумінні процесів, з цілеспрямованим урахуванням фізіологічних властивостей, що відбуваються в зернових масах на всіх етапах їх післязбиральної обробки і подальшому зберіганні.\nОсоблив	2017-04-15	387	https://doi.org/10.15673/gpmf.v17i1.307	ФІЗИКО-ТЕХНОЛОГІЧНІ ВЛАСТИВОСТІ СУЧАСНИХ СОРТІВ ДРІБНОНАСІННЄВИХ КУЛЬТУР	3
388	Стаття	Based on comparative analysis of the industrial accident causes in Ukraine and EU countries this article establishes that the main accident reasons are organizational ones (50 to 70% of the total number of cases), however such indicators as the regi	2016-12-24	388	https://doi.org/10.15673/gpmf.v64i4.267	LABOUR PROTECTION AND INDUSTRIAL SAFETY IN UKRAINE: PROBLEMS OF TRANSITION PERIOD AND PERSPECTIVE WAYS OF DEVELOPMENT	3
389	Стаття	Серед багатьох технологічних процесів, що застосовують як у харчовій промисловості, так і кормовиробництві, одним із найпоширеніших є енергоємний процес сушіння. Загальний потенціал енергоефективності при сушінні кормових трав, який визначається різн	2016-12-24	389	https://doi.org/10.15673/gpmf.v64i4.266	ЕНЕРГЕТИЧНИЙ АУДИТ ТЕХНОЛОГІЇ ПЕРЕРОБКИ ВОЛОГИХ КОРМОВИХ ТРАВ	3
390	Стаття	Нормування годівлі молодняку свиней на відгодівлі живою масою 70-110 кг здійснювали на основі норм концентрації енергії і поживних речовин в 1 кг повнораціонного комбікорму. Годівлю молодняку свиней проводили повнораціонним комбікормом для молодняку	2016-12-24	390	https://doi.org/10.15673/gpmf.v64i4.265	ПРОДУКТИВНІ ЯКОСТІ МОЛОДНЯКУ СВИНЕЙ НА ВІДГОДІВЛІ ЖИВОЮ МАСОЮ 70 - 110 КГ ЗА  ВИКОРИСТАННЯ ПОВНОРАЦІОННОГО КОМБІКОРМУ	3
391	Стаття	The article is devoted to the research of applicability of gluten-free flours from cereal crops and from by-products of cereal crop processing - ground crumbs sifted out in a process of flake production from rice, corn and millet during the productio	2016-12-24	391	https://doi.org/10.15673/gpmf.v64i4.262	THE INFLUENCE OF GLUTEN - FREE FLOURS ON THE QUALITY INDICATORS OF BISCUIT SEMI - FINISHED PRODUCTS	3
392	Стаття	В повседневной жизни мы редко задумываемся о том, что наше здоровье находится в абсолютной зависимости от того, что мы употребляем в пищу. На мой взгляд, этому есть объяснение. Организм сам дает сигналы о дефиците того или иного компонента для нормал	2016-12-24	392	https://doi.org/10.15673/gpmf.v64i4.264	РАСТИТЕЛЬНОЕ МАСЛО	3
393	Стаття	В даний час зростають потреби населення в нових продуктах харчування, які характеризуються екологічною чистотою і здоровим напрямком. Одним з таких продуктів є гречана крупа, отримана із зерна гречки. При вирощуванні гречки не застосовуються хімічні	2016-12-24	393	https://doi.org/10.15673/gpmf.v64i4.263	ВИРОБНИЦТВО І ЯКІСТЬ ГРЕЧАНИХ ПРОДУКТІВ	3
394	Стаття	У статті описані основні тенденції щодо розвитку харчової промисловості у напрямку створення функціональних продуктів, здатних замінити рафіновані продукти масового споживання та висвітлені основні проблеми, які виникають при виробництві цільнозернов	2016-12-24	394	https://doi.org/10.15673/gpmf.v64i4.260	ДОСЛІДЖЕННЯ ТЕХНОЛОГІЧНИХ АСПЕКТІВ  ВИРОБНИЦТВА ХЛІБА ІЗ ДИСПЕРГОВАНОЇ ЗЕРНОВОЇ МАСИ З ВИКОРИСТАННЯМ ДОДАТКОВОЇ ПІДГОТОВКИ СИРОВИНИ	3
395	Стаття	Статья посвящена обоснованию целесообразности производства зернового хлеба на основе трехкомпонентных смесей из диспергированной зерновой массы, муки из крошки пшеничных хлопьев с внесением измельченных семян кунжута. Показана актуальность расширения	2016-12-24	395	https://doi.org/10.15673/gpmf.v64i4.259	ТРЕХКОМПОНЕНТНЫЕ СМЕСИ В ТЕХНОЛОГИИ ЗЕРНОВОГО ХЛЕБА	3
396	Стаття	The article describes the quantification of the level of safety in the brewing industry, which allows determining the contribution of each employee to ensure healthy and safe working conditions. Factors have also been shown to affect the safety of ea	2016-10-06	396	https://doi.org/10.15673/gpmf.v63i3.221	LABOUR PROTECTION AND SAFETY IN  THE BREWING INDUSTRY	3
397	Стаття	У статті проаналізовано сучасний стан інноваційних технологій виробництва комбікормової продукції та перспективи розвитку тваринництва та птахівництва в умовах фермерських господарств України. Одним із напрямків інтенсивного розвитку тваринництва та	2016-10-06	397	https://doi.org/10.15673/gpmf.v63i3.220	КОМПЛЕКСНІ ПРОЕКТНІ РІШЕННЯ НА  ПЕРЕСУВНИХ КОМБІКОРМОВИХ АГРЕГАТАХ ТА ТЕХНІКА БЕЗПЕКИ ПРИ ЕКСПЛУАТАЦІЇ	3
398	Стаття	Мировой объем производства комбикормов в настоящее время составляет более 900 миллионов тонн в год. Качество перемешивания комбикормов чрезвычайно важно, и нередко их производители, стараясь достичь полноты смешивания, необдуманно расходуют электроэн	2016-10-06	398	https://doi.org/10.15673/gpmf.v63i3.219	ФЕРРОМАГНИТНЫЕ МИКРОТРЕЙСЕРЫ КАК  ИНДИКАТОРЫ КАЧЕСТВА ОДНОРОДНОСТИ  КОМБИКОРМОВ ДЛЯ ЖИВОДНОВОДСТВА И  ПТИЦЕВОДСТВА	3
399	Стаття	У статті представлена принципова технологічна схема виробництва томатної кормової добавки (ТКД). Також детально описано технологічний процес переробки томатних вичавок в томатну кормову добавку із наведенням режимів.  Для отримання комбікорму високої	2016-10-06	399	https://doi.org/10.15673/gpmf.v63i3.217	УДОСКОНАЛЕННЯ ТЕХНОЛОГІЇ ВИРОБНИЦТВА КОМБІКОРМІВ З ВИКОРИСТАННЯМ ТОМАТНОЇ КОРМОВОЇ ДОБАВКИ	3
400	Стаття	Годівля молодняку свиней у віці від 91 до 130 діб диференційована на чотири вікові періоди – від 91 до 100 діб, від 101 до 110, від 111 до 120 і від 121 до 130 діб. У перший віковий період молодняку свиней згодовують 1,8 кг повнораціонного комбікорму	2016-10-06	400	https://doi.org/10.15673/gpmf.v63i3.216	ПРОДУКТИВНІ ЯКОСТІ МОЛОДНЯКУ СВИНЕЙ У ВІЦІ ВІД 91 ДО 130 ДІБ ЗА ВИКОРИСТАННЯ  ПОВНОРАЦІОННОГО КОМБІКОРМУ	3
401	Стаття	Рішення національної програми підняття продуктивності і ефективності тваринництва неможливо без створення надійної кормової бази, яка багато в чому визначає якість і ціну виробленої продукції. У статті дана оцінка ефективності силосування кукурудзи г	2016-10-06	401	https://doi.org/10.15673/gpmf.v63i3.215	ЕФЕКТИВНІСТЬ ПРЕПАРАТУ «СЕНОСІЛ» ДЛЯ КОНСЕРВУВАННЯ силосу	3
402	Стаття	Аграрний сектор України був і залишається одним із основних чинників економічної бази держави, а основою аграрного бізнесу є виробництво та переробка зернових культур. Необхідно відзначити, що за останні 20…25 років виробництво зернових культур збіль	2016-10-06	402	https://doi.org/10.15673/gpmf.v63i3.214	ПЕРСПЕКТИВИ СТВОРЕННЯ ДОДАТКОВОЇ ВАРТОСТІ ПРИ ПЕРЕРОБЦІ ЗЕРНОВИХ КУЛЬТУР	3
403	Стаття	Наявність інноваційної складової у концепції підприємства є однією із умов його сталої конкурентоспроможності. Інноваційний розвиток закладів ресторанного господарства (ЗРГ) та підприємств харчової промисловості є основою стратегічного планування, як	2016-10-06	403	https://doi.org/10.15673/gpmf.v63i3.213	ДОСЛІДЖЕННЯ ВПЛИВУ ОЛІЇ СОНЯШНИКОВОЇ ВИСОКООЛЕЇНОВОГО ТИПУ НА СТРУКТУРНО МЕХАНІЧНІ ВЛАСТИВОСТІ ЗАВАРНОГО ТІСТА ТА ВИПЕЧЕНИХ З НЬОГО НАПІВФАБРИКАТІВ	3
404	Стаття	Учитывая возрастающую роль в агробизнесе Украины такой культуры как соя, рассмотрим указанную проблему применительно к этой культуре. От размещения растений сои на поле зависит: форма и размер площади питания, освещенность, обеспеченность влагою и пи	2016-10-06	404	https://doi.org/10.15673/gpmf.v63i3.222	ТОЧНАЯ АГРОТЕХНОЛОГИЯ  БУДУЩЕГО НАЧИНАЕТСЯ СЕГОДНЯ (СОЯ)	3
405	Стаття	Багато часу витрачається на рішення проблем які здатні покращити виробництво у сільськогосподарській галузі. Але головним чинником для вчених та сільськогосподарських робітників є підвищення удосконалення та здешевлення виробляємої ними продукції. Т	2016-07-21	405	https://doi.org/10.21691/gpmf.v61i1.104	ПІДВИЩЕННЯ ПРОДУКТИВНОСТІ СВИНЕЙ НА РАЦІОНАХ З ФЕРМЕНТНИМ ПРЕПАРАТОМ «ЛІЗОЦИМ»	3
406	Стаття	Високі темпи розвитку птахівництва вимагають вирішення таких проблем як, розширення сировинної бази при виробництві комбікормів і забезпечення кальцієвого дефіциту у високопродуктивних несучок. Разом з тим, при\nвиробництві соків і рослинних консерві	2016-07-21	406	https://doi.org/10.21691/gpmf.v61i1.103	РОЗРОБКА І ВИКОРИСТАННЯ НЕТРАДИЦІЙНИХ КОРМОВИХ ДОБАВОК У ГОДІВЛІ КУРЕЙ-НЕСУЧОК	3
407	Стаття	Годівля поросят у віці від 61 до 90 діб диференційована на три вікові періоди – від 61 до 70 діб, від 71 до 80 і від 81 до 90 діб. У перший віковий період поросятам згодовують 1,0 кг повнораціонного комбікорму за добу, в другий –\n1,4 кг і в третій в	2016-07-21	407	https://doi.org/10.21691/gpmf.v61i1.102	ПРОДУКТИВНІ ЯКОСТІ ПОРОСЯТ У ВІЦІ ВІД 61 ДО 90 ДІБ ЗА ВИКОРИСТАННЯ ПОВНОРАЦІОННОГО КОМБІКОРМУ, ЗГІДНО З ДСТУ 4124-2002	3
408	Стаття	Целью настоящей работы стало определение влияния добавки кокосового масла на показатели липидного обмена и микробиоценоза в организме крыс, получавших безжировой рацион. Кокосовое масло, содержащее более 70 % среднецепочечных жирных кислот, почти по	2016-07-21	408	https://doi.org/10.21691/gpmf.v61i1.101	ВЛИЯНИЕ КОКОСОВОГО МАСЛА НА ЛИПИДНЫЙ ОБМЕН И МИКРОБИОЦЕНОЗ У ЭКСПЕРИМЕНТАЛЬНЫХ ЖИВОТНЫХ	3
409	Стаття	У роботі розглянуто корисні якості вівса та вівсяного борошна, роаналізовано цінність сировинних компонентів, окреслено їх вплив на здоров’я людини, наведено напрямки практичного застосування. Показано доцільність\nвикористання вівсяного борошна як с	2016-07-21	409	https://doi.org/10.21691/gpmf.v61i1.100	ОБҐРУНТУВАННЯ ВИБОРУ ВІВСЯНОГО БОРОШНА ДЛЯ ВИРОБНИЦТВА НИЗЬКОЖИРНИХ КИСЛОВЕРШКОВИХ СПРЕДІВ	3
410	Стаття	В роботі наведено аналіз ринку йогуртів в Україні, показано споживчі переваги українців при виборі йогуртів з наповнювачами, наведено сегментарний розподіл структури споживання йогуртів в залежності від виду наповнювача. Окреслено перспективи розшир	2016-07-21	410	https://doi.org/10.21691/gpmf.v61i1.99	МАТЕМАТИЧНЕ МОДЕЛЮВАННЯ КОМПОНЕНТНОГО СКЛАДУ КОМБІНОВАНИХ ЙОГУРТОВИХ НАПОЇВ	3
411	Стаття	а основі аналізу науково-технічної літератури встановлено, що зернобобові займають виняткове місце серед продовольчої сировини завдяки унікальному біохімічному складу, обумовленому, головним чином, високим вмістом\nбілка. Зернова квасоля є джерелом ф	2016-07-21	411	https://doi.org/10.21691/gpmf.v61i1.98	ВИЗНАЧЕННЯ ХІМІЧНОГО СКЛАДУ ТА ЯКІСНИХ ХАРАКТЕРИСТИК ЗЕРНОВОЇ КВАСОЛІ БІЛОЇ	3
412	Стаття	В статті показано вплив плазмохімічно активованої води на особливості процесу вологотеплової обробки з огляду на зміни крохмалю зерна пшениці та активність амілолітичних ферментів, присутніх у зерні. Встановлено, що плазмохімічно активована вода зі	2016-07-21	412	https://doi.org/10.21691/gpmf.v61i1.97	ВПЛИВ ПЛАЗМОХІМІЧНО АКТИВОВАНОЇ ВОДИ НА ВУГЛЕВОДНО-АМІЛАЗНИЙ КОМПЛЕКС ЗЕРНА ПШЕНИЦІ	3
413	Стаття	Динамика прогресса в агробизнесе позволяет утверждать, что в первой половине XXI века точная агротехнология станет абсолютной нормой на всех\nконтинентах по той простой причине, что она позво ляет поднять эффективность использования земли. Точная агр	2016-07-21	413	https://doi.org/10.21691/gpmf.v61i1.96	ТОЧНАЯ АГРОТЕХНОЛОГИЯ БУДУЩЕГО НАЧИНАЕТСЯ СЕГОДНЯ. КУКУРУЗА	3
414	Стаття	В статті наведені дослідження з сушіння насіння овочевих культур із визначення режимів сушіння насіннєвого матеріалу.	2019-02-15	414	https://doi.org/10.15673/swonaft.v82i2.1189	ДОСЛІДЖЕННЯ ТЕПЛОМАСОБМІННИХ ПРОЦЕСІВ СУШІННЯ НАСІННЯ ОВОЧЕВИХ КУЛЬТУР	4
415	Стаття	Визначено актуальність дослідження інноваційних способів енергопідводу в процесах сушіння рослинної сировини. Показано основні переваги сушіння вологих матеріалів у мікрохвильовому та інфрачервоному електромагнітному полі. Обґрунтовано вибір моделі	2019-02-15	415	https://doi.org/10.15673/swonaft.v82i2.1242	АПАРАТИ ДЛЯ СУШІННЯ РОСЛИННОЇ СИРОВИНИ ЕЛЕКТРОМАГНІТНИМ ПОЛЕМ	4
757	Стаття	The work is devoted to the study of the biologically active components and the oxidation stability of oils made from non-traditional raw materials such as walnuts and pumpkin seeds. The characteristics that have been determined are the content of ph	2019-04-11	757	https://doi.org/10.15673/fst.v13i1.1311	COMPARATIVE STUDY OF THE BIOLOGICAL VALUE AND OXIDATIVE STABILITY OF WALNUT AND PUMPKIN-SEED OILS	5
416	Стаття	Анотація. В матеріалах розглянуто проблему удосконалення основного та найважливішого процесу виробництва рибних консервів ‑ стерилізації, що гарантує безпечність, стабільність при зберіганні, а також, екологічність готової продукції. Відомо, що одни	2019-02-15	416	https://doi.org/10.15673/swonaft.v82i2.1243	ТЕОРЕТИЧНІ АСПЕКТИ ТА ОБГРУНТУВАННЯ СУЧАСНОГО СПОСОБУ СТЕРИЛІЗАЦІЇ РИБНИХ КОНСЕРВІВ	4
417	Стаття	Abstract. The article describes the interim results of a research project «The improvement of the process wine quality control with new sensor-based devices». The purpose of our work was to develop a block diagram of the device with connected electr	2019-02-15	417	https://doi.org/10.15673/swonaft.v82i2.1273	THE AUTOMATIC CONTROL OF WINE QUALITY ATTRIBUTES	4
418	Стаття	Україна є одним із світових лідерів у постачанні зерна. Невпинно ведеться робота з підвищення врожайності культур та впровадження нових, більш стійких до впливу зовнішніх умов, сортів зернових. Нові сорти потребують вивчення впливу на них умов збері	2019-02-15	418	https://doi.org/10.15673/swonaft.v82i2.1184	ВПЛИВ РІЗНИХ УМОВ ЗБЕРІГАННЯ  НА ЯКІСТЬ ЗЕРНА ПРОСА	4
419	Стаття	В данній статті обгрунтована актуальність досліджень для розширення асортименту м’ясних напівфабрикатів, збагаченних йодом. Приведена характеристика сировини для виробництва м’ясо-рослинних січених напівфабрикатів, які використовуються для профілакт	2019-02-15	419	https://doi.org/10.15673/swonaft.v82i2.1166	ІННОВАЦІЙНІ ТЕХНОЛОГІЇ ПРОТИ ЙОДОДЕФІЦИТУ	4
420	Стаття	Відомо, що різні групи фенольних сполук мають адаптогенні властивості, тому метою досліджень було визначення оптимальних параметрів процесу екстракції листя Ginkgo biloba з метою максимального вилучення фенольних сполук. Визначення проводили спектро	2019-02-15	420	https://doi.org/10.15673/swonaft.v82i2.1165	ВИЗНАЧЕННЯ СУМАРНОГО ВМІСТУ  ФЕНОЛЬНИХ СПОЛУК В ЕКСТРАКТІ З ЛИСТЯ Ginkgo biloba L.	4
421	Стаття	Одним з актуальних наукових напрямків в створенні здорової їжі є застосування нових підходів до розробки рецептур і технологій, що дозволяють створити продукти з новими властивостями, поліпшити якість шляхом введення в склад біологічно активних речо	2019-02-15	421	https://doi.org/10.15673/swonaft.v82i2.1164	ДОСЛІДЖЕННЯ СПОСОБІВ ВИЛУЧЕННЯ  ФІТОКОМПОНЕНТІВ З БУРЯКУ	4
422	Стаття	У роботі розглянуто можливість використання пшеничних висівок як джерела ряда біологічно активних речовин та харчових волокон. Проаналізовано структурні зміни, які відбуваються в клітинах алейронового шару висівок в результаті їх замочування, це в с	2019-02-15	422	https://doi.org/10.15673/swonaft.v82i2.1144	ОЦІНКА ФРАКЦІЙ ВИСІВОК ПШЕНИЦІ ЯК ОБ’ЄКТІВ БІОТЕХНОЛОГІЧНОЇ ПЕРЕРОБКИ	4
423	Стаття	Їстівні покриття і плівки – вид біодеградабельної полімерної упаковки, яка не потребує індивідуального збору та особливих умов утилізації. Активне використання біоупаковки дозволить значно скоротити екологічне навантаження на довкілля. Дослідження з	2019-02-15	423	https://doi.org/10.15673/swonaft.v82i2.1169	ДОСЛІДЖЕННЯ ТЕПЛОФІЗИЧНИХ ХАРАКТЕРИСТИК  ФОРМУВАЛЬНОГО РОЗЧИНУ БІОДЕГРАДАБЕЛЬНОГО  ЇСТІВНОГО ПОКРИТТЯ/ПЛІВКИ	4
424	Стаття	У статті показано, що особливої популярності останнім часом набувають фермен-товані продукти. Однак у процесі виробництва зрілих вин, сирів, ковбас і багатьох рибних продуктів утворюються біогенні аміни в результаті декарбоксилювання вільних аміноки	2019-02-15	424	https://doi.org/10.15673/swonaft.v82i2.1152	ЩОДО ПИТАННЯ ПРО УТВОРЕННЯ БІОГЕННИХ АМІНІВ У ХАРЧОВИХ ПРОДУКТАХ	4
425	Стаття	У статті  обґрунтовано доцільність використання борошна із вичавків винограду сорту Одеський чорний при виробництві комбікормової продукції. Визначено біологічну цінність борошна та виявлено перспективні напрямки його використання. Дослідженнями in	2019-02-15	425	https://doi.org/10.15673/swonaft.v82i2.1153	ОБГРУНТУВАННЯ ДОЦІЛЬНОСТІ ВИКОРИСТАННЯ БОРОШНА З ВИЧАВОК ВИНОГРАДУ ПРИ ВИРОБНИЦТВІ КОМБІКОРМОВОЇ ПРОДУКЦ	4
426	Стаття	У статті проведено аналіз особливостей фізіології годівлі молодняка сільськогосподарської птиці. Доведено, що успішне птахівництво обумовлено використанням сучасних високопродуктивних кросів сільськогосподарської птиці зарубіжної селекції. Вони воло	2019-02-15	426	https://doi.org/10.15673/swonaft.v82i2.1146	ТЕОРЕТИЧНІ ОСНОВИ ФІЗІОЛОГІЇ ГОДІВЛІ  МОЛОДНЯКА СІЛЬСЬКОГОСПОДАРСЬКОЇ ПТИЦІ	4
461	Стаття	Постійний попит на сою і соєві продукти як на внутрішньому, так і зовнішньому ринках України зумовив розширення площі посівів під цією рослиною і вона стала одною з найприбутковіших культур, які вирощуються у сільськогосподарських підприємствах. Пол	2018-08-23	461	https://doi.org/10.15673/swonaft.v82i1.999	ІНТЕНСИФІКАЦІЯ ПРОЦЕСУ СУШІННЯ РОСЛИННОЇ  СУМІШІ З  СОЇ ТА БАТАТУ	4
427	Стаття	У статті досліджено можливості коригування властивостей борошна різної якості технологічними добавками для покращення показників якості хліба. Проведено аналіз основних показників якості борошна хлібопекарського вищого ґатунку, представлених у торго	2019-02-15	427	https://doi.org/10.15673/swonaft.v82i2.1244	КОРИГУВАННЯ ПШЕНИЧНОГО БОРОШНА ІЗ НЕЗАДОВІЛЬНИМИ ХЛІБОПЕКАРСЬКИМИ ВЛАСТИВОСТЯМИ	4
428	Стаття	Анотація. Розвиток комбікормової промисловості характеризується інтенсифікацією технологічних процесів, направлених, в першу чергу, на підвищення санітарної якості. До таких процесів відносять волого-теплову обробку. Вплив волого-теплової обробки на	2019-02-15	428	https://doi.org/10.15673/swonaft.v82i2.1193	ТЕХНОЛОГІЧНА ЕФЕКТИВНІСТЬ УДОСКОНАЛЕННЯ ТЕХНОЛОГІЇ ГРАНУЛЮВАННЯ КОМБІКОРМІВ	4
429	Стаття	Анотація. Пшениця до цього часу залишається основним продуктом харчування у більшості країн світу для великої кількості населення. Важливу роль при визначенні якості пшениці відіграє клейковина, кількість та якість якої є одними з ціноутворюючих пок	2019-02-15	429	https://doi.org/10.15673/swonaft.v82i2.1275	ПОРІВНЯЛЬНІ ХАРАКТЕРИСТИКИ РІЗНИХ СПОСОБІВ  ВІДМИВАННЯ КЛЕЙКОВИНИ	4
430	Стаття	Анотація. Значне розширення об’ємів виробництва зерна кукурудзи спонукало розширенню технології його зберігання в герметичних полімерних зернових рукавах (ПЗР), що дозволяє значно  подовжити терміни безпечного зберігання вологого зерна в умовах недо	2019-02-15	430	https://doi.org/10.15673/swonaft.v82i2.1274	ДОСЛІДЖЕННЯ АГРОТЕХНОЛОГІЧНИХ ХАРАКТЕРИСТИК  ЗЕРНА ОКРЕМИХ ГІБРИДІВ КУКУРУДЗИ	4
431	Стаття	У статті аналізували способи попередньої обробки капусти білоголової, які використовують для традиційної сировини у соковому виробництві і біохімічні методи, які пов’язані з підвищенням клі-тинної проникності та виходу соку. Обґрунтовано доцільність	2019-02-15	431	https://doi.org/10.15673/swonaft.v82i2.1170	ВИКОРИСТАННЯ ПРИЙОМІВ БІОТЕХНОЛОГІЇ ДЛЯ  ПІДВИЩЕННЯ ВИХОДУ СОКУ З КАПУСТИ БІЛОГОЛОВОЇ	4
432	Стаття	В матеріалах статті розглянуто проблему білоквмісних кормів в годівлі сільськогосподарських тварин. Надано функціональну схему виробництва білково-вітамінної добавки біотехнологічним методом, яка включає наступні етапи: підготовка меляси, культивува	2019-02-15	432	https://doi.org/10.15673/swonaft.v82i2.1168	ТЕХНОЛОГІЯ ВИРОБНИЦТВА БІЛКОВО-ВІТАМІННОЇ  ДОБАВКИ БІОТЕХНОЛОГІЧНИМ МЕТОДОМ	4
433	Стаття	Незважаючи на явну необхідність визначення вартості об'єкта інтелектуальної власності, на українському ринку важливість даної оцінки стали розуміти тільки в останні роки. Формування ринку інтелектуальної власності є сьогодні із значущих напрямків ро	2019-02-15	433	https://doi.org/10.15673/swonaft.v82i2.1167	АЛГОРИТМИ ВАРТІСНОГО ОЦІНЮВАННЯ  ІНТЕЛЕКТУАЛЬНОЇ ПРОМИСЛОВОЇ ВЛАСНОСТЇ	4
434	Стаття	У роботі розглянуто нормативні документи, сучасні законодавчі, а також літературні джерела щодо ролі системи простежуваності для гарантування безпечності продуктів харчування. Показано, які існують важливі проблеми у сфері харчування, а саме: наявні	2019-02-15	434	https://doi.org/10.15673/swonaft.v82i2.1157	РОЗВИТОК СИСТЕМИ ПРОСТЕЖУВАНОСТІ У М'ЯСНІЙ  ПРОМИСЛОВОСТІ	4
435	Стаття	На примере подразделения итальянской компании по производству пищевых продуктов выполнен анализ значимости её активов по отношению к рыночной стоимости подразделения и формировании экономической безопасности. Для оценивания уровня экономической безо	2019-02-15	435	https://doi.org/10.15673/swonaft.v82i2.1156	ОЦЕНИВАНИЕ ВЛИЯНИЯ АКТИВОВ ПИЩЕВОГО  ПРЕДПРИЯТИЯ НА ЭКОНОМИЧЕСКУЮ БЕЗОПАСНОСТЬ	4
436	Стаття	Проведений аналіз конвеєрних апаратів для забезпечення необхідного вологовидалення сипкої сільськогосподарської сировини дозволив обґрунтувати ефективність вібраційних конвеєрних схем. Класичні віброконвеєрні машини базуються на електромагнітному ві	2018-08-25	436	https://doi.org/10.15673/swonaft.v82i1.1024	ОБГРУНТУВАННЯ ПАРАМЕТРІВ ПРОЦЕСУ  ІНФРАЧЕРВОНОГО СУШІННЯ ЗЕРНОВОЇ ПРОДУКЦІЇ  З ВІБРОХВИЛЬОВИМ КОНВЕЄРОМ	4
437	Стаття	У даній статті представлено результати досліджень процесів екстрагування у мікрохвильовому полі в умовах зниженого тиску. Об’єктом досліджень обрано плоди шипшини – багаті на термолабільний вітамін С. При екстрагуванні у створеному зразку екстрактора	2018-08-24	437	https://doi.org/10.15673/swonaft.v82i1.1004	ВАКУУМНІ МІКРОХВИЛЬОВІ ТЕХНОГІЇ ПРИ ВИРОБНИЦТВІ  ФІТОПРЕПАРАТІВ З ПЛОДІВ ШИПШИН	4
438	Стаття	Рассмотрены мировые тенденции на рынке сушеных продуктов и концентратов. Анализируются энерготехнологии основных процессов обезвоживания – выпарки и сушки. Сравниваются современные технологи обезвоживания и обсуждаются научно-технические противоречи	2018-08-23	438	https://doi.org/10.15673/swonaft.v82i1.1023	ИССЛЕДОВАНИЕ ЭНЕРГОТЕХНОЛОГИЙ ПРОЦЕССОВ  ОБЕЗВОЖИВАНИЯ  РАСТИТЕЛЬНОГО СЫРЬЯ	4
439	Стаття	Метою роботи є вивчення впливу ультразвуку малої потужності на процеси тепло- і масообміну в установках блочного виморожування. Доведено, що ефективним засобом управління потоками енергії при блочному виморожування є застосування ультразвукового пол	2018-08-23	439	https://doi.org/10.15673/swonaft.v82i1.1022	ПІДВИЩЕННЯ ЕФЕКТИВНОСТІ ПРОЦЕСУ ОЧИСТКИ ВОДИ МЕТОДОМ БЛОЧНОГО ВИМОРОЖУВАННЯ	4
440	Стаття	Удаление влаги из пищевого сырья является одной из ключевых и наиболее энергозатратных задач пищевых технологий. Наиболее распространенными технологиями обезвоживания являются выпаривание и сушка. При этом енергетический КПД процесса сушки в 2 и бол	2018-08-23	440	https://doi.org/10.15673/swonaft.v82i1.1021	ИННОВАЦИОННЫЕ РЕШЕНИЯ В ТЕХНОЛОГИЯХ ОБЕЗВОЖИВАНИЯ	4
441	Стаття	Для інтенсифікації процесу вакуум-випарювання запропоновано забезпечити рівномірність енергопідведення і виключити проміжний теплоносій за рахунок використання мікрохвильових технологій. При мікрохвильовому підведенні енергія надходить безпосередньо	2018-08-23	441	https://doi.org/10.15673/swonaft.v82i1.1020	МЕТОДИКА РОЗРАХУНКУ ПРОЦЕСУ КОНЦЕНТРУВАННЯ  ХАРЧОВИХ РОЗЧИНІВ ТА ЕКСТРАКТІВ У МІКРОХВИЛЬОВОМУ ВАКУУМ-ВИПАРНОМУ АПАРАТІ	4
442	Стаття	В статті наводяться результати досліджень щодо застосування гідроциклонів для відокремлення твердих частинок з виноградного сусла, виноградного насіння з вичавок, а також для освітлення дифузійного соку після екстракції виноградних вичавок, стічних в	2018-08-23	442	https://doi.org/10.15673/swonaft.v82i1.1019	АПАРАТИ ДЛЯ РОЗДІЛЕННЯ ПРОДУКТІВ ВИНОРОБСТВА	4
443	Стаття	У даній статті  розглядаються способи підвищення ефективності, оптимізації та інтенсифікації процесів сепарації та сепараційного обладнання установок стабілізації нафти/конденсату. Робота включає в себе теоретичне ознайомлення з процесом сепарації г	2018-08-23	443	https://doi.org/10.15673/swonaft.v82i1.1018	ОПТИМІЗАЦІЙНЕ КОМПОНУВАННЯ ФАЗНИХ  РОЗДІЛЮВАЧІВ З ЗАСТОСУВАННЯМ МОДУЛЬНИХ  СЕПАРАЦІЙНИХ ПРИСТРОЇВ	4
444	Стаття	Проведений аналіз конвеєрних апаратів для забезпечення необхідного вологовидалення сипкої сільськогосподарської сировини дозволив обґрунтувати ефективність вібраційних конвеєрних схем. Класичні віброконвеєрні машини базуються на електромагнітному ві	2018-08-23	444	https://doi.org/10.15673/swonaft.v82i1.1017	ОБҐРУНТУВАННЯ ЕНЕРГОЕФЕКТИВНИХ РЕЖИМІВ РОБОТИ  БАРАБАННОЇ СУШАРКИ КОМПЛЕКСУ ВИРОБНИЦТВА  КОМПОЗИЦІЙНОГО БІОПАЛИВА	4
445	Стаття	У роботі розглянуто можливість отримання імунотропної дієтичної добавки на основі низькомолекулярних продуктів деградації пептидогліканів клітинних стінок пробіотичних бактерій. Встановлено раціональні режими автолізу біомаси як первинного етапу дес	2018-08-23	445	https://doi.org/10.15673/swonaft.v82i1.1016	ДІЄТИЧНА ДОБАВКА ІМУНОТРОПНОЇ ДІЇ НА ОСНОВІ  ПРОДУКТІВ ДЕСТРУКЦІЇ ПРОБІОТИЧНИХ  БАКТЕРІАЛЬНИХ КУЛЬТУР	4
446	Стаття	В роботі наведено літературні дані щодо впливу розчинних речовин різного типу на процес та механізм зв’язування води. Порівняно результати визначення стану води у вихідній рослинній сировині, які були отримані з розрахунку за межею гігроскопічності,	2018-08-23	446	https://doi.org/10.15673/swonaft.v82i1.1015	ВПЛИВ РОЗЧИННИХ РЕЧОВИН НА СТАН ВОДИ  В РОСЛИННИХ ТКАНИНАХ ТА КІНЕТИКУ ЇХ СУШІННЯ	4
447	Стаття	Створено комплекс технічних засобів, що включає обладнання і блоки пресування насіння, адсорбентної рафінації, гідратації і коагуляції, центрифугування і дезодорації, очищення і мікрофільтрації олії. Конструкції технічних засобів дозволяють компонува	2018-08-23	447	https://doi.org/10.15673/swonaft.v82i1.1014	ФОРМУВАННЯ ТЕХНОЛОГІЇ ОЧИСТКИ РОСЛИННОЇ ОЛІЇ В УМОВАХ МІНІ-ЦЕХІВ	4
448	Стаття	Ефективне управління твердими муніципальними відходами є першочерговим завданням у сфері міжнародної та національної екологічної безпеки. В Україні воно фактично вирішується через зберігання сотень тисяч відходів на керованих та некерованих звалищах	2018-08-23	448	https://doi.org/10.15673/swonaft.v82i1.1013	ДОСЛІДЖЕННЯ ПРОЦЕСІВ КОМПОСТУВАННЯ ХАРЧОВОЇ СКЛАДОВОЇ ТВЕРДИХ МУНІЦИПАЛЬНИХ ВІДХОДІВ  З ВИКОРИСТАННЯМ МІНЕРАЛЬНИХ ДОБАВОК	4
450	Стаття	В роботі приведено результати досліджень кінетики вилучення білків з модельного середовища, зміни оптичної густини дисперсій білка в результаті дії на досліджувану дисперсію випромінювання надвисокочастотного діапазону. Процес денатурації дисперсій	2018-08-23	450	https://doi.org/10.15673/swonaft.v82i1.1011	ВИЛУЧЕННЯ БІЛКІВ ЗІ СТІЧНИХ ВОД ХАРЧОВИХ  ВИРОБНИЦТВ ШЛЯХОМ ЗАСТОСУВАННЯ НВЧ  ВИПРОМІНЮВАННЯ	4
451	Стаття	Відходи сучасних виробництв становлять серйозну загрозу для навколишнього середовища, що спонукає до розробки новітніх методів їх утилізації.  Вміст вуглекислого газу в атмосфері вже давно є предметом обговорення на політичному рівні держав світу, л	2018-08-23	451	https://doi.org/10.15673/swonaft.v82i1.1010	ІНГІБІТОРИ ТА АКТИВАТОРИ ПРОЦЕСУ  ПОГЛИНАННЯ ВУГЛЕКИСЛОГО ГАЗУ ХЛОРОФІЛСИНТЕЗУЮЧИМИ  МІКРОВОДОРОСТЯМИ	4
452	Стаття	Важливою складовою собівартості продукції харчових виробництв є елементи забезпечення їх безпечного виробництва, одним з яких являється внутрішній протипожежний водопровід, який обов’язковий для встановлення в приміщеннях харчових виробництв з відпо	2018-08-23	452	https://doi.org/10.15673/swonaft.v82i1.1009	ДОСЛІДЖЕННЯ ГІДРОДИНАМІЧНИХ ХАРАКТЕРИСТИК ЕЛЕМЕНТІВ ЗАХИСТУ ХАРЧОВИХ ВИРОБНИЦТВ	4
453	Стаття	Разработана математическая модель и численный метод расчета динамики тепломассопереноса, фазовых превращений и усадки при сушке коллоидных капиллярно-пористых тел цилиндрической формы в условиях равномерного обдува теплоносителем. Математическая мод	2018-08-23	453	https://doi.org/10.15673/swonaft.v82i1.1008	МАТЕМАТИЧЕСКАЯ МОДЕЛЬ И МЕТОД РАСЧЕТА ДИНАМИКИ СУШКИ И ТЕРМОДЕСТРУКЦИИ БИОМАССЫ	4
454	Стаття	Проведено огляд і аналіз літературних джерел, які відображають основні результати та напрямки досліджень процесу розчинення під час пневматичного перемішування. Вони показують, які проблемні напрями науки потребують детальніших досліджень. Обгрунтов	2018-08-23	454	https://doi.org/10.15673/swonaft.v82i1.1007	МОДЕЛЮВАННЯ РУХУ БУЛЬБАШОК СТИСНЕНОГО ПОВІТРЯ У АПАРАТІ З ПНЕВМАТИЧНИМ ПЕРЕМІШУВАННЯМ	4
455	Стаття	Універсальна моделююча програма ChemCad дозволяє провести моделювання процесу насичення плодів гарбуза цукром. Результати моделювання дають можливість здійснення технологічного процесу з мінімальними енергозатратами та максимальним збереженням пожив	2018-08-23	455	https://doi.org/10.15673/swonaft.v82i1.1006	МОДЕЛЮВАННЯ ІЗОТЕРМІЧНОГО РЕАКТОРА ДЛЯ  НАСИЧЕННЯ САХАРОЗОЮ ЦУКАТІВ З ГАРБУЗА	4
456	Стаття	На сьогодні задача акумулювання теплової енергії є досить актуальною. Перспективним напрямком є використання теплоакумулюючих матеріалів з фазовим переходом. При цьому важливо вибрати матеріал, який зможе забезпечити теплові та експлуатаційні параме	2018-08-23	456	https://doi.org/10.15673/swonaft.v82i1.1005	МОДЕЛЮВАННЯ ФАЗОВИХ ПЕРЕХОДІВ «ТВЕРДЕ  ТІЛО - РІДИНА» ТЕПЛОАКУМУЛЮЮЧИХ МАТЕРІАЛІВ ПРИ ДОСЛІДЖЕННІ ПРОЦЕСУ ТЕПЛООБМІНУ	4
457	Стаття	Досліджені експлуатаційні характеристики адсорбційного регенератора низько-потенційного тепла та вологи на основі композитних сорбентів «силікагель – натрій сульфат», синтезованих золь – гель методом. Розроблені математична модель та алгоритм визнач	2018-08-23	457	https://doi.org/10.15673/swonaft.v82i1.1003	PERFORMANCE CHARACTERISTICS OF ADSORPTIVE  REGENERATOR OF LOW-POTENTIAL HEAT AND MOISTURE BASED ON COMPOSITE ADSORBENTS ‘SILICA GEL – SODIUM SULPHATE’ SYNTHESIZED BY SOL – GEL METHOD	4
458	Стаття	Досліджувався процес екстрагування твердої речовини з капілярів циліндричної форми з метою визначення кінетики даного процесу. Твердою фазою служив купруму сульфат, який екстрагувався дистильованою водою. Екстрагування твердої фази складається з про	2018-08-23	458	https://doi.org/10.15673/swonaft.v82i1.1002	КІНЕТИКА ЕКСТРАГУВАННЯ КУПРУМУ СУЛЬФАТУ З ОДИНАРНОГО КАПІЛЯРА  В УМОВАХ ВАКУУМУВАННЯ СИСТЕМИ	4
459	Стаття	В процесі розвитку технічного прогресу харчова промисловість вимагає нових технологічних рішень для підвищення якості харчових продуктів. Сегмент ринку снеків в наш час дуже поширений та популярний серед споживачів, проте якість цих снеків бажала б	2018-08-23	459	https://doi.org/10.15673/swonaft.v82i1.1001	ВПЛИВ ШВИДКОСТІ РУХУ ПОВІТРЯ НА ПРОЦЕС  КОНВЕКТИВНО-ТЕРМОРАДІАЦІЙНОГО СУШІННЯ  ЯБЛУЧНИХ СНЕКІВ	4
460	Стаття	В статті розглянуті питання, пов’язані із виникненням і розвитком явища гідродинамічної кавітації при обробці рідких середовищ. Показана актуальність і можливості практичного використання ефектів, що супроводжують гідродинамічну кавітацію, для інтен	2018-08-23	460	https://doi.org/10.15673/swonaft.v82i1.1000	ВПЛИВ ГІДРОДИНАМІЧНОЇ КАВІТАЦІЇ  НА ЗМІНУ ТЕМПЕРАТУРНИХ ПОКАЗНИКІВ ВОДИ	4
462	Стаття	Використання методів пасивної інтенсифікації у вигляді поверхонь з капілярно-пористим покриттям в контактних апаратах істотно ускладнює гідродинамічну картину взаємодії системи «поверхня – плівка рідини – газовий потік». Інтенсифікуючи процеси тепло	2018-08-23	462	https://doi.org/10.15673/swonaft.v82i1.998	ДОСЛІДЖЕННЯ СТІЙКОСТІ ТЕЧІЇ ГРАВІТАЦІЙНО СТІКАЮЧОЇ ПЛІВКИ РІДИНИ В ДВОФАЗНИХ СИСТЕМАХ	4
463	Стаття	Целью данной работы является раскрыть механизмы воздействия кавитации на биологические клетки для создания новых технологий и оборудования, а также усовершенствования уже существующих. Анализ современной литературы показал, что процесс кавитации широ	2018-08-23	463	https://doi.org/10.15673/swonaft.v82i1.997	ВОЗДЕЙСТВИЕ ГИДРОДИНАМИЧЕСКОЙ КАВИТАЦИИ НА БИОЛОГИЧЕСКИЕ КЛЕТКИ.  МЕХАНИЗМЫ, ТЕХНОЛОГИИ, ПРИМЕНЕНИЕ	4
464	Стаття	В роботі розглянуто низку питань, пов’язаних з теплообмінними процесами, які відбуваються у промислових вуглевипалювальних установках. Дослідження спрямоване на пошук розрахункового алгоритму, який здатен еквівалентно врахувати вплив структури компо	2018-08-23	464	https://doi.org/10.15673/swonaft.v82i1.996	ВИВЧЕННЯ ВПЛИВУ РАДІАЦІЙНОЇ СКЛАДОВОЇ НА ВЕЛИЧИНУ ЕФЕКТИВНОЇ ТЕПЛОПРОВІДНОСТІ  КОМПОЗИТНО-ПОРИСТОГО МАСИВУ	4
465	Стаття	Чотири мільярди людей мінімум один місяць в році зустрічаються з дефіцитом прісної води. В 2030 р до 47 % населення світу буде жити під загрозою водного дефіциту. Такі перспективи значно підвищують важливість отримання очищеної води. Існує зростаючи	2018-05-09	465	https://doi.org/10.15673/swonaft.v81i2.914	ДОСЛІДЖЕННЯ ВПЛИВУ УЛЬТРАЗВУКОВОГО ПОЛЯ НА ЕНЕРГОЕФЕКТИВНІСТЬ ПРОЦЕСУ ВИМОРОЖУВАННЯ БЛОКУ ЛЬОДУ	4
466	Стаття	В Україні діє понад 22 тисяч виробників харчових продуктів, що використовують різні види упаковки, які часто поступаються кращим вітчизняним та іноземним аналогам за рівнем дизайну. З усієї цієї кількості вітчизняних виробників тільки кілька сотень	2018-05-09	466	https://doi.org/10.15673/swonaft.v81i2.913	ОЦІНЮВАННЯ РІВНЯ ДИЗАЙНУ УПАКОВОК ХАРЧОВИХ ПРОДУКТІВ КІЛЬКІСНИМ МЕТОДОМ	4
467	Стаття	Рассматривается компьютерное моделирование множественной регрессии экспериментальных данных, относящихся к детерминированным техническим и технологическим системам.\n\nПервичную информацию (статистическую модель) исследуемого объекта, часто представля	2018-05-09	467	https://doi.org/10.15673/swonaft.v81i2.912	КОМПЬЮТЕРНОЕ МОДЕЛИРОВАНИЕ МНОЖЕСТВЕННОЙ РЕГРЕССИИ	4
468	Стаття	Мета статті розробити рекомендації щодо підвищення енергоефективності і зменшення техногенного навантаження біогазової установки на навколишнє середовище.\n\nІз збільшенням уваги до раціонального споживання свіжої води, як наслідок знижується її спожи	2018-05-09	468	https://doi.org/10.15673/swonaft.v81i2.911	ЕКОНОМІЯ ВОДИ В ТЕХНОЛОГІЧНИХ ПРОЦЕСАХ БІОГАЗОВОЇ УСТАНОВКИ	4
469	Стаття	Обговорюються технологічні проблеми одного із ключових процесів харчових технологій — концентрування розчинів (соків, екстрактів, тощо). Аналізуються енерготехнології традиційних випарних апаратів. У статті формулюються проблеми та наукові протирічч	2018-05-09	469	https://doi.org/10.15673/swonaft.v81i2.910	ЗАСТОСУВАННЯ ЕЛЕКТРОМАГНІТНИХ ДЖЕРЕЛ ЕНЕРГІЇ В ІННОВАЦІЙНИХ ТЕХНОЛОГІЯХ ПЕРЕРОБКИ ХАРЧОВОЇ СИРОВИНИ	4
470	Стаття	У роботі наведено асортимент, властивості та склад засобів для тонізації шкіри; проаналізовано ринок тоніків і лосьйонів в Україні, ефективність використання лізатів пробіотичних культур лакто— і біфідобактерій у косметичних продуктах та доцільність	2018-05-09	470	https://doi.org/10.15673/swonaft.v81i2.909	ОПТИМІЗАЦІЯ СКЛАДУ ТОНІКА З ПРОБІОТИКАМИ ДЛЯ СУХОЇ ШКІРИ	4
471	Стаття	Прогресивний ринок косметики диктує створення нових видів продукції, зокрема з використанням рослинної сировини та екстрактів на її основі. При цьому у якості фітоматеріалів використовують листя, плоди, ягоди, корені різних рослин; у якості екстраге	2018-05-09	471	https://doi.org/10.15673/swonaft.v81i2.908	ЕКСТРАКТИ FRUCTUS ROSAE ЯК ФІТОСИРОВИНА ДЛЯ ВИРОБНИЦТВА КОСМЕТИЧНИХ ПРОДУКТІВ	4
472	Стаття	У роботі наведено вимоги до натуральної і органічної косметики; обґрунтовано необхідність розробки новітніх інгредієнтів для виробництва натуральних і органічних косметичних засобів на основі молочної сироватки.\n\nНаведено розроблену авторами схему к	2018-05-09	472	https://doi.org/10.15673/swonaft.v81i2.907	НОВІТНІ ІНГРЕДІЄНТИ ДЛЯ НАТУРАЛЬНОЇ КОСМЕТИКИ НА ОСНОВІ МОЛОЧНОЇ СИРОВАТКИ	4
473	Стаття	У роботі наведено наукове обґрунтування використання пробіотичних культур біфідо— і лактобактерій та молочно—рослинних систем при розробці інноваційних технологій комбінованих ферментованих харчових продуктів з радіопротекторними і пробіотичними вла	2018-05-09	473	https://doi.org/10.15673/swonaft.v81i2.906	НОВІ КОМБІНОВАНІ ПРОДУКТИ З РАДІОПРОТЕКТОРНИМИ ВЛАСТИВОСТЯМИ І ЗБАЛАНСОВАНИМ ХІМІЧНИМ СКЛАДОМ ДЛЯ ВІЙСЬКОВОСЛУЖБОВЦІВ: ПЕРСПЕКТИВИ ВИРОБНИЦТВА	4
474	Стаття	Наведений аналіз сучасного стану готельної індустрії Одеської області, здійснено розгляд недоліків і визначення перспектив розвитку індустрії гостинності в цьому регіоні. Зазначено, що завдяки особливостям економіко—географічного розташування, розви	2018-05-09	474	https://doi.org/10.15673/swonaft.v81i2.905	ЕКОНОМІЧНІ ПЕРЕДУМОВИ РОЗВИТКУ ІНДУСТРІЇ ГОСТИННОСТІ В ОДЕСЬКІЙ ОБЛАСТІ	4
475	Стаття	У роботі представлено основні властивості збагачених біокоректорами харчових продуктів; наведено аналіз тенденцій світового ринку щодо розширення асортименту олійно—жирових продуктів, сучасні тенденції створення збагачених майонезних соусів зі збала	2018-05-09	475	https://doi.org/10.15673/swonaft.v81i2.904	ДОСЛІДЖЕННЯ ЯКОСТІ ЕМУЛЬСІЇ МАЙОНЕЗНИХ СОУСІВ, ЗБАГАЧЕНИХ БІОКОРЕКТОРАМИ	4
476	Стаття	У роботі, на основі аналізу ринку продуктів для вагітних жінок, наведені перспективи розробки молочних продуктів для харчування вагітних жінок з підвищеними пробіотичними, антагоністичними властивостями та подовженим терміном зберігання. Наведені ви	2018-05-09	476	https://doi.org/10.15673/swonaft.v81i2.903	ОБҐРУНТУВАННЯ ПАРАМЕТРІВ ФЕРМЕНТАЦІЇ СИРОВИНИ У ВИРОБНИЦТВІ НАПОЮ ДЛЯ ХАРЧУВАННЯ ВАГІТНИХ	4
477	Стаття	Мета статті — визначення придатності води для технологічних цілей у пивоварінні, дослідження впливу показників якості води на смакові дескриптори пива.\n\nУ процесі дослідження використовували зразки світлого пива з масовою часткою сухих речовин у поч	2018-05-09	477	https://doi.org/10.15673/swonaft.v81i2.902	ВПЛИВ ЯКОСТІ ПІДГОТОВКИ ВОДИ НА ОРГАНОЛЕПТИЧНІ ПОКАЗНИКИ ПИВА	4
478	Стаття	Дослідження в статті направлені на визначення хлібопекарських властивостей пшеничного борошна вищого сорту з різних регіонів України, виробленого на борошномельних заводах у 2016 р. Проведено оцінку білості, кількості та якості клейковини, вмісту бі	2018-05-09	478	https://doi.org/10.15673/swonaft.v81i2.901	АНАЛІЗ ЯКОСТІ БОРОШНА З РІЗНИХ РЕГІОНІВ УКРАЇНИ	4
479	Стаття	В статті наведено результати дослідження впливу плівкоутворювача полівінілового спирту (ПВС) на властивості їстівних плівок на основі картопляного крохмалю та желатину. Мета статті полягала у дослідженні впливу ПВС на динамічну в’язкість, температур	2018-05-09	479	https://doi.org/10.15673/swonaft.v81i2.900	ВПЛИВ ПОЛІВІНІЛОВОГО СПИРТУ НА ВЛАСТИВОСТІ ЇСТІВНИХ ПЛІВОК НА ОСНОВІ КАРТОПЛЯНОГО КРОХМАЛЮ І ЖЕЛАТИНУ	4
480	Стаття	Метою статті є обґрунтування розробки технології заморожених напівфабрикатів млинців підвищеної харчової цінності з ламінарією для профілактики дефіциту йоду та його несприятливих наслідків у населення України. На підставі моніторингу ринку харчової	2018-05-09	480	https://doi.org/10.15673/swonaft.v81i2.898	ПЕРСПЕКТИВИ ВИРОБНИЦТВА НАПІВФАБРИКАТІВ МЛИНЦІВ З ЙОДОВМІСНИМИ НАЧИНКАМИ	4
481	Стаття	Вивчення видового та кількісного складу мікрофлори, особливо нових сортів, має велике значення для розробки й застосування на практиці прийомів зберігання насіння з метою подальшого його використання в харчовій і комбікормовій промисловості.\n\nВ робо	2018-05-09	481	https://doi.org/10.15673/swonaft.v81i2.899	ДОСЛІДЖЕННЯ ПОКАЗНИКІВ САНІТАРНОЇ БЕЗПЕКИ НОВИХ СОРТІВ ЛЬОНУ	4
482	Стаття	Розглянуто можливість отримання біологічно активних складових пептидогліканів клітинних стінок Lactobacillus acidophilus K 3111шляхом послідовної обробки біомаси ультразвуком та папаїном. Біомасу піддавали обробці ультразвуком з робочою частотою 25,	2018-05-09	482	https://doi.org/10.15673/swonaft.v81i2.897	КОМБІНОВАНИЙ МЕТОД ДЕЗІНТЕГРАЦІЇ МІКРОБІАЛЬНОЇ БІОМАСИ	4
483	Стаття	Вращением кривой Персея построена поверхность эритроцита, определена его площадь поверхности и объём. В реальной крови они распределены по нормальному закону. Проведено сопоставление численных характеристик объёмов эритроцитов (по данным Чижевского	2018-01-27	483	https://doi.org/10.15673/swonaft.v0i48.812	ГЕОМЕТРИЯ ЭРИТРОЦИТА	4
536	Стаття	Vacuum evaporation is widely used in the food technologies. The equipment for this process is well \nknown and methods of calculation and design of vacuum evaporators are described in literature as well. However, \nin some cases the accuracy of existin	2017-12-08	536	https://doi.org/10.15673/swonaft.v81i1.724	EXPERIMENTAL STUDIES OF BOILING HEAT TRANSFER  OF FOOD SOLUTIONS	4
484	Стаття	Стаття присвячена питанню використання системи НАССР для забезпечення якості\nта безпечності продуктів харчування на підприємствах роздрібної торгівлі. На прикладі умовного тор-\nгівельного підприємства на якому передбачено виробництво булочних виробі	2018-01-27	484	https://doi.org/10.15673/swonaft.v0i48.811	ВИКОРИСТАННЯ ПРИНЦИПІВ НАССР ДЛЯ ЗАБЕЗПЕЧЕННЯ ЯКОСТІ ТА БЕЗПЕЧНОСТІ ПРОДУКТІВ НА ПІДПРИЄМСТВАХ РОЗДРІБНОЇ ТОРГІВЛІ	4
485	Стаття	Розглянуто основні питання, які стосуються культури і сервісу обслуговування, що постають при\nнаданні послуг в готелях. На прикладі готелю «Вікторія» (м. Одеса) показано впровадження інновацій в\nцій сфері. Інновації стосуються професійної етики, пов	2018-01-27	485	https://doi.org/10.15673/swonaft.v0i48.810	ІННОВАЦІЇ В КУЛЬТУРІ І СЕРВІСІ ОБСЛУГОВУВАННЯ В ГОТЕЛЬНОМУ ГОСПОДАРСТВІ	4
486	Стаття	Статья посвящена вопросу возникновения и развития такого понятия в дизайне как стилевое направление. Рассмотрены основные виды дизайна и их объекты, а также факторы, влияющие на принятие тех или иных дизайнерских решений. Предложена структура дизайн	2018-01-27	486	https://doi.org/10.15673/swonaft.v0i48.809	РАЗВИТИЕ СТИЛЕВОГО НАПРАВЛЕНИЯ В ДИЗАЙНЕ	4
487	Стаття	Проведён расчёт конкурентоспособности процесса формообразования изделий из разрабатываемого композиционного материала на основе неметаллической матрицы и металлического наполнителя.\nПостроены диаграмма соотношения факторов конкурентоспособности изде	2018-01-27	487	https://doi.org/10.15673/swonaft.v0i48.808	РАСЧЕТ КОНКУРЕНТОСПОСОБНОСТИ ПРОЦЕССА ФОРМООБРАЗОВАНИЯ КОМПОЗИЦИОННЫХ МАТЕРИАЛОВ	4
488	Стаття	Разработан метод и показатели для оценивания уровня дизайна технологического оборудования для\nпищевой промышленности. Выполнено оценивание уровня дизайна с использованием предложенного метода, комплексных и единичных показателей на примере зерновых	2018-01-27	488	https://doi.org/10.15673/swonaft.v0i48.807	ОЦЕНИВАНИЕ УРОВНЯ ДИЗАЙНА НА ПРИМЕРЕ ТЕХНОЛОГИЧЕСКОГО ОБОРУДОВАНИЯ В ПИЩЕВОЙ ПРОМЫШЛЕННОСТИ	4
631	Стаття	Виконано моделювання процесу перемішування компонентів комплексного добрива.\nModeling the process of mixing the components of complex fertilizers.	2017-05-31	631	https://doi.org/10.15673/swonaft.v1i47.358	МОДЕЛЮВАННЯ ПРОЦЕСУ СТВОРЕННЯ КОМПЛЕКСНИХ МІНЕРАЛЬНО-ОРГАНІЧНИХ ДОБРИВ З ВИКОРИСТАННЯМ КІСТКОВОГО БОРОШНА	4
489	Стаття	В статті виконано моделювання деформаційної поведінки мембран металевих кришок консервної\nскляної тари під час зберігання та оброблення пакованої продукції. На базі основного розрахункового\nрівняння в середовищі MATLAB R2008a було розроблено комп’ют	2018-01-27	489	https://doi.org/10.15673/swonaft.v0i48.806	МОДЕЛЮВАННЯ РОБОТИ МЕМБРАН ВАКУУМНИХ КРИШОК: ПРОГИН, ТОВЩИНА	4
490	Стаття	Предложен новый метод изучения гистерезиса поляризация — напряженность поля на основе соответствующего изучения экспериментально зарегистрированной кинетики электретного потенциала в\nпроцессе коронной электризации при постоянном токе зарядки. В тех	2018-01-27	490	https://doi.org/10.15673/swonaft.v0i48.805	ПОСТРОЕНИЕ ПЕТЛИ ГИСТЕРЕЗИСА «ПОЛЯРИЗАЦИЯ – НАПРЯЖЕННОСТЬ ПОЛЯ» В СЕГНЕТОЭЛЕКТРИЧЕСКИХ ПОЛИМЕРАХ	4
491	Стаття	В статье рассмотрен вопрос обоснованного выбора диапазонов настроечных параметров тестовых систем автоматического регулирования для исследования алгоритмов их самонастройки. Приведена базовая структура системы с самонастройкой к изменяющемуся коэффи	2018-01-27	491	https://doi.org/10.15673/swonaft.v0i48.804	ТЕСТОВЫЕ САР ДЛЯ ИССЛЕДОВАНИЯ АЛГОРИТМОВ ИХ САМОНАСТРОЙКИ	4
492	Стаття	Экспериментально установлено, что при освещении односторонне металлизированных короноэлек-\nтретов из политетрафторэтилена (ПТФЭ) возникают обратимые фототоки смещения, направление\nкоторых противоположно току, обусловленному движением поверхностных з	2018-01-27	492	https://doi.org/10.15673/swonaft.v0i48.803	ПЕРЕХОДНЫЕ ТОКИ В НЕПОЛЯРНЫХ ПОЛИМЕРНЫХ ЭЛЕКТРЕТАХ	4
493	Стаття	Предложена модель, предполагающая объемную фотоионизацию акцепторных примесных центров\nи движение образованных носителей в сильном внутреннем поле при УФ-облучении пленок политет-\nрафторэтилена (ПТФЭ). Из сравнения экспериментальных и расчетных крив	2018-01-27	493	https://doi.org/10.15673/swonaft.v0i48.802	ФОТОТОКИ ПРИ УФ-ОБЛУЧЕНИИ ЗАРЯЖЕННЫХ ПЛЕНОК ПОЛИТЕТРАФТОРЭТИЛЕНА	4
758	Стаття	The problems considered in the paper are the incidence of dysbiosis in the Ukrainian people, the reasons for it, and the methods of improving the diet of those suffering from microfloral disorders. Useful properties and effects of the microorganisms	2019-04-11	758	https://doi.org/10.15673/fst.v13i1.1310	SYNBIOTIC ADDITIVES IN THE WAFFLES TECHNOLOGY	5
494	Стаття	В результате проведенных исследований установлено количественный и качественный состав ле-\nтучих ароматических веществ виноматериалов из винограда сортов Алиготе, Пино Блан, Пино Гри,\nРислинг, Совиньон Блан и Шардоне урожая 2014 года (ООО «ПТК Шабо»	2018-01-27	494	https://doi.org/10.15673/swonaft.v0i48.801	РЕЗУЛЬТАТЫ ИССЛЕДОВАНИЯ АРОМАТИЧЕСКИХ СОЕДИНЕНИЙ ВИНОМАТЕРИАЛОВ ИЗ БЕЛЫХ СОРТОВ ВИНОГРАДА ООО «ПТК ШАБО»	4
495	Стаття	Показана возможность определения галловой кислоты (ГК) в винах с использованием в качестве\nлюминесцентного маркера ионы тербия (III). Разработана простая и надежная методика количествен-\nного определения ГК в винах методом тонкослойной хроматографии	2018-01-27	495	https://doi.org/10.15673/swonaft.v0i48.800	ЛЮМИНЕСЦЕНТНЫЙ МАРКЕР ДЛЯ ОПРЕДЕЛЕНИЯ ПОДЛИННОСТИ ВИНОГРАДНЫХ ВИН	4
496	Стаття	У роботі вивчено вплив оброблення високим гідростатичним тиском на термін зберігання «Шинки з\nбілого м'яса». Особливістю нового продукту є відсутність в рецептурі нітриту натрію, використання\nнатуральних інгредієнтів замість комбі-домішок. Для вироб	2018-01-27	496	https://doi.org/10.15673/swonaft.v0i48.799	ВИЗНАЧЕННЯ ТЕРМІНУ ЗБЕРІГАННЯ ШИНКИ З М'ЯСА ПТИЦІ, ВИГОТОВЛЕНОЇ АТЕРМІЧНИМ ОБРОБЛЕННЯМ	4
497	Стаття	Їстівні плівкоутворюючі покриття можуть покращити якість свіжого, замороженого або обробленого м'яса, птиці та морепродуктів, затримуючи втрату вологи, знижуючи окиснення жирів і запобі-\nгаючи знебарвленню, покращити зовнішній вигляд продукту в упак	2018-01-27	497	https://doi.org/10.15673/swonaft.v0i48.798	ВИКОРИСТАННЯ ПЛІВКОУТВОРЮЮЧИХ ПОКРИТТІВ В М’ЯСНІЙ ПРОМИСЛОВОСТІ	4
498	Стаття	У статті наведено результати досліджень впливу електроактивованої води на мікробіологічні показники м’яса. Проведено порівняльний аналіз впливу процесу електролізу на мікробіологічні показники\nпитної води. Визначено дію електроактивованої води на ро	2018-01-27	498	https://doi.org/10.15673/swonaft.v0i48.797	ВПЛИВ ЕЛЕКТРОАКТИВОВАНОЇ ВОДИ НА МІКРОБІОЛОГІЧНІ ПОКАЗНИКИ М’ЯСНОЇ СИРОВИНИ	4
499	Стаття	В статті показано вплив рецептурного складу білкових паст для дитячого харчування на динаміку\nприросту маси тіла, гематологічних показників крові та складу індигенної мікрофлори відлучених щуре-\nнят. Встановлено, що досліджені білкові пасти доброякі	2018-01-27	499	https://doi.org/10.15673/swonaft.v0i48.796	МЕДИКО-БІОЛОГІЧНІ ДОСЛІДЖЕННЯ БІЛКОВИХ ПАСТ ДЛЯ ДИТЯЧОГО ХАРЧУВАННЯ	4
717	Стаття	The Palais-Smale condition was introduced by Palais and Smale in the mid-sixties and applied to an extension of Morse theory to infinite dimensional Hilbert spaces. Later this condition was extended by Palais for the more general case of real functi	2018-06-10	717	https://doi.org/10.15673/tmgc.v11i1.915	A Generalized Palais-Smale Condition in the Fr\\'{e}chet space setting	6
500	Стаття	В данной работе проведены сравнительные исследования динамики роста культуры Bifidobacterium\nbifidum при культивировании на стандартных классических средах и на лактозной среде с добавлением\nразличной массовой доли соевой сыворотки. Установлено необ	2018-01-27	500	https://doi.org/10.15673/swonaft.v0i48.795	УСОВЕРШЕНСТВОВАНИЕ СОСТАВА ПИТАТЕЛЬНОЙ СРЕДЫ ДЛЯ КУЛЬТИВИРОВАНИЯ БИФИДОБАКТЕРИЙ	4
501	Стаття	Стаття присвячена проблемі розробки технології желе з радіопротекторними властивостями з\nдобавками спіруліни, гарбуза та кефіру. Були розглянуті питання розробки і впровадження у раціон харчування населення України продуктів функціонального призначе	2018-01-27	501	https://doi.org/10.15673/swonaft.v0i48.794	РОЗРОБКА ТЕХНОЛОГІЇ БАГАТОШАРОВОГО ЖЕЛЕ З РАДІОПРОТЕКТОРНИМИ ВЛАСТИВОСТЯМИ	4
502	Стаття	В статті наведено результати дослідження впливу олії амаранту та біополімерних комплексів\nприродного походження на вирощування Lactobacillus plantarum. Показано, що олія амаранту не пригнічує ріст лактобацил, а у присутності пребіотиків, а саме висі	2018-01-27	502	https://doi.org/10.15673/swonaft.v0i48.793	ЗАСТОСУВАННЯ ОЛІЇ АМАРАНТУ ПРИ ВИРОЩУВАННІ LACTOBACILLUS PLANTARUM	4
503	Стаття	Досліджено склад та властивості полісолодових екстрактів як «основи» для безалкогольного напою, підібрано оптимальні співвідношення полісолодового екстракту, водного екстракту малини і необхідної кількості глюкозно-фруктозної патоки для одержання зб	2018-01-27	503	https://doi.org/10.15673/swonaft.v0i48.792	РОЗРОБЛЕННЯ ТЕХНОЛОГІЇ БЕЗАЛКОГОЛЬНИХ НАПОЇВ З ВИКОРИСТАННЯМ ПОЛІСОЛОДОВИХ ЕКСТРАКТІВ	4
570	Стаття	На основании подхода, использующего интеграцию теплового насоса в схему пастеризационноохладительной установки для молока и установок для получения горячей и «ледяной» воды, разработана\nсхема пастеризационно - охладительной установки для молочных про	2017-05-31	570	https://doi.org/10.15673/swonaft.v1i47.421	ТЕПЛОНАСОСНАЯ ПАСТЕРИЗАЦИОННО-ОХЛАДИТЕЛЬНАЯ УСТАНОВКА	4
504	Стаття	Досліджуваному комерційному препарату «Fibregum B» надано органолептичну оцінку та встановлено хімічний склад. В його складі домінує полісахаридна компонента (арабіногалактан) — 65,4 %, яка\nковалентно зв’язана з мінорною складовою — білковими речови	2018-01-27	504	https://doi.org/10.15673/swonaft.v0i48.791	ПРЕПАРАТ ГУМІАРАБІКУ «FIBREGUM B» ЯК ПЕРСПЕКТИВНИЙ ФІЗІОЛОГІЧНО-ФУНКЦІОНАЛЬНИЙ ХАРЧОВИЙ ІНГРЕДІЄНТ	4
505	Стаття	Отримані β-глюкани із рослинної сировини та із клітинних стінок дріжджів S. cerevisae в результаті часткової ферментативної деструкції і визначена їх біологічна активність, зокрема, антиоксидантні та пребіотичні властивості. Запропоновано використов	2018-01-27	505	https://doi.org/10.15673/swonaft.v0i48.790	ВИЗНАЧЕННЯ БІОЛОГІЧНОЇ АКТИВНОСТІ ОЛІГОМЕРІВ ВУГЛЕВОДІВ	4
506	Стаття	В даній статті встановлено залежність гранулометричного складу добавки від ступеню набрякання\nта температури води. Наведено результати досліджень загального хімічного складу добавки, отриманої із вторинних продуктів переробки картоплі. Проведено дос	2018-01-27	506	https://doi.org/10.15673/swonaft.v0i48.789	ДОСЛІДЖЕННЯ ПОКАЗНИКІВ ЯКОСТІ ТА БЕЗПЕКИ СУХОЇ ДОБАВКИ ОТРИМАНОЇ ІЗ ВТОРИННИХ ПРОДУКТІВ ПЕРЕРОБКИ КАРТОПЛІ	4
507	Стаття	Микробиологическая характеристика является одним из основных критериев как качества, так и\nбезопасности продуктов из гидробионтов. В данной работе приведены данные по исследованию влияния\nспособов замораживания, наличия защитных покрытий на трансфор	2018-01-27	507	https://doi.org/10.15673/swonaft.v0i48.788	ВЛИЯНИЕ СПОСОБА ЗАМОРАЖИВАНИЯ НА КАЧЕСТВЕННЫЙ И КОЛИЧЕСТВЕННЫЙ СОСТАВ МИКРООРГАНИЗМОВ МОРОЖЕНОГО ТОЛСТОЛОБИКА	4
508	Стаття	У статті розглянуто вимоги до якості таких заморожених морепродуктів як креветки варено-\nморожені, кальмари заморожені і заморожені крабові палички, які регламентуються національними\nнормативними документами і стандартами Codex Alimentarius; стисло	2018-01-27	508	https://doi.org/10.15673/swonaft.v0i48.787	ПРОБЛЕМИ ЯКОСТІ ЗАМОРОЖЕНИХ МОРЕПРОДУКТІВ, ЩО ПРЕДСТАВЛЕНІ НА СУЧАСНОМУ РИНКУ УКРАЇНИ	4
509	Стаття	За останні роки постійно розширюється асортимент кулінарії, яка виготовляється з морепродуктів та овочевої сировини. Важливість білків тваринного походження та водорозчинних біологічно-\nактивних речовин рослинної сировини обумовлює необхідність теор	2018-01-27	509	https://doi.org/10.15673/swonaft.v0i48.786	ДОСЛІДЖЕННЯ ВПЛИВУ ТЕПЛОВОЇ ОБРОБКИ НА ЯКІСТЬ КОМБІНОВАНИХ КУЛІНАРНИХ ВИРОБІВ ІЗ МОРЕПРОДУКТІВ ТА КАПУСТИ БІЛОГОЛОВОЇ	4
510	Стаття	Основным условием производства имитированных балычных изделий является наличие сырьевых\nисточников, которые отвечают ряду требований, прежде всего размерам мышечного волокна, химического состава и способности к созреванию. В работе исследованы основ	2018-01-27	510	https://doi.org/10.15673/swonaft.v0i48.785	ПЕРСПЕКТИВЫ ПРОИЗВОДСТВА ИМИТИРОВАННЫХ РЫБНЫХ ПРОДУКТОВ ИЗ ГИДРОБИОНТОВ	4
511	Стаття	У роботі досліджена зміна структурно-механічних характеристик модельних розчинів цитрусового\nпектину від властивостей модифікованого пектину. Встановлено, що кількість іона кальцію, який вно-\nситься, значною мірою впливає на ефективну в’язкість моде	2018-01-27	511	https://doi.org/10.15673/swonaft.v0i48.784	ДОСЛІДЖЕННЯ ВПЛИВУ МОДИФІКАЦІЇ ПЕКТИНОВИХ РЕЧОВИН НА РЕОЛОГІЧНІ ВЛАСТИВОСТІ ПСЕВДОПЛАСТИЧНИХ РІДИН	4
512	Стаття	Стаття спрямована на визначення змін в процесі пророщування сочевиці за різних режимів та дослідженню змін в її хімічному складі. В статті наведено аналіз найбільш значущих складових сочевиці, що\nвиявляють негативну дію при її засвоєнні. Проаналізов	2018-01-27	512	https://doi.org/10.15673/swonaft.v0i48.783	ОБҐРУНТУВАННЯ ТЕХНОЛОГІЧНИХ ПАРАМЕТРІВ ПРОРОЩУВАННЯ ЗЕРЕН СОЧЕВИЦІ	4
513	Стаття	В данной работе исследовано влияние различных режимов хранения на изменения биохимических и\nмикробиологических показателей качества семян сои. Подобраны условия, способствующие снижению\nинтенсивности окислительных процессов и замедлению процессов жи	2018-01-27	513	https://doi.org/10.15673/swonaft.v0i48.782	ИЗМЕНЕНИЕ ПОКАЗАТЕЛЕЙ КАЧЕСТВА СЕМЯН СОИ ПРИ РАЗЛИЧНЫХ РЕЖИМАХ ХРАНЕНИЯ	4
514	Стаття	Визначено уточнені дані складу зернового екстракту із тритікале (цитолітичних ферментних препаратів). Досліджено технологічні параметри процесу в області заданих параметрів (дозу цитолітичних ферментних препаратів) на реологічні властивості затору і	2018-01-27	514	https://doi.org/10.15673/swonaft.v0i48.781	ДОСЛІДЖЕННЯ ВПЛИВУ ЦИТОЛІТИЧНИХ ФЕРМЕНТНИХ ПРЕПАРАТІВ НА РЕОЛОГІЧНІ (В’ЯЗКІСТНІ) ВЛАСТИВОСТІ ЗАТОРУ ІЗ ТРИТІКАЛЕ НА ВІСКОЗИМЕТРІ «РЕОТЕСТ-2»	4
515	Стаття	Проведено исследование безопасности образцов муки как компонентов сырья для производства хле-\nбобулочных изделий. Безопасность данного пищевого сырья определялась методами биотестирования\nтест-организмами различных систематических групп. Исследовани	2018-01-27	515	https://doi.org/10.15673/swonaft.v0i48.780	ОЦЕНКА ДЕЙСТВИЯ БИОСЕНСОРОВ ДЛЯ ЭКСПРЕСС- ДИАГНОСТИКИ И МОНИТОРИНГА БЕЗОПАСНОСТИ МУКИ	4
516	Стаття	В статті наведена послідовність технологічних процесів та режими виробництва екструдованої\nкормової добавки з використанням водоростей ламінарії. Визначено хімічний склад екструдованої водо-\nростевої кормової добавки (ВКД). Представлені результати р	2018-01-27	516	https://doi.org/10.15673/swonaft.v0i48.779	БІОЛОГІЧНА ОЦІНКА ЕКСТРУДОВАНОЇ КОРМОВОЇ ДОБАВКИ З ВОДОРОСТЯМИ	4
517	Стаття	В статті висвітлені результати проведених досліджень з використання хеномелесу та продуктів\nйого переробки при виробництві борошняних кондитерських виробів з дріжджового тіста. В якості\nпродуктів переробки хеномелесу використали сік, пюре та порошок	2018-01-27	517	https://doi.org/10.15673/swonaft.v0i48.778	ТЕХНОЛОГІЯ ДРІЖДЖОВИХ БУЛОЧНИХ ВИРОБІВ З ВИКОРИСТАННЯМ ХЕНОМЕЛЕСУ	4
518	Стаття	Робота присвячена теоретичному обґрунтуванню та експериментальному підтвердженню використання нетрадиційної рослинної сировини (подрібненого кореня лопуха) у технологіях хліба. Досліджено\nпоказники якості готових виробів (органолептичні, фізико-хімі	2018-01-27	518	https://doi.org/10.15673/swonaft.v0i48.777	ВИКОРИСТАННЯ НЕТРАДИЦІЙНОЇ РОСЛИННОЇ СИРОВИНИ У ТЕХНОЛОГІЇ ПШЕНИЧНОГО ХЛІБА	4
519	Стаття	Целью работы является разработка технологии замороженных полуфабрикатов булочных изделий,\nнаправленная на улучшение показателей качества готовых изделий, изготовленных по технологии «отложенного выпекания», внедрение безотходной технологии, за счет	2018-01-27	519	https://doi.org/10.15673/swonaft.v0i48.776	РАЗРАБОТКА ТЕХНОЛОГИИ ЗАМОРОЖЕННЫХ ПОЛУФАБРИКАТОВ БУЛОЧНЫХ ИЗДЕЛИЙ ФУНКЦИОНАЛЬНОГО НАЗНАЧЕНИЯ	4
520	Стаття	У статті наведено результати маркетингових досліджень споживчих мотивацій та переваг при виборі зернових пластівців. Проведено товарознавчу оцінку рецептур нових багатокомпонентних сумішей зернових пластівців з включенням збагачувальних добавок на о	2018-01-27	520	https://doi.org/10.15673/swonaft.v0i48.775	РОЗШИРЕННЯ АСОРТИМЕНТУ БАГАТОКОМПОНЕНТНИХ СУМІШЕЙ НА ОСНОВІ ЗЕРНОВИХ ПЛАСТІВЦІВ	4
521	Стаття	У статті наведена актуальність розробки нових продуктів оздоровчого призначення, а саме зернових хлібців, розроблена балова шкала органолептичних показників якості зернових хлібців та приведені результати органолептичної оцінки якості нових продукті	2018-01-27	521	https://doi.org/10.15673/swonaft.v0i48.774	РОЗРОБКА ТА АПРОБАЦІЯ БАЛОВОЇ ШКАЛИ ДЛЯ ОЦІНКИ ЯКОСТІ ЗЕРНОВИХ ХЛІБЦІВ ОЗДОРОВЧОГО ПРИЗНАЧЕННЯ	4
522	Стаття	Проаналізовано проблеми моделювання процесу екстрагування у умовах протитечійного руху екстрагенту і твердої фази в умовах мікрохвильового поля. Обґрунтовано доцільність розрахунку та оптимізації мікрохвильових екстракторів. Визначено основні парамет	2017-12-08	522	https://doi.org/10.15673/swonaft.v81i1.694	МАТЕМАТИЧНЕ МОДЕЛЮВАННЯ ТА ОПТИМІЗАЦІЯ МІКРОХВИЛЬОВОГО ПРОТИТЕЧІЙНОГО ЕКСТРАКТОРА	4
523	Стаття	В статье рассмотрены микроволновые технологии интенсификации процессов концентрирования экстрактов ароматических и биологически-активных веществ. Для интенсификации процесса вакуум-выпарки предлагается обеспечить равномерность подвода энергии и исклю	2017-12-08	523	https://doi.org/10.15673/swonaft.v81i1.693	МОДЕЛИРОВАНИЕ ПРОЦЕССА КОНЦЕНТРИРОВАНИЯ ПИЩЕВЫХ РАСТВОРОВ В МИКРОВОЛНОВОМ ВАУУМ-ВЫПАРНОМ АППАРАТЕ	4
524	Стаття	Стаття присвячена проблемі підвищення теплонадходження геліопанелі, що працює для вироблення теплової енергії. Такі пристрої можуть використовуватися для отримання гарячої води та у системах опалення «тепла підлога». До переваг таких систем треба від	2017-12-08	524	https://doi.org/10.15673/swonaft.v81i1.692	ПІДВИЩЕННЯ ТЕПЛОНАДХОДЖЕННЯ ГЕЛІОПАНЕЛІ ДЛЯ ВИРОБЛЕННЯ ТЕПЛОВОЇ ЕНЕРГІЇ	4
525	Стаття	Дослідження процесів, що протікають в технологічних установках, встановлення закономірностей їх протікання, знаходження залежностей, необхідних для їх аналізу і розрахунку, можна проводити різними методами: теоретичним, експериментальним, подоби. Тео	2017-12-08	525	https://doi.org/10.15673/swonaft.v81i1.691	ЗАСТОСУВАННЯ ТЕОРІЇ ПОДІБНОСТІ В МОДЕЛЮВАННІ ПРОЦЕСУ КОНВЕКТИВНО-ТЕРМОРАДІАЦІЙНОГО СУШІННЯ КУЛЬТИВОВАНИХ ГРИБІВ	4
526	Стаття	Запропоновано методичні основи з оцінювання енергоекономічної ефективності систем енергозабезпечення (СЕ) з когенераційно-теплонасосними установками (КТНУ) різних рівнів потужності та піковими джерелами теплоти (ПДТ), з урахуванням комплексного вплив	2017-12-08	526	https://doi.org/10.15673/swonaft.v81i1.690	МЕТОДИЧНІ ОСНОВИ З ОЦІНЮВАННЯ ЕНЕРГОЕКОНОМІЧНОЇ ЕФЕКТИВНОСТІ СИСТЕМ ЕНЕРГОЗАБЕЗПЕЧЕННЯ З КОГЕНЕРАЦІЙНО - ТЕПЛОНАСОСНИМИ УСТАНОВКАМИ ТА ПІКОВИМИ ДЖЕРЕЛАМИ ТЕПЛОТИ	4
527	Стаття	Ефективна робота віброекстракційної апаратури передбачає оптимізацію співвідношення між мікро-і макромасштабними параметрами дії турбулентних пульсуючих струменів, що можливо здійснити лише при більш глибокому аналізі їх природи на стадії генерування	2017-12-08	527	https://doi.org/10.15673/swonaft.v81i1.689	МОДЕЛЮВАННЯ ГІДРОДИНАМІЧНОЇ СТРУКТУРИ ПОТОКІВ ПРИ БЕЗПЕРЕРВНОМУ ВІБРОЕКСТРАГУВАННІ НА ОСНОВІ КОМІРЧАСТОЇ МОДЕЛІ ІЗ ЗВОРОТНИМИ ПОТОКАМИ	4
528	Стаття	Статья посвящена разработке математической модели процесса высокотемпературной сушки торфа и растительной биомассы в технологиях производства твердых биотоплив. Предложенная математическая модель учитывает наиболее характерные стороны процесса высоко	2017-12-08	528	https://doi.org/10.15673/swonaft.v81i1.688	МОДЕЛИРОВАНИЕ ВЫСОКОТЕМПЕРАТУРНОЙ СУШКИ ТОРФА И БИОМАССЫ В ТЕХНОЛОГИЯХ ПРОИЗВОДСТВА БИОТОПЛИВ	4
529	Стаття	Микроволновый противоточный экстрактор – аппарат в котором организуется режим противоточного движения твердой фазы и экстрагента, что способствует более полному извлечению экстрактивных веществ из сырья в экстракт. Основой для выбора режимных и техно	2017-12-08	529	https://doi.org/10.15673/swonaft.v81i1.687	ИСПЫТАНИЯ МИКРОВОЛНОВОГО ЭКСТРАКТОРА В УСЛОВИЯХ ПРОИЗВОДСТВА	4
530	Стаття	В настоящей работе освещаются различные аспекты гидродинамической кавитации, включая базовый механизм, анализ динамики единичного пузырька и кавитационного кластера с рекомендациями по оптимальным рабочим параметрам. Разрабатываемые в рамках этого на	2017-12-08	530	https://doi.org/10.15673/swonaft.v81i1.686	ЧИСЛЕННОЕ ИССЛЕДОВАНИЕ ПОВЕДЕНИЯ ПУЗЫРЬКОВОГО КЛАСТЕРА В ПРОЦЕССАХ ГИДРОДИНАМИЧЕСКОЙ КАВИТАЦИИ	4
531	Стаття	Соевый белок характеризуется достаточно хорошо сбалансированным аминокислотным составом, который почти соответствует балансу идеального белка. Как важнейший белоксодержащий продукт - соя, потребление которой способствует преодолению белкового голода,	2017-12-08	531	https://doi.org/10.15673/swonaft.v81i1.685	ПОЛУЧЕНИЕ НЕЭНЕРГОЕМКИХ ФИТОЭСТРОГЕННЫХ РАСТИТЕЛЬНЫХ ПОРОШКОВ	4
713	Стаття	We give a sufficient condition on strongly separately continuous\nfunction f to be continuous on space ℓ_p for p ∊ 2 [1;+∞]. We prove the\n\nexistence of an ssc function f : ℓ_∞ → R which is not Baire measurable.\nWe show that any open set in ℓ_p is the	2018-06-10	713	https://doi.org/10.15673/tmgc.v10i3-4.769	Some remarks concerning strongly separately continuous functions on spaces ℓ_p with p ∊ [1;+∞]	6
532	Стаття	В статті розглянуті питання, пов’язані із виникненням і розвитком явища гідродинамічної кавітації при обробленні рідких гетерогенних систем. Показана актуальність і практична значимість використання ефектів, що супроводжують гідродинамічну кавітацію.	2017-12-08	532	https://doi.org/10.15673/swonaft.v81i1.684	ВПЛИВ ЕФЕКТІВ ГІДРОДИНАМІЧНОЇ КАВІТАЦІЇ НА ЕЛЕКТРОХІМІЧНІ ВЛАСТИВОСТІ ВОДИ	4
533	Стаття	Робота присвячена вивченню пристроїв блочного заморожування концентрату гранатового соку. Обговорюється перспектива концентрованих соків, місце гранатового соку на ринку. Проаналізовано традиційні принципи концентрації соків у випарниках. Показані не	2017-12-08	533	https://doi.org/10.15673/swonaft.v81i1.683	БАЛАНСОВІ, ЕНЕРГЕТИЧНІ, КІНЕТИЧНІ ТА ФАЗОВІ МОДЕЛІ ПРОЦЕСІВ КРІОКОНЦЕНТРУВАННЯ ГРАНАТОВОГО СОКУ	4
534	Стаття	Показано, що Україна є лідером серед країн – виробників соняшникової олії і обсяги її переробки динамічно зростають. Поширюється попит і на олію із сої. Ключовим процесом в технологіях олійного виробництва є сушіння сировини. Саме сушіння в значній м	2017-12-08	534	https://doi.org/10.15673/swonaft.v81i1.682	КІНЕТИКА СУШІННЯ ОЛІЙНОЇ СИРОВИНИ В ЕЛЕКТРОМАГНІТНОМУ ПОЛІ	4
535	Стаття	У статті дано визначення фруктово-овочевих чипсів, зазначено основні способи зневоднення, які використовуються в світі для отримання чипсів, наведені недоліки технологій їх виробництва. Представлені вимоги до сировини при виробництві фруктово-овочеви	2017-12-08	535	https://doi.org/10.15673/swonaft.v81i1.681	ІНТЕНСИФІКАЦІЯ ВОЛОГОВИДАЛЕННЯ ПРИ ЗНЕВОДНЕННІ ПЛОДООВОЧЕВОЇ СИРОВИНИ	4
537	Стаття	Исследование процесса теплопередачи в реальных условиях сопряжено с большими трудностями, вследствие сложности и нестационарности процессов, поэтому важность приобретает теоретический анализ и построение моделей. Было проведено численное моделировани	2017-12-08	537	https://doi.org/10.15673/swonaft.v81i1.680	ПОВЫШЕНИЕ ЭНЕРГОЭФФЕКТИВНОСТИ ПРОЦЕССА КРИСТАЛЛИЗАЦИИ ВОДЫ В УЛЬТРАЗВУКОВОМ ПОЛЕ	4
538	Стаття	В даний час для питного водопостачання використовується все більше води з артезіанських свердловин (підземні води). Це пов’язане з погіршенням екологічної обстановки в Україні, яка призвела до зараження поверхневих вод важкими металами, радіоактивним	2017-12-08	538	https://doi.org/10.15673/swonaft.v81i1.679	ДОСЛІДЖЕННЯ ВПЛИВУ КОНСТРУКТИВНИХ ТА ГІДРОДИНАМІЧНИХ ПАРАМЕТРІВ АЕРАЦІЙНО-ОКИСНЮВАЛЬНОЇ УСТАНОВКИ РОТОРНОГО ТИПУ НА ПРОЦЕС ЗНЕЗАЛІЗНЕННЯ ПИТНОЇ ВОДИ	4
539	Стаття	Обговорено перспективи фітопрепаратів, їх концентрати із рослинної сировини. Аналізуються традиційні технології та способи переробки плодів шипшини, пектинових розчинів. Показано, що недоліками відомих технологій є громіздкість обладнання та низька е	2017-12-08	539	https://doi.org/10.15673/swonaft.v81i1.678	ДОСЛІДЖЕННЯ ПРОЦЕСІВ ВИРОБНИЦТВА НЕЕНЕРГОЄМНИХ КОНЦЕНТРОВАНИХ ФІТОПРЕПАРАТІВ	4
540	Стаття	Статтю присвячено застосуванню потужних кавітаційних механізмів, які на сьогодні є одним з найбільш діючих способів досягнення високих енергетичних показників у технологіях обробки рідинних дисперсних середовищ. На базі літературного огляду встановле	2017-12-08	540	https://doi.org/10.15673/swonaft.v81i1.677	ЗАСТОСУВАННЯ ЕНЕРГОЕФЕКТИВНОГО ОБЛАДНАННЯ ДЛЯ ОТРИМАННЯ ЕКСТРАКТУ ЧИСТОТІЛУ	4
541	Стаття	Сучасні технології потребують новітніх процесів утилізації, проте більшість із них також дають відходи, які не завжди легко утилізуються. Натомість усі процеси, що відбуваються у живій природі, є циклічними і добре збалансованими. Перетворення речов	2017-12-08	541	https://doi.org/10.15673/swonaft.v81i1.676	ПОГЛИНАННЯ ВУГЛЕКИСЛОГО ГАЗУ ІЗ СУМІШІ ПОВІТРЯ З ДІОКСИДОМ СІРКИ	4
542	Стаття	Представлено результати експериментальних досліджень динаміки сорбції та іонообмінного поглинання іонів купруму цеолітом у апараті колонного типу. Було проаналізовано існуючий теоретичний апарат для опису процесів адсорбції. Досліджено механізм проце	2017-12-08	542	https://doi.org/10.15673/swonaft.v81i1.675	ДОСЛІДЖЕННЯ АДСОРБЦІЙНО-ДИФУЗІЙНИХ ПРОЦЕСІВ У НЕРУХОМОМУ ШАРІ ДИСПЕРCНОГО МАТЕРІАЛУ В СТАТИЧНИХ ТА ДИНАМІЧНИХ УМОВАХ	4
543	Стаття	Розглядається взаємодія твердого тіла з рідким реагентом, що супроводжується значним тепловим ефектом. Тепло хімічної взаємодії виділяється на поверхні розділу фаз і поширюється теплопровідністю у твердому тілі та конвективним теплообміном у рідині.	2017-12-08	543	https://doi.org/10.15673/swonaft.v81i1.673	ТЕПЛОМАСООБМІН ПІДЧАС ВЗАЄМОДІЇ ТВЕРДОГО ТІЛА З РІДКИМ РЕАГЕНТОМ	4
544	Стаття	Рассмотрены недостатки оборудования для механической и термомеханической обработки пищевых продуктов. Предлагаются пути решения энергетических проблем в технологиях термообработки пищевых жидкостей, сушки дисперсных продуктов, разделения плодов косто	2017-12-08	544	https://doi.org/10.15673/swonaft.v81i1.672	ИННОВАЦИОННОЕ ЭНЕРГОЭФФЕКТИВНОЕ ОБОРУДОВАНИЕ ДЛЯТЕПЛОВОЙ И МЕХАНИЧЕСКОЙ ОБРАБОТКИ ПЛОДОВ	4
545	Стаття	Розглянуто олійне виробництво за ієрархічною технологічною схемою за рівнями: «підприємство – цехи – технологічні лінії – обладнання». Методами енергетичного аудиту визначено щомісячні показники потужності виробництва, витрати теплової та електричної	2017-12-08	545	https://doi.org/10.15673/swonaft.v81i1.671	ЕНЕРГЕТИЧНИЙ МОНІТОРИНГ ОЛІЙНОГО ВИРОБНИЦТВА	4
546	Стаття	В работе приведен широкий анализ опубликованных работ, посвященных методам интеграции процессов и оптимизации теплообменных систем в производствах, использующих химикотехнологические методы переработки и производства веществ. Из множества возможных с	2017-12-08	546	https://doi.org/10.15673/swonaft.v81i1.670	ЭНЕРГОЭФФЕКТИВНАЯ РЕКОНСТРУКЦИЯ ДВУХПОТОКОВЫХ ТЕПЛООБМЕННЫХ СИСТЕМ	4
547	Стаття	У статті аналізується структура виробництва зернових в Україні, виявлено, що при обробці зерна в крупі утворюється значна частина вторинних матеріальних ресурсів (борошна та лушпиння).\nТому важливо використовувати лушпиння зернових як сировину для ви	2017-12-08	547	https://doi.org/10.15673/swonaft.v81i1.669	ОБГРУНТУВАННЯ ДОЦІЛЬНОСТІ ВИКОРИСТАННЯ ВІДХОДІВ КРУПЯНОГО ВИРОБНИЦТВА ЯК СИРОВИНИ ДЛЯ БІОПАЛИВА	4
548	Стаття	Одним з розповсюджених джерел теплової енергії є природна теплота ґрунту. Предметом дослідження статті є технології видобування геотермальної низькопотенційної теплоти приповерхневих шарів Землі. Розглянуто технології видобування теплоти приповерхнев	2017-12-08	548	https://doi.org/10.15673/swonaft.v81i1.668	ВИЛУЧЕННЯ ГЕОТЕРМАЛЬНОЇ ТЕПЛОТИ ЗА ДОПОМОГОЮ ТЕПЛОВИХ ТРУБ	4
549	Стаття	В статье рассматриваются методические приемы синтеза энергоэффективных строительных композиционных материалов на основе методов теории перколяции и структурной оптимизации.\nОсновная проблема, возникающая при проектировании материала, заключается в об	2017-12-08	549	https://doi.org/10.15673/swonaft.v81i1.667	ПРИНЦИПЫ ОПТИМИЗАЦИИ СТРУКТУРЫ ЭНЕРГОЭФФЕКТИВНЫХ МАТЕРИАЛОВ	4
550	Стаття	Предложена теплоэнергетическая система снабжения: электроэнергией, горячей водой и отоплением, в которой совместно с ветроэлектрогенератором, двухконтурной солнечной установкой, используется геотермальный грунтовый тепловой насос «грунт-вода», аккуму	2017-12-08	550	https://doi.org/10.15673/swonaft.v81i1.666	ТЕПЛОЭНЕРГЕТИЧЕСКАЯ УСТАНОВКА НА ВОЗОБНОВЛЯЕМЫХ ИСТОЧНИКАХ ЭНЕРГИИ	4
551	Стаття	В даній роботі запропоновано новий спосіб нейтралізації конденсату продуктів згоряння \nприродного газу без використання хімічних реагентів з метою його повторного використання для промис-\nлових потреб, а також як  води для живлення водогрійних котлів	2017-12-08	551	https://doi.org/10.15673/swonaft.v81i1.663	ЗАСТОСУВАННЯ СПОСОБУ ДИСКРЕТНО-ІМПУЛЬСНОГО ВВЕДЕННЯ  ЕНЕРГІЇ ДЛЯ НЕЙТРАЛІЗАЦІЇ КОНДЕНСАТУ ПРОДУКТІВ ЗГОРЯННЯ   ПРИРОДНОГО ГАЗУ	4
552	Стаття	Operating processes of open-type sorption heat accumulator in heating systems were studied. The al-\ngorithm for calculation of its performance is developed. It includes computation of mass transfer cofficient, sorp-\ntion, useful heat sorption, heat i	2017-12-08	552	https://doi.org/10.15673/swonaft.v81i1.662	OPERATING PROCESSES PARAMETERS OF OPEN-TYPE SORPTIVE HEAT  STORAGE DEVICES IN HEAT SUPPLY SYSTEMS	4
553	Стаття	В статті відображено один з варіантів вирішення технічної проблеми, пов’язаної зі складністю вимірювання температури в об’ємі дослідного зразка, що обробляється в середовищі потужного мікрохвильового електромагнітного поля. Задля розкриття змісту і в	2017-05-31	553	https://doi.org/10.15673/swonaft.v1i47.438	ДЕЯКІ ПРОБЛЕМИ ЕКСПЕРИМЕНТАЛЬНОГО МОДЕЛЮВАННЯ ПРОЦЕСІВ СУШІННЯ РОСЛИННОЇ СИРОВИНИ В МІКРОХВИЛЬОВОМУ ЕЛЕКТРОМАГНІТНОМУ ПОЛІ	4
715	Стаття	One considers the problem connected with the finding of the non-isotropic surface in Minkowsky space with the help of its Grassman image in the global aspect. This problem can be reduced to the proof of the existence of the solution of the partial di	2018-06-10	715	https://doi.org/10.15673/tmgc.v11i1.917	The existence of the surface with edge in Minkowsky space with the given Grassman image	6
554	Стаття	В работе на основе широкого анализа литературы определена специфика энергообеспечения предприятий ресторанного и гостиничного комплекса. Предложены пути повышения эффективности использования энергии при соблюдении необходимых условий комфорта. Рассмо	2017-05-31	554	https://doi.org/10.15673/swonaft.v1i47.437	ЭНЕРГОМОНИТОРИНГ ПРЕДПРИЯТИЙ РЕСТОРАННОГО И ГОСТИНИЧНОГО КОМПЛЕКСА	4
555	Стаття	Розроблено та виготовлено різні типи сонячних теплових повітряних колекторів (СТПК), які працюють виключно від сонячної енергії. Ці пристрої перевершують за своїми характеристиками аналоги,\nякі є на українському ринку в даний час, при цьому їх ціна в	2017-05-31	555	https://doi.org/10.15673/swonaft.v1i47.436	СОНЯЧНІ ПОВІТРЯНІ ТЕПЛОВІ КОЛЕКТОРИ ДЛЯ ЕКОЛОГІЧНО ЧИСТОЇ СУШКИ ПРОДУКТІВ ХАРЧУВАННЯ	4
556	Стаття	Розроблено технологію вітчизняного харчового продукта спеціального дієтичного призначення в сухій формі – продукту, який містить до 80 % гідролізованого білка, що за складом незамінних амінокислот наближений до «ідеального».\nAn article deals with wor	2017-05-31	556	https://doi.org/10.15673/swonaft.v1i47.435	ТЕХНОЛОГІЯ ВІТЧИЗНЯНОГО ПРОДУКТУ СПЕЦІАЛЬНОГО ДІЄТИЧНОГО ПРИЗНАЧЕННЯ «БІЛОК ГІДРОЛІЗОВАНИЙ СУХИЙ»	4
557	Стаття	В статье рассмотрена технология производства пеллет из виноградных выжимок. Представлены\nрезультаты исследований по дроблению и прессованию выжимок. Определены удельные расходы энергии на дробление и прессование пеллет из выжимок.\nIn current paper th	2017-05-31	557	https://doi.org/10.15673/swonaft.v1i47.434	ТЕХНОЛОГИЯ ПРОИЗВОДСТВА ПЕЛЛЕТ ИЗ ВИНОГРАДНЫХ ВЫЖИМОК	4
558	Стаття	Стаття присвячена обґрунтуванню технології комплексної переробки торфу. Представлені результати дослідження енергетичних та структурно механічних властивосте твердого залишку торфу\nпісля екстракції гумінових речовин.\nThe article is devoted to substan	2017-05-31	558	https://doi.org/10.15673/swonaft.v1i47.433	ЗАЛИШОК ПІСЛЯ ЕКСТРАКЦІЇ ГУМІНОВИХ РЕЧОВИН З ТОРФУ ЯК СИРОВИНА ДЛЯ ВИГОТОВЛЕННЯ БІОПАЛИВА	4
559	Стаття	Основні енерговитрати в лінії виробництва твердого біопалива: сушіння 70% та пресування\n17%. Проведення термовологісної обробки біомаси є достатньою для реалізації процесу брикето- та\nгрануло утворення при низьких тисках. Проведені дослідження впливу	2017-05-31	559	https://doi.org/10.15673/swonaft.v1i47.432	АНАЛІЗ ЕНЕРГОВИТРАТ СТАДІЇ ТЕРМОВОЛОГІСНОЇ ОБРОБКИ БІОМАСИ В ТЕХНОЛОГІЯХ ВИРОБНИЦТВА ТВЕРДОГО БІОПАЛИВА	4
560	Стаття	В статті проведені розрахунки корисної різниціміж затраченою енергією на сушіння подрібнених\nстебел соняшника та їх нижчою теплотворною здатністю залежно від вологовмісту, на основі чого\nвизначено оптимальні параметри фільтраційного сушіння такого ви	2017-05-31	560	https://doi.org/10.15673/swonaft.v1i47.431	ВИЗНАЧЕННЯ ОПТИМАЛЬНИХ ПАРАМЕТРІВ СУШІННЯ ПОДРІБНЕНИХ СТЕБЕЛ СОНЯШНИКА ДЛЯ ВИРОБНИЦТВА ПАЛИВНИХ БРИКЕТІВ	4
561	Стаття	Досліджено режими екстрагування гумусових та гумінових речовин торфу за класичною та розробленою технологією з використанням пульсаційних апаратів ДІВЕ. Показано, від яких факторів залежить максимальний вихід гумусових речовин. Дано рекомендації по в	2017-05-31	561	https://doi.org/10.15673/swonaft.v1i47.430	ДОСЛІДЖЕННЯ РЕЖИМІВ ЕКСТРАГУВАННЯ ГУМУСОВИХ ТА ГУМІНОВИХ РЕЧОВИН	4
562	Стаття	Для зброджування сусла в умовах високогустинного пивоваріння здійснено підбір рас пивних дріжджів за осмо-, спирто- та термостійкістю, бродильною активністю, ступенем зброджування та здатністю до редукції дикетонів. Досліджено вплив концентрації сухи	2017-05-31	562	https://doi.org/10.15673/swonaft.v1i47.429	ЗБРОДЖУВАННЯ ВИСОКОКОНЦЕНТРОВАНОГО ПИВНОГО СУСЛА ДРІЖДЖАМИ РІЗНИХ РАС	4
563	Стаття	Рассмотрены аппараты на базе термосифонов для сушки дисперсных пищевых материалов. Приведены результаты экспериментальных исследований.\nDevices on the basis of thermosiphons for drying of disperse food materials are considered. Results of\nexperimenta	2017-05-31	563	https://doi.org/10.15673/swonaft.v1i47.428	ИССЛЕДОВАНИЕ РАБОТЫ РЕКУПЕРАТИВНЫХ СУШИЛОК НА БАЗЕ ТЕРМОСИФОНОВ	4
564	Стаття	В представленій роботі вивчено процес експлуатації сонячного адсорбційного холодильника на основі композитного сорбенту «силікагель/Na2SO4». Наведено та проаналізовано графік зміни температури\nв холодильній камері в зимовий та літній періоди. Виявлен	2017-05-31	564	https://doi.org/10.15673/swonaft.v1i47.427	ОСНОВНІ РОБОЧІ ХАРАКТЕРИСТИКИ СОНЯЧНОГО АДСОРБЦІЙНОГО ХОЛОДИЛЬНИКА НА ОСНОВІ КОМПОЗИТНОГО СОРБЕНТУ «СИЛІКАГЕЛЬ/Nа2SO4»	4
565	Стаття	Получены обобщенные зависимости: удельной плотности теплового потока от температуры теплоносителя в солнечном коллекторе, времени работы установки в течение светового дня и расхода\nтеплоносителя; коэффициента полезного действия от удельной плотности	2017-05-31	565	https://doi.org/10.15673/swonaft.v1i47.426	ОПТИМИЗАЦИЯ РАБОТЫ СИСТЕМ СОЛНЕЧНОГО ГОРЯЧЕГО ВОДОСНАБЖЕНИЯ	4
566	Стаття	Приведено сравнение путей снижения затрат энергии при концентрировании растворов выпариванием. Произведена оценка эффективности применения испарительно-конденсационных систем трансформации энергии в сравнении с традиционными схемами с механической ко	2017-05-31	566	https://doi.org/10.15673/swonaft.v1i47.425	СИСТЕМНЫЙ АНАЛИЗ ЭНЕРГОЭФФЕКТИВНОСТИ ВВУ С ТЕПЛОВЫМ НАСОСОМ	4
567	Стаття	Исследованы различные типы солнечных установок и материалы, применяемые в них. Выбраны: вариант солнечной установки в качестве прототипа для оптимизации, интеграции и автоматизации;\nматериалы, применяемые в новейших разработках солнечных установок и	2017-05-31	567	https://doi.org/10.15673/swonaft.v1i47.424	ЭКСЕРГЕТИЧЕСКИЙ МЕТОД РЕШЕНИЯ ЗАДАЧИ ОПТИМИЗАЦИИ РАБОТЫ СОЛНЕЧНОЙ УСТАНОВКИ	4
568	Стаття	Запропоновано методичні основи комплексного оцінювання енергетичної ефективності парокомпресійних теплонасосних станцій (ТНС) з електричним та когенераційним приводами з урахуванням комплексного впливу змінних режимів роботи ТНС, пікових джерел тепло	2017-05-31	568	https://doi.org/10.15673/swonaft.v1i47.423	МЕТОДИЧНІ ОСНОВИ КОМПЛЕКСНОГО ОЦІНЮВАННЯ ЕНЕРГЕТИЧНОЇ ЕФЕКТИВНОСТІ ПАРОКОМПРЕСІЙНИХ ТЕПЛОНАСОСНИХ СТАНЦІЙ З ЕЛЕКТРИЧНИМ ТА КОГЕНЕРАЦІЙНИМ ПРИВОДОМ	4
569	Стаття	В статті приведені результати теоретичного аналізу стану використання біомаси в Україні. Кількість внесених добрив мінеральних та органічних. Показано, що основними можливими напрямками використання біомаси в Україні є: в якості добрив, палива та кор	2017-05-31	569	https://doi.org/10.15673/swonaft.v1i47.422	НАУКОВІ АСПЕКТИ ПІДВИЩЕННЯ ЕНЕРГОЕФЕКТИВНОСТІ ПРИ ПЕРЕРОБЦІ ВТОРИННИХ РЕСУРСІВ АГРОПРОМУ	4
571	Стаття	Растительное сырье содержит биологически-активные вещества, которые отвечают за различные\nжизненно-необходимые процессы в организме. В связи с постоянным увеличением темпа жизни, нехваткой времени актуальным является разработка продуктов, которые сок	2017-05-31	571	https://doi.org/10.15673/swonaft.v1i47.420	ЭНЕРГОЭФФЕКТИВНЫЕ ТЕХНОЛОГИИ ПЕРЕРАБОТКИ РАСТИТЕЛЬНОГО СЫРЬЯ	4
572	Стаття	Описано принцип роботи кавітаційного реактора пульсаційного типу. Визначено режимні параметри оптимальної дії кавітаційних ефектів для екстрагування з рослинної сировини. Представлено технологічні характеристики розробленого апарата. Експериментально	2017-05-31	572	https://doi.org/10.15673/swonaft.v1i47.419	ЗАСТОСУВАННЯ КАВІТАЦІЙНОГО РЕАКТОРА ПУЛЬСАЦІЙНОГО ТИПУ ДЛЯ ЕКСТРАГУВАННЯ З РОСЛИННОЇ СИРОВИНИ	4
573	Стаття	Описан новый метод фильтрационной сушки в тепло-массообменном модуле под действием повышенного давления. Проведено сравнение удельных энергозатрат конвективной сушки и сушки в тепломассообменном модуле под действием повышенного давления. Показано, чт	2017-05-31	573	https://doi.org/10.15673/swonaft.v1i47.418	ФИЛЬТРАЦИОННАЯ СУШКА ПРИ ПОВЫШЕННОМ ДАВЛЕНИИ	4
574	Стаття	Стаття присвячена дослідженню обґрунтування ІЧ-обробки насіння соняшника перед його обрушуванням з метою зменшення залишкової лушпинності.\nThe article investigates justification IR processing sunflower seeds to bring down his tub to reduce residual\nh	2017-05-31	574	https://doi.org/10.15673/swonaft.v1i47.417	ОБҐРУНТУВАННЯ ІЧ-ОБРОБКИ НАСІННЯ СОНЯШНИКА ПЕРЕД ЙОГО ОБРУШУВАННЯМ	4
575	Стаття	Розглянуто переваги роботи каскаднихсхем екструзії і наведені результати попередніх досліджень\nкаскадного дисково-шестеренного екструдера в складі лінії для виробництва труб.\nThe advantages of extrusion and cascading schemes are the results of previo	2017-05-31	575	https://doi.org/10.15673/swonaft.v1i47.416	РЕСУРСО-ЕНЕРГООЩАДНИЙ ПРОЦЕС ВИРОБНИЦТВА ПОЛІМЕРНИХ ТРУБ	4
716	Стаття	We consider optimal Morse flows on closed surfaces. Up to topological trajectory equivalence such flows are determined by marked chord diagrams. We present list all such diagrams for flows on nonorientable surfaces of genus at most 4 and indicate pa	2018-06-10	716	https://doi.org/10.15673/tmgc.v11i1.916	Trajectory equivalence of optimal Morse flows on closed surfaces	6
576	Стаття	В статті проведений аналіз процесів екструзії та запропонована схема каскадного дисковошестеренного екструдера в лінії для виробництва полімерної плівки.\nThe article analyzed the extrusion process and the proposed scheme cascade of disk-cogwheel extr	2017-05-31	576	https://doi.org/10.15673/swonaft.v1i47.415	РЕСУРСО-ЕНЕРГООЩАДНИЙ ПРОЦЕС ВИРОБНИЦТВА ПОЛІМЕРНОЇ ПЛІВКИ	4
577	Стаття	Утилізація та переробка полімерних відходів у статті представлена як комплексне дослідження та\nаналіз енерго- і ресурсозберігаючих процесів переробки полімерних відходів різного походження. Дослідження спрямовані на вивчення таких питань як: класифік	2017-05-31	577	https://doi.org/10.15673/swonaft.v1i47.414	ОСОБЛИВОСТІ ПРОЦЕСІВ УТИЛІЗАЦІЇ ПЛІВКОВИХ ПОЛІМЕРНИХ ВІДХОДІВ	4
578	Стаття	В работе анализируются традиционные технологии переработки плодов шиповника. Показана необходимость совершенствования этих технологий. Предложена концепция использования принципов\nадресной доставки энергии к элементам растительного сырья в процессах	2017-05-31	578	https://doi.org/10.15673/swonaft.v1i47.413	ПУТИ ПОВЫШЕНИЯ ЭНЕРГЕТИЧЕСКОЙ ЭФФЕКТИВНОСТИ ПРОЦЕССОВ ПЕРЕРАБОТКИ ПЛОДОВ ШИПОВНИКА	4
579	Стаття	Изучены процессы получения ферратов(VI) с помощью гипохлоритного и комбинированного способов в концентрированных растворах гидроксидов щелочных металлов (10 – 16 М OH–). Рассмотрены\nпути улучшения качества синтезированных ферратов. Предложена техноло	2017-05-31	579	https://doi.org/10.15673/swonaft.v1i47.412	ЭНЕРГОЭФФЕКТИВНЫЕ ОБОРУДОВАНИЕ И ТЕХНОЛОГИЯ ДЛЯ ПОЛУЧЕНИЯ ОСОБО ЧИСТЫХ ФЕРРАТОВ (VI)	4
580	Стаття	Розглянуто способи нейтралізації кислого конденсату продуктів згоряння природного газу. Запропоновано новий високоефективний спосіб нейтралізації кислого конденсату без використання хімічних\nреагентів, що дозволить використовувати його як воду для жи	2017-05-31	580	https://doi.org/10.15673/swonaft.v1i47.411	СПОСІБ БЕЗРЕАГЕНТНОЇ НЕЙТРАЛІЗАЦІЇ КИСЛОГО КОНДЕНСАТУ ПРОДУКТІВ ЗГОРЯННЯ ПРИРОДНОГО ГАЗУ	4
581	Стаття	Наведено і проаналізовано результати експериментальних досліджень з впливу технологічних параметрів (швидкості фільтрування V, напруженості магнітного поля H) процесу магнітного очищення\nводних середовищ феримагнітною фільтруючою загрузкою на ефектив	2017-05-31	581	https://doi.org/10.15673/swonaft.v1i47.410	РЕСУРСОЗБЕРІГАЮЧА ТЕХНОЛОГІЯ МАГНІТНОГО ОЧИЩЕННЯ ВОДНИХ СЕРЕДОВИЩ	4
582	Стаття	Показана целесообразность созданиия мало - и среднетоннажных производств микробиологических\nсредств защиты растений (МБСЗР) на основе новейших технологий и разработок оборудования модульного типа, которое может быть использовано для реализации биотех	2017-05-31	582	https://doi.org/10.15673/swonaft.v1i47.409	ЭНЕРГОЭФФЕКТИВНЫЕ ТЕХНОЛОГИИ И ОБОРУДОВАНИЕ ДЛЯ МАЛОТОННАЖНЫХ ПРОИЗВОДСТВ МИКРОБИОЛОГИЧЕСКИХ СРЕДСТВ ЗАЩИТЫ РАСТЕНИЙ (МБСЗР)	4
583	Стаття	В даній статті описана актуальність використання процесу інфрачервоного сушіння термолабільних матеріалів. Завдяки даному методу сушіння збільшується якість продукту, збільшується швидкість\nсушіння та зменшуються енергетичні витрати.\nIn this article	2017-05-31	583	https://doi.org/10.15673/swonaft.v1i47.408	ФІЗИЧНА МОДЕЛЬ ПРОЦЕСУ ІНФРАЧЕРВОНОГО СУШІННЯ ТЕРМОЛАБІЛЬНИХ МАТЕРІАЛІВ	4
584	Стаття	Излагается способ непрерывной сушки термолабильных материалов, который позволяет сократить время сушки, обеспечить энергосбережение при сохранении высокого качества продукции. Приводится схема ленточной сушильной установки для реализации данного спос	2017-05-31	584	https://doi.org/10.15673/swonaft.v1i47.407	СПОСОБ СУШКИ ТЕРМОЛАБИЛЬНЫХ МАТЕРИАЛОВ В ЛЕНТОЧНОЙ СУШИЛЬНОЙ УСТАНОВКЕ С ПРИМЕНЕНИЕМ ТЕПЛОВОГО НАСОСА	4
585	Стаття	Рассматриваются вопросы, связанные с созданием современных безопасных энергоресурсосберегающих технологических процессов химической отделки текстильных материалов. Анализируются пути повышения эффективности тепло-массообменных процессов отделочного п	2017-05-31	585	https://doi.org/10.15673/swonaft.v1i47.406	НЕКОТОРЫЕ АСПЕКТЫ СОЗДАНИЯ ИННОВАЦИОННЫХ БЕЗОПАСНЫХ ЭНЕРГОРЕСУРСОСБЕРЕГАЮЩИХ ПРОМЫШЛЕННЫХ ТЕХНОЛОГИЙ ХИМИЧЕСКОЙ ОТДЕЛКИ ТЕКСТИЛЬНЫХ МАТЕРИАЛОВ	4
586	Стаття	В работе рассмотрены современные технологии экстрагирования с использованием микроволнового\nполя. Показаны результаты применения комбинированных методов, которые позволяют достигнуть\nположительных результатов при экстрагировании компонентов. Приведен	2017-05-31	586	https://doi.org/10.15673/swonaft.v1i47.405	СОВЕРШЕНСТВОВАНИЕ ТЕПЛОТЕХНОЛОГИЙ ПРОИЗВОДСТВА КОФЕ	4
587	Стаття	Представлено результати досліджень зміни температури комірки розчину сахарози при її одночасному нестаціонарному контакті з паровою бульбашкою та кристалом цукру в залежності від сталих\nабо змінних коефіцієнтів теплофізичних характеристик по кожній о	2017-05-31	587	https://doi.org/10.15673/swonaft.v1i47.404	ДОСЛІДЖЕННЯ ЗМІНИ ТЕМПЕРАТУРИ В КОМІРЦІ РОЗЧИНУ САХАРОЗИ ПРИ ЇЇ ОДНОЧАСНОМУ КОНТАКТУ З ПАРОВОЮ БУЛЬБАШКОЮ ТА КРИСТАЛОМ ЦУКРУ В ЗАЛЕЖНОСТІ ВІД СТАЛИХ АБО ЗМІННИХ КОЕФІЦІЄНТІВ ТЕПЛОФІЗИЧНИХ ХАРАКТЕРИСТИК КОМІРОК ПРИ МАСОВІЙ КРИСТАЛІЗАЦІЇ ЦУКРУ	4
588	Стаття	Розглянуто вплив температури та механічного перемішування на швидкість проходження процесу\nекстрагування пряно-ароматичної сировини. Встановлено вплив гідромодуля, виду екстрагенту та сировини на процес вилучення вітаміну С і фенольних речовин з прян	2017-05-31	588	https://doi.org/10.15673/swonaft.v1i47.403	ІНТЕНСИФІКАЦІЯ ПРОЦЕСУ ЕКСТРАГУВАННЯ ПРИ ВИРОБНИЦТВІ ГІРКИХ НАСТОЯНОК	4
589	Стаття	Представлено результати досліджень дисперсного аналізу рослинної сировини зернового походження. На підставі отриманих даних побудовано диференціальні та інтегральні криві дисперсного складу\nсировини зернового походження різного помелу.\nResults of the	2017-05-31	589	https://doi.org/10.15673/swonaft.v1i47.402	АНАЛІЗ ДИСПЕРСНОГО СТАНУ РОСЛИННОЇ СИРОВИНИ ЗЕРНОВОГО ПОХОДЖЕННЯ	4
590	Стаття	В статье рассматриваются недостатки традиционных технологий выпаривания. Предлагается\nобеспечить равномерность подвода энергии за счет использования микроволновых технологий. Описана\nконструкция лабораторного образца вакуум-выпарной установки с микро	2017-05-31	590	https://doi.org/10.15673/swonaft.v1i47.401	КОНЦЕНТРИРОВАНИЕ ЭКСТРАКТОВ СТЕВИИ В МИКРОВОЛНОВОЙ ВАКУУМ-ВЫПАРНОЙ УСТАНОВКЕ	4
591	Стаття	Представлена методика экспериментального исследования коэффициентов теплоотдачи компонентов слоя. Получены обобщенные зависимости по теплоотдаче газового и твердого компонентов при\nналичии в слое источников тепла.\nThis article presents method of expe	2017-05-31	591	https://doi.org/10.15673/swonaft.v1i47.400	ИССЛЕДОВАНИЕ КОЭФФИЦИЕНТОВ ТЕПЛООБМЕНА НЕПОДВИЖНОГО СЛОЯ С ВНУТРЕННИМИ ИСТОЧНИКАМИ ТЕПЛОТЫ	4
702	Стаття	We propose to consider ensembles of cycles (quadrics), which are interconnected through conformal-invariant geometric relations (e.g. ``to be orthogonal'', ``to be tangent'', etc.), as new objects in an extended M\\"obius--Lie geometry. It was recent	2019-01-21	702	https://doi.org/10.15673/tmgc.v11i3.1203	An extension of Mobius--Lie geometry with conformal ensembles of cycles and its implementation in a GiNaC library	6
592	Стаття	Выпечка булочных и кондитерских изделий в печах с конвективным обогревом осуществляется путем интенсивного конвективного теплообмена между изделиями и средой пекарной камеры. Для получения качественных мелкоштучных хлебобулочных изделий при выпечке в	2017-05-31	592	https://doi.org/10.15673/swonaft.v1i47.399	ОПРЕДЕЛЕНИЕ ПАРАМЕТРОВ ТЕПЛОПОГЛОЩЕНИЯВ ХЛЕБОПЕКАРНЫХ ПЕЧАХ С КОНВЕКТИВНЫМ ОБОГРЕВОМ	4
593	Стаття	Стаття присвячена дослідженню інтенсифікування процесу екстрагування олії із насіння промислового призначення сої дією мікрохвильового поля. Досліджено вплив питомого енергоспоживання від\nгідромодуля та питомої потужності.\nThearticleisdevotedtotheint	2017-05-31	593	https://doi.org/10.15673/swonaft.v1i47.398	ЗАЛЕЖНІСТЬ ПИТОМОГО ЕНЕРГОСПОЖИВАННЯ ВІД ГІДРОМОДУЛЯ ТА ПИТОМОЇ ПОТУЖНОСТІ ПРИ ЕКСТРАГУВАННІ НАСІННЯ СОЇ	4
594	Стаття	У статті наведені результати експериментального дослідження впливу технологічних параметрів\nпроцесу конвективно-кондуктивної сушки на теплоту випаровування вологи з паренхімних тканин яблука. Показано, що змінення технологічних параметрів процесу суш	2017-05-31	594	https://doi.org/10.15673/swonaft.v1i47.397	ВПЛИВ ТЕХНОЛОГІЧНИХ ПАРАМЕТРІВ ПРОЦЕСУ СУШКИ НА ТЕПЛОТУ ВИПАРОВУВАННЯ ВОЛОГИ З РОСЛИННИХ ТКАНИН	4
595	Стаття	Стаття присвячена дослідженню зміни температурних режимів процесу сушіння у виробництві\nцукатів з гарбуза. Проведені експериментальні дослідження з теплообміну та кінетики сушіння цукатів\nз гарбуза різної температури. Експериментально підтверджена до	2017-05-31	595	https://doi.org/10.15673/swonaft.v1i47.396	ДОСЛІДЖЕННЯ ЗМІНИ ТЕМПЕРАТУРНИХ РЕЖИМІВ ПРОЦЕСУ СУШІННЯ У ВИРОБНИЦТВІ ЦУКАТІВ З ГАРБУЗА	4
596	Стаття	В статті наведено результати з очищення екстракту з топінамбуру за допомогою вапняного молока, визначено оптимальну кількість цього реагенту та температурний діапазон, при якому найефективніше працювати з метою очищення екстракту від високомолекулярн	2017-05-31	596	https://doi.org/10.15673/swonaft.v1i47.395	ОЧИЩЕННЯ ТОПІНАМБУРОВОГО ЕКСТРАКТУ ВАПНЯНИМ МОЛОКОМ	4
630	Стаття	Розглянуто енергетичний баланс досліджуваної системи, визначені складові енергії на протікання\nкавітаційного процесу обробки технологічного середовища.\nWe considerthe energy balanceof the system, defined theenergy toflowcavitationprocessingtechnology	2017-05-31	630	https://doi.org/10.15673/swonaft.v1i47.359	ЕНЕРГЕТИКА КАВІТАЦІЙНОЇ ОБРОБКИ ТЕХНОЛОГІЧНОГО СЕРЕДОВИЩА	4
597	Стаття	Представлено результати досліджень енерговитрат на процес вилучення цільових компонентів із\nрослинної сировини віброекстрагуванням в апаратах періодичної та безперервної дії. Обґрунтовано\nвплив низькочастотних механічних коливань на витрати енергії т	2017-05-31	597	https://doi.org/10.15673/swonaft.v1i47.393	ВИЗНАЧЕННЯ ВИТРАТ ЕНЕРГІІ ПРИ ВІБРОЕКСТРАГУВАННІ ІЗ РОСЛИННОЇ СИРОВИНИ	4
598	Стаття	У даній статті висвітлюються принципово нові способи збереження бетаніну столового буряку та\nсуттєвого зниження енерговитрат на процес сушіння завдяки розробленій енергоефективній теплотехнології переробки столового буряку із застосуванням методу ств	2017-05-31	598	https://doi.org/10.15673/swonaft.v1i47.392	ДОСЛІДЖЕННЯ ТЕПЛОТИ ВИПАРОВУВАННЯ ВОЛОГИ З БЕТАНІНОВМІСНОЇ РОСЛИННОЇ СИРОВИНИ В ПРОЦЕСІ ЗНЕВОДНЕННЯ МЕТОДОМ СИНХРОННОГО ТЕПЛОВОГО АНАЛІЗУ	4
599	Стаття	В статті наведені дослідження з насіння пшениці з застосування ступінчатих режимів сушіння.\nThe article presents research on drying antioxidant-based raw carrots and vegetable ingredients.	2017-05-31	599	https://doi.org/10.15673/swonaft.v1i47.391	ЗАСТОСУВАННЯ СТУПІНЧАТИХ РЕЖИМІВ ПРИ СУШІННІ НАСІННЯ ПШЕНИЦІ	4
600	Стаття	В статье приведены результаты экспериментального измерения затрат теплоты на испарение в\nпроцессе концентрирования яблочного сока путем конвективно-кондуктивной сушки. Зафиксировано\nпостепенное увеличение затрат теплоты на испарение влаги из яблочног	2017-05-31	600	https://doi.org/10.15673/swonaft.v1i47.390	ИЗМЕРЕНИЕ ЗАТРАТ ТЕПЛОТЫ НА ИСПАРЕНИЕ В ПРОЦЕССЕ КОНЦЕНТРИРОВАНИЯ ЯБЛОЧНОГО СОКА	4
601	Стаття	Метою даної статті є дослідження способу сушіння гідратованих концентрату соєвого білка\n«Pro-Vo КМ» і білка тваринного походження «Белкотон С 95» та їх комбінації, які в подальшому передбачається використовувати для виготовлення м'ясних та м'ясомістк	2017-05-31	601	https://doi.org/10.15673/swonaft.v1i47.389	ДОСЛІДЖЕННЯ ПРОЦЕСУ СУШІННЯ БІЛКІВ СОЄВОГО КОНЦЕНТРАТУ «Pro-Vo КМ», «БЕЛКОТОН С 95» ТА ЇХ КОМБІНАЦІЇ КОНВЕКТИВНО-ТЕРМОРАДІАЦІЙНИМ СПОСОБОМ	4
602	Стаття	Найбільш ефективним методом консервування харчових продуктів на сьогодні є сушіння. В той же\nчас цей метод є і найдорожчим. Тому головним завданням процесу сушіння є добитися найвищої якості\nпри мінімальних витратах електроенергії. Для зневоднення гл	2017-05-31	602	https://doi.org/10.15673/swonaft.v1i47.388	ДОСЛІДЖЕННЯ КІНЕТИКИ КОНВЕКТИВНО - ТЕРМОРАДІАЦІЙНОГО СУШІННЯ ГЛОДУ	4
603	Стаття	В останні роки перспективним напрямом в харчовій промисловості є створення харчових продуктів\nнового покоління. Наразі значна частина сировини, яка використовується для виробництва харчових\nпродуктів, переобтяжена засвоюваними вуглеводами і тому ці п	2017-05-31	603	https://doi.org/10.15673/swonaft.v1i47.387	ДОСЛІДЖЕННЯ СУШІННЯ КУЛЬТИВОВАНИХ ГРИБІВ РІЗНИМИ ІНФРАЧЕРВОНИМИ ВИПРОМІНЮВАЧАМИ	4
604	Стаття	Предложен экстрактор для малотоннажных пищевых производств, в котором интенсификация\nпроцесса экстрагирования осуществляется применением вибрации. Конструкция аппарата позволяет\nиспользовать легколетучие экстрагенты. В статье приведены некоторые пред	2017-05-31	604	https://doi.org/10.15673/swonaft.v1i47.386	ЭКСТРАКТОР ДЛЯ МАЛОТОННАЖНЫХ ПИЩЕВЫХ ПРОИЗВОДСТВ	4
605	Стаття	Представлені результати досліджень впливу гідродинамічної кавітації на структурно-механічні\nвластивості водної дисперсії з фосфоліпідами. Наведені залежності ефективної в'язкості дисперсії від\nпараметрів кавітаційної обробки. Проведено порівняння ене	2017-05-31	605	https://doi.org/10.15673/swonaft.v1i47.385	ДОСЛІДЖЕННЯ ВПЛИВУ КАВІТАЦІЙНОЇ ОБРОБКИ НА СТРУКТУРНО-МЕХАНІЧНІ ВЛАСТИВОСТІ ДИСПЕРСНОЇ СИСТЕМИ З ФОСФОЛІПІДАМИ	4
606	Стаття	У статті наведені результати експериментальних досліджень основних фізичних характеристик\nподрібненої деревини (тирси), а також дослідження кінетики і динаміки та швидкості її фільтраційного сушіння.\nIn the article we see results of experimental stud	2017-05-31	606	https://doi.org/10.15673/swonaft.v1i47.383	КІНЕТИКА ФІЛЬТРАЦІЙНОГО СУШІННЯ ПОДРІБНЕНОЇ ДЕРЕВИНИ	4
607	Стаття	Проведен сравнительный анализ конструкций грануляторов в производстве гранулированных продуктов. Описана краткая характеристика грануляционного оборудования. Рассматривается возможность применения технологии гранулирования в вихревом взвешенном слое	2017-05-31	607	https://doi.org/10.15673/swonaft.v1i47.382	ГРАНУЛИРОВАНИЕ В ВИХРЕВОМ ВЗВЕШЕННОМ СЛОЕ: АНАЛИЗ КОНСТРУКЦИЙ ГРАНУЛЯТОРОВ И ПЕРСПЕКТИВЫ РАЗВИТИЯ ТЕХНОЛОГИИ	4
608	Стаття	В даній статті описана актуальність виробництва органо-мінеральних гумінових добрив та дослідження процесу подрібнення гранул добрив, а саме створення ретурну за допомогою дезінтигратора.\nЗавдяки даному дезінтегратору постає можливість у створенні гр	2017-05-31	608	https://doi.org/10.15673/swonaft.v1i47.381	ДОСЛІДЖЕННЯ ПРОЦЕСУ СТВОРЕННЯ РЕТУРНУ ПРИ ВИРОБНИЦТВІ ОРГАНО-МІНЕРАЛЬНИХ ГУМІНОВИХ ДОБРИВ В ПРИСУТНОСТІ ОРГАНІЧНИХ І МІНЕРАЛЬНИХ ДОМІШОК	4
609	Стаття	Обгунтована актуальність виробництва органо-мінеральних гумінових добрив та застосування\nпроцессу утворення ретуру про їх створені. Досліджено процес подрібнення гранул добрив, а саме створення ретуру, за допомогою дезінтигратора. Завдяки запропонова	2017-05-31	609	https://doi.org/10.15673/swonaft.v1i47.380	ПРОЦЕС СТВОРЕННЯ РЕТУРУ ПРИ ВИРОБНИЦТВІ ОРГАНО-МІНЕРАЛЬНИХ ГУМІНОВИХ ДОБРИВ В ПРИСУТНОСТІ ОРГАНІЧНИХ І МІНЕРАЛЬНИХ ДОМІШОК	4
610	Стаття	Розглянуто принципи та обгрунтувано необхідність створення та застосування комплексного мінерально-органічних добрива. Підібрано компоненти комплексного добрива на базі сульфату амонію,\nгумітів та кісткового борошна.\nThe principles of justification a	2017-05-31	610	https://doi.org/10.15673/swonaft.v1i47.379	ПЕРЕВАГИ ЗАСТОСУВАННЯ ОРГАНО-МІНЕРАЛЬНИХ ГУМІНОВИХ ДОБРИВ В ПРИСУТНОСТІ КІСТКОВОГО БОРОШНА	4
611	Стаття	Отримані водно-етанольні суміші із застосуванням високочастотних гідродинамічних коливань в\nапараті, що реалізує принципи дискретно-імпульсного введення енергії. Розглянуто механізм утворення\nводно-етанольних сумішей. Проведено хроматографічні дослід	2017-05-31	611	https://doi.org/10.15673/swonaft.v1i47.378	ВПЛИВ ВИСОКОЧАСТОТНИХ ГІДРОДИНАМІЧНИХ КОЛИВАНЬ НА ВЛАСТИВОСТІ ВОДНО-ЕТАНОЛЬНИХ СУМІШЕЙ	4
612	Стаття	Разработана энергоэффективная технология получения низкоконцентрированных растворов гипохлорита натрия высокой чистоты. Основным элементом технологии является электрохимический реактор, в котором синтез растворов гипохлорита натрия осуществляется в п	2017-05-31	612	https://doi.org/10.15673/swonaft.v1i47.377	ЭНЕРГОЭФФЕКТИВНАЯ ТЕХНОЛОГИЯ СИНТЕЗА НИЗКОКОНЦЕНТРИРОВАННЫХ РАСТВОРОВ ГИПОХЛОРИТА НАТРИЯ ДЛЯ МЕДИЦИНЫ И ВЕТЕРИНАРИИ	4
613	Стаття	Представлено багатофакторні експериментальні дослідження впливу геометричних параметрів\nкавітаційного сопла Вентурі на інтенсивність кавітації в ньому. Також представлено відповідну експериментальну кавітаційну установку та методику проведення експер	2017-05-31	613	https://doi.org/10.15673/swonaft.v1i47.376	ЕКСПЕРИМЕНТАЛЬНЕ ДОСЛІДЖЕННЯ ІНТЕНСИВНОСТІ КАВІТАЦІЇ В СОПЛІ ВЕНТУРІ	4
614	Стаття	Запропоновано дослідження кінетики процесу гранулоутворення твердих багатошарових органомінерально-гумінових композитів при зневодненні висококонцентрованих рідких гетерогенних систем із\nзагальною концентрацією твердої фази понад 60%.\nПредложено иссл	2017-05-31	614	https://doi.org/10.15673/swonaft.v1i47.375	КІНЕТИКА ПРОЦЕСУ СТВОРЕННЯ ОРГАНО-МІНЕРАЛЬНО-ГУМІНОВИХ ДОБРИВ	4
615	Стаття	В статті представлені теоретичні та експериментальні дослідження щодо визначення ефективного коефіцієнта внутрішньої дифузії вологи із шару шлаку теплових електростанцій (ТЕС) під час фільтраційного сушіння. Визначено ефективний коефіцієнт внутрішньо	2017-05-31	615	https://doi.org/10.15673/swonaft.v1i47.374	ВНУТРІШНЬОДИФУЗІЙНЕ МАСОПЕРЕНЕСЕННЯ ПІД ЧАС ФІЛЬТРАЦІЙНОГО СУШІННЯ ШЛАКУ ТЕПЛОВИХ ЕЛЕКТРОСТАНЦІЙ	4
616	Стаття	У статті представлено критеріальні залежності, отримані на основі результатів експериментальних і теоретичних досліджень гідродинаміки руху теплового агента крізь шар кристалів залізного\nкупоросу\nThe article presents the dimensionless dependences obt	2017-05-31	616	https://doi.org/10.15673/swonaft.v1i47.373	ГІДРОДИНАМІКА СТАЦІОНАРНОГО ШАРУ ЗАЛІЗНОГО КУПОРОСУ	4
617	Стаття	Мета даного проекту полягає в дослідженні процесу виробництва карбаміду до грануляції. Результати вивчення технологічної схеми та регламенту дозволяють визначити технологічні потоки, котрі\nнеобхідні для початку проектування теплової інтеграції процес	2017-05-31	617	https://doi.org/10.15673/swonaft.v1i47.372	ЕКСТРАКЦІЯ ДАНИХ ПРОЦЕСУ ВИРОБНИЦТВА КАРБАМІДУ	4
618	Стаття	Запропоновано метод формування вхідної інформації для раціоналізації використання вторинної\nтеплової енергії в системі з парком резервуарів за умов різного рівня невизначеностей. Виконана апробація запропонованого методу на прикладі технологічної сис	2017-05-31	618	https://doi.org/10.15673/swonaft.v1i47.371	МЕТОД РАЦІОНАЛАЗАЦІЇ ВИКОРИСТАННЯ ВТОРИННОЇ ТЕПЛОВОЇ ЕНЕРГІЇ В СИСТЕМІ З ПАРКОМ РЕЗЕРВУАРІВ	4
619	Стаття	Запропоновано математичну модель безперервного процесу утворення багатошарових гуміновомінеральних композитів з рідких систем, яка дозволяє визначити потужність узагальненого джерела\nдля стабілізації дисперсного складу гранульованого продукту.\nThe ma	2017-05-31	619	https://doi.org/10.15673/swonaft.v1i47.370	ОСОБЛИВОСТІ МОДЕЛЮВАННЯ БЕЗПЕРЕРВНОГО ПРОЦЕСУ УТВОРЕННЯ АЗОТНО-КАЛЬЦІЄВО-ГУМІНОВИХ ДОБРИВ	4
620	Стаття	Досліджено кінетику адсорбції альбуміну природним цеолітом з метою очищення стічних вод молокопереробних підприємств. Представлено ізотерму адсорбції та визначено кінетичні параметри в умовах механічного перемішування.\nThe kinetics of adsorption of a	2017-05-31	620	https://doi.org/10.15673/swonaft.v1i47.369	КІНЕТИКА АДСОРБЦІЇ АЛЬБУМІНУ ПРИРОДНИМ ЦЕОЛІТОМ	4
621	Стаття	Розглянуто розчинення твердих частинок кулястої форми в умовах вакуумування системи, що\nстворює умови кипіння рідини. Визначено коефіцієнти масовіддачі. Результати досліджень узагальнено\nкритеріальною залежністю, яка описує процеси хімічної взаємодії	2017-05-31	621	https://doi.org/10.15673/swonaft.v1i47.368	РОЗЧИНЕННЯ ТВЕРДИХ ТІЛ У ТРИФАЗНІЙ СИСТЕМІ, УТВОРЕНІЙ ВАКУУМУВАННЯМ	4
622	Стаття	Целью статьи является описание процесса создания сети теплообменных аппаратов с максимальной рекуперацией тепла, руководствуясь заранее заданным значением минимальной разности температур и с применением пинч-технологий. В работе выполнена пинч-интегр	2017-05-31	622	https://doi.org/10.15673/swonaft.v1i47.367	ПИНЧ-ИНТЕГРАЦИЯ ПРОЦЕССОВ ВЫДЕЛЕНИЯ БЕНЗОЛ-ТОЛУОЛ-КСИЛОЛЬНОЙ ФРАКЦИИ И ГИДРОДЕАЛКИЛАТА В ПРОИЗВОДСТВЕ БЕНЗОЛА	4
623	Стаття	хлаждающие радиаторы на основе микроструктурных элементов реализуют инновационную технологию эффективного теплоотвода для миниатюрных объектов, характеризующихся высокой плотностью тепловыделения (например, микроэлектронные чипы, микросхемы, биологич	2017-05-31	623	https://doi.org/10.15673/swonaft.v1i47.366	ПРОБЛЕМЫ МОДЕЛИРОВАНИЯ ПРОЦЕССОВ ТЕПЛООБМЕНА В МИКРОСТРУКТУРАХ	4
759	Стаття	Daily food consumption norms of an average woman and a pregnant woman have been analysed. It has been established that in a pregnant woman’s diet, it is necessary to increase the content of proteins, fibre, vitamins C, E, D, PP, and B, and reduce fa	2019-04-11	759	https://doi.org/10.15673/fst.v13i1.1309	THE SWEET ICES FOR PREGNANT WOMEN	5
624	Стаття	Рассмотрены аппараты на базе термосифонов для термообработки неньютоновских пищевых жидкостей. Приведены результаты экспериментальных исследований.\ndevices on the basis of thermosiphons for heat treatment of non-Newtonian food liquid are considered.	2017-05-31	624	https://doi.org/10.15673/swonaft.v1i47.365	ОПТИМИЗАЦИЯ РАБОТЫ ВЫПАРНОГО АППАРАТА НА БАЗЕ ВРАЩАЮЩЕГОСЯ ТЕРМОСИФОНА	4
625	Стаття	У статті представлено результати експериментальних досліджень впливу безреагентних методів\nобробки рідин, що ґрунтуються на механізмах дискретно-імпульсного введення енергії, а саме адіабатичне закипання для обробки води і молока та високочастотні гі	2017-05-31	625	https://doi.org/10.15673/swonaft.v1i47.364	ДОСЛІДЖЕННЯ ВПЛИВУ МЕХАНІЗМІВ ДІВЕ НА ЗМІНУ ФІЗИКО-ХІМІЧНИХ ВЛАСТИВОСТЕЙ ВОДИ, МОЛОКА ТА ПРИ ВІДНОВЛЕННІ СУХИХ МОЛОЧНИХ ПРОДУКТІВ	4
626	Стаття	Рассматриваются вопросы относительно математического моделирования процесса мембранного\nконцентрирования белково-углеводного молочного сырья. Приведены результаты исследований влияния\nосновных параметров процесса мембранной обработки белково-углеводн	2017-05-31	626	https://doi.org/10.15673/swonaft.v1i47.363	МОДЕЛИРОВАНИЕ МЕМБРАННЫХ ТЕХНОЛОГИЙ В ПРОЦЕССЕ КОНЦЕНТРИРОВАНИЯ БЕЛКОВО-УГЛЕВОДНОГО МОЛОЧНОГО СЫРЬЯ	4
627	Стаття	Дан комплексный анализ конструктивного совершенствования тестомесильных машин. Проведены исследования факторов влияющих на реализацию процессов, реализуемых при замесе хлебопекарного,\nкондитерского и макаронного теста. Рассмотрена взаимосвязь критери	2017-05-31	627	https://doi.org/10.15673/swonaft.v1i47.362	ОПРЕДЕЛЕНИЕ ВЕЛИЧИН ПРОЦЕССА ПЕРЕМЕШИВАНИЯ ХЛЕБОПЕКАРНОГО, КОНДИТЕРСКОГО И МАКАРОННОГО ТЕСТА	4
628	Стаття	У статті були використані основні положення теорії подібності для тепломасообмінних процесів,\nдинаміки руху віброзрідженого шару сипкої продукції, методи теплофізичного експерименту. Складене\nкритеріальне рівняння в узагальнених змінних процесу сушін	2017-05-31	628	https://doi.org/10.15673/swonaft.v1i47.361	МОДЕЛЮВАННЯ ПРОЦЕСУ ВІБРАЦІЙНОГО СУШІННЯ СОНЯШНИКУ ПРИ ВИКОРИСТАННІ ТЕОРІЇ ПОДІБНОСТІ	4
629	Стаття	Представлена методика расчета допустимого времени микроволновой обработки семян с целью их\nбиостимуляции. На примере семян пшеницы твердой получено, что допустимая длительность обработки уменьшается с ростом влагосодержания и с увеличением начальной	2017-05-31	629	https://doi.org/10.15673/swonaft.v1i47.360	ОЦЕНКА ДЛИТЕЛЬНОСТИ ПРЕДПОСЕВНОЙ ОБРАБОТКИ СЕМЯН В МИКРОВОЛНОВОМ ПОЛЕ	4
632	Стаття	Наведено результати експериментального дослідження кінетики приросту біомаси мікроводоростей при поглинанні вуглекислого газу за участі мікроводоростей типу хлорели. Мікроводорості мають\nвисокі темпи приросту, що сприяє швидкому перетворенню вуглекис	2017-05-31	632	https://doi.org/10.15673/swonaft.v1i47.357	МАСООБМІН ПРИ КУЛЬТИВУВАННІ МІКРОВОДОРОСТЕЙ	4
633	Стаття	В статье рассматривается моделирование процессов сушки на основе совместного решения уравнений масоотдачи, фильтрации и диффузии влаги в пористом слое с учетом влияния механизма капиллярного торможения. В работе приведены результаты теоретических исс	2017-05-31	633	https://doi.org/10.15673/swonaft.v1i47.356	МОДЕЛИРОВАНИЕ ПРОЦЕССОВ СУШКИ НА ОСНОВЕ МЕХАНИЗМА КАПИЛЛЯРНОГО ТОРМОЖЕНИЯ	4
634	Стаття	У статті на основі теоретичних досліджень процесу струминної гомогенізації молока з роздільною\nподачею вершків визначені шляхи підвищення ефективності пристрою. Наведені та проаналізовані математичні залежності процесу струминної гомогенізації молока	2017-05-31	634	https://doi.org/10.15673/swonaft.v1i47.355	ПІДВИЩЕННЯ ЕФЕКТИВНОСТІ СТРУМИННОГО ГОМОГЕНІЗАТОРУ МОЛОКА З РОЗДІЛЬНОЮ ПОДАЧЕЮ ВЕРШКІВ	4
635	Стаття	Проаналізовано існуючі конструкції сепараційних пристроїв та запропоновано їх заміну на більш\nенергоефективні. Досліджено вплив конструктивних і технологічних параметрів сепараційних пристроїв на гідродинаміку потоків. Розроблено методику інженерного	2017-05-31	635	https://doi.org/10.15673/swonaft.v1i47.354	МОДЕЛЮВАННЯ ПРОЦЕСІВ СЕПАРАЦІЇ ТА РОЗРОБКА МЕТОДИКИ РОЗРАХУНКУ ТРИФАЗНОГО СЕПАРАТОРА	4
636	Стаття	Исследовательский интерес статьи посвящен моделированию процесса сушки пшеницы в сушилке на\nоснове вращающегося термосифона. Актуальность вопроса продиктована необходимостью снижения\nэнергозатрат на процесс сушки пшеницы в аграрных масштабах. В связи	2017-05-31	636	https://doi.org/10.15673/swonaft.v1i47.353	МОДЕЛИРОВАНИЕ ПРОЦЕССА СУШКИ ПШЕНИЦЫ В СУШИЛКЕ НА БАЗЕ ВРАЩАЮЩЕГОСЯ ТЕРМОСИФОНА	4
637	Стаття	В статье представлены результаты литературного обзора новейших разработок в области очистки промышленных сточных вод, а также осветлена последняя разработка в этой области Института технической теплофизики НАНУ – это технология и оборудование для без	2017-05-31	637	https://doi.org/10.15673/swonaft.v1i47.352	НОВЫЕ ПОДХОДЫ В ОБЛАСТИ ОЧИСТКИ ПРОМЫШЛЕННЫХ СТОЧНЫХ ВОД	4
638	Стаття	Розроблена математична модель масообмінного процесу адсорбції на прикладі синтетичних\nбарвників природними дисперсними сорбентами з використанням теорії локальної ізотропічної\nтурбулентності та гелевої моделі. Отримані емпіричні рівняння розрахунку к	2017-05-31	638	https://doi.org/10.15673/swonaft.v1i47.351	МЕТОДИ ПРОГНОЗУВАННЯ СОРБЦІЙНИХ ПРОЦЕСІВ З ВИКОРИСТАННЯМ ПРИРОДНИХ СОРБЕНТІВ	4
639	Стаття	На основе анализа экспериментальных данных показано, что поверхность блока льда имеет фрактальные\nсвойства. Предложена теплофизическая модель массопереноса с учетом фрактальных особенностей поверхности\nблока. Анализируется специфичный двухфазный подс	2017-05-31	639	https://doi.org/10.15673/swonaft.v1i47.350	МОДЕЛИРОВАНИЕ ПРОЦЕССА КРИСТАЛЛИЗАЦИИ С УЧЕТОМ СТРУКТУРЫ ПОВЕРХНОСТИ БЛОКА ЛЬДА	4
640	Стаття	В обзоре описаны некоторые универсальные и специальные размерности, вошедшие в математический аппарат теоретической физики в двадцатом столетии.\nIn the review describes some of the universal and special dimensions included in the mathematical formali	2017-05-31	640	https://doi.org/10.15673/swonaft.v1i47.349	РАЗМЕРНОСТИ: ГЕНЕЗИС ПРЕДСТАВЛЕНИЙ И ФИЗИЧЕСКИЕ ПРИЛОЖЕНИЯ	4
641	Стаття	У даній роботі розглядається технологічний процес стабілізації нафти на одноколонной установці.\nАктуальність теми обумовлена тим, що зростання цін на енергію спонукає економніше використовувати енергоресурси з тим, щоб зменшити загальні витрати. За д	2017-05-31	641	https://doi.org/10.15673/swonaft.v1i47.347	ЕНЕРГЕТИЧНЕ ОБСТЕЖЕННЯ СИСТЕМ РЕКУПЕРАТИВНОГО ТЕПЛООБМІНУ УСТАНОВКИ СТАБІЛІЗАЦІЇ НАФТИ З ВИКОРИСТАННЯМ МЕТОДУ ПІНЧ-АНАЛІЗУ	4
642	Стаття	Приведены результаты энергетического и экологического мониторинга в пищеконцентратном производстве. Формулируются научные гипотезы путей решения задач. Предложены инновационные проекты совершенствования теплотехнологий пищевых концентратов. Анализиру	2017-05-31	642	https://doi.org/10.15673/swonaft.v1i47.348	ИННОВАЦИОННЫЕ ТЕПЛОТЕХНОЛОГИИ ПРОИЗВОДСТВА КОФЕПРОДУКТОВ	4
643	Стаття	Запропоновано та обґрунтовано математичну модель процесу створення ретуру при виробництві\nоргано-мінеральних композитів. Отримано залежність витраченої на подрібнення енергії в залежності\nвід розмірів.\nProposed and reasonably mathematical model of c	2017-05-31	643	https://doi.org/10.15673/swonaft.v1i47.345	МАТЕМАТИЧНЕ МОДЕЛЮВАННЯ ПРОЦЕСУ СТВОРЕННЯ РЕТУРУ ПРИ ВИРОБНИЦТВІ ОРГАНО-МІНЕРАЛЬНИХ КОМПОЗИТІВ	4
644	Стаття	В роботе выполнена пинч-интеграция процессов стабилизации ППФ, разделение ППФ и разделение\nШФЛУ. На основании анализа технологической схемы и поточных данных, с помощью метода пинч-\nанализа спроектирована сеточная диаграмма теплообменной системы, по	2017-05-31	644	https://doi.org/10.15673/swonaft.v1i47.344	ПИНЧ-ИНТЕГРАЦИЯ ПРОЦЕССОВ РАЗДЕЛЕНИЯ ШИРОКОЙ ФРАКЦИИ ЛЕГКИХ УГЛЕВОДОРОДОВ И ПРОПАН-ПРОПИЛЕНОВОЙ ФРАКЦИИ НА УСТАНОВКАХ ГАЗОФРАКЦИОНИРОВАНИЯ И КОМПРИМИРОВАНИЯ	4
645	Стаття	В работе дано определение и классификация технологий направленного энергетического действия\n(НЭД). Сформулированы гипотезы перевода сушильных процессов на НЭД технологии. Обсуждаются\nрежимы ламинарной и турбулентной диффузии. Анализируется механизм	2017-05-31	645	https://doi.org/10.15673/swonaft.v1i47.316	ТЕХНОЛОГИИ НАПРАВЛЕННОГО ЭНЕРГЕТИЧЕСКОГО ДЕЙСТВИЯ В АПК	4
646	Стаття	Исследуется эффективность работы теплоутилизатора с гранулированной насадкой. Обоснован выбор для исследования частиц гравия и керамзита в качестве материала насадки. Представлены результаты экспериментального изучения межкомпонентного теплообмена в	2017-05-04	646	https://doi.org/10.15673/swonaft.v80i2.343	ИЗУЧЕНИЕ ПРОЦЕССОВ ТЕПЛОПЕРЕНОСА В ТЕПЛООБМЕННИКЕ С ГРАНУЛИРОВАННОЙ НАСАДКОЙ	4
647	Стаття	Проведено аналитическое исследование процессов теплопроводности при высокоинтенсивном нагреве плотных тел, подобных глинистым и пластическим материалам. Рассмотрены условия применимости гиперболического и параболического уравнения теплопроводности дл	2017-05-04	647	https://doi.org/10.15673/swonaft.v80i2.342	АНАЛИТИЧЕСКОЕ ИССЛЕДОВАНИЕ ПРОЦЕССА ТЕПЛОПРОВОДНОСТИ ПРИ ИНТЕНСИВНОМ НАГРЕВЕ ПЛОТНЫХ ТЕЛ	4
648	Стаття	Важным фактором повышения коэффициента полезного действия газотурбины является процесс охлаждения лопаток турбины. Проектирование эффективной системы охлаждения является очень сложным процессом. Однако это необходимо для проектирования турбин с наиб	2017-05-04	648	https://doi.org/10.15673/swonaft.v80i2.341	НОВЫЙ МЕТОД ОХЛАЖДЕНИЯ ЛОПАТОК ГАЗОТУРБИН	4
649	Стаття	Саді Карно увійшов в історію і науковий світ як філософ природознавства і видатний вчений, незважаючи на те, що його життя було присвячене не теоретичним узагальненням і висновкам, а практичному використанню енергії водяної пари і пропаганді теплови	2017-05-04	649	https://doi.org/10.15673/swonaft.v80i2.340	ІСТОРИЧНА МІСІЯ САДІ КАРНО	4
650	Стаття	В статье проводится анализ энергетической эффективности работы конденсационного газового водогрейного котла в течение отопительного сезона. Выделены характерные возмущающие воздействия, определены диапазоны их изменения. Также оценено их влияние на э	2017-05-04	650	https://doi.org/10.15673/swonaft.v80i2.339	ОЦЕНКА ЭНЕРГЕТИЧЕСКОЙ ЭФФЕКТИВНОСТИ ГАЗОВОГО КОНДЕНСАЦИОННОГО ВОДОГРЕЙНОГО КОТЛА КАК ОБЪЕКТА УПРАВЛЕНИЯ	4
651	Стаття	У роботі наведено доцільність використання м’яса індика у виробництві напівфабрикатів з метою удосконалення структури харчування людей різних вікових груп. Проведені дослідження сенсорних характеристик модельних фаршів дозволили встановити доцільніс	2017-05-04	651	https://doi.org/10.15673/swonaft.v80i2.338	ПІДВИЩЕННЯ СПОЖИВНИХ ВЛАСТИВОСТЕЙ РУБАНИХ НАПІВФАБРИКАТІВ ІЗ М'ЯСА ІНДИКА	4
652	Стаття	У роботі наведено вимоги сучасної нутриціології щодо співвідношення основних харчових нутрієнтів у харчуванні дорослої здорової людини; показано відсутність на ринку України кисломолочних продуктів з пробіотичними властивостями зі збалансованим спів	2017-05-04	652	https://doi.org/10.15673/swonaft.v80i2.337	ОБГРУНТУВАННЯ ПАРАМЕТРІВ ФЕРМЕНТАЦІЇ МОЛОЧНО—РИСОВИХ СУМІШЕЙ ЙОГУРТОВИМИ ЗАКВАСКАМИ	4
653	Стаття	У часи економічних криз в Україні, обсяг молочної сировини значно скорочується. На жаль, якісні характеристики молока також не завжди відповідають вимогам заводів з переробки молока. Таким чином, методи зниження собівартості при виробництві морозива	2017-05-04	653	https://doi.org/10.15673/swonaft.v80i2.336	ПІДБІР ЖИРОВИХ КОМПОНЕНТІВ ДЛЯ СУМІШЕЙ МОРОЗИВА З КОМБІНОВАНИМ СКЛАДОМ СИРОВИНИ	4
654	Стаття	Розроблена інноваційна технологія білкового кисломолочного продукту для харчування дітей від восьми місяців, частково адаптованого до молока жіночого, з підвищеними пробіотичними, в т. ч. антагоністичними, властивостями та зниженим алергізуючим потен	2017-05-04	654	https://doi.org/10.15673/swonaft.v80i2.335	ІННОВАЦІЙНА ТЕХНОЛОГІЯ ВИРОБНИЦТВА БІЛКОВОГО КИСЛОМОЛОЧНОГО ПРОДУКТУ ДИТЯЧОГО ХАРЧУВАННЯ	4
655	Стаття	В статті виконано аналіз послідовності проходження процесу бродіння виноградного сусла в процесі його надходження на завод. Цей аналіз надає розгорнуту картину процесу бродіння в масштабі підприємства і створює передумови для оцінки виходу СО2 за сез	2017-05-04	655	https://doi.org/10.15673/swonaft.v80i2.334	АНАЛІЗ ВИХОДУ СО2 ПРИ БРОДІННІ ВИНОГРАДНОГО СУСЛА ПЕРІОДИЧНИМ СПОСОБОМ	4
656	Стаття	Ефективність виробництва пива визначається тривалістю основних процесів технологічного циклу. Головною та найбільш тривалою стадією є зброджування пивного сусла та дозрівання молодого пива. Одним з направлень підвищення ефективності бродіння є викор	2017-05-04	656	https://doi.org/10.15673/swonaft.v80i2.333	ІНТЕНСИФІКАЦІЯ ПРОЦЕСУ ЗБРОДЖУВАННЯ ПИВНОГО СУСЛА В УМОВАХ ВИРОБНИЦТВА ТОВ «ПИВОВАРНЯ «ОПІЛЛЯ»	4
657	Стаття	Стаття присвячена вивченню здатності природного полімеру хітозану сорбувати іони заліза із білих столових вин і розробці раціональної технології їх деметалізації. Автором проаналізовано шляхи потрапляння заліза у вино на різних етапах технологічного	2017-05-04	657	https://doi.org/10.15673/swonaft.v80i2.332	РОЗРОБКА РАЦІОНАЛЬНОЇ ТЕХНОЛОГІЇ ЗАСТОСУВАННЯ ХІТОЗАНУ У ВИНОРОБСТВІ	4
658	Стаття	Встановлено, що використання комбікорму з різною нормою концентрації хлориду натрію, кальцію і фосфору за аналогічного вмісту інших нормованих компонентів живлення, згідно з ДСТУ 4124—2002 на комбікорми повнораціонні для свиней, при організації годі	2017-05-04	658	https://doi.org/10.15673/swonaft.v80i2.331	ПРОДУКТИВНІ ЯКОСТІ ПОРОСЯТ У ВІЦІ ВІД 41 ДО 60 ДІБ ЗА ВИКОРИСТАННЯ КОМБІКОРМУ З РІЗНОЮ НОРМОЮ КОНЦЕНТРАЦІЇ ХЛОРИДУ НАТРІЮ, КАЛЬЦІЮ І ФОСФОРУ	4
659	Стаття	Актуальным остается поиск источников функциональных ингредиентов для получения продуктов профилактического и оздоровительного направления. Особенный интерес вызывает получение функциональных ингредиентов из вторичного пищевого сырья, поскольку это по	2017-05-04	659	https://doi.org/10.15673/swonaft.v80i2.330	ФУНКЦИОНАЛЬНЫЕ ИНГРЕДИЕНТЫ НА ОСНОВЕ КОФЕЙНОГО ШЛАМА	4
660	Стаття	В статті наведено результати проведеної товарознавчої оцінки п’яти зразків пресервів «Оселедець філе—шматочки в олії». Представлено результати дослідження маркування зразків пресервів на відповідність національним нормативним документам. За результат	2017-05-04	660	https://doi.org/10.15673/swonaft.v80i2.329	ТОВАРОЗНАВЧА ОЦІНКА ТА РОЗРОБКА ПРОПОЗИЦІЙ ЩОДО ЯКОСТІ РИБНИХ ПРЕСЕРВІВ	4
661	Стаття	Можливим шляхом вирішення проблем як збільшення виробництва і споживання рибних продуктів. так і впровадження основних напрямків політики України в галузі здорового харчування є розробка та виробництво фаршів та фаршевих виробів регульованого складу	2017-05-04	661	https://doi.org/10.15673/swonaft.v80i2.328	ВИВЧЕННЯ ФУНКЦІОНАЛЬНИХ ОСОБЛИВОСТЕЙ ФАРШЕВИХ ВИРОБІВ З ПРІСНОВОДНИХ РИБ	4
662	Стаття	Автор в роботі аналізує важливість розробки харчових продуктів з підвищеною біологічною цінністю для харчування населення. Перспективними є розробки з використання сировини місцевого походження з високим вмістом біологічно—активних компонентів. Топі	2017-05-04	662	https://doi.org/10.15673/swonaft.v80i2.327	РОЗРОБКА ТЕХНОЛОГІЇ СОЛОДКИХ СОУСІВ  З ВИКОРИСТАННЯМ ТОПІНАМБУРУ ТА ХЕНОМЕЛЕСУ	4
663	Стаття	Створення харчових продуктів збагачених біологічно активними речовинами є важливим завданням на сучасному етапі розвитку України. Продукти з дріжджового тіста досить популярні, що робить їх перспективним об'єктом для збагачення мікроелементами. Встан	2017-05-04	663	https://doi.org/10.15673/swonaft.v80i2.326	ВИКОРИСТАННЯ ЕКСТРАКТІВ З ВИЧАВОК ХЕНОМЕЛЕСУ  В ТЕХНОЛОГІЇ ВИРОБІВ З ДРІЖДЖОВОГО ТІСТА	4
664	Стаття	Для підприємств ресторанного господарства України суттєвою проблемою є висока енергоємність технологічних процесів та неефективне використання ресурсів. Метою роботи є проведення аналізу енергозберігаючих технологій в ресторанному господарстві на пр	2017-05-04	664	https://doi.org/10.15673/swonaft.v80i2.324	АНАЛІЗ ЕНЕРГОЗБЕРІГАЮЧИХ ТЕХНОЛОГІЙ В РЕСТОРАННОМУ ГОСПОДАРСТВІ	4
665	Стаття	Розроблено спосіб виробництва желейних продуктів з використанням кверцетину рослинної сировини адсорбованого на поверхні високометоксильованних і низькометоксильованих пектинових речовин і ферменту пероксидази кореня хрону і редьки чорної. Встановле	2017-05-04	665	https://doi.org/10.15673/swonaft.v80i2.323	РОЗРОБКА СПОСОБУ ОДЕРЖАННЯ ПРОДУКТІВ ІЗ БІОХІМІЧНО МОДИФІКОВАНИХ ПЕКТИНОВИХ РЕЧОВИН ПОЛІФЕНОЛАМИ РОСЛИННОЇ СИРОВИНИ	4
666	Стаття	На ринку України не представлена десертна продукція, виготовлена на основі коріння селери. У статті викладені основні перспективи використання нетрадиційної сировини — соку коренеплоду селери для приготування желе, обґрунтовано вибір інших складових	2017-05-04	666	https://doi.org/10.15673/swonaft.v80i2.322	ЖЕЛЕ ІЗ СОКУ КОРІННЯ СЕЛЕРИ	4
667	Стаття	Протягом довгого часу процес розробки продуктів був мало пов'язаний з дослідницькою та інженерною діяльністю підприємств. У зв’язку із розвитком розробки нових і спеціалізованих продуктів, з'явилася гостра необхідність у продуктовому розмаїтті, ство	2017-05-04	667	https://doi.org/10.15673/swonaft.v80i2.321	МЕТОДОЛОГІЯ РОЗРОБКИ НОРМАТИВНОЇ ДОКУМЕНТАЦІЇ, АДАПТОВАНОЇ ДО ЄВРОПЕЙСЬКОГО ЗАКОНОДАВСТВА	4
668	Стаття	З огляду на зростаючі об’єми виробництва безалкогольних напоїв та актуальність розробки нових, більш ефективних змішувачів рідких компонентів обгрунтовано конструкцію протитечійно-струминного змішувача, який забезпечує високу продуктивність при низь	2017-04-11	668	https://doi.org/10.15673/swonaft.v80i1.242	ВИЗНАЧЕННЯ ВМІСТУ ЦУКРОВОГО СИРОПУ В НАПОЇ ПРИ ЗМІШУВАННІ У ПРОТИТЕЧІЙНО-СТУМИННОМУ АПАРАТІ	4
669	Стаття	У статті представлені результати експериментальних досліджень переробки плодів аличі сорту “Фіолетова десертна” холодним способом (у свіжому стані) на перфорованої поверхні в поле відцентрових сил. Мета досліджень - розділення плодів на фракції - на	2017-04-11	669	https://doi.org/10.15673/swonaft.v80i1.241	ВИКОРИСТАННЯ МЕТОДІВ ТЕОРІЇ ПОДІБНОСТІ ТА  АНАЛІЗУ РОЗМІРНОСТЕЙ ПРИ ФІЗИКО-МАТЕМАТИЧНОМУ МОДЕЛЮВАННІ ПРОЦЕСІВ ПЕРЕРОБКИ ПЛОДІВ КІСТОЧКОВИХ КУЛЬТУР ХОЛОДНИМ  СПОСОБОМ	4
670	Стаття	У більшості галузей, які спеціалізуються на переробці сільськогосподарських продуктів, об'єм сировини в декілька разів перевищує вихід готової продукції, а відходи є цінним біоенергетичним ресурсом. Актуальність використання відходів можна визначити	2017-04-11	670	https://doi.org/10.15673/swonaft.v80i1.240	ВІДХОДИ ОЛІЙНОЖИРОВОГО ПІДПРИЄМСТВА, ЯК ДЖЕРЕЛО ЕНЕРГІЇ	4
671	Стаття	Розкривається суть запропонованих рішень з реконструкції системи аспірації на одному із зернопереробних підприємств Тернопільщини,а також можливі шляхи оцінки економічної вигоди від застосування пилоочисного обладнання. На основі аналізу роботи найп	2017-04-11	671	https://doi.org/10.15673/swonaft.v80i1.239	МОЖЛИВОСТІ ЗАСТОСУВАННЯ ПИЛОВЛОВЛЮВАЧІВ КОМБІНОВАНОЇ ДІЇ НА ПІДПРИЄМСТВАХ ПЕРЕРОБНОЇ ГАЛУЗІ РЕГІОНУ І ЕКОНОМІЧНА ОЦІНКА ЕФЕКТИВНОСТІ ПРОЦЕСУ ПИЛООЧИЩЕННЯ	4
672	Стаття	На базі потоково-просторових технологічних систем можуть широко вирішуватися питання комплексної автоматизації виробничих процесів виготовлення та упаковування різних виробів і виконання прогресивних технологічних процесів. Сучасний розвиток науково	2017-04-11	672	https://doi.org/10.15673/swonaft.v80i1.238	СИНТЕЗ ПРОСТОРОВИХ ПОТОКОВО-ТРАНСПОРТНИХ СИСТЕМ ЛІНІЙ  ПАКУВАННЯ ХАРЧОВИХ ПРОДУКТІВ	4
673	Стаття	Досліджено кінетику адсорбції оксіпропіонової кислоти природним цеолітом з метою очищення стічних вод молокопереробних підприємств. Також досліджено механізм процесу адсорбції і розроблено методи для ідентифікації експериментальних даних теоретичним	2017-04-11	673	https://doi.org/10.15673/swonaft.v80i1.237	ПРОБЛЕМА ОЧИЩЕННЯ СТІЧНИХ ВОД МОЛОКОПЕРЕРОБНИХ ПІДПРИЄМСТВ	4
674	Стаття	There were suggested in the paper the right principle form of the Vacuum Evaporator (VE) optimal parameters determination. The problem studied on the example of the corresponding device for the food juices concentration by the vacuum conditions. It i	2017-04-11	674	https://doi.org/10.15673/swonaft.v80i1.236	THE DETERMINATON OF ENERGY SOURCE OPTIMAL  PARAMETERS FOR VACUUM EVAPORATION	4
675	Стаття	Наявність каталізатора в коолігомеризатіна стадії дистиляції, яка здійснюється при температурах до 463 К, робить негативний вплив на колір кінцевого продукту. Традиційна технологія виробництва нафтополімерних смолшляхом каталітичної коолігомеризації	2017-04-11	675	https://doi.org/10.15673/swonaft.v80i1.235	ДОСЛІДЖЕННЯ ПРОЦЕСУ ДЕЗАКТИВАЦІЇ КООЛІГОМЕРИЗАТУ ІЗ ФРАКЦІЇ С9ОТРИМАНОГО ДВОСТАДІЙНИМ ТЕРМІЧНО-КАТАЛІТИЧНИМ  СПОСОБОМ	4
676	Стаття	В работе рассмотрен процесс разделение однородной системы (вода – уксусная кислота) с целью сокращения энергозатрат. Для получения максимального энергосберегающего эффекта была проведена как внешняя так и внутренняя интеграция технологического проце	2017-04-11	676	https://doi.org/10.15673/swonaft.v80i1.234	ИСПОЛЬЗОВАНИЕ ЭНЕРГЕТИЧЕСКОГО ПОТЕНЦИАЛА  ПРОЦЕССА РЕКТИФИКАЦИИ СМЕСИ  ВОДА – УКСУСНАЯ КИСЛОТА	4
677	Стаття	The operating characteristics adsorptive regenerator of low-potential heat and moisture based on composite sorbents ‘silica gel – sodium sulphate’ and ‘silica gel – sodium acetate’ synthesized by sol – gel method are studied. Sorption heat regenerato	2017-04-11	677	https://doi.org/10.15673/swonaft.v80i1.233	OPERATING CHARACTERISTICS OF ADSORPTIVE REGENERATOR OF  LOW-POTENTIAL HEAT AND MOISTURE BASED ON COMPOSITE SORBENTS ‘SILICA GEL – SODIUM SULPHATE’ AND ‘SILICA GEL – SODIUM ACETATE’  SYNTHESIZED BY SOL – GEL METHOD	4
678	Стаття	В роботі набула подальшого розвитку теорія диспергування жирової фази молока в струминному гомогенізаторі з роздільною подачею вершків. Актуальність досліджень обумовлена необхідністю підвищення ефективності процесу сучасних пристроїв для гомогенізац	2017-04-11	678	https://doi.org/10.15673/swonaft.v80i1.232	МЕХАНІЗМИ ДИСПЕРГУВАННЯ ЖИРОВИХ КУЛЬОК В  СТРУМИННОМУ ГОМОГЕНІЗАТОРІ МОЛОКА	4
679	Стаття	Екстрагування фізіологічно-активних сполук із рослинної сировини є важливим технологічним процесом цілого ряду галузей промисловості.  Ефективність процесу екстрагування із рослинної сировини залежить перш за все від розчинності і швидкості переходу	2017-04-11	679	https://doi.org/10.15673/swonaft.v80i1.231	РОЗРОБЛЕННЯ ЕКОЛОГІЧНО БЕЗПЕЧНОЇ ТЕХНОЛОГІЇ  ОДЕРЖАННЯ ФІЗІОЛОГІЧНО АКТИВНИХ СПОЛУК МЕТОДОМ ЕКСТРАГУВАННЯ РОСЛИННОЇ СИРОВИНИ	4
680	Стаття	У роботі запропоновано математичну модель процесу фільтрації рідких середовищ у мембранних технологіях. Модель побудована на основі положень механіки дисперсних середовищ. Тому вона дозволяє дослідити основні закономірності фільтрування рідких середо	2017-04-11	680	https://doi.org/10.15673/swonaft.v80i1.230	ВИЗНАЧЕННЯ КОНЦЕНТРАЦІЙ ФАЗ ПРИ МЕМБРАННОМУ ФІЛЬТРУВАННІ  РІДКИХ СЕРЕДОВИЩ	4
814	Стаття	Considered the technology for the production of edible powders from vegetable raw materials. The technology for producing powders from berries is developed to produce a high-quality product in which all ingredients of raw materials are stored in a c	2018-04-10	814	https://doi.org/10.15673/fst.v12i1.837	STUDY OF THE USE OF EDIBLE POWDERS TOMATO SAUCE TECHNOLOGIES	5
681	Стаття	У роботі проведено імітаційне моделювання процесу інфрачервоного жарення біфштексів за використання програмного комплексу Vensim, що реалізує системно-динамічну технологію потокового типу. Використання системно-динамічного моделювання уможливлює повн	2017-04-11	681	https://doi.org/10.15673/swonaft.v80i1.229	СИСТЕМНО-ДИНАМІЧНЕ МОДЕЛЮВАННЯ ПРОЦЕСУ ІНФРАЧЕРВОНОГО ЖАРЕННЯ БІФШТЕКСІВ	4
682	Стаття	В процесі роботи колонних віброекстракторів безперервної дії під впливом низькочастотних механічних коливань транспортувально-сепарувальних пристроїв (тарілок) в робочому об’ємі апарата утворюється основний двофазовий потік, який можна умовно розбит	2017-04-11	682	https://doi.org/10.15673/swonaft.v80i1.228	МАТЕМАТИЧНИЙ ОПИС ГІДРОДИНАМІЧНОЇ СТРУКТУРИ  ПОТОКІВ ПРИ БЕЗПЕРЕРВНОМУ ВІБРОЕКСТРАГУВАННІ НА ОСНОВІ  КОМІРКОВОЇ МОДЕЛІ ІЗ ЗАСТІЙНИМИ ЗОНАМИ	4
683	Стаття	Эффективность работы сушильной установки кипящего слоя зависит от правильного задания времени пребывания в ней высушиваемого материала. Экспериментальное исследование кинетики сушки в условиях интенсивного протекания тепломассообменных процессов в ча	2017-04-11	683	https://doi.org/10.15673/swonaft.v80i1.227	МАТЕМАТИЧЕСКОЕ МОДЕЛИРОВАНИЕ ДИНАМИКИ СУШКИ КОЛЛОИДНЫХ КАПИЛЛЯРНО-ПОРИСТЫХ ТЕЛ В УСЛОВИЯХ КИПЯЩЕГО СЛОЯ	4
684	Стаття	Розглянуті недоліки устаткування для термомеханічної обробки харчових продуктів. Пропонуються шляхи рішення енергетичних проблем в технологіях термообробки харчових рідин, сушіння дисперсних продуктів. Представлені конструкції сушарок і апаратів для	2017-04-11	684	https://doi.org/10.15673/swonaft.v80i1.226	ЗАСТОСУВАННЯ ТЕРМОМЕХАНІЧНИХ СИСТЕМ В ХАРЧОВИХ  ТЕХНОЛОГІЯХ	4
685	Стаття	В статье рассмотрены микроволновые технологии интенсификации процессов экстрагирования вкусовых и ароматических компонентов из кофейного сырья и концентрирования экстрактов ароматических и биологически-активных веществ. Показано влияние микроволново	2017-04-11	685	https://doi.org/10.15673/swonaft.v80i1.225	МИКРОВОЛНОВЫЕ ТЕХНОЛОГИИ ИНТЕНСИФИКАЦИИ  МАССООБМЕННЫХ И ТЕПЛОВЫХ ПРОЦЕССОВ ПРИ ПЕРЕРАБОТКЕ РАСТИТЕЛЬНОГО СЫРЬЯ	4
686	Стаття	В работе представлен критический анализ технологий экстрагирования из лекарственного растительного сырья. Показано, что в различных отраслях техники предпочтение отдается микроволновым способам подвода энергии. Приведены результаты комплексных экспер	2017-04-11	686	https://doi.org/10.15673/swonaft.v80i1.224	МАССОПЕРЕНОС ПРИ ЭКСТРАГИРОВАНИИ ИЗ ЛЕЧЕБНОГО  РАСТИТЕЛЬНОГО СЫРЬЯ В ЭЛЕКТРОМАГНИТНОМ ПОЛЕ	4
687	Стаття	Зараз існує велика потреба в зневоднених продуктах тривалого зберігання, у першу чергу з рослинної сировини. Сушіння грибів є однією з найважливіших стадій технологічного процесу виробництва харчових концентратів. Від режиму сушіння грибів залежить х	2017-04-11	687	https://doi.org/10.15673/swonaft.v80i1.223	ВИЗНАЧЕННЯ ОСНОВНИХ ТЕПЛОМАСООБМІННИХ ПАРАМЕТРІВ  СУШІННЯ КУЛЬТИВОВАНИХ ГРИБІВ ПРИ РІЗНИХ СПОСОБАХ  ЕНЕРГОПІДВЕДЕННЯ	4
688	Стаття	Під час переробки екзотичних фруктів, виникає велика кількість побічних продуктів, особливо насіння і шкірки, що традиційно викидають в навколишнє середовище, тим самим викликаючи органічне забруднення. Проте, слід зазначити, що ці побічні продукти є	2017-04-11	688	https://doi.org/10.15673/swonaft.v80i1.200	ЗАСТОСУВАННЯ ЕЛЕКТРОІМПУЛЬСНОЇ ЕНЕРГІЇ ПРИ  ЕКСТРАКЦІЇ БІОЛОГІЧНО АКТИВНИХ РЕЧОВИН З ВІДХОДІВ ПЕРЕРОБКИ  ЕКЗОТИЧНИХ ФРУКТІВ	4
689	Стаття	Актуальним на сьогоднішній день є завдання підвищення працездатності електро пневматичного приводу запірно-регулюючої трубопровідної арматури з метою досягнення експлуатаційних характеристик при змінних температурних показниках навколишнього середови	2017-04-11	689	https://doi.org/10.15673/swonaft.v80i1.199	ПІДВИЩЕННЯ ПРАЦЕЗДАТНОСТІ ТРУБОПРОВІДНОЇ  АРМАТУРИ В ТЕХНОЛОГІЧНИХ ПРОЦЕСАХ	4
690	Стаття	У  статті проведено порівняльний аналіз масообмінних процесів, таких як екстрагування та сушіння. Доведено важливість встановлення закономірностей протікання масообмінних процесів, адже маючи чіткі уявлення про механізм, рівновагу та кінетику можна	2017-04-11	690	https://doi.org/10.15673/swonaft.v80i1.198	РІВНОВАГА, МЕХАНІЗМ І КІНЕТИКА ПРОЦЕСІВ  ЕКСТРАГУВАННЯ ТА СУШІННЯ	4
703	Стаття	In 1994 N.~Papaghiuc introduced the notion of semi-slant submanifold in a Hermitian manifold which is a generalization of $CR$- and slant-submanifolds, \\cite{MR0353212}, \\cite{MR760392}.\n&#x0d;\n\nIn particular, he considered this submanifold in Kaehl	2019-01-21	703	https://doi.org/10.15673/tmgc.v11i3.1202	Warped product semi-slant submanifolds in locally conformal Kaehler manifolds II	6
691	Стаття	В матеріалах статті обґрунтовано актуальність вибору об’єкту дослідження – подрібнених стебел соняшника, з метою виготовлення паливних брикетів. Встановлено, що результати експериментальних та теоретичних досліджень, які наводяться у науковій літерат	2017-04-11	691	https://doi.org/10.15673/swonaft.v80i1.197	КІНЕТИКА ФІЛЬТРАЦІЙНОГО СУШІННЯ ПОДРІБНЕНИХ  СТЕБЕЛ СОНЯШНИКА	4
692	Стаття	На сьогоднішній день в Україні недостатньо виробництва з переробки рослинної сировини в харчові продукти, що дозволяє зберегти якість вихідної сировини з мінімальними енергозатратами на переробку.Труднощі при сушінні рослинної сировини пов’язані з т	2017-04-11	692	https://doi.org/10.15673/swonaft.v80i1.196	ДЕРИВАТОГРАФІЧНЕ ДОСЛІДЖЕННЯ ЗНЕВОДНЕННЯ БЕТАНІНОВМІСНИХ РОСЛИННИХ МАТЕРІАЛІВ  ТА ЇХ ТЕРМІЧНОЇ СТІЙКОСТІ	4
693	Стаття	Розроблено математичну модель безперервного процесу гранулоутворення гуміново-мінеральних композитів із заданими властивостями в псевдозрідженому шарі з використанням моделі нечітких множин. \nРобота проводилась на основі експериментальних досліджень	2017-04-11	693	https://doi.org/10.15673/swonaft.v80i1.195	МОДЕЛЮВАННЯ СТОХАСТИЧНИХ ПРОЦЕСІВ ГРАНУЛОУТВОРЕННЯ  МІНЕРАЛЬНО-ГУМІНОВИХ ДОБРИВ У  ПСЕВДОЗРІДЖЕНОМУ ШАРІ	4
694	Стаття	З метою розробки необхідного складу технологічного мастила, що мають не тільки підвищені антифрикційні властивості, а й забезпечують надійний протикорозійний захист внутрішньої поверхні труб досліджено процес взаємодії зразка натрій пірофосфату з по	2017-04-11	694	https://doi.org/10.15673/swonaft.v80i1.194	ДОСЛІДЖЕННЯ ВЗАЄМОДІЇ РОЗПЛАВУ НАТРІЙ  ПІРОФОСФАТУ З ОКАЛИНОЮ, УТВОРЕНОЮ В ПРОЦЕСІ  ГАРЯЧОГО ОБРОБЛЕННЯ МЕТАЛІВ ТИСКОМ	4
695	Стаття	Розглянуто процес розчинення полідисперсної твердої фази калію сульфату. Наведені літературні дані стосуються розчинення монодисперсної системи та умови постійності рушійної сили, що визначається як різниця між концентрацією насичення та текучою конц	2017-04-11	695	https://doi.org/10.15673/swonaft.v80i1.193	КІНЕТИКА РОЗЧИНЕННЯ ПОЛІДИСПЕРСНОГО КАЛІЮ СУЛЬФАТУ ЗА ПЕРЕМІННОЇ РУШІЙНОЇ СИЛИ	4
696	Стаття	В данной работе исследуется потенциал энергосбережения в процессах разделения широкой фракции углеводородов. На основании анализа технологической схемы и потоковых данных, с помощью метода пинч-анализа, спроектирована сеточная диаграмма интегрированн	2017-04-11	696	https://doi.org/10.15673/swonaft.v80i1.192	ИНТЕГРАЦИЯ ТЕПЛОВОГО НАСОСА В ПРОЦЕСС РАЗДЕЛЕНИЯ ЛЕГКИХ УГЛЕВОДОРОДОВ	4
714	Стаття	Статтю присвячено проблемі дифеоморфізмів многовидів, на яких задано афінорну структуру певного типу. Поняття 2F-планарного відображення афіннозв’язних і ріманових просторів було запроваджено  до розгляду Р.Дж.Кадемом. Воно є природним узагальненням	2018-06-10	714	https://doi.org/10.15673/tmgc.v11i1.918	2F-планарні відображення  псевдоріманових просторів з f-структурою	6
697	Стаття	Розглянуто механізм утворення кислого конденсату при спалюванні природного газу. Наведено основний склад димових газів і кислого конденсату. Встановлено, що кислий конденсат димових газів за своїм складом є знесоленою водою, що наближається до дистил	2017-04-11	697	https://doi.org/10.15673/swonaft.v80i1.191	УТВОРЕННЯ КИСЛОГО КОНДЕНСАТУ ПРИ ГЛИБОКІЙ  УТИЛІЗАЦІЇ ТЕПЛОТИ ПРОДУКТІВ ЗГОРЯННЯ ПРИРОДНОГО ГАЗУ І  ОБЛАДНАННЯ ДЛЯ ЙОГО НЕЙТРАЛІЗАЦІЇ	4
698	Стаття	In this paper we introduce a new class of foliations on Rie-mannian 3-manifolds, called B-foliations, generalizing the class of foliations of non-negative curvature. The leaves of B-foliations have bounded total absolute curvature in the induced Rie	2019-04-04	698	https://doi.org/10.15673/tmgc.v11i4.1307	Nonpositive curvature foliations on 3-manifolds with bounded total absolute curvature of leaves	6
699	Стаття	Let $M$ be a compact two-dimensional manifold and, $f \\in C^{\\infty}(M, R)$ be a Morse function, and $\\Gamma$ be its Kronrod-Reeb graph.\nDenote by $O(f)={f o h | h \\in D(M)}$ the orbit of $f$ with respect to the natural right action of the group of	2019-04-04	699	https://doi.org/10.15673/tmgc.v11i4.1306	Automorphisms of Kronrod-Reeb graphs of Morse functions on 2-sphere	6
700	Стаття	We discuss the integration problem for systems of partial differential equations in one unknown function and special attention is given to the first order systems. The Grassmannian contact structures are the basic setting for our discussion and the	2019-04-04	700	https://doi.org/10.15673/tmgc.v11i4.1305	On the integrability problem for systems of partial differential equations in one unknown function, I	6
701	Стаття	В статье изучаются 2F-планарные отображения псевдоримановых пространств, снабженных аффинорной структурой определенного типа. Понятие 2F-планарного отображения аффинносвязных и римановых пространств было введено в рассмотрение Р.Дж. Кадемом. В его р	2019-04-01	701	https://doi.org/10.15673/tmgc.v11i4.1304	Специальные классы псевдоримановых пространств с f-структурой, допускающих 2F-планарные отображения	6
704	Стаття	Как известно, функция двух переменных z=f(x, y) задает на плоскости (x, y) в окрестности регулярной точки некоторую три-ткань, образованную слоениями x=const, y=const и f(x, y)=const.\n&#x0d;\n\nТри-ткань называется регулярной, если она эквивалентна (л	2019-01-21	704	https://doi.org/10.15673/tmgc.v11i3.1201	О регулярных тканях, определенных плюригармоническими функциями	6
705	Стаття	Для n-вимірної (2 ⩽ n &lt; 1) комутативної асоціативної алгебри	2019-01-21	705	https://doi.org/10.15673/tmgc.v11i3.1200	Про моногенні функції на розширеннях комутативної алгебри	6
706	Стаття	In the following, bypassing dynamical systems tools, we propose a simple means of computing the box dimension of the graph of the classical Weierstrass function defined, for any real number~$x$, by\n\\[{\\mathcal W}(x)= \\sum_{n=0}^{+\\infty} \\lambda^n\\,	2018-09-15	706	https://doi.org/10.15673/tmgc.v11i2.1028	Bypassing dynamical systems: a simple way to get the box-counting dimension of the graph of the Weierstrass function	6
707	Стаття	It is proven that Rankin-Cohen brackets form an associative\ndeformation of the algebra of polynomials whose coeffcients are holomorphic\nfunctions on the upper half-plane.	2018-09-15	707	https://doi.org/10.15673/tmgc.v11i2.1027	Moyal and Rankin-Cohen deformations of algebras	6
708	Стаття	We study two measures of nonplanarity of cubic graphs G, the genus γ (G), and the edge deletion number ed(G). For cubic graphs of small orders these parameters are compared with another measure of nonplanarity, the rectilinear crossing number (G). W	2018-09-15	708	https://doi.org/10.15673/tmgc.v11i2.1026	On measures of nonplanarity of cubic graphs	6
709	Стаття	In the paper it is proved that any orientable surface admits an orientation-preserving diffeomorphism with one saddle orbit. It distinguishes in principle the considered class of systems from source-sink diffeomorphisms existing only on the sphere. I	2018-09-15	709	https://doi.org/10.15673/tmgc.v11i2.1025	A calculation of periodic data of surface diffeomorphisms with one saddle orbit.	6
710	Стаття	Продолжается изучение введенных ранее квази-геодезических отображений рекуррентно-параболических пространств. Выделен специальный класс таких отображений - канонические квази-геодезические отображения. Построены геометрические объекты, инвариантные о	2018-06-10	710	https://doi.org/10.15673/tmgc.v10i3-4.773	О канонических квази-геодезических отображениях рекуррентно-параболических пространств	6
711	Стаття	Статтю присвячено проблемі голоморфно-проективних перетворень. Варто зазначити, що Й. Мікеш та  Ж. Радулович довели, що локально конформно-келерові многовиди не дозволяють скінченних нетривіальних голоморфно проективних відображень для зв'язності Ле	2018-06-10	711	https://doi.org/10.15673/tmgc.v10i3-4.772	Інваріантні об'єкти конформно голоморфно-проективних перетворень ЛКК-многовидів	6
712	Стаття	In this paper we construct a new class of surfaces whose geodesic flow is integrable (in the sense of Liouville). We do so by generalizing the notion of tubes about curves to 3-dimensional manifolds, and using Jacobi fields we derive conditions unde	2018-06-10	712	https://doi.org/10.15673/tmgc.v10i3-4.770	Integrable geodesic flows on tubular sub-manifolds	6
718	Стаття	Гиперболическое пространство Ĥ3 положительной кривизны рассмотрено в проективной модели Кэли-Клейна, на идеальной области пространства Лобачевского. Введены основные понятия теории объемов пространства Ĥ3 через инварианты фундаментальной группы прост	2017-11-05	718	https://doi.org/10.15673/tmgc.v10i2.654	Объем конечного ортогонального h-конуса в гиперболическом пространстве положительной кривизны	6
719	Стаття	Для некоторых известных уравнений в частных производных найдены решения, которым соответствует шестиугольная три-ткань	2017-11-05	719	https://doi.org/10.15673/tmgc.v10i2.653	О  "шестиугольных" решениях некоторых уравнений математической физики	6
720	Стаття	У даній роботі вводиться поняття лінійно опуклих та спряжених функцій у n-вимірному гіперкомплексному просторі Hn, досліджуються їхні властивості.	2017-11-05	720	https://doi.org/10.15673/tmgc.v10i2.652	Властивості спряжених функцій у гіперкомлексному просторі	6
721	Стаття	Нехай $Z$ - некомпактний двовимірний многовид, і $\\Delta$ - одновимірне шарування на $Z$ таке, що межа $\\partial Z$ складається з деяких шарів $\\Delta$ і кожен шар $\\Delta$ є некомпактною замкнутою підмножиною $Z$. В роботі отримано характеризацію пі	2017-11-05	721	https://doi.org/10.15673/tmgc.v10i2.651	Характеризація смугастих поверхонь	6
722	Стаття	In 1994, in [13], N. Papaghiuc introduced the notion of semi-slant submanifold in a Hermitian manifold which is a generalization of CR- and slant-submanifolds. In particular, he considered this submanifold in Kaehlerian manifolds, [13]. Then, in 200	2017-11-05	722	https://doi.org/10.15673/tmgc.v10i2.650	Warped product semi-slant submanifolds in locally conformal Kaehler manifolds	6
723	Стаття	In the first section, we prove some isometric versions of the classical Ramsey theorem. In the second section, we discuss open problems on metrically Ramsey ultrafilters. 	2017-11-05	723	https://doi.org/10.15673/tmgc.v10i2.649	On colorings and isometries	6
724	Стаття	В работе рассматривается задача классификации точек двумерных поверхностей четырехмерного пространства Минковского. Получены аффинная классификация и классификация точек с помощью грассманова образа поверхности. Найдены условия при которых эти две кл	2017-08-13	724	https://doi.org/10.15673/tmgc.v1i10.550	Эквивалентность аффинной и грассмановой классификаций точек поверхности пространства Минковского	6
725	Стаття	У даній роботі розглядаються потоки Морса-Смейла на торі з діркою, особливі точки яких лежать на межі. Побудовано повний топологічний інваріант даних потоків та описано їх топологічну структуру. Обраховано загальну кількість топологічно нееквівалентн	2017-08-13	725	https://doi.org/10.15673/tmgc.v1i10.549	Потоки Морса-Смейла на торі з діркою	6
726	Стаття	Let $Z$ be a non-compact two-dimensional manifold obtained from a family of open strips $\\mathbb{R}\\times(0,1)$ with boundary intervals by gluing those strips along their boundary intervals.\n\nEvery such strip has a foliation into parallel lines $\\ma	2017-08-13	726	https://doi.org/10.15673/tmgc.v1i10.548	Homeotopy groups of one-dimensional foliations on surfaces	6
727	Стаття	In this paper we will consider the 2-fold symmetric complex hy­perbolic triangle groups generated by three complex reflections through angle 2Π/p with p ≥ 2. We will mainly concentrate on the groups where some ele­ments are elliptic of finite order.	2017-08-13	727	https://doi.org/10.15673/tmgc.v1i10.547	Complex hyperbolic triangle groups with 2-fold symmetry	6
728	Стаття	В работе  дан обзор результатов, связанных с проблемой тени, полученных в исследованиях за последние полтора года. Обсуждаются нерешенные задачи и даны оценки необходимых и достаточных условий.	2017-04-25	728	https://doi.org/10.15673/tmgc.v9i3-4.319	Задача о тени и смежные задачи	6
729	Стаття	Ми вивчаємо топологічні властивості часткових метрик і частково метричних просторів, зокрема, досліджуємо зв'язок між регулярністю частково метричних просторів і різними аспектами неперервності часткової метрики. Для відображень зі значеннями у частк	2017-04-25	729	https://doi.org/10.15673/tmgc.v9i3-4.318	Топологічні властивості частково метричних просторів	6
730	Стаття	Ми вводимо поняття (локально) слабкого простору-склеювача і розглядаємо застосування склеювачів до берівської класифікації відображень з класів Лебеґа, а також фрагментовних відображень.	2017-04-25	730	https://doi.org/10.15673/tmgc.v9i3-4.317	Застосування просторів-склеювачів до класифікації Бера відображень однієї змінної	6
731	Стаття	In a M. Prvanović’s paper [5], we can find a new curvature-like tensor in an almost Hermitian manifold.\nIn this paper, we define a new curvature-like tensor, named contact holomorphic Riemannian, briefly (CHR), curvature tensor in an almost contact	2017-04-25	731	https://doi.org/10.15673/tmgc.v9i3-4.320	A new curvature-like tensor in an almost contact Riemannian manifold	6
732	Стаття	Ранее мы ввели в рассмотрение  понятие полукватернионной структуры на пространстве аффинной связности, порожденной парой почти комплексных структур, коммутирующих друг с другом. Мы также исследовали 4-квазипланарные отображения  пространств аффинной	2017-01-20	732	https://doi.org/10.15673/tmgc.v9i2.281	О 4-квазипланарных отображениях полукватернионных многообразий	6
733	Стаття	В данной работе рассматриваются классы поверхностей (времениподобные и пространственноподобные) пространства Минковского ^1R_4 со стационарными значениями кривизны грассманова многообразия PG(2,4) вдоль площадок, касательных к их грассманову образу Г	2017-01-20	733	https://doi.org/10.15673/tmgc.v9i2.280	О поверхностях пространства Минковского со стационарными значениями кривизны грассманова образа	6
734	Стаття	В роботі досліджуються топологічні властивості потоків Морса-Смейла на двовимірному диску, у яких особливості лежать на межі диска. Побудовано повний топологічний інваріант потоку. Отримана топологічна класифікація. Запропоновано спосіб нумерації пот	2017-01-20	734	https://doi.org/10.15673/tmgc.v9i2.279	Топологія потоків Морса-Смейла з особливостями на межі двовимірного диска	6
735	Стаття	Досліджується геометрія нескінченних ітерованих гіперпросторів компактних max-плюс опуклих множин, їх поповнень та компактифікацій.	2017-01-20	735	https://doi.org/10.15673/tmgc.v9i2.278	Трійки нескінченних ітерацій гіперпросторів max-плюс опуклих множин	6
736	Стаття	Нехай X - (n+1)-вимірний многовид, Δ  - одновимірне шарування на X і p: X → X / Δ фактор-відображення в простір шарів. Назвемо шар ω шарування Δ спеціальным, якщо простір шарів X / Δ не є хаусдорфовим в точці ω. В статті наведені необхідні і достатні	2017-01-20	736	https://doi.org/10.15673/tmgc.v9i2.277	Одновимірні шарування на топологічних многовидах	6
737	Стаття	Памяти товарища и друга	2016-06-30	737	https://doi.org/10.15673/tmgc.v9i1.93	Леонид Евгеньевич Евтушик - геометр	6
738	Стаття	В этой статье мы используем аффинную геометрию на прямой для построения обыкновенных дифференциальных уравнений, интегрируемых в квадратурах. Эти уравнения являются дифференциаль ными уравнениями для аффинных геометрических величин, допускающих аффин	2016-06-30	738	https://doi.org/10.15673/tmgc.v9i1.92	Квадратуры и аффинная геометрия на прямой	6
813	Стаття	The article deals with ecological safety, resource saving, economic efficienty in the technologies of wastewater purification from heavy metals ions. It is shown that modern technologies of wastewater purification from such substances need to be imp	2018-04-10	813	https://doi.org/10.15673/fst.v12i1.841	BIOSORBENTS – PROSPECTIVE MATERIALS FOR HEAVY METAL IONS EXTRACTION FROM WASTEWATER	5
739	Стаття	Розглянуто голоморфно-проективнi вiдображення та можливiсть Ёх iснування на локально конформно-келерових многовидах. Отримана система рiвнянь типу Коши, що є визачальною для групи конформно голоморфно-проективних iнфiнiтезимальних перетворень.	2016-06-30	739	https://doi.org/10.15673/tmgc.v9i1.91	Голоморфно-проективнi перетворення та конформно-келеровi многовиди	6
740	Стаття	Розглянуто iнфiнiтезимальнi перетворення рiманових просторiв з умовою iнварiантностi тензору Ейнштейна. Визначено умови iнварiантностi цього тензору. Також, знайденi iншi тензорнi iнварiнти перетворень. Також, розглянутi перетворення у просторах стал	2016-06-30	740	https://doi.org/10.15673/tmgc.v9i1.90	Нескiнченно малi перетворення у просторах сталої скалярно кривини та iнварiантнiсть певних геометричних об'єктiв	6
741	Стаття	В статтi дослiджується структура симетричних розв'язкiв матричного рiвняння AX = B, де A i B - (m х n)-матрицi над полем F, X  невiдома (n х n)-матриця. Встановлено новi умови, за яких для рiвняння AX = B iснують симетричнi розв'язки та описано їх ст	2016-06-30	741	https://doi.org/10.15673/tmgc.v9i1.89	Структура симетричних розв'язкiв матричного рiвняння AX = B над довiльним полем	6
742	Стаття	В роботі було досліджено та знайдено всі можливі f-атоми складност 4 функцій Морса на замкнених орієнтованих двовимірних многовидах.	2016-06-30	742	https://doi.org/10.15673/tmgc.v9i1.88	f-атоми складності функцій Морса на замкнених оріорієнтованих двовимірних многовидах	6
743	Стаття	The duality between E8xE8 heteritic string on manifold K3xT2 and Type IIA string compactified on a Calabi-Yau manifold induces a correspondence between vector bundles on K3xT2 and Calabi-Yau manifolds. Vector bundles over compact base space K3xT2 for	2016-06-30	743	https://doi.org/10.15673/tmgc.v9i1.87	K-theory and phase transitions at high energies	6
744	Стаття	In the paper we go on our work on application of a chaos geometry tools and non-linear analysis technique to studying chaotic features of different nature systems. Here there are presented the results of using an advanced chaos-geometric approach to	2016-06-30	744	https://doi.org/10.15673/tmgc.v9i1.86	Geometry of a Chaos: Advanced computational ap- proach to treating chaotic dynamics of environ- mental radioactivity systems II	6
745	Стаття	Recently, microalgae have become important in their health, and cosmetic applications since they are viewed as new sources of carotenoids. Fucoxanthin is also a type of carotenoid. The anti-diabetic, anti-obesity, anti-cancer, and antioxidant proper	2019-05-03	745	https://doi.org/10.15673/fst.v13i1.1342	OPTIMIZATION OF EXTRACTION PARAMETERS FOR FUCOXANTHIN, GALLIC ACID AND RUTIN FROM NITZSCHIA THERMALIS	5
746	Стаття	Upper Mesopotamia is a part of Turkish territory is the homeland of the olive tree with a wide range genetic resource. This is the first report on chemical composition and oxidative stability of olive oil extracted from Uslu cultivar grown locally i	2019-05-02	746	https://doi.org/10.15673/fst.v13i1.1341	EFFECTS OF FİLTRATİON PROCESS AND STORAGE TİME ON THE CHEMİCAL CHANGES AND SENSORY PROPERTİES OF  OLİVE OİL EXTRACTED FROM TURKİSH USLU CULTİVAR	5
747	Стаття	Lipid oxidation is the main chemical process affecting mayonnaise deterioration. Today, essential oils from aromatic plants have been qualified as natural antioxidants and proposed as potential substitutes of synthetic antioxidants in food products.	2019-05-02	747	https://doi.org/10.15673/fst.v13i1.1340	OXIDATIVE STABILITY OF MAYONNAISE SUPPLEMENTED WITH ESSENTIAL OIL OF ACHILLEA MILLEFOLIUM SSP MILLEFOLIUM DURING STORAGE	5
748	Стаття	The research is dedicated to the development of recipes of cooked sausages and their diversification through including in the recipes poultry meat, and by-products of processing meat and milk. The meat products most affordable and popular with the U	2019-05-02	748	https://doi.org/10.15673/fst.v13i1.1339	EFFICIENCY OF USING THE ANIMAL PROTEIN COMPLEX IN THE TECHNOLOGY OF COOKED SAUSAGE	5
749	Стаття	The paper considers the technological properties of dried carrot pomace obtained in the technology of organic direct pressing juices. Its use as a valuable source of food fibre and β-carotene in bread technology for elderly people has been substanti	2019-05-02	749	https://doi.org/10.15673/fst.v13i1.1338	USE OF DRIED CARROT POMACE IN THE TECHNOLOGY OF WHEAT BREAD FOR ELDERLY PEOPLE	5
750	Стаття	The article considers the possibility of obtaining a protein-rich feed additive from by-products of sunflower oil production. From literary sources it is known that in the global food market, Ukraine ranks first in cultivating the sunflower and in p	2019-05-02	750	https://doi.org/10.15673/fst.v13i1.1337	PROSPECTS OF USING BY-PRODUCTS OF SUNFLOWER OIL  PRODUCTION IN COMPOUND FEED INDUSTRY	5
751	Стаття	The paper presents the results of the study of changes in the microbiological parameters of instant cereals for military personnel during storage. The purpose of the microbiological studies of instant cereals was assessing whether the products were	2019-05-02	751	https://doi.org/10.15673/fst.v13i1.1336	MICROBIOTA OF INSTANT CEREALS AND ITS CHANGE DURING STORAGE	5
752	Стаття	The article presents the results of studying the foaming properties of gelatin with solubilized substances by Rauch’s method. To improve the nutritional value of gelatin, deodorized refined sunflower oil with β-carotene was used. It has been proved	2019-05-02	752	https://doi.org/10.15673/fst.v13i1.1335	STUDY OF THE FOAMING PROPERTIES OF GELATIN WITH SOLUBILIZED SUBSTANCES FOR THE PRODUCTION OF MARSHMALLOWS	5
753	Стаття	The paper describes some aspects of producing germinated cereal grain with the use of fruits acids of various concentrations. The technological process of grain germination (including washing grain, disinfection, hydration by alternate steeping and	2019-05-02	753	https://doi.org/10.15673/fst.v13i1.1334	FEATURES OF GRAIN GERMINATION WITH THE USE OF AQUEOUS SOLUTIONS OF FRUIT ACIDS	5
754	Стаття	The article considers how oenological tannins effect on the content of anthocyanins, phenolic substances, and their forms that influence the stability of the colour of rosé and red wines. The research material was wine model systems that underwent i	2019-05-02	754	https://doi.org/10.15673/fst.v13i1.1333	THE INFLUENCE OF TANNIN PREPARATIONS ON THE CONTENT AND FORM OF ANTHOCYANINS OF MODEL WINE SYSTEMS IN THE CONDITIONS OF  INDUCED OXIDATION	5
760	Стаття	The work analyzes the global experience of using wines and grape-processing products to support a person’s\nphysical, mental, and psychological health, to slow down aging, to prevent and treat many diseases, in particular cardiovascular and\noncologic	2019-04-11	760	https://doi.org/10.15673/fst.v13i1.1308	RESEARCH OF THE PROPERTIES OF GRAPE PROCESSING PRODUCTS IN RELATION TO ITS APPLICATION IN SPA AND WELLNESS INDUSTRIES	5
761	Стаття	During the implementation of scientific research on the direction of automation of feed mills there was a significant disadvantage. The losses resulting from this shortcoming are, according to our estimates, about 1.2 billion hryvnias per year only	2019-01-24	761	https://doi.org/10.15673/fst.v12i4.1222	SYSTEM FOR ANALYZING THE QUALITATIVE  CHARACTERISTICS OF GRAIN MIXES IN REAL TIME MODE	5
762	Стаття	The article presents the results of obtaining dried poultry meat under vacuum conditions using ultrahigh electromagnetic energy sources. A characteristic of the most common principles of drying is presented, which shows that the trends in the techno	2019-01-22	762	https://doi.org/10.15673/fst.v12i4.1218	KINETICS AND ENERGY OF POULTRY MEAT DEHYDRATION IN VACUUM AND MICROWAVE FIELD CONDITIONS	5
763	Стаття	The aim of the research was to make the mechanical and technological process of calibrating confectionery sunflower seeds with a vibrating sieve more effective by giving reasons for its rational methodical and technological parameters. The study of	2019-01-22	763	https://doi.org/10.15673/fst.v12i4.1209	STUDY OF THE PROCESS OF CALIBRATION OF CONFECTIONERY  SUNFLOWER SEEDS	5
764	Стаття	Meat products, at different technological stages and as finished articles, retain their morphological features. Microstructure analysis of the raw material, ready-to-cook products, or finished articles allows determining the presence of certain type	2019-01-21	764	https://doi.org/10.15673/fst.v12i4.1208	MICROSTRUCTURAL ANALYSIS OF FORCEMEATS OF READY-TO-COOK CHOPPED MEAT WITH FUNCTIONAL INGREDIENTS	5
765	Стаття	This study considers the development of combined meat products containing, along with meat raw materials, other types of raw materials of animal and vegetable origin. The aim of the research is to substantiate the advantages of combining duck meat o	2019-01-21	765	https://doi.org/10.15673/fst.v12i4.1207	DEVELOPMENT OF COOKED SMOKED SAUSAGE ON THE BASIS OF MUSKOVY DUCK MEAT	5
766	Стаття	This article is devoted to the optimization of the formulations of mincemeat products (cutlets) based on the semi-finished product from the freshwater mussel of the genus Anodonta. Recipe of this semi-finished product that can be introduced into the	2019-01-21	766	https://doi.org/10.15673/fst.v12i4.1206	OPTIMIZATION OF THE RECIPES OF FORCEMEAT PRODUCTS ON THE BASIS OF PROCESSED FRESHWATER MUSSELS	5
767	Стаття	In the article the advantages of using grain legumes as protein plant concentrates are analysed, and a comparative analysis of the chemical composition of the pea and the soybean meal is carried out. Besides, the official parameters for different pr	2019-01-21	767	https://doi.org/10.15673/fst.v12i4.1205	SCIENTIFIC AND PRACTICAL BASIS OF USING PROTEIN PLANT CONCENTRATES FOR THE PRODUCTION OF COMPOUND FEEDS	5
768	Стаття	Recently, sugar maize has become more and more widely used for the production of new types of food. Its use in the production of cereal products for babies makes it possible to use no sugar in their composition, switch to the production of dietary a	2019-01-21	768	https://doi.org/10.15673/fst.v12i4.1204	CHANGE OF MICROBIOTAS OF MAIZE-BASED EXTRUDED PRODUCTS WITH VEGETABLE ADDITIVES DURING STORAGE	5
769	Стаття	The secondary raw materials have been studied as sources of pectic substances necessary for the endo-ecological protection of the organism in the globally deteriorating living conditions of modern humans. The article reveals the significance and lon	2019-01-18	769	https://doi.org/10.15673/fst.v12i4.1198	SECONDARY PLANT RESOURCES AS PROSPECTIVE UNCONVENTIONAL SOURCES OF PECTIС SUBSTANCES	5
770	Стаття	The work considers the isolation of homogeneous precursor proteins of biologically active peptides from milk whey by gel filtration, in conditions that maximally ensure the preservation of their structure, composition, and properties. Considering th	2019-01-17	770	https://doi.org/10.15673/fst.v12i4.1183	GEL FILTRATION OF COW MILK WHEY PROTEINS	5
771	Стаття	This paper considers the prospects of using phytomaterials to solve the problems of baking industry, caused by the instability and defects of wheat flour, and analyses the main methods of regulating structural and mechanical properties of wheat doug	2019-01-17	771	https://doi.org/10.15673/fst.v12i4.1182	METHODS OF REGULATING PHYSICAL PROPERTIES OF DOUGH USING PHYTOEXTRACTS	5
772	Стаття	The paper presents the overview data of the diseases and major classes of microorganisms which cause tomato damage after harvesting. Generally accepted effective ways of storage of fruit and vegetable products are considered. These are cold storage	2019-01-17	772	https://doi.org/10.15673/fst.v12i4.1181	PERSPECTIVES OF THE USE OF PLANT RAW MATERIAL EXTRACTS FOR STORAGE OF TOMATOES	5
773	Стаття	The Ukrainian people’s diet lacks a number of biologically active substances. But their addition to the food is not effective enough as aggressive bodily fluids influence their activity and substantially reduce it. There are undesirable changes in t	2019-01-17	773	https://doi.org/10.15673/fst.v12i4.1180	OBTAINING AND CHARACTERISTICS OF A PAPAIN AND MAIZE ARABINOXYLAN COMPLEX	5
774	Стаття	The food industry is a strategic industry that works quite steadily even during periods of economic crises, providing food security to any state, and is a source of raw material for other industries with a high potential for development, for example	2019-01-17	774	https://doi.org/10.15673/fst.v12i4.1179	OPTIMIZATION OF PARAMETERS OF FERMENTOLYSIS OF PROTEINS IN THE COMPOSITION OF SERUM-PROTEIN CONCENTRATE	5
775	Стаття	Cultivation of Spirulina platensis in Zarrouk media containing 0–20 g l-1 glucose was studied in a photobioreactor for 30 days using a light intensity of 3 klux. Various parameters were measured to evaluate the enhancement of cell performance with g	2019-01-17	775	https://doi.org/10.15673/fst.v12i4.1178	FEATURES OF SPIRULINA PLATENSIS CULTIVATED UNDER AUTOTROPHIC AND MIXOTROPHIC CONDITIONS	5
776	Стаття	The article presents the results of investigating how the intensity of aerating the medium effects on the cultivation process and the metabolic activity of alcoholic yeast Saccharomyces cerevisiae, strain U-563, in the modern technology of alcohol a	2019-01-17	776	https://doi.org/10.15673/fst.v12i4.1177	THE EFFECT OF THE INTENSITY OF AERATING THE MEDIUM ON THE METABOLIC ACTIVITY OF ALCOHOL YEAST	5
777	Стаття	Fermenting microflora has been selected by biotechnological activity markers, with various methodological approaches used, namely: directional selection, selection of bacteriophage-insensitive mutants, protoplast regeneration. The experimental data	2019-01-15	777	https://doi.org/10.15673/fst.v12i4.1176	STUDY OF THE BIOTECHNOLOGICAL POTENTIAL OF SELECTED LACTIC ACID BACTERIA CULTURES	5
778	Стаття	The possibility of obtaining bioavailable mixed ligand chelate complexes of Magnesium has been considered. As bioligands, it is proposed to use the metabolites and products of enzymatic hydrolysis of the peptidoglycans of the cell walls of Bifidobac	2018-10-12	778	https://doi.org/10.15673/fst.v12i3.1054	Obtaining and characteristic of the magnesium organic forms on the basis of products of bifidobacteria processing and their metabolites	5
779	Стаття	The paper presents the results of studies related to determining the interconnections between hydrodynamic and energy parameters of gas-liquid media. The whole scope of information about them taken together allows evaluating the prospects of searchi	2018-10-04	779	https://doi.org/10.15673/fst.v12i3.1047	Hydrodynamic and energy parameters of gas-liquid media	5
780	Стаття	The article represents the results of research of the effluents purification by the reagent methods. The effluents were polluted by organic compounds of processing enterprises  with small productivity. The analysis of pollution of the hydrosphere ca	2018-10-04	780	https://doi.org/10.15673/fst.v12i3.1046	Reagent purification of the processing industry enterprises effluents	5
781	Стаття	The paper considers the kinetics of changes in the values of рН and temperature of beef of slaughtered Holstein bull calfs aged 15 months during cold storage. It has been established that the rate of pH decrease during autolytic maturation is greatl	2018-10-04	781	https://doi.org/10.15673/fst.v12i3.1044	Determination of functional and technological properties of beef based on the analysis of color digital images of muscular tissue samples	5
782	Стаття	Today, bakery and milling industry is actively developing, as well as other branches of food industry. This is due to the applying of new foreign trends to the technology and range of products of the Ukrainian market. In these conditions, the classi	2018-10-04	782	https://doi.org/10.15673/fst.v12i3.1043	Development of technological solutions for flour production with specified quality parameters	5
783	Стаття	This article shows the prospects of using glucan-containing cereal grain materials in the production of baked goods. The results of the research are presented of how oat and barley flours and the method and stage of adding them effect on the quality	2018-10-04	783	https://doi.org/10.15673/fst.v12i3.1042	The use of glucan-containing grain materials in the technology of foam-like pastries	5
784	Стаття	In this paper, new results are presented regarding the preparation of polyextracts under the conditions of the action of the microwave field and their subsequent thickening. According to the hypothesis advanced by the authors, the features of the se	2018-10-04	784	https://doi.org/10.15673/fst.v12i3.1045	The using of mechanodiffusion effect in the production of concentrated polyextracts	5
785	Стаття	The article considers the safety and environmental cleanliness of grapeseed powders compared to the natural and alkalized cocoa powders. The content of heavy metals in the investigated powders has been determined by the atomic adsorption method; rad	2018-10-03	785	https://doi.org/10.15673/fst.v12i3.1041	Investigation of the safety grapeseed powder as an alternative to cocoa-powder in a confectionery glaze	5
786	Стаття	Physical and chemical properties of cream multistep modes of ripening and fermentations are investigation and their role in the production of sour-cream butter is studied. The process of ripening of cream was carried out multistep, regimes were selec	2018-10-03	786	https://doi.org/10.15673/fst.v12i3.1040	Influence of temperature regimes of ripening and fermentation stages on the physical and chemical properties of cream and sour-cream butter quality indicators	5
787	Стаття	In this work, a film-forming coating for natural semi-finished pork meat has been developed, which has barrier properties against microbial flora and free oxygen radicals. Polysaccharides such as agar, gelatin, cornstarch, and citrus pectin were use	2018-10-03	787	https://doi.org/10.15673/fst.v12i3.1039	Edible film-forming coating with CO2-extracts of plants for meat products	5
788	Стаття	In this study Turkish monocultivar extra virgin olive oil (EVOO) “Sarı Ulak” was extracted by using the Mobile Olive Oil Processing Unit (TEM Oliomio 500-2GV, Italy). Changes in minor and major components and quality characteristics, free fatty acid	2018-10-03	788	https://doi.org/10.15673/fst.v12i3.1038	Determination of some chemical and quality parameters of changes in turkish Sari Ulak monocultivar extra virgin olive oil during 12 months of storage	5
789	Стаття	In this paper, the problem of studying of the films properties on the basis of uronate polysaccharides (sodium alginate and pectin low-esterified amidated), created on the principle of ionotropic gelation with the participation of calcium ions, has	2018-10-03	789	https://doi.org/10.15673/fst.v12i3.1037	Investigation of the films based on the uronate polysaccharides by the method of differential scanning calorimetry	5
790	Стаття	The peculiarities of crystallization during the freezing of the inflorescences broccoli of Parthenon sort, zoned cabbage  in Ukraine, have been researched and analyzed. The mass fraction of moisture and the form of its connection with dry substances	2018-10-03	790	https://doi.org/10.15673/fst.v12i3.1036	The peculiarities of crystal formation during freezing of broccoli	5
791	Стаття	The article considers the scientific aspects of probable partial transformation of lactose into lactobionic acid due to the electrical discharge dispersion of magnesium and manganese conductive granules in milk whey – a traditional lactose-containin	2018-10-03	791	https://doi.org/10.15673/fst.v12i3.1035	The effect of electrical discharge treatment of milk whey on partial conversion of lactose into lactobionic acid	5
792	Стаття	Nowadays, it is recognized that a lot of polysaccharides are biologically active. It is well known that these biomolecules show the highest level of their activity if they are water-soluble preparations, their molecular weight being 15–25 kDa, and i	2018-10-03	792	https://doi.org/10.15673/fst.v12i3.1032	Features of the hemicellulose structure of some species of regional raw materials and products of their enzymatic hydrolysis	5
793	Стаття	Einkorn wheat is a grain crop characterized by the ability not to accumulate heavy metals from the soil. Besides, it is rich in selenium. Jerusalem artichoke is rich in inulin. From the combination of these two types of flour (einkorn wheat and Jeru	2018-07-02	793	https://doi.org/10.15673/fst.v12i2.943	DETERMINING THE MODES OF TECHNOLOGICAL OPERATIONS IN THE PRODUCTION OF EINKORN WHEAT BREAD MADE OF FROZEN DOUGH AND ENRICHED WITH JERUSALEM ARTICHOKE FLOUR	5
794	Стаття	In the article, based on analysis of the market of dry breakfasts in Ukraine and calculations of the assortment of instant and quick-cooked cereals, which are implemented in trading networks of Odessa and Odessa region, it was established that studi	2018-07-02	794	https://doi.org/10.15673/fst.v12i2.941	MODERN TECHNOLOGY OF PRODUCTION AND STRATEGY OF PROMOTION OF NEW CEREAL PRODUCTS ON UKRAINIAN CONSUMER MARKET	5
795	Стаття	The effect of grape powders on the rheological properties of dough and the indicators of butter biscuits quality have been investigated. Butter biscuits were cooked with the addition of powdered grape seeds and grape skins from the grape pomace obta	2018-07-02	795	https://doi.org/10.15673/fst.v12i2.945	THE INFLUENCE OF GRAPE POWDERS ON THE RHEOLOGICAL PROPERTIES OF DOUGH AND CHARACTERISTICS OF THE QUALITY OF BUTTER BISCUITS	5
796	Стаття	It is found that the ways of storing radish root vegetables have different effect on their nutritive properties. The data obtained show that the total mass losses during storage in containers in bulk range from 14.80% (Bila Zymova Skvyrska) to 19.20	2018-07-02	796	https://doi.org/10.15673/fst.v12i2.942	CHANGES IN THE NUTRITIVE VALUE OF THE RADISH OF DIFFERENT VARIETIES DEPENDING ON THE STORAGE METHOD	5
797	Стаття	The article reveals the research results of freshness and safety of sprouted wheat bread made with the use of water additionally treated with nonequilibrium low-temperature contact plasma. Prospects of the use of dispersion of wheat grain for the wh	2018-07-02	797	https://doi.org/10.15673/fst.v12i2.940	PLASMA-CHEMICALLY ACTIVATED WATER INFLUENCE ON STALING AND SAFETY OF SPROUTED BREAD	5
798	Стаття	Industrial cultivation of mushrooms in Ukraine in recent years has been developing at a rather high pace. A promising consumer of Ukrainian mushrooms may be the European Union market. But mushrooms are not delivered there in significant volumes due t	2018-07-02	798	https://doi.org/10.15673/fst.v12i2.939	DETERMINING HEAVY METALS IN MUSHROOM SAMPLES BY STRIPPING VOLT-AMMETRY	5
799	Стаття	The leading vegetables in Ukraine are cabbages, cucumbers, tomatoes, sweet peppers, and aubergines.  More than 27 million tons of sweet pepper is grown in the world yearly, and only about 161,600 tons of it in Ukraine. However, it takes one of the l	2018-07-02	799	https://doi.org/10.15673/fst.v12i2.938	THE RATE OF THE TEMPERATURE DROP IN SWEET PEPPERS AT THE TECHNICAL STAGE OF RIPENESS DURING THEIR COOLING	5
800	Стаття	Grape pomace contains a complex of valuable and biologically active compounds. Drying is one of the main ways of microbiological stabilisation and preservation of the nutritional value of this secondary raw material. Kinetic parameters of dehydratio	2018-07-02	800	https://doi.org/10.15673/fst.v12i2.937	STUDYING THE PROPERTIES OF GRAPE POMACE AS OF AN OBJECT OF DRYING	5
801	Стаття	. In the article, the data are given of research carried out in vitro to determine the amino acid composition and the degree of digestibility of the reference and experimental samples of cooked sausage, with the use of the protein-containing composi	2018-07-02	801	https://doi.org/10.15673/fst.v12i2.936	QUALITY ASSESSMENT OF PROTEINS IN COOKED SAUSAGES WITH FOOD COMPOSITIONS	5
802	Стаття	The possibility of obtaining bioavailable mixed ligand chelate complexes of calcium has been considered. As bioligands, it is proposed to use the metabolic products of probiotic bacteria combination and products of enzymatic hydrolysis of peptidogly	2018-07-02	802	https://doi.org/10.15673/fst.v12i2.944	OBTAINING AND CHARACTERISTICS OF CALCIUM ORGANIC FORMS ON THE BASIS OF METABOLITES AND PROCESSING PRODUCTS OF PROBIOTIC BACTERIA	5
803	Стаття	The purpose of this study was to investigate the effect of the collagen-based additive Bilkozyne on the texture of cooked sausages. This additive is a food ingredient obtained by partial hydrolysis of a beef skin split. We suggested that Bilkozyne u	2018-07-02	803	https://doi.org/10.15673/fst.v12i2.935	MORPHOLOGY OF THE SURFACE OF COOKED SAUSAGES MADE WITH THE COLLAGEN-CONTAINING PROTEIN ADDITIVE “BILKOZYNE”	5
804	Стаття	The yttrium (III)-rutin (Rut) complex in the presence of bovine serum albumin (BSA) is suggested as a luminescent sensor to determine tartrate ions (Tart). It has been experimentally established that tartrate ions reduce the luminescence intensity (	2018-07-02	804	https://doi.org/10.15673/fst.v12i2.934	DETERMINING TARTRATE IONS IN THE SAMPLES OF MINERAL TABLE WATERS BY THE DECAY OF MOLECULAR LUMINESCENCE OF RUTIN IN COMPLEX WITH YTTRIUM (III)	5
805	Стаття	The article considers the possibility of obtaining purified fractions-precursors of bioactive peptides from milk proteins by the method of preparative electrophoresis. To choose an electrophoretic system, a comparative study has been carried out of	2018-07-02	805	https://doi.org/10.15673/fst.v12i2.932	ELECTROPHORETIC SYSTEMS FOR PREPARATIVE FRACTIONATION OF PROTEIN PRECURSORS OF BIOACTIVE PEPTIDES FROM COW’S MILK	5
806	Стаття	In this paper, an optimal complex is selected of enzyme preparations for hydrolysis of the components of grain raw materials during fermentation of high concentration wort. When selecting enzyme systems, their effect on the technical and chemical pa	2018-07-02	806	https://doi.org/10.15673/fst.v12i2.931	SELECTION OF THE COMPLEX OF ENZYME PREPARATIONS FOR  THE HYDROLYSIS OF GRAIN CONSTITUENTS DURING THE FERMENTATION OF THE WORT OF HIGH CONCENTRATION	5
807	Стаття	The article presents data on the development of the technology of multicomponent probiotics from two bacterial strains: Bifidobacterium longum-Ya3 and Propionibacterium shermanii-4. The ability of bacteria of the genus Propionibacterium to have a se	2018-07-02	807	https://doi.org/10.15673/fst.v12i2.930	TECHNOLOGY OF PRODUCING SYMBIOTIC BIOLOGICALLY ACTIVE ADDITIVE	5
808	Стаття	The peculiarities of anaerobic fermentation processes with the accumulation of dissolved ethyl alcohol and carbon dioxide in the culture media are considered in the article.\n\nThe solubility of CO2 is limited by the state of saturation in accordance	2018-04-10	808	https://doi.org/10.15673/fst.v12i1.846	MASS TRANSFER IN FERMENTATION PROCESSES	5
809	Стаття	Removing lactose from buttermilk and other dairy products is a topical problem, as there is a significant increase in morbidity rates due to lactose intolerance. In many cases, milk and dairy products containing lactose can not be completely exclude	2018-04-10	809	https://doi.org/10.15673/fst.v12i1.839	ANALYSIS OF A NEW DIAFILTRATION METHOD OF CLEANING BUTTERMILK FROM LACTOSE WITH MINERAL COMPOSITION PRESERVED	5
810	Стаття	Today, the publicity and the scientific community, businessmen and officials pay much attention to the food security problem. However, despite this, it is not solved. This problem has even become global. An analysis of the existing approaches to the	2018-04-10	810	https://doi.org/10.15673/fst.v12i1.845	FOOD MARKETS AND FOOD SECURITY: SCIENTIFIC BASIS  OF FORMATION	5
811	Стаття	The analysis and comparative description are carried out of varieties of brewing barley light malt and type 90 hops from domestic and foreign producers, as the main plant raw material that forms the quality of beer. The quality indexes of malt sampl	2018-04-10	811	https://doi.org/10.15673/fst.v12i1.844	BASIC INGREDIENTS AND THEIR ANALYSIS DURING THE FORMATION OF BEER QUALITY	5
812	Стаття	This article presents the results of studies of the properties of marmalade with natural plant cryoadditives during storage for 3 months (90 days). To improve the organoleptic characteristics and antioxidant properties of marmalade, plant additives o	2018-04-10	812	https://doi.org/10.15673/fst.v12i1.843	INVESTIGATION OF THE PROPERTIES OF MARMALADE  WITH PLANT CRYOADDITIVES DURING STORAGE	5
815	Стаття	Aerobic composting is one of the best available technologies for an integrated waste management system in terms of minimizing the anthropogenic impact on the environment, complying with the latest domestic and foreign developments, economic and prac	2018-04-10	815	https://doi.org/10.15673/fst.v12i1.842	COMPOSTING OF ORGANIC WASTE WITH THE USE OF MINERAL ADDITIVES	5
816	Стаття	Color characteristics of compositions of three-component fruit and berry pastes before and after infrared drying are determined. The compositions were prepared on the basis of apples, cranberries, and hawthorn with increased nutrition value and ther	2018-04-10	816	https://doi.org/10.15673/fst.v12i1.840	COLOR CHARACTERISTICS OF DRIED THREE-COMPONENT FRUIT AND BERRY PASTES	5
817	Стаття	In the work, various technological methods are presented of preliminary processing of celery and parsnip roots to prevent their darkening during cooking in restaurants. These methods are: immersing in a citric acid solution (c = 0.05 %, 0.1 %, 0.15 	2018-04-10	817	https://doi.org/10.15673/fst.v12i1.838	EFFECT OF PRE-TREATMENT ON QUALITATIVE INDICES OF WHITE ROOTS	5
818	Стаття	Because of fishes Sparidentex hasta and Pampus argenteus in the southern of Iran are consumed abundant in a particular season and it should be frozen for consumption throughout the year. Therefore, this research was carried out to investigate the ef	2018-04-10	818	https://doi.org/10.15673/fst.v12i1.835	COMPARATIVE STUDIES ON EFFECTS OF FREEZING ON PHYSICOCHEMICAL PROPERTIES OF FILLETS TWO FISH SPECIES IN IRAN	5
819	Стаття	The possibility of muropeptides obtaining of peptidoglycans of Lactobacillus delbrueckii subsp. Bulgaricus B-3964 cell walls by the combination of the use of autolytic processes and enzyme treatment of biomass with the participation of lysozyme and	2018-04-10	819	https://doi.org/10.15673/fst.v12i1.885	OBTAINING AND CHARACTERISTIC OF MUROPEPTIDES OF  PROBIOTIC CULTURES CELL WALLS	5
820	Стаття	The expediency of optimization of starter cultures composition of mixed cultures Lactococcus sp. and mixed cultures Bifidobacterium bifidum BB 01 + Bifidobacterium longum BL 01 + Bifidobacterium breve BR 01 for the manufacture of fermented milk prod	2018-04-10	820	https://doi.org/10.15673/fst.v12i1.836	STARTER CULTURES COMPOSITIONS WITH PROBIOTICS  FOR FERMENTED MILK PRODUCTS AND COSMETICS	5
821	Стаття	Basing on the survey of respondents, a marketing research was carried out on military service people’s consumer motivations and benefits for the existing dry product package and ways to improve it, as well as on the attitude towards the consumption o	2018-04-10	821	https://doi.org/10.15673/fst.v12i1.834	THE MARKETING RESEARCH OF MILITARY SERVICE PEOPLE’S CONSUMER PREFERENCES OF DRY PRODUCT PACKAGES AND WAYS OF THEIR IMPROVEMENT	5
822	Стаття	Thе аrtісlе prеsеnts the dаtа оn thе rеlеvаnсе оf conducting sсіеntіfіс rеsеаrсh оn thе оrgаnіс prоduсtіоn іn Ukrаіnе аnd іts rоlе іn еnsurіng еnvіrоnmеntаl sаfеty in the food industry. The аnаlysіs оf оrgаnіс аgrісulturаl prоduсtіоn іn thе wоrld аnd	2017-12-18	822	https://doi.org/10.15673/fst.v11i4.736	Thе оrgаnіс prоduсtіоn іn thе соntеxt оf іmprоvіng thе есоlоgісаl safety оf prоduсtіоn оf the fооd іndustry	5
823	Стаття	In the presented article, based on the detailed analysis of scientific sources and many years of own experience in production of the probiotic foods, the definition of “probiotics” in cosmetics, as well as the definition of “living” and “probiotic”	2017-12-18	823	https://doi.org/10.15673/fst.v11i4.735	“Lving” and “probiotic” cosmetics: modern view and defenitions	5
824	Стаття	In the article a comparative analysis of the use of the bacterial preparation Herobacterin and the starter RSF-742 (Chr. Hansen, Denmark) in the technology of brine cheese was conducted. Herobacterin is a bacterial preparation created using bacteria	2017-12-18	824	https://doi.org/10.15673/fst.v11i4.734	The use of bacconcentrate Herobacterin in brine cheese technology	5
825	Стаття	An important intervention in the composition of food products is enrichment of food with micronutrients. In this regard, the authors investigated how the additive with the corresponding trace element will be distributed in the food product, and in t	2017-12-18	825	https://doi.org/10.15673/fst.v11i4.733	Study of regularities of distributing powdered dietetic additives in coarse dispersed foodstuffs	5
826	Стаття	У статті представлено результати з визначення рівня мікробної контамінації м’яса забійних тварин та птиці в процесі його технологічної переробки. Визначено, що кількість МАФАнМ та бактерій родини Enterobacteriaceae на поверхні туш яловичих варіює пр	2017-12-18	826	https://doi.org/10.15673/fst.v11i4.732	Контамінація м’яса тварин і птиці та засоби її зниження	5
827	Стаття	In this article the technological properties of milk whey, enriched with magnesium and manganese particles by electrical discharge dispersion of metal granules in the medium, and the effect of whey on the technological process and quality of bakery	2017-12-18	827	https://doi.org/10.15673/fst.v11i4.731	The prospects of using milk whey enriched with Mg and Mn in the technology of bakery products	5
828	Стаття	The study reveals the results of evaluating the effectiveness of the state control system (supervision) on the safety and individual indicators of the quality of livestock products in Ukraine. The necessity of application of such components of effic	2017-12-18	828	https://doi.org/10.15673/fst.v11i4.730	Efficiency of the functioning of the state control system for the safety and quality of animal products in Ukraine	5
829	Стаття	The influence of heat treatment with antioxidant compositions on the content of biologically active substances during storage of cucumbers is investigated. It was found that the use of the proposed treatment inhibits the activity of ascorbate oxidas	2017-12-18	829	https://doi.org/10.15673/fst.v11i4.729	The influence of antioxidant postharvest treatment on content of biologically active substances during storage of cucumbers	5
830	Стаття	Recently, the traditional formulations of essential food products are actively including malt – a valuable dietary product rich in extractives and hydrolytic enzymes, obtained by germination in artificially created conditions. Containing a full set o	2017-12-18	830	https://doi.org/10.15673/fst.v11i4.728	Features of obtaining malt with use of aqueous solutions of organic acids	5
831	Стаття	The production of candied fruits is a priority development area of the food industry. The basic process in candied fruits production is diffusion of sugar syrup into vegetable raw material. Kinetics of the diffusion processes depends on sucrose conc	2017-12-18	831	https://doi.org/10.15673/fst.v11i4.727	Study of diffusion processes in pumpkin particles during candied fruits production	5
861	Стаття	The information about problems and prospects of development of food production processes based on high-tech and knowledge-intensive technical solutions is presented. To accomplish these objectives the problems of rational growing of grapes, intensiv	2017-04-05	861	https://doi.org/10.15673/fst.v11i1.302	High-tech processing of secondary resources of winemaking	5
832	Стаття	The article summarizes data concerning the biological activity of the promising herbal raw material: aerial part of goutweed (Aegopodium podagraria L., Apiaceae). This plant since time immemorial has been used as vegetable and fodder plant as well a	2017-12-18	832	https://doi.org/10.15673/fst.v11i4.726	Goutweed (Aegopodium podagraria L.) biological activity and the possibilities of its use for the correction of the lipid metabolism disorders	5
833	Стаття	Influence of magnetic field on water has been described in the paper. The patented device constructed on the basis of a stator of three-phase asynchronous motor has been used for processing of water in the experiments.\n\nIt has been found that the wa	2017-12-18	833	https://doi.org/10.15673/fst.v11i4.725	Influence of the unfrozen magnetized water on juices	5
834	Стаття	В работе рассмотрены и выполнены расчетно-теоретические исследования характеристик линейного асинхронного двигателя (ЛАД) в зависимости от основных технических и конструктивных параметров пакетоформирующих машин. Объектом исследования в работе являе	2017-10-05	834	https://doi.org/10.15673/fst.v11i3.614	ИССЛЕДОВАНИЕ ЕЛЕКТРОПРИВОДА С ЛИНЕЙНЫМ  ДВИГАТЕЛЕМ ДЛЯ ПАКЕТОФОРМИРУЮЩИХ МАШИН	5
835	Стаття	Changes in the quality indicators of sour-milk infant drink «Biolakt» characterized by high probiotic and immunomodulatory properties and low allergic effect that were made according to the improved technology and stored in sealed-off containers at	2017-10-05	835	https://doi.org/10.15673/fst.v11i3.613	SUBSTANTIATION OF STORAGE PARAMETERS OF THE SOUR-MILK INFANT DRINK «BIOLAKT»	5
836	Стаття	Potential pathogens of foodborne toxic infections – bacterial contaminants Bacillus cereus isolated from plant raw materials and food products from the Ukrainian region were investigated. When determining of the proportion of isolated bacilli from th	2017-10-05	836	https://doi.org/10.15673/fst.v11i3.612	Toxin production ability of Bacillus cereus strains from food product of Ukraine	5
837	Стаття	Corrosion of metal canning containers is one of the obstacles in spreading its application for packing of food. Particularly aggressive to the metal container is fruit canned medium, containing organic acids.\n\nThe basic material for the production o	2017-10-05	837	https://doi.org/10.15673/fst.v11i3.611	RESEARCH OF FRUIT CONSERVES’ CORROSIVE AGGRESSIVENESS	5
838	Стаття	The article shows the necessity of healthy foods development and introduction into population`s food ration, which are enriched with scarce micronutrients, especially with iodine, to strengthen health and prevent diseases. There is a review of Lamin	2017-10-05	838	https://doi.org/10.15673/fst.v11i3.610	FROZEN PRE-COOKED SEMI-PRODUCTS WITH IODINE-CONTAINING STUFFING	5
839	Стаття	In work it is considered conditions of preparation of a core of the Walnut for the following use as a prescription component of soft drinks of improvement. It is provided the analysis of patent and literary source in which are explained the existing	2017-10-05	839	https://doi.org/10.15673/fst.v11i3.609	PREPARATION OF THE CORE OF WALNUT FOR USE IN THE COMPOSITION OF SOFT DRINKS	5
840	Стаття	Досліджено жирнокислотний склад ліпідів сухих рибо-рослинних напівфабрикатів на основі фаршів з бичка азово-чорноморського та суміші рослинних інгредієнтів (шротів насіння льону, висівок пшеничних, вівсяних та житніх), вивчено показники їх біологічн	2017-10-05	840	https://doi.org/10.15673/fst.v11i3.608	ДОСЛІДЖЕННЯ ЖИРНОКИСЛОТНОГО СКЛАДУ ЛІПІДІВ СУХИХ РИБО-РОСЛИННИХ НАПІВФАБРИКАТІВ	5
841	Стаття	У статті проведено аналіз літературних джерел та проведених власних досліджень щодо показників біологічної цінності прісноводної риби Кременчуцького водосховища. Показано доцільність виористання цієї сировини, для розширення асортименту біологічно ці	2017-10-05	841	https://doi.org/10.15673/fst.v11i3.607	БІОЛОГІЧНА ЦІННІСТЬ ПРІСНОВОДНОЇ РИБИ КРЕМЕНЧУЦЬКОГО ВОДОСХОВИЩА	5
842	Стаття	The current study is a review of characteristics, production, physiological properties and application of xylooligosaccharides (XOS). XOS are the carbohydrates, their molecules are built from xylose residues linked mainly by в-(1→4)-glycoside bonds.	2017-10-05	842	https://doi.org/10.15673/fst.v11i3.606	XYLOOLIGOSACCHARIDES FROM AGRICULTURAL BY-PRODUCTS: CHARACTERISATION, PRODUCTION AND PHYSIOLOGICAL EFFECTS	5
843	Стаття	Expediency of development of recipes and innovative biotechnologies for combined milk-vegetational products with balanced chemical composition, strengthened probiotic properties and extended shelf life was proven in field of establishing proper diet	2017-10-05	843	https://doi.org/10.15673/fst.v11i3.605	INNOVATIVE SOLUTIONS IN BIOTECHNOLOGIES OF COMBINED YOGURT DRINKS WITH BALANCED CHEMICAL CONTENTS	5
844	Стаття	β-галактозидазна активність є одним з критеріїв відбору штамів до складу бактеріальних препаратів для кисломолочних продуктів спеціального призначення. Саме цей фермент є ключовим у розщепленні лактози молока мікроорганізмами закваски. Одним з важли	2017-10-05	844	https://doi.org/10.15673/fst.v11i3.604	β- ГАЛАКТОЗИДАЗНА АКТИВНІСТЬ БАКТЕРІЙ, ЯК КРИТЕРІЙ ВІДБОРУ ШТАМІВ ДО СКЛАДУ БАКТЕРІАЛЬНИХ ПРЕПАРАТІВ	5
845	Стаття	The specific understanding of food philosophy according to the facts of development of cooking technologies and growth rate of food range is given. As it has been proven by historical stages of production of flavorings, aroma is one of the important	2017-10-05	845	https://doi.org/10.15673/fst.v11i3.603	STUDY OF FACTORS AFFECTING DEVELOPMENT OF FOOD AROMATIZATION	5
846	Стаття	The article to determine peculiarities of macromolecule deformation behavior under conditions of a jet-shaping head that would allow to solve the issue related to the mechanism of increasing water-jet cutting power with polymer additions. In converg	2017-06-12	846	https://doi.org/10.15673/fst.v11i2.517	Mechanism of the high efficiency of the cutting frozen food products using water-jet with polymer additions	5
928	Стаття	One of the promising ways in environmentalizing marine internal combustion engines is the neutralization of harmful substances in exhaust gases through particular gas recirculation (EGR-technology). However, the use of such techniques conflicts with	2019-06-10	928	https://doi.org/10.15673/ret.v55i1.1346	Using the heat of recirculation gases of the ship main engine by an ejector refrigeration machine for intake air cooling	7
847	Стаття	Досліджено дисперсний склад овочевого та фруктового напівфабрикату, як основної складової частини для виробництва напою смузі. Завдяки отриманим диференціальним та інтегральним кривим встановлено ступінь подрібнення заморожених напівфабрикатів для с	2017-06-12	847	https://doi.org/10.15673/fst.v11i2.516	Дослідження дисперсного складу овочевого та фруктового напівфабрикатів як основної складової частини для напою смузі	5
848	Стаття	Наведено характеристику, основні властивості, біологічну дію Bacillus cereus і перелік деяких харчових продуктів, які найчастіше можуть бути контаміновані цими мікроорганізмами. Охарактеризовано класичні та сучасні методи визначення Bacillus cereus.	2017-06-12	848	https://doi.org/10.15673/fst.v11i2.515	Bacillus cereus: характеристика, біологічна дія, особливості визначення в харчових продуктах	5
849	Стаття	In order to develop methods for preserving fruit and berry syrup, which exclude the use of high-temperature sterilization and preservatives, the survival of spores of micromycetes (B. nivea molds) in model media with different concentration of food	2017-06-12	849	https://doi.org/10.15673/fst.v11i2.514	Modelling of the process of micromycetus survival in fruit and berry syrups	5
850	Стаття	У статті проведено огляд найважливіших факторів, які обумовлюють якість готових томатних продуктів, а саме: стиглість томатів, місцевість вирощування, клімат і технологічні умови переробки, застосування нововведень у полі та нових технологій у вироб	2017-06-12	850	https://doi.org/10.15673/fst.v11i2.513	Аналіз сучасних методів переробки томатів	5
851	Стаття	Physicochemical and biochemical indices, which characterize quality of white wine grape varieties Zagrey and Aromatnyi of selection of NNC «IV&amp;W named after V. Ye. Tairov», (harvest of 2016) were determined. The field trial which includes variou	2017-06-12	851	https://doi.org/10.15673/fst.v11i2.512	Quality parameters of wine grape varieties under the influence of different vine spacing and training systems	5
852	Стаття	The article presents the results of the ascorbic acid (AA) determination with using a complex of an Tb (III) ion with ciprofloxacin (CF) as a lanthanide luminescent marker. The luminescent properties of the Tb (III)-CF complex in the presence of AA w	2017-06-12	852	https://doi.org/10.15673/fst.v11i2.511	Luminescent determination of ascorbic acid in dietary supplements	5
853	Стаття	Досліджено термодинамічні властивості крохмалів фізичної модифікації із воскової кукурудзи «Primа» і тапіокові «Endura», «Indulge». Висвітлено сучасний стан виробництва та споживання соусів солодких. Однією з вимог до якості соусів солодких є стабіл	2017-06-12	853	https://doi.org/10.15673/fst.v11i2.510	Дослідження термодинамічних властивостей крохмалів фізичної модифікації при виробництві соусів солодких	5
854	Стаття	The article describes the role of selenium in the humankind being. The analysis based on the published data shows that the biological synthesis is a perspective way to obtain an organic form of selenium, which can be used in dietary supplements. The	2017-06-12	854	https://doi.org/10.15673/fst.v11i2.509	Dietary supplements based on selenium containing culture of lactic acid bacteria	5
855	Стаття	Тhe practical value of the culture liquid of probiotic bacteria was demonstrated. The culture fluid contains the products of vital activity of probiotic bacteria. It is the product of waste in the manufacture of classical probiotics. The culture liq	2017-06-12	855	https://doi.org/10.15673/fst.v11i2.508	Investigation of the antagonistic activity of secondary metabolites of propionic acid bacteria	5
856	Стаття	The artificial methods of must concentration were discussed in current study: the microwave vacuum dehydration, reverse osmosis and cryoextraction. The main factor of using of alternative ways is deficiently low temperatures in winter period that ar	2017-06-12	856	https://doi.org/10.15673/fst.v11i2.507	Analysis of alternative methods and price politic of icewine production	5
857	Стаття	This article presents the results of the study of literary sources to prove the viability of the idea of using sweet whey to deep its fractionation, and to obtain biologically active proteins with immunomodulatory effect. We demonstrated methods for	2017-06-12	857	https://doi.org/10.15673/fst.v11i2.506	Sweet whey as a raw material for the dietary supplements obtaining with immunomodulatory effect	5
858	Стаття	У статті узагальнено сучасні явлення про роль казеїну в технологічних процесах перероблення молока, розглянуто фізико-хімічні, хімічні та ферментативні способи модифікації казеїну, висвітлено взаємозв’язок між способами модифікації казеїну та його ф	2017-04-05	858	https://doi.org/10.15673/fst.v11i1.305	Модифікація структури та функціонально-технологічних властивостей казеїну: наукові та прикладні аспекти	5
859	Стаття	E статті виконано дослідження процесу переробки холодним способом слив сортів «Угорка домашня» та «Угорка італійська» з використанням перфорованих оболонок в полі відцентрових сил з метою відокремлення запасаючих тканин (м’якоті) від кісточок. В яко	2017-04-05	859	https://doi.org/10.15673/fst.v11i1.304	Дослідження процесу переробки холодним способом плодів кісточкових культур	5
860	Стаття	Expediency of the development of formulae and innovative technologies for production of prophylactic application drinks possessing antioxidant, probiotic and hepatoprotective properties with the use of the secondary dairy product – whey, as well as	2017-04-05	860	https://doi.org/10.15673/fst.v11i1.303	Modelling formulae of strawberry whey drinks of prophylactic application	5
862	Стаття	У статті обґрунтовано доцільність використання вакуумних полімерних матеріалів в технології Sous-Vide при приготуванні страв для військовослужбовців, туристів, експедиторів. Із метою дослідження вакуумних упаковок проведено детальний аналіз літерату	2017-04-05	862	https://doi.org/10.15673/fst.v11i1.301	Використання полімерних комбінованих плівок у технології sous-vide	5
863	Стаття	The expediency of using the profile method of analysis for assessing the influence of technological factors on the quality of beer has been established. The characteristics for the evaluation of beer quality by the profile method are chosen. The res	2017-04-05	863	https://doi.org/10.15673/fst.v11i1.298	Using the profile method for evaluationthe beer quality	5
864	Стаття	The problem of microelements bioavailability is highlighted and the correct ways of its solution are substantiated as a result of generalization of theoretical aspects of obtaining of the biometals chelate forms. The characteristics of the main bioge	2017-04-05	864	https://doi.org/10.15673/fst.v11i1.297	Chelate forms of biometalls. Theoretical aspects of obtaining and characteristics	5
865	Стаття	The article presents data on the positive impact of essential microelement selenium on the human body. It was characterized the ability to accumulate inorganic forms of selenium (such as selenites and selenates) into the organic forms by probiotic m	2017-04-05	865	https://doi.org/10.15673/fst.v11i1.296	Technology of production biological active additive based on selenium containing culture of bifidobacterium	5
866	Стаття	In the article there are considered questions of the sweet foods with a high nutritional value development. Evaluation of the organoleptic and physical-chemical properties of model jelly samples with jost and spirulina showed that the proposed formu	2017-04-05	866	https://doi.org/10.15673/fst.v11i1.294	Desserts with a high nutritional value in the industry employees nutrition	5
867	Стаття	For the purpose of improvement of the Ukrainian nutritional standards this Article provides comparative analysis of field rations of different countries worldwide to make a proposal on improvement of food-stuff assortment in food ration for military	2017-04-05	867	https://doi.org/10.15673/fst.v11i1.293	Comparative analysis of field ration for military personnel of the ukrainian army and armies of other countries worldwide	5
868	Стаття	The mathematical toolkit created and used for the design of durable nutrition systems aimed at the prevention and therapy of the diseases caused by calcium deficiency is analyzed. In particular, these are: the complex of mathematical models of the e	2017-04-05	868	https://doi.org/10.15673/fst.v11i1.291	Mathematical aspects of nutrition systems projecting for dietary therapy	5
869	Стаття	The comparative analysis of the micronutrient diet compositions of the patients with type II diabetes and healthy people were held. It was found that in a diet it is necessary to enrich the following micronutrients: B vitamins, biotin, vitamin A, E,	2017-04-05	869	https://doi.org/10.15673/fst.v11i1.290	Сomparison of the quality micronutrient compound of recommended daily intakes and the second type diabetes patients’ diet	5
870	Стаття	In this article there is analysis of condition of stone fruit crops in fresh during their rotative movement on immobile perforated surface of cylindrical coating under field of centrifugal forces aimed at division onto semi-product (flesh) and waste	2016-12-26	870	https://doi.org/10.15673/fst.v10i4.257	Сondition analysis of stone fruit crops during their processing on perforated surface under centrifugal forces	5
871	Стаття	Проблема формування хімічного складу та біоценозів підземних вод досі є однією з найбільш складних проблем теоретичної гідрогеології. Найбільший інтерес представляють такі процеси, як зміни фізико-хімічного складу та мікробіологічного стану підземни	2016-12-26	871	https://doi.org/10.15673/fst.v10i4.256	Моніторинг безпечності та якості природної мінеральної води свердловини № 14/7832 м. Одеса	5
872	Стаття	This work is dedicated to the substantiation of development of technology of fruit and vegetable mousses using wheat starch and surfactant – Tween 20. The innovative idea of product with foamy structure was expounded, the implementation of which wil	2016-12-26	872	https://doi.org/10.15673/fst.v10i4.255	The substantiation of development of mousses technology using wheat starch	5
873	Стаття	У статті наведено результати досліджень використання в пряниках нетрадиційних рецептурних компонентів: кедрового, кунжутного борошна та борошна з коріння гірчака зміїного. Проведено дослідження динаміки зміни фізико-хімічних, структурно-механічних,	2016-12-26	873	https://doi.org/10.15673/fst.v10i4.254	Зміна якісних характеристик пряників під час зберігання	5
874	Стаття	For the recreational zone located in the Odessa region along the coast of the Black Sea it is expedient to use (as an additional source of water supply) the water received from air. It is shown that it is possible to receive water from air by means o	2016-12-26	874	https://doi.org/10.15673/fst.v10i4.253	Quality of the water received from air by means of conditioners	5
875	Стаття	This article shows the feasibility of using waxy wheat flour, the starch of which doesn`t contain amylose, in order to stabilize the quality of yeast-containing cakes. The influence of the waxy wheat flour mass fraction and the stage of its adding on	2016-12-26	875	https://doi.org/10.15673/fst.v10i4.252	Technological characteristics of yeast-containing cakes production using waxy wheat flour	5
876	Стаття	The article is devoted to research of functional and technological properties of powders from banana, carrots, strawberry, apple, spinach and orange received by cold spray drying. Expediency of vegetable and fruit powders use in the confectionery in	2016-12-26	876	https://doi.org/10.15673/fst.v10i4.251	Study of functional and technological properties of plant powders for use in confectionery industry	5
877	Стаття	The article is based on research of the protein components of different nature analysis. The possibility of their use as components of protein and fat emulsions for the purpose of modeling their optimal formulations for use in the composition of mea	2016-12-26	877	https://doi.org/10.15673/fst.v10i4.250	Development of formulation multicomponent protein-fat emulsion	5
1090	Стаття	The use of cold accumulators based on the principle of ice build up on the cooled surfaces during off-peak periods and ice melting during on-peak periods is an effective method of electricity bills reduction. Within comparatively short periods of on-	2016-08-09	1090	https://doi.org/10.15673/ret.v52i3.117	A STUDY INTO ICE BUILD-UP AND MELTING ON VERTICAL COOLED PIPES	7
878	Стаття	У статті обґрунтовано доцільність використання крупи пшоно у виробництві хлібобулочних виробів. Наведено результати розробки рецептурного складу нового виду хліба із пшеничного борошна з додаванням пшона, попередньо відвареного до напівготовності. І	2016-12-26	878	https://doi.org/10.15673/fst.v10i4.249	Використання пшона у виробництві хліба оздоровчого призначення	5
879	Стаття	The publication presents data on the effect of polysaccharides as cryoprotectants on changes of the lipid fraction of quick-frozen semi-finished products during storage. Since the structure of minced systems is formed as a result of the destruction o	2016-12-26	879	https://doi.org/10.15673/fst.v10i4.248	Study of cryoprotectors effect on oxidation processes at storage of frozen halffinished products	5
880	Стаття	The article presents experimental study on the feasibility of using edible films (in the coating) as a means of preventing staling and method of increasing the biological value of gingerbread products. Grounded components of edible coating. Based on	2016-12-26	880	https://doi.org/10.15673/fst.v10i4.247	Edible coating as factor of preserving freshness and increasing biological value of gingerbread cakes	5
881	Стаття	Annotation. This article presents the analysis of marketing environment of the enterprises that produce yogurt products in Ukraine. In order to carry out a deeper analysis of the marketing environment of the new yoghurt drinks with a balanced compos	2016-12-26	881	https://doi.org/10.15673/fst.v10i4.246	Marketing research in positioning and launching of yoghurt with a balanced chemical composition	5
882	Стаття	The constant selling race results in need for improving the quality of nutrition products among in-house food and pharmaceutical processing industries, which is an all-important key to success on the consumer market. This requires constant improvemen	2016-12-26	882	https://doi.org/10.15673/fst.v10i4.187	THE RESEARCH OF THE AMOUNT OF HEAVY METALS AND NITROSO COMPOUNDS IN CONCENTRATED TOMATO PRODUCTS	5
883	Стаття	Питання стосується процесу переробки дрібноплідних плодів кісточкових культур (вишні, дрібноплідна алича, кизил, черешні) в свіжому стані на перфорованій поверхні в полі відцентрових сил в режимі безперервної дії з метою їх розділення на складові: н	2016-09-08	883	https://doi.org/10.15673/fst.v10i3.185	Теоретичне обґрунтування процесу  переробки плодів кісточкових культур	5
884	Стаття	У статті наведені дані щодо актуальності проведення наукових досліджень рибних ресурсів Кременчуцького водосховища. Проведений аналіз споживання та вилову рибної продукції в Україні. Встановлено, що підвищення рівня забезпечення населення України ри	2016-09-08	884	https://doi.org/10.15673/fst.v10i3.184	ЩОДО ЕКОЛОГІЧНОЇ БЕЗПЕЧНОСТІ РИБНИХ РЕСУРСІВ  КРЕМЕНЧУЦЬКОГО ВОДОСХОВИЩА	5
885	Стаття	Проведено исследование  фенольного и липидного состава вторичных ресурсов экологически чистой сосны (Pinus Sylvestris) (sosnowskyi), распространённой на охраняемой территории Тушети (регион северо-восточной части Грузии), в частности, коры, древесны	2016-09-08	885	https://doi.org/10.15673/fst.v10i3.186	НЕКОТОРЫЕ ХИМИЧЕСКИЕ КОМПОНЕНТЫ СОСНЫ	5
886	Стаття	У статті представлена порівняльна оцінка хімічного складу шроту насіння льону та пшеничного борошна, вплив шроту на якість хліба у разі включення його до рецептури. Відзначено, що введення до рецептури хлібобулочних виробів шроту насіння льону дозво	2016-09-08	886	https://doi.org/10.15673/fst.v10i3.183	ШРОТ НАСІННЯ ЛЬОНУ В ТЕХНОЛОГІЇ ХЛІБОБУЛОЧНИХ ВИРОБІВ	5
887	Стаття	Быстрозамороженные полуфабрикаты пользуются спросом у населения из-за удобства использования, отсутствия консервантов и возможности длительного хранения в домашних условиях. Основной проблемой в сфере их производства и реализации является снижение к	2016-09-08	887	https://doi.org/10.15673/fst.v10i3.182	ВЛИЯНИЕ ПРИРОДНЫХ ПОЛИСАХАРИДОВ НА КАЧЕСТВЕННЫЕ ПОКАЗАТЕЛИ ЗАМОРОЖЕННЫХ ПОЛУФАБРИКАТОВ ПРИ ХРАНЕНИИ	5
888	Стаття	статті наведено можливі варіанти використання яловичого колагенового білка «Білкозин» в поєд-\nнанні з харчовими полісахаридами для отримання ковбасних виробів високої якості. Раціональним обрано співвідно-\nшення для гідратації композиційних білоквмі	2016-09-08	888	https://doi.org/10.15673/fst.v10i3.181	ВПЛИВ БІЛОКВМІСНИХ КОМПОЗИЦІЙ НА ОСНОВІ КОЛАГЕНУ НА ЯКІСТЬ КОВБАСНІХ ВИРОБІВ	5
889	Стаття	Отримано комплекс β-циклодекстрину з йодом, який був використаний в якості добавки для збага-\nчення йодом м’ясних сосисок.\nДосліджено можливість утворення 3,5-дийодтирозину внаслідок взаємодії між L-тирозином та отриманим ком-\nплексом за допомогою ме	2016-09-08	889	https://doi.org/10.15673/fst.v10i3.180	Використання комплексу β- циклодектрину з йодом при виробництві варених ковбасних виробів	5
890	Стаття	Досліджено ефективність застосування водорозчинних вітамінів групи В при зброджуванні пивного сусла дріжджами низового бродіння штаму Saflager W-34/70 в умовах високогустинного пивоваріння. Вітаміни, будучи коферментами зимазних ферментів, забезпечу	2016-09-08	890	https://doi.org/10.15673/fst.v10i3.179	ІНТЕНСИФІКАЦІЯ ЗБРОДЖУВАННЯ ВИСОКОГУСТИННОГО ПИВНОГО СУСЛА ЗА УЧАСТЮ ВІТАМІНІВ	5
891	Стаття	 \n\nВ качестве люминесцентного сенсора для определения метилпарабена предложено использовать комплекс тербий (III) - 2,2' –дипиридил. Изучены люминесцентные свойства комплекса иона Tb(III) с 2,2'-дипиридилом и метилпарабеном в твёрдом слое сорбента: с	2016-09-08	891	https://doi.org/10.15673/fst.v10i3.178	ОПРЕДЕЛЕНИЕ МЕТИЛПАРАБЕНА В КОСМЕТИЧЕСКИХ СРЕДСТВАХ С ИСПОЛЬЗОВАНИЕМ ЛЮМИНЕСЦЕНТНОГО СЕНСОРА Tb(III) - 2,2' -ДИПИРИДИЛ	5
892	Стаття	Досліджено вплив бактеріального препарату «Лакмік» на формування якісних характеристик суцільном’язових продуктів з яловичини. Встановлено, що застосування бактеріального препарату на основі молочнокислих бактерій дає змогу цілеспрямовано впливати н	2016-09-08	892	https://doi.org/10.15673/fst.v10i3.177	БАКТЕРІАЛЬНІ ПРЕПАРАТИ У ТЕХНОЛОГІЇ СУЦІЛЬНОМ’ЯЗОВИХ СИРОКОПЧЕНИХ ПРОДУКТІВ З ЯЛОВИЧИНИ	5
893	Стаття	The studies referred to in this article showed the principle possibility of use of hydrolytic enzymatic agent\nwith α-D-galactosidase activity for the enzymatic hydrolysis of soy oligosaccharides. Optimal parameters of the enzyme activity\nwere determ	2016-09-08	893	https://doi.org/10.15673/fst.v10i3.176	BIOTECHNOLOGY OF OBTAINING A HYDROLYTIC ENZYMATIC AGENT WITH α-D- GALACTOSIDASE ACTIVITY	5
894	Стаття	It is shown that microorganisms are an integral element of the mаcroorganism immune system.\nPeptidoglycan, muramyldypeptyd, teichoic acids are structural components of cell walls of microorganisms. These components\nare an object for recognition of th	2016-09-08	894	https://doi.org/10.15673/fst.v10i3.175	Immunological properties of the bacterial origin compounds	5
895	Стаття	The article states that the development of insulin resistance is influenced by many parameters, however, one of the first is the increased weight. The main parameter that characterizes the degree of obesity is the body mass index. There is a direct	2016-09-08	895	https://doi.org/10.15673/fst.v10i3.174	QUALITY MACRONUTRIENT DIET СOMPARISON OF THE RECOMMENDED DAILY INTAKE DIABETES TYPE II PATIENTS AND HEALTHY PERSONS	5
896	Стаття	я. У статті досліджено робочий процес пластифікації кондитерських мас у пластифікаторі ВВ-ПМЛ.\nРозглянуто реологічну модель руйнування кондитерських блоків під дією динамічного навантаження у маслорізці\nпластифікатора ВВ-ПМЛ у вигляді диференціально	2016-08-26	896	https://doi.org/10.15673/fst.v10i2.159	МОДЕЛЮВАННЯ І ОБҐРУНТУВАННЯ РОБОЧОГО ПРОЦЕСУ ПЛАСТИФІКАТОРА ВВ-ПМЛ	5
897	Стаття	У статті представлено огляд літератури та експериментальні дослідження, що стосуються процесу\nпервинної переробки плодів кісточкових культур на прикладі абрикосу сорту «Домашній» у свіжому стані (холодним\nспособом) на перфорованій поверхні в полі ві	2016-08-26	897	https://doi.org/10.15673/fst.v10i2.158	МОДЕЛЮВАННЯ ПРОЦЕСУ ПЕРЕРОБКИ ПЛОДІВ КІСТОЧКОВИХ КУЛЬТУР У СВІЖОМУ СТАНІ НА ПЕРФОРОВАНІЙ ПОВЕРХНІ В ПОЛІ ВІДЦЕНТРОВАНИХ СИЛ	5
898	Стаття	Доведено можливість використання порошку з листя волоського горіха та борошна «Здоров’я» у технології\nпісочного напівфабрикату. Введення до рецептури пісочних напівфабрикатів нетрадиційних компонентів сприяє зба-\nгаченню їхнього хімічного складу. На	2016-08-26	898	https://doi.org/10.15673/fst.v10i2.157	ТЕХНОЛОГІЯ ПІСОЧНИХ КОНДИТЕРСЬКИХ ВИРОБІВ З ПОРОШКОМ ЛИСТЯ ВОЛОСЬКОГО ГОРІХА ТА БОРОШНОМ «ЗДОРОВ’Я»	5
899	Стаття	The article analyses the candied fruit market in Ukraine and describes the main technological operations pertaining\nto processing of non-traditional candied products – celery and parsnip roots. Darkening of the roots surface caused by\nthe enzyme oxi	2016-08-26	899	https://doi.org/10.15673/fst.v10i2.156	TECHNOLOGICAL ASPECTS OF PRODUCTION OF THE CANDIED FRUITS FROM NON-TRADITIONAL RAW MATERIAL	5
900	Стаття	У роботі встановлено вплив температурного режиму обсмаження картопляних чіпсів, а також вплив\nпитомої поверхні (форми та розміру) скибочок картоплі на вміст жиру в картопляних чіпсах. Необхідну якість готово-\nго продукту можна досягти при обсмаженні	2016-08-26	900	https://doi.org/10.15673/fst.v10i2.155	ДОСЛІДЖЕННЯ ПРОЦЕСУ ОБСМАЖУВАННЯ КАРТОПЛЯНИХ ЧІПСІВ	5
901	Стаття	Розроблено технологію отримання залізовмісного комплексу на основі полісахаридів печериці дво-\nспорової, яка складається з двох стадій: вилучення полісахаридів та формування залізовмісного комплексу. Встанов-\nлено, що одержувати полісахариди з сиров	2016-08-26	901	https://doi.org/10.15673/fst.v10i2.154	ТЕХНОЛОГІЯ ОТРИМАННЯ ЗАЛІЗОВМІСНОГО КОМПЛЕКСУ НА ОСНОВІ ПОЛІСАХАРИДІВ ПЕЧЕРИЦІ ДВОСПОРОВОЇ	5
902	Стаття	В статье представлен обзор литературы и собственные экспериментальные данные, касающиеся\nвлияния молочной кислоты на качество выпечки и содержание микроэлементов в хлебобулочных изделиях после вве-\nдения в рецептуру хлебопекарных дрожжей, обогащенны	2016-08-26	902	https://doi.org/10.15673/fst.v10i2.153	ВЛИЯНИЕ МОЛОЧНОЙ КИСЛОТЫ НА КАЧЕСТВО ХЛЕБОБУЛОЧНЫХ ИЗДЕЛИЙ И ПОТЕРИ МИКРОЭЛЕМЕНТОВ ПРИ ВЫПЕКАНИИ И ХРАНЕНИИ	5
1091	Стаття	This paper presents a mathematical model of calculating the main parameters the operating cycle, rotary-vane gas refrigerating machine that affect installation, machine control and working processes occurring in it at the specified criteria. A proced	2016-08-09	1091	https://doi.org/10.15673/ret.v52i3.116	MATHEMATICAL MODEL FOR THE STUDY AND DESIGN OF A ROTARY-VANE GAS REFRIGERATION MACHINE	7
903	Стаття	У статті наведено результати досліджень процесів набухання і розчинення альгінату натрію, йота-\nкарагінану і агару у вершках з метою обґрунтування способу їх введення в емульсійно-пінну систему вершкового\nкрему. Встановлено, що під час охолодження з	2016-08-26	903	https://doi.org/10.15673/fst.v10i2.152	ДОСЛІДЖЕННЯ ПРОЦЕСУ НАБУХАННЯ ПОЛІСАХАРИДІВ ДЛЯ ВИКОРИСТАННЯ В ТЕХНОЛОГІЇ ВЕРШКОВИХ КРЕМІВ	5
904	Стаття	This article describes the influence of electrolysed water on yield and organoleptic properties of the pig\nwhole muscle meat products. The relation of desiccation during the thermal treatment depending on type of binary mixture of\nelectrolysed water	2016-08-26	904	https://doi.org/10.15673/fst.v10i2.151	THE CHANGES OF CHARACTERISTICS OF THE PORK WHOLE MUSCLE MEAT PRODUCTS WHILE USING THE ELECTROLYZED WATER	5
905	Стаття	В качестве люминесцентного сенсора для определения цитрат-ионов предложен комплекс иттрий (III) - рутин - цитрат-ион с соотношением компонентов 1:1:1. Установлены оптимальные условия образования\nразнолигандного комплекса, определены его спектрально-	2016-08-26	905	https://doi.org/10.15673/fst.v10i2.150	ОПРЕДЕЛЕНИЕ ЦИТРАТ - ИОНОВ В СЛАДКИХ БЕЗАЛКОГОЛЬНЫХ НАПИТКАХ ПО МОЛЕКУЛЯРНОЙ ЛЮМИНЕСЦЕНЦИИ РУТИНА В КОМПЛЕКСЕ С ИТТРИЕМ (III)	5
906	Стаття	Loss prevention and food quality maintenance are primarily associated with protection against the negative\nimpact of microorganisms and their metabolites during manufacture and storage. In this regard, in recent years, the issue of the\ngoods safety	2016-08-26	906	https://doi.org/10.15673/fst.v10i2.149	STUDY OF LACTIC ACID BACTERIA AS A BIO-PROTECTIVE CULTURE FOR MEAT	5
907	Стаття	У роботі встановлено ефективність використання надвисокочастотного (НВЧ) випромінювання для\nдезінтеграції дріжджів Saccharomyces cerevisiae, суспендованих в розчині натрій гідроксиду, з метою виділення полі-\nсахаридів клітинних стінок. Надано характ	2016-08-26	907	https://doi.org/10.15673/fst.v10i2.148	ВИКОРИСТАННЯ НАДВИСОКОЧАСТОТНОГО ВИПРОМІНЮВАННЯ ПРИ ВИДІЛЕННІ ПОЛІСАХАРИДІВ КЛІТИННИХ СТІНОК ДРІЖДЖІВ	5
908	Стаття	У статті наводяться результати досліджень використання шротів у технології борошняних кондитерських виробів – пісочного печива з використанням шроту олійних культур. Науково обгрунтовано і розроблено технологію борошняних кондитерських виробів з пісо	2016-06-29	908	https://doi.org/10.21691/fst.v10i1.83	ТЕХНОЛОГІЯ ТА ЯКІСТЬ ПЕЧИВА ЗІ ШРОТАМИ ОЛІЙНИХ КУЛЬТУР	5
909	Стаття	В данной статье приведены результаты исследований влияния белоксодержащего сырья: альбумина сухого и модифицированного, амарантовой муки на динамику изменений качественных характеристик выпеченных бисквитов при хранении. Определено, что замена меланж	2016-06-29	909	https://doi.org/10.21691/fst.v10i1.82	ИЗМЕНЕНИЕ ПОКАЗАТЕЛЕЙ КАЧЕСТВА БИСКВИТНЫХ ПОЛУФАБРИКАТОВ ПРИ ХРАНЕНИИ	5
910	Стаття	статті за допомогою причинно-наслідкової діаграми Ісікава проаналізовано основні чинники, що формують якість борошняних кондитерських виробів. Питання збалансованості та біологічної повноцінності мафінів вирішено шляхом розробки багатокомпонентних ре	2016-06-29	910	https://doi.org/10.21691/fst.v10i1.81	РОЗРОБКА КОМПОЗИЦІЇ БОРОШНЯНОГО КОНДИТЕРСЬКОГО ВИРОБУ «ВУПІ ПАЙ»	5
911	Стаття	Обґрунтувано класифікацію сировини рослинного походження з урахуванням чинних нормативних, термінологічних документів, принципів класифікації продукції, за якими формується статистична інформація щодо її виробництва та обігу. За розробленою схемою пр	2016-06-29	911	https://doi.org/10.21691/fst.v10i1.80	СТАТИСТИЧНИЙ АНАЛІЗ РЕЗУЛЬТАТІВ ВИЗНАЧЕННЯ ФАКТИЧНОГО ХІМІЧНОГО СКЛАДУ СІЛЬСЬКОГОСПОДАРСЬКОЇ СИРОВИНИ	5
912	Стаття	На основі аналізу існуючої світової практики розроблено склад підкислювачів для прискорення технології житніх і житньо-пшеничних виробів, що виготовляють в умовах міні-виробництв і закладів ресторанного господарства. Проведено аналіз впливу підкислю	2016-06-29	912	https://doi.org/10.21691/fst.v10i1.79	ДОСЛІДЖЕННЯ ЗМІНИ ФІЗИЧНИХ ВЛАСТИВОСТЕЙ ЖИТНЬО- ПШЕНИЧНОГО ТІСТА ПРИ ВИКОРИСТАННІ ПІДКИСЛЮВАЧІВ	5
913	Стаття	Проведено порівняння якості цукрів за наступними фізико-хімічними показниками: розчинність, глікемічний індекс, калорійність, температура плавлення, солодкість. Порівняння проводили за допомогою комплексного показника за методом, який враховує значе	2016-06-29	913	https://doi.org/10.21691/fst.v10i1.78	ТАГАТОЗА І МАЛЬТИТОЛ – ІННОВАЦІЙНА СИРОВИНА ПРИ ВИРОБНИЦТВІ ЖУВАЛЬНОЇ КАРАМЕЛІ	5
914	Стаття	С целью обогащения напитков биологически активными веществами из гибискуса китайского(Hibiscus rosa-sinensis) и лекарственных растений, проведены исследования их водных экстрактов.\nНа основе полученных водных экстрактов разработаны композиции для об	2016-06-29	914	https://doi.org/10.21691/fst.v10i1.77	ПЕРСПЕКТИВЫ ИСПОЛЬЗОВАНИЯ ЭКСТРАКТОВ ИЗ HIBISCUS ROSA-SINENSIS И ЛЕКАРСТВЕННЫХ РАСТЕНИЙ ДЛЯ ПРОИЗВОДСТВА НАПИТКОВ	5
915	Стаття	У статті обґрунтовано доцільність застосування ферментних препаратів целюлази, ксиланази та глюкозооксидази для підвищення якості полб’яного та пшеничного зернового хліба. Із використанням методів експериментально-статистичного планування та програми	2016-06-29	915	https://doi.org/10.21691/fst.v10i1.76	ОПТИМІЗАЦІЯ СКЛАДУ КОМПОЗИЦІЇ ФЕРМЕНТНИХ ПРЕПАРАТІВ ДЛЯ ПІДВИЩЕННЯ ЯКОСТІ ЗЕРНОВОГО ХЛІБА	5
916	Стаття	У статті наведено дані щодо актуальності створення нових альтернативних джерел органічних форм селену. Описано здатність мікроорганізмів до біотрансформації селену. Наведено дані стосовно впливу концентрацій натрію селеніту на приріст біомаси лакто-	2016-06-29	916	https://doi.org/10.21691/fst.v10i1.75	КУЛЬТИВУВАННЯ БІФІДО- І ЛАКТОБАКТЕРІЙ В СЕРЕДОВИЩАХ ІЗ НАТРІЮ СЕЛЕНІТОМ	5
917	Стаття	Проведено аналіз ринку соусів в Україні, наведено дані щодо структури експорту та імпорту готових соусів. Для обґрунтування доцільності розробки та впровадження нового продукту проведено маркетингові дослідження споживацьких мотивацій і переваг при	2016-06-29	917	https://doi.org/10.21691/fst.v10i1.74	МАРКЕТИНГОВІ ДОСЛІДЖЕННЯ ПРИ ПОЗИЦІОНУВАННІ ТА ВИВЕДЕННІ НА РИНОК НИЗЬКОКАЛОРІЙНОГО МАЙОНЕЗУ, ЗБАГАЧЕНОГО КОМПЛЕКСОМ СИНБІОТИКІВ	5
918	Стаття	Обґрунтовано доцільність аналізу класифікацій продуктів дитячого харчування у світі й Україні з метою розробки інноваційних технологій продуктів для харчування малюків, які були б конкурентоспроможними як на українському ринку, так і на ринку Євросою	2016-06-29	918	https://doi.org/10.21691/fst.v10i1.73	ОСОБЛИВОСТІ КЛАСИФІКАЦІЙ ПРОДУКТІВ ДИТЯЧОГО ХАРЧУВАННЯ В УКРАЇНІ ТА СВІТІ	5
919	Стаття	Встановлення строку придатності готової продукції вимагає тривалих досліджень. Використання методів моделювання у даному випадку дозволяє за короткий проміжок часу отримати необхідні дані та спрогнозувати тривалість зберігання харчового продукту. На	2016-06-29	919	https://doi.org/10.21691/fst.v10i1.72	КІНЕТИЧНА МОДЕЛЬ ЗМІНИ ЯКОСТІ НОВІТНІХ ХАРЧОВИХ ПРОДУКТІВ	5
920	Стаття	The advantages and disadvantages of Arduino controllers in relation to refrigeration automation systems are considered.  An example of using the Arduino controller for creating an automation and monitoring system for a non-standard  laboratory  refr	2019-06-10	920	https://doi.org/10.15673/ret.v55i1.1354	Advisability use of Arduino controllers in automation of refrigeration devices	7
921	Стаття	У  сучасних конденсаторах систем кондиціонування повітря, теплових насосів, випарниках систем опріснювання морської води і нагрівачах електростанцій процес конденсації пари здійснюється переважно у середині горизонтальних труб і каналів.  Процеси те	2019-06-10	921	https://doi.org/10.15673/ret.v55i1.1353	Метод розрахунку теплообміну під час конденсації холодоагентів у середині горизонтальних труб у разі стратифікованого режиму течії фаз	7
922	Стаття	Information on surface tension is necessary for modeling boiling processes in nanofluids. It was shown that the problem of predicting the surface tension of complex thermodynamic systems, such as nanofluids, remains outstanding. It should be noted t	2019-06-10	922	https://doi.org/10.15673/ret.v55i1.1352	The relationship between the surface tension and the saturated vapor pressure of model nanofluids	7
923	Стаття	The efficiency of deep cooling air at the inlet of gas turbine unite to the temperature of 10 °С by waste heat recovery combined absorption-ejector chiller was analyzed in climatic conditions at Kharkov site, Ukraine, and Beijing site, China, and co	2019-06-10	923	https://doi.org/10.15673/ret.v55i1.1351	Analyzing the efficiency of moderate and deep cooling of air at the inlet of gas turbine in various climatic conditions	7
924	Стаття	The necessity to fulfill all requirements of international organizations in the field of environmental protection, need to reduce heat loss in combustion of organic fuels, increasing economy and reliability of all elements of ship's power plant make	2019-06-10	924	https://doi.org/10.15673/ret.v55i1.1350	System for complex exhaust gas cleaning of internal combustion engine with water-fuel emulsion burning	7
925	Стаття	The efficiency of integrated cooling air at the intake of Turbocharger and Scavenge air at the inlet of working cylinders of the main diesel engine of dry-cargo ship by transforming the waste heat into a cold by an Refrigerant Ejector Chiller (ECh)	2019-06-10	925	https://doi.org/10.15673/ret.v55i1.1349	A new approach to increasing the efficiency of the ship main engine air waste heat recovery cooling system	7
926	Стаття	В даний час для вирішення проблем енергозбереження проводяться роботи з дослідження та використання малопотужних розширювальних машин для утилізаційних турбогенераторів. Перспективним є  створення  турбоагрегатів на базі відносно тихохідних вихрових	2019-06-10	926	https://doi.org/10.15673/ret.v55i1.1348	Стенд для дослідження розширювальних турбомашин малої потужності та агрегатів на їх основі	7
927	Стаття	Two-phase nozzles, in which the phase transition process takes place, can work in jet superchargers for various  purposes,  including  jet  thermal pumps (steam-water injectors) and thermal compressors. In such schemes of thermal transformers, the e	2019-06-10	927	https://doi.org/10.15673/ret.v55i1.1347	Adiabated flowing streams in nozzles: influence of regular characteristics on relaxation steam formation	7
929	Стаття	Проведено експеріментальне дослідження  теплових полів морозильного ларя з моніторингом температур по корпусі теплоізолюючих огороджень при роботі системи. Описано теплові поля ларя при пікових навантаженнях. Обґрунтовано теплові навантаження на кор	2018-12-30	929	https://doi.org/10.15673/ret.v54i6.1262	Визначення та дослідження температурних полів морозильних скринь	7
930	Стаття	У статті представлена математична модель процесу віброкипіння, яка з єдиних позицій описує структуру й поведінку віброкиплячого шару в різних умовах, дозволяє спрогнозувати поведінку віброкиплячого шару в цілому для широкого спектру впливаючих чинни	2018-12-30	930	https://doi.org/10.15673/ret.v54i6.1261	Модель віброкиплячого шару сипких середовищ та її програмна реалізація	7
1009	Стаття	Для обеспечения условия непрорывания наружного холодного воздуха в отапливаемые помещения зданий и сооружений различного назначения, решалась задача распределения полей избыточных температур во взаимодействующих струях. Для оценки эффективности работ	2017-11-19	1009	https://doi.org/10.15673/ret.v53i4.705	Оценка эффективности работы теплолокализующих устройств	7
931	Стаття	Визначено енергозберігаючі заходи підвищення енергоефективності в області кондиціювання за допомогою методів математичного моделювання схемно-технічних рішень і режимів роботи обладнання систем кондиціювання громадських об'єктів при використанні суч	2018-12-30	931	https://doi.org/10.15673/ret.v54i6.1260	Підвищення енергоефективності багатозональних VRF систем кондиціювання повітря	7
932	Стаття	Розвиток судноплавства на водних шляхах призвів до будівництва нового, сучасного флоту з потужними енергетичними установками. Масова експлуатація такого флоту супроводжується інтенсивним зростанням його впливу на навколишнє середовище. Один з найваж	2018-12-30	932	https://doi.org/10.15673/ret.v54i6.1259	Аналіз способів зменшення шкідливих викидів суднових двигунів рециркуляцією відпрацьованих газів	7
933	Стаття	Проаналізовано паливну ефективність глибокого охолодження повітря на вході газотурбінної установки (ГТУ)  при для кліматичних умов півдня України (регіон м. Одеса) та субтропічного клімату КНР (на прикладі м. Чженьцзян, провінція Цзянсу). Досліджено	2018-12-30	933	https://doi.org/10.15673/ret.v54i6.1258	Аналіз паливної ефективності глибокого охолодження повітря на вході газотурбінної установки в різних кліматичних умовах	7
934	Стаття	Розглянуто схему заміщення побутового холодильника у вигляді еквівалентного активного чотириполюсника, вхідними затискачами якого прийнято випарник, а вихідними - конденсатор.  Математичну модель холодильника як чотириполюсника розроблено у вигляді	2018-12-30	934	https://doi.org/10.15673/ret.v54i6.1257	Побутовий холодильник і його схема заміщення чотириполюсником	7
935	Стаття	Запропоновано підхід до аналізу ефективності використання встановленої (проектної) холодопродуктивності холодильних машин систем кондиціювання припливного повітря (СКПП) з урахуванням змін теплових навантажень у відповідності з поточними кліматичним	2018-12-30	935	https://doi.org/10.15673/ret.v54i6.1256	Підхід до аналізу ефективності використання встановленої холодопродуктивності систем кондиціювання припливного повітря	7
936	Стаття	В статті виконано літературний огляд досліджень пов'язаних з удосконаленням теплообмінників з повітряним охолодженням, аналіз енергетичних показників конденсаторів з повітряним охолодженням, представлені основні напрямки підвищення їх енергетичної е	2018-12-30	936	https://doi.org/10.15673/ret.v54i6.1255	Аналіз енергетичних показників конденсаторів холодильних установок з повітряним охолодженням	7
937	Стаття	Розглянуто характеристики елементів малої системи три генерації та алгоритм регулювання роботи системи в умовах тропічного клімату. Система вкючає енергетичну установку з прямім перетворенням сонячної енергії в електричную, холодильну компресорну ма	2018-12-30	937	https://doi.org/10.15673/ret.v54i6.1240	Характеристики та принципи регулювання роботи елементів малої системи тригенерації в умовах тропічного климату	7
938	Стаття	Стаття присвячена розробці імітаційних моделей процесів управління наданням інтелектуальних сервісів в NGN. Показано, що для визначення ефективності управління наданням інтелектуальних сервісів різними авторами запропонована низка аналітичних моделе	2018-12-13	938	https://doi.org/10.15673/ret.v54i3.1117	Моделювання процесів управління наданням інтелектуальних сервісів в NGN	7
939	Стаття	Вихревые трубы по эффективности уступают детандерам, но обладают рядом неоспоримых преимуществ, таких как компактность, надежность, многофункциональность. Несмотря на эти достоинства, существует совсем немного примеров эффективного применения вихрев	2018-12-13	939	https://doi.org/10.15673/ret.v54i3.1116	Применение вихревых газодинамических охладителей в технологиях извлечения редких газов	7
940	Стаття	В настоящей работе представлены результаты экспериментального исследования давления насыщенных паров растворов наночастиц Al2O3 в изопропиловом спирте. Средний размер наночастиц Al2O3, определенный методом сканирующей электронной микроскопии состави	2018-12-13	940	https://doi.org/10.15673/ret.v54i3.1115	Исследование влияния наночастиц на давление насыщенных паров изопропилового спирта	7
1010	Стаття	Представлены результаты экспериментального исследования нагрева неподвижного слоя керамзита при его контакте с движущейся воздушной средой. Получены характерные кривые изменения температур газового и твердого компонентов на входе и выходе из аппарата	2017-11-19	1010	https://doi.org/10.15673/ret.v53i4.704	Исследование теплообмена в неподвижном плотном слое гранулированного материала	7
941	Стаття	Як один із перспективних і недорогих способів інтенсифікації процесів кипіння холодоагентів у випарниках холодильних машин останнім часом розглядається введення в склад робочого тіла наночастинок. Наявні в даний час експериментальні дослідження в ці	2018-12-12	941	https://doi.org/10.15673/ret.v54i3.1111	Експериментальне дослідження коефіцієнта тепловіддачі при кипінні нанохолодоагенту R141b/наночастинки TiO2 на поверхнях з різним ступенем змочування	7
942	Стаття	Представлены результаты аналитического исследования процесса нагрева диэлектрического материала в микроволновом поле. Применяемые зависимости для расчета температур получены на основе решений математических моделей теплопроводности с учетом внутренн	2018-12-12	942	https://doi.org/10.15673/ret.v54i3.1110	Аналитическое исследование нагрева диэлектрического материала в микроволновом поле	7
943	Стаття	При переходе бытовой холодильной технике на природные рабочие тела особое место занимают холодильники с абсорбционными холодильными агрегатами (АХА). Основной недостаток абсорбционных холодильников – высокое энергопотребление. Это связано с отсутств	2018-12-12	943	https://doi.org/10.15673/ret.v54i3.1108	Моделирование режимов ручейкового безнапорного течения жидкой фазы рабочего тела в элементах абсорбционных холодильных аппаратов	7
944	Стаття	В статті розглянуто проблеми значних втрат енергії для подолання гідравлічного опору, представлені результати діагностики структури потоку при русі в елементах турбін, а також варіанти удосконалення геометрії частин потоку. Головною проблемою гідрод	2018-12-11	944	https://doi.org/10.15673/ret.v54i2.1105	Реконструкція турбін методом аналогового моделювання, зображення структури потоку і вдосконалення частин потоку	7
945	Стаття	The depth of sorbate penetration into the adsorbent grains is a new dimensional criterion for estimating efficiency of using the adsorbent in periodic adsorption and desorption processes. The possibility of this criterion utilization in preliminary	2018-12-11	945	https://doi.org/10.15673/ret.v54i2.1104	The depth of sorbath penetration in periodic adsorption processes	7
946	Стаття	В роботі розглянуто змінення середньооб'ємної температури продукту (на прикладі м'яса) при його охолодженні. Використані різноманітні методи розрахунків. Розглянута можливість продукту віддати теплоту та можливість охолоджувального середовища сприйн	2018-12-11	946	https://doi.org/10.15673/ret.v54i2.1103	Аналіз зміни середньооб'ємної температури при охолодженні харчових продуктів	7
947	Стаття	Проведено експериментальне дослідження спільного тепломасообміну та аеродинаміки течії повітря у щільних насадкових шарах упорядкованої структури в умовах поперечноточної схеми контактування при змінному коефіцієнті зрошування РН. Представлений граф	2018-12-11	947	https://doi.org/10.15673/ret.v54i2.1102	Регулярні насадки для апаратів зволоження повітря	7
948	Стаття	Экономичность терморегуляции многослойными ограждающими конструкциями (МОК) зданий и сооружений СНиП, действовавшие ранее в Украине,  регламентировали установлением приемлемых в определенные периоды эксплуатации перепадов температур, декларируя неиз	2018-12-11	948	https://doi.org/10.15673/ret.v54i2.1101	Модернизация систем, регулирующих температуры поверхностей многослойных ограждающих конструкций	7
949	Стаття	Перспективным, с точки зрения энергосбережения, направлением в современной технике является создание бытовых приборов, объединяющих функции холодильного хранения и тепловой обработки пищевых продуктов, полуфабрикатов и сельскохозяйственного сырья. И	2018-12-11	949	https://doi.org/10.15673/ret.v54i2.1098	Разработка бытовых комбинированных приборов абсорбционного типа	7
950	Стаття	Абсорбційні холодильники можуть знайти широке застосування при роботі в широкому діапазоні температур повітря навколишнєго середовища. Для вирішення ряду технічних завдань по оптимізації енергетичних характеристик були виконані теоретичні дослідженн	2018-12-07	950	https://doi.org/10.15673/ret.v54i3.1096	Удосконалення режимних параметрів водоаміачних абсорбційних холодильних агрегатів, працюючих у широкому діапазоні температур навколишнього середовища	7
951	Стаття	Реальним робочим тілом парокомпресійних холодильних машин є розчини холодоагенту в компресорних мастилах. Однак питання впливу домішок компресорного мастила в холодоагенті на показники ефективності компресорної системи залишаються недостатньо вивчен	2018-10-31	951	https://doi.org/10.15673/ret.v54i5.1268	Експериментальне дослідження калоричних властивостей розчинів диметилового ефіру (DME) в триетиленгліколі (TEG)	7
952	Стаття	 В статье приводится информация про влияние применения наночастиц для улучшения теплотехнических характеристик теплообменных аппаратов холодильной машины, работающей на изобутане. Приводится описание экспериментального исследования конденсатора мало	2018-10-31	952	https://doi.org/10.15673/ret.v54i5.1267	Экспериментальное исследование процесса конденсации холодильного агента r600a при добавлении нанофлюидов	7
953	Стаття	Концентрати неону, гелію, криптону і ксенону здобувають з атмосфери в якості побічних продуктів при переробці в повітророздільних установках великих обсягів атмосферного повітря. Основними джерелами неону і гелію в Україні є кисневі цехи металургійн	2018-10-31	953	https://doi.org/10.15673/ret.v54i5.1266	Методи забезпечення кріогенних температур в установках збагачення неоногелієвої суміші	7
954	Стаття	Представлены технические решения известных в мировой практике узлов стыковки систем термостатирования воздухом низкого давления ракет космического назначения. Проанализированы приведенные технические решения. По результатам анализа изложены выводы.	2018-10-31	954	https://doi.org/10.15673/ret.v54i5.1265	Анализ технических решений узлов стыковки систем термостатирования космических ракет	7
955	Стаття	The modern trend in compressor industry is an extension of the use of multi-shaft centrifugal compressors. Multi-shaft compressors have a number of advantages over single-shaft. The design of such compressors gives opportunity to use an axial inlet	2018-10-31	955	https://doi.org/10.15673/ret.v54i5.1239	Design of high efficiency centrifugal compressors stages	7
956	Стаття	Розглянуто спосіб зниження енергетичних витрат при холодильному зберіганні соковитої рослинної продукції шляхом підвищення теплової інерційності та акумулюючої здатності охолоджуваного простору. Засобом підвищення теплової інерційності охолоджуваног	2018-10-31	956	https://doi.org/10.15673/ret.v54i5.1221	Зниження енергетичних витрат при роботі холодильного обладнання під час зберігання соковитої рослинницької сировини	7
957	Стаття	Проведено аналіз виробництва і роботи морозильного ларя з моніторингом температур та енергозатратами системи при отримання штучного холоду. Описані технічні характеристики торгівельного холодильника моделі М400S+. Показана доцільність створення комп	2018-10-31	957	https://doi.org/10.15673/ret.v54i3.1109	Дослідження вирорбництва та роботи торгового холодильного обладнання	7
958	Стаття	У статті наведені результати експериментальних досліджень кінематичної в'язкості, густини, теплоємності і теплопровідності теплоносія C14-30 в інтервалі температур 20 - 300 ˚С. Також в роботі детально розглянуті методики проведення досліджень теплоф	2018-10-30	958	https://doi.org/10.15673/ret.v54i5.1251	Експериментальне дослідження густини, теплоємності, теплопровідності і в'язкості високотемпературного теплоносія C14-30	7
959	Стаття	Concerning the construction of a solar water-thermal collector – the analysis of the applied polymeric materials has been performed in relation to manufacturing of its main parts – the heat absorber and the transparent cover. The use of polymers in	2018-10-30	959	https://doi.org/10.15673/ret.v54i5.1250	The prospects of polymeric materials in assembling the solar water-thermal collectors. Comparative data analysis and exploratory research of promising solutions	7
1103	Стаття	The development and implementation of a new economic electrical equipment, in particular, energy-efficient distribution transformers – is a very essential step to reduce electricity losses in 0,4-35kV distribution networks. In a market economy the f	2016-06-30	1103	https://doi.org/10.21691/ret.v52i2.59	ENERGY EFFICIENT TRANSFORMERS WITH VARIOUS LOAD GRAPHICS  FOR THE CONSUMERS OF ELECTRIC POWER	7
960	Стаття	Один з перспективних шляхів економії первинної енергії паливно-енергетичних ресурсів з  одночасним  отриманням електроенергії, тепла та холоду ґрунтується на концепції тригенерації. Наведено  спосіб створення системи тригенерації через концептуальну	2018-10-30	960	https://doi.org/10.15673/ret.v54i5.1249	Обговорення можливості створення систем тригенерації в умовах клімату країн Близького Сходу	7
961	Стаття	Проведено аналіз існуючих газотурбінних установок (ГТУ) із застосуванням проміжного охолодження циклового повітря різних фірм-виробників, визначені основні технічні характеристики та головні параметри роботи цих ГТУ. Розглянуто основні шляхи реаліза	2018-10-30	961	https://doi.org/10.15673/ret.v54i5.1248	Застосування контактного охолодження повітря аеротермопресором в циклі газотурбінної установки	7
962	Стаття	Напрямком дослідження є аналіз каскадної холодильної машини для морських контейнерних перевезень. Низькотемпературні рефконтейнери призначені для перевезення на далекі відстані цінних вантажів, таких як: продукти крові, біопрепарати і цінні види риб	2018-10-30	962	https://doi.org/10.15673/ret.v54i5.1247	Термодинамічний аналіз каскадної холодильної машини морського рефконтейнера	7
1034	Стаття	Plate-fin heat exchangers are widely used in refrigeration technique. They are popular because of their compactness and excellent heat transfer performance. Here we present a numerical model for the development, research and optimization of a plate-f	2017-10-30	1034	https://doi.org/10.15673/ret.v53i2.589	Numerical Study of Compact Plate-Fin Heat Exchanger for Rotary-Vane Gas Refrigeration Machine	7
963	Стаття	Проаналізовано охолодження повітря на вході газотурбінного двигуна при змінних упродовж року кліматичних умовах експлуатації. Запропоновано для охолодження повітря застосування тепловикористовуючих холодильних машин, що використовують для отримання	2018-10-30	963	https://doi.org/10.15673/ret.v54i5.1246	Порівняння ефективності охолодження повітря на вході газотурбінного двигуна в умовах помірного і субтропічного клімату	7
964	Стаття	Запропоновано підхід до визначення складових теплового навантаження системи кондиціонування припливного повітря (СКПП) з урахуванням поточних кліматичних умов експлуатації, який базується на гіпотезі розкладання поточних змінних теплових навантажень	2018-10-30	964	https://doi.org/10.15673/ret.v54i5.1245	Підхід до визначення складових теплового навантаження систем кондиціонування припливного повітря	7
965	Стаття	Запропоновано метод виділення властивостей, які характеризують певний об'єкт предметної області, з метою скорочення трудових і часових витрат на зіставлення об'єктів різних предметних областей при побудові об’єднаної моделі предметної області в проц	2018-10-07	965	https://doi.org/10.15673/ret.v54i2.1048	Метод виділення властивостей, які характеризують об’єкт предметної області	7
966	Стаття	Представлены результаты аналитического исследования тепломассопереноса в плотном слое гранулированного материала с газовым потоком как теплообменного участка регенеративных и рекуперативных устройств. Предложена математическая модель теплообмена межд	2018-09-12	966	https://doi.org/10.15673/ret.v54i2.1029	Аналитическое исследование теплопереноса в плотном слое гранулированного материала с внутренними источниками теплоты	7
967	Стаття	У праці проаналізовано теоретичні та експериментальні моделі та методи розрахунку гідродинаміки і теплообміну під час конденсації робочих речовин у середині горизонтальних труб у разі стратифікованого режиму течії фаз із відкритих літературних джере	2018-09-10	967	https://doi.org/10.15673/ret.v54i4.1121	Гідродинаміка та теплообмін під час конденсації пари робочих речовин у середині горизонтальних труб у разі стратифікованого режиму течії фаз. Огляд праць	7
968	Стаття	The importance of thermodynamic and phase behavior of working fluids embedded with nanostructured materials is fundamental to new nanotechnology applications. The fullerenes (C60) and carbon nanotubes (CNT) adding to refrigerants change their thermo	2018-09-09	968	https://doi.org/10.15673/ret.v54i4.1213	The Joule-Thomson Effect for Refrigerants with Dopants of the Fullerenes and Carbon Nanotubes	7
969	Стаття	З кожним роком проблема енергозбереження в сучасному світі стає все більш і більш актуальною. Енергозбереження передбачає економне витрачання енергетичних ресурсів, тому що природні ресурси є вичерпними, дорого коштують, а їх видобуток в більшості в	2018-09-09	969	https://doi.org/10.15673/ret.v54i4.1212	Теплозахист будинків і споруд системами теплолокалізаціі	7
970	Стаття	Для вирішення проблеми енергозбереження при обов'язковому і строгому дотриманні нормативних вимог до повітря, досліджений вплив   ефекту «теплової хвилі» на холодопродуктивність кондиціонера.  За допомогою  розробленої методики нестаціонарного розра	2018-09-09	970	https://doi.org/10.15673/ret.v54i4.1211	Дослідження впливу  ефекту «теплової хвилі» на  холодопродуктивність кондиціонера	7
971	Стаття	Gas-dynamic characteristics of the compressor make it possible to evaluate its energy and economic properties, to predict the values of capacity, the generated gas pressure and the power consumption during the compressor operation. For more in-depth	2018-09-09	971	https://doi.org/10.15673/ret.v54i4.1118	Gazdynamic characteristics of the centrifugal compressor calculation	7
972	Стаття	На текущий момент, сфера создания полуфабрикатов постоянно расширяется. Процесс получения полуфабрикатов достаточно хорошо известен и распространен. Данная работа включает в себя новый взгляд на производство и разработку роботизированного комплекса	2018-08-30	972	https://doi.org/10.15673/ret.v54i4.1220	Интеграция робототехнического комплекса производства замороженных полуфабрикатов особых форм	7
973	Стаття	В роботі запропоновано теоретичне рівняння стану рідкого метану, побудоване в рамках теорії збурення, де в якості нульового наближення виступає флюїд Ленарда-Джонса, а в якості потенціалу збурення – октуполь-октупольна взаємодія молекул метану. Рівн	2018-08-30	973	https://doi.org/10.15673/ret.v54i4.1219	Рівняння стану конденсованого метану при високих тисках	7
974	Стаття	У роботі розглянуто підходи до приготування робочих тіл парокомпресійних холодильних систем з добавками наночастинок оксидів металів - нанохолодоагентів. Показано, що до сих пір не розроблено технології приготування агрегативно стабільних нанохолодо	2018-08-30	974	https://doi.org/10.15673/ret.v54i4.1216	Дослідження технології приготування робочих тіл парокомпресійних холодильних систем з добавками наночастинок TiO2	7
975	Стаття	В даний час має місце інтенсивне посилення норм на токсичні викиди відпрацьованих газів суднових дизелів при плаванні суден в прибережних морських районах і на внутрішніх водних шляхах. Постійне зростання числа суден призводить до збільшення об’єму	2018-08-30	975	https://doi.org/10.15673/ret.v54i4.1215	Метод рециркуляції відпрацьованих газів суднових дизелів для зме-ншення їх токсичності	7
976	Стаття	Работа посвящена экспериментальному и теоретическому решению важной научно-технической задачи интенсификации теплообмена в микроструктурных элементах систем терморегулирования с целью повышения их теплотехнической эффективности, надежности, уменьшен	2018-08-30	976	https://doi.org/10.15673/ret.v54i4.1214	Факторы интенсификации кипения в двухфазных системах терморегулирования	7
977	Стаття	З появою мультисервісних мереж з’явилися інтелектуальні сервіси (INS) і, відповідно, новий тип трафіку. Протягом довгого часу вважалося, що мережний трафік відповідає пуасонівським процесам, але подальші дослідження довели, що в трафіку деяких мереж	2018-08-30	977	https://doi.org/10.15673/ret.v54i4.1175	Аналітична модель інтелектуальної надбудови NGN з урахуванням самоподібності трафіку	7
978	Стаття	One of the aspects of the global trend in the development of Smart systems is considered in the paper, namely those solutions of the leading manufacturers of electrical household appliances that relate to the implementation of additional intelligent	2018-08-17	978	https://doi.org/10.15673/ret.v54i1.994	Smart Refrigerators in Return for Energy Efficiency	7
979	Стаття	An analytical solution is obtained for a system of differential equations consisting of the equation for diffusion and absorption of a component in adsorbent grains and the balance equation for this component moving in the adsorbent layer.The techniq	2018-08-17	979	https://doi.org/10.15673/ret.v54i1.992	Effect of Adsorbent Grain Size on the Pressure Swing Adsorption	7
980	Стаття	Метою дослідження є моделювання робочих процесів з урахуванням особливостей плівкових течій в тепло-масообмінних апаратах і проведення дослідження сонячних регенераторів абсорбенту та випаровувальних охолоджувачів; на основі виконаного циклу робіт о	2018-08-17	980	https://doi.org/10.15673/ret.v54i1.991	Автоматизація розрахунків і конструювання тепло-масообмінних апаратів	7
981	Стаття	В роботі представлено дослідження особливостей функцій маршрутизаторів в різних областях дії протоколу OSPF. Робота проводилась у середовищі Cisco Packet Tracer. Вивчалися налаштування маршрутизаторів у різних варіантах побудови ієрархічної системи н	2018-08-17	981	https://doi.org/10.15673/ret.v54i1.990	Особливості  функціонування  і  налаштувань маршрутизаторів в різних областях дії протоколу динамічної маршрутизації OSPF	7
982	Стаття	Розглянуто особливості побудови приладів для дистанційного контролю температури та вологості повітря, з використанням мікроконтролерів і однокристальних Ethernet інтерфейсів, мікросхем фірми Microchip ENC28J60, ENC424J600 і KSZ8441.	2018-08-17	982	https://doi.org/10.15673/ret.v54i1.989	Застосування інтернету речей для контролю температури та вологості повітря	7
983	Стаття	Дефицит органических топливных ресурсов, особенно ощутимый в настоящее время в Украине, а также ужесточающийся во всем мире экологические требования по снижению потенциала глобального потепления на планете ставят как никогда ранее актуальную задачу	2018-08-17	983	https://doi.org/10.15673/ret.v54i1.988	Методика определения термодинамической эффективности абсорбционных холодильных установок на основе анализа эксергетических потерь в их элементах	7
984	Стаття	Задача з проектування вузлів стикування (ВС) систем термостатування (СТ) ракет космічного призначення (РКП) вперше виникла в Україні і в ДП «КБ «Південне»», починаючи з розробки КРК «Циклон-4». До цього на аналогічних комплексах за дані пристрої відп	2018-08-17	984	https://doi.org/10.15673/ret.v54i1.986	Шляхи створення вузлів стикування систем термостатування ракет космічного призначення	7
985	Стаття	The influence of a biologically inert protective coating on the basis of low-esterified pectin substances (LEPS) on the qualitative indicators of frozen fish and its lipids is studied in this paper: organoleptic, physico-chemical, structural-mechanic	2018-08-17	985	https://doi.org/10.15673/ret.v54i1.985	Influence of Biologically Inert Protective Coating Based on Pectin Substances on PUFA Quality and Shelf-Life of Frozen Fish	7
986	Стаття	Вивчені експлуатаційні характеристики сонячних колекторів, які виготовлені зі стільникових полікарбонатних пластиків, для адсорбційних холодильних установок. Проведені натурні випробування розроблених колекторів ПСК-АВ2-3, ПСК-АВ1-2, ПСК-АВ2-1, ПСК-В	2018-08-17	986	https://doi.org/10.15673/ret.v54i1.984	Експлуатаційні характеристики полімерних сонячних колекторів для адсорбційних холодильних геліоустановок	7
987	Стаття	Рассматривается использование теплообменника-регенератора с гранулированной насадкой для утилизации низкопотенциальной теплоты отходящих газов. Приведена методика теплового расчета регенератора с неподвижной насадкой гранулированного материала. Предс	2018-08-17	987	https://doi.org/10.15673/ret.v54i1.983	Разработка теплообменника с неподвижной гранулированной насадкой для утилизации низкопотенциальной теплоты	7
988	Стаття	The choice of trade-off working fluid in the reverse Rankine cycle was studied as a problem of fuzzy optimization. Three main criteria were chosen as objective functions: thermodynamic (COP – coefficient of performance), economic (LCC – cost of life	2018-08-17	988	https://doi.org/10.15673/ret.v54i1.982	Smart working fluid selection in refrigeration systems	7
989	Стаття	Проведено теоретичне дослідження характеристик одноступеневої холодильної машини на сучасних холодоагентах, що застосовуються в холодильній техніці, а також, у якості альтернативного варіанту – на природних холодоагентах, зокрема аміак, пропан, проп	2018-07-09	989	https://doi.org/10.15673/ret.v54i3.1107	Дослідження характеристик холодильної машини, працюючої на натуральних альтернативних холодоагентах	7
990	Стаття	A new approach to modeling of the pressure swing adsorption (PSA) based on a wave method for calculating non-stationary periodic mass transfer processes is proposed. The analysis of solutions for plants designed to produce oxygen from air is given.	2018-07-08	990	https://doi.org/10.15673/ret.v54i4.1120	Wave approach for modeling pressure swing adsorption	7
991	Стаття	В роботі представлено дослідження особливостей функціювання декількох протоколів маршрутизації одночасно на одному маршрутизаторі та особливостей налаштування такої взаємодії. Робота проводилась у середовищі Cisco Packet Tracer. Вивчено налаштування	2018-06-11	991	https://doi.org/10.15673/ret.v53i6.928	Особливості взаємодії декількох протоколів маршрутизації у складній комп‘ютерній мережі	7
992	Стаття	Проведено дослідження і симулювання процесу нестаціонарного теплообміну під час охолодження води в дослідній секції поблизу охолоджуваної вертикальної трубчастої поверхні. Побудовано та проведено аналіз графіків розподілу швидкості води по всій висот	2018-06-11	992	https://doi.org/10.15673/ret.v53i6.927	Тривимірне моделювання нестаціонарного теплообміну під час охолодження води	7
993	Стаття	Эволюция энергетических систем в сторону парадигмы интеллектуальных сетей производства и распределения электроэнергии во многом определяется развитием новых технологий и их приложений.  В статье рассматривается подход, который использует достижения и	2018-06-11	993	https://doi.org/10.15673/ret.v53i6.926	Облачный компьютинг для снижения потребления энергии в холодильных системах	7
994	Стаття	Розглянуто питання енергетичної ефективності одного з елементів системи теплового насосу – бака акумулятора теплової енергії. Характеристикою ефективності даного апарата являється мінімальна величина втрат тепла і для її визначення розроблена модель	2018-06-11	994	https://doi.org/10.15673/ret.v53i6.925	Метод визначення тепловтрат у вертикальних циліндричних ємностях на основі сумарного термічного опору тепловіддачі	7
995	Стаття	Статья посвящена методическим принципам проектирования стационарных систем термостатирования. Изложены разновидности систем термостатирования с указанием преимуществ и недостатков. Представ-лены технические требования, предъявляемые к системам со сто	2018-06-11	995	https://doi.org/10.15673/ret.v53i6.924	Методические основы проектирования стационарных систем термостатирования ракет космического назначения на низко- и высококипящих компонентах топлива	7
996	Стаття	In the present research we investigate pressure driven flow in the transition and free-molecular flow regimes with the objective of developing unified flow models for microchannels. These models are based on a velocity scaling law, which is valid for	2018-06-11	996	https://doi.org/10.15673/ret.v53i6.923	Gas Velosity and Mass Flowrate Scaling Modeling  in Microelectronics’ Thermal Control Systems	7
997	Стаття	This paper describes the mathematical model of concentration waves passing through a layer of adsorbent. The analytic solution to this model deduced for eigenwaves of adsorptive layer had been found. It allows finding the analytical decisions for co	2018-06-11	997	https://doi.org/10.15673/ret.v53i6.922	Wave Mathematical Model to Describe Gas Chromatography	7
998	Стаття	При эксплуатации многослойной ограждающей конструкции (МОК) постоянно возникает превышение расчетной температуры наружной поверхности наружного слоя, сравнительно с температурой пространства, расположенного снаружи этой ограды. На наружной поверхност	2018-06-11	998	https://doi.org/10.15673/ret.v53i6.921	Взаимодействие систем теплоснабжения для устранения потерь через наружную поверхность многослойной ограждающей конструкции	7
999	Стаття	Для типового предприятия нефтеперерабатывающего комплекса проведен численный сравнительный анализ возможностей применения теплоиспользующих пароэжекторных (ПЭХУ) и абсорбционных водоаммиачных (АХУ) холодильных установок, работающих с отходящими нагре	2018-06-11	999	https://doi.org/10.15673/ret.v53i6.920	Анализ перспектив использования пароэжекторной и абсорбцион-ной холодильных установок для охлаждения технологического газа и получения жидкого углеводородного топлива	7
1000	Стаття	Розроблено математичну модель ексергетичного методу аналізу роботи одноступеневих хладонових холодильних машин, які використовують в місцевих автономних кондиціонерах. Визначено ексергетичний ККД та втрати ексергії у окремих елементах split-кондиціон	2018-06-11	1000	https://doi.org/10.15673/ret.v53i6.919	Ексергетична ефективність заміни холодильного агента R410А на R32 у split-кондиціонері	7
1001	Стаття	Answers to the question ‘what should we do to improve energy efficiency?’ will have to advance beyond the notion of simply ‘saving energy’ to an enhanced paradigm of policy options as cross-sectoral issue. In this paper we propose to improve rate of	2018-04-30	1001	https://doi.org/10.15673/ret.v54i2.1099	Energy efficiency projects	7
1002	Стаття	У статті представлено результати дослідження роботи повітроохолоджувачів методом комп’ютерного моделювання. Специфічні умови роботи низькотемпературних повітроохолоджувачів пов’язані з інеєутворенням на поверхні теплообміну в процесі експлуатації. Ав	2018-04-30	1002	https://doi.org/10.15673/ret.v54i2.993	Моделювання роботи повітроохолоджувачів холодильних установок	7
1003	Стаття	Создание масштабных или узкоспециализированых проектов в среде AutoCAD занимает много времени. Для сокращения времени проектирования и добавления функционала используются различные методы автоматизации проектирования. Большинство из них, кроме знаний	2017-11-19	1003	https://doi.org/10.15673/ret.v53i4.711	Методы автоматизации проектирования в среде AutoCAD	7
1004	Стаття	Рассмотрен конструктивный метод повышения показателей надежности (интенсивности отказов и вероятности безотказной работы) двухкаскадных термоэлектрических охлаждающих устройств в режиме минимума интенсивности отказов. В двухкаскадных охлаждающих уст	2017-11-19	1004	https://doi.org/10.15673/ret.v53i4.710	Модель взаимосвязи геометрии ветвей термоэлементов и показателей надежности при проектировании двухкаскадных охладителей в режиме минимума интенсивности отказов	7
1005	Стаття	У статті розглянуто особливості анімаційної візуалізації рідини та фактори, що впливають на використання того або іншого математичного методу. Проаналізовано особливості застосування методів для анімаційної візуалізації об’єму, поверхневого хвилюванн	2017-11-19	1005	https://doi.org/10.15673/ret.v53i4.709	Анімаційна візуалізація течії та об'єму рідини	7
1006	Стаття	Рассмотрена концепция интеллектуальных сетей (Smart Grid) электроснабжения для повышения энергоэффективности холодильных систем. Предложена модель виртуальной энергетической системы, в состав которой входят подсистемы охлаждения и отопления. Эта сист	2017-11-19	1006	https://doi.org/10.15673/ret.v53i4.708	Повышение энергоэффективности холодильных систем в интеллектуальных сетях электроснабжения	7
1007	Стаття	Предлагается проект вымораживающего опреснителя-разделителя (ВОР), в котором исходный рассол (как пример – йодо-бромный 5%-ный) опресняется насухо – без вывода концентрата, загрязняющего окружающую среду. Соли разделяют путем использования различия п	2017-11-19	1007	https://doi.org/10.15673/ret.v53i4.707	Талая облегченная питьевая вода, соли, тяжелая вода – из вымораживающего опреснителя разделителя со «своей» электростанцией	7
1008	Стаття	Розроблено та обґрунтовано цільову функцію спільної оптимізації сумарної величини капітальних і експлуатаційних витрат на тепловий захист приміщень і кліматичне енергозберігаюче обладнання протягом терміну їх експлуатації. Наведена цільова функція є	2017-11-19	1008	https://doi.org/10.15673/ret.v53i4.706	Оптимізація сумарної вартості теплового захисту приміщень та кліматичного обладнання	7
1011	Стаття	При поиске энергосберегающих режимов абсорбционных холодильных агрегатов необходимо обратить особое внимание на эффективность транспортировки аммиака в испаритель, особенно в условиях работы при пониженных температурах наружного воздуха. Ключевую рол	2017-11-19	1011	https://doi.org/10.15673/ret.v53i4.703	Моделирование тепловых режимов дефлегматора бытового абсорбционного холодильного агрегата	7
1012	Стаття	В роботі проаналізовано, які цілі та задачі пред’являються до автоматизованих систем обліку та контролю електричної енергії (АСКОЕ) і представлено автоматизовану систему обліку електроенергії, яку було розроблено і введено в експлуатацію в Одеській о	2017-11-17	1012	https://doi.org/10.15673/ret.v53i3.700	Впровадження автоматизованих систем обліку та контролю електричної енергії на прикладі ПАТ «Одесаобленерго»	7
1013	Стаття	Вопрос безопасности объектов критической важности, в частности в сфере электроэнергетики, всегда стоит остро как перед владельцами предприятий, так и перед государством. В статье рассматриваются особенности обеспечения информационной защиты для элек	2017-11-17	1013	https://doi.org/10.15673/ret.v53i3.699	Особенности информационной безопасности в электроэнергетике	7
1014	Стаття	Розглянуто шляхи підвищення енергоефективності багатозональних систем кондиціювання повітря, деякі технології і елементи, вдосконалення яких безпосередньо підвищує енергоефективність і знижує споживання електроенергії в річному циклі використання сис	2017-11-17	1014	https://doi.org/10.15673/ret.v53i3.698	Шляхи підвищення енергоефективності багатозональних VRF систем кондиціювання повітря	7
1015	Стаття	Широко известны и используются в различных процессах системы регулирования температур на поверхностях многослойных ограждающих конструкций (МОК), обеспечивающие достижение разных и даже противоположных целей: поддержание заданной температуры внутренн	2017-11-17	1015	https://doi.org/10.15673/ret.v53i3.697	Предпосылки использования влияния теплообмена на потерю тепловым потоком, пересекающим ограждение	7
1016	Стаття	Запропонована математична модель, яка враховує інерційну та термодинамічну складові осциляції бульбашок, теплообмінні процеси у рідині, теплообмін на границі бульбашки. Проведено дослідження динамічних характеристик газопарових бульбашок різних розмі	2017-11-17	1016	https://doi.org/10.15673/ret.v53i3.696	Аналіз впливу розміру газопарової бульбашки на процес гідратоутворення	7
1017	Стаття	Показана целесообразность форсирования подводимой тепловой нагрузки на генератор абсорбционного холодильного агрегата в период пуска – снижение энергозатрат при эксплуатации может составить от 25 до 35%. Предложен bи обоснован новый способ управления	2017-11-17	1017	https://doi.org/10.15673/ret.v53i3.695	Повышение энергетической эффективности бытовых  абсорбционных холодильных приборов	7
1018	Стаття	Джерелом зниження ефективності теплообмінного апарату в процесі експлуатації є відклади. Проблеми відкладів на поверхнях теплообмінних апаратів віднесено до “невирішених”. В роботі наведено спосіб експериментального дослідження повітряного конденсато	2017-11-17	1018	https://doi.org/10.15673/ret.v53i3.674	Метод експериментального дослідження повітряних конденсаторів малих холодильних машин і теплових насосів	7
1019	Стаття	Розроблена автоматизована система ThermoPro 5 для розрахунку теплофізичних властивостей більше 50 речовин. В автоматизованій системі в основному представлені сучасні рівняння стану фундаментального типу, а також віріального рівняння стану для високих	2017-11-02	1019	https://doi.org/10.15673/ret.v53i5.857	Автоматизована система для визначення теплофізичних властивостей технічних речовин	7
1020	Стаття	Одной из главных проблематик в развитии концепции интернета вещей (IoT, Industrial Internet of Things) в большинстве приложений является обеспечение информационной безопасности.  Эти проблемы становятся все более актуальными из-за роста спроса на IoT	2017-11-02	1020	https://doi.org/10.15673/ret.v53i5.856	Проблематика использования интернета вещей на примере смарт-холодильников	7
1021	Стаття	В роботі представлений метод оцінки структурної живучості інтелектуальної надбудови з децентралізованим принципом управління при наданні інтелектуальних сервісів в мережах наступного покоління. Для оцінки структурної живучості інтелектуальної надбудо	2017-11-02	1021	https://doi.org/10.15673/ret.v53i5.855	Метод забезпечення структурної живучості інтелектуальної надбудови з децентралізованим принципом управління	7
1022	Стаття	В статье рассматриваются системы управления процессами охлаждения продуктов в туннельных камерах. Представляется разработанная лабораторная холодильная установка с туннельной камерой как физическая модель для экспериментальных исследований рассматрив	2017-11-02	1022	https://doi.org/10.15673/ret.v53i5.854	Разработка алгоритмов управления процессами охлаждения продуктов в туннельных камерах	7
1023	Стаття	В статье приведены основные зависимости для определения плотности и теплопроводности инея. Приведено сравнение наиболее распространённых зависимостей теплопроводности и плотности инея. Представлены результаты расчета математической модели в виде граф	2017-11-02	1023	https://doi.org/10.15673/ret.v53i5.853	Оценка влияния исходных уравнений плотности и теплопроводности инея на результаты прогнозирования скорости формирования намороженного слоя	7
1024	Стаття	The analysis of different aspects of grain refrigeration on elevators of Ukraine, Commonwealth of Independent States (CIS)   and in the world is carried out. The advantage of the refrigeration method is shown  concerning the quality  and   of energy	2017-11-02	1024	https://doi.org/10.15673/ret.v53i5.852	Cooling System for Primary Low Temperature Processing and Storage of Grains of Small Frachioned	7
1025	Стаття	В роботі розглянуті шляхи підвищення ефективності систем кондиціювання повітря для закритих басейнів цілорічного функціонування, розглянуті деякі технології i елементи, вдосконалення яких безпосередньо підвищує енергоефективність i знижує споживання	2017-11-02	1025	https://doi.org/10.15673/ret.v53i5.851	Шляхи підвищення енергоефективності систем кондиціювання повітря в басейні	7
1026	Стаття	The well-known complicated system of non-equilibrium balance equations for a continuous fluid (f) medium needs the new non-Gibbsian model of f-phase to be applicable for description of the heterogeneous porous media (PMs). It should be supplemented b	2017-11-02	1026	https://doi.org/10.15673/ret.v53i5.850	New Non-Stationary Gradient Model of Heat-Mass-Electric Charge Transfer in Thin Porous Media	7
1027	Стаття	В статье приведены результаты экспериментального исследования влияния примесей фуллеренов С60 на значения давления насыщенных паров и поверхностного натяжения растворов хладагента R600a/минеральное масло. Исследования проведены в интервале температур	2017-10-30	1027	https://doi.org/10.15673/ret.v53i2.597	ЭКСПЕРИМЕНТАЛЬНОЕ ИССЛЕДОВАНИЕ ВЛИЯНИЯ ФУЛЛЕРЕНОВ С60 НА ДАВЛЕНИЯ НАСЫЩЕННЫХ ПАРОВ И ПОВЕРХНОСТНОЕ НАТЯЖЕНИЕ РАСТВОРОВ ХЛАДАГЕНТА R600а С КОМПРЕССОРНЫМ МАСЛОМ	7
1028	Стаття	Природный газ является ценным энергоносителем, а также сырьем для химической промышленности. В работе приведены данные по мировому рынку природного газа с учетом сжиженного природного газа: запасы, производство, потребление. Показано, что поставки сж	2017-10-30	1028	https://doi.org/10.15673/ret.v53i2.595	СЖИЖЕННЫЙ ГАЗ – АЛЬТЕРНАТИВНЫЙ ИСТОЧНИК ПОСТАВОК ПРИРОДНОГО ГАЗА В ПРОМЫШЛЕННО РАЗВИТЫЕ РЕГИОНЫ МИРА	7
1029	Стаття	Применение аккумуляторов теплоты на основе твёрдых веществ в системах теплоснабжения является актуальным при использовании двух- и трёхзонного тарифа на электроэнергию. Основными преимуществами таких аккумуляторов теплоты являются простота конструкц	2017-10-30	1029	https://doi.org/10.15673/ret.v53i2.594	МОДЕРНИЗАЦИЯ КОНСТРУКЦИИ АККУМУЛЯТОРОВ ТЕПЛОТЫ НА ОСНОВЕ ТВЕРДЫХ МАТЕРИАЛОВ ДЛЯ РАБОТЫ ПО НОЧНОМУ ТАРИФУ НА ЭЛЕКТРОЭНЕРГИЮ	7
1030	Стаття	Теплообменники контактного типа, особенностями которых является передача теплоты путем непосредственного соприкосновения рабочих тел, имеют ряд несомненных преимуществ в сравнении с теплообменниками поверхностного типа. К основным преимуществам относ	2017-10-30	1030	https://doi.org/10.15673/ret.v53i2.593	МАТЕМАТИЧЕСКОЕ ОПИСАНИЕ ПРОЦЕССА ТЕПЛООБМЕНА МЕЖДУ ПОТОКАМИ ГАЗА И ДИСПЕРСНОГО МАТЕРИАЛА	7
1031	Стаття	В роботі наведено причини і виконане обґрунтування доцільності впровадження на етапі проектування розподільчого трансформатора з економічно обґрунтованою і оптимальною конструкцією - методу моделювання поля температур на підставі вирішення рівняння П	2017-10-30	1031	https://doi.org/10.15673/ret.v53i2.592	МОДЕЛЮВАННЯ ПОЛЯ ТЕМПЕРАТУРИ РОЗПОДІЛЬЧОГО ТРАНСФОРМАТОРА	7
1032	Стаття	В современной Украине на объектах торговли получили распространение камеры небольшой вместимости от 4 м2 до 11 м2. Причем, при увеличении площади торгового зала увеличивается, как правило, количество камер, а не их вместимость. Использование централь	2017-10-30	1032	https://doi.org/10.15673/ret.v53i2.591	ОСОБЕННОСТИ ТЕХНИКО-ЭКОНОМИЧЕСКИХ РАСЧЕТОВ ХОЛОДИЛЬНЫХ КАМЕР ОБЪЕКТОВ ТОРГОВЛИ	7
1033	Стаття	The article touches upon the design and calculation of trade objects refrigerating chambers. The influence of the cost of various groups of components and equipment on the final cost of the camera is analyzed. The influence of such factors as noise,	2017-10-30	1033	https://doi.org/10.15673/ret.v53i2.590	FEATURES OF TECHNO-ECONOMIC CALCULATION OF COMMERCIAL COOLING CHAMBERS	7
1035	Стаття	Приведен способ синтеза схемно-циклового решения низкотемпературной теплоиспользующей  машины с R744, в которой термодинамические процессы прямого (силового) цикла происходят в надкритической области для R744, обратного (холодильного) - в надкритичес	2017-10-30	1035	https://doi.org/10.15673/ret.v53i2.588	Низкотемпературные теплоиспользующие компрессорные холодильные машины с R744	7
1036	Стаття	Progress on advancing technology of using liquid nitrogen for the non-polluting automobiles is reported. It is shown that the low exergy efficiency of the known engines fueled with liquid nitrogen has discredited the very idea of a cryomobile. The de	2017-10-30	1036	https://doi.org/10.15673/ret.v53i5.849	Application of the Open Cycle Stirling Engine Driven with Liquid Nitrogen for the Non-Polluting Automobiles	7
1037	Стаття	У роботі проведено аналіз експериментальних досліджень конденсації робочих речовин всередині мініканалів із літературних джерел. Наведено залежності коефіцієнтів тепловіддачі від масового паровмісту за різними масовими швидкостями та тепловими потока	2017-10-30	1037	https://doi.org/10.15673/ret.v53i5.848	Теплообмін при конденсації всередині мініканалів	7
1038	Стаття	Представлены результаты экспериментальных исследований генераторных узлов абсорбционных холодильных приборов в диапазоне температур воздуха окружающей среды 8…34 °С. Показана необходимость установки тепловой изоляции на всей длине подъемного участка	2017-10-30	1038	https://doi.org/10.15673/ret.v53i5.847	Результаты экспериментальных исследований генераторных узлов абсорбционных холодильных приборов, работающих в широком диапазоне температур окружающей среды	7
1039	Стаття	Предлагается вымораживающая   технология производства тяжелой воды.  Технология основана на значительном коэффициенте разделения изотопов водорода  в  процессах  вымораживания. Используется принцип колоночной кристаллизации  и  плавления льда по высо	2017-09-11	1039	https://doi.org/10.15673/ret.v53i1.546	ТЕХНОЛОГИЯ ПРОИЗВОДСТВА ТЯЖЕЛОЙ ВОДЫ ВЫМОРАЖИВАНИЕМ	7
1040	Стаття	В статье представлена математическая модель колпака-гасителя колебаний давления в поршневых насосах и ее апробация на практических расчетах. Цель работы – получение теоретического обоснование обоснования для расчета колпака-гасителя колебаний давлени	2017-09-11	1040	https://doi.org/10.15673/ret.v53i1.545	АЛГОРИТМ РАСЧЕТА ДЕМПФИРУЮЩЕГО КОЛПАКА ДЛЯ ПОРШНЕВОГО НАСОСА	7
1041	Стаття	В статье представлены результаты экспериментального исследования температурной и концентрационной зависимостей плотности и вязкости, растворов хладагент R600a/минеральное масло ХФ16-12/ фуллерены С60. Измерения плотности выполнены пикнометрическим ме	2017-09-11	1041	https://doi.org/10.15673/ret.v53i1.544	ПЛОТНОСТЬ И ВЯЗКОСТЬ РАСТВОРОВ ХЛАДАГЕНТ R600a / МИНЕРАЛЬНОЕ МАСЛО / ФУЛЛЕРЕНЫ С60	7
1042	Стаття	К числу важнейших проблем разработки энергосберегающих технологий сталеплавильного производства стали относится проблема продувки ванны сталеплавильного агрегата с организацией эффективного кислородного режима выплавки стали для дожигания оксида угле	2017-09-11	1042	https://doi.org/10.15673/ret.v53i1.543	ОПРЕДЕЛЕНИЕ ВЛИЯНИЯ ТЕПЛОФИЗИЧЕСКИХ ПАРАМЕТРОВ НА ИНТЕНСИФИКАЦИЮ ПРОЦЕССОВ ТЕПЛООБМЕНА В ВАННЕ СТАЛЕПЛАВИЛЬНОГО АГРЕГАТА	7
1043	Стаття	Результатом роботи є обґрунтування доцільності впровадження результатів моделювання рівнянь теплового балансу, складених для активної частини розподільчого трансформатора напруги, на стадії його завершального і уточнюючого етапу проектування. Активна	2017-09-11	1043	https://doi.org/10.15673/ret.v53i1.542	МОДЕЛЮВАННЯ ПРОЦЕСУ КОНВЕКТИВНОГО ТЕПЛООБМІНУ МАСЛОМ З ПОВЕРХНІ РОЗПОДІЛЬЧОГО ТРАНСФОРМАТОРА	7
1044	Стаття	Изложены методика и результаты численного моделирования напряженно-деформированного состояния лопаток завихрителя вихревой горелки, разработанной для модернизации отопительных котлов. Особенностью предложенной горелки является конструкция закручиваю	2017-09-11	1044	https://doi.org/10.15673/ret.v53i1.541	МОДЕЛИРОВАНИЕ НАПРЯЖЕННО-ДЕФОРМИРОВАННОГО СОСТОЯНИЯ ЗАВИХРИТЕЛЯ ВИХРЕВОЙ ГОРЕЛКИ	7
1045	Стаття	Рассмотрены особенности рабочего диагностирования цифровых компонентов в системах критического применения, обеспечивающих функциональную безопасность объектов повышенного риска, включая криогенную технику. Показана целесообразность развития рабочего	2017-09-11	1045	https://doi.org/10.15673/ret.v53i1.540	МЕТОДЫ РАБОЧЕГО ДИАГНОСТИРОВАНИЯ ДЛЯ ЦИФРОВЫХ КОМПОНЕНТОВ СИСТЕМ КРИТИЧЕСКОГО ПРИМЕНЕНИЯ	7
1046	Стаття	The problem of energy saving becomes one of the most important in power engineering. It is caused by exhaustion of world reserves in hydrocarbon fuel, such as gas, oil and coal representing sources of traditional heat supply. Conventional sources hav	2017-09-11	1046	https://doi.org/10.15673/ret.v53i1.539	TWO-STAGE HEAT PUMPS FOR ENERGY SAVING TECHNOLOGIES	7
1047	Стаття	Технологический процесс спекания в микроволновом поле дает возможность получения материалов с улучшенными по сравнению с существующими эксплуатационными и функциональными свойствами. Представлена оценка энергетической эффективности микроволновой техн	2017-09-11	1047	https://doi.org/10.15673/ret.v53i1.538	ЭНЕРГЕТИЧЕСКАЯ ЭФФЕКТИВНОСТЬ СПЕКАНИЯ ТЕХНИЧЕСКОЙ КЕРАМИКИ В МИКРОВОЛНОВОМ ПОЛЕ	7
1048	Стаття	Выполнено математическое моделирование тепловых режимов дефлегматора, которые отвечают за процессы очистки и транспортировке пара аммиака. Моделирование проведено на типовых конструкциях абсорбционных холодильных агрегатов с учетом обоснованных допущ	2017-09-11	1048	https://doi.org/10.15673/ret.v53i1.535	МОДЕЛИРОВАНИЕ ТЕПЛОВЫХ РЕЖИМОВ ПОДЪЕМНОГО УЧАСТКА ДЕФЛЕГМАТОРА БЫТОВОГО АБСОРБЦИОННОГО ХОЛОДИЛЬНОГО АГРЕГАТА	7
1049	Стаття	Разработана математическая модель режимов пленочного течения с восходящим потоком паровой смеси с высокоэффективным отводом тепла в режиме вынужденной конвекции.  Проведена оценка параметров пленочного течения жидкости и парового потока (скорости и	2017-09-11	1049	https://doi.org/10.15673/ret.v53i1.534	МАТЕМАТИЧЕСКОЕ МОДЕЛИРОВАНИЕ РАБОЧИХ РЕЖИМОВ ДЕФЛЕГМАТОРА АБСОРБ-ЦИОННОГО ВОДОАММИАЧНОГО ХОЛОДИЛЬНОГО АГРЕГАТА В СИСТЕМАХ ПОЛУЧЕНИЯ ВОДЫ ИЗ АТМОСФЕРНОГО ВОЗДУХА С ИСПОЛЬЗОВАНИЕМ СОЛНЕЧНОЙ ЭНЕРГИИ	7
1050	Стаття	Эксергетический метод термодинамического анализа стал неотъемлемым элементом научных исследований в области холодильной  и теплонасосной техники.  Информация, полученная в результате эксергетического анализа более масштабная по сравнению с другими ви	2017-09-11	1050	https://doi.org/10.15673/ret.v53i1.533	ВВЕДЕНИЕ В ЭКСЕРГЕТИЧЕСКИЙ АНАЛИЗ АБСОРБЦИОННО-РЕЗОРБЦИОННОЙ ХОЛОДИЛЬНОЙ МАШИНЫ	7
1051	Стаття	Рассмотрены возможности повышения достоверности методов рабочего диагностирования в контроле результатов, вычисляемых в цифровых компонентах информационных управляющих систем критического применения, широко используемых в энергетике, включая криогенн	2017-07-05	1051	https://doi.org/10.15673/ret.v53i3.702	Повышение достоверности контроля цифровых компонентов в системах критического применения	7
1052	Стаття	Рассмотрена возможность рационального проектирования термоэлектрического устройства в составе радиоэлектронной аппаратуры при эксплуатации в различных климатических условиях. Показана возможность выбора в качестве начального — наиболее нагруженного т	2017-07-05	1052	https://doi.org/10.15673/ret.v53i3.701	Рациональное проектирование термоэлектрического охлаждающего устройства для переменных температурных условий эксплуатации	7
1053	Стаття	Розроблено математичну модель нестаціонарного теплового обміну приміщень. Тепловий баланс об'єкта моделюється системою звичайних неоднорідних диференціальних рівнянь з нелінійними коефіцієнтами. В розробленій моделі враховуються нестаціонарні характе	2017-05-28	1053	https://doi.org/10.15673/ret.v52i6.479	МАТЕМАТИЧНЕ МОДЕЛЮВАННЯ НЕСТАЦІОНАРНОГО ТЕПЛОВОГО ОБМІНУ ПРИМІЩЕНЬ	7
1054	Стаття	Проведен анализ отечественных и зарубежных электронных датчиков высокой точности, которые разработаны для измерения деформаций механических деталей в различных областях техники. Но они обеспечивают измерения деформаций с высокой точностью только в уз	2017-05-28	1054	https://doi.org/10.15673/ret.v52i6.478	ЭЛЕКТРОННЫЙ ДАТЧИК ДЛЯ ИЗМЕРЕНИЯ ДЕФОРМАЦИЙ ДЕТАЛЕЙ В ШИРОКОМ ИНТЕРВАЛЕ ТЕМПЕРАТУР	7
1055	Стаття	Результатом роботи є обґрунтування доцільності впровадження результатів моделювання рівнянь теплового балансу, складених для активної частини розподільчого трансформатора напруги, на стадії його завершального і уточнюючого етапу проектування. Активна	2017-05-28	1055	https://doi.org/10.15673/ret.v52i6.477	ТЕПЛОВА ПІДСИСТЕМА РОЗПОДІЛЬЧОГО ТРАНСФОРМАТОРА НАПРУГИ	7
1056	Стаття	Ability of a mixture of low-esterified pectin and acid to cause structural changes of mesopelagic small fish proteins is determined. These changes lead to a decrease in the MRP and an increase in water yielding. Such a influence mechanism on the mois	2017-05-28	1056	https://doi.org/10.15673/ret.v52i6.476	THE INFLUENCE OF PRE-TREATMENT AND LOW-ESTERIFIED PECTINE SUBSTANCES ON QUALITY OF FROZEN FISHERY SEMIFINISHED PRODUCTS	7
1057	Стаття	В работе представлены новые экспериментальные данные по изохорной теплоемкости со стороны двухфазной области для диметилового эфира DME, триэтиленгликоля TEG и растворов DME/TEG при массовых концентрациях DME 20,8% и 74,7% в температурном диапазоне о	2017-05-28	1057	https://doi.org/10.15673/ret.v52i6.475	ЭКСПЕРИМЕНТАЛЬНОЕ ИССЛЕДОВАНИЕ ТЕПЛОЕМКОСТИ РАСТВОРОВ ДИМЕТИЛОВОГО ЭФИРА В ТРИЭТИЛЕНГЛИКОЛЕ	7
1058	Стаття	Для локалізації проривів зовнішнього холодного повітря в опалювальні приміщення застосовують повітряно-теплові завіси. Розглянуто систему локалізації теплоти, шляхом перекривання в перемежованому порядку повітророзподільного отвори повітряно-теплової	2017-05-28	1058	https://doi.org/10.15673/ret.v52i6.470	ДОСЛІДЖЕННЯ СИСТЕМ ТЕПЛОЛОКАЛІЗАЦІЇ ПОВІТРЯНО-ТЕПЛОВИМИ ЗАВІСАМИ	7
1059	Стаття	У статті використана авторська інноваційна математична дослідницька модель впровадженої центральної прямотечійної системи кондиціювання повітря операційних чистих кімнат. Мета моделі – комп’ютерне оцінювання ексергетичної ефективності діючої системи	2017-05-28	1059	https://doi.org/10.15673/ret.v52i6.469	ЗАЛЕЖНІСТЬ ЕКСЕРГЕТИЧНОГО ККД СИСТЕМИ КОНДИЦІЮВАННЯ ПОВІТРЯ ОПЕРАЦІЙНИХ ЧИСТИХ КІМНАТ ВІД ТЕМПЕРАТУРИ І ВОЛОГОВМІСТУ НАВКОЛИШНЬОГО СЕРЕДОВИЩА	7
1060	Стаття	Представлены результаты экспериментальных исследований абсорбционного транспортного холодильника «Киев» АЛ-35 с горелочными устройствами, которые показали его работоспособность при использовании различных доступных органических теплоносителей (этило	2017-05-28	1060	https://doi.org/10.15673/ret.v52i6.468	РАЗРАБОТКА И ИССЛЕДОВАНИЕ ГЕНЕРАТОРОВ ТРАНСПОРТНЫХ АБСОРБЦИОННЫХ ХОЛОДИЛЬНЫХ ПРИБОРОВ	7
1061	Стаття	В работе представлен обзор работ, включающий в себя результаты теоретических и экспериментальных исследований конденсации внутри горизонтальных труб. Показано сравнение теоретических решений с экспериментальными данными.	2017-05-28	1061	https://doi.org/10.15673/ret.v52i6.467	КОНДЕНСАЦИЯ ВНУТРИ ГЛАДКИХ ГОРИЗОНТАЛЬНЫХ ТРУБ. СРАВНЕНИЕ ТЕОРЕТИЧЕСКИХ РЕШЕНИЙ И ЭКСПЕРИМЕНТАЛЬНЫХ ДАННЫХ	7
1062	Стаття	Составлены уравнения, описывающие опытные данные о равновесии жидкость-пар в бинарных смесях неона с криптоном либо ксеноном. Уравнения отображают зависимость давления жидкости либо пара от температуры и состава. При их составлении программа выбирала	2017-05-28	1062	https://doi.org/10.15673/ret.v52i6.466	РАВНОВЕСИЕ ЖИДКОСТЬ–ПАР В СМЕСЯХ НЕОНА С КРИПТОНОМ ЛИБО КСЕНОНОМ	7
1063	Стаття	Nowadays energy efficiency improvement and global warming are issues of current interest because of the natural resources depletion and extreme climate change. Thus, the problem of formation of strict regulations regarding emissions into the air aris	2017-05-28	1063	https://doi.org/10.15673/ret.v52i6.465	ENERGY EFFICIENCY, ENERGY SAVING POTENTIAL AND ENVIRONMENTAL IMPACT RESEARCH OF LPG CARRIER REFRIGERATION SYSTEM	7
1064	Стаття	Rising prices on power supply are forcing business owners to search the ways of operating costs reducing. Refrigeration system in the food industry is a major source of power consumption. The utilization of cold accumulation systems allows reducing o	2017-05-28	1064	https://doi.org/10.15673/ret.v52i6.464	POWER EFFICIENCY OPPORTUNITIES FOR INDUSTRIAL REFRIGERATION SYSTEM OF FOOD PROCESSING ENTERPRISE	7
1065	Стаття	Разработан одноканальный линейный прецизионный формирователь средних и больших временных интервалов на основе известного метода суммирования единичных временных приращений. Приведены структура и алгоритм преобразования программного (заданный) кода во	2017-05-27	1065	https://doi.org/10.15673/ret.v53i2.600	ФОРМИРОВАТЕЛЬ СРЕДНИХ И БОЛЬШИХ ВРЕМЕННЫХ ИНТЕРВАЛОВ ВЫСОКОЙ ТОЧНОСТИ ДЛЯ УПРАВЛЕНИЯ ДВУХПОЗИЦИОННЫМИ ОБЪЕКТАМИ	7
1066	Стаття	Рассмотрено влияние геометрии ветвей термоэлементов в каскадах при (l/S)1 = (l/S)2 на показатели надежности двухкаскадных термоэлектрических охлаждающих устройств для различных перепадов температуры ∆T = 60; 70; 80; 90 К для отношения высоты термоэле	2017-05-27	1066	https://doi.org/10.15673/ret.v53i2.599	МОДЕЛЬ ВЗАИМОСВЯЗИ ГЕОМЕТРИИ ВЕТВЕЙ ТЕРМОЭЛЕМЕНТОВ И ПОКАЗАТЕЛЕЙ НАДЕЖНОСТИ ПРИ ПРОЕКТИРОВАНИИ ДВУХКАСКАДНОГО ОХЛАДИТЕЛЯ В РЕЖИМЕ Q0max	7
1067	Стаття	В статье предложен метод определения функциональной живучести интеллектуальной надстройки, осуществляющей децентрализованное управление процессом предоставления интеллектуальных сервисов, получены выражения для оценки функциональной живучести системы	2017-05-27	1067	https://doi.org/10.15673/ret.v53i2.598	МЕТОД ОПРЕДЕЛЕНИЯ ФУНКЦИОНАЛЬНОЙ ЖИВУЧЕСТИ ПРИ ДЕЦЕНТРАЛИЗОВАННОМ УПРАВЛЕНИИ ИНТЕЛЛЕКТУАЛЬНЫМ СЕРВИСОМ	7
1068	Стаття	Несмотря на развитие атомной и альтернативной энергетик, горение органических топлив является одним из основных источников получения энергии. Использование этого источника сопряжено с выбросами в атмосферу дымовых газов, в состав которых входят разли	2017-02-21	1068	https://doi.org/10.15673/ret.v52i5.289	СОЗДАНИЕ КОМПЬЮТЕРНОЙ МОДЕЛИ ЭКСПЕРИМЕНТА ПО ОЧИСТКЕ ДЫМОВЫХ  ГАЗОВ	7
1069	Стаття	В данной работе произведен оценка влияния снижения температурного графика зданий после реновации на повышение КПД конденсационных котлов, повышение коэффициента преобразования тепловых насосов. Произведен расчет эффективности внедрения тепловых насос	2017-02-21	1069	https://doi.org/10.15673/ret.v52i5.288	ПОВЫШЕНИЕ ЭНЕРГОЭФФЕКТИВНОСТИ СИСТЕМ ИНДИВИДУАЛЬНОГО ТЕПЛОСНАБЖЕНИЯ ЗДАНИЙ ПУТЕМ СНИЖЕНИЯ ТЕМПЕРАТУРНОГО ГРАФИКА ПОСЛЕ ТЕРМОРЕНОВАЦИИ	7
1070	Стаття	В роботі продовжується розглядання розробки параболо-циліндричного сонячного нагрівача, призначеного для приготування та розігріву харчових продуктів, з використанням сонячної енергії. Розглянуто недоліки даного типу сонячного нагрівача та методику	2017-02-21	1070	https://doi.org/10.15673/ret.v52i5.287	ПЕРЕНОСНИЙ ПАРАБОЛОЦИЛІНДРИЧНИЙ СОНЯЧНИЙ НАГРІВАЧ ХАРЧОВИХ ПРОДУКТІВ. ЧАСТИНА 2	7
1071	Стаття	Ограниченность цели создания ограждения, согласно ДБН, поддержанием нормативной температуры с его внутренней стороны,  при постоянстве сопротивлений передаче тепла в  замкнутых слоях многослойной ограждающей конструкции (МОК), пренебрегает учетом выб	2017-02-21	1071	https://doi.org/10.15673/ret.v52i5.286	ПРЕДПОСЫЛКИ ВКЛЮЧЕНИЯ ПОДВИЖНОГО СЛОЯ В ОГРАЖДАЮЩУЮ КОНСТРУКЦИЮ	7
1072	Стаття	Анализируются результаты расчетов избыточной температуры в теле с учетом релаксационных явлений. Определена возможность получения данных по тепловому состоянию тела для любых сколь угодно малых значений чисел Фурье. Показано, что при числах Фурье, бл	2017-02-21	1072	https://doi.org/10.15673/ret.v52i5.285	АНАЛИТИЧЕСКОЕ ИССЛЕДОВАНИЕ ТЕПЛОВОГО СОСТОЯНИЯ ТЕЛА ПРИ ВЫСОКОИНТЕНСИВНЫХ ПРОЦЕССАХ РАСПРОСТРАНЕНИЯ ТЕПЛОТЫ	7
1073	Стаття	The concept of evaporative coolers of gases and fluids on the basis of monoblock multichannel polymeric structures is presented. Different schemes of indirect evaporative coolers, in which the natural cooling limit is the dew point of the ambient air	2017-02-21	1073	https://doi.org/10.15673/ret.v52i5.284	EVAPORATIVE  WATER AND AIR COOLERS FOR SOLAR COOLING SYSTEMS.  ANALYSIS AND PERSPECTIVES	7
1074	Стаття	Работа посвящена развитию инженерных основ создания аппаратов бытовой холодильной техники абсорбционного типа. Объекты исследований – абсорбционные холодильные приборы с объемом холодильной камеры от 35 до 40 дм3, размещенные на малых морских судах,	2017-02-21	1074	https://doi.org/10.15673/ret.v52i5.283	РАЗРАБОТКА ТРАНСПОРТНЫХ АБСОРБЦИОННЫХ ХОЛОДИЛЬНЫХ ПРИБОРОВ	7
1075	Стаття	Данная работа посвящена изучению методов и устройств, повышающих эксплуатационные характеристики и надежность поршневых насосов. Представлено экспериментальное исследование нормальных и аварийных режимов работы поршневых насосов с криогенной средой.	2017-02-21	1075	https://doi.org/10.15673/ret.v52i5.282	ИССЛЕДОВАНИЕ ДИНАМИКИ ПОРШНЕВОГО НАСОСА В НОРМАЛЬНОМ РЕЖИМЕ РАБОТЫ И ПРИ СРЫВЕ ПОДАЧИ	7
1076	Стаття	Стаття присвячена досвіду впровадження і використання системи підтримки навчання на базі Moodle, яка створена і використовується в Одеській національній академії харчових технологій з 2014 р. Відмічається, що на даному етапі використання ця система н	2017-01-14	1076	https://doi.org/10.15673/ret.v52i4.275	ВИКОРИСТАННЯ ДИСТАНЦІЙНИХ ТЕХНОЛОГІЙ ЯК ЗАСІБ ПІДВИЩЕННЯ ЯКОСТІ НАВЧАННЯ	7
1077	Стаття	В статье описывается создание динамической библиотеки, включающей в себя функции для работы с идеальным газом. В частности, рассматривается обработка цикла, состоящего из произвольного количества точек. Показаны особенности алгоритмизации термодинами	2017-01-14	1077	https://doi.org/10.15673/ret.v52i4.274	АЛГОРИТМИЗАЦИЯ ТЕРМОДИНАМИЧЕСКИХ РАСЧЕТОВ В МАТЕМАТИЧЕСКОМ ПАКЕТЕ MAPLE C ИСПОЛЬЗОВАНИЕМ ТЕХНОЛОГИИ OPENMAPLE	7
1078	Стаття	Використовуючи основні принципи моделювання розроблено метод розрахунку річного споживання холоду систем кондиціювання повітря. Вихідними даними є: місце розташування будівлі та місцеві метеорологічні умови за даними багаторічних спостережень; розрах	2017-01-14	1078	https://doi.org/10.15673/ret.v52i4.273	МЕТОД  РОЗРАХУНКУ РІЧНОГО СПОЖИВАННЯ ХОЛОДУ СИСТЕМ КОНДИЦІЮВАННЯ ПОВІТРЯ	7
1079	Стаття	В состав дымовых газов в зависимости от вида топлива или режима горения включают множество различных соединений. Эффективным методом очистки дымовых газов является ввод в поток газов различных химических веществ. Конденсационный эжекционный фильтр пр	2017-01-14	1079	https://doi.org/10.15673/ret.v52i4.272	УСТРОЙСТВО ДЛЯ ПОДАЧИ ЖИДКОГО ХЛАДАГЕНТА В ЭЖЕКТОРНЫЙ ТЕПЛООБМЕННИК	7
1080	Стаття	Разработаны принципиальные решения испарительных водо- и воздухоохладителей прямого и непрямого типа со сниженным пределом охлаждения (по отношению к температуре мокрого термометра поступающего в охладитель воздушного потока). Насадочная часть тепло-	2017-01-14	1080	https://doi.org/10.15673/ret.v52i4.271	ИСПАРИТЕЛЬНЫЕ ОХЛАДИТЕЛИ ГАЗОВ И ЖИДКОСТЕЙ ПРЯМОГО И НЕПРЯМОГО ТИПОВ СО СНИЖЕННЫМ ПРЕДЕЛОМ ОХЛАЖДЕНИЯ	7
1081	Стаття	Приводятся результаты исследований направленных на изучение гранулометрического состава слоя сыпучего железорудного и бокситового материала, формирование которого осуществляется при использовании систем загрузки в виде вибрационного и барабанного пит	2017-01-14	1081	https://doi.org/10.15673/ret.v52i4.270	ВЛИЯНИЕ УСЛОВИЙ ФОРМИРОВАНИЯ СЫПУЧЕГО СЛОЯ ЖЕЛЕЗОРУДНЫХ И БОКСИТОВЫХ МАТЕРИАЛОВ НА КОЭФФИЦИЕНТ ТЕПЛООТДАЧИ	7
1082	Стаття	Составлены уравнения, описывающие экспериментальные данные о вязкости и теплопроводности смеси хладагентов R125/R134а. Коэффициенты этих уравнений определены методом наименьших квадратов. Уравнения отображают зависимость вязкости и теплопроводности с	2017-01-14	1082	https://doi.org/10.15673/ret.v52i4.268	ВЯЗКОСТЬ И ТЕПЛОПРОВОДНОСТЬ СМЕСИ ХЛАДАГЕНТОВ R125/R134а	7
1083	Стаття	Современная система тригенерации состоит из энергетической установки, оборудования регенерации тепла и холодильной машины. В малой энергетике она решает проблемы удаленных от центральных систем энергоснабжения населенных пунктов и независимых  малых	2017-01-14	1083	https://doi.org/10.15673/ret.v52i4.258	ЭНЕРГЕТИЧЕСКАЯ ЭФФЕКТИВНОСТЬ  АБСОРБЦИОННО-РЕЗОРБЦИОННОЙ ХОЛОДИЛЬНОЙ МАШИНЫ В СИСТЕМЕ ТРИГЕНЕРАЦИИ МАЛОЙ ЭНЕРГЕТИКИ	7
1084	Стаття	Creating a computer program to calculate microchannel air condensers to reduce design time and carrying out variant calculations. Software packages for thermophysical properties of the working substance and the coolant, the correlation equation for c	2016-08-09	1084	https://doi.org/10.15673/ret.v52i3.123	COMPUTER PROGRAM FOR CALCULATION MICROCHANNEL HEAT EXCHANGERS FOR AIR CONDITIONING SYSTEMS	7
1085	Стаття	The paper is dedicated to intellectual services provision control quality comparison by the intellectual superstructures with centralized and decentralized control principles in NGN. The necessity of three parties interests consideration, namely: ser	2016-08-09	1085	https://doi.org/10.15673/ret.v52i3.122	COMPLEX QUALITY CRITERION OF CONTROL OF THE INTELLECTUAL SERVICES PROVISION IN NGN	7
1086	Стаття	In this paper, solubility and low temperature miscibility of refrigerants R407C and R410A in four different commercial Polyolester (POE) lubricants, produced by the same company but with different ISO standard viscosity grade, are measured with the	2016-08-09	1086	https://doi.org/10.15673/ret.v52i3.121	SOLUBILITY AND MISCIBILITY OF REFRIGERANTS R407C AND R410A WITH SYNTHETIC COMPRESSOR OILS	7
1087	Стаття	This paper presents the experimental data on the kinematic viscosity of water / ethanol / propylene glycol solutions that are prospective as coolants. An experimental setup with capillary viscometers was used to measure the kinematic viscosity of sam	2016-08-09	1087	https://doi.org/10.15673/ret.v52i3.120	VISCOSITY OF TERNARY SOLUTIONS COMPOSED OF PROPYLENE GLYCOL, ETHANOL AND WATER	7
1088	Стаття	Loss control of oil products is the one of the relevant paths of saving of the fuel and energy resources play a crucial role in development of economics. Now a great many of different procedures of a choice of means of reduction of oil losses and pet	2016-08-09	1088	https://doi.org/10.15673/ret.v52i3.119	ANTICIPATED COSTEFFECTIVE EFFECT FROM APPLICATION OF THE EJECTOR HEAT EXCHANGER FOR CONDENSATION OF LIGHT FRACTION HYDROCARBON ON THE PETROLEUM STORAGE DEPOT	7
1089	Стаття	Full-scale metal solar collectors and solar collectors fabricated from polymeric materials are studied in present research. Honeycomb multichannel plates made from polycarbonate were chosen to create a polymeric solar collector. Polymeric collector i	2016-08-09	1089	https://doi.org/10.15673/ret.v52i3.118	POLYMERIC MATERIALS FOR SOLAR ENERGY UTILIZATION: A COMPARATIVE EXPERIMENTAL STUDY AND ENVIRONMENTAL ASPECTS	7
1092	Стаття	Запропоновано при розрахунку екологічної складової приведених витрат ставку податку за викиди вуглецевого газу рахувати як суму ставки за Податковим кодексом України та ставки за Кіотським протоколом. Одною з переваг сонячної, вітрової та атомної ен	2016-06-30	1092	https://doi.org/10.21691/ret.v52i2.64	УДОСКОНАЛЕННЯ МЕТОДИКИ ВИЗНАЧЕННЯ ЕКОЛОГІЧНОЇ СКЛАДОВОЇ В ТЕХНІКО-ЕКОНОМІЧНИХ РОЗРАХУНКАХ ЕНЕРГЕТИЧНИХ УСТАНОВОК	7
1093	Стаття	У роботі представлено маленький сегмент завдання енергозбереження в системах вентиляції та мікроскопічний сегмент величезної комплексної проблеми щодо раціонального використання енергії при обов'язковому зменшенні шкідливого впливу на екологію навко	2016-06-30	1093	https://doi.org/10.21691/ret.v52i2.63	ЕНЕРГОЗБЕРЕЖЕННЯ ПРИ ЕКСПЛУАТАЦІЇ ПРИПЛИВНИХ СИСТЕМ ВЕНТИЛЯЦІЇ  ТА КОНДИЦІЮВАННЯ ПОВІТРЯ	7
1094	Стаття	 В статье описана математическая модель расчета геометрических и энергетических параметров жидкостно-парового эжектора с цилиндрической камерой смешения и приведены результаты численного моделирования течения двухфазной среды в такой камере смешения	2016-06-30	1094	https://doi.org/10.21691/ret.v52i2.58	ЭКСПЕРИМЕНТАЛЬНОЕ ИССЛЕДОВАНИЕ ЖИДКОСТНО-ПАРОВОГО ЭЖЕКТОРА С ЦИЛИНДРИЧЕСКОЙ КАМЕРОЙ СМЕШЕНИЯ	7
1095	Стаття	Предложена методика прогнозирования плотности многокомпонентных хладоносителей, в состав которых входят вода, одноатомные и многоатомные спирты. Применение этой методики не требует большого объема эмпирической информации. Представлены результаты вер	2016-06-30	1095	https://doi.org/10.21691/ret.v52i2.56	ИССЛЕДОВАНИЕ ПЛОТНОСТИ БИНАРНЫХ И ТРОЙНЫХ ВОДНЫХ РАСТВОРОВ ЭТИЛЕНГЛИКОЛЯ, ПРОПИЛЕНГЛИКОЛЯ И ЭТАНОЛА	7
1096	Стаття	В статье описывается создание и использование библиотек динамической компоновки для инженерных расчетов. Рассмотрены варианты создания универсальных библиотек, также описано использование технологии OpenMaple, применимой только для математического п	2016-06-30	1096	https://doi.org/10.21691/ret.v52i2.53	СОЗДАНИЕ И ИСПОЛЬЗОВАНИЕ БИБЛИОТЕК ДИНАМИЧЕСКОЙ КОМПОНОВКИ В  ИНЖЕНЕРНЫХ РАСЧЕТАХ	7
1097	Стаття	В роботі представлено розробку параболоциліндричного сонячного нагрівача, призначеного для приготування та розігріву харчових продуктів, з використанням сонячної енергії. Конструкція  складається з рефлектора, у вигляді параболоциліндричної лінзи, і	2016-06-30	1097	https://doi.org/10.21691/ret.v52i2.52	ПЕРЕНОСНИЙ ПАРАБОЛОЦИЛІНДРИЧНИЙ СОНЯЧНИЙ НАГРІВАЧ ХАРЧОВИХ  ПРОДУКТІВ	7
1098	Стаття	В статье рассматриваются особенности технологической подготовки предприятия (ТПП) в условиях виртуального предприятия (ВП) энергетического машиностроения. Основными путями развития технологической подготовки предприятия является комплексная автомати	2016-06-30	1098	https://doi.org/10.21691/ret.v52i2.50	МУЛЬТИАГЕНТНАЯ СИСТЕМА ТЕХНОЛОГИЧЕСКОЙ ПОДГОТОВКИ ВИРТУАЛЬНОГО ПРЕДПРИЯТИЯ	7
1099	Стаття	В статье рассмотрены герметичные криохирургические аппараты, работающие на твердом этиловом спирте. Приведены уравнения, определяющие тепловые потоки, проходящие от замораживаемого объекта через криозонд (медный стержень) к жидкому и, далее, к тверд	2016-06-30	1099	https://doi.org/10.21691/ret.v52i2.95	КРИОХИРУРГИЧЕСКИЕ АППАРАТЫ, РАБОТАЮЩИЕ НА ЭТИЛОВОМ СПИРТЕ	7
1100	Стаття	Компресорна холодильна машина з приводом від турбіни за єдиною робочою речовиною з холодильною, входить до класифікаційної групи тепловикористальних. Розвиток машин пов'язано з використанням R744. Розглянуто прямий цикл машини за двома схемними ріше	2016-06-30	1100	https://doi.org/10.21691/ret.v52i2.94	АНАЛІЗ ХАРАКТЕРИСТИК ПРЯМОГО ЦИКЛУ ТЕПЛОВИКОРИСТАЛЬНОЇ  КОМПРЕСОРНОЇ МАШИНИ З R744	7
1101	Стаття	Разработаны схемные решения тепло-массообменных аппаратов (ТМА) с подвижной псевдоожиженной насадкой (ПН) «газ-жидкоть-твердое тело» для испарительного охлаждения сред (ИО) (испарительные охладители непрямого типа, воды НИОж и воздуха НИОг) и многоф	2016-06-30	1101	https://doi.org/10.21691/ret.v52i2.62	РАЗРАБОТКА МНОГОФУНКЦИОНАЛЬНЫХ АБСОРБЦИОННЫХ СОЛНЕЧНЫХ СИСТЕМ НА ОСНОВЕ ТЕПЛОМАССООБМЕННЫХ АППАРАТОВ С ПОДВИЖНОЙ НАСАДКОЙ	7
1102	Стаття	Выполнен обзор теплообменного оборудования рекуперативного типа для подогрева топливного газа в газотурбинных двигателях на основе утилизации тепла системы смазки. Рассмотрены конструктивные решения, обеспечивающие безопасную работу оборудования и и	2016-06-30	1102	https://doi.org/10.21691/ret.v52i2.60	ГАЗОМАСЛЯНЫЙ УТИЛИЗАЦИОННЫЙ ТЕПЛООБМЕННИК В СИСТЕМЕ СМАЗКИ  ГАЗОТУРБИННОГО ДВИГАТЕЛЯ	7
1104	Стаття	В статье автор акцентирует внимание на серии важных вопросов, связанных с экономической эффективностью энергетического сектора промышленности. Применение эжекторных теплообменников лежит в основе качественного использования контактного теплообмена.	2016-06-30	1104	https://doi.org/10.21691/ret.v52i2.49	НАУЧНО-ТЕХНОЛОГИЧЕСКИЕ ОСНОВЫ СОЗДАНИЯ ЭЖЕКТОРНЫХ ТЕПЛООБМЕННИКОВ И ИХ ПРИМЕНЕНИЕ В РАЗЛИЧНЫХ СИСТЕМАХ	7
1105	Стаття	Проведено экспериментальное исследование установки на двухкомпонентной смеси этана и изобутана. В результате прямых измерений было установлено, что в рекуперативном теплообменнике экспериментальной установки имелись две области, в которых температур	2016-06-30	1105	https://doi.org/10.21691/ret.v52i2.48	ЭКСПЕРИМЕНТАЛЬНОЕ ИССЛЕДОВАНИЕ ХОЛОДИЛЬНОЙ УСТАНОВКИ, РАБОТАЮЩЕЙ НА НЕАЗЕОТРОПНОЙ СМЕСИ ХОЛОДИЛЬНЫХ АГЕНТОВ	7
1106	Стаття	В статье приведено описание экспериментальной установки, методика проведения эксперимента и обработки данных полученных на адиабатном калориметре, который реализует метод непосредственного нагрева. В работе приведены экспериментальные данные о тепло	2016-06-28	1106	https://doi.org/10.21691/ret.v52i1.47	ВЛИЯНИЕ ПРИМЕСЕЙ НАНОЧАСТИЦ Al2O3 НА ТЕПЛОЕМКОСТЬ ИЗОПРОПИЛОВО-ГО СПИРТА	7
1107	Стаття	The theoretical equation of state for solid methane, developed within the framework of perturbation theory, with the crystal consisting of spherical molecules as zero-order approximation, and octupole – octupole interaction of methane molecules as a	2016-06-28	1107	https://doi.org/10.21691/ret.v52i1.46	LOW-TEMPERATURE EQUATION OF STATE OF SOLID METHANE	7
1108	Стаття	Получены экспериментальные данные о плотности и вязкости смесей синтетического смазочного масла ISO 10 с хладоном R134а в диапазоне температур от 273 до 353 K и при массовой концентрации масла от 0,7 до 1. Вязкость смесей масло-хладон в жидкой фазе	2016-06-28	1108	https://doi.org/10.21691/ret.v52i1.45	ИСПОЛЬЗОВАНИЕ МОДИФИЦИРОВАННОЙ МОДЕЛИ ТВЕРДЫХ СФЕР ДЛЯ РАСЧЕТА ВЯЗКОСТИ СМЕСЕЙ МАСЛО-ХЛАДОН	7
1109	Стаття	В работе приведены результаты исследования кинетики сушки плотного слоя зерновых материалов в микроволновом поле. Показано, что изменения влагосодержания и температуры во времени соответствуют кривым, характерным для сушки коллоидных капиллярно-пори	2016-06-28	1109	https://doi.org/10.21691/ret.v52i1.44	КИНЕТИКА СУШКИ ЗЕРНОВЫХ МАТЕРИАЛОВ В МИКРОВОЛНОВОМ ПОЛЕ	7
1110	Стаття	З використанням спеціально розробленого програмного забезпечення проведено чисельне дослідження впливу параметрів ультразвукової кавітації на потік тепла, спрямованого через переріз капіляра, зануреного в рідину, якщо кавітація збуджена під каналом	2016-06-28	1110	https://doi.org/10.21691/ret.v52i1.43	ВИЗНАЧЕННЯ ОПТИМАЛЬНИХ УМОВ ФОРМУВАННЯ ПОТОКУ ТЕПЛА В АКУСТИЧ-НОМУ ПОЛІ НА ПЕРЕРІЗІ КАПІЛЯРА	7
1111	Стаття	Анализ энергосбережения тепловыми потоками ограждений, базирующийся на теории Фурье и утвержденный ДБН «Тепловая изоляция зданий» постулатами: - о постоянстве термического сопротивления; - о замкнутости  слоев, пересекаемых потоком между поверхностя	2016-06-28	1111	https://doi.org/10.21691/ret.v52i1.41	ЭВОЛЮЦИЯ СИСТЕМАТИЗАЦИИ ПОТЕРЬ ТЕПЛА В МНОГОСЛОЙНОМ ОГРАЖДЕ-НИИ СОГЛАСНО ДБН В.2.6-31:2006 ПРИ ЭКСПЛУАТАЦИИ	7
1112	Стаття	В статті наведено результати дослідження енерго-ресурсозберігаючої технології формування масивних аморфних структур. Розглянуті особливості процесів тепломасообміну  при утворенні в розплаві додаткових активних центрів охолодження, локальних теплост	2016-06-28	1112	https://doi.org/10.21691/ret.v52i1.40	МЕТОД ОТРИМАННЯ АМОРФНОЇ СТРУКТУРИ	7
1113	Стаття	Обоснована общая концепция построения САУ для повышения эффективности процесса производства искусственного холода в АХП, предполагающая переход от позиционных к непрерывным (квазинепрерывным) алгоритмам управления и реализацию новых функций управлен	2016-06-28	1113	https://doi.org/10.21691/ret.v52i1.35	СИСТЕМЫ АВТОМАТИЧЕСКОГО УПРАВЛЕНИЯ ДЛЯ ПОВЫШЕНИЯ ЭФФЕКТИВНОСТИ АБСОРБЦИОННЫХ ХОЛОДИЛЬНЫХ ПРИБОРОВ	7
1114	Стаття	Рассмотрен вопрос выбора угла наклона солнечного коллектора с точки зрения максимума переданной теплоты потребителю в зависимости от длительности эксплуатации солнечной установки в течение года на примере юга Украины. На основании данных по инсоляци	2016-06-28	1114	https://doi.org/10.21691/ret.v52i1.37	ОПРЕДЕЛЕНИЕ ОПТИМАЛЬНОГО УГЛА НАКЛОНА СОЛНЕЧНОГО КОЛЛЕКТОРА В ЗАВИСИМОСТИ ОТ ДЛИТЕЛЬНОСТИ РАБОТЫ В ТЕЧЕНИЕ ГОДА	7
1115	Стаття	Разработаны схемные решения тепло-массообменных аппаратов с подвижной псевдоожиженной насадкой «газ-жидкость-твердое тело» для испарительного охлаждения сред (испарительные охладители воды – градирни и охладители воздуха) и многофункциональных солне	2016-06-28	1115	https://doi.org/10.21691/ret.v52i1.36	ЭКСПЕРИМЕНТАЛЬНЫЕ ИССЛЕДОВАНИЯ ГИДРО-АЭРОДИНАМИКИ И ТЕПЛОМАССООБМЕНА В АППАРАТАХ С ПОДВИЖНОЙ ПСЕВДООЖИЖЕННОЙ НАСАДКОЙ	7
1116	Стаття	To improve the mechanical design of the piston Stirling gas refrigeration machine the structural optimization of rotary vane Stirling gas refrigeration machine is carried out. This paper presents the results of theoretical research. Analysis and pro	2016-06-28	1116	https://doi.org/10.21691/ret.v52i1.34	THE STIRLING GAS REFRIGERATING MACHINE MECHANICAL DESIGN IMPROVING	7
1117	Стаття	Каскадная холодильная машина  – комплекс одноступенчатых циклов-каскадов с разными рабочими веществами. Приведен способ термодинамического анализа каскадных машин, в которых цикл верхнего каскада реализуется в надкритической области рабочим вещество	2016-06-28	1117	https://doi.org/10.21691/ret.v52i1.32	ТЕРМОДИНАМИЧЕСКИЙ АНАЛИЗ КАСКАДНЫХ ХОЛОДИЛЬНЫХ МАШИН С R744 В ВЕРХНЕМ КАСКАДЕ	7
1118	Стаття	Результати роботи стосуються холодильної установки рефрижераторного контейнера і  спрямовані на розв’язання задачі конвективного теплообміну навколо трубчатого випарника із вентилятором примусового обдування, які розташовано в металевому кожусі. Пос	2016-06-28	1118	https://doi.org/10.21691/ret.v52i1.31	МОДЕЛЮВАННЯ ЗАДАЧІ КОНВЕКТИВНОГО ТЕПЛООБМІНУ З ПОВЕРХНІ ВИПАР-НИКА ХОЛОДИЛЬНОЇ УСТАНОВКИ РЕФРИЖЕРАТОРНОГО КОНТЕЙНЕРА	7
\.


--
-- TOC entry 2956 (class 0 OID 16918)
-- Dependencies: 210
-- Data for Name: publications_authors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.publications_authors (id_publication_author, id_publication, id_author) FROM stdin;
0	0	0
2	2	2
3	2	3
4	2	4
5	2	5
6	2	6
7	3	7
8	4	8
9	4	9
10	5	10
11	5	11
12	5	12
13	6	13
14	6	5
15	6	6
16	6	16
17	6	17
18	6	18
19	7	19
20	8	20
21	8	7
22	9	22
23	10	7
24	10	20
25	11	25
26	11	26
27	11	27
28	12	28
29	12	29
30	12	30
31	13	31
32	14	32
33	15	33
34	15	34
35	15	35
36	15	36
37	16	37
38	16	38
39	16	39
40	16	40
41	16	41
42	16	42
43	17	43
44	18	44
45	18	45
46	18	46
47	18	47
48	19	48
49	19	49
50	20	5
51	20	13
52	20	6
53	20	16
54	20	17
55	20	18
56	21	56
57	21	57
58	21	58
59	22	59
60	22	60
61	22	61
62	23	62
63	23	63
64	24	64
65	24	65
66	25	19
67	25	67
68	26	68
69	26	69
70	26	70
71	27	71
72	27	12
73	28	73
74	28	74
75	29	75
76	29	76
77	29	77
78	30	78
79	30	79
80	31	80
81	31	81
82	31	82
83	31	83
84	31	32
85	32	85
86	32	86
87	32	87
88	32	88
89	33	89
90	33	90
91	33	91
92	33	92
93	34	93
94	34	94
95	34	95
96	34	96
97	35	97
98	35	98
99	35	99
100	35	100
101	35	101
102	36	102
103	36	103
104	36	104
105	37	105
106	37	106
107	37	107
108	37	108
109	38	109
110	38	110
111	38	111
112	38	112
113	39	10
114	39	11
115	39	115
116	40	75
117	40	76
118	40	77
119	41	119
120	41	120
121	42	121
122	42	111
123	42	112
124	43	28
125	43	125
126	44	126
127	44	127
128	44	128
129	45	129
130	45	130
131	46	131
132	46	132
133	47	133
134	47	134
135	47	135
136	48	80
137	48	83
138	49	138
139	50	139
140	51	140
141	51	141
142	52	142
143	52	143
144	52	111
145	52	145
146	53	146
147	53	147
148	53	148
149	54	9
150	54	150
151	54	151
152	55	152
153	55	153
154	55	154
155	56	33
156	56	156
157	56	34
158	56	36
159	57	159
160	57	160
161	57	161
162	57	162
163	58	163
164	58	164
165	58	164
166	59	166
167	59	167
168	59	12
169	60	25
170	60	170
171	60	171
172	61	36
173	61	173
174	62	174
175	62	175
176	63	176
177	64	177
178	64	178
179	64	179
180	64	180
181	65	181
182	65	182
183	65	183
184	65	184
185	65	185
186	65	186
187	66	187
188	66	188
189	66	189
190	67	190
191	67	191
192	68	192
193	68	193
194	69	194
195	69	111
196	69	134
197	70	197
198	70	198
199	70	199
200	71	200
201	71	201
202	72	202
203	72	203
204	73	204
205	73	205
206	73	206
207	74	176
208	75	208
209	75	209
210	75	210
211	76	28
212	76	212
213	76	213
214	77	214
215	77	215
216	77	216
217	78	217
218	78	218
219	79	219
220	80	139
221	81	221
222	81	222
223	82	223
224	82	224
225	82	225
226	83	226
227	83	227
228	83	228
229	84	229
230	84	230
231	84	231
232	85	131
233	85	233
234	85	132
235	86	235
236	86	236
237	86	237
238	87	238
239	87	239
240	88	240
241	88	241
242	88	242
243	89	243
244	90	59
245	90	61
246	91	246
247	91	247
248	91	248
249	92	249
250	92	250
251	93	251
252	93	252
253	93	253
254	94	254
255	94	255
256	95	19
257	95	257
258	96	258
259	96	259
260	96	260
261	96	102
262	97	262
263	97	263
264	97	105
265	98	265
266	98	266
267	98	267
268	99	268
269	99	269
270	100	210
271	100	209
272	100	208
273	101	102
274	101	274
275	101	104
276	102	276
277	103	177
278	103	178
279	103	179
280	103	180
281	104	281
282	104	282
283	104	283
284	104	284
285	105	223
286	106	286
287	106	287
288	106	287
289	107	22
290	107	290
291	108	197
292	108	198
293	108	111
294	109	294
295	109	295
296	110	193
297	110	297
298	111	243
299	112	299
300	112	189
301	113	301
302	114	302
303	114	303
304	114	304
305	114	305
306	114	306
307	115	28
308	115	308
309	116	309
310	116	310
311	117	311
312	117	312
313	118	176
314	119	111
315	119	235
316	119	199
317	120	317
318	121	318
319	121	319
320	121	320
321	122	321
322	123	322
323	123	59
324	123	59
325	124	325
326	125	326
327	126	327
328	126	61
329	127	329
330	128	330
331	128	331
332	129	22
333	130	333
334	130	334
335	130	335
336	131	336
337	131	337
338	132	338
339	133	339
340	133	340
341	134	341
342	135	342
343	136	343
344	136	344
345	137	345
346	138	223
347	138	224
348	138	225
349	139	349
350	140	350
351	140	351
352	141	352
353	141	353
354	142	262
355	142	263
356	142	356
357	142	357
358	143	189
359	144	359
360	144	360
361	145	361
362	145	362
363	145	363
364	145	364
365	146	365
366	146	366
367	147	367
368	148	368
369	148	369
370	149	370
371	149	371
372	150	372
373	150	373
374	150	374
375	150	375
376	151	376
377	151	377
378	152	376
379	152	379
380	153	380
381	153	381
382	154	382
383	155	383
384	155	384
385	156	385
386	157	386
387	157	387
388	157	388
389	157	389
390	158	368
391	159	368
392	159	369
393	160	393
394	160	394
395	160	395
396	160	396
397	161	393
398	161	398
399	161	399
400	161	400
401	162	401
402	163	402
403	163	403
404	164	404
405	164	385
406	165	406
407	165	407
408	166	363
409	166	409
410	166	410
411	166	411
412	167	380
413	167	413
414	168	414
415	168	415
416	169	416
417	169	417
418	170	418
419	170	419
420	170	420
421	171	421
422	171	389
423	171	423
424	171	424
425	172	410
426	172	364
427	172	427
428	172	428
429	173	429
430	173	430
431	173	431
432	174	432
433	174	433
434	174	434
435	175	435
436	176	436
437	176	437
438	177	438
439	177	439
440	177	440
441	178	441
442	178	442
443	178	443
444	178	444
445	179	445
446	179	446
447	180	418
448	180	448
449	181	449
450	182	368
451	183	421
452	183	452
453	183	453
454	184	454
455	184	433
456	184	456
457	185	410
458	185	458
459	185	459
460	186	438
461	186	439
462	186	440
463	187	463
464	187	464
465	187	465
466	188	362
467	188	361
468	188	468
469	189	469
470	189	470
471	190	372
472	190	389
473	190	473
474	191	474
475	191	475
476	191	476
477	192	477
478	192	478
479	193	479
480	193	384
481	193	481
482	194	368
483	194	483
484	195	484
485	195	485
486	196	421
487	196	389
488	196	424
489	197	410
490	197	427
491	197	428
492	198	393
493	198	493
494	199	494
495	199	495
496	200	496
497	201	433
498	201	432
499	201	499
500	202	368
501	202	501
502	203	502
503	204	503
504	204	504
505	204	505
506	205	506
507	205	507
508	206	504
509	206	509
510	207	510
511	207	511
512	208	512
513	208	513
514	208	514
515	209	367
516	210	421
517	210	389
518	210	518
519	211	494
520	211	520
521	211	521
522	212	418
523	212	523
524	213	524
525	214	525
526	215	404
527	215	470
528	216	528
529	217	445
530	218	372
531	218	531
532	219	532
533	220	477
534	220	478
535	221	401
536	222	536
537	222	389
538	222	538
539	223	510
540	223	540
541	224	541
542	224	542
543	224	543
544	225	474
545	225	545
546	225	546
547	225	547
548	226	510
549	226	549
550	227	494
551	227	551
552	228	442
553	228	443
554	229	359
555	229	555
556	230	556
557	230	557
558	231	421
559	231	559
560	232	510
561	232	561
562	233	416
563	234	563
564	234	564
565	235	565
566	236	368
567	237	386
568	238	536
569	238	569
570	239	570
571	239	571
572	239	572
573	240	430
574	241	574
575	241	389
576	241	576
577	242	421
578	242	389
579	242	579
580	243	580
581	244	504
582	244	503
583	245	510
584	246	368
585	247	439
586	247	586
587	248	362
588	248	361
589	248	468
590	249	367
591	250	404
592	250	470
593	250	593
594	251	594
595	251	595
596	252	596
597	253	597
598	254	598
599	255	416
600	255	600
601	256	368
602	257	372
603	257	603
604	258	496
605	259	528
606	259	606
607	260	506
608	261	540
609	262	429
610	262	430
611	262	431
612	263	612
613	263	613
614	264	368
615	265	477
616	265	616
617	266	617
618	266	618
619	266	619
620	267	620
621	268	621
622	268	432
623	268	433
624	269	624
625	270	625
626	270	626
627	271	627
628	272	463
629	273	629
630	273	594
631	274	594
632	274	632
633	275	454
634	276	433
635	276	410
636	276	636
637	277	410
638	277	433
639	278	445
640	279	627
641	280	641
642	280	642
643	280	643
644	281	644
645	281	645
646	282	646
647	283	594
648	283	595
649	284	594
650	284	650
651	285	651
652	286	652
653	287	541
654	287	525
655	288	655
656	289	627
657	289	657
658	290	542
659	290	659
660	291	368
661	292	545
662	292	662
663	293	594
664	293	664
665	294	665
666	294	666
667	295	429
668	295	430
669	296	363
670	296	670
671	297	671
672	298	672
673	298	477
674	298	674
675	299	675
676	300	414
677	300	677
678	301	678
679	302	679
680	302	680
681	303	420
682	304	393
683	305	683
684	306	368
685	307	685
686	307	686
687	307	687
688	308	688
689	308	689
690	309	690
691	309	691
692	309	692
693	309	693
694	310	694
695	310	695
696	311	696
697	311	697
698	311	698
699	311	699
700	311	700
701	312	701
702	312	702
703	313	703
704	313	704
705	314	705
706	314	706
707	315	707
708	315	708
709	315	709
710	316	710
711	316	711
712	317	712
713	317	713
714	317	714
715	318	715
716	318	716
717	319	717
718	319	718
719	320	719
720	320	720
721	320	721
722	321	722
723	321	723
724	321	724
725	321	725
726	322	726
727	322	727
728	323	728
729	324	729
730	325	730
731	325	731
732	325	732
733	325	733
734	326	734
735	326	735
736	326	736
737	326	737
738	326	738
739	327	739
740	327	732
741	328	741
742	328	742
743	328	743
744	329	744
745	329	745
746	329	746
747	330	747
748	330	748
749	330	749
750	331	750
751	331	751
752	331	752
753	332	753
754	332	754
755	332	755
756	333	756
757	334	757
758	334	758
759	335	759
760	335	760
761	335	761
762	335	762
763	336	763
764	336	764
765	336	765
766	337	766
767	337	767
768	337	768
769	338	769
770	338	770
771	338	771
772	339	772
773	339	773
774	339	774
775	340	775
776	340	776
777	340	777
778	340	778
779	341	779
780	342	780
781	343	781
782	344	782
783	344	783
784	344	784
785	345	785
786	345	759
787	346	787
788	347	788
789	347	789
790	348	790
791	348	791
792	348	792
793	349	793
794	349	794
795	350	795
796	351	796
797	351	797
798	352	798
799	352	799
800	352	800
801	353	759
802	353	782
803	353	803
804	354	804
805	354	805
806	354	768
807	354	807
808	354	808
809	355	809
810	356	810
811	356	811
812	356	812
813	357	813
814	358	796
815	358	797
816	359	816
817	360	817
818	361	790
819	362	819
820	363	820
821	363	821
822	364	780
823	365	823
824	366	824
825	367	825
826	368	826
827	368	827
828	369	828
829	370	829
830	371	830
831	372	831
832	373	832
833	374	833
834	375	785
835	376	766
836	377	836
837	378	837
838	379	838
839	380	839
840	381	831
841	382	766
842	382	768
843	383	785
844	384	844
845	385	779
846	386	831
847	387	810
848	388	848
849	388	797
850	389	850
851	389	851
852	390	852
853	391	853
854	391	854
855	391	855
856	392	831
857	393	819
858	393	769
859	393	859
860	394	860
861	394	861
862	394	862
863	395	863
864	395	864
865	395	865
866	396	866
867	397	867
868	397	868
869	398	869
870	398	870
871	399	871
872	399	872
873	400	873
874	401	874
875	402	875
876	403	876
877	404	877
878	405	785
879	405	879
880	406	880
881	406	805
882	407	852
883	408	883
884	408	884
885	408	885
886	409	886
887	409	887
888	410	886
889	410	889
890	411	890
891	412	891
892	412	892
893	412	861
894	412	894
895	412	895
896	413	831
897	414	897
898	415	898
899	415	899
900	415	900
901	415	901
902	416	902
903	416	903
904	416	904
905	417	905
906	418	906
907	418	907
908	418	908
909	418	909
910	418	910
911	419	911
912	419	912
913	420	913
914	420	914
915	420	915
916	420	916
917	421	917
918	421	918
919	421	919
920	422	920
921	422	921
922	422	922
923	423	923
924	423	924
925	423	925
926	423	926
927	424	927
928	424	928
929	424	929
930	424	930
931	425	931
932	425	932
933	425	933
934	425	934
935	425	935
936	426	936
937	426	937
938	427	938
939	427	939
940	427	934
941	428	941
942	428	942
943	429	943
944	429	944
945	429	945
946	430	946
947	430	947
948	431	948
949	431	929
950	432	941
951	432	951
952	432	952
953	433	953
954	433	954
955	433	955
956	434	956
957	434	957
958	435	958
959	435	959
960	435	960
961	436	961
962	436	962
963	436	963
964	437	964
965	437	965
966	437	966
967	437	967
968	438	968
969	438	969
970	438	970
971	438	971
972	439	972
973	439	973
974	439	974
975	439	975
976	440	971
977	440	977
978	440	970
979	440	979
980	440	980
981	441	981
982	441	982
983	441	983
984	442	984
985	442	985
986	442	986
987	442	987
988	442	988
989	443	989
990	443	990
991	443	991
992	443	992
993	443	993
994	443	994
995	444	995
996	444	996
997	444	997
998	445	998
999	445	999
1000	446	1000
1001	447	1001
1002	447	1002
1003	448	1003
1004	448	1004
1005	448	1005
1006	448	1006
1007	448	1007
1008	449	1008
1009	449	1009
1010	450	1010
1011	450	1011
1012	451	1012
1013	451	1013
1014	451	1014
1015	451	1015
1016	452	1016
1017	452	1017
1018	452	1018
1019	452	1019
1020	453	1020
1021	453	1021
1022	454	1022
1023	454	1023
1024	454	1011
1025	455	1025
1026	455	1023
1027	456	1027
1028	456	996
1029	456	1029
1030	457	1030
1031	457	1031
1032	457	1032
1033	457	1033
1034	457	1034
1035	458	1035
1036	458	1036
1037	459	1037
1038	459	1038
1039	459	1039
1040	460	1040
1041	460	1041
1042	460	1042
1043	461	1043
1044	461	1044
1045	462	1045
1046	462	1046
1047	463	1047
1048	463	1048
1049	463	1049
1050	464	1050
1051	464	1051
1052	464	1052
1053	465	1053
1054	465	1054
1055	465	1055
1056	466	1056
1057	466	1057
1058	467	1058
1059	467	1059
1060	467	1060
1061	468	1061
1062	468	1062
1063	469	1063
1064	469	965
1065	469	1065
1066	469	1066
1067	470	1067
1068	470	1068
1069	470	1069
1070	470	1070
1071	470	1071
1072	471	1072
1073	471	1073
1074	471	1070
1075	471	1075
1076	471	1076
1077	472	1067
1078	472	1078
1079	472	1079
1080	472	1073
1081	472	1081
1082	473	1067
1083	473	1079
1084	473	1084
1085	473	1085
1086	474	1086
1087	474	1087
1088	474	1088
1089	475	1089
1090	476	1072
1091	476	1073
1092	476	1092
1093	477	1093
1094	477	1094
1095	477	1095
1096	478	819
1097	478	1097
1098	478	1098
1099	479	1099
1100	480	1100
1101	480	1101
1102	481	1102
1103	481	810
1104	481	1104
1105	482	1105
1106	482	1106
1107	483	1107
1108	483	1058
1109	483	1059
1110	484	1110
1111	484	1111
1112	484	1070
1113	484	1113
1114	485	1086
1115	486	1115
1116	486	1116
1117	486	1117
1118	487	1115
1119	487	1119
1120	488	1115
1121	488	1121
1122	488	1122
1123	489	1123
1124	490	1124
1125	490	1125
1126	491	1126
1127	492	1125
1128	492	1124
1129	493	1125
1130	493	1124
1131	494	1131
1132	494	672
1133	494	1133
1134	495	1134
1135	496	1135
1136	496	1136
1137	496	1137
1138	496	1138
1139	497	1139
1140	498	1135
1141	498	1141
1142	499	1067
1143	499	1143
1144	499	1144
1145	500	1145
1146	500	1146
1147	500	1147
1148	501	1148
1149	502	1149
1150	502	1150
1151	502	1104
1152	503	1152
1153	503	1153
1154	503	1093
1155	504	1155
1156	505	1156
1157	505	1157
1158	506	1158
1159	507	1159
1160	507	1160
1161	508	1161
1162	509	1162
1163	509	1163
1164	510	1164
1165	510	1138
1166	510	1166
1167	510	1167
1168	511	1168
1169	511	1169
1170	512	1170
1171	512	1171
1172	513	1172
1173	513	1146
1174	513	1174
1175	513	1175
1176	514	1176
1177	514	1177
1178	515	1178
1179	515	1179
1180	516	825
1181	517	1181
1182	517	1182
1183	518	1183
1184	519	1184
1185	519	1185
1186	519	1186
1187	520	819
1188	520	1110
1189	520	1189
1190	520	1190
1191	520	1191
1192	520	1192
1193	521	1193
1194	521	1194
1195	521	1195
1196	522	1196
1197	522	1197
1198	522	967
1199	523	971
1200	523	1200
1201	523	1201
1202	524	1202
1203	524	1203
1204	525	1204
1205	525	1205
1206	525	1038
1207	526	1207
1208	527	1208
1209	527	1209
1210	527	1210
1211	527	1211
1212	527	1212
1213	528	1213
1214	528	1021
1215	529	964
1216	529	1216
1217	530	1217
1218	531	1218
1219	531	1219
1220	532	1040
1221	532	1042
1222	533	1222
1223	533	1223
1224	533	1224
1225	534	898
1226	534	1226
1227	534	1227
1228	534	1228
1229	535	996
1230	535	1230
1231	535	1231
1232	536	1197
1233	536	1233
1234	536	969
1235	537	1235
1236	537	1236
1237	537	1237
1238	538	1238
1239	538	1239
1240	539	918
1241	539	1241
1242	539	1242
1243	539	1243
1244	540	1047
1245	540	1245
1246	540	1246
1247	540	1247
1248	540	1048
1249	541	1012
1250	541	1014
1251	541	1251
1252	541	1015
1253	542	1010
1254	542	1011
1255	543	1011
1256	543	1023
1257	543	1257
1258	543	1258
1259	544	1259
1260	544	1260
1261	545	898
1262	545	900
1263	545	1227
1264	546	1264
1265	546	1265
1266	547	1266
1267	547	932
1268	547	1268
1269	547	1269
1270	548	1270
1271	548	1271
1272	548	1272
1273	549	1273
1274	549	1274
1275	549	1275
1276	549	1276
1277	550	1277
1278	550	1278
1279	550	1279
1280	551	1280
1281	551	1247
1282	551	1049
1283	551	1245
1284	551	1284
1285	551	1285
1286	552	1286
1287	552	1287
1288	552	1288
1289	552	1289
1290	553	1290
1291	553	1291
1292	554	1292
1293	555	1293
1294	555	1294
1295	555	1295
1296	555	1296
1297	556	1297
1298	556	1298
1299	556	1299
1300	556	1300
1301	556	1301
1302	557	1302
1303	557	1303
1304	558	1304
1305	558	1305
1306	559	1304
1307	559	1305
1308	559	1308
1309	559	1309
1310	560	1310
1311	560	1311
1312	560	1312
1313	561	1313
1314	562	1314
1315	562	1315
1316	562	1316
1317	562	1317
1318	563	1318
1319	564	1319
1320	564	1320
1321	564	1321
1322	564	1322
1323	564	1323
1324	564	1324
1325	565	1325
1326	565	1326
1327	565	1327
1328	565	1328
1329	566	1329
1330	566	1330
1331	566	1331
1332	567	1325
1333	567	1326
1334	567	1327
1335	567	1328
1336	568	1336
1337	569	1337
1338	570	1338
1339	571	1339
1340	572	1340
1341	572	1341
1342	572	1342
1343	573	1343
1344	573	1344
1345	573	1345
1346	574	1346
1347	575	1347
1348	575	1348
1349	575	1349
1350	576	1347
1351	576	1348
1352	576	1352
1353	577	1353
1354	578	1354
1355	578	1355
1356	579	1356
1357	579	1357
1358	580	1358
1359	581	1359
1360	581	1360
1361	582	1361
1362	582	1362
1363	582	1363
1364	582	1364
1365	582	1365
1366	583	1305
1367	583	1367
1368	584	1368
1369	584	1369
1370	584	1370
1371	584	1371
1372	585	1372
1373	585	1373
1374	586	1374
1375	586	964
1376	586	1376
1377	587	1377
1378	588	1378
1379	588	1379
1380	588	1380
1381	588	1381
1382	589	1379
1383	589	1383
1384	589	1384
1385	589	1385
1386	589	1378
1387	589	1380
1388	589	1381
1389	589	1389
1390	590	1354
1391	590	1391
1392	590	1392
1393	590	1393
1394	591	1394
1395	591	1395
1396	592	1396
1397	592	1397
1398	593	1398
1399	594	1399
1400	595	1400
1401	595	1311
1402	595	1402
1403	595	1403
1404	596	1404
1405	596	1405
1406	596	1406
1407	596	1407
1408	597	1408
1409	597	1380
1410	597	1410
1411	597	1381
1412	597	1389
1413	597	1413
1414	598	1313
1415	598	1304
1416	598	1416
1417	599	1304
1418	599	1418
1419	599	1416
1420	599	1420
1421	600	1369
1422	600	1422
1423	600	1399
1424	600	1424
1425	600	1425
1426	601	1426
1427	601	1427
1428	601	1428
1429	601	1429
1430	601	1430
1431	601	1431
1432	602	1427
1433	602	1433
1434	602	1426
1435	602	1435
1436	602	1436
1437	603	1435
1438	603	1427
1439	603	1433
1440	604	1440
1441	604	1441
1442	605	1442
1443	605	1300
1444	605	1298
1445	605	1445
1446	606	1446
1447	606	1447
1448	606	1448
1449	607	1449
1450	607	1450
1451	607	1451
1452	607	1452
1453	608	1453
1454	608	1454
1455	609	1453
1456	609	1454
1457	610	1454
1458	610	1458
1459	611	1459
1460	612	1460
1461	612	1461
1462	613	1462
1463	613	1463
1464	614	1464
1465	614	1465
1466	614	1466
1467	614	1467
1468	614	1468
1469	614	1469
1470	615	1470
1471	615	1311
1472	615	1472
1473	616	1473
1474	616	1311
1475	617	1475
1476	617	1476
1477	617	1477
1478	618	1478
1479	618	1479
1480	618	1480
1481	619	1464
1482	619	1465
1483	620	1483
1484	620	1484
1485	620	1485
1486	621	1483
1487	621	1487
1488	621	1488
1489	622	1489
1490	622	1490
1491	623	1491
1492	624	1318
1493	624	1493
1494	625	1494
1495	626	1495
1496	626	1496
1497	626	1497
1498	627	1498
1499	628	1346
1500	628	1500
1501	628	1501
1502	629	1502
1503	629	1503
1504	630	1504
1505	631	1454
1506	631	1458
1507	632	1507
1508	632	1389
1509	632	1509
1510	633	1330
1511	633	1329
1512	634	1512
1513	634	1513
1514	635	1514
1515	635	1515
1516	635	1516
1517	635	1517
1518	636	1318
1519	636	1519
1520	637	1520
1521	638	1521
1522	638	1522
1523	638	1523
1524	638	1524
1525	639	1354
1526	639	1526
1527	639	1527
1528	640	1527
1529	641	1475
1530	641	1530
1531	642	1374
1532	643	1532
1533	643	1533
1534	644	1534
1535	644	1535
1536	644	1536
1537	645	1222
1538	646	1538
1539	647	1539
1540	647	1540
1541	647	1541
1542	648	1542
1543	648	1543
1544	649	1544
1545	649	1545
1546	650	1546
1547	650	1547
1548	650	1548
1549	651	911
1550	651	1550
1551	651	1551
1552	652	1552
1553	652	1553
1554	652	1554
1555	652	1555
1556	653	1556
1557	653	1557
1558	654	1552
1559	654	1559
1560	654	1560
1561	655	1561
1562	655	1562
1563	656	1563
1564	656	1564
1565	657	905
1566	658	1566
1567	659	1567
1568	660	1568
1569	661	1569
1570	661	902
1571	662	1571
1572	662	1572
1573	662	1573
1574	663	1574
1575	663	1572
1576	663	1576
1577	664	1577
1578	664	1003
1579	664	1579
1580	665	927
1581	665	929
1582	665	1582
1583	666	966
1584	667	1584
1585	667	1585
1586	668	1586
1587	668	1587
1588	668	1588
1589	669	1589
1590	670	1590
1591	670	1591
1592	670	1592
1593	671	1593
1594	671	1011
1595	671	1595
1596	672	1596
1597	672	1597
1598	672	1598
1599	672	1599
1600	672	1600
1601	673	1601
1602	673	1010
1603	673	1011
1604	674	1604
1605	674	1605
1606	674	1606
1607	675	1607
1608	675	1608
1609	675	1025
1610	675	1610
1611	676	1611
1612	676	1277
1613	676	1009
1614	676	1614
1615	676	1615
1616	676	1616
1617	676	1617
1618	676	1618
1619	677	1619
1620	677	1620
1621	677	1621
1622	677	1622
1623	677	1623
1624	677	1624
1625	678	1586
1626	678	1626
1627	679	1012
1628	679	1212
1629	679	1014
1630	680	1630
1631	680	1631
1632	681	1632
1633	681	1633
1634	682	1208
1635	682	1209
1636	682	1210
1637	682	1637
1638	682	1211
1639	682	1212
1640	683	1213
1641	683	1641
1642	684	969
1643	684	1643
1644	685	964
1645	685	1200
1646	685	1646
1647	685	1647
1648	686	971
1649	686	1649
1650	686	1355
1651	686	1651
1652	687	1037
1653	687	1038
1654	687	1205
1655	688	1655
1656	688	1656
1657	688	1657
1658	688	1658
1659	688	1659
1660	689	1660
1661	689	1661
1662	690	1662
1663	690	1663
1664	690	1664
1665	690	1665
1666	691	1666
1667	691	1023
1668	691	1668
1669	692	996
1670	692	1043
1671	692	1671
1672	692	1672
1673	693	1673
1674	693	1674
1675	694	1675
1676	695	1257
1677	695	1011
1678	695	1023
1679	695	1022
1680	696	1680
1681	696	1681
1682	696	1611
1683	696	1683
1684	696	1265
1685	697	1280
1686	697	1247
1687	697	1285
1688	697	1245
1689	697	1284
1690	697	1690
1691	698	1691
1692	699	1692
1693	699	1693
1694	700	1694
1695	701	1695
1696	701	1696
1697	702	1697
1698	703	1698
1699	704	1699
1700	704	1700
1701	705	1701
1702	706	1702
1703	707	1703
1704	708	1704
1705	709	1705
1706	709	1706
1707	710	1707
1708	710	1708
1709	711	1709
1710	711	1710
1711	712	1711
1712	713	1712
1713	713	1713
1714	714	1714
1715	714	1715
1716	714	1716
1717	715	1717
1718	715	1718
1719	716	1719
1720	716	1720
1721	716	1721
1722	717	1722
1723	718	1723
1724	719	1700
1725	720	1725
1726	721	1726
1727	721	1727
1728	722	1698
1729	723	1729
1730	724	1730
1731	724	1731
1732	725	1720
1733	725	1733
1734	726	1734
1735	726	1735
1736	726	1736
1737	727	1737
1738	727	1738
1739	728	1739
1740	728	1740
1741	728	1741
1742	729	1742
1743	729	1743
1744	730	1712
1745	731	1698
1746	732	1715
1747	733	1717
1748	733	1718
1749	734	1749
1750	734	1750
1751	735	1751
1752	735	1752
1753	736	1726
1754	736	1727
1755	737	1755
1756	738	1756
1757	739	1757
1758	740	1758
1759	741	1759
1760	742	1760
1761	742	1761
1762	743	1762
1763	744	1763
1764	744	1764
1765	744	1765
1766	745	1766
1767	745	1767
1768	745	1768
1769	745	1769
1770	745	1770
1771	746	1771
1772	746	1772
1773	746	1773
1774	746	1774
1775	747	1775
1776	747	1776
1777	747	1777
1778	747	1778
1779	747	1779
1780	747	1780
1781	748	1781
1782	748	1782
1783	748	1783
1784	748	1784
1785	749	1785
1786	749	1786
1787	749	1787
1788	749	1788
1789	749	1789
1790	750	1790
1791	750	1791
1792	750	1792
1793	750	1793
1794	751	1794
1795	751	1795
1796	751	1796
1797	751	1797
1798	751	1798
1799	751	1799
1800	752	1800
1801	752	1801
1802	752	1802
1803	752	1803
1804	753	1804
1805	753	1805
1806	754	1806
1807	754	1807
1808	754	1808
1809	754	1809
1810	754	1810
1811	755	1811
1812	755	1812
1813	755	1813
1814	755	1814
1815	755	1815
1816	756	1816
1817	756	1817
1818	756	1818
1819	756	1819
1820	756	1820
1821	757	1821
1822	757	1822
1823	757	1823
1824	757	1824
1825	757	1825
1826	758	1826
1827	758	1827
1828	758	1828
1829	758	1829
1830	759	1830
1831	759	1831
1832	759	1832
1833	760	1833
1834	761	193
1835	761	1835
1836	761	297
1837	761	1837
1838	761	1838
1839	762	1839
1840	762	145
1841	762	1841
1842	763	1842
1843	763	1843
1844	764	1844
1845	764	1845
1846	764	1846
1847	764	1847
1848	765	1848
1849	765	1849
1850	765	1850
1851	765	1851
1852	766	1852
1853	766	1853
1854	766	1854
1855	766	1855
1856	767	1790
1857	767	1857
1858	767	1858
1859	767	1859
1860	768	1860
1861	768	1861
1862	768	1862
1863	768	1817
1864	768	1797
1865	769	1865
1866	769	1866
1867	769	1867
1868	769	1868
1869	769	1869
1870	770	1870
1871	770	1871
1872	771	1828
1873	771	1827
1874	771	1874
1875	771	1875
1876	772	1876
1877	772	1877
1878	772	1878
1879	772	1879
1880	772	1880
1881	773	1881
1882	773	1882
1883	773	1883
1884	774	1884
1885	774	1885
1886	774	1886
1887	774	510
1888	774	1888
1889	775	1889
1890	775	1890
1891	775	1891
1892	776	1892
1893	776	1893
1894	777	1894
1895	777	1895
1896	777	1896
1897	778	1897
1898	778	1898
1899	778	1899
1900	779	1900
1901	779	1901
1902	779	1902
1903	779	1786
1904	780	1904
1905	780	1812
1906	780	1906
1907	780	1907
1908	781	1908
1909	781	1909
1910	781	1910
1911	781	1911
1912	782	1912
1913	782	1913
1914	782	1914
1915	782	1915
1916	783	1916
1917	783	1917
1918	783	1829
1919	783	1919
1920	784	1839
1921	784	1921
1922	784	1922
1923	784	1923
1924	784	1924
1925	785	1925
1926	785	1926
1927	785	1927
1928	785	1928
1929	785	1929
1930	786	1930
1931	787	1931
1932	787	1932
1933	787	1933
1934	788	1934
1935	788	1772
1936	788	1936
1937	788	1937
1938	789	1938
1939	789	1939
1940	789	1940
1941	789	1941
1942	790	1942
1943	790	1943
1944	790	1944
1945	790	1945
1946	790	1946
1947	791	1947
1948	792	1948
1949	792	1881
1950	792	1882
1951	793	1951
1952	793	1952
1953	793	1953
1954	794	1794
1955	794	1796
1956	794	1798
1957	794	1795
1958	794	1958
1959	795	1959
1960	795	1960
1961	795	1926
1962	795	1962
1963	795	1929
1964	796	1876
1965	796	1965
1966	796	1877
1967	796	1880
1968	796	1878
1969	797	1969
1970	797	1970
1971	797	1971
1972	797	1972
1973	798	1973
1974	799	1974
1975	799	1975
1976	799	1976
1977	799	1977
1978	800	1978
1979	800	1869
1980	800	1867
1981	801	1981
1982	801	1982
1983	801	1983
1984	801	1947
1985	802	1897
1986	802	1881
1987	802	1987
1988	803	1848
1989	803	1851
1990	803	1990
1991	803	1990
1992	803	1992
1993	804	1993
1994	804	1994
1995	804	1995
1996	805	1870
1997	805	1997
1998	805	1871
1999	805	1999
2000	806	2000
2001	806	2001
2002	806	2002
2003	806	2003
2004	806	2004
2005	807	2005
2006	807	2006
2007	807	2007
2008	807	2008
2009	807	2009
2010	808	1900
2011	808	1902
2012	808	1901
2013	808	1786
2014	809	2014
2015	809	2015
2016	809	2016
2017	809	2017
2018	810	2018
2019	810	1790
2020	811	2020
2021	811	2021
2022	811	2022
2023	811	2023
2024	812	2024
2025	812	1801
2026	812	2026
2027	812	2027
2028	813	2028
2029	813	2029
2030	813	2030
2031	814	2031
2032	814	2032
2033	814	2033
2034	815	2034
2035	815	1812
2036	815	2036
2037	815	2037
2038	815	2038
2039	816	2039
2040	816	2040
2041	816	2041
2042	816	2041
2043	816	2043
2044	817	2044
2045	817	2045
2046	817	308
2047	817	2047
2048	818	2048
2049	818	2049
2050	818	2050
2051	818	2051
2052	819	1897
2053	819	1881
2054	819	2054
2055	820	1884
2056	820	2056
2057	820	2057
2058	820	2058
2059	820	2059
2060	821	1794
2061	821	2061
2062	821	1795
2063	822	449
2064	822	2064
2065	822	2065
2066	823	1884
2067	823	2067
2068	823	2057
2069	823	2069
2070	823	1885
2071	824	2071
2072	824	2072
2073	824	2073
2074	825	2074
2075	825	2075
2076	825	2076
2077	825	2077
2078	826	2078
2079	826	2079
2080	826	2078
2081	827	1947
2082	827	2082
2083	828	2083
2084	828	2084
2085	829	2085
2086	829	2086
2087	829	2087
2088	829	2088
2089	830	1804
2090	830	1805
2091	830	2091
2092	830	2092
2093	831	2093
2094	831	2094
2095	831	2095
2096	832	2096
2097	832	2097
2098	832	2098
2099	832	2099
2100	832	2100
2101	832	2101
2102	832	2102
2103	833	2103
2104	833	2104
2105	833	2105
2106	834	2106
2107	834	2107
2108	834	2108
2109	835	1884
2110	835	2110
2111	835	2111
2112	835	2112
2113	836	2113
2114	836	1867
2115	836	2115
2116	836	2116
2117	837	2117
2118	837	2118
2119	838	2119
2120	838	2120
2121	838	2121
2122	839	2122
2123	839	2123
2124	839	2105
2125	840	2125
2126	841	2126
2127	841	2127
2128	841	2128
2129	842	2006
2130	842	2130
2131	842	1815
2132	842	2132
2133	843	2133
2134	843	2134
2135	843	2135
2136	843	2136
2137	844	2137
2138	844	2138
2139	844	2139
2140	844	2140
2141	845	2141
2142	845	2142
2143	845	2143
2144	845	2144
2145	846	2145
2146	846	2146
2147	847	2147
2148	847	2148
2149	847	2149
2150	847	2150
2151	848	2151
2152	848	2152
2153	848	2153
2154	848	2154
2155	849	2155
2156	849	2156
2157	849	2157
2158	849	2158
2159	850	2159
2160	850	2160
2161	851	2161
2162	851	2162
2163	852	1993
2164	852	1994
2165	852	2165
2166	853	2166
2167	853	2167
2168	854	2168
2169	854	2169
2170	854	2170
2171	855	2005
2172	855	2006
2173	855	2173
2174	856	2174
2175	856	2161
2176	856	2176
2177	857	2177
2178	858	2178
2179	858	2179
2180	858	2180
2181	859	2181
2182	860	1884
2183	860	2110
2184	860	2120
2185	860	2185
2186	861	1869
2187	861	2187
2188	862	2188
2189	862	2189
2190	863	2190
2191	863	1895
2192	863	2192
2193	863	2193
2194	864	2194
2195	864	1881
2196	865	2006
2197	865	2169
2198	865	2168
2199	866	1831
2200	866	2200
2201	867	1794
2202	867	2202
2203	867	1795
2204	868	2204
2205	868	2205
2206	868	2043
2207	869	1830
2208	869	1831
2209	869	2209
2210	870	2210
2211	871	2211
2212	872	2212
2213	872	2213
2214	872	2214
2215	873	2215
2216	873	2216
2217	874	2217
2218	874	2218
2219	875	2219
2220	875	1917
2221	875	2221
2222	876	2222
2223	876	2223
2224	876	2224
2225	877	2225
2226	877	2226
2227	877	2227
2228	878	2228
2229	878	2229
2230	878	2230
2231	879	2231
2232	880	2232
2233	880	2233
2234	880	2234
2235	881	1794
2236	881	1884
2237	881	2237
2238	881	2238
2239	882	2239
2240	883	2240
2241	883	2241
2242	884	2126
2243	884	2127
2244	884	2128
2245	885	2245
2246	886	2246
2247	886	2247
2248	886	2248
2249	887	2249
2250	888	2250
2251	888	2251
2252	888	2252
2253	888	2253
2254	889	2254
2255	889	2255
2256	889	2256
2257	889	2253
2258	889	2251
2259	890	2259
2260	890	2260
2261	890	2261
2262	890	2262
2263	891	2263
2264	891	2264
2265	891	2265
2266	892	2266
2267	892	2267
2268	892	2268
2269	892	2269
2270	893	2270
2271	894	2271
2272	894	1881
2273	895	1830
2274	895	1831
2275	896	2275
2276	896	2276
2277	896	2277
2278	897	2278
2279	898	2279
2280	899	2280
2281	899	2281
2282	900	2282
2283	900	2283
2284	900	2284
2285	900	2285
2286	900	2286
2287	901	2287
2288	901	2288
2289	901	2289
2290	902	2290
2291	902	2291
2292	903	2292
2293	903	2293
2294	903	2294
2295	903	2295
2296	903	2296
2297	904	2297
2298	904	2298
2299	905	2299
2300	905	2300
2301	905	2301
2302	905	2302
2303	906	2303
2304	906	2304
2305	906	2305
2306	906	2306
2307	907	2307
2308	907	1063
2309	907	2309
2310	908	2310
2311	908	2311
2312	909	2312
2313	909	2313
2314	909	2314
2315	909	2315
2316	910	2316
2317	910	2317
2318	910	2318
2319	911	2319
2320	911	2320
2321	911	2321
2322	912	2322
2323	912	2323
2324	912	2324
2325	913	2325
2326	913	2326
2327	913	2327
2328	914	2328
2329	915	2329
2330	915	2330
2331	915	2331
2332	916	1145
2333	916	2333
2334	916	2334
2335	917	1110
2336	917	1067
2337	917	2337
2338	917	1089
2339	918	1067
2340	919	2340
2341	919	2341
2342	919	2342
2343	920	2343
2344	920	2344
2345	920	2345
2346	920	2346
2347	920	2347
2348	920	2348
2349	921	2349
2350	921	2350
2351	921	2351
2352	922	2352
2353	922	2353
2354	922	2354
2355	922	2355
2356	922	2356
2357	923	2357
2358	923	2358
2359	923	2359
2360	924	2360
2361	925	2361
2362	925	2362
2363	925	2363
2364	925	2364
2365	926	2365
2366	926	2366
2367	926	2367
2368	926	2368
2369	926	2369
2370	926	2370
2371	927	2371
2372	927	2372
2373	927	2373
2374	928	2361
2375	928	2375
2376	928	2362
2377	928	2377
2378	929	2378
2379	929	2379
2380	929	2380
2381	930	2381
2382	930	2382
2383	930	2383
2384	930	2384
2385	931	2385
2386	931	2386
2387	931	2387
2388	932	2388
2389	933	2389
2390	933	2390
2391	933	2391
2392	933	2392
2393	934	2393
2394	934	2394
2395	934	2395
2396	935	2396
2397	935	2397
2398	935	2391
2399	935	2399
2400	936	2400
2401	937	2401
2402	937	2402
2403	937	2403
2404	937	2404
2405	938	156
2406	938	2406
2407	938	2407
2408	939	2408
2409	939	2409
2410	939	2410
2411	939	2411
2412	940	2412
2413	940	2413
2414	940	2414
2415	941	2415
2416	941	2416
2417	941	2417
2418	941	2418
2419	941	2419
2420	941	2420
2421	942	2421
2422	942	2422
2423	942	2423
2424	942	2424
2425	943	2425
2426	943	2426
2427	943	2427
2428	944	2428
2429	944	2429
2430	945	2430
2431	946	2431
2432	946	2432
2433	947	2433
2434	947	2432
2435	947	2431
2436	948	2436
2437	949	2437
2438	949	2425
2439	949	2439
2440	950	2440
2441	950	2441
2442	951	2442
2443	951	2443
2444	951	2444
2445	951	2445
2446	952	2446
2447	952	2447
2448	953	2448
2449	953	2449
2450	953	2411
2451	953	2451
2452	954	2452
2453	955	2453
2454	955	2454
2455	955	2455
2456	955	2456
2457	956	2457
2458	956	2379
2459	956	2459
2460	957	2460
2461	957	2379
2462	957	2462
2463	958	2463
2464	958	2444
2465	958	2465
2466	958	2443
2467	958	2445
2468	959	2468
2469	959	2469
2470	960	2401
2471	960	2403
2472	960	2402
2473	961	2383
2474	961	2474
2475	962	2475
2476	962	2476
2477	962	2477
2478	962	2478
2479	963	2389
2480	963	2390
2481	963	2391
2482	963	2392
2483	964	2483
2484	964	2397
2485	964	2485
2486	964	2399
2487	965	2487
2488	965	2488
2489	966	2489
2490	966	2490
2491	966	2491
2492	966	2492
2493	967	2349
2494	967	2350
2495	968	2495
2496	968	2496
2497	968	2497
2498	969	2498
2499	970	2499
2500	971	2453
2501	971	2454
2502	972	2502
2503	972	1172
2504	972	37
2505	972	56
2506	972	42
2507	972	2507
2508	973	2424
2509	973	2509
2510	974	2444
2511	974	2511
2512	974	2512
2513	974	2445
2514	974	2419
2515	974	2465
2516	975	2516
2517	975	2517
2518	976	2518
2519	977	2519
2520	977	156
2521	977	2406
2522	978	2522
2523	978	2523
2524	979	2430
2525	980	2525
2526	980	2526
2527	981	2527
2528	981	2528
2529	982	2529
2530	982	2530
2531	983	2425
2532	983	2532
2533	983	2533
2534	984	2534
2535	984	2535
2536	985	2536
2537	985	2537
2538	985	2538
2539	986	2539
2540	986	2540
2541	986	2541
2542	986	2542
2543	986	2543
2544	986	2544
2545	987	2545
2546	987	2546
2547	987	2490
2548	988	2548
2549	988	2549
2550	989	2432
2551	990	2430
2552	991	2527
2553	991	2528
2554	992	2554
2555	992	2555
2556	992	2556
2557	992	2557
2558	993	2558
2559	993	2559
2560	994	2560
2561	994	2561
2562	994	2557
2563	995	2563
2564	996	2564
2565	996	2565
2566	997	2566
2567	998	2436
2568	999	2425
2569	999	2569
2570	999	2570
2571	999	2571
2572	1000	2572
2573	1000	2573
2574	1000	2574
2575	1000	2575
2576	1001	2576
2577	1001	2577
2578	1001	2578
2579	1002	2579
2580	1002	2580
2581	1002	2581
2582	1003	2582
2583	1003	2583
2584	1003	2584
2585	1003	2585
2586	1004	2586
2587	1005	2587
2588	1006	2558
2589	1006	1053
2590	1006	2590
2591	1007	2591
2592	1008	2499
2593	1008	2593
2594	1009	2594
2595	1010	2490
2596	1011	2596
2597	1011	2425
2598	1011	2598
2599	1012	2599
2600	1012	2600
2601	1012	2601
2602	1013	2602
2603	1013	127
2604	1013	2604
2605	1014	2605
2606	1015	2436
2607	1016	2607
2608	1016	2608
2609	1016	2609
2610	1017	2610
2611	1017	2611
2612	1018	2402
2613	1018	2613
2614	1018	2476
2615	1018	2477
2616	1019	2616
2617	1020	2602
2618	1020	127
2619	1020	2604
2620	1020	2620
2621	1021	2621
2622	1022	2622
2623	1022	2623
2624	1022	2624
2625	1022	2625
2626	1023	2626
2627	1024	2627
2628	1025	2628
2629	1025	2629
2630	1025	2630
2631	1025	2631
2632	1026	2632
2633	1026	2633
2634	1026	2634
2635	1027	2635
2636	1027	2636
2637	1027	2413
2638	1027	2512
2639	1028	2639
2640	1028	2640
2641	1028	2425
2642	1029	2642
2643	1029	2643
2644	1029	2644
2645	1030	2645
2646	1030	2545
2647	1031	2647
2648	1031	2393
2649	1031	2649
2650	1032	2610
2651	1032	2651
2652	1032	2652
2653	1032	2611
2654	1032	2654
2655	1033	2655
2656	1033	2656
2657	1033	2657
2658	1034	2658
2659	1034	2659
2660	1035	2660
2661	1035	2476
2662	1035	2662
2663	1035	2663
2664	1036	2430
2665	1037	2665
2666	1038	2596
2667	1038	2425
2668	1039	2668
2669	1040	2669
2670	1040	2670
2671	1041	2671
2672	1041	2636
2673	1041	2413
2674	1042	2674
2675	1042	2675
2676	1043	2676
2677	1043	2677
2678	1043	2678
2679	1044	2679
2680	1044	2680
2681	1044	2681
2682	1045	2682
2683	1045	2683
2684	1045	2684
2685	1045	2685
2686	1046	2686
2687	1046	2687
2688	1046	2688
2689	1046	2689
2690	1047	2545
2691	1047	2422
2692	1047	2692
2693	1048	2693
2694	1048	2425
2695	1048	2596
2696	1049	2696
2697	1049	2697
2698	1050	2660
2699	1050	2662
2700	1051	2683
2701	1051	2682
2702	1051	2702
2703	1051	2685
2704	1052	2586
2705	1053	2605
2706	1053	2379
2707	1054	2707
2708	1054	2708
2709	1055	2647
2710	1055	2393
2711	1055	2711
2712	1056	2712
2713	1056	2536
2714	1056	2714
2715	1056	1868
2716	1057	2716
2717	1057	2418
2718	1057	2718
2719	1057	2719
2720	1058	2498
2721	1058	2401
2722	1059	2722
2723	1059	2723
2724	1060	2441
2725	1060	2725
2726	1060	2596
2727	1060	2727
2728	1061	2349
2729	1062	2729
2730	1063	2730
2731	1063	2659
2732	1063	2732
2733	1064	2657
2734	1064	2734
2735	1064	2735
2736	1064	2655
2737	1065	2737
2738	1065	2590
2739	1065	2739
2740	1066	2586
2741	1067	2741
2742	1068	2742
2743	1068	2743
2744	1068	2744
2745	1068	2379
2746	1069	2746
2747	1069	2747
2748	1070	2748
2749	1071	2436
2750	1072	2750
2751	1072	2751
2752	1072	2489
2753	1073	2753
2754	1073	2754
2755	1073	2755
2756	1074	2425
2757	1074	2757
2758	1075	2758
2759	1075	2669
2760	1076	99
2761	1076	2761
2762	1076	1053
2763	1077	2379
2764	1077	2764
2765	1078	2605
2766	1079	2743
2767	1079	2742
2768	1079	2744
2769	1079	2379
2770	1080	2770
2771	1080	1058
2772	1080	2317
2773	1080	2773
2774	1080	2774
2775	1081	2775
2776	1081	2675
2777	1081	2777
2778	1082	2778
2779	1082	2779
2780	1083	2660
2781	1083	2662
2782	1084	2782
2783	1085	2783
2784	1085	2784
2785	1086	2785
2786	1086	2786
2787	1087	2352
2788	1087	2788
2789	1087	2789
2790	1087	2790
2791	1087	2356
2792	1088	2792
2793	1088	2793
2794	1088	2794
2795	1088	2655
2796	1089	2796
2797	1089	2797
2798	1089	2798
2799	1089	2799
2800	1089	2800
2801	1090	2801
2802	1090	2802
2803	1090	2803
2804	1090	2348
2805	1091	2658
2806	1091	2659
2807	1091	2807
2808	1092	2808
2809	1092	2809
2810	1093	2605
2811	1093	2811
2812	1093	2379
2813	1094	2813
2814	1094	2814
2815	1095	2414
2816	1095	2816
2817	1095	2817
2818	1095	2818
2819	1095	2413
2820	1096	2379
2821	1096	2764
2822	1097	2748
2823	1098	2823
2824	1099	2824
2825	1100	2402
2826	1100	2476
2827	1100	2662
2828	1101	2770
2829	1101	2829
2830	1101	2830
2831	1101	2831
2832	1102	2832
2833	1102	2833
2834	1102	2814
2835	1102	2835
2836	1103	2836
2837	1103	2837
2838	1103	2838
2839	1104	2742
2840	1105	2840
2841	1106	2841
2842	1106	2842
2843	1106	2412
2844	1106	2413
2845	1107	2845
2846	1107	2846
2847	1108	2847
2848	1108	2848
2849	1109	2422
2850	1110	2850
2851	1110	2851
2852	1111	2436
2853	1111	2853
2854	1112	2608
2855	1112	2855
2856	1112	2856
2857	1113	2598
2858	1114	2858
2859	1114	2808
2860	1114	2860
2861	1115	2770
2862	1115	2829
2863	1115	2831
2864	1115	2864
2865	1116	2658
2866	1116	2659
2867	1116	2867
2868	1116	2807
2869	1117	2660
2870	1118	2393
2871	1118	2871
\.


--
-- TOC entry 2959 (class 0 OID 16925)
-- Dependencies: 213
-- Data for Name: publications_keywords; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.publications_keywords (id_publication_keyword, id_publication, id_keyword) FROM stdin;
0	0	0
2	2	2
3	2	3
4	2	4
5	2	5
6	2	6
7	2	7
8	3	8
9	3	9
10	3	10
11	4	11
12	4	12
13	4	13
14	4	14
15	4	15
16	5	16
17	5	17
18	5	18
19	5	19
20	5	20
21	6	21
22	6	22
23	6	23
24	6	24
25	6	25
26	6	26
27	6	27
28	6	28
29	7	29
30	7	30
31	7	31
32	7	32
33	7	33
34	8	34
35	8	35
36	8	36
37	8	37
38	8	38
39	8	39
40	8	40
41	9	41
42	9	42
43	9	43
44	9	44
45	9	45
46	9	46
47	10	35
48	10	36
49	10	37
50	10	38
51	10	39
52	10	40
53	11	53
54	11	54
55	11	55
56	11	56
57	11	57
58	11	58
59	11	59
60	12	60
61	12	61
62	12	62
63	12	63
64	13	64
65	13	65
66	13	66
67	14	67
68	14	68
69	14	69
70	14	70
71	14	71
72	15	72
73	15	73
74	15	74
75	15	75
76	15	76
77	16	77
78	16	78
79	16	79
80	16	80
81	17	43
82	17	82
83	17	83
84	17	44
85	17	85
86	17	86
87	17	87
88	18	88
89	18	89
90	18	90
91	19	91
92	19	92
93	19	93
94	19	94
95	20	21
96	20	22
97	20	23
98	20	24
99	20	25
100	20	100
101	20	27
102	20	28
103	21	103
104	21	104
105	21	105
106	21	106
107	21	107
108	21	108
109	21	109
110	21	110
111	21	111
112	21	112
113	22	113
114	22	114
115	22	115
116	22	116
117	23	117
118	23	118
119	23	119
120	23	120
121	23	121
122	23	122
123	23	123
124	24	124
125	24	125
126	24	126
127	24	11
128	25	128
129	25	129
130	25	130
131	25	131
132	25	132
133	25	133
134	25	134
135	25	14
136	25	118
137	26	137
138	26	138
139	26	139
140	26	140
141	26	141
142	27	142
143	27	143
144	27	144
145	27	145
146	28	146
147	28	147
148	28	148
149	28	149
150	28	150
151	28	151
152	28	152
153	29	153
154	29	154
155	29	155
156	29	156
157	29	157
158	30	158
159	30	159
160	30	160
161	30	161
162	31	162
163	31	163
164	31	14
165	31	165
166	31	166
167	31	29
168	31	168
169	32	169
170	32	170
171	32	171
172	32	172
173	33	173
174	33	174
175	33	175
176	33	176
177	33	177
178	33	178
179	34	179
180	34	180
181	34	181
182	34	182
183	34	183
184	35	184
185	35	185
186	35	186
187	35	187
188	35	188
189	35	189
190	35	190
191	35	191
192	35	192
193	36	193
194	36	194
195	36	195
196	37	196
197	37	197
198	37	198
199	37	199
200	37	200
201	38	201
202	38	202
203	38	203
204	38	204
205	38	205
206	38	206
207	39	207
208	39	208
209	39	16
210	39	17
211	39	18
212	40	153
213	40	154
214	40	155
215	40	215
216	40	157
217	41	217
218	41	218
219	41	219
220	41	220
221	42	169
222	42	170
223	42	223
224	42	224
225	42	225
226	43	226
227	43	61
228	43	228
229	43	229
230	43	230
231	43	231
232	43	232
233	43	233
234	43	234
235	44	235
236	44	236
237	44	237
238	44	238
239	44	239
240	44	240
241	45	241
242	45	242
243	45	243
244	45	244
245	45	245
246	45	246
247	45	247
248	45	248
249	45	249
250	46	235
251	46	251
252	46	252
253	46	253
254	46	254
255	46	255
256	47	256
257	47	257
258	47	258
259	47	259
260	47	260
261	47	261
262	47	262
263	48	263
264	48	264
265	48	265
266	49	266
267	49	267
268	49	268
269	49	269
270	50	44
271	50	271
272	50	272
273	51	273
274	51	274
275	51	275
276	51	276
277	51	277
278	51	278
279	52	279
280	52	172
281	52	202
282	52	282
283	52	283
284	52	284
285	52	285
286	53	286
287	53	287
288	53	288
289	53	289
290	53	290
291	54	291
292	54	292
293	54	293
294	54	294
295	54	295
296	54	296
297	54	297
298	55	298
299	55	299
300	55	300
301	55	301
302	56	302
303	56	303
304	56	304
305	56	305
306	56	306
307	57	307
308	57	308
309	57	309
310	57	86
311	57	194
312	57	312
313	58	313
314	58	314
315	58	315
316	58	316
317	58	317
318	58	318
319	59	319
320	59	320
321	59	321
322	59	322
323	60	323
324	60	324
325	60	325
326	60	326
327	60	327
328	61	328
329	61	329
330	61	330
331	61	331
332	61	332
333	61	333
334	61	334
335	61	335
336	62	336
337	62	86
338	62	338
339	62	339
340	63	340
341	63	42
342	63	342
343	63	343
344	63	344
345	63	345
346	63	346
347	63	43
348	63	348
349	64	349
350	64	350
351	64	351
352	64	352
353	65	353
354	65	354
355	65	355
356	65	356
357	65	357
358	65	358
359	66	359
360	66	360
361	66	361
362	66	362
363	67	363
364	67	364
365	67	365
366	67	366
367	67	367
368	67	368
369	67	369
370	67	370
371	67	371
372	68	372
373	68	373
374	68	374
375	69	375
376	69	376
377	69	377
378	69	378
379	69	379
380	69	380
381	69	381
382	69	382
383	70	383
384	70	384
385	70	385
386	70	386
387	70	387
388	71	388
389	71	389
390	71	390
391	71	391
392	71	392
393	71	393
394	71	394
395	71	395
396	71	396
397	72	397
398	72	398
399	72	399
400	72	400
401	72	401
402	74	402
403	74	403
404	74	43
405	74	405
406	74	85
407	74	194
408	74	408
409	74	409
410	75	410
411	75	411
412	75	412
413	76	413
414	76	61
415	76	230
416	76	416
417	76	417
418	76	418
419	77	419
420	77	420
421	77	421
422	78	422
423	79	423
424	79	424
425	79	425
426	79	426
427	79	427
428	80	428
429	80	429
430	80	430
431	81	431
432	81	432
433	81	433
434	81	434
435	81	329
436	81	436
437	81	437
438	82	438
439	82	439
440	82	440
441	82	441
442	83	422
443	84	443
444	84	444
445	84	445
446	84	446
447	84	305
448	84	448
449	85	449
450	85	450
451	85	451
452	86	452
453	86	453
454	86	326
455	86	455
456	87	456
457	87	457
458	87	458
459	87	459
460	88	460
461	88	461
462	88	462
463	88	463
464	88	464
465	88	465
466	88	466
467	89	423
468	89	468
469	89	469
470	89	470
471	89	471
472	89	472
473	90	473
474	90	474
475	90	475
476	90	476
477	90	477
478	91	478
479	91	479
480	91	480
481	91	481
482	91	482
483	91	483
484	91	484
485	91	485
486	92	486
487	92	487
488	92	488
489	92	489
490	92	490
491	92	491
492	93	492
493	93	335
494	93	494
495	93	495
496	93	496
497	94	497
498	94	498
499	94	499
500	94	500
501	95	501
502	95	502
503	95	503
504	95	504
505	96	505
506	96	506
507	96	507
508	96	508
509	97	509
510	97	510
511	97	511
512	97	512
513	97	513
514	97	514
515	97	515
516	98	516
517	98	517
518	98	518
519	99	519
520	99	520
521	99	521
522	99	522
523	100	523
524	100	524
525	100	525
526	101	526
527	101	527
528	101	528
529	101	529
530	102	530
531	102	531
532	102	532
533	102	533
534	102	534
535	103	535
536	103	350
537	103	351
538	103	352
539	104	539
540	104	540
541	104	541
542	104	542
543	104	543
544	105	544
545	105	545
546	105	546
547	105	547
548	105	548
549	106	549
550	106	550
551	106	551
552	106	552
553	106	553
554	106	554
555	106	555
556	106	556
557	106	557
558	107	558
559	107	559
560	107	560
561	107	561
562	107	562
563	107	563
564	107	42
565	107	565
566	107	43
567	107	567
568	108	568
569	108	569
570	108	570
571	108	571
572	108	572
573	109	573
574	109	574
575	109	114
576	109	576
577	109	577
578	109	578
579	109	194
580	109	580
581	110	581
582	110	582
583	110	583
584	110	584
585	110	585
586	110	586
587	110	587
588	110	588
589	111	423
590	111	468
591	111	469
592	111	470
593	111	471
594	111	594
595	111	595
596	111	596
597	112	597
598	112	598
599	112	599
600	112	600
601	112	194
602	113	602
603	113	603
604	113	604
605	113	605
606	113	606
607	114	607
608	114	608
609	114	609
610	114	610
611	115	611
612	115	612
613	115	613
614	115	614
615	115	615
616	115	616
617	115	617
618	116	618
619	116	619
620	116	620
621	116	621
622	116	622
623	116	623
624	117	624
625	117	625
626	117	626
627	117	627
628	117	628
629	118	629
630	118	85
631	118	565
632	118	43
633	118	633
634	118	634
635	118	194
636	119	636
637	119	637
638	119	638
639	119	639
640	120	640
641	120	60
642	120	642
643	120	643
644	120	644
645	120	645
646	120	646
647	121	647
648	121	648
649	121	649
650	121	650
651	121	651
652	121	652
653	122	653
654	122	654
655	122	655
656	122	656
657	122	657
658	122	658
659	122	659
660	122	660
661	123	661
662	123	662
663	123	172
664	123	664
665	123	60
666	124	666
667	124	667
668	124	668
669	124	669
670	124	670
671	125	443
672	125	444
673	125	445
674	125	446
675	125	305
676	125	448
677	126	677
678	126	678
679	126	679
680	126	194
681	127	681
682	127	682
683	127	683
684	127	562
685	127	685
686	127	686
687	128	687
688	128	688
689	128	689
690	128	690
691	128	691
692	129	692
693	129	693
694	129	46
695	129	695
696	129	685
697	129	697
698	130	698
699	130	699
700	130	700
701	130	701
702	130	702
703	131	703
704	131	704
705	131	705
706	132	706
707	132	707
708	132	708
709	132	709
710	132	710
711	133	711
712	133	712
713	133	713
714	133	714
715	133	715
716	133	716
717	134	717
718	134	197
719	134	719
720	134	720
721	134	721
722	134	722
723	135	723
724	135	511
725	135	725
726	136	726
727	136	727
728	136	728
729	136	729
730	137	730
731	137	731
732	137	732
733	137	733
734	138	734
735	138	735
736	138	736
737	138	737
738	138	738
739	139	739
740	139	740
741	139	741
742	139	742
743	139	733
744	139	744
745	140	745
746	140	746
747	140	747
748	140	748
749	141	749
750	141	750
751	141	751
752	141	752
753	142	753
754	142	511
755	142	755
756	142	512
757	142	513
758	142	758
759	142	759
760	142	760
761	143	761
762	143	762
763	143	763
764	143	764
765	143	765
766	143	766
767	143	767
768	144	768
769	144	769
770	144	770
771	144	771
772	145	772
773	145	773
774	145	774
775	145	775
776	145	776
777	145	777
778	146	778
779	146	779
780	146	780
781	146	781
782	146	782
783	146	783
784	146	784
785	147	785
786	147	786
787	147	787
788	147	788
789	147	789
790	148	790
791	148	777
792	148	792
793	148	793
794	148	794
795	148	795
796	148	796
797	148	797
798	149	798
799	149	799
800	149	800
801	149	801
802	149	802
803	149	803
804	150	804
805	150	805
806	150	806
807	150	807
808	150	172
809	150	809
810	151	732
811	151	811
812	151	812
813	151	813
814	151	814
815	151	815
816	152	732
817	152	817
818	152	818
819	152	819
820	152	820
821	152	821
822	153	822
823	153	823
824	153	824
825	153	825
826	153	826
827	153	827
828	154	828
829	154	829
830	154	830
831	154	831
832	154	832
833	155	833
834	155	834
835	155	835
836	155	836
837	155	837
838	156	838
839	156	839
840	156	840
841	156	841
842	156	842
843	157	843
844	157	628
845	157	845
846	158	846
847	158	847
848	158	848
849	158	849
850	158	850
851	158	851
852	158	852
853	159	853
854	159	790
855	159	855
856	159	774
857	159	857
858	159	858
859	159	859
860	160	860
861	160	861
862	160	862
863	160	863
864	160	864
865	160	865
866	160	866
867	161	867
868	161	868
869	161	869
870	161	870
871	161	871
872	161	872
873	161	873
874	161	874
875	162	875
876	162	876
877	162	877
878	162	878
879	162	879
880	162	880
881	163	881
882	163	842
883	163	883
884	163	884
885	163	885
886	163	886
887	163	887
888	163	888
889	163	889
890	163	890
891	163	891
892	163	892
893	163	893
894	163	894
895	164	895
896	164	896
897	164	897
898	165	898
899	165	899
900	165	900
901	165	901
902	165	902
903	165	903
904	165	904
905	166	905
906	166	906
907	166	907
908	166	866
909	166	197
910	167	910
911	167	911
912	167	912
913	167	913
914	167	914
915	167	915
916	168	916
917	168	917
918	168	918
919	168	919
920	168	920
921	169	921
922	169	922
923	169	923
924	169	924
925	169	925
926	169	926
927	170	927
928	170	928
929	170	929
930	170	930
931	170	931
932	171	932
933	171	933
934	171	934
935	172	935
936	172	936
937	172	937
938	172	938
939	173	939
940	173	940
941	173	941
942	173	942
943	173	943
944	173	944
945	174	945
946	174	946
947	174	947
948	174	948
949	174	949
950	174	950
951	175	951
952	175	952
953	175	953
954	175	954
955	175	955
956	175	956
957	176	957
958	176	958
959	176	959
960	176	960
961	176	961
962	176	962
963	176	963
964	176	964
965	177	910
966	177	829
967	177	967
968	177	968
969	177	969
970	177	970
971	178	971
972	178	972
973	178	973
974	178	974
975	178	975
976	179	178
977	179	977
978	179	978
979	179	979
980	179	980
981	179	951
982	180	982
983	180	983
984	180	910
985	180	985
986	180	826
987	180	774
988	180	901
989	181	989
990	181	990
991	181	991
992	181	992
993	182	956
994	182	994
995	182	995
996	182	996
997	182	997
998	183	998
999	183	999
1000	183	1000
1001	183	1001
1002	183	1002
1003	184	1003
1004	184	940
1005	184	1005
1006	184	1006
1007	184	1007
1008	185	867
1009	185	1009
1010	185	1010
1011	185	1011
1012	185	1012
1013	185	868
1014	185	1014
1015	186	1015
1016	186	1016
1017	186	967
1018	186	866
1019	186	1019
1020	187	1020
1021	187	1021
1022	187	1022
1023	187	1023
1024	188	1024
1025	188	773
1026	188	1026
1027	188	1027
1028	188	1028
1029	189	1029
1030	189	1030
1031	189	1031
1032	189	838
1033	189	1033
1034	190	1034
1035	190	1035
1036	190	1036
1037	190	1037
1038	190	1038
1039	190	1039
1040	190	1040
1041	190	1041
1042	191	1042
1043	191	1043
1044	191	1044
1045	191	1045
1046	191	1046
1047	191	1047
1048	192	1048
1049	192	1049
1050	192	1050
1051	192	1051
1052	192	161
1053	192	1053
1054	193	1054
1055	193	1055
1056	193	983
1057	193	1057
1058	193	1058
1059	193	1059
1060	194	1060
1061	194	1061
1062	194	855
1063	194	1063
1064	194	1064
1065	194	774
1066	194	1066
1067	195	1067
1068	195	1068
1069	195	1069
1070	195	901
1071	195	1071
1072	196	1072
1073	196	1073
1074	196	1074
1075	196	933
1076	196	1076
1077	196	1077
1078	196	1078
1079	197	863
1080	197	1080
1081	197	1081
1082	197	1082
1083	198	1083
1084	198	1084
1085	198	1085
1086	198	1086
1087	198	1087
1088	198	1053
1089	199	940
1090	199	871
1091	199	1051
1092	199	1092
1093	199	866
1094	199	1011
1095	199	1095
1096	199	1096
1097	200	1097
1098	200	1098
1099	200	901
1100	200	1100
1101	200	1101
1102	201	1102
1103	201	1103
1104	201	1104
1105	201	1105
1106	201	1106
1107	201	1107
1108	201	1108
1109	202	1109
1110	202	1110
1111	202	1111
1112	202	1112
1113	202	1113
1114	203	1114
1115	203	1115
1116	203	1116
1117	203	1117
1118	203	1118
1119	203	1119
1120	204	1120
1121	204	1015
1122	204	1122
1123	204	1123
1124	204	1124
1125	205	1125
1126	205	1126
1127	205	1127
1128	205	1128
1129	205	1129
1130	206	957
1131	206	1131
1132	206	1132
1133	206	1133
1134	206	1134
1135	207	1135
1136	207	1136
1137	207	1137
1138	207	1138
1139	207	1139
1140	207	1140
1141	207	1141
1142	207	1142
1143	208	1143
1144	208	1144
1145	208	1145
1146	208	1146
1147	208	1147
1148	209	787
1149	209	788
1150	209	1150
1151	209	1151
1152	209	1152
1153	209	1153
1154	210	1154
1155	210	1155
1156	210	1156
1157	210	1157
1158	211	940
1159	211	1096
1160	211	1011
1161	211	1161
1162	211	1081
1163	211	1163
1164	212	1164
1165	212	1165
1166	212	1166
1167	212	1167
1168	212	1168
1169	212	1169
1170	213	901
1171	213	1171
1172	213	1172
1173	213	1173
1174	213	1174
1175	214	985
1176	214	1176
1177	214	1177
1178	214	1178
1179	215	1179
1180	215	1180
1181	216	197
1182	216	1182
1183	216	1051
1184	216	1184
1185	217	1185
1186	217	197
1187	217	1187
1188	217	1188
1189	217	1189
1190	218	1190
1191	218	1191
1192	218	1192
1193	218	1193
1194	218	1194
1195	219	1195
1196	219	1196
1197	219	985
1198	219	1198
1199	219	1199
1200	219	1200
1201	220	1048
1202	220	1202
1203	220	1049
1204	220	1204
1205	220	1051
1206	220	161
1207	220	1053
1208	221	876
1209	221	877
1210	221	1210
1211	221	1211
1212	221	1212
1213	221	1213
1214	222	1214
1215	222	1215
1216	222	1216
1217	222	1217
1218	223	839
1219	223	1219
1220	223	1220
1221	223	1221
1222	223	1222
1223	223	1223
1224	224	1224
1225	224	1225
1226	224	1226
1227	224	1227
1228	224	1228
1229	225	1229
1230	225	1230
1231	225	1231
1232	225	1232
1233	225	1233
1234	225	1234
1235	226	1235
1236	226	1236
1237	226	1237
1238	226	1155
1239	226	1239
1240	226	1240
1241	227	1082
1242	227	906
1243	227	1243
1244	227	866
1245	227	1245
1246	228	1246
1247	228	1247
1248	228	1248
1249	228	1249
1250	228	1250
1251	228	1251
1252	228	1252
1253	228	1253
1254	228	1254
1255	229	1255
1256	229	1256
1257	229	1257
1258	229	1258
1259	229	1259
1260	230	1260
1261	230	732
1262	230	1262
1263	230	1263
1264	230	1264
1265	231	1001
1266	231	1266
1267	231	1267
1268	231	1268
1269	231	1269
1270	231	1270
1271	232	1271
1272	232	1237
1273	232	1267
1274	232	1274
1275	232	348
1276	233	1276
1277	233	1277
1278	233	1278
1279	233	1279
1280	233	1280
1281	234	1281
1282	234	1282
1283	234	1283
1284	234	1284
1285	234	1285
1286	235	1286
1287	235	1287
1288	235	1288
1289	235	42
1290	235	1290
1291	235	1151
1292	235	1292
1293	236	1293
1294	236	1294
1295	236	1295
1296	236	1296
1297	236	1297
1298	237	1298
1299	237	1299
1300	237	1300
1301	237	1301
1302	238	1302
1303	238	1303
1304	238	1304
1305	238	1305
1306	239	1306
1307	239	1307
1308	239	1308
1309	239	1309
1310	239	1310
1311	239	1311
1312	239	1312
1313	239	1313
1314	239	1314
1315	240	1315
1316	240	1316
1317	240	1317
1318	240	1318
1319	240	1319
1320	240	1320
1321	241	1321
1322	241	1322
1323	241	1323
1324	241	1324
1325	241	1325
1326	242	933
1327	242	1327
1328	242	1328
1329	243	803
1330	243	1330
1331	243	1331
1332	243	1332
1333	243	1333
1334	244	1334
1335	244	1335
1336	244	1336
1337	244	1337
1338	245	1338
1339	245	1339
1340	245	1340
1341	245	1341
1342	245	1342
1343	246	1293
1344	246	1344
1345	246	1345
1346	246	1346
1347	246	1347
1348	247	1348
1349	247	969
1350	247	772
1351	247	1351
1352	247	1352
1353	247	1353
1354	247	1354
1355	248	772
1356	248	1356
1357	248	1357
1358	248	1358
1359	248	1359
1360	248	1360
1361	249	785
1362	249	1362
1363	249	788
1364	249	1364
1365	249	1365
1366	250	1366
1367	250	1367
1368	250	1368
1369	251	1369
1370	251	1370
1371	251	1371
1372	251	1372
1373	251	1373
1374	251	1374
1375	251	1375
1376	252	785
1377	252	1377
1378	252	1378
1379	252	1379
1380	252	1380
1381	253	1381
1382	253	1382
1383	253	1383
1384	253	1384
1385	253	1385
1386	254	1386
1387	254	1387
1388	254	304
1389	254	1389
1390	254	1390
1391	255	1391
1392	255	1392
1393	255	1393
1394	255	1394
1395	256	1395
1396	256	1396
1397	256	1397
1398	256	1398
1399	256	1399
1400	257	1400
1401	257	1401
1402	257	1402
1403	257	1403
1404	257	1404
1405	257	1405
1406	258	1097
1407	258	1098
1408	258	1408
1409	258	1409
1410	258	1410
1411	258	1411
1412	259	985
1413	259	1413
1414	259	1177
1415	259	1415
1416	260	1416
1417	260	1417
1418	260	1418
1419	260	1419
1420	260	1420
1421	261	1421
1422	261	1422
1423	261	1423
1424	261	839
1425	262	1425
1426	262	1426
1427	262	1427
1428	262	1428
1429	262	1429
1430	263	1430
1431	263	1431
1432	263	1432
1433	263	1433
1434	263	1434
1435	263	1435
1436	264	1436
1437	264	1437
1438	264	1397
1439	264	1439
1440	264	1440
1441	264	1066
1442	265	1442
1443	265	1049
1444	265	1444
1445	265	1445
1446	266	1446
1447	266	985
1448	266	1448
1449	266	1449
1450	266	1450
1451	267	1451
1452	267	1452
1453	267	1453
1454	268	1454
1455	268	1455
1456	268	1456
1457	268	1457
1458	268	1458
1459	268	1459
1460	268	1460
1461	268	1461
1462	269	1462
1463	269	1463
1464	269	1464
1465	269	1465
1466	269	1466
1467	269	1467
1468	270	1468
1469	270	1469
1470	270	1470
1471	270	1471
1472	270	1472
1473	270	1473
1474	271	150
1475	271	1475
1476	271	848
1477	271	1477
1478	271	1478
1479	271	1479
1480	272	1480
1481	272	1481
1482	272	1482
1483	272	1483
1484	272	1397
1485	272	1485
1486	273	1486
1487	273	1487
1488	273	1488
1489	273	1489
1490	273	1490
1491	273	1491
1492	273	1492
1493	273	1493
1494	274	1494
1495	274	1495
1496	274	1496
1497	274	1497
1498	275	1003
1499	275	940
1500	275	1500
1501	275	1006
1502	275	1502
1503	276	1503
1504	276	1103
1505	276	1505
1506	276	1506
1507	276	1507
1508	276	1508
1509	277	1509
1510	277	1103
1511	277	1511
1512	277	940
1513	277	935
1514	278	1514
1515	278	1515
1516	278	1516
1517	278	951
1518	278	1518
1519	279	1173
1520	279	1263
1521	279	868
1522	279	1522
1523	279	848
1524	280	1524
1525	280	1525
1526	280	1526
1527	280	1527
1528	281	1528
1529	281	1529
1530	281	1530
1531	281	1531
1532	281	1532
1533	282	1533
1534	282	994
1535	282	1535
1536	282	1536
1537	282	1537
1538	282	1538
1539	283	1539
1540	283	1540
1541	283	1541
1542	283	1542
1543	283	1543
1544	283	1544
1545	284	1545
1546	284	1546
1547	284	1547
1548	284	1548
1549	284	1549
1550	284	1550
1551	284	1551
1552	285	1552
1553	285	1553
1554	285	1554
1555	286	1555
1556	286	1556
1557	286	1557
1558	286	1558
1559	286	1559
1560	287	1560
1561	287	1561
1562	287	1562
1563	287	1563
1564	288	1522
1565	288	823
1566	288	1547
1567	288	1567
1568	288	1568
1569	288	1569
1570	289	1570
1571	289	1571
1572	289	1572
1573	289	1573
1574	289	1574
1575	290	1575
1576	290	1576
1577	290	1577
1578	290	1578
1579	290	901
1580	291	1580
1581	291	1581
1582	291	1582
1583	291	1583
1584	291	1584
1585	291	1585
1586	292	1444
1587	292	161
1588	292	1588
1589	292	790
1590	292	1590
1591	292	1176
1592	293	823
1593	293	1593
1594	293	1594
1595	293	178
1596	293	1596
1597	293	1597
1598	293	31
1599	294	733
1600	294	1600
1601	294	1601
1602	294	1602
1603	296	1603
1604	296	1604
1605	296	1605
1606	297	1606
1607	297	1607
1608	297	900
1609	297	1176
1610	297	1610
1611	297	1611
1612	298	1051
1613	298	1613
1614	298	1614
1615	298	1615
1616	298	1616
1617	298	1617
1618	299	1618
1619	299	1374
1620	299	1620
1621	299	1621
1622	299	1622
1623	300	1623
1624	300	1624
1625	300	1625
1626	300	1626
1627	301	1627
1628	301	1628
1629	301	1629
1630	301	1630
1631	301	1631
1632	301	829
1633	302	1633
1634	302	1634
1635	302	1635
1636	302	1636
1637	302	1637
1638	302	1638
1639	303	1639
1640	303	935
1641	303	1641
1642	303	1522
1643	303	1643
1644	303	1644
1645	303	1645
1646	304	1173
1647	304	1647
1648	304	1648
1649	304	1649
1650	304	1650
1651	304	1651
1652	304	1652
1653	305	1196
1654	305	1654
1655	305	1614
1656	305	1656
1657	305	1536
1658	305	1658
1659	306	1659
1660	306	1580
1661	306	1437
1662	306	1662
1663	306	1663
1664	306	733
1665	306	1665
1666	307	1666
1667	307	1667
1668	307	1668
1669	307	1669
1670	307	1670
1671	308	1671
1672	308	1672
1673	308	1673
1674	308	1674
1675	308	1675
1676	309	1676
1677	309	1677
1678	309	1678
1679	310	1679
1680	310	1680
1681	310	1681
1682	310	1682
1683	310	1683
1684	311	1684
1685	311	1685
1686	311	1686
1687	311	1687
1688	311	1688
1689	311	1689
1690	311	1690
1691	312	1691
1692	312	1680
1693	312	1693
1694	312	1694
1695	313	1695
1696	313	1696
1697	313	1697
1698	313	1698
1699	313	1699
1700	313	1700
1701	313	1701
1702	314	1702
1703	314	1703
1704	314	1704
1705	314	1705
1706	314	1706
1707	315	1707
1708	315	1708
1709	315	1709
1710	315	1710
1711	315	1711
1712	316	1712
1713	316	1713
1714	316	1714
1715	316	1715
1716	316	1716
1717	316	1717
1718	316	1718
1719	317	1719
1720	317	1720
1721	317	1721
1722	317	1722
1723	317	1723
1724	317	1724
1725	318	1725
1726	318	1726
1727	318	1727
1728	318	1728
1729	318	1729
1730	319	1730
1731	319	1731
1732	319	1732
1733	319	1733
1734	319	1734
1735	320	1735
1736	320	1736
1737	320	1737
1738	320	1738
1739	320	1739
1740	320	1740
1741	320	1741
1742	320	1742
1743	321	1743
1744	321	1744
1745	321	1745
1746	321	1746
1747	321	1747
1748	321	1748
1749	322	1749
1750	322	1744
1751	322	1751
1752	322	1752
1753	322	1753
1754	322	1754
1755	322	1755
1756	322	1756
1757	322	1757
1758	322	1758
1759	323	1759
1760	323	1760
1761	323	1761
1762	323	1762
1763	323	1763
1764	323	1707
1765	323	1765
1766	323	1766
1767	324	1767
1768	324	1768
1769	324	1769
1770	325	1770
1771	325	1771
1772	325	1772
1773	325	1773
1774	325	1774
1775	325	1775
1776	325	1776
1777	326	1777
1778	326	1778
1779	326	1779
1780	326	1780
1781	327	1781
1782	327	1782
1783	327	1783
1784	327	1784
1785	327	1785
1786	328	1786
1787	328	777
1788	329	1788
1789	329	1789
1790	329	1790
1791	329	1791
1792	329	1792
1793	329	1793
1794	329	1794
1795	329	1795
1796	329	1796
1797	330	1797
1798	330	1798
1799	330	1799
1800	330	1800
1801	331	1801
1802	331	1802
1803	331	1803
1804	331	1804
1805	331	1805
1806	331	1806
1807	331	1807
1808	332	1808
1809	332	1809
1810	332	1810
1811	332	1811
1812	332	1812
1813	332	1813
1814	333	1814
1815	333	1815
1816	333	1704
1817	333	1817
1818	333	1818
1819	333	1819
1820	333	1820
1821	333	1706
1822	334	1822
1823	334	1823
1824	334	1824
1825	334	1536
1826	334	36
1827	334	1827
1828	334	37
1829	335	1829
1830	335	1830
1831	335	1831
1832	335	1832
1833	335	1833
1834	335	1834
1835	335	1835
1836	335	1836
1837	335	1837
1838	335	1838
1839	335	1839
1840	336	1840
1841	336	1841
1842	336	1842
1843	336	1843
1844	336	1844
1845	336	1845
1846	337	1846
1847	337	1847
1848	337	1848
1849	337	1849
1850	337	1850
1851	337	1851
1852	338	1852
1853	338	1853
1854	338	1854
1855	338	1855
1856	338	1856
1857	338	1857
1858	338	1858
1859	338	1859
1860	338	1860
1861	339	1861
1862	339	1862
1863	339	1863
1864	339	1864
1865	339	1865
1866	340	1866
1867	340	1867
1868	340	1868
1869	340	1869
1870	342	1870
1871	342	1871
1872	343	1872
1873	343	1873
1874	343	1874
1875	343	1875
1876	343	1876
1877	343	1877
1878	343	1878
1879	343	1879
1880	343	1880
1881	343	1881
1882	344	1882
1883	344	1785
1884	344	1884
1885	344	1885
1886	345	1886
1887	345	1887
1888	345	1888
1889	345	1889
1890	345	1890
1891	345	1891
1892	346	1892
1893	346	1893
1894	347	1894
1895	347	315
1896	347	1896
1897	347	613
1898	347	1898
1899	348	1899
1900	348	1900
1901	348	1901
1902	348	1902
1903	348	1903
1904	348	1904
1905	348	1905
1906	349	1906
1907	349	1907
1908	349	1908
1909	349	1909
1910	350	1910
1911	350	1911
1912	350	1912
1913	350	1913
1914	350	1914
1915	351	1915
1916	351	1916
1917	351	1917
1918	351	1918
1919	351	1919
1920	351	426
1921	352	1921
1922	352	1922
1923	352	1923
1924	352	1924
1925	352	1925
1926	352	1926
1927	353	1927
1928	353	1928
1929	353	1929
1930	353	1930
1931	353	1931
1932	353	1932
1933	353	1933
1934	353	1934
1935	353	1935
1936	353	1936
1937	354	1862
1938	354	1938
1939	354	1939
1940	354	1940
1941	354	1941
1942	355	1942
1943	355	1943
1944	355	1944
1945	356	1945
1946	356	1946
1947	356	1947
1948	356	1948
1949	356	1949
1950	357	422
1951	358	1951
1952	358	1706
1953	358	1953
1954	358	1954
1955	358	1955
1956	358	1956
1957	358	1957
1958	358	335
1959	359	1959
1960	359	1960
1961	359	1961
1962	359	1962
1963	359	1963
1964	359	1964
1965	360	1965
1966	360	1966
1967	360	1967
1968	360	1968
1969	360	1969
1970	361	1970
1971	361	1785
1972	361	1972
1973	361	1973
1974	361	1974
1975	361	1975
1976	361	1904
1977	361	1977
1978	361	1978
1979	361	1979
1980	361	1980
1981	362	1981
1982	362	32
1983	362	1983
1984	362	1984
1985	362	1985
1986	362	1986
1987	362	1987
1988	362	1988
1989	363	1989
1990	363	1990
1991	363	1991
1992	363	1992
1993	363	1993
1994	363	1994
1995	363	1995
1996	364	1996
1997	364	1997
1998	364	1998
1999	365	1999
2000	365	2000
2001	365	2001
2002	365	2002
2003	365	2003
2004	365	2004
2005	365	2005
2006	366	2006
2007	366	2007
2008	366	2008
2009	366	2009
2010	367	2010
2011	367	2011
2012	367	2012
2013	367	1948
2014	368	2014
2015	368	2015
2016	368	2016
2017	368	2017
2018	368	2018
2019	368	2019
2020	368	2020
2021	368	2021
2022	368	2022
2023	368	2023
2024	369	2024
2025	369	2025
2026	369	2026
2027	369	2027
2028	369	2028
2029	369	2029
2030	369	2030
2031	369	2031
2032	370	2032
2033	370	2033
2034	370	2034
2035	370	2035
2036	370	2036
2037	370	2037
2038	371	1945
2039	371	2039
2040	371	2040
2041	371	117
2042	371	2042
2043	371	2043
2044	372	1867
2045	372	2045
2046	373	2046
2047	373	468
2048	373	2048
2049	373	86
2050	373	2050
2051	374	2051
2052	375	2052
2053	375	2053
2054	375	2054
2055	375	32
2056	376	2056
2057	376	2057
2058	376	2058
2059	376	2059
2060	376	2060
2061	377	2061
2062	377	2062
2063	377	2063
2064	377	2064
2065	377	2065
2066	377	2066
2067	378	2067
2068	378	2068
2069	378	2025
2070	378	2070
2071	378	2071
2072	379	2072
2073	379	2073
2074	379	2074
2075	379	2075
2076	379	2076
2077	379	2077
2078	380	2078
2079	380	2079
2080	381	2080
2081	381	2081
2082	381	2082
2083	382	1846
2084	382	1847
2085	382	2085
2086	382	2086
2087	382	2087
2088	382	2088
2089	382	1929
2090	383	1886
2091	383	1887
2092	383	1888
2093	383	1785
2094	383	2058
2095	383	2095
2096	384	2096
2097	384	1855
2098	384	2098
2099	384	2099
2100	384	2100
2101	385	1452
2102	385	2102
2103	385	2103
2104	385	2104
2105	385	2105
2106	385	1925
2107	385	2107
2108	385	2108
2109	386	2109
2110	386	2102
2111	386	2111
2112	387	1945
2113	387	2113
2114	387	2114
2115	387	2115
2116	387	745
2117	388	1951
2118	388	1706
2119	388	2119
2120	388	2120
2121	388	2121
2122	388	807
2123	388	2123
2124	389	391
2125	389	2125
2126	389	9
2127	389	2127
2128	389	1849
2129	389	1785
2130	389	2130
2131	390	2131
2132	390	2132
2133	390	2133
2134	390	2134
2135	390	2135
2136	390	1977
2137	390	1978
2138	390	2138
2139	391	2139
2140	391	2140
2141	391	2141
2142	391	2142
2143	391	2143
2144	392	2144
2145	392	2145
2146	392	1975
2147	393	2147
2148	393	2148
2149	393	2149
2150	393	1855
2151	393	2151
2152	394	2152
2153	394	2153
2154	394	2154
2155	394	2155
2156	396	2156
2157	396	2157
2158	396	2158
2159	396	1706
2160	396	2160
2161	397	2161
2162	397	2162
2163	397	2163
2164	397	2052
2165	397	2165
2166	398	2166
2167	398	2167
2168	398	2168
2169	398	2169
2170	398	2170
2171	398	2063
2172	398	2172
2173	398	2173
2174	399	2174
2175	399	2175
2176	399	1849
2177	399	2177
2178	399	1785
2179	399	2179
2180	400	2131
2181	400	2132
2182	400	2133
2183	400	2134
2184	400	2135
2185	400	1977
2186	400	1978
2187	400	2138
2188	402	2188
2189	402	2154
2190	402	1981
2191	402	2147
2192	402	2192
2193	402	2193
2194	403	2194
2195	403	2195
2196	403	2196
2197	403	2197
2198	405	1450
2199	405	2056
2200	405	2200
2201	405	2201
2202	405	2202
2203	406	2174
2204	406	2175
2205	406	1849
2206	406	2177
2207	406	1785
2208	406	2095
2209	407	2209
2210	407	2132
2211	407	2133
2212	407	2134
2213	407	2135
2214	407	1977
2215	407	1978
2216	407	2138
2217	408	2217
2218	408	2218
2219	408	2219
2220	408	2220
2221	408	2221
2222	408	2222
2223	408	2223
2224	409	2224
2225	409	2225
2226	409	1993
2227	409	1986
2228	409	2228
2229	409	2229
2230	409	2230
2231	409	2231
2232	410	2232
2233	410	2233
2234	410	2234
2235	410	2235
2236	410	2236
2237	410	1993
2238	410	2238
2239	411	2239
2240	411	1993
2241	411	2241
2242	412	2152
2243	412	2243
2244	412	2244
2245	412	2153
2246	412	2246
2247	413	2247
2248	413	2248
2249	414	2249
2250	415	2250
2251	416	2251
2252	417	2252
2253	418	2253
2254	419	1277
2255	419	2255
2256	419	2256
2257	419	2257
2258	419	2258
2259	419	2259
2260	419	2260
2261	420	2261
2262	420	2262
2263	420	2263
2264	420	2264
2265	420	2265
2266	420	2266
2267	420	2267
2268	421	2268
2269	421	2269
2270	421	2270
2271	421	2271
2272	421	2272
2273	421	2273
2274	422	2274
2275	423	2275
2276	423	2276
2277	423	2277
2278	423	2278
2279	423	2279
2280	423	2280
2281	424	2281
2282	424	2282
2283	424	2283
2284	424	2284
2285	424	2285
2286	424	2286
2287	425	2287
2288	426	2288
2289	427	2289
2290	428	2290
2291	429	2291
2292	430	2292
2293	431	2293
2294	432	2294
2295	432	2295
2296	432	2296
2297	432	1849
2298	432	2298
2299	432	2290
2300	432	2300
2301	433	2301
2302	433	2302
2303	433	2303
2304	433	2304
2305	433	2305
2306	434	2306
2307	434	2307
2308	434	2308
2309	434	2309
2310	434	31
2311	434	2311
2312	435	2312
2313	435	2313
2314	435	2314
2315	435	2315
2316	436	2316
2317	436	2317
2318	436	772
2319	436	2154
2320	436	2320
2321	436	2250
2322	436	1904
2323	436	2323
2324	437	2273
2325	437	2325
2326	437	2326
2327	437	2327
2328	437	2328
2329	438	2329
2330	438	2330
2331	438	2331
2332	438	2332
2333	438	2333
2334	439	2233
2335	439	2335
2336	439	1905
2337	439	2337
2338	439	2249
2339	439	2339
2340	440	2340
2341	440	2341
2342	440	2342
2343	440	2343
2344	440	2344
2345	441	2327
2346	441	2346
2347	441	2347
2348	441	2348
2349	442	2349
2350	442	2350
2351	442	2351
2352	442	2352
2353	443	2353
2354	443	2354
2355	443	2233
2356	443	2356
2357	443	2357
2358	443	733
2359	443	2359
2360	443	2360
2361	444	2361
2362	444	2362
2363	444	2363
2364	444	2364
2365	445	2365
2366	445	2366
2367	445	2367
2368	445	2368
2369	445	2369
2370	445	2370
2371	445	2371
2372	446	2372
2373	446	2373
2374	446	2374
2375	446	2250
2376	447	2376
2377	447	2377
2378	447	2290
2379	447	2163
2380	447	1948
2381	448	2381
2382	448	1862
2383	448	2383
2384	448	2384
2385	448	2385
2386	448	2386
2387	449	2387
2388	449	2388
2389	449	2389
2390	449	2390
2391	449	2391
2392	450	2392
2393	450	2393
2394	450	2394
2395	450	2395
2396	450	2396
2397	451	2397
2398	451	2398
2399	451	2399
2400	451	2400
2401	451	2401
2402	451	2402
2403	451	2403
2404	452	2404
2405	452	2405
2406	452	2406
2407	452	2407
2408	452	2408
2409	453	2409
2410	453	2410
2411	453	2411
2412	453	2412
2413	453	2413
2414	453	2414
2415	453	2415
2416	454	2416
2417	454	2417
2418	454	2418
2419	454	2419
2420	454	2420
2421	455	2421
2422	455	2422
2423	455	2423
2424	455	2424
2425	455	2233
2426	455	2426
2427	456	2427
2428	456	2428
2429	456	2429
2430	456	2430
2431	457	2431
2432	457	2432
2433	458	2433
2434	458	2273
2435	458	2435
2436	458	2436
2437	458	2437
2438	459	2438
2439	459	2439
2440	459	2440
2441	459	2250
2442	459	2442
2443	459	2249
2444	459	122
2445	460	2445
2446	460	2446
2447	460	2447
2448	460	2448
2449	461	2449
2450	461	2393
2451	461	2145
2452	461	2250
2453	461	2453
2454	462	2454
2455	462	2455
2456	462	2456
2457	462	2457
2458	463	2458
2459	463	2459
2460	463	2460
2461	463	2461
2462	464	2462
2463	464	2463
2464	464	2464
2465	464	2465
2466	464	2466
2467	464	2467
2468	465	2233
2469	465	2335
2470	465	1905
2471	465	2337
2472	465	2249
2473	465	2339
2474	466	2474
2475	466	2307
2476	466	2476
2477	466	2477
2478	466	2478
2479	466	2479
2480	466	2480
2481	467	2481
2482	467	2482
2483	467	2483
2484	467	2484
2485	467	2485
2486	467	2486
2487	468	2392
2488	468	2488
2489	468	1865
2490	468	2490
2491	468	2491
2492	469	2125
2493	469	2493
2494	469	2233
2495	469	2495
2496	469	2496
2497	469	2497
2498	469	2498
2499	470	2499
2500	470	2500
2501	470	2501
2502	470	2502
2503	470	2272
2504	470	2504
2505	470	2505
2506	470	2506
2507	470	733
2508	470	2508
2509	471	2509
2510	471	2273
2511	471	2511
2512	471	2512
2513	471	2153
2514	471	2514
2515	471	2515
2516	471	2264
2517	471	2517
2518	472	2518
2519	472	2519
2520	472	2520
2521	472	2512
2522	472	2522
2523	472	2523
2524	472	2524
2525	472	2525
2526	472	2526
2527	472	2527
2528	473	2528
2529	473	2529
2530	473	2530
2531	473	2531
2532	473	2532
2533	473	2533
2534	473	2534
2535	473	2535
2536	474	2536
2537	474	1522
2538	474	2538
2539	474	1614
2540	474	2540
2541	475	2541
2542	475	2542
2543	475	2543
2544	475	2544
2545	475	2545
2546	475	2231
2547	475	2547
2548	475	2548
2549	476	2549
2550	476	2525
2551	476	2526
2552	476	2527
2553	476	2553
2554	476	2230
2555	476	2555
2556	476	2530
2557	477	2153
2558	477	2558
2559	477	2559
2560	477	2560
2561	477	2561
2562	477	2562
2563	477	2292
2564	477	970
2565	478	2565
2566	478	1983
2567	478	2393
2568	478	2568
2569	478	2569
2570	478	1986
2571	478	1987
2572	479	2572
2573	479	2280
2574	479	2278
2575	479	2575
2576	479	2576
2577	479	2577
2578	479	2578
2579	480	2579
2580	480	2580
2581	480	2581
2582	480	2582
2583	480	2255
2584	480	2584
2585	480	1796
2586	481	2349
2587	481	2587
2588	481	2588
2589	481	2531
2590	481	2590
2591	482	2361
2592	482	2592
2593	482	2593
2594	482	2594
2595	482	2595
2596	482	2596
2597	483	2597
2598	483	2598
2599	483	2599
2600	483	2600
2601	483	2601
2602	484	2602
2603	484	2603
2604	484	1530
2605	484	2605
2606	484	2606
2607	485	2607
2608	485	2608
2609	485	2609
2610	485	2292
2611	485	954
2612	486	2612
2613	486	1114
2614	486	2614
2615	486	2615
2616	487	2616
2617	487	2617
2618	487	2618
2619	487	2619
2620	487	2620
2621	488	2614
2622	488	2622
2623	488	2623
2624	488	2624
2625	488	2625
2626	489	2626
2627	489	2627
2628	489	2628
2629	489	2629
2630	489	2630
2631	489	29
2632	490	2632
2633	490	2633
2634	490	2634
2635	491	2635
2636	491	2636
2637	491	2637
2638	492	2638
2639	492	2639
2640	492	2640
2641	492	2641
2642	492	2642
2643	493	2643
2644	493	2644
2645	493	2642
2646	493	2632
2647	494	2647
2648	494	2648
2649	494	2649
2650	494	2650
2651	494	2651
2652	494	2652
2653	495	2653
2654	495	2654
2655	495	2655
2656	495	2656
2657	496	2657
2658	496	2658
2659	496	2659
2660	497	2660
2661	497	2661
2662	497	2662
2663	497	2663
2664	498	2664
2665	498	2665
2666	498	2666
2667	498	2667
2668	498	2668
2669	498	2669
2670	498	2670
2671	498	2671
2672	499	2672
2673	499	2673
2674	499	2674
2675	499	2675
2676	499	2676
2677	499	2677
2678	500	2678
2679	500	2145
2680	500	2680
2681	500	2681
2682	500	2409
2683	500	2683
2684	501	2684
2685	501	2685
2686	501	2686
2687	501	2687
2688	501	2688
2689	501	2689
2690	502	2690
2691	502	2691
2692	502	2692
2693	502	2693
2694	503	2694
2695	503	2695
2696	503	2197
2697	503	2697
2698	504	2698
2699	504	2699
2700	504	2661
2701	504	2701
2702	504	2702
2703	505	2703
2704	505	2704
2705	505	2295
2706	505	2706
2707	506	2707
2708	506	2114
2709	506	2709
2710	507	2710
2711	507	2711
2712	507	2712
2713	507	2713
2714	507	2714
2715	508	2292
2716	508	2716
2717	508	2717
2718	508	2718
2719	509	2719
2720	509	2720
2721	509	2251
2722	509	2722
2723	509	2723
2724	509	2724
2725	510	2725
2726	510	2726
2727	510	2727
2728	510	2728
2729	511	2729
2730	511	2730
2731	511	2731
2732	511	2732
2733	511	2733
2734	512	1989
2735	512	1802
2736	512	2393
2737	512	2737
2738	512	2738
2739	513	2739
2740	513	2740
2741	513	2741
2742	513	2742
2743	513	2743
2744	513	2744
2745	513	2745
2746	514	2746
2747	514	2747
2748	515	2748
2749	515	2749
2750	515	2750
2751	515	2751
2752	515	2752
2753	516	2753
2754	516	1849
2755	516	1851
2756	516	1785
2757	516	1929
2758	516	2758
2759	517	2759
2760	517	2760
2761	517	1905
2762	517	2762
2763	517	2763
2764	518	2764
2765	518	2765
2766	518	2766
2767	518	2767
2768	518	2768
2769	519	2769
2770	519	1276
2771	519	2771
2772	519	2772
2773	519	2773
2774	520	2774
2775	520	2775
2776	520	2292
2777	520	2777
2778	521	2778
2779	521	2779
2780	521	2780
2781	521	2781
2782	521	2782
2783	522	733
2784	522	2784
2785	522	2785
2786	522	2786
2787	522	2787
2788	522	2788
2789	523	2789
2790	523	2790
2791	523	2791
2792	523	2792
2793	524	2793
2794	524	2794
2795	524	2250
2796	524	2796
2797	524	2797
2798	524	2798
2799	524	2799
2800	524	2800
2801	525	2801
2802	525	2802
2803	525	2787
2804	525	2250
2805	525	2805
2806	526	2806
2807	526	2807
2808	526	2808
2809	526	2809
2810	526	2810
2811	527	29
2812	527	2812
2813	527	2813
2814	527	2814
2815	527	2815
2816	527	2816
2817	528	2817
2818	528	2409
2819	528	2819
2820	528	2410
2821	528	2821
2822	528	2822
2823	529	2823
2824	529	2824
2825	529	2825
2826	529	2826
2827	529	2827
2828	529	2828
2829	530	2829
2830	530	2830
2831	530	2831
2832	531	2832
2833	531	2833
2834	531	2145
2835	531	2835
2836	531	2836
2837	532	2445
2838	532	2446
2839	532	2447
2840	532	2840
2841	533	2841
2842	533	2842
2843	533	2843
2844	533	2844
2845	533	2845
2846	533	2846
2847	534	2847
2848	534	2848
2849	534	2250
2850	535	2850
2851	535	2851
2852	535	2852
2853	535	2853
2854	535	2854
2855	535	2855
2856	536	2856
2857	536	2857
2858	536	2858
2859	536	2859
2860	536	2860
2861	537	2412
2862	537	2862
2863	537	2863
2864	537	2864
2865	537	2249
2866	537	2339
2867	537	2867
2868	537	2868
2869	538	2869
2870	538	2870
2871	538	2871
2872	538	2872
2873	539	2326
2874	539	2325
2875	539	2875
2876	539	2250
2877	539	2877
2878	540	2878
2879	540	2262
2880	540	2880
2881	540	2881
2882	541	2882
2883	541	2883
2884	541	2398
2885	541	2885
2886	541	2886
2887	541	29
2888	541	123
2889	541	2889
2890	541	2890
2891	542	2891
2892	542	2892
2893	542	2893
2894	542	2801
2895	543	2895
2896	543	2464
2897	543	2446
2898	543	2898
2899	544	2899
2900	544	2900
2901	544	2901
2902	544	2902
2903	544	2903
2904	544	2904
2905	545	2905
2906	545	2906
2907	545	2250
2908	545	2908
2909	546	2909
2910	546	2910
2911	546	2911
2912	546	2912
2913	547	2913
2914	547	2914
2915	547	2915
2916	547	2916
2917	547	2917
2918	547	2918
2919	548	2919
2920	548	2920
2921	548	2921
2922	548	2922
2923	548	17
2924	548	2924
2925	549	2925
2926	549	2867
2927	549	2927
2928	550	2928
2929	550	2929
2930	550	2930
2931	550	2390
2932	551	2932
2933	551	2933
2934	551	2934
2935	551	2935
2936	552	2936
2937	552	2937
2938	552	2938
2939	553	2939
2940	553	2851
2941	553	2250
2942	553	2881
2943	553	2943
2944	553	2944
2945	553	2945
2946	554	2909
2947	554	2947
2948	554	2948
2949	555	2949
2950	555	2410
2951	556	2951
2952	556	2871
2953	556	2953
2954	557	2817
2955	557	2955
2956	557	2956
2957	557	2957
2958	558	2362
2959	558	2819
2960	558	2960
2961	558	2961
2962	558	2962
2963	559	2250
2964	559	2913
2965	559	2965
2966	559	2966
2967	559	2967
2968	559	2968
2969	559	2969
2970	560	2913
2971	560	2971
2972	560	122
2973	560	2973
2974	561	2815
2975	561	2960
2976	561	2819
2977	562	2977
2978	562	2978
2979	562	2979
2980	562	2980
2981	563	2981
2982	563	2982
2983	563	2983
2984	564	2984
2985	564	2985
2986	564	2986
2987	564	2987
2988	565	2988
2989	565	2989
2990	565	2391
2991	566	2991
2992	566	2992
2993	566	2993
2994	566	2930
2995	566	400
2996	567	2996
2997	567	2997
2998	567	2988
2999	567	2989
3000	567	2391
3001	568	3001
3002	568	3002
3003	568	3003
3004	568	3004
3005	568	3005
3006	569	2361
3007	569	2250
3008	569	3008
3009	569	2733
3010	569	2163
3011	570	2930
3012	570	3012
3013	570	3013
3014	570	3014
3015	570	3015
3016	571	3016
3017	571	3017
3018	571	3018
3019	571	3019
3020	572	2445
3021	572	2815
3022	572	2881
3023	572	3001
3024	573	2410
3025	573	3025
3026	573	3026
3027	573	3027
3028	574	3028
3029	574	3029
3030	574	2349
3031	574	3031
3032	574	3032
3033	574	3033
3034	575	3034
3035	575	3035
3036	575	3036
3037	576	3037
3038	576	3038
3039	576	3039
3040	576	1450
3041	577	3041
3042	577	3042
3043	577	3043
3044	577	3044
3045	577	3045
3046	577	3046
3047	578	3047
3048	578	2823
3049	578	3049
3050	578	2410
3051	578	3051
3052	579	3052
3053	579	3053
3054	579	3054
3055	579	3055
3056	580	3056
3057	580	3057
3058	580	3058
3059	580	3059
3060	581	3060
3061	581	3061
3062	581	3062
3063	581	3063
3064	582	3064
3065	582	2909
3066	582	3066
3067	582	3067
3068	583	2250
3069	583	3069
3070	583	3070
3071	584	3071
3072	584	3072
3073	584	3073
3074	584	3074
3075	584	2930
3076	585	3076
3077	585	3077
3078	585	3078
3079	585	2993
3080	586	3080
3081	586	3081
3082	586	3082
3083	586	2826
3084	586	3084
3085	587	2249
3086	587	3086
3087	587	3087
3088	588	2815
3089	588	3089
3090	588	3090
3091	588	3091
3092	589	3092
3093	589	2881
3094	589	3094
3095	589	3095
3096	590	3096
3097	590	3081
3098	590	2792
3099	591	3099
3100	591	3100
3101	591	3101
3102	592	3102
3103	592	3103
3104	592	3104
3105	592	3105
3106	592	3106
3107	593	2815
3108	593	2145
3109	593	2514
3110	593	3110
3111	593	3111
3112	593	3112
3113	593	3113
3114	594	3114
3115	594	2250
3116	594	3116
3117	594	3117
3118	595	2687
3119	595	2426
3120	595	2250
3121	595	130
3122	595	123
3123	595	3123
3124	596	745
3125	596	3125
3126	596	3126
3127	596	3127
3128	597	2815
3129	597	3129
3130	597	2454
3131	597	2812
3132	597	3132
3133	597	3133
3134	597	3134
3135	597	3135
3136	597	3136
3137	598	2250
3138	598	2271
3139	598	2250
3140	598	3140
3141	598	2276
3142	599	3142
3143	599	2250
3144	599	3144
3145	600	3145
3146	600	2991
3147	600	3147
3148	601	3148
3149	601	3149
3150	601	3150
3151	601	3151
3152	601	3152
3153	601	3153
3154	602	2250
3155	602	3155
3156	602	3151
3157	602	3152
3158	602	3158
3159	602	3159
3160	603	2250
3161	603	3161
3162	603	3162
3163	603	3152
3164	603	3158
3165	603	2250
3166	604	2823
3167	604	2825
3168	604	3168
3169	604	3169
3170	604	2344
3171	604	3171
3172	604	3172
3173	605	2445
3174	605	2729
3175	605	3175
3176	605	3176
3177	605	2871
3178	606	3178
3179	606	3179
3180	606	3180
3181	606	123
3182	606	3182
3183	606	3183
3184	606	3184
3185	607	3185
3186	607	3186
3187	608	3187
3188	608	3188
3189	608	3189
3190	609	3187
3191	609	3188
3192	609	3192
3193	610	3193
3194	610	3194
3195	610	3195
3196	610	3196
3197	611	3197
3198	611	2871
3199	611	3199
3200	611	3200
3201	611	3201
3202	611	3202
3203	611	3203
3204	612	3204
3205	612	3205
3206	612	3206
3207	612	3207
3208	613	3208
3209	613	2448
3210	613	3210
3211	614	3211
3212	614	3212
3213	614	3213
3214	614	3214
3215	615	3215
3216	615	3216
3217	615	122
3218	615	3218
3219	616	3219
3220	616	3180
3221	616	3184
3222	616	2454
3223	617	3223
3224	617	3212
3225	617	3225
3226	617	3226
3227	617	3227
3228	618	3228
3229	618	3229
3230	618	3230
3231	618	3231
3232	618	3232
3233	618	132
3234	618	2251
3235	618	3235
3236	619	3236
3237	619	3237
3238	619	3238
3239	619	3239
3240	619	3240
3241	620	3241
3242	620	3242
3243	620	3243
3244	620	2801
3245	621	2417
3246	621	123
3247	621	3247
3248	621	3248
3249	622	3249
3250	622	2983
3251	622	2911
3252	622	3252
3253	622	3253
3254	623	3254
3255	623	3255
3256	623	3256
3257	623	2412
3258	623	2911
3259	624	2981
3260	624	3260
3261	625	2871
3262	625	3262
3263	625	3263
3264	625	2153
3265	625	3126
3266	625	3266
3267	625	3267
3268	626	2412
3269	626	3269
3270	626	3270
3271	626	2991
3272	626	2626
3273	627	3273
3274	627	3274
3275	627	3275
3276	627	3276
3277	627	3277
3278	627	3278
3279	627	399
3280	628	3280
3281	628	3281
3282	628	3282
3283	628	3283
3284	629	3284
3285	629	2789
3286	629	3286
3287	629	3287
3288	629	3288
3289	629	3289
3290	630	3290
3291	630	3291
3292	630	2658
3293	630	3293
3294	630	3294
3295	630	3295
3296	630	2445
3297	631	3194
3298	631	3298
3299	631	3196
3300	632	3300
3301	632	2882
3302	632	2885
3303	632	2886
3304	632	29
3305	632	123
3306	633	2410
3307	633	2904
3308	633	2412
3309	633	3309
3310	633	3310
3311	634	3311
3312	634	3312
3313	634	3313
3314	634	3314
3315	634	1352
3316	635	3316
3317	635	3317
3318	635	3318
3319	635	3319
3320	635	3140
3321	635	2353
3322	635	3322
3323	636	3323
3324	636	2904
3325	637	3325
3326	637	3326
3327	637	3327
3328	637	3328
3329	637	3329
3330	637	3330
3331	637	3331
3332	638	3332
3333	638	3333
3334	638	123
3335	638	2886
3336	639	2862
3337	639	2412
3338	639	3338
3339	639	3339
3340	640	3340
3341	640	3341
3342	640	3342
3343	640	3343
3344	640	3344
3345	641	3345
3346	641	3346
3347	641	1965
3348	641	3348
3349	642	3349
3350	642	2827
3351	642	2412
3352	642	3352
3353	642	3353
3354	642	3354
3355	643	3193
3356	643	3195
3357	643	3192
3358	643	3358
3359	644	3359
3360	644	3252
3361	644	3253
3362	644	3362
3363	644	3363
3364	644	3364
3365	645	3365
3366	645	2410
3367	645	2823
3368	645	2330
3369	646	3369
3370	646	3370
3371	646	3371
3372	646	2330
3373	647	3373
3374	647	3374
3375	647	3375
3376	647	3376
3377	647	3377
3378	647	2789
3379	648	3379
3380	648	3380
3381	648	3381
3382	648	3382
3383	649	3383
3384	649	3384
3385	649	3385
3386	649	3386
3387	650	3387
3388	650	2330
3389	651	3389
3390	651	1277
3391	651	3391
3392	651	3392
3393	652	2232
3394	652	2531
3395	652	3395
3396	652	2525
3397	652	3397
3398	652	2526
3399	652	2230
3400	652	2555
3401	653	3401
3402	653	3402
3403	653	3403
3404	653	3404
3405	653	2603
3406	654	2672
3407	654	3407
3408	654	957
3409	654	2526
3410	654	2527
3411	654	3411
3412	654	3412
3413	654	2525
3414	654	3414
3415	654	2316
3416	655	2935
3417	655	3417
3418	655	3418
3419	655	3419
3420	655	3420
3421	656	3421
3422	656	3422
3423	656	3423
3424	656	3424
3425	656	2562
3426	657	3426
3427	657	3427
3428	657	3428
3429	657	3429
3430	658	2209
3431	658	2132
3432	658	2135
3433	658	1977
3434	658	1978
3435	658	3435
3436	658	2175
3437	658	3437
3438	658	3438
3439	658	2133
3440	659	3440
3441	659	3441
3442	659	3442
3443	660	2292
3444	660	2716
3445	660	3445
3446	660	2718
3447	661	3447
3448	661	3448
3449	661	3449
3450	661	3450
3451	661	3451
3452	662	2759
3453	662	3453
3454	662	3454
3455	662	3455
3456	662	3456
3457	662	3457
3458	662	2555
3459	663	2759
3460	663	3460
3461	663	2272
3462	663	2760
3463	663	1983
3464	663	1905
3465	664	2538
3466	664	3466
3467	664	3158
3468	664	2906
3469	665	3469
3470	665	3470
3471	665	3471
3472	665	3472
3473	665	3473
3474	666	2684
3475	666	3475
3476	666	2766
3477	666	3477
3478	667	3478
3479	667	3479
3480	668	3480
3481	668	3481
3482	668	3482
3483	668	3483
3484	668	3484
3485	668	3485
3486	668	2337
3487	668	3487
3488	668	1352
3489	669	2785
3490	669	3490
3491	669	1940
3492	669	3492
3493	669	3493
3494	669	3494
3495	669	3495
3496	670	2392
3497	670	2490
3498	670	2919
3499	670	1865
3500	670	3500
3501	671	3501
3502	671	3502
3503	671	3503
3504	671	1536
3505	671	3505
3506	672	3506
3507	672	3507
3508	672	2456
3509	672	3509
3510	672	3510
3511	672	3511
3512	672	3248
3513	673	3513
3514	673	2893
3515	673	2801
3516	673	3242
3517	673	3243
3518	673	1905
3519	673	2984
3520	674	3520
3521	674	412
3522	674	3522
3523	675	3523
3524	675	3524
3525	675	3525
3526	675	3526
3527	675	3527
3528	676	3528
3529	676	2387
3530	676	3363
3531	676	3362
3532	676	3532
3533	677	2431
3534	677	3534
3535	678	3535
3536	678	3536
3537	678	3537
3538	678	3538
3539	678	3539
3540	678	3540
3541	678	3541
3542	679	2262
3543	679	3543
3544	679	3544
3545	679	3545
3546	680	3546
3547	680	3547
3548	680	1796
3549	681	3549
3550	681	3550
3551	681	3551
3552	681	3552
3553	681	3553
3554	682	29
3555	682	2812
3556	682	3556
3557	682	3557
3558	682	2815
3559	682	2816
3560	683	2412
3561	683	3561
3562	683	3562
3563	683	3563
3564	683	2819
3565	684	3565
3566	684	2919
3567	684	2493
3568	684	2233
3569	685	3082
3570	685	3570
3571	685	2823
3572	685	2790
3573	685	2792
3574	686	3574
3575	686	2823
3576	686	3353
3577	686	3577
3578	687	2250
3579	687	3161
3580	687	3162
3581	687	3152
3582	687	3158
3583	687	2250
3584	688	3584
3585	688	3585
3586	688	1862
3587	688	2262
3588	688	3588
3589	689	3136
3590	689	3590
3591	689	3591
3592	689	3592
3593	689	3593
3594	690	2262
3595	690	2250
3596	690	3543
3597	690	1133
3598	690	2886
3599	690	123
3600	691	2913
3601	691	2971
3602	691	122
3603	691	123
3604	691	2454
3605	691	3605
3606	691	3606
3607	692	3607
3608	692	3608
3609	692	3609
3610	692	2270
3611	692	3611
3612	693	3612
3613	693	3613
3614	693	3614
3615	693	3615
3616	694	3616
3617	694	3617
3618	694	3618
3619	694	3619
3620	695	3620
3621	695	3621
3622	695	2801
3623	696	3359
3624	696	3252
3625	696	3253
3626	696	3362
3627	696	3363
3628	696	2983
3629	696	2930
3630	697	3630
3631	697	3058
3632	697	3057
3633	698	3633
3634	698	3634
3635	698	3635
3636	698	3636
3637	698	3637
3638	699	3638
3639	699	3639
3640	700	3640
3641	700	3641
3642	700	3642
3643	700	3643
3644	701	3644
3645	702	3645
3646	703	3646
3647	703	3647
3648	703	3648
3649	703	3649
3650	704	3650
3651	704	3651
3652	705	3652
3653	705	3653
3654	705	3654
3655	706	3655
3656	706	3656
3657	707	3657
3658	707	3658
3659	708	3659
3660	708	3660
3661	708	3661
3662	708	3662
3663	708	3663
3664	708	3664
3665	709	3665
3666	709	3666
3667	710	3667
3668	710	3668
3669	711	3669
3670	711	3670
3671	711	3671
3672	711	3672
3673	712	3673
3674	712	3674
3675	712	3675
3676	712	3676
3677	713	3677
3678	713	3678
3679	714	3679
3680	714	3680
3681	715	3681
3682	715	3682
3683	715	3683
3684	716	3684
3685	716	3685
3686	716	3686
3687	716	3687
3688	717	3688
3689	717	3689
3690	717	3690
3691	718	3691
3692	718	3692
3693	718	3693
3694	719	3694
3695	719	3695
3696	719	3696
3697	719	3697
3698	719	3698
3699	720	3699
3700	720	3700
3701	720	3701
3702	720	3702
3703	721	3703
3704	721	3704
3705	722	3705
3706	722	3706
3707	722	3707
3708	722	3649
3709	723	3709
3710	723	3710
3711	723	3711
3712	724	3712
3713	724	3713
3714	725	3714
3715	725	3715
3716	725	3716
3717	725	3717
3718	726	3634
3719	726	3719
3720	727	3720
3721	727	3721
3722	728	3722
3723	728	3723
3724	728	3724
3725	728	3725
3726	728	3726
3727	729	3727
3728	729	3728
3729	729	3729
3730	729	3730
3731	729	3731
3732	730	3732
3733	730	3733
3734	730	3734
3735	730	3735
3736	731	3736
3737	731	3737
3738	731	3738
3739	731	3739
3740	731	3740
3741	731	3741
3742	732	3742
3743	732	3743
3744	732	3744
3745	733	3712
3746	733	3746
3747	733	3747
3748	734	3748
3749	734	3749
3750	734	3750
3751	735	3751
3752	735	3752
3753	735	3753
3754	736	3754
3755	736	3755
3756	736	3756
3757	736	3757
3758	737	3758
3759	737	3759
3760	738	3760
3761	738	3761
3762	738	3762
3763	739	3763
3764	739	3764
3765	739	3765
3766	740	3766
3767	740	3767
3768	740	3768
3769	742	3769
3770	742	3770
3771	742	3771
3772	743	3772
3773	743	3773
3774	743	3774
3775	744	3775
3776	744	3776
3777	744	3777
3778	745	3778
3779	745	3779
3780	745	3780
3781	745	3781
3782	745	3782
3783	746	3783
3784	746	3784
3785	746	3785
3786	746	3786
3787	746	3787
3788	747	3788
3789	747	3789
3790	747	3790
3791	747	3791
3792	748	3792
3793	748	3793
3794	748	3794
3795	748	3795
3796	748	3796
3797	748	3797
3798	749	3798
3799	749	3799
3800	749	3800
3801	749	3801
3802	750	3802
3803	750	3803
3804	750	3804
3805	750	3805
3806	750	3806
3807	751	3807
3808	751	3808
3809	751	3809
3810	751	3810
3811	752	3811
3812	752	3812
3813	752	3802
3814	752	3799
3815	752	3815
3816	752	3816
3817	752	3817
3818	753	1695
3819	753	3819
3820	753	3820
3821	753	3821
3822	753	3822
3823	753	3797
3824	754	3824
3825	754	3825
3826	754	973
3827	754	3827
3828	755	3828
3829	755	3829
3830	755	3830
3831	755	3831
3832	755	3832
3833	755	3833
3834	756	3834
3835	756	3835
3836	756	1908
3837	756	3837
3838	756	613
3839	757	3839
3840	757	3840
3841	757	3841
3842	757	3842
3843	757	3843
3844	758	3844
3845	758	3845
3846	758	3846
3847	758	3847
3848	758	3848
3849	758	3849
3850	758	3850
3851	759	3851
3852	759	3852
3853	759	3853
3854	759	3854
3855	759	3855
3856	760	3856
3857	760	973
3858	760	3858
3859	760	3859
3860	760	3860
3861	760	3861
3862	761	194
3863	761	3863
3864	761	3864
3865	761	3865
3866	762	3866
3867	762	3867
3868	762	3868
3869	762	3869
3870	763	3870
3871	763	3871
3872	763	3872
3873	763	3873
3874	763	3874
3875	764	3875
3876	764	3876
3877	764	3877
3878	764	3878
3879	764	3879
3880	765	3880
3881	765	3881
3882	765	3882
3883	766	3883
3884	766	3884
3885	766	3885
3886	766	306
3887	766	3887
3888	767	3888
3889	767	3889
3890	767	3890
3891	767	1843
3892	767	3892
3893	767	3893
3894	768	3894
3895	768	3895
3896	768	3896
3897	768	3897
3898	768	3898
3899	769	3899
3900	769	3900
3901	769	3901
3902	769	3902
3903	769	3903
3904	769	3904
3905	769	3905
3906	769	3871
3907	770	3907
3908	770	3908
3909	770	3909
3910	771	3910
3911	771	3911
3912	771	3912
3913	771	3913
3914	771	615
3915	771	3915
3916	771	3916
3917	772	3917
3918	772	3918
3919	772	3919
3920	772	2936
3921	772	3921
3922	772	3922
3923	772	3923
3924	773	3924
3925	773	3925
3926	773	3926
3927	773	3927
3928	773	3928
3929	774	839
3930	774	3930
3931	774	3931
3932	774	3932
3933	774	3933
3934	774	3934
3935	774	3935
3936	774	306
3937	774	3937
3938	775	3938
3939	775	3939
3940	775	3940
3941	775	3941
3942	776	3942
3943	776	3943
3944	776	3944
3945	776	3945
3946	776	3946
3947	776	3947
3948	777	3948
3949	777	3949
3950	777	3950
3951	777	3951
3952	777	3952
3953	778	3953
3954	778	3954
3955	778	3955
3956	778	3956
3957	778	3957
3958	779	3958
3959	779	3959
3960	779	3960
3961	779	3961
3962	779	3962
3963	779	3963
3964	780	3964
3965	780	3965
3966	780	3966
3967	780	3967
3968	780	3968
3969	780	3969
3970	781	3970
3971	781	3971
3972	781	3972
3973	781	3973
3974	782	3974
3975	782	3975
3976	782	3976
3977	782	3977
3978	783	3978
3979	783	3979
3980	783	3980
3981	783	3981
3982	783	3982
3983	784	3983
3984	784	3984
3985	784	3985
3986	784	3986
3987	784	3866
3988	785	3988
3989	785	3989
3990	785	3990
3991	785	3991
3992	786	3992
3993	786	3993
3994	786	3994
3995	786	3995
3996	786	3996
3997	786	3997
3998	787	3998
3999	787	3999
4000	787	4000
4001	788	4001
4002	789	4002
4003	790	4003
4004	791	4004
4005	792	4005
4006	793	4006
4007	793	4007
4008	793	4008
4009	793	4009
4010	793	4010
4011	793	4011
4012	794	4012
4013	794	4013
4014	794	4014
4015	794	4015
4016	794	4016
4017	794	4017
4018	795	4018
4019	795	4019
4020	795	4020
4021	795	4021
4022	795	4022
4023	795	4023
4024	795	4024
4025	795	4025
4026	796	4026
4027	796	2936
4028	796	4028
4029	796	4029
4030	796	4030
4031	796	972
4032	796	4032
4033	797	4033
4034	797	4034
4035	797	4035
4036	797	4036
4037	797	4037
4038	797	4038
4039	797	4039
4040	797	4040
4041	797	3988
4042	798	4042
4043	798	4043
4044	798	4044
4045	798	4045
4046	798	4046
4047	799	4047
4048	799	4048
4049	799	4049
4050	799	4050
4051	799	4051
4052	800	4052
4053	800	4053
4054	800	4054
4055	800	4055
4056	800	4056
4057	800	4057
4058	801	4058
4059	801	4059
4060	801	3792
4061	801	4061
4062	801	3797
4063	801	4063
4064	802	4064
4065	802	3954
4066	802	4066
4067	802	3955
4068	802	3956
4069	802	3957
4070	803	3792
4071	803	4071
4072	803	4072
4073	803	4073
4074	803	4074
4075	804	4075
4076	804	4076
4077	804	4077
4078	804	3780
4079	805	4079
4080	805	4080
4081	805	3909
4082	806	1729
4083	806	4083
4084	806	4084
4085	806	4085
4086	806	3943
4087	807	4087
4088	807	4088
4089	807	4089
4090	807	4090
4091	808	3984
4092	808	3943
4093	808	4093
4094	808	528
4095	808	296
4096	808	3961
4097	808	3960
4098	809	4098
4099	809	4099
4100	809	4100
4101	809	4101
4102	809	4102
4103	809	4103
4104	809	4104
4105	810	1417
4106	810	4106
4107	810	768
4108	810	4108
4109	810	1684
4110	810	1955
4111	811	4111
4112	811	4112
4113	811	4113
4114	811	4114
4115	811	4115
4116	812	4116
4117	812	4117
4118	812	4118
4119	812	4119
4120	812	4120
4121	812	4121
4122	813	4122
4123	813	4123
4124	813	4124
4125	813	4125
4126	813	4126
4127	813	4127
4128	814	3917
4129	814	3990
4130	814	4130
4131	814	4131
4132	814	4132
4133	815	4133
4134	815	3830
4135	815	4135
4136	815	4136
4137	815	4137
4138	816	4138
4139	816	4139
4140	816	4140
4141	816	4141
4142	816	4142
4143	816	1684
4144	817	4144
4145	817	4145
4146	817	4146
4147	817	4147
4148	817	4148
4149	817	4149
4150	817	4150
4151	817	4151
4152	817	4152
4153	817	4153
4154	818	4154
4155	818	4155
4156	818	4156
4157	818	4157
4158	818	4158
4159	819	4159
4160	819	4160
4161	819	4161
4162	819	4162
4163	819	3832
4164	819	3925
4165	819	4165
4166	819	4166
4167	819	3957
4168	819	4168
4169	820	4169
4170	820	3930
4171	820	4171
4172	820	4172
4173	820	4173
4174	820	3997
4175	820	4175
4176	820	306
4177	820	4177
4178	821	4178
4179	821	3808
4180	821	4180
4181	821	4181
4182	821	4182
4183	822	4183
4184	822	4184
4185	822	4185
4186	822	4186
4187	822	4187
4188	822	4188
4189	823	4189
4190	823	4190
4191	823	4171
4192	823	4192
4193	823	4193
4194	823	4087
4195	823	4195
4196	824	4196
4197	824	4118
4198	824	4198
4199	824	4199
4200	824	4200
4201	824	4201
4202	824	4202
4203	826	2670
4204	826	4204
4205	826	4205
4206	826	4206
4207	826	4207
4208	826	4208
4209	827	4209
4210	827	4210
4211	827	4211
4212	827	4212
4213	827	4213
4214	827	4214
4215	827	4215
4216	828	4216
4217	828	4056
4218	828	1684
4219	828	4219
4220	828	4220
4221	828	4221
4222	829	4222
4223	829	4223
4224	829	4224
4225	829	4225
4226	829	4226
4227	829	4149
4228	829	4150
4229	830	4229
4230	830	4230
4231	830	4231
4232	830	4232
4233	830	4233
4234	830	4234
4235	830	4235
4236	830	4236
4237	831	4237
4238	831	296
4239	831	4239
4240	831	4240
4241	831	4241
4242	831	4242
4243	831	4243
4244	832	4244
4245	832	4245
4246	832	4246
4247	832	4247
4248	832	4248
4249	833	4249
4250	833	4250
4251	833	4251
4252	833	4252
4253	833	4253
4254	833	4254
4255	833	4255
4256	833	4256
4257	834	4257
4258	834	4258
4259	834	874
4260	834	4260
4261	834	4261
4262	834	4262
4263	835	4263
4264	835	4264
4265	835	2936
4266	835	4023
4267	835	3997
4268	835	4268
4269	835	3847
4270	835	4270
4271	836	4271
4272	836	4272
4273	836	4273
4274	836	4274
4275	836	4275
4276	836	4276
4277	837	4277
4278	837	4278
4279	837	4279
4280	837	4280
4281	837	4281
4282	838	4282
4283	838	4283
4284	838	4284
4285	838	4285
4286	838	4286
4287	838	4287
4288	838	4288
4289	839	4289
4290	839	4000
4291	839	4291
4292	839	4292
4293	839	4293
4294	839	4294
4295	839	4295
4296	839	4118
4297	840	4297
4298	840	4298
4299	840	4299
4300	840	4300
4301	841	4301
4302	841	2251
4303	841	2067
4304	841	4304
4305	841	4305
4306	841	4306
4307	841	2531
4308	841	4308
4309	841	4309
4310	842	2003
4311	842	4311
4312	842	1999
4313	842	3832
4314	843	4314
4315	843	4315
4316	843	4316
4317	843	4317
4318	843	4318
4319	843	4087
4320	843	4320
4321	843	4321
4322	843	1040
4323	844	4323
4324	844	4324
4325	844	4325
4326	844	4326
4327	845	4327
4328	845	4328
4329	845	433
4330	845	4330
4331	845	4331
4332	846	4332
4333	846	768
4334	846	4334
4335	846	4335
4336	846	4336
4337	846	4337
4338	846	4338
4339	847	4339
4340	847	4340
4341	847	4341
4342	847	3213
4343	847	2579
4344	848	4344
4345	848	4345
4346	848	4346
4347	848	2307
4348	848	4348
4349	848	4349
4350	849	4350
4351	849	4351
4352	849	4352
4353	849	4353
4354	849	4354
4355	849	4355
4356	850	4356
4357	850	4357
4358	850	4358
4359	850	4359
4360	850	4360
4361	850	4361
4362	850	4362
4363	851	4363
4364	851	4364
4365	851	4365
4366	851	4366
4367	851	4367
4368	851	4018
4369	852	4076
4370	852	4370
4371	852	4224
4372	852	4372
4373	853	4373
4374	853	4374
4375	853	4375
4376	854	3952
4377	854	4377
4378	854	4378
4379	854	4379
4380	855	4380
4381	855	4381
4382	855	4382
4383	855	4383
4384	856	4384
4385	856	4385
4386	856	4386
4387	856	4387
4388	856	1684
4389	857	4389
4390	857	4390
4391	857	4391
4392	857	4392
4393	857	4393
4394	857	4394
4395	858	4395
4396	858	4396
4397	858	4397
4398	858	4398
4399	858	3680
4400	858	4400
4401	858	4401
4402	859	4402
4403	859	1940
4404	859	4404
4405	859	4405
4406	860	4406
4407	860	4407
4408	860	4408
4409	860	4409
4410	860	4410
4411	860	4411
4412	860	306
4413	860	3937
4414	861	4018
4415	861	4052
4416	861	4416
4417	861	4417
4418	861	4418
4419	862	4419
4420	862	4420
4421	862	4421
4422	862	4422
4423	862	4423
4424	862	4424
4425	862	2528
4426	862	4426
4427	862	4427
4428	863	4111
4429	863	4411
4430	863	4430
4431	863	4431
4432	864	4432
4433	864	4433
4434	864	3954
4435	864	4066
4436	864	3952
4437	864	3956
4438	864	4438
4439	866	4439
4440	866	4440
4441	866	4441
4442	866	4442
4443	866	4443
4444	866	3915
4445	866	4445
4446	867	4446
4447	867	4447
4448	867	4448
4449	867	4449
4450	867	4450
4451	867	4451
4452	868	4452
4453	868	4453
4454	868	4454
4455	868	4455
4456	868	4456
4457	868	4457
4458	868	4458
4459	869	4459
4460	869	4460
4461	869	4461
4462	869	4462
4463	869	4463
4464	869	4464
4465	870	4465
4466	870	4466
4467	870	3971
4468	870	4468
4469	870	3830
4470	871	4470
4471	871	4471
4472	871	4472
4473	871	4473
4474	871	4474
4475	871	4475
4476	871	4476
4477	872	4477
4478	872	4478
4479	872	4479
4480	872	4480
4481	872	4481
4482	872	4482
4483	872	3816
4484	873	4484
4485	873	2780
4486	873	4486
4487	873	1904
4488	873	4488
4489	873	2259
4490	874	4490
4491	874	4491
4492	874	4411
4493	874	4493
4494	874	4494
4495	875	4495
4496	875	4496
4497	875	4497
4498	875	4024
4499	875	4023
4500	875	4411
4501	876	4501
4502	876	4502
4503	876	4292
4504	876	3868
4505	876	4505
4506	876	4506
4507	877	4507
4508	877	4508
4509	877	4509
4510	878	4510
4511	878	4511
4512	878	2072
4513	878	4513
4514	878	4514
4515	878	4515
4516	878	3392
4517	879	4517
4518	879	4518
4519	879	4519
4520	879	4520
4521	879	2936
4522	880	4522
4523	880	4523
4524	880	4524
4525	880	4525
4526	881	4526
4527	881	4527
4528	881	4528
4529	881	4178
4530	881	4530
4531	883	4402
4532	883	1940
4533	883	3493
4534	883	4534
4535	884	1575
4536	884	4536
4537	884	4537
4538	884	4538
4539	885	4539
4540	885	4540
4541	885	4541
4542	885	4542
4543	885	4543
4544	886	4544
4545	886	4545
4546	886	2072
4547	886	4547
4548	886	4548
4549	887	4549
4550	887	4550
4551	887	4551
4552	888	2393
4553	888	2542
4554	888	4554
4555	888	4555
4556	888	4556
4557	888	4557
4558	888	4558
4559	888	4559
4560	889	4560
4561	889	4561
4562	889	4562
4563	889	4563
4564	889	4564
4565	889	4565
4566	890	4566
4567	890	3424
4568	890	4568
4569	890	4569
4570	890	4570
4571	890	4571
4572	891	4572
4573	891	2653
4574	891	4574
4575	891	4575
4576	891	4576
4577	892	4577
4578	892	4578
4579	893	4579
4580	893	4580
4581	893	4147
4582	893	4582
4583	894	4168
4584	894	4584
4585	894	4585
4586	894	4162
4587	894	4587
4588	894	4588
4589	894	4589
4590	895	4590
4591	895	4460
4592	895	4461
4593	895	4593
4594	895	4594
4595	895	4595
4596	896	4596
4597	896	4597
4598	896	4598
4599	896	4599
4600	896	4600
4601	897	4402
4602	897	4598
4603	897	4603
4604	897	1940
4605	897	4605
4606	897	3495
4607	898	2733
4608	898	4608
4609	898	4609
4610	898	4610
4611	898	4611
4612	898	2531
4613	899	4145
4614	899	4614
4615	899	4321
4616	899	4616
4617	899	4617
4618	900	4618
4619	900	4619
4620	900	4620
4621	900	4621
4622	900	4622
4623	901	2733
4624	901	3161
4625	901	2661
4626	901	4626
4627	901	4627
4628	901	4628
4629	902	4629
4630	902	4562
4631	902	4631
4632	902	4632
4633	902	4633
4634	902	4634
4635	902	4635
4636	902	2714
4637	903	4637
4638	903	4638
4639	903	4639
4640	903	4640
4641	903	4641
4642	903	4642
4643	904	3867
4644	904	4644
4645	904	4617
4646	904	4646
4647	904	4647
4648	904	4648
4649	904	4649
4650	905	4650
4651	905	2653
4652	905	4652
4653	905	4653
4654	906	4654
4655	906	4655
4656	906	4656
4657	906	4657
4658	907	4658
4659	907	4659
4660	907	4660
4661	907	4661
4662	907	4662
4663	908	4663
4664	908	4664
4665	908	4665
4666	908	4666
4667	909	4667
4668	909	4668
4669	909	4669
4670	909	4670
4671	909	4671
4672	910	4672
4673	910	4673
4674	910	4674
4675	910	4675
4676	910	2233
4677	911	2531
4678	911	4678
4679	911	4679
4680	911	4680
4681	912	4681
4682	912	2072
4683	912	4683
4684	912	4684
4685	913	4685
4686	913	4686
4687	913	4687
4688	913	4688
4689	913	4689
4690	913	4690
4691	913	4691
4692	914	4692
4693	914	4693
4694	914	4694
4695	914	4695
4696	914	4696
4697	914	4697
4698	914	4698
4699	915	4699
4700	915	4700
4701	915	733
4702	915	2102
4703	915	2033
4704	916	2527
4705	916	2526
4706	916	2693
4707	916	4707
4708	916	4708
4709	917	790
4710	917	1353
4711	917	4711
4712	917	4712
4713	917	4713
4714	918	2672
4715	918	4715
4716	919	2307
4717	919	4717
4718	919	2292
4719	919	4719
4720	919	4720
4721	920	4721
4722	920	685
4723	920	4723
4724	920	4724
4725	920	86
4726	920	4726
4727	921	4727
4728	921	2464
4729	921	4729
4730	921	4730
4731	921	4731
4732	922	4732
4733	922	4733
4734	922	4734
4735	922	4735
4736	922	4736
4737	923	4737
4738	923	4738
4739	923	4739
4740	923	4740
4741	923	4741
4742	923	4742
4743	924	4743
4744	924	4744
4745	924	4745
4746	925	4746
4747	925	4747
4748	925	4748
4749	925	4749
4750	925	4750
4751	926	1965
4752	926	4752
4753	926	4753
4754	926	4754
4755	926	4755
4756	927	4756
4757	927	4757
4758	927	4758
4759	927	4759
4760	927	4760
4761	928	4761
4762	928	4762
4763	928	4763
4764	928	4764
4765	928	4765
4766	928	4766
4767	928	4767
4768	928	4768
4769	929	4769
4770	929	4770
4771	929	4771
4772	929	4772
4773	929	4773
4774	930	4774
4775	930	4775
4776	930	4776
4777	930	4777
4778	930	4778
4779	930	4779
4780	931	2250
4781	931	733
4782	931	4782
4783	931	1965
4784	931	2784
4785	931	4598
4786	931	2464
4787	932	4787
4788	932	4788
4789	932	4789
4790	932	4790
4791	932	4791
4792	933	4792
4793	933	4793
4794	933	4794
4795	933	4795
4796	934	4796
4797	934	4797
4798	934	4798
4799	934	4799
4800	934	4800
4801	934	4801
4802	934	4802
4803	935	4803
4804	935	4804
4805	935	4805
4806	935	4793
4807	935	4795
4808	936	4598
4809	936	4809
4810	936	3001
4811	936	2464
4812	936	4812
4813	936	4813
4814	936	733
4815	937	4815
4816	937	4816
4817	937	4817
4818	937	4818
4819	937	4819
4820	937	4820
4821	938	4821
4822	938	4822
4823	938	4823
4824	938	4824
4825	938	4825
4826	938	4826
4827	938	4827
4828	938	3550
4829	939	4829
4830	939	4830
4831	939	4831
4832	939	4832
4833	940	4833
4834	940	4834
4835	940	4835
4836	940	4836
4837	940	4837
4838	941	4838
4839	941	4839
4840	941	4840
4841	941	4841
4842	941	4842
4843	942	4843
4844	942	4844
4845	942	4845
4846	942	4846
4847	942	4847
4848	942	3375
4849	943	4849
4850	943	4850
4851	943	2412
4852	943	4852
4853	943	3273
4854	944	4854
4855	944	4855
4856	944	4856
4857	944	4857
4858	945	4858
4859	945	4859
4860	945	4860
4861	945	4861
4862	945	4862
4863	946	4863
4864	946	4864
4865	946	4865
4866	946	4866
4867	947	4867
4868	947	4868
4869	947	4869
4870	947	4870
4871	947	4871
4872	948	4872
4873	948	4873
4874	948	4874
4875	948	4875
4876	948	4876
4877	948	4877
4878	948	4878
4879	948	4879
4880	948	4880
4881	949	4881
4882	949	2993
4883	949	4883
4884	949	4884
4885	950	4885
4886	951	4886
4887	951	4887
4888	951	4888
4889	951	4889
4890	951	4890
4891	951	4891
4892	951	4892
4893	952	4893
4894	952	4894
4895	952	4895
4896	952	4896
4897	952	4897
4898	952	4898
4899	952	4899
4900	953	4900
4901	953	4901
4902	953	4902
4903	953	4903
4904	953	4904
4905	953	4905
4906	954	4906
4907	954	4907
4908	954	4908
4909	955	4909
4910	955	4910
4911	955	4911
4912	955	4912
4913	956	4913
4914	956	4914
4915	956	4915
4916	956	4916
4917	956	4917
4918	957	4769
4919	957	3375
4920	957	4920
4921	958	4921
4922	958	4922
4923	958	4923
4924	958	4924
4925	958	4925
4926	958	2277
4927	959	4927
4928	959	4928
4929	959	4929
4930	959	4930
4931	959	4931
4932	960	4932
4933	960	4933
4934	960	4934
4935	960	4935
4936	960	4936
4937	960	4937
4938	961	4938
4939	961	4939
4940	961	4940
4941	961	4941
4942	962	4942
4943	962	4943
4944	962	4944
4945	962	4945
4946	963	4792
4947	963	4942
4948	963	4936
4949	963	4949
4950	964	4817
4951	964	4951
4952	964	4952
4953	964	4953
4954	964	4954
4955	965	4955
4956	966	2821
4957	966	4957
4958	966	4958
4959	966	4959
4960	966	4960
4961	966	4961
4962	966	4962
4963	967	4727
4964	967	2464
4965	967	29
4966	967	4966
4967	967	4731
4968	967	4968
4969	968	4969
4970	968	4970
4971	968	4971
4972	968	4972
4973	968	4973
4974	968	4974
4975	968	4975
4976	969	4976
4977	969	4977
4978	969	4885
4979	969	4979
4980	969	4980
4981	970	4885
4982	970	4982
4983	970	4983
4984	970	4984
4985	970	4985
4986	970	3123
4987	970	4987
4988	970	4885
4989	971	4989
4990	971	4910
4991	971	4991
4992	971	4992
4993	971	4911
4994	971	4912
4995	972	4995
4996	972	4667
4997	972	4997
4998	972	4998
4999	972	4999
5000	973	5000
5001	973	5001
5002	973	5002
5003	973	5003
5004	973	5004
5005	974	4838
5006	974	4839
5007	974	5007
5008	974	5008
5009	974	5009
5010	975	4788
5011	975	4789
5012	975	4791
5013	975	4790
5014	976	3168
5015	976	5015
5016	976	5016
5017	976	5017
5018	976	5018
5019	977	4821
5020	977	5020
5021	977	5021
5022	977	5022
5023	977	5023
5024	978	5024
5025	978	5025
5026	978	5026
5027	979	4858
5028	979	5028
5029	979	5029
5030	979	5030
5031	979	5031
5032	980	5032
5033	980	3135
5034	980	5034
5035	980	5035
5036	980	5036
5037	981	5037
5038	981	5038
5039	981	5039
5040	981	5040
5041	981	5041
5042	982	5042
5043	982	5043
5044	982	5044
5045	982	5045
5046	982	5046
5047	983	5047
5048	983	5048
5049	983	5049
5050	983	2330
5051	984	5051
5052	984	5052
5053	984	5053
5054	985	5054
5055	985	5055
5056	985	5056
5057	985	5057
5058	985	5058
5059	985	5059
5060	985	5060
5061	985	5061
5062	985	5062
5063	986	5063
5064	986	5064
5065	986	5065
5066	987	5066
5067	987	5067
5068	987	5068
5069	987	5069
5070	987	5070
5071	987	5071
5072	988	5072
5073	988	5073
5074	988	5074
5075	989	5075
5076	990	5028
5077	990	4858
5078	990	5078
5079	990	4859
5080	990	5080
5081	991	5037
5082	991	5038
5083	991	5039
5084	991	5040
5085	992	5085
5086	992	5086
5087	992	2464
5088	992	5088
5089	992	5089
5090	992	5090
5091	992	5091
5092	993	5092
5093	993	5093
5094	993	5094
5095	993	5095
5096	994	5096
5097	994	5097
5098	994	5098
5099	994	5099
5100	995	5100
5101	995	5101
5102	996	5102
5103	996	5103
5104	996	5104
5105	996	5105
5106	996	5106
5107	996	5107
5108	996	5108
5109	997	4858
5110	997	5110
5111	997	5111
5112	997	5112
5113	998	5113
5114	998	5114
5115	998	5115
5116	998	5116
5117	998	5117
5118	998	5118
5119	998	5119
5120	998	5120
5121	999	5121
5122	999	5122
5123	999	5123
5124	999	5124
5125	999	5125
5126	999	5126
5127	1000	5127
5128	1000	5128
5129	1000	5129
5130	1000	5130
5131	1000	5131
5132	1001	5132
5133	1001	5133
5134	1001	5134
5135	1001	5135
5136	1001	5136
5137	1001	5137
5138	1001	5138
5139	1001	5139
5140	1001	5140
5141	1002	5141
5142	1002	5142
5143	1002	5143
5144	1002	5144
5145	1002	5145
5146	1002	5146
5147	1003	5147
5148	1003	5148
5149	1003	5149
5150	1003	5150
5151	1003	5151
5152	1003	5152
5153	1003	5153
5154	1004	5154
5155	1004	5155
5156	1004	5156
5157	1004	5157
5158	1005	5158
5159	1005	5159
5160	1005	5160
5161	1006	5161
5162	1006	2909
5163	1006	5163
5164	1007	5164
5165	1007	5165
5166	1007	5166
5167	1007	5167
5168	1007	5168
5169	1008	733
5170	1008	2784
5171	1008	4885
5172	1008	4982
5173	1008	4885
5174	1008	5174
5175	1008	5175
5176	1009	5176
5177	1009	5177
5178	1009	5178
5179	1009	5179
5180	1009	5180
5181	1010	5181
5182	1010	3371
5183	1010	5183
5184	1010	5184
5185	1010	5185
5186	1011	5186
5187	1011	5187
5188	1011	2412
5189	1011	5189
5190	1011	2330
5191	1011	5191
5192	1012	5192
5193	1012	5193
5194	1012	5194
5195	1012	5195
5196	1012	5196
5197	1012	5197
5198	1012	5198
5199	1013	5199
5200	1013	5200
5201	1013	5201
5202	1013	5202
5203	1014	5203
5204	1014	5204
5205	1014	5205
5206	1014	4885
5207	1014	5207
5208	1014	5208
5209	1014	5209
5210	1014	5210
5211	1015	4872
5212	1015	5212
5213	1015	5213
5214	1015	4877
5215	1015	3371
5216	1015	2996
5217	1016	5217
5218	1016	5218
5219	1016	2464
5220	1016	5220
5221	1016	5221
5222	1016	3375
5223	1017	5223
5224	1017	5224
5225	1017	5225
5226	1017	5226
5227	1017	5227
5228	1018	5228
5229	1018	5229
5230	1018	5230
5231	1018	5231
5232	1019	218
5233	1019	5233
5234	1019	5234
5235	1019	4922
5236	1019	5236
5237	1019	5237
5238	1020	5238
5239	1020	5239
5240	1020	5240
5241	1020	239
5242	1020	5242
5243	1021	5243
5244	1021	5244
5245	1021	5245
5246	1021	5246
5247	1021	5247
5248	1022	5248
5249	1022	5249
5250	1022	5250
5251	1022	449
5252	1022	2909
5253	1022	5253
5254	1023	5254
5255	1023	5255
5256	1023	5256
5257	1023	5257
5258	1023	5258
5259	1023	5259
5260	1024	5260
5261	1024	5261
5262	1024	5262
5263	1024	5263
5264	1025	4982
5265	1025	5265
5266	1025	5175
5267	1025	5267
5268	1025	5268
5269	1025	733
5270	1026	5270
5271	1026	5271
5272	1026	5272
5273	1026	5273
5274	1027	4833
5275	1027	5275
5276	1027	5276
5277	1027	4837
5278	1027	5278
5279	1028	5279
5280	1028	5280
5281	1028	5281
5282	1028	5282
5283	1029	5283
5284	1029	5284
5285	1029	5285
5286	1029	5286
5287	1030	2911
5288	1030	5288
5289	1030	5289
5290	1030	5290
5291	1030	2821
5292	1030	5292
5293	1031	4885
5294	1031	5294
5295	1031	5295
5296	1031	5296
5297	1031	5297
5298	1031	5298
5299	1032	5299
5300	1032	5300
5301	1032	5301
5302	1033	5302
5303	1033	5303
5304	1033	5304
5305	1034	5305
5306	1034	5306
5307	1034	5307
5308	1034	5308
5309	1035	5309
5310	1035	5310
5311	1035	5311
5312	1035	5312
5313	1036	5313
5314	1036	5314
5315	1036	5315
5316	1036	5316
5317	1036	5317
5318	1036	5318
5319	1037	5319
5320	1037	5320
5321	1037	2464
5322	1037	4968
5323	1037	5323
5324	1037	5324
5325	1038	5325
5326	1038	5326
5327	1038	5327
5328	1038	5187
5329	1038	2330
5330	1038	5330
5331	1039	5331
5332	1039	5167
5333	1039	3338
5334	1039	5164
5335	1040	5335
5336	1040	5336
5337	1040	5337
5338	1040	5338
5339	1040	5339
5340	1041	5340
5341	1041	5341
5342	1041	5342
5343	1041	4833
5344	1041	5344
5345	1041	5345
5346	1041	5346
5347	1042	5347
5348	1042	3371
5349	1042	5349
5350	1042	5350
5351	1042	5351
5352	1042	5352
5353	1043	4885
5354	1043	5294
5355	1043	5355
5356	1043	5356
5357	1043	5357
5358	1043	5298
5359	1044	5359
5360	1044	5360
5361	1044	5361
5362	1045	5362
5363	1045	5363
5364	1045	5364
5365	1045	5365
5366	1045	5366
5367	1045	5367
5368	1046	5368
5369	1046	5369
5370	1046	5370
5371	1046	5371
5372	1046	5372
5373	1047	2789
5374	1047	2909
5375	1047	5375
5376	1047	3168
5377	1047	5377
5378	1048	5378
5379	1048	2330
5380	1048	5380
5381	1048	5187
5382	1048	5382
5383	1049	5383
5384	1049	5384
5385	1049	5385
5386	1050	5386
5387	1050	5387
5388	1050	5388
5389	1051	5389
5390	1051	5390
5391	1051	5391
5392	1051	5364
5393	1051	5393
5394	1051	5394
5395	1051	5395
5396	1052	5396
5397	1052	5397
5398	1052	5154
5399	1053	3123
5400	1053	4885
5401	1053	4982
5402	1053	5402
5403	1053	5403
5404	1053	5404
5405	1053	5405
5406	1053	4885
5407	1053	5407
5408	1054	5408
5409	1054	5409
5410	1054	5410
5411	1054	5411
5412	1054	5412
5413	1055	4885
5414	1055	5294
5415	1055	3123
5416	1055	5356
5417	1055	5357
5418	1055	5298
5419	1056	5419
5420	1056	5420
5421	1056	5421
5422	1056	4008
5423	1056	5423
5424	1056	5424
5425	1057	5425
5426	1057	5426
5427	1057	5427
5428	1057	5428
5429	1057	5429
5430	1058	5430
5431	1058	5431
5432	1058	5432
5433	1058	5433
5434	1059	5127
5435	1059	5435
5436	1059	5436
5437	1059	5129
5438	1059	5438
5439	1060	5439
5440	1060	5440
5441	1060	5441
5442	1061	3371
5443	1061	5443
5444	1061	5444
5445	1062	5445
5446	1062	5446
5447	1062	5447
5448	1062	5448
5449	1062	5449
5450	1062	5450
5451	1063	5451
5452	1063	5452
5453	1063	5453
5454	1063	326
5455	1063	5455
5456	1063	5456
5457	1064	5457
5458	1064	5458
5459	1064	5459
5460	1064	326
5461	1064	5461
5462	1065	5462
5463	1065	5463
5464	1065	5464
5465	1065	5465
5466	1066	5155
5467	1066	5397
5468	1066	5154
5469	1067	5469
5470	1067	5470
5471	1067	5471
5472	1067	5472
5473	1068	5473
5474	1068	5474
5475	1068	5475
5476	1068	5476
5477	1068	5477
5478	1069	5478
5479	1069	5479
5480	1069	5480
5481	1069	5481
5482	1070	5482
5483	1070	5483
5484	1070	5484
5485	1070	5485
5486	1070	5486
5487	1070	5487
5488	1071	5488
5489	1071	5489
5490	1071	5490
5491	1071	5491
5492	1072	5492
5493	1072	5493
5494	1072	5494
5495	1072	5495
5496	1072	5496
5497	1073	5497
5498	1073	5498
5499	1073	5499
5500	1073	5500
5501	1073	5501
5502	1073	5502
5503	1074	5503
5504	1074	5186
5505	1074	5505
5506	1074	5506
5507	1074	5507
5508	1074	5508
5509	1075	5509
5510	1075	5510
5511	1075	5511
5512	1075	3369
5513	1075	5513
5514	1076	5514
5515	1076	5515
5516	1076	5516
5517	1076	5517
5518	1076	5518
5519	1076	5519
5520	1077	5520
5521	1077	5521
5522	1077	5522
5523	1078	4885
5524	1078	5435
5525	1078	5525
5526	1078	4885
5527	1078	5527
5528	1078	5528
5529	1078	5529
5530	1078	5530
5531	1079	5473
5532	1079	5532
5533	1079	5533
5534	1079	5534
5535	1079	5535
5536	1080	5536
5537	1080	5537
5538	1080	5538
5539	1080	5539
5540	1080	5540
5541	1081	5541
5542	1081	5542
5543	1081	5543
5544	1081	5544
5545	1081	4897
5546	1081	5546
5547	1082	5276
5548	1082	5548
5549	1082	5345
5550	1082	5284
5551	1082	5551
5552	1083	5552
5553	1083	5553
5554	1083	5387
5555	1083	5555
5556	1084	5556
5557	1084	5557
5558	1084	5558
5559	1084	5559
5560	1084	326
5561	1084	5561
5562	1084	5562
5563	1084	5563
5564	1084	5564
5565	1085	4821
5566	1085	5566
5567	1085	5567
5568	1085	5568
5569	1085	5569
5570	1086	5570
5571	1086	5571
5572	1086	5572
5573	1086	5573
5574	1086	5574
5575	1086	5575
5576	1086	5576
5577	1087	5577
5578	1087	5578
5579	1087	5579
5580	1087	5580
5581	1087	5581
5582	1087	5582
5583	1087	4735
5584	1087	5584
5585	1088	5585
5586	1088	5586
5587	1088	5587
5588	1088	5588
5589	1088	5589
5590	1088	5590
5591	1089	5500
5592	1089	5592
5593	1089	5593
5594	1089	5594
5595	1089	5595
5596	1090	5596
5597	1090	5597
5598	1090	5598
5599	1090	5599
5600	1090	5600
5601	1090	5601
5602	1091	5602
5603	1091	5305
5604	1091	5604
5605	1091	326
5606	1091	5606
5607	1092	5607
5608	1092	5608
5609	1092	5609
5610	1093	4885
5611	1093	5611
5612	1093	5435
5613	1093	5613
5614	1093	5525
5615	1093	5615
5616	1093	5616
5617	1093	5617
5618	1094	5618
5619	1094	5619
5620	1094	5620
5621	1094	3369
5622	1094	5622
5623	1095	5623
5624	1095	5624
5625	1095	5625
5626	1095	5626
5627	1095	5627
5628	1095	5344
5629	1095	5629
5630	1095	5630
5631	1096	5631
5632	1096	5521
5633	1096	5633
5634	1097	5634
5635	1097	5635
5636	1097	5483
5637	1097	5484
5638	1097	5485
5639	1097	5639
5640	1097	5487
5641	1098	5641
5642	1098	5642
5643	1098	5643
5644	1098	5644
5645	1099	5645
5646	1099	5646
5647	1099	5647
5648	1099	5648
5649	1099	5649
5650	1100	5650
5651	1101	5651
5652	1101	5652
5653	1101	5653
5654	1101	5654
5655	1101	5655
5656	1101	5656
5657	1101	5657
5658	1101	5658
5659	1101	5659
5660	1102	5660
5661	1102	5661
5662	1102	5662
5663	1102	5663
5664	1102	5664
5665	1103	5665
5666	1103	5666
5667	1103	5667
5668	1103	5668
5669	1103	5669
5670	1104	5670
5671	1104	5671
5672	1104	5672
5673	1104	5673
5674	1104	5674
5675	1105	5249
5676	1105	5676
5677	1105	5677
5678	1106	5678
5679	1107	5679
5680	1108	5680
5681	1109	5681
5682	1110	5682
5683	1111	5683
5684	1112	5684
5685	1113	5685
5686	1114	5686
5687	1115	5687
5688	1116	5688
5689	1117	5689
5690	1118	5690
\.


--
-- TOC entry 2952 (class 0 OID 16903)
-- Dependencies: 206
-- Data for Name: ratings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ratings (id_rating, stars, seen) FROM stdin;
0	0	0
2	0	0
3	0	0
4	0	0
5	0	0
6	0	0
7	0	0
8	0	0
9	0	0
10	0	0
11	0	0
12	0	0
13	0	0
14	0	0
15	0	0
16	0	0
17	0	0
18	0	0
19	0	0
20	0	0
21	0	0
22	0	0
23	0	0
24	0	0
25	0	0
26	0	0
27	0	0
28	0	0
29	0	0
30	0	0
31	0	0
32	0	0
33	0	0
34	0	0
35	0	0
36	0	0
37	0	0
38	0	0
39	0	0
40	0	0
41	0	0
42	0	0
43	0	0
44	0	0
45	0	0
46	0	0
47	0	0
48	0	0
49	0	0
50	0	0
51	0	0
52	0	0
53	0	0
54	0	0
55	0	0
56	0	0
57	0	0
58	0	0
59	0	0
60	0	0
61	0	0
62	0	0
63	0	0
64	0	0
65	0	0
66	0	0
67	0	0
68	0	0
69	0	0
70	0	0
71	0	0
72	0	0
73	0	0
74	0	0
75	0	0
76	0	0
77	0	0
78	0	0
79	0	0
80	0	0
81	0	0
82	0	0
83	0	0
84	0	0
85	0	0
86	0	0
87	0	0
88	0	0
89	0	0
90	0	0
91	0	0
92	0	0
93	0	0
94	0	0
95	0	0
96	0	0
97	0	0
98	0	0
99	0	0
100	0	0
101	0	0
102	0	0
103	0	0
104	0	0
105	0	0
106	0	0
107	0	0
108	0	0
109	0	0
110	0	0
111	0	0
112	0	0
113	0	0
114	0	0
115	0	0
116	0	0
117	0	0
118	0	0
119	0	0
120	0	0
121	0	0
122	0	0
123	0	0
124	0	0
125	0	0
126	0	0
127	0	0
128	0	0
129	0	0
130	0	0
131	0	0
132	0	0
133	0	0
134	0	0
135	0	0
136	0	0
137	0	0
138	0	0
139	0	0
140	0	0
141	0	0
142	0	0
143	0	0
144	0	0
145	0	0
146	0	0
147	0	0
148	0	0
149	0	0
150	0	0
151	0	0
152	0	0
153	0	0
154	0	0
155	0	0
156	0	0
157	0	0
158	0	0
159	0	0
160	0	0
161	0	0
162	0	0
163	0	0
164	0	0
165	0	0
166	0	0
167	0	0
168	0	0
169	0	0
170	0	0
171	0	0
172	0	0
173	0	0
174	0	0
175	0	0
176	0	0
177	0	0
178	0	0
179	0	0
180	0	0
181	0	0
182	0	0
183	0	0
184	0	0
185	0	0
186	0	0
187	0	0
188	0	0
189	0	0
190	0	0
191	0	0
192	0	0
193	0	0
194	0	0
195	0	0
196	0	0
197	0	0
198	0	0
199	0	0
200	0	0
201	0	0
202	0	0
203	0	0
204	0	0
205	0	0
206	0	0
207	0	0
208	0	0
209	0	0
210	0	0
211	0	0
212	0	0
213	0	0
214	0	0
215	0	0
216	0	0
217	0	0
218	0	0
219	0	0
220	0	0
221	0	0
222	0	0
223	0	0
224	0	0
225	0	0
226	0	0
227	0	0
228	0	0
229	0	0
230	0	0
231	0	0
232	0	0
233	0	0
234	0	0
235	0	0
236	0	0
237	0	0
238	0	0
239	0	0
240	0	0
241	0	0
242	0	0
243	0	0
244	0	0
245	0	0
246	0	0
247	0	0
248	0	0
249	0	0
250	0	0
251	0	0
252	0	0
253	0	0
254	0	0
255	0	0
256	0	0
257	0	0
258	0	0
259	0	0
260	0	0
261	0	0
262	0	0
263	0	0
264	0	0
265	0	0
266	0	0
267	0	0
268	0	0
269	0	0
270	0	0
271	0	0
272	0	0
273	0	0
274	0	0
275	0	0
276	0	0
277	0	0
278	0	0
279	0	0
280	0	0
281	0	0
282	0	0
283	0	0
284	0	0
285	0	0
286	0	0
287	0	0
288	0	0
289	0	0
290	0	0
291	0	0
292	0	0
293	0	0
294	0	0
295	0	0
296	0	0
297	0	0
298	0	0
299	0	0
300	0	0
301	0	0
302	0	0
303	0	0
304	0	0
305	0	0
306	0	0
307	0	0
308	0	0
309	0	0
310	0	0
311	0	0
312	0	0
313	0	0
314	0	0
315	0	0
316	0	0
317	0	0
318	0	0
319	0	0
320	0	0
321	0	0
322	0	0
323	0	0
324	0	0
325	0	0
326	0	0
327	0	0
328	0	0
329	0	0
330	0	0
331	0	0
332	0	0
333	0	0
334	0	0
335	0	0
336	0	0
337	0	0
338	0	0
339	0	0
340	0	0
341	0	0
342	0	0
343	0	0
344	0	0
345	0	0
346	0	0
347	0	0
348	0	0
349	0	0
350	0	0
351	0	0
352	0	0
353	0	0
354	0	0
355	0	0
356	0	0
357	0	0
358	0	0
359	0	0
360	0	0
361	0	0
362	0	0
363	0	0
364	0	0
365	0	0
366	0	0
367	0	0
368	0	0
369	0	0
370	0	0
371	0	0
372	0	0
373	0	0
374	0	0
375	0	0
376	0	0
377	0	0
378	0	0
379	0	0
380	0	0
381	0	0
382	0	0
383	0	0
384	0	0
385	0	0
386	0	0
387	0	0
388	0	0
389	0	0
390	0	0
391	0	0
392	0	0
393	0	0
394	0	0
395	0	0
396	0	0
397	0	0
398	0	0
399	0	0
400	0	0
401	0	0
402	0	0
403	0	0
404	0	0
405	0	0
406	0	0
407	0	0
408	0	0
409	0	0
410	0	0
411	0	0
412	0	0
413	0	0
414	0	0
415	0	0
416	0	0
417	0	0
418	0	0
419	0	0
420	0	0
421	0	0
422	0	0
423	0	0
424	0	0
425	0	0
426	0	0
427	0	0
428	0	0
429	0	0
430	0	0
431	0	0
432	0	0
433	0	0
434	0	0
435	0	0
436	0	0
437	0	0
438	0	0
439	0	0
440	0	0
441	0	0
442	0	0
443	0	0
444	0	0
445	0	0
446	0	0
447	0	0
448	0	0
449	0	0
450	0	0
451	0	0
452	0	0
453	0	0
454	0	0
455	0	0
456	0	0
457	0	0
458	0	0
459	0	0
460	0	0
461	0	0
462	0	0
463	0	0
464	0	0
465	0	0
466	0	0
467	0	0
468	0	0
469	0	0
470	0	0
471	0	0
472	0	0
473	0	0
474	0	0
475	0	0
476	0	0
477	0	0
478	0	0
479	0	0
480	0	0
481	0	0
482	0	0
483	0	0
484	0	0
485	0	0
486	0	0
487	0	0
488	0	0
489	0	0
490	0	0
491	0	0
492	0	0
493	0	0
494	0	0
495	0	0
496	0	0
497	0	0
498	0	0
499	0	0
500	0	0
501	0	0
502	0	0
503	0	0
504	0	0
505	0	0
506	0	0
507	0	0
508	0	0
509	0	0
510	0	0
511	0	0
512	0	0
513	0	0
514	0	0
515	0	0
516	0	0
517	0	0
518	0	0
519	0	0
520	0	0
521	0	0
522	0	0
523	0	0
524	0	0
525	0	0
526	0	0
527	0	0
528	0	0
529	0	0
530	0	0
531	0	0
532	0	0
533	0	0
534	0	0
535	0	0
536	0	0
537	0	0
538	0	0
539	0	0
540	0	0
541	0	0
542	0	0
543	0	0
544	0	0
545	0	0
546	0	0
547	0	0
548	0	0
549	0	0
550	0	0
551	0	0
552	0	0
553	0	0
554	0	0
555	0	0
556	0	0
557	0	0
558	0	0
559	0	0
560	0	0
561	0	0
562	0	0
563	0	0
564	0	0
565	0	0
566	0	0
567	0	0
568	0	0
569	0	0
570	0	0
571	0	0
572	0	0
573	0	0
574	0	0
575	0	0
576	0	0
577	0	0
578	0	0
579	0	0
580	0	0
581	0	0
582	0	0
583	0	0
584	0	0
585	0	0
586	0	0
587	0	0
588	0	0
589	0	0
590	0	0
591	0	0
592	0	0
593	0	0
594	0	0
595	0	0
596	0	0
597	0	0
598	0	0
599	0	0
600	0	0
601	0	0
602	0	0
603	0	0
604	0	0
605	0	0
606	0	0
607	0	0
608	0	0
609	0	0
610	0	0
611	0	0
612	0	0
613	0	0
614	0	0
615	0	0
616	0	0
617	0	0
618	0	0
619	0	0
620	0	0
621	0	0
622	0	0
623	0	0
624	0	0
625	0	0
626	0	0
627	0	0
628	0	0
629	0	0
630	0	0
631	0	0
632	0	0
633	0	0
634	0	0
635	0	0
636	0	0
637	0	0
638	0	0
639	0	0
640	0	0
641	0	0
642	0	0
643	0	0
644	0	0
645	0	0
646	0	0
647	0	0
648	0	0
649	0	0
650	0	0
651	0	0
652	0	0
653	0	0
654	0	0
655	0	0
656	0	0
657	0	0
658	0	0
659	0	0
660	0	0
661	0	0
662	0	0
663	0	0
664	0	0
665	0	0
666	0	0
667	0	0
668	0	0
669	0	0
670	0	0
671	0	0
672	0	0
673	0	0
674	0	0
675	0	0
676	0	0
677	0	0
678	0	0
679	0	0
680	0	0
681	0	0
682	0	0
683	0	0
684	0	0
685	0	0
686	0	0
687	0	0
688	0	0
689	0	0
690	0	0
691	0	0
692	0	0
693	0	0
694	0	0
695	0	0
696	0	0
697	0	0
698	0	0
699	0	0
700	0	0
701	0	0
702	0	0
703	0	0
704	0	0
705	0	0
706	0	0
707	0	0
708	0	0
709	0	0
710	0	0
711	0	0
712	0	0
713	0	0
714	0	0
715	0	0
716	0	0
717	0	0
718	0	0
719	0	0
720	0	0
721	0	0
722	0	0
723	0	0
724	0	0
725	0	0
726	0	0
727	0	0
728	0	0
729	0	0
730	0	0
731	0	0
732	0	0
733	0	0
734	0	0
735	0	0
736	0	0
737	0	0
738	0	0
739	0	0
740	0	0
741	0	0
742	0	0
743	0	0
744	0	0
745	0	0
746	0	0
747	0	0
748	0	0
749	0	0
750	0	0
751	0	0
752	0	0
753	0	0
754	0	0
755	0	0
756	0	0
757	0	0
758	0	0
759	0	0
760	0	0
761	0	0
762	0	0
763	0	0
764	0	0
765	0	0
766	0	0
767	0	0
768	0	0
769	0	0
770	0	0
771	0	0
772	0	0
773	0	0
774	0	0
775	0	0
776	0	0
777	0	0
778	0	0
779	0	0
780	0	0
781	0	0
782	0	0
783	0	0
784	0	0
785	0	0
786	0	0
787	0	0
788	0	0
789	0	0
790	0	0
791	0	0
792	0	0
793	0	0
794	0	0
795	0	0
796	0	0
797	0	0
798	0	0
799	0	0
800	0	0
801	0	0
802	0	0
803	0	0
804	0	0
805	0	0
806	0	0
807	0	0
808	0	0
809	0	0
810	0	0
811	0	0
812	0	0
813	0	0
814	0	0
815	0	0
816	0	0
817	0	0
818	0	0
819	0	0
820	0	0
821	0	0
822	0	0
823	0	0
824	0	0
825	0	0
826	0	0
827	0	0
828	0	0
829	0	0
830	0	0
831	0	0
832	0	0
833	0	0
834	0	0
835	0	0
836	0	0
837	0	0
838	0	0
839	0	0
840	0	0
841	0	0
842	0	0
843	0	0
844	0	0
845	0	0
846	0	0
847	0	0
848	0	0
849	0	0
850	0	0
851	0	0
852	0	0
853	0	0
854	0	0
855	0	0
856	0	0
857	0	0
858	0	0
859	0	0
860	0	0
861	0	0
862	0	0
863	0	0
864	0	0
865	0	0
866	0	0
867	0	0
868	0	0
869	0	0
870	0	0
871	0	0
872	0	0
873	0	0
874	0	0
875	0	0
876	0	0
877	0	0
878	0	0
879	0	0
880	0	0
881	0	0
882	0	0
883	0	0
884	0	0
885	0	0
886	0	0
887	0	0
888	0	0
889	0	0
890	0	0
891	0	0
892	0	0
893	0	0
894	0	0
895	0	0
896	0	0
897	0	0
898	0	0
899	0	0
900	0	0
901	0	0
902	0	0
903	0	0
904	0	0
905	0	0
906	0	0
907	0	0
908	0	0
909	0	0
910	0	0
911	0	0
912	0	0
913	0	0
914	0	0
915	0	0
916	0	0
917	0	0
918	0	0
919	0	0
920	0	0
921	0	0
922	0	0
923	0	0
924	0	0
925	0	0
926	0	0
927	0	0
928	0	0
929	0	0
930	0	0
931	0	0
932	0	0
933	0	0
934	0	0
935	0	0
936	0	0
937	0	0
938	0	0
939	0	0
940	0	0
941	0	0
942	0	0
943	0	0
944	0	0
945	0	0
946	0	0
947	0	0
948	0	0
949	0	0
950	0	0
951	0	0
952	0	0
953	0	0
954	0	0
955	0	0
956	0	0
957	0	0
958	0	0
959	0	0
960	0	0
961	0	0
962	0	0
963	0	0
964	0	0
965	0	0
966	0	0
967	0	0
968	0	0
969	0	0
970	0	0
971	0	0
972	0	0
973	0	0
974	0	0
975	0	0
976	0	0
977	0	0
978	0	0
979	0	0
980	0	0
981	0	0
982	0	0
983	0	0
984	0	0
985	0	0
986	0	0
987	0	0
988	0	0
989	0	0
990	0	0
991	0	0
992	0	0
993	0	0
994	0	0
995	0	0
996	0	0
997	0	0
998	0	0
999	0	0
1000	0	0
1001	0	0
1002	0	0
1003	0	0
1004	0	0
1005	0	0
1006	0	0
1007	0	0
1008	0	0
1009	0	0
1010	0	0
1011	0	0
1012	0	0
1013	0	0
1014	0	0
1015	0	0
1016	0	0
1017	0	0
1018	0	0
1019	0	0
1020	0	0
1021	0	0
1022	0	0
1023	0	0
1024	0	0
1025	0	0
1026	0	0
1027	0	0
1028	0	0
1029	0	0
1030	0	0
1031	0	0
1032	0	0
1033	0	0
1034	0	0
1035	0	0
1036	0	0
1037	0	0
1038	0	0
1039	0	0
1040	0	0
1041	0	0
1042	0	0
1043	0	0
1044	0	0
1045	0	0
1046	0	0
1047	0	0
1048	0	0
1049	0	0
1050	0	0
1051	0	0
1052	0	0
1053	0	0
1054	0	0
1055	0	0
1056	0	0
1057	0	0
1058	0	0
1059	0	0
1060	0	0
1061	0	0
1062	0	0
1063	0	0
1064	0	0
1065	0	0
1066	0	0
1067	0	0
1068	0	0
1069	0	0
1070	0	0
1071	0	0
1072	0	0
1073	0	0
1074	0	0
1075	0	0
1076	0	0
1077	0	0
1078	0	0
1079	0	0
1080	0	0
1081	0	0
1082	0	0
1083	0	0
1084	0	0
1085	0	0
1086	0	0
1087	0	0
1088	0	0
1089	0	0
1090	0	0
1091	0	0
1092	0	0
1093	0	0
1094	0	0
1095	0	0
1096	0	0
1097	0	0
1098	0	0
1099	0	0
1100	0	0
1101	0	0
1102	0	0
1103	0	0
1104	0	0
1105	0	0
1106	0	0
1107	0	0
1108	0	0
1109	0	0
1110	0	0
1111	0	0
1112	0	0
1113	0	0
1114	0	0
1115	0	0
1116	0	0
1117	0	0
1118	0	0
\.


--
-- TOC entry 2974 (class 0 OID 0)
-- Dependencies: 207
-- Name: authors_id_author_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.authors_id_author_seq', 2871, true);


--
-- TOC entry 2975 (class 0 OID 0)
-- Dependencies: 208
-- Name: journals_id_journal_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.journals_id_journal_seq', 8, true);


--
-- TOC entry 2976 (class 0 OID 0)
-- Dependencies: 209
-- Name: keywords_id_keyword_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.keywords_id_keyword_seq', 5690, true);


--
-- TOC entry 2977 (class 0 OID 0)
-- Dependencies: 211
-- Name: publications_authors_id_publication_author_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.publications_authors_id_publication_author_seq', 2871, true);


--
-- TOC entry 2978 (class 0 OID 0)
-- Dependencies: 212
-- Name: publications_id_publication_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.publications_id_publication_seq', 1118, true);


--
-- TOC entry 2979 (class 0 OID 0)
-- Dependencies: 214
-- Name: publications_keywords_id_publication_keyword_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.publications_keywords_id_publication_keyword_seq', 5690, true);


--
-- TOC entry 2980 (class 0 OID 0)
-- Dependencies: 215
-- Name: ratings_id_rating_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ratings_id_rating_seq', 1118, true);


--
-- TOC entry 2778 (class 2606 OID 16940)
-- Name: authors authors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_pkey PRIMARY KEY (id_author);


--
-- TOC entry 2781 (class 2606 OID 16942)
-- Name: journals journals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.journals
    ADD CONSTRAINT journals_pkey PRIMARY KEY (id_journal);


--
-- TOC entry 2786 (class 2606 OID 16944)
-- Name: keywords keywords_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.keywords
    ADD CONSTRAINT keywords_pkey PRIMARY KEY (id_keyword);


--
-- TOC entry 2798 (class 2606 OID 16946)
-- Name: publications_authors publications_authors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publications_authors
    ADD CONSTRAINT publications_authors_pkey PRIMARY KEY (id_publication_author);


--
-- TOC entry 2801 (class 2606 OID 16948)
-- Name: publications_keywords publications_keywords_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publications_keywords
    ADD CONSTRAINT publications_keywords_pkey PRIMARY KEY (id_publication_keyword);


--
-- TOC entry 2792 (class 2606 OID 16950)
-- Name: publications publications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publications
    ADD CONSTRAINT publications_pkey PRIMARY KEY (id_publication);


--
-- TOC entry 2795 (class 2606 OID 16952)
-- Name: ratings ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_pkey PRIMARY KEY (id_rating);


--
-- TOC entry 2775 (class 1259 OID 16953)
-- Name: authors_full_name_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX authors_full_name_uindex ON public.authors USING btree (full_name);


--
-- TOC entry 2776 (class 1259 OID 16954)
-- Name: authors_id_author_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX authors_id_author_uindex ON public.authors USING btree (id_author);


--
-- TOC entry 2779 (class 1259 OID 16955)
-- Name: journals_id_journal_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX journals_id_journal_uindex ON public.journals USING btree (id_journal);


--
-- TOC entry 2782 (class 1259 OID 16956)
-- Name: journals_title_en_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX journals_title_en_uindex ON public.journals USING btree (title_en);


--
-- TOC entry 2783 (class 1259 OID 16957)
-- Name: journals_title_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX journals_title_uindex ON public.journals USING btree (title);


--
-- TOC entry 2784 (class 1259 OID 16958)
-- Name: keywords_id_keyword_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX keywords_id_keyword_uindex ON public.keywords USING btree (id_keyword);


--
-- TOC entry 2787 (class 1259 OID 16959)
-- Name: keywords_word_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX keywords_word_uindex ON public.keywords USING btree (word);


--
-- TOC entry 2796 (class 1259 OID 16960)
-- Name: publications_authors_id_publication_author_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX publications_authors_id_publication_author_uindex ON public.publications_authors USING btree (id_publication_author);


--
-- TOC entry 2788 (class 1259 OID 16961)
-- Name: publications_doi_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX publications_doi_uindex ON public.publications USING btree (doi);


--
-- TOC entry 2789 (class 1259 OID 16962)
-- Name: publications_id_publication_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX publications_id_publication_uindex ON public.publications USING btree (id_publication);


--
-- TOC entry 2790 (class 1259 OID 16963)
-- Name: publications_id_raiting_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX publications_id_raiting_uindex ON public.publications USING btree (id_rating);


--
-- TOC entry 2799 (class 1259 OID 16964)
-- Name: publications_keywords_id_publication_keyword_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX publications_keywords_id_publication_keyword_uindex ON public.publications_keywords USING btree (id_publication_keyword);


--
-- TOC entry 2793 (class 1259 OID 16965)
-- Name: ratings_id_rating_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ratings_id_rating_uindex ON public.ratings USING btree (id_rating);


--
-- TOC entry 2808 (class 2620 OID 16966)
-- Name: authors dont_delete_null_record_authors; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER dont_delete_null_record_authors BEFORE DELETE ON public.authors FOR EACH ROW WHEN ((old.id_author = 0)) EXECUTE FUNCTION public.dont_delete_null_record();


--
-- TOC entry 2810 (class 2620 OID 16967)
-- Name: journals dont_delete_null_record_journals; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER dont_delete_null_record_journals BEFORE DELETE ON public.journals FOR EACH ROW WHEN ((old.id_journal = 0)) EXECUTE FUNCTION public.dont_delete_null_record();


--
-- TOC entry 2812 (class 2620 OID 16968)
-- Name: keywords dont_delete_null_record_keywords; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER dont_delete_null_record_keywords BEFORE DELETE ON public.keywords FOR EACH ROW WHEN ((old.id_keyword = 0)) EXECUTE FUNCTION public.dont_delete_null_record();


--
-- TOC entry 2814 (class 2620 OID 16969)
-- Name: publications dont_delete_null_record_publications; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER dont_delete_null_record_publications BEFORE DELETE ON public.publications FOR EACH ROW WHEN ((old.id_publication = 0)) EXECUTE FUNCTION public.dont_delete_null_record();


--
-- TOC entry 2818 (class 2620 OID 16970)
-- Name: publications_authors dont_delete_null_record_publications_authors; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER dont_delete_null_record_publications_authors BEFORE DELETE ON public.publications_authors FOR EACH ROW WHEN ((old.id_publication_author = 0)) EXECUTE FUNCTION public.dont_delete_null_record();


--
-- TOC entry 2820 (class 2620 OID 16971)
-- Name: publications_keywords dont_delete_null_record_publications_keywords; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER dont_delete_null_record_publications_keywords BEFORE DELETE ON public.publications_keywords FOR EACH ROW WHEN ((old.id_publication_keyword = 0)) EXECUTE FUNCTION public.dont_delete_null_record();


--
-- TOC entry 2816 (class 2620 OID 16972)
-- Name: ratings dont_delete_null_record_ratings; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER dont_delete_null_record_ratings BEFORE DELETE ON public.ratings FOR EACH ROW WHEN ((old.id_rating = 0)) EXECUTE FUNCTION public.dont_delete_null_record();


--
-- TOC entry 2809 (class 2620 OID 16973)
-- Name: authors dont_update_null_record_authors; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER dont_update_null_record_authors BEFORE UPDATE ON public.authors FOR EACH ROW WHEN ((old.id_author = 0)) EXECUTE FUNCTION public.dont_update_null_record();


--
-- TOC entry 2811 (class 2620 OID 16974)
-- Name: journals dont_update_null_record_journals; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER dont_update_null_record_journals BEFORE UPDATE ON public.journals FOR EACH ROW WHEN ((old.id_journal = 0)) EXECUTE FUNCTION public.dont_update_null_record();


--
-- TOC entry 2813 (class 2620 OID 16975)
-- Name: keywords dont_update_null_record_keywords; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER dont_update_null_record_keywords BEFORE UPDATE ON public.keywords FOR EACH ROW WHEN ((old.id_keyword = 0)) EXECUTE FUNCTION public.dont_update_null_record();


--
-- TOC entry 2815 (class 2620 OID 16976)
-- Name: publications dont_update_null_record_publications; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER dont_update_null_record_publications BEFORE UPDATE ON public.publications FOR EACH ROW WHEN ((old.id_publication = 0)) EXECUTE FUNCTION public.dont_update_null_record();


--
-- TOC entry 2819 (class 2620 OID 16977)
-- Name: publications_authors dont_update_null_record_publications_authors; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER dont_update_null_record_publications_authors BEFORE UPDATE ON public.publications_authors FOR EACH ROW WHEN ((old.id_publication_author = 0)) EXECUTE FUNCTION public.dont_update_null_record();


--
-- TOC entry 2821 (class 2620 OID 16978)
-- Name: publications_keywords dont_update_null_record_publications_keywords; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER dont_update_null_record_publications_keywords BEFORE UPDATE ON public.publications_keywords FOR EACH ROW WHEN ((old.id_publication_keyword = 0)) EXECUTE FUNCTION public.dont_update_null_record();


--
-- TOC entry 2817 (class 2620 OID 16979)
-- Name: ratings dont_update_null_record_ratings; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER dont_update_null_record_ratings BEFORE UPDATE ON public.ratings FOR EACH ROW WHEN ((old.id_rating = 0)) EXECUTE FUNCTION public.dont_update_null_record();


--
-- TOC entry 2804 (class 2606 OID 16980)
-- Name: publications_authors publications_authors_id_author_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publications_authors
    ADD CONSTRAINT publications_authors_id_author_fkey FOREIGN KEY (id_author) REFERENCES public.authors(id_author);


--
-- TOC entry 2805 (class 2606 OID 16985)
-- Name: publications_authors publications_authors_id_publication_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publications_authors
    ADD CONSTRAINT publications_authors_id_publication_fkey FOREIGN KEY (id_publication) REFERENCES public.publications(id_publication);


--
-- TOC entry 2802 (class 2606 OID 16990)
-- Name: publications publications_journals_id_journal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publications
    ADD CONSTRAINT publications_journals_id_journal_fkey FOREIGN KEY (id_journal) REFERENCES public.journals(id_journal);


--
-- TOC entry 2806 (class 2606 OID 16995)
-- Name: publications_keywords publications_keywords_id_keyword_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publications_keywords
    ADD CONSTRAINT publications_keywords_id_keyword_fkey FOREIGN KEY (id_keyword) REFERENCES public.keywords(id_keyword);


--
-- TOC entry 2807 (class 2606 OID 17000)
-- Name: publications_keywords publications_keywords_id_publication_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publications_keywords
    ADD CONSTRAINT publications_keywords_id_publication_fkey FOREIGN KEY (id_publication) REFERENCES public.publications(id_publication);


--
-- TOC entry 2803 (class 2606 OID 17005)
-- Name: publications publications_ratings_id_rating_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publications
    ADD CONSTRAINT publications_ratings_id_rating_fkey FOREIGN KEY (id_rating) REFERENCES public.ratings(id_rating);


-- Completed on 2019-10-23 00:45:34

--
-- PostgreSQL database dump complete
--

