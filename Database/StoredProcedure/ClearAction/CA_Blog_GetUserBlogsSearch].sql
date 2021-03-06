/****** Object:  StoredProcedure [dbo].[CA_Blog_GetUserBlogs]    Script Date: 09-03-2021 2.27.38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [CA_Blog_GetUserBlogs] 40,5
alter PROCEDURE [dbo].[CA_Blog_GetUserBlogsSearch] 
@UserID int,
@TopN int,
@search varchar(50)
AS
BEGIN
/* if we have DONE then we need to 
- show a mix of TODO and DONE ( 3 TODO + 2 Done or 
- if no DONE then get mix bag from each categories for TODO 
*/
DECLARE @TotalDone AS INT
DECLARE @TotalToDo AS INT
-- Calculate Total DONE
SET @TotalDone = (SELECT DISTINCT COUNT(M.ContentItemId) FROM  
	             ( SELECT ContentItemId FROM dbo.Blog_Posts WHERE Published=1 ) AS M 
	               INNER JOIN (SELECT ItemID,HasSeen FROM dbo.ClearAction_UserComponents
				   WHERE (UserID = @UserID AND ComponentID=2
                 )) AS UC 
	            ON M.ContentItemId = UC.ItemID
				WHERE IsNull(UC.HasSeen,0)=1)
				
--  Calculate Total TODO
SET @TotalToDo = (SELECT DISTINCT COUNT(M.ContentItemId) FROM  
	             ( SELECT ContentItemId FROM dbo.Blog_Posts WHERE Published=1 ) AS M 
	               INNER JOIN (SELECT ItemID,HasSeen FROM dbo.ClearAction_UserComponents
				   WHERE (UserID = @UserID AND ComponentID=2
                 )) AS UC 
	            ON M.ContentItemId = UC.ItemID
				WHERE IsNull(UC.HasSeen,0)=0 and IsNull(UC.ItemID,0) > 0)
				--PRINT '1. TODO :'+cast(@TotalToDo as varchar) +' DONE: '+cast(@TotalDone as varchar)
IF (@TotalDONE>0) 
BEGIN
	IF (@TotalToDo=0)
	BEGIN
		SET @TotalDone=@TopN -- show all as done
		PRINT '2. TODO :'+cast(@TotalToDo as varchar) +' DONE: '+cast(@TotalDone as varchar)
	END
	ELSE 
	BEGIN
	 -- we have DONE also, then show 3 TODO + 2 DONE or 2/1 TODO + 2 DONE 
	-- 3+2 mix 
	 IF (@TotalDone<@TotalToDo) 
 BEGIN
	SET @TotalDone= CASE WHEN @TotalDone > 2 THEN 2 ELSE @TotalDone END       
	SET @TotalToDo = CASE WHEN @TotalToDo > 3 THEN 3 ELSE @TotalToDo END      
	SET @TotalToDo = @TopN - @TotalDone   
  PRINT '3. TODO :'+CAST(@TotalToDo AS VARCHAR) +' DONE: '+ CAST(@TotalDone AS VARCHAR)      
 END
 ELSE
 BEGIN -- if total done is more than todo
	IF (@TotalToDo<3)
	BEGIN
		SET @TotalDone=@TopN-@TotalToDo
		 PRINT '3.1 TODO :'+CAST(@TotalToDo AS VARCHAR) +' DONE: '+ CAST(@TotalDone AS VARCHAR)   
	END
	ELSE
	BEGIN
		SET @TotalToDo = CASE WHEN @TotalToDo>3 THEN 3 ELSE @TotalToDo END
		SET @TotalDone = @TopN - @TotalToDo
		 PRINT '3.2 TODO :'+CAST(@TotalToDo AS VARCHAR) +' DONE: '+ CAST(@TotalDone AS VARCHAR)   
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
SELECT TOP (@TotalToDo)
CASE  
	WHEN (ISNULL(HasSeen,0)=1) THEN 'Completed' 
	WHEN (B.IsAssigned=1 AND ISNULL(HasSeen,0)=0) THEN 'To-Do'
	END AS [Status],
	B.* 
FROM
(SELECT DISTINCT
	M.Title, 	M.ContentItemId, 	M.Summary,
	(CASE WHEN (ISNULL(UC.ItemID,0)>0) THEN 1 ELSE 0 END) IsAssigned,
	ISNULL(HasSeen,0) HasSeen , PublishedOnDate,ShortDescription
FROM  
(
	SELECT * FROM Blog_Posts WHERE ContentItemId IN (
		SELECT A.ContentItemId FROM (
				SELECT A.ContentItemId,BC.CategoryId 
				FROM 
				(SELECT * FROM dbo.Blog_Posts P WHERE Published=1) A
				INNER JOIN Blog_PostCategoryRelation BC on BC.ContentItemId=A.ContentItemId
				INNER JOIN (SELECT * FROM dbo.ClearAction_UserComponents WHERE (UserID = @UserID AND ComponentID=2 and IsNull(HasSeen,0)=0 and ISNULL(ItemID,0)>0)) AS UC ON A.ContentItemId = UC.ItemID
		) A GROUP BY A.CategoryId,A.ContentItemId
)) AS M 
INNER JOIN
        (SELECT *
        FROM dbo.ClearAction_UserComponents
        WHERE (UserID = @UserID AND ComponentID=2
)) AS UC 
ON 
	M.ContentItemId = UC.ItemID
LEFT OUTER JOIN Blog_PostCategoryRelation BC on BC.ContentItemId=M.ContentItemId
GROUP BY 
	M.Title,BC.CategoryID, M.ContentItemId, UC.ItemID,M.Summary,HasSeen,PublishedOnDate,ShortDescription
	
	) as B 
	WHERE (IsAssigned=1 and ISNULL(HasSeen,0)=0) and title LIKE ''+ @search +'%'
	--ORDER BY B.PublishedOnDate DESC

UNION
-- Get DONE List
SELECT TOP (@TotalDone)
CASE  
	WHEN (ISNULL(HasSeen,0)=1) THEN 'Completed' 
	WHEN (B.IsAssigned=1 AND ISNULL(HasSeen,0)=0) THEN 'To-Do'
	END AS [Status],
	B.* 
FROM
(SELECT DISTINCT
	M.Title, 	M.ContentItemId, 	M.Summary,
	(CASE WHEN (ISNULL(UC.ItemID,0)>0) THEN 1 ELSE 0 END) IsAssigned,
	ISNULL(HasSeen,0) HasSeen , PublishedOnDate,ShortDescription
FROM  
	(SELECT * FROM dbo.Blog_Posts WHERE Published=1  ) AS M 
INNER JOIN
        (SELECT *
        FROM dbo.ClearAction_UserComponents
        WHERE (UserID = @UserID AND ComponentID=2
)) AS UC 
ON 
	M.ContentItemId = UC.ItemID
LEFT OUTER JOIN Blog_PostCategoryRelation BC on BC.ContentItemId=M.ContentItemId
GROUP BY 
	M.Title,BC.CategoryID, M.ContentItemId, UC.ItemID,M.Summary,HasSeen,PublishedOnDate,ShortDescription
	
	) as B 
	WHERE (IsAssigned=1 and ISNULL(HasSeen,0)=1) and title LIKE ''+ @search +'%'
END
