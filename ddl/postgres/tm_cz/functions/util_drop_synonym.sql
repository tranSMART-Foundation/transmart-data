--
-- Name: util_drop_synonym(character varying); Type: FUNCTION; Schema: tm_cz; Owner: -
--
CREATE OR REPLACE FUNCTION util_drop_synonym (
  v_objname IN character varying DEFAULT NULL
)
--AUTHID CURRENT_USER
 RETURNS VOID AS $body$
DECLARE

-------------------------------------------------------------------------------------
-- NAME: UTIL_DROP_SYNONYM
--
-- Copyright c 2011 Recombinant Data Corp.
--

--------------------------------------------------------------------------------------
   v_cmdline varchar(100);

   ts CURSOR FOR
     SELECT 'drop synonym ' || synonym_name || ' ' from user_synonyms;



BEGIN

  OPEN ts;
   FETCH ts INTO v_cmdline;
   WHILE ts%FOUND
   LOOP

      BEGIN
         BEGIN

            BEGIN
               EXECUTE v_cmdline;
               RAISE NOTICE '%%', 'SUCCESS ' ,  v_cmdline;
            END;
         EXCEPTION
            WHEN OTHERS THEN

               BEGIN
                  RAISE NOTICE '%%', 'ERROR ' ,  v_cmdline;
               END;
         END;
         FETCH ts INTO v_cmdline;
      END;
   END LOOP;
   CLOSE ts;
END;
 
$body$
LANGUAGE PLPGSQL;
