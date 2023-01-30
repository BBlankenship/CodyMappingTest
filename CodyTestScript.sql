--Added a USe assuming the DB name will be the same
USE [CodyMappingTraining]

--Need to declare a table instead of INTO Add logic to check if Temp table already exists too

DROP TABLE IF EXISTS #PhoneNumbers 
SELECT Id 
       ,PersonId
	   ,PhoneNumber OrignalPhoneNumber
	   ,TRIM(CASE 
             WHEN CHARINDEX('x',PhoneNumber) > 0 
	         THEN  SUBSTRING( PhoneNumber ,1,CHARINDEX('x',PhoneNumber)-1)	         	     
	         ELSE PhoneNumber 	         		 
	         END) PhoneNumber
	   ,CASE 
           WHEN CHARINDEX('x',PhoneNumber) > 0 
	       THEN SUBSTRING( PhoneNumber ,CHARINDEX('x',PhoneNumber)+1,len(PhoneNumber)-CHARINDEX('x',PhoneNumber)+1)
	       ELSE NULL
	       END Extension
	   ,Type
INTO #PhoneNumbers
FROM [src].[Phone] p

--Remove country code 1- this would ahve to be more elaborate if there were phone numbers from different countries (2 or 3 digit instead of 1 in some cases) 
UPDATE #PhoneNumbers
SET PhoneNumber = CASE 
	         WHEN CHARINDEX('1-',PhoneNumber) = 1 
	         THEN RIGHT(PhoneNumber, LEN(PhoneNumber)-2) 			  
			 ELSE PhoneNumber 
			 END
--Adding (###) formatting. Could be more elaborate but the phone numbers are format the same way with dashes
UPDATE #PhoneNumbers
SET PhoneNumber =  '('+STUFF(PhoneNumber, CHARINDEX('-',PhoneNumber),LEN('-'),') ')

--Same as above; Need to declare a table instead of INTO Add logic to check if Temp table already exists too
DROP TABLE IF EXISTS #CleanedPhoneNumbers 
SELECT PersonId,
MAX(CASE WHEN Type = 'Home' THEN PhoneNumber END) AS HomePhone,
MAX(CASE WHEN Type = 'Home' THEN Extension END) AS HomeExtension,
MAX(CASE WHEN Type = 'Cell' THEN PhoneNumber END) AS CellPhone,
MAX(CASE WHEN Type = 'Cell' THEN Extension END) AS CellExtension,
MAX(CASE WHEN Type = 'Work' THEN PhoneNumber END) AS WorkPhone,
MAX(CASE WHEN Type = 'Work' THEN Extension END) AS WorkExtension
INTO #CleanedPhoneNumbers
FROM #PhoneNumbers p
GROUP BY PersonId


--Could list the columns out if there was a need for clarity
INSERT INTO [dst].[Mastname]
(           [Recnum]
           ,[FName]
           ,[MName]
           ,[LName]
           ,[Suffix]
           ,[Age]
           ,[House]
           ,[Street]
           ,[City]
           ,[State]
           ,[Zip]
           ,[ZipExtension]
           ,[Height]
           ,[Weight]
           ,[Ethnicity_Code]
           ,[Ethnicity_Desc]
           ,[Race_Code]
           ,[Race_Desc]
           ,[Build_Code]
           ,[Build_Desc]
           ,[Complexion_Code]
           ,[Complexion_Desc]
           ,[EyeColor_Code]
           ,[EyeColor_Desc]
           ,[Sex_Code]
           ,[Sex_Desc]
           ,[HairColor_Code]
           ,[HairColor_Desc]
           ,[SSN]
           ,[DRLic]
           ,[DRLic_StateCode]
           ,[DRLic_StateDesc]
           ,[Passport]
           ,[Phone1]
           ,[Phone1_Extension]
           ,[Phone2]
           ,[Phone2_Extension]
           ,[Phone3]
           ,[Phone3_Extension])
 --Recnum - I don't know what this is. I am going to assume it's an incremental number that needs to increase from the last one for now. 
 --If it is based on value from source, I don't see it
 --Other methods maybe be better if there lots of inserting happening, but this should work in this test case
 SELECT
      ROW_NUMBER() OVER(ORDER BY pt.id) +(SELECT MAX(RecNum) FROM [dst].[Mastname]),
       pt.FirstName,
       pt.MiddleName,
       pt.LastName,
       pt.NameSufx,
       pt.Age,
	   --This works with this data but have to be aware of the potential of a 112A Street Name (not in this data). It might be better to look first first space CHARINDEX(' ',pt.Street)
       LEFT(pt.Street,patindex('%[^0-9]%', pt.Street)-1) House,
       SUBSTRING(pt.Street,patindex('%[^0-9]%', pt.Street)+1,len(pt.Street)) Street,
       pt.City,
       pt.State,
       CASE WHEN CHARINDEX('-',pt.Zip) > 0 THEN SUBSTRING(pt.Zip,1,CHARINDEX('-',pt.Zip)-1) ELSE pt.Zip END Zip,
       CASE WHEN CHARINDEX('-',pt.Zip) > 0 THEN SUBSTRING(pt.Zip,CHARINDEX('-',pt.Zip)+1,len(pt.Zip)-CHARINDEX('-',pt.Zip)+1) ELSE NULL END ZipExtension,
	   --I assume Height in MastName is feet and inches concatenated  
       CASE WHEN HEIGHT IS NOT NULL THEN CONCAT(ppf.Height/12,RIGHT('00'+CONVERT(VARCHAR,ppf.Height%12),2)) ELSE NULL END Height,
       ppf.Weight,
	   --Src and MastName seem to have these values flipped. I am going to assume MastName is correct way to load it.
	   cr.Race,--?
       cr.Description RaceDesc,--?
	   ce.Ethnicity,--??
       ce.Description EthnicityDesc,--??
	   ---------------------------------
	   --Build code wouldn't fit so I trimmed off the end. Not sure if this is correct, but best I could without more info.
       LEFT(cb.build,6),
       cb.Description BuildDesc,
       cc.Complexion,
       cc.Description ComplexionDesc,
       ec.Eye,
       ec.Description EyeDesc,
       cs.Sex,
       cs.Description SexDesc,
       hc.Hair,
       hc.Description HairDesc,
       SUBSTRING(pit.SSN,1,3)+'-'+SUBSTRING(pit.SSN,4,2)+'-'+SUBSTRING(pit.SSN,6,4)
       ,DriversLicense
	--Needs to have a table created with these values or a function to get the Abbr or maybe even a view or TVF could work if you want to do it as a join
       ,CASE DriversLicenseState
             WHEN 'Alabama' THEN 'AL' 
             WHEN 'Alaska' THEN 'AK' 
             WHEN 'Arizona' THEN 'AZ' 
             WHEN 'Arkansas' THEN 'AR' 
             WHEN 'California' THEN 'CA' 
             WHEN 'Colorado' THEN 'CO' 
             WHEN 'Connecticut' THEN 'CT' 
             WHEN 'Delaware' THEN 'DE' 
             WHEN 'District of Columbia' THEN 'DC' 
             WHEN 'Florida' THEN 'FL' 
             WHEN 'Georgia' THEN 'GA' 
             WHEN 'Hawaii' THEN 'HI' 
             WHEN 'Idaho' THEN 'ID' 
             WHEN 'Illinois' THEN 'IL' 
             WHEN 'Indiana' THEN 'IN' 
             WHEN 'Iowa' THEN 'IA' 
             WHEN 'Kansas' THEN 'KS' 
             WHEN 'Kentucky' THEN 'KY' 
             WHEN 'Louisiana' THEN 'LA' 
             WHEN 'Maine' THEN 'ME' 
             WHEN 'Maryland' THEN 'MD' 
             WHEN 'Massachusetts' THEN 'MA' 
             WHEN 'Michigan' THEN 'MI' 
             WHEN 'Minnesota' THEN 'MN' 
             WHEN 'Mississippi' THEN 'MS' 
             WHEN 'Missouri' THEN 'MO' 
             WHEN 'Montana' THEN 'MT' 
             WHEN 'Nebraska' THEN 'NE' 
             WHEN 'Nevada' THEN 'NV' 
             WHEN 'New Hampshire' THEN 'NH' 
             WHEN 'New Jersey' THEN 'NJ' 
             WHEN 'New Mexico' THEN 'NM' 
             WHEN 'New York' THEN 'NY' 
             WHEN 'North Carolina' THEN 'NC' 
             WHEN 'North Dakota' THEN 'ND' 
             WHEN 'Ohio' THEN 'OH' 
             WHEN 'Oklahoma' THEN 'OK' 
             WHEN 'Oregon' THEN 'OR' 
             WHEN 'Pennsylvania' THEN 'PA' 
             WHEN 'Rhode Island' THEN 'RI' 
             WHEN 'South Carolina' THEN 'SC' 
             WHEN 'South Dakota' THEN 'SD' 
             WHEN 'Tennessee' THEN 'TN' 
             WHEN 'Texas' THEN 'TX' 
             WHEN 'Utah' THEN 'UT' 
             WHEN 'Vermont' THEN 'VT' 
             WHEN 'Virginia' THEN 'VA' 
             WHEN 'Washington' THEN 'WA' 
             WHEN 'West Virginia' THEN 'WV' 
             WHEN 'Wisconsin' THEN 'WI' 
             WHEN 'Wyoming' THEN 'WY' 
                 ELSE NULL
             END StateAbbrv
       ,DriversLicenseState
       ,Passport
       
       /*	   
       Probably could be made into a function if this is a common occurence. Probably would create something called fnCleanPhoneNumber. Probably strip off any extensions. 
       Get just numbers and then see if there is a country code included (number len). If so, grab the right 10 numbers. 
       You can do the preferred formatting in the function or format the 10 numbers returned in the desired format
       */
       ,cpn.HomePhone
       , cpn.HomeExtension
       ,cpn.CellPhone 
       ,cpn.CellExtension
       ,cpn.WorkPhone
       ,cpn.WorkExtension
  FROM [src].[PersonTable] pt 
  INNER JOIN [src].[PersonIdentifierTable] pit ON pit.PersonId = pt.id
  CROSS APPLY (SELECT top 1 * FROM [src].[PersonPhysicalFeatureTable] ppf WHERE pt.Id = ppf.PersonId ORDER BY ppf.AsOfDate DESC) ppf
  LEFT JOIN #CleanedPhoneNumbers cpn on cpn.PersonId = pt.id
  LEFT JOIN [src].[CodeBuild] cb on cb.Id = ppf.BuildId
  LEFT JOIN [src].[CodeEthnicity] ce on ce.Id = ppf.EthnicityId
  LEFT JOIN [src].[CodeEyeColor] ec on ec.Id = ppf.EyeColorId
  LEFT JOIN [src].[CodeHairColor] hc on hc.Id = ppf.HairColorId
  LEFT JOIN [src].[CodeComplexion] cc on cc.Id = ppf.ComplexionId
  LEFT JOIN [src].[CodeRace] cr on cr.Id = ppf.RaceId
  LEFT JOIN [src].[CodeSex] cs on cs.Id = ppf.SexId


DROP TABLE IF EXISTS #PhoneNumbers 
DROP TABLE IF EXISTS #CleanedPhoneNumbers 

