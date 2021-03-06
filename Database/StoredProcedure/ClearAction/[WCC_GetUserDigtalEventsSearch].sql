/****** Object:  StoredProcedure [dbo].[WCC_GetUserDigtalEvents]    Script Date: 09-03-2021 3.11.08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [WCC_GetUserDigtalEvents] 40,4,5
create PROCEDURE [dbo].[WCC_GetUserDigtalEventsSearch]  --777,4,5
@UserID int,      
@ComponentID int,      
@TopN int,
@search  varchar(50)      
AS        
BEGIN        
/* if we have DONE then we need to         
- show a mix of TODO and DONE ( 3 TODO + 2 Done or         
- if no DONE then get mix bag from each categories for TODO         
*/        
DECLARE @TotalDone AS INT        
DECLARE @TotalToDo AS INT        
-- Calculate Total DONE        
SET @TotalDone = (SELECT  COUNT( DISTINCT M.WCCId) FROM          
              ( SELECT DISTINCT * FROM dbo.WCC_Posts WHERE IsPublish=1 AND ComponentID=@ComponentID) AS M       
      INNER JOIN (SELECT * FROM WCC_PostCategoryRelation  WHERE IsActive=1 ) BC on BC.WCCId=M.WCCId      
                INNER JOIN (SELECT ItemID,HasSeen FROM dbo.ClearAction_UserComponents        
       WHERE (UserID = @UserID AND ComponentID=@ComponentID    
                 )) AS UC         
             ON M.WCCId = UC.ItemID        
      WHERE IsNull(UC.HasSeen,0)=1)    
--  Calculate Total TODO        
SET @TotalToDo = (SELECT DISTINCT COUNT(DISTINCT M.WCCId) FROM          
              ( SELECT distinct * FROM dbo.WCC_Posts WHERE IsPublish=1 AND ComponentID=@ComponentID) AS M         
       INNER JOIN (SELECT * FROM WCC_PostCategoryRelation  WHERE IsActive=1 ) BC ON BC.WCCId=M.WCCId    
                INNER JOIN (SELECT ItemID,HasSeen FROM dbo.ClearAction_UserComponents        
                WHERE (UserID = @UserID AND ComponentID=@ComponentID      
              )) AS UC         
             ON M.WCCId = UC.ItemID        
    WHERE IsNull(UC.HasSeen,0)=0 and IsNull(UC.ItemID,0) > 0)        
   -- PRINT '1. TODO :'+cast(@TotalToDo as varchar) +' DONE: '+CAST(@TotalDone as varchar)        
IF (@TotalDONE>0)         
BEGIN        
 IF (@TotalToDo=0)        
 BEGIN        
  SET @TotalDone=@TopN -- show all as done        
 -- PRINT '2. TODO :'+cast(@TotalToDo as varchar) +' DONE: '+cast(@TotalDone as varchar)        
 END        
 ELSE         
 BEGIN        
  -- we have DONE also, then show 3 TODO + 2 DONE or 2/1 TODO + 2 DONE         
 -- 3 + 2 mix         
 IF (@TotalDone<@TotalToDo)   
 BEGIN  
 SET @TotalDone= CASE WHEN @TotalDone > 2 THEN 2 ELSE @TotalDone END         
 SET @TotalToDo = CASE WHEN @TotalToDo > 3 THEN 3 ELSE @TotalToDo END        
 SET @TotalToDo = @TopN - @TotalDone     
 -- PRINT '3. TODO :'+CAST(@TotalToDo AS VARCHAR) +' DONE: '+ CAST(@TotalDone AS VARCHAR)        
 END  
 ELSE  
 BEGIN -- if total done is more than todo  
 IF (@TotalToDo<3)  
 BEGIN  
  SET @TotalDone=@TopN-@TotalToDo  
  -- PRINT '3.1 TODO :'+CAST(@TotalToDo AS VARCHAR) +' DONE: '+ CAST(@TotalDone AS VARCHAR)     
 END  
 ELSE  
 BEGIN  
  SET @TotalToDo = CASE WHEN @TotalToDo>3 THEN 3 ELSE @TotalToDo END  
  SET @TotalDone = @TopN - @TotalToDo  
  -- PRINT '3.2 TODO :'+CAST(@TotalToDo AS VARCHAR) +' DONE: '+ CAST(@TotalDone AS VARCHAR)     
 END  
 END  
  END        
END        
  
  
-- Uncomment to check Value of DONE AND TODO SELECT @TotalDone as 'DONE' , @TotalToDo 'TODO'        
IF @TotalDone=0         
BEGIN        
  
-- get the list of mix bag from each categories        
 SET @TotalToDo=@TopN -- show all as todo        
 set @TotalDone=1 -- handle the error of top 0, 0 throws error        
 PRINT '4. TODO :'+cast(@TotalToDo as varchar) +' DONE: '+CAST(@TotalDone as varchar)        
END        
PRINT '5. TODO :'+cast(@TotalToDo as varchar) +' DONE: '+CAST(@TotalDone as varchar)        
-- TODO List        
SELECT       
CASE          
 WHEN (ISNULL(HasSeen,0)=1) THEN 'Completed'         
 WHEN (B.IsAssigned=1 AND ISNULL(HasSeen,0)=0) THEN 'To-Do'        
 END AS [Status],        
 B.*         
FROM        
(SELECT DISTINCT        
 M.Title,  M.WCCId,  M.ShortDescription,        
 (CASE WHEN (ISNULL(UC.ItemID,0)>0) THEN 1 ELSE 0 END) IsAssigned,        
 ISNULL(HasSeen,0) HasSeen , CreatedOnDate,  M.EventDate,M.EventTime,M.PresenterID, M.PresenterName,M.PresenterTitle,M.PresenterCompany,M.PresenterProfilePic, M.RegistrationLink, M.ExpiredviewLink,M.WebApiKey      
FROM          
(        
 SELECT * FROM WCC_Posts WHERE WCCId IN (        
  SELECT A.WCCId FROM (        
    SELECT A.WCCId,BC.CategoryId         
    FROM         
    (SELECT * FROM dbo.WCC_Posts P WHERE IsPublish=1 AND P.ComponentID=@ComponentID) A        
   INNER JOIN (SELECT * FROM WCC_PostCategoryRelation  WHERE IsActive=1 ) BC on BC.WCCId=A.WCCId        
    INNER JOIN (SELECT * FROM dbo.ClearAction_UserComponents WHERE (UserID = @UserID AND ComponentID=@ComponentID AND IsNull(HasSeen,0)=0 AND ISNULL(ItemID,0)>0)) AS UC ON A.WCCId = UC.ItemID        
  ) A GROUP BY A.WCCId ,A.CategoryId  
)) AS M         
INNER JOIN        
        (SELECT *        
        FROM dbo.ClearAction_UserComponents        
        WHERE (UserID = @UserID AND ComponentID=@ComponentID       
)) AS UC         
ON         
 M.WCCId = UC.ItemID        
LEFT OUTER JOIN WCC_PostCategoryRelation BC on BC.WCCId=M.WCCId   
GROUP BY         
 M.Title,BC.CategoryID, M.WCCId, UC.ItemID,HasSeen,CreatedOnDate,ShortDescription , M.EventDate,M.EventTime,M.PresenterID, M.PresenterName,M.PresenterTitle,M.PresenterCompany,M.PresenterProfilePic, M.RegistrationLink, M.ExpiredviewLink,M.WebApiKey
         
 ) as B         
 WHERE (IsAssigned=1 and ISNULL(HasSeen,0)=0)   and title like ''+@search+'%'    
 --ORDER BY B.CreatedOnDate DESC        
        
UNION        
-- Get DONE List  
  
   
        
SELECT        
CASE          
 WHEN (ISNULL(HasSeen,0)=1) THEN 'Completed'         
 WHEN (B.IsAssigned=1 AND ISNULL(HasSeen,0)=0) THEN 'To-Do'        
 END AS [Status],        
 B.*         
FROM        
(SELECT DISTINCT        
 M.Title,  M.WCCId,  M.ShortDescription,        
 (CASE WHEN (ISNULL(UC.ItemID,0)>0) THEN 1 ELSE 0 END) IsAssigned,        
 ISNULL(HasSeen,0) HasSeen , CreatedOnDate  , M.EventDate,M.EventTime,M.PresenterID, M.PresenterName,M.PresenterTitle,M.PresenterCompany,M.PresenterProfilePic, M.RegistrationLink, M.ExpiredviewLink,M.WebApiKey
FROM          
 (SELECT * FROM dbo.WCC_Posts WHERE IsPublish=1  ) AS M         
INNER JOIN        
        (SELECT *        
        FROM dbo.ClearAction_UserComponents        
        WHERE (UserID = @UserID AND ComponentID=@ComponentID  
)) AS UC         
ON         
 M.WCCId = UC.ItemID        
LEFT OUTER JOIN WCC_PostCategoryRelation BC on BC.WCCId=M.WCCId        
GROUP BY         
 M.Title,BC.CategoryID, M.WCCId, UC.ItemID,M.ShortDescription,HasSeen,CreatedOnDate, M.EventDate,M.EventTime,M.PresenterID, M.PresenterName,M.PresenterTitle,M.PresenterCompany,M.PresenterProfilePic, M.RegistrationLink, M.ExpiredviewLink,M.WebApiKey
         
 ) as B         
 WHERE (IsAssigned=1 and ISNULL(HasSeen,0)=1)  and title like ''+@search+'%'          
END  

