/****** Object:  StoredProcedure [dbo].[WCC_GetEventByUserAssignment]    Script Date: 5/25/2020 1:58:52 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[WCC_GetEventByUserAssignment]
GO
/****** Object:  StoredProcedure [dbo].[WCC_GetEventByUserAssignment]    Script Date: 5/25/2020 1:58:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[WCC_GetEventByUserAssignment]       
@UserID int,             
@CatID int,            
@OptionID varchar(10),            
@LoggedInUser int,            
@SearchKey varchar(200),        
@Componentid int =-1        
AS            
BEGIN            
	DECLARE @searchWord NVARCHAR(100),
	@searchSQLStr NVARCHAR(MAX) = '';

DECLARE @searchSQLTemplate NVARCHAR(MAX) = 'ShortDescription LIKE ''%@SearchKey%'' OR LongDescription LIKE ''%@SearchKey%'' OR Title LIKE ''%@SearchKey%'' 
										    OR PresenterName LIKE ''%@SearchKey%'' OR PresenterTitle LIKE ''%@SearchKey%'' OR PresenterCompany LIKE ''%@SearchKey%'''

DECLARE searchWordList_cursor CURSOR
FOR SELECT VALUE FROM STRING_SPLIT(@SearchKey, ' ')

OPEN searchWordList_cursor

FETCH NEXT FROM searchWordList_cursor INTO @searchWord

WHILE @@FETCH_STATUS = 0
	BEGIN

		IF @searchSQLStr != ''
			BEGIN
				SET @searchSQLStr = @searchSQLStr + ' OR '	
			END

		SET @searchSQLStr = @searchSQLStr + REPLACE(@searchSQLTemplate, '@SearchKey', @searchWord)	

		FETCH NEXT FROM searchWordList_cursor INTO @searchWord
	END

--SELECT @searchSQLStr

CLOSE searchWordList_cursor

DEALLOCATE searchWordList_cursor

IF (@UserID>0)          
	BEGIN
		DECLARE @userIdSQL VARCHAR(MAX) = 'SELECT * FROM ( SELECT           
				CASE            
				 WHEN (ISNULL(HasSeen,0)=1) THEN ''Completed''           
				 WHEN (B.IsAssigned=1 AND ISNULL(HasSeen,0)=0) THEN ''To-Do''         
				 END AS [Status],          
				 B.*        
				FROM          
				(          
				 SELECT DISTINCT P.*,          
				  (CASE WHEN (ISNULL(UC.ItemID,0)>0) THEN 1 ELSE 0 END) IsAssigned,          
				  CASE WHEN (ISNULL(UC.CreatedBy,-1)='+CAST(@UserID AS NVARCHAR(150))+' AND IsNull(UC.ItemID,0)>0) THEN 1 ELSE 0 END IsSelfAssigned,          
				  ISNULL(HasSeen,0) HasSeen        
				 FROM          
				 (SELECT * FROM WCC_Posts WHERE (IsPublish=1) AND (('+CAST(@Componentid AS NVARCHAR(150))+'=-1) OR (ComponentID='+CAST(@Componentid AS NVARCHAR(150))+'))) as P           
				 INNER JOIN          
				    (SELECT * FROM dbo.ClearAction_UserComponents WHERE ((('+CAST(@UserID AS NVARCHAR(150))+'=-1) OR (UserID = '+CAST(@UserID AS NVARCHAR(150))+' )) AND ((ComponentID IN (4,5,6,7,8,9))))) AS UC           
				 ON P.WCCId = UC.ItemID          
				 LEFT OUTER JOIN           
				  (SELECT * FROM WCC_PostCategoryRelation WHERE IsActive=1 ) BC ON BC.WCCId = P.WCCId        
				 GROUP BY          
				  P.WCCId, P.ShortDescription, P.LongDescription, BC.CategoryID, P.Title,P.ComponentID,P.EventDate,P.EventTime,P.PresenterID,        
				  P.PresenterName,P.PresenterTitle,P.PresenterCompany,P.PresenterProfilePic,P.ViewCount,P.IsPublish,P.WebApiKey,        
				  UC.ItemID, HasSeen,        
				  P.CreatedByUserID, UC.CreatedBy, P.CreatedOnDate, P.filestackurl,        
				  P.UpdatedByUserID, P.UpdatedOnDate, P.RegistrationLink, P.ExpiredviewLink        
				 HAVING           
				 (('+CAST(@CatID AS NVARCHAR(150))+'=-1) OR (BC.CategoryId='+CAST(@CatID AS NVARCHAR(150))+'))          
				 AND           
				 (('''+@SearchKey+'''='''') OR ('+@searchSQLStr+'))          
				) AS B          
				) tblFinal           
				WHERE (('''+@OptionID+'''=''All'') or ([Status]='''+@OptionID+'''))'  

			EXEC(@userIdSQL) 
	END
ELSE
	BEGIN
		DECLARE @loggedInUserSQL NVARCHAR(MAX) = ''
		
		SET @loggedInUserSQL = 'SELECT * FROM (          
				SELECT           
				CASE            
				 WHEN (ISNULL(HasSeen,0)=1) THEN ''Completed''           
				 WHEN (B.IsAssigned=1 AND ISNULL(HasSeen,0)=0) THEN ''To-Do''
				 END AS [Status],          
				 B.*        
				FROM          
				(          
				 SELECT DISTINCT P.*,          
				  (CASE WHEN (ISNULL(UC.ItemID,0)>0) THEN 1 ELSE 0 END) IsAssigned,          
				  CASE WHEN (IsNull(UC.CreatedBy,-1)='+CAST(@LoggedInUser AS NVARCHAR(150))+' AND IsNull(UC.ItemID,0)>0) THEN 1 ELSE 0 END IsSelfAssigned,          
				  IsNull(HasSeen,0) HasSeen        
				 FROM  (SELECT * FROM dbo.WCC_Posts          
				    WHERE ((ISNULL(CreatedByUserID,-1)='+CAST(@LoggedInUser AS NVARCHAR(150))+') OR (IsPublish=1)) AND (('+CAST(@Componentid AS NVARCHAR(150))+'=-1) OR (ComponentID='+CAST(@Componentid AS NVARCHAR(150))+'))      
				    AND        
				    (('''+@SearchKey+'''='''') OR ('+@searchSQLStr+'))          
				   ) P           
				 LEFT OUTER JOIN          
				  (SELECT * FROM dbo.ClearAction_UserComponents WHERE (UserID = '+CAST(@LoggedInUser AS NVARCHAR(150))+' AND ((ComponentID in(4,5,6,7,8,9))))) AS UC           
				 ON P.WCCId = UC.ItemID          
				 LEFT OUTER JOIN           
				  (SELECT * FROM WCC_PostCategoryRelation WHERE IsActive=1 ) BC ON BC.WCCId=P.WCCId        
				 GROUP BY           
				 P.WCCId, P.ShortDescription, P.LongDescription, BC.CategoryID, P.Title,P.ComponentID,P.EventDate,P.EventTime,P.PresenterID,        
				   P.PresenterName,P.PresenterTitle,P.PresenterCompany,P.PresenterProfilePic,P.ViewCount,P.IsPublish,P.WebApiKey,        
				   UC.ItemID, HasSeen,        
				   P.CreatedByUserID, UC.CreatedBy, P.CreatedOnDate, P.filestackurl,        
				   P.UpdatedByUserID, P.UpdatedOnDate, P.RegistrationLink, P.ExpiredviewLink        
				 HAVING           
				 (('+CAST(@CatID AS NVARCHAR(150))+'=-1) OR (BC.CategoryId='+CAST(@CatID AS NVARCHAR(150))+'))          
				) AS B           
				) tblFinal          
				WHERE (('''+@OptionID+'''=''All'') or ([Status]='''+@OptionID+'''))'

		EXEC(@loggedInUserSQL)
	END   
END  
GO
