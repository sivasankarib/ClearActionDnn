/****** Object:  StoredProcedure [dbo].[CA_Forum_GetUserForums]    Script Date: 09-03-2021 2.46.09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [CA_Forum_GetUserForums] 40,5
create PROCEDURE [dbo].[CA_Forum_GetUserForumsSearch] 
@UserID int,
@TopN int,
@AuthorId int
AS 
BEGIN
/* if we have DONE then we need to 
- show a mix of TODO and DONE ( 3 TODO + 2 Done or 
- if no DONE then get mix bag from each categories for TODO 
*/
DECLARE @TotalDone AS INT=0
DECLARE @TotalToDo AS INT=0
-- Calculate Total DONE
SET @TotalDone = (SELECT DISTINCT COUNT(M.ContentID) FROM  
	             (SELECT C.ContentID FROM (select * from  dbo.activeforums_Topics where IsDeleted=0) T 
			INNER JOIN activeforums_Content C on C.contentID=T.ContentId) AS M 
	               INNER JOIN (SELECT ItemID,HasSeen FROM dbo.ClearAction_UserComponents
				   WHERE (UserID = @UserID AND ComponentID=1
                 )) AS UC 
	            ON M.ContentID = UC.ItemID
				WHERE IsNull(UC.HasSeen,0)=1 ) 
Print '1. TODO :'+cast(@TotalToDo as varchar) +' DONE: '+cast(@TotalDone as varchar)
--  Calculate Total TODO
SET @TotalToDo = (SELECT DISTINCT COUNT(M.ContentID) FROM  
	             (SELECT C.ContentID FROM (select * from  dbo.activeforums_Topics where IsDeleted=0) T  
			INNER JOIN activeforums_Content C on C.contentID=T.ContentId) AS M 
	               INNER JOIN (SELECT ItemID,HasSeen FROM dbo.ClearAction_UserComponents
				   WHERE (UserID = @UserID AND ComponentID=1
                 )) AS UC 
	            ON M.ContentID = UC.ItemID
				WHERE IsNull(UC.HasSeen,0)=0 AND IsNull(UC.ItemID,0) > 0)
Print '2. TODO :'+cast(@TotalToDo as varchar) +' DONE: '+cast(@TotalDone as varchar)
IF (@TotalDONE>0) 
BEGIN
	IF (@TotalToDo=0)
	BEGIN
		SET @TotalDone=@TopN -- show all as done
		Print '3. TODO :'+cast(@TotalToDo as varchar) +' DONE: '+CAST(@TotalDone as varchar)
	END
	ELSE 
	BEGIN
	 -- we have DONE also, then show 3 TODO + 2 DONE or 2/1 TODO + 2 DONE 
	-- 3+2 mix 
	IF (@TotalDone>@TotalToDo)
	BEGIN
		IF (@TotalToDo<3)
		BEGIN
			SET @TotalDone=@TopN-@TotalToDo
			PRINT '3.1 TODO :'+CAST(@TotalToDo AS VARCHAR) +' DONE: '+ CAST(@TotalDone AS VARCHAR)   
		END
		ELSE
		BEGIN
			SET @TotalToDo=CASE WHEN @TotalToDo>3 THEN 3 ELSE @TotalToDo END
			SET @TotalDone=@TopN-@TotalToDo
			PRINT '3.2 TODO :'+CAST(@TotalToDo AS VARCHAR) +' DONE: '+ CAST(@TotalDone AS VARCHAR)   
		END
		Print '4. TODO :'+cast(@TotalToDo as varchar) +' DONE: '+CAST(@TotalDone as varchar)
	END
	ELSE
	BEGIN
		SET @TotalDone= CASE WHEN @TotalDone > 2 THEN 2 ELSE @TotalDone END 
		SET @TotalToDo = CASE WHEN @TotalToDo > 3 THEN 3 ELSE @TotalToDo END
		SET @TotalToDo=@TopN-@TotalDone
		Print '5. TODO :'+cast(@TotalToDo as varchar) +' DONE: '+CAST(@TotalDone as varchar)
	END
	END
END
--SELECT @TotalDone as 'DONE' , @TotalToDo 'TODO'
IF @TotalDone=0 
BEGIN
-- get the list of mix bag from each categories
	SET @TotalToDo=@TopN -- show all as todo
	Print '1. TODO :'+cast(@TotalToDo as varchar) +' DONE: '+cast(@TotalDone as varchar)
END

-- TODO List
SELECT TOP (@TotalToDo)
CASE  
	WHEN (ISNULL(HasSeen,0)=1) THEN 'Completed' 
	WHEN (B.IsAssigned=1 AND ISNULL(HasSeen,0)=0) THEN 'To-Do'
	END AS [Status],
	B.[Subject],B.Body,B.Summary,B.TopicId,B.ContentId,B.AuthorId
FROM
(
	SELECT DISTINCT M.[Subject],M.ContentId,M.TopicId,M.Summary,CAST(M.Body as varchar(1000)) Body, M.AuthorId,
		(CASE WHEN (ISNULL(UC.ItemID,0)>0) THEN 1 ELSE 0 END) IsAssigned,IsNull(HasSeen,0) HasSeen,M.DateCreated
	FROM  (SELECT C.DateCreated,C.AuthorId, C.[Subject],C.ContentID,T.TopicId,T.CategoryID,C.Body,C.Summary FROM dbo.activeforums_Topics T 
			INNER JOIN activeforums_Content C on C.contentID=T.ContentId where T.IsDeleted=0) AS M 
	INNER JOIN
		(SELECT * FROM dbo.ClearAction_UserComponents WHERE (UserID = @UserID AND ComponentID=1 )) AS UC 
	ON M.ContentId = UC.ItemID
	LEFT OUTER JOIN 
		activeforums_TopicCategoryRelation FC on FC.TopicId=M.TopicId
	GROUP BY 
		M.TopicId,M.ContentId,M.[Subject],cast(M.Body as varchar(1000)),FC.CategoryID, UC.ItemID,M.Summary,HasSeen,M.AuthorId,M.DateCreated
) AS B 
WHERE (IsAssigned=1 and ISNULL(HasSeen,0)=0) and AuthorId=@AuthorId

UNION
-- Get DONE List

SELECT TOP (@TotalDone)
CASE  
	WHEN (ISNULL(HasSeen,0)=1) THEN 'Completed' 
	WHEN (B.IsAssigned=1 AND ISNULL(HasSeen,0)=0) THEN 'To-Do'
	END AS [Status],
	B.[Subject],B.Body,B.Summary,B.TopicId,B.ContentId,B.AuthorId
FROM
(
	SELECT DISTINCT M.[Subject],M.ContentId,M.TopicId,M.Summary,CAST(M.Body as varchar(1000)) Body, M.AuthorId,
		(CASE WHEN (ISNULL(UC.ItemID,0)>0) THEN 1 ELSE 0 END) IsAssigned,IsNull(HasSeen,0) HasSeen,M.DateCreated
	FROM  (SELECT C.DateCreated,C.AuthorId, C.[Subject],C.ContentID,T.TopicId,T.CategoryID,C.Body,C.Summary FROM dbo.activeforums_Topics T 
			INNER JOIN activeforums_Content C on C.contentID=T.ContentId where t.IsDeleted=0) AS M 
	INNER JOIN
		(SELECT * FROM dbo.ClearAction_UserComponents WHERE (UserID = @UserID AND ComponentID=1 )) AS UC 
	ON M.ContentId = UC.ItemID
	LEFT OUTER JOIN 
		activeforums_TopicCategoryRelation FC on FC.TopicId=M.TopicId
	GROUP BY 
		M.TopicId,M.ContentId,M.[Subject],cast(M.Body as varchar(1000)),FC.CategoryID, UC.ItemID,M.Summary,HasSeen,M.AuthorId,M.DateCreated
) AS B 
WHERE (IsAssigned=1 and ISNULL(HasSeen,0)=1) and AuthorId=@AuthorId

END
