-----------------------------------------------------------------------
--             DO NOT EDIT THIS FILE. IT IS AUTOGENERATED            --
-- Edit the original file in the macroed_functions directory instead --
-----------------------------------------------------------------------
-- Generated by Ora2Pg, the Oracle database Schema converter, version 11.4
-- Copyright 2000-2013 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=mydb.mydom.fr;sid=SIDNAME


CREATE OR REPLACE FUNCTION tm_cz.rwg_add_taxonomy_term (
	New_Term_in character varying,
	parent_term_in character varying,
	category_term_in character varying,
	currentJobID numeric DEFAULT (-1)
)
 RETURNS BIGINT AS $body$
DECLARE

/*************************************************************************
* Copyright 2008-2012 Janssen Research & Development, LLC.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
******************************************************************/
--Audit variables
	newJobFlag    smallint;
	databaseName  varchar(100);
	procedureName varchar(100);
	jobID         integer;
	stepCt        integer;
	rowCt         integer;
	errorNumber   varchar;
	errorMessage  varchar;


	Parent_Id integer;
	New_Term_in_Id integer;
	keyword_id integer;
	Lcount integer;
	Ncount integer;
	--Existing_Term Exception;
BEGIN
	--Set Audit Parameters
	newJobFlag := 0; -- False (Default)
	jobID := currentJobID;
	SELECT current_user INTO databaseName; --(sic)
	procedureName := 'RWG_ADD_TAXONOMY_TERM';

	--Audit JOB Initialization
	--If Job ID does not exist, then this is a single procedure run and we need to create it
	IF (coalesce(jobID::text, '') = '' OR jobID < 1)
		THEN
		newJobFlag := 1; -- True
		SELECT cz_start_audit(procedureName, databaseName) INTO jobID;
	END IF;
	PERFORM cz_write_audit(jobId, databaseName, procedureName,
		'Start FUNCTION', 0, stepCt, 'Done');
	stepCt := 1;

	PERFORM cz_write_audit(jobId, databaseName, procedureName,
		'Term: ' || New_Term_in, 0, stepCt, 'Done');
	stepCt := stepCt + 1;

	PERFORM cz_write_audit(jobId, databaseName, procedureName,
		'Category: ' || category_term_in, 0, stepCt, 'Done');
	stepCt := stepCt + 1;

	PERFORM cz_write_audit(jobId, databaseName, procedureName,
		'Parent: ' || parent_term_in, 0, stepCt, 'Done');
	stepCt := stepCt + 1;

	/*
	0. Check if term exists in Search_Keyword_term
	1. Insert term into Searchapp.search_keyword
	2. Insert term into Searchapp.Search_Keyword_term
	3. Find parent
	4. Insert new term into Searchapp.Search_Taxonomy
	5. Find id of new term
	6. Insert relationship into searchapp.search_taxonomy_rels
	 */
	-- Get the data category using the parent term
	/*
	Select distinct(data_category)
	into category_term_in
	From Searchapp.Search_Keyword Where Upper(Keyword)
	like upper(parent_term_in) or upper(display_data_category) like upper(parent_term_in);
	 */
	-- check if the new term exists (use the keyword AND the category, as the same
	-- term name may be used in more than 1 category
	SELECT
		COUNT ( * )
		INTO Ncount
	FROM
		Searchapp.Search_Keyword
	WHERE
		UPPER ( Keyword ) = UPPER ( New_Term_in )
		AND UPPER ( data_category ) LIKE UPPER ( category_term_in );
	--If(Ncount>0) Then
	-- RAISE Existing_Term;
	--END IF;
	-- Insert taxonomy term into searchapp.search_keyword
	IF Ncount = 0 THEN
		BEGIN
		INSERT INTO Searchapp.Search_Keyword (
			Data_Category,
			Keyword,
			Unique_Id,
			Source_Code,
			Display_Data_Category )
		SELECT
			DISTINCT data_category,
			New_Term_in,
			'RWG:' || data_category || ':' || New_Term_in,
			'RWG_ADD_TAXONOMY_TERM',
			Display_Data_Category
		FROM
			Searchapp.Search_Keyword
		WHERE
			UPPER ( display_data_category ) LIKE UPPER ( category_term_in );
		/*
		Insert Into Searchapp.Search_Keyword (Data_Category, Keyword, Unique_Id, Source_Code, Display_Data_Category)
		Select category_term_in, New_Term_in, 'RWG:'|| category_term_in || ':' || New_Term_in, 'RWG_ADD_TAXONOMY_TERM', category_term_in from dual;
		 */
		GET DIAGNOSTICS rowCt := ROW_COUNT;
	PERFORM cz_write_audit(jobId, databaseName, procedureName,
		'Term added to Searchapp.Search_Keyword', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		PERFORM cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		PERFORM cz_end_audit (jobID, 'FAIL');
		RETURN -16;
	END;
	END IF;

	-- Get the ID of the new term in Search_Keyword
	BEGIN
	SELECT
		Search_Keyword_Id INTO Keyword_Id
	FROM
		Searchapp.Search_Keyword
	WHERE
		UPPER ( Keyword ) = UPPER ( New_Term_in )
		AND UPPER ( data_category ) LIKE UPPER ( category_term_in );
	GET DIAGNOSTICS rowCt := ROW_COUNT;
	PERFORM cz_write_audit(jobId, databaseName, procedureName,
		'New search keyword ID stored in Keyword_Id', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		PERFORM cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		PERFORM cz_end_audit (jobID, 'FAIL');
		RETURN -16;
	END;

	-- Insert the new term into Searchapp.Search_Keyword_Term
	BEGIN
	INSERT INTO Searchapp.Search_Keyword_Term (
		Keyword_Term,
		Search_Keyword_Id,
		RANK,
		Term_Length )
	SELECT
		New_Term_in,
		Keyword_Id,
		1,
		LENGTH ( New_Term_in )
	WHERE
		NOT EXISTS (
			SELECT
				1
			FROM
				searchapp.search_keyword_term x
			WHERE
				x.search_keyword_id = Keyword_Id );
	GET DIAGNOSTICS rowCt := ROW_COUNT;
	PERFORM cz_write_audit(jobId, databaseName, procedureName,
		'Term added to Searchapp.Search_Keyword_Term', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		PERFORM cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		PERFORM cz_end_audit (jobID, 'FAIL');
		RETURN -16;
	END;

	-- Get the ID of the parent term
	SELECT
		DISTINCT Term_Id
	INTO Parent_Id
	FROM
		Searchapp.Search_Taxonomy
	WHERE
		UPPER ( Term_Name ) LIKE UPPER ( parent_term_in );

	IF COALESCE(Parent_Id,-1) > 0 THEN
		-- Insert the new term into the taxonomy
		BEGIN
		INSERT INTO Searchapp.Search_Taxonomy (
			term_name,
			source_cd,
			import_date,
			search_keyword_id )
		SELECT
			New_Term_in,
			parent_term_in || ':' || New_Term_in,
			LOCALTIMESTAMP,
			Keyword_Id
		WHERE
			NOT EXISTS (
				SELECT
					1
				FROM
					searchapp.search_taxonomy x
				WHERE
					x.search_keyword_id = Keyword_Id );
		GET DIAGNOSTICS rowCt := ROW_COUNT;
	PERFORM cz_write_audit(jobId, databaseName, procedureName,
		'Term added to Searchapp.Search_Taxonomy', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		PERFORM cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		PERFORM cz_end_audit (jobID, 'FAIL');
		RETURN -16;
	END;

		-- Get the ID of the new term
		SELECT
			DISTINCT Term_Id INTO New_Term_in_Id
		FROM
			Searchapp.Search_Taxonomy
		WHERE
			UPPER ( Term_Name ) LIKE UPPER ( New_Term_in );

		BEGIN
		INSERT INTO Searchapp.Search_Taxonomy_Rels (
			Child_Id,
			Parent_Id )
		SELECT
			New_Term_in_Id,
			Parent_Id
		WHERE
			NOT EXISTS (
				SELECT
					1
				FROM
					searchapp.search_taxonomy_rels x
				WHERE
					x.child_id = New_Term_in_Id
					AND x.parent_id = Parent_id );
		GET DIAGNOSTICS rowCt := ROW_COUNT;
	PERFORM cz_write_audit(jobId, databaseName, procedureName,
		'Term relationship added to Searchapp.Search_Taxonomy_Rels', rowCt, stepCt, 'Done');
	stepCt := stepCt + 1;
	EXCEPTION
		WHEN OTHERS THEN
		errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		PERFORM cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		PERFORM cz_end_audit (jobID, 'FAIL');
		RETURN -16;
	END;
	END IF;

	---Cleanup OVERALL JOB if this proc is being run standalone
	IF newJobFlag = 1
		THEN
		PERFORM cz_end_audit (jobID, 'SUCCESS');
	END IF;
EXCEPTION
	WHEN OTHERS THEN
	errorNumber := SQLSTATE;
		errorMessage := SQLERRM;
		PERFORM cz_error_handler(jobID, procedureName, errorNumber, errorMessage);
		PERFORM cz_end_audit (jobID, 'FAIL');
		RETURN -16;
END;
$body$
LANGUAGE PLPGSQL;


