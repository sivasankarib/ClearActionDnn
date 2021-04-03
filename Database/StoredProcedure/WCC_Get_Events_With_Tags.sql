/****** Object:  StoredProcedure [dbo].[WCC_Get_Events_With_Tags]    Script Date: 6/11/2020 7:31:53 AM ******/
DROP PROCEDURE IF EXISTS [dbo].[WCC_Get_Events_With_Tags]
GO
/****** Object:  StoredProcedure [dbo].[WCC_Get_Events_With_Tags]    Script Date: 6/11/2020 7:31:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      <Author, , Name>
-- Create Date: <Create Date, , >
-- Description: Get events with assigned tags
-- exec WCC_Get_Events_With_Tags
-- =============================================
CREATE PROCEDURE [dbo].[WCC_Get_Events_With_Tags]
(
    @componentId INT = -1
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

    -- Insert statements for procedure here
	DECLARE @ComponentList TABLE
	(
	Id INT NOT NULL,
	ComponentName VARCHAR(150) NOT NULL
	)
	
	INSERT INTO @ComponentList VALUES
		(4, 'Community Calls'),
		(5, 'Webcast Conversations'),
		(6, 'Roundtable'),
		(7, 'Virtual Conference'),
		(8, 'Fireside Chat'),
		(9, 'Expert Presentation')
	
	;WITH Events_CTE AS
	(
		SELECT P.WCCId AS Id, P.Title, C.ComponentName, T.TagName from WCC_Posts P
		JOIN @ComponentList C ON C.Id = P.ComponentID
		JOIN WCC_Posts_Tags PT ON PT.PostId = P.WCCId
		JOIN WCC_Tags T ON T.TagId = PT.TagId
		WHERE @componentId = -1 OR P.ComponentID = @componentId
	)
	SELECT Id, Title, ComponentName, STRING_AGG(TagName, ', ') Tags FROM Events_CTE
	GROUP BY Id, Title, ComponentName 
END
GO
