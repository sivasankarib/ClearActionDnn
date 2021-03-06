/****** Object:  StoredProcedure [dbo].[CA_ListSolveSpacesTopN]    Script Date: 09-03-2021 5.21.49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sachin Srivastava
-- Create date: 13-Nov-2017
-- Description:	To Get the list of Solve-Spaces on various parameters
--  [dbo].[CA_ListSolveSpacesTopN] 1
-- =============================================
--exec [CA_ListSolveSpacesTopNSearch] 40,100,'Master'
alter PROCEDURE [dbo].[CA_ListSolveSpacesTopNSearch]  
@UserID int,
@TopN int,
@search varchar(50)
AS
BEGIN
/* 
2 "In-Progress" + 2 "To-Do" + 1 "Done"
- show more "to do" than "done
- only "to do" then show five based on the best mix of the 6 categories.
- only "to do" and "in progress" then show more “in progress” than “to do.”
- If there are only "in progress" then show up to five with the most recent one they worked on showing up first. 
*/ 
DECLARE @TotalDone AS INT
DECLARE @TotalToDo AS INT
Declare @TotalInProgress as Int

/* Calculate Total DONE*/
SET @TotalDone=IsNull((SELECT COUNT(*) FROM (SELECT A.SolveSpaceID FROM 
	(SELECT * FROM ClearAction_SolveSpaceMaster WHERE IsDeleted=0 and TabLink!='') A 
	LEFT OUTER JOIN 
	(
		SELECT DISTINCT USERID,COUNT(StepID) StepCount,SolveSpaceID ,MAX(LastUpdatedOn) LastUpdatedOn
		FROM ClearAction_UserSolveSpaces 
		GROUP BY SolveSpaceID,UserID
		HAVING UserID=@UserID 
	) USS ON USS.SolveSpaceID=A.SolveSpaceID 
	inner JOIN 
(SELECT DISTINCT * FROM ClearAction_UserComponents WHERE UseriD=@UserID  and ComponentID=3) UC  
ON A.SolveSpaceID=UC.ItemID
					WHERE  UC.ItemID>0 and A.TotalSteps=StepCount) A),0)
	 

/* Calculate Total In-Progress */
SET @TotalInProgress=ISNULL((SELECT COUNT(*) FROM (SELECT A.SolveSpaceID  FROM 
				(SELECT * FROM ClearAction_SolveSpaceMaster WHERE IsDeleted=0 and TabLink!='') A 
				  LEFT OUTER JOIN 
					(
						SELECT DISTINCT USERID,COUNT(StepID) StepCount,SolveSpaceID ,MAX(LastUpdatedOn) LastUpdatedOn
						FROM ClearAction_UserSolveSpaces 
						GROUP BY SolveSpaceID,UserID
						HAVING UserID=@UserID
					) USS ON USS.SolveSpaceID=A.SolveSpaceID 
					LEFT OUTER JOIN 
(SELECT DISTINCT * FROM ClearAction_UserComponents WHERE UseriD=@UserID and ComponentID=3) UC  
ON A.SolveSpaceID=UC.ItemID
					WHERE  UC.ItemID>0 and A.TotalSteps>StepCount and StepCount>0) A),0)

/* Calculate Total To-Do*/	
SET @TotalToDo=ISNULL((SELECT COUNT(*) FROM (SELECT A.SolveSpaceID FROM 
	(SELECT * FROM ClearAction_SolveSpaceMaster WHERE IsDeleted=0 and tablink!='') A 
	LEFT OUTER JOIN (
		SELECT DISTINCT USERID,COUNT(StepID) StepCount,SolveSpaceID ,MAX(LastUpdatedOn) LastUpdatedOn
		FROM ClearAction_UserSolveSpaces 
		GROUP BY SolveSpaceID,UserID
		HAVING UserID=@UserID
	) USS ON USS.SolveSpaceID=A.SolveSpaceID 
	LEFT OUTER JOIN 
	(SELECT DISTINCT * FROM ClearAction_UserComponents WHERE UseriD=@UserID and ComponentID=3) UC  
	ON A.SolveSpaceID=UC.ItemID
	GROUP BY USS.UserID,UC.UserID,USS.LastUpdatedOn,UC.CreatedOn,UC.ItemID,USS.StepCount,A.Title,A.SolveSpaceID,
	UC.CreatedOn,UC.CreatedBy,a.DurationInMin,a.ShortDescription,a.TabLink,a.TotalSteps
	HAVING 
	(IsNull(USS.StepCount,0)=0 AND UC.ItemID>0)) A ) ,0)
PRINT '1 > TotalInProgress: '+CAST(@TotalInProgress AS VARCHAR)+' , TODO: '+CAST(@TotalToDo AS VARCHAR) +' Done '+CAST(@TotalDone as varchar)
IF (@TotalDone>0) AND (@TotalToDo>0) AND (@TotalInProgress>0)
BEGIN -- 2 "IN-PROGRESS" + 2 "TO-DO" + 1 "DONE"
	SET @TotalDone	=1 --minimum 1 done will be there
		IF (@TotalToDo>@TotalInProgress)
		BEGIN
			SET @TotalInProgress= CASE WHEN @TotalInProgress > 1 then 2 else 1 end
			SET @TotalToDo=@TopN-(@TotalInProgress+@TotalDone)
			print 'x.1 > TotalInProgress: '+cast(@TotalInProgress as varchar)+' , TODO: '+CAST(@TotalToDo as varchar) +' Done '+CAST(@TotalDone as varchar)
		END
		ELSE
		BEGIN
			SET @TotalToDo= CASE WHEN @TotalToDo > 1 then 2 else 1 end
			SET @TotalInProgress=@TopN-(@TotalToDo+@TotalDone)
			print 'x.2 > TotalInProgress: '+cast(@TotalInProgress as varchar)+' , TODO: '+CAST(@TotalToDo as varchar) +' Done '+CAST(@TotalDone as varchar)
		END
END
print 'B > TotalInProgress: '+cast(@TotalInProgress as varchar)+' , TODO: '+CAST(@TotalToDo as varchar) +' Done '+CAST(@TotalDone as varchar)
IF (@TotalDone=0 AND @TotalInProgress>0 AND @TotalToDo=0)
BEGIN -- If only Progress , no done, no todo , show recent one on Top/first
	SET @TotalToDo = 1
	SET @TotalInProgress = @TopN
	SET @TotalDone=1 -- to handle the 0 Top error , make it 1
END
 print 'C > TotalInProgress: '+cast(@TotalInProgress as varchar)+' , TODO: '+CAST(@TotalToDo as varchar) +' Done '+CAST(@TotalDone as varchar)
IF (@TotalDone=0 AND @TotalInProgress>0 AND @TotalToDo>0)
BEGIN -- If No Done, but In-Progress and TODO, show more In-Progress than TODO
	IF (@TotalInProgress<@TotalToDo) 
		BEGIN /*if InProgress are less then show rest item as TODO */
			SET @TotalInProgress = CASE WHEN @TotalInProgress > 3 THEN 3 ELSE @TotalInProgress END
			SET @TotalToDo=@TopN-@TotalInProgress
			 print 'D > TotalInProgress: '+cast(@TotalInProgress as varchar)+' , TODO: '+CAST(@TotalToDo as varchar) +' Done '+CAST(@TotalDone as varchar)
		END
	ELSE
		BEGIN
			SET @TotalToDo = CASE WHEN @TotalToDo > 2 THEN 2  ELSE @TotalToDo END 
			SET @TotalInProgress = ( @TopN - @TotalToDo )
 print 'E > TotalInProgress: '+cast(@TotalInProgress as varchar)+' , TODO: '+CAST(@TotalToDo as varchar) +' Done '+CAST(@TotalDone as varchar)
		END
	SET @TotalDone=1 -- to handle the 0 Top error , make it 1
END

IF (@TotalDone>0 and @TotalInProgress>0 and @TotalToDo=0) -- MORE PROGRESS THAN DONE
BEGIN
	IF (@TotalInProgress<@TotalDone) 
		BEGIN /*if InProgress are less then show rest item as TODO */
			SET @TotalInProgress = CASE WHEN @TotalInProgress > 3 THEN 3 ELSE @TotalInProgress END
			SET @TotalDone=@TopN-@TotalInProgress
			 print 'D > TotalInProgress: '+cast(@TotalInProgress as varchar)+' , TODO: '+CAST(@TotalToDo as varchar) +' Done '+CAST(@TotalDone as varchar)
		END
	ELSE
		BEGIN
			SET @TotalDone = CASE WHEN @TotalDone > 2 THEN 2  ELSE @TotalDone END 
			SET @TotalInProgress = ( @TopN - @TotalDone )
 print 'F > TotalInProgress: '+cast(@TotalInProgress as varchar)+' , TODO: '+CAST(@TotalToDo as varchar) +' Done '+CAST(@TotalDone as varchar)
		END
END
IF (@TotalDone>0 and @TotalInProgress=0 AND @TotalToDo>0)
BEGIN
	SET @TotalDone= case when @TotalDone>2 THEN 2 ELSE @TotalDone END
	SET @TotalToDo=@TopN-@TotalDone
PRINT 'H > TotalInProgress: '+CAST(@TotalInProgress AS VARCHAR)+' , TODO: '+CAST(@TotalToDo AS VARCHAR) +' Done '+CAST(@TotalDone as varchar)
END
IF (@TotalDone>0 and @TotalInProgress=0 and @TotalToDo=0)
BEGIN -- only DONE
	SET @TotalDone=@TopN
	SET @TotalToDo=1 -- handle the error of Top Zero
	SET @TotalInProgress=1 -- handle the error of Top Zero
END
IF (@TotalDone=0 and @TotalInProgress>0 and @TotalToDo=0)
BEGIN -- Only InProgress
	SET @TotalInProgress=@TopN
	SET @TotalToDo=1 -- handle the error of Top Zero
	SET @TotalDone=1 -- handle the error of Top Zero
END
IF (@TotalDone=0 and @TotalInProgress=0 and @TotalToDo>0)
BEGIN -- Only TODO
	SET @TotalToDo=@TopN
	SET @TotalInProgress=1 -- handle the error of Top Zero
	SET @TotalDone=1 -- handle the error of Top Zero
END
/*
SELECT @TotalDone 'Done'
SELECT @TotalInProgress 'InProgress'
SELECT @TotalToDo 'To-Do'*/

IF (@TotalToDo=0 and @TotalDone=0 and @TotalInProgress>0)
BEGIN -- ONLY PROGRESS , SHOW UP TO FIVE WITH THE MOST RECENT ONE THEY WORKED ON SHOWING UP FIRST.
	SELECT DISTINCT TOP (@TopN) tblFinal.* FROM (
	SELECT 
		CASE WHEN ((ISNULL(StepCount, 0)) > 0 AND (ISNULL(StepCount, 0))<TotalSteps) THEN 'In-Progress' 
		WHEN (TabLink = '') THEN 'Soon' 
		WHEN (TotalSteps = StepCount) THEN 'Completed' 
		WHEN (B.IsAssigned=1 AND StepCount=0) then 'To-Do'
		END AS [Status],
		B.* 
	FROM (
	SELECT 
		USS.UserID,Max(USS.LastUpdatedOn) LastUpdatedOn, UC.CreatedOn,A.SolveSpaceID,
		CASE WHEN (IsNull(UC.CreatedBy,-1)=@UserID AND IsNull(UC.ItemID,0)>0) THEN 1 ELSE 0 END IsSelfAssigned,
		CASE WHEN ISNULL(UC.ItemID,0)>0 THEN 1 ELSE 0 END IsAssigned,
		ISNULL( USS.StepCount,0) StepCount, 
		 A.DurationInMin, A.ShortDescription,
		A.TabLink, A.Title, A.TotalSteps
	FROM 
		(SELECT * FROM ClearAction_SolveSpaceMaster WHERE IsDeleted=0) A
	LEFT OUTER JOIN 
	(
		SELECT DISTINCT USERID,COUNT(StepID) StepCount,SolveSpaceID ,MAX(LastUpdatedOn) LastUpdatedOn
		FROM ClearAction_UserSolveSpaces 
		GROUP BY SolveSpaceID,UserID
		HAVING UserID=@UserID
	) USS 
	ON USS.SolveSpaceID=A.SolveSpaceID 
	LEFT OUTER JOIN 
	(SELECT DISTINCT * FROM ClearAction_UserComponents WHERE UseriD=@UserID and ComponentID=3) UC  
	ON A.SolveSpaceID=UC.ItemID
	GROUP BY USS.UserID,UC.UserID,USS.LastUpdatedOn,UC.CreatedOn,UC.ItemID,USS.StepCount,A.Title,A.SolveSpaceID,
	UC.CreatedOn,UC.CreatedBy,a.DurationInMin,a.ShortDescription,a.TabLink,a.TotalSteps
	HAVING 
	(UC.UserID=@UserID OR USS.UserID=@UserID ) and UC.ItemId>0
	) AS B) tblFinal
	LEFT OUTER JOIN ClearAction_SolveSpaceCategories SSC on SSC.SolveSpaceID=tblFinal.SolveSpaceID
	WHERE [status] = 'To-Do' 
	ORDER BY LastUpdatedOn DESC
	END
	
ELSE
BEGIN
-- Mix Bag Case 
/* Get In-Progress List First*/
SELECT * FROM (
	SELECT DISTINCT tblFinal.* FROM (
	SELECT 
		CASE WHEN ((ISNULL(StepCount, 0)) > 0 AND (ISNULL(StepCount, 0))<TotalSteps) THEN 'In-Progress' 
		WHEN (TabLink = '') THEN 'Soon' 
		WHEN (TotalSteps = StepCount) THEN 'Completed' 
		WHEN (B.IsAssigned=1 AND StepCount=0) then 'To-Do'
		END AS [Status],
		B.* 
	FROM (
	SELECT 
		USS.UserID,Max(USS.LastUpdatedOn) LastUpdatedOn, UC.CreatedOn,A.SolveSpaceID,
		CASE WHEN (IsNull(UC.CreatedBy,-1)=@UserID AND IsNull(UC.ItemID,0)>0) THEN 1 ELSE 0 END IsSelfAssigned,
		CASE WHEN ISNULL(UC.ItemID,0)>0 THEN 1 ELSE 0 END IsAssigned,
		ISNULL( USS.StepCount,0) StepCount, 
		 A.DurationInMin, A.ShortDescription,
		A.TabLink, A.Title, A.TotalSteps
	FROM 
		(SELECT * FROM ClearAction_SolveSpaceMaster WHERE IsDeleted=0) A
	LEFT OUTER JOIN 
	(
		SELECT DISTINCT USERID,COUNT(StepID) StepCount,SolveSpaceID ,MAX(LastUpdatedOn) LastUpdatedOn
		FROM ClearAction_UserSolveSpaces 
		GROUP BY SolveSpaceID,UserID
		HAVING UserID=@UserID
	) USS 
	ON USS.SolveSpaceID=A.SolveSpaceID 
	LEFT OUTER JOIN 
	(SELECT DISTINCT * FROM ClearAction_UserComponents WHERE UseriD=@UserID and ComponentID=3) UC  
	ON A.SolveSpaceID=UC.ItemID
	GROUP BY USS.UserID,UC.UserID,USS.LastUpdatedOn,UC.CreatedOn,UC.ItemID,USS.StepCount,A.Title,A.SolveSpaceID,
	UC.CreatedOn,UC.CreatedBy,a.DurationInMin,a.ShortDescription,a.TabLink,a.TotalSteps
	HAVING 
	(UC.UserID=@UserID OR USS.UserID=@UserID ) and UC.ItemId>0
	) AS B) tblFinal
	LEFT OUTER JOIN ClearAction_SolveSpaceCategories SSC on SSC.SolveSpaceID=tblFinal.SolveSpaceID
	WHERE [status] = 'In-Progress') A  where title like ''+@search+'%'

UNION 
-- Get TO-DO List on Second
SELECT * FROM (
 SELECT DISTINCT  tblFinal.* FROM (
	SELECT
		CASE WHEN ((ISNULL(StepCount, 0)) > 0 AND (ISNULL(StepCount, 0))<TotalSteps) THEN 'In-Progress' 
		WHEN (TabLink = '') THEN 'Soon' 
		WHEN (TotalSteps = StepCount) THEN 'Completed' 
		WHEN (B.IsAssigned=1 AND StepCount=0) then 'To-Do'
		END AS [Status],
		B.* 
	FROM (
	SELECT 
		USS.UserID,Max(USS.LastUpdatedOn) LastUpdatedOn, UC.CreatedOn,A.SolveSpaceID,
		CASE WHEN (IsNull(UC.CreatedBy,-1)=@UserID AND IsNull(UC.ItemID,0)>0) THEN 1 ELSE 0 END IsSelfAssigned,
		CASE WHEN ISNULL(UC.ItemID,0)>0 THEN 1 ELSE 0 END IsAssigned,
		ISNULL( USS.StepCount,0) StepCount, 
		 A.DurationInMin, A.ShortDescription,
		A.TabLink, A.Title, A.TotalSteps
	FROM 
		(SELECT * FROM ClearAction_SolveSpaceMaster WHERE IsDeleted=0) A 
	LEFT OUTER JOIN 
	(
		SELECT DISTINCT USERID,COUNT(StepID) StepCount,SolveSpaceID ,MAX(LastUpdatedOn) LastUpdatedOn
		FROM ClearAction_UserSolveSpaces 
		GROUP BY SolveSpaceID,UserID
		HAVING UserID=@UserID
	) USS 
	ON USS.SolveSpaceID=A.SolveSpaceID 
	LEFT OUTER JOIN 
	(SELECT DISTINCT * FROM ClearAction_UserComponents WHERE UseriD=@UserID and ComponentID=3) UC  
	ON A.SolveSpaceID=UC.ItemID
	GROUP BY USS.UserID,UC.UserID,USS.LastUpdatedOn,UC.CreatedOn,UC.ItemID,USS.StepCount,A.Title,A.SolveSpaceID,
	UC.CreatedOn,UC.CreatedBy,a.DurationInMin,a.ShortDescription,a.TabLink,a.TotalSteps
	HAVING 
	(UC.UserID=@UserID OR USS.UserID=@UserID ) and UC.ItemId>0
	) AS B) tblFinal
	LEFT OUTER JOIN ClearAction_SolveSpaceCategories SSC on SSC.SolveSpaceID=tblFinal.SolveSpaceID
	WHERE [status] = 'To-Do') B where title like ''+@search+'%'
UNION
-- Get DONE List at 3rd position
	SELECT * FROM (
	SELECT DISTINCT tblFinal.* FROM (
		SELECT 
			CASE WHEN ((ISNULL(StepCount, 0)) > 0 AND (ISNULL(StepCount, 0))<TotalSteps) THEN 'In-Progress' 
			WHEN (TabLink = '') THEN 'Soon' 
			WHEN (TotalSteps = StepCount) THEN 'Completed' 
			WHEN (B.IsAssigned=1 AND StepCount=0) then 'To-Do'
			END AS [Status],
			B.* 
		FROM (
		SELECT 
			USS.UserID,Max(USS.LastUpdatedOn) LastUpdatedOn, UC.CreatedOn,A.SolveSpaceID,
			CASE WHEN (IsNull(UC.CreatedBy,-1)=@UserID AND IsNull(UC.ItemID,0)>0) THEN 1 ELSE 0 END IsSelfAssigned,
			CASE WHEN ISNULL(UC.ItemID,0)>0 THEN 1 ELSE 0 END IsAssigned,
			ISNULL( USS.StepCount,0) StepCount, 
			 A.DurationInMin, A.ShortDescription,
			A.TabLink, A.Title, A.TotalSteps
		FROM 
			(SELECT * FROM ClearAction_SolveSpaceMaster WHERE IsDeleted=0) A
		LEFT OUTER JOIN 
		(
			SELECT DISTINCT USERID,COUNT(StepID) StepCount,SolveSpaceID ,MAX(LastUpdatedOn) LastUpdatedOn
			FROM ClearAction_UserSolveSpaces 
			GROUP BY SolveSpaceID,UserID
			HAVING UserID=@UserID
		) USS 
		ON USS.SolveSpaceID=A.SolveSpaceID 
		LEFT OUTER JOIN 
		(SELECT DISTINCT * FROM ClearAction_UserComponents WHERE UseriD=@UserID and ComponentID=3) UC  
		ON A.SolveSpaceID=UC.ItemID
		GROUP BY USS.UserID,UC.UserID,USS.LastUpdatedOn,UC.CreatedOn,UC.ItemID,USS.StepCount,A.Title,A.SolveSpaceID,
		UC.CreatedOn,UC.CreatedBy,a.DurationInMin,a.ShortDescription,a.TabLink,a.TotalSteps
		HAVING 
		(UC.UserID=@UserID OR USS.UserID=@UserID ) and UC.ItemId>0
		) AS B) tblFinal
		LEFT OUTER JOIN ClearAction_SolveSpaceCategories SSC on SSC.SolveSpaceID=tblFinal.SolveSpaceID
		WHERE [status] = 'Completed') as C where title like ''+@search+'%'
		
	END

END
