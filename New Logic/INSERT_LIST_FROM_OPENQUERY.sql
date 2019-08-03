--
--       VICIDIAL LISTS

INSERT  OPENQUERY 
(
[VICIDIAL],
'
    SELECT 
        list_id,
        list_name,
        campaign_id,
        active,
        list_description,
        list_changedate,
        list_lastcalldate,
        reset_time,
        agent_script_override,
        campaign_cid_override,
        am_message_exten_override,
        drop_inbound_group_override,
        xferconf_a_number,
        xferconf_b_number,
        xferconf_c_number,
        xferconf_d_number,
        xferconf_e_number,
        web_form_address,
        web_form_address_two,
        time_zone_setting,
        inventory_report,
        expiration_date,
        na_call_url,
        local_call_time,
        web_form_address_three,
        status_group_id,
        user_new_lead_limit,
        inbound_list_script_override,
        default_xfer_group,
        daily_reset_limit,
        resets_today
    FROM vicidial_lists
'
)
VALUES
(
	1000001,	        --  LIST_ID
	'Autolist_EFNI',	--  LIST_NAME
	'EFNI',	            --  CAMPAIGN_ID
	'N',	            --  ACTIVE
	'Lista de carga de base automatica para Equipos Financiados',	-- LIST_DESCRIPTION
	NULL,	            -- LIST_CHANGEDATE
	NULL,		        -- LIST_LASTCALLDATE
	NULL,		        -- RESET_TIME
	NULL,		        -- AGENT_SCRIPT_OVERRIDE
	NULL,		        -- CAMPAING_CID_OVERRIDE
	NULL,		        -- AM_MESSAGE_EXTEND_OVERRIDE
	NULL,		        -- DROP_INBOUND_GROUP_OVERRIDE
	NULL,		        -- XFERCONF_A_NUMBER
	NULL,		        -- XFERCONF_B_NUMBER
	NULL,		        -- XFERCONF_C_NUMBER
	NULL,		        -- XFERCONF_D_NUMBER
	NULL,		        -- XFERCONF_E_NUMBER
	NULL, 	            -- WEB_FORM_ADDRESS
	NULL,		        -- WEB_FORM_ADDRESS_TWO
	'COUNTRY_AND_AREA_CODE', -- TIME_ZONE_SETTING
	'Y',		        -- INVENTORY_REPORT
	'2099-12-31',       -- EXPIRATION_DATE
	NULL,	            -- NA_CALL_URL
	'campaign',	        -- LOCAL_CALL_TIME
	NULL,		        -- WEB_FORM_ADDRESS_THREE
	NULL,		        -- STATUS_GROUP_ID
	-1,			        -- USER_NEW_LEAD_LIMIT
	NULL,		        -- INBOUND_LIST_SCRIPT_OVERRIDE
	'-- -NONE-- -',	    -- DEFAULT_XFER_GROUP
	-1,		            -- DAILY_RESET_LIMIT
	0			        -- RESETS_TODAY
)



--
--
-- VICIDIAL LIST


DECLARE @LIST_ID INT,
        @PHONE_NUMBER INT,
        @FIRST_NAME NVARCHAR(MAX),
        @DOMICILIO NVARCHAR(MAX),
        @SALARIO FLOAT,				
        @CEDULA NVARCHAR(16),				
        @DEPARTAMENTO NVARCHAR(50),
        @CIUDAD NVARCHAR(50),
        @ALT_PHONE INT,				
	    @STATUS_CREDEX NVARCHAR(50),
        @TARJETA NVARCHAR(50)

SET @LIST_ID = 1000001
SET @PHONE_NUMBER = 87654321
SET @FIRST_NAME = 'TESTING TEST'
SET @DOMICILIO = 'DOMINIC'
SET @SALARIO = 123			
SET @CEDULA = '4071243232231B'			
SET @DEPARTAMENTO = 'MyDepartment'
SET @CIUDAD = 'MyCity'
SET @ALT_PHONE = 12345678		
SET	@STATUS_CREDEX = 'CREDEX'
SET @TARJETA= 'BANCO 1'

INSERT  OPENQUERY 
(
[VICIDIAL],
'
    SELECT 
	entry_date,
	modify_date,
	status,
	user,
	vendor_lead_code,
	source_id,list_id,
	gmt_offset_now,
	called_since_last_reset,
	phone_code,
	phone_number,
	title,first_name,
	middle_initial,
	last_name,
	address1,
	address2,
	address3,
	city,
	state,
	province,
	postal_code,
	country_code,
	gender,
	date_of_birth,
	alt_phone,
	email,
	security_phrase,
	comments,
	called_count,
	last_local_call_time,
	rank,
	owner,
	entry_list_id
        FROM vicidial_list
'
)
values
(
	-- 835920,				-- lead_id
	GETDATE(),				-- entry_date
	NULL,               	-- modify_date
	'NEW',					-- status
	NULL,					-- user
	NULL,					-- vendor_lead_code
	NULL,					-- source_id
	@LIST_ID,				-- list_id
	'-6',					-- gmt_offset_now
	'N',					-- called_since_last_reset
	'505',					-- phone_code
	@PHONE_NUMBER,			-- phone_number
	NULL,					-- title
	@FIRST_NAME,			-- first_name
	NULL,					-- middle_initial
	NULL,					-- last_name
	@DOMICILIO,				-- address1
	@SALARIO,				-- address2
	@CEDULA,				-- address3
	@DEPARTAMENTO,			-- city
	NULL,					-- state
	@CIUDAD,				-- province
	NULL,					-- postal_code
	NULL,					-- country_code
	NULL,					-- gender
	NULL,			-- date_of_birth
	@ALT_PHONE,				-- alt_phone
	@STATUS_CREDEX,			-- email
	NULL,					-- security_phrase
	@TARJETA,				-- comments
	0,						-- called_count
	NULL,			-- last_local_call_time
	0,						-- rank
	NULL,					-- owner
	0						-- entry_list_id
)

