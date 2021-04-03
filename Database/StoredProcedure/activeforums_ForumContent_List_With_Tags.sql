/****** Object:  StoredProcedure [dbo].[activeforums_ForumContent_List_With_Tags]    Script Date: 6/11/2020 9:35:20 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[activeforums_ForumContent_List_With_Tags]
GO
/****** Object:  StoredProcedure [dbo].[activeforums_ForumContent_List_With_Tags]    Script Date: 6/11/2020 9:35:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Rakesh
-- Create Date: 06/11/2020
-- Description: Get list forums with tags
-- exec activeforums_ForumContent_List_With_Tags
-- =============================================
CREATE PROCEDURE [dbo].[activeforums_ForumContent_List_With_Tags]
(
    -- Add the parameters for the stored procedure here
    @authorId INT = -1
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

    -- Insert statements for procedure here
    ;WITH Forums_CTE AS (
	SELECT C.ContentId AS Id, STRING_AGG(TS.TagName, ', ') TAGS FROM activeforums_Content C
	JOIN activeforums_Topics T ON T.ContentId = C.ContentId
	JOIN activeforums_Topics_Tags TT ON TT.TopicId = T.TopicId
	JOIN activeforums_Tags TS ON TS.TagId = TT.TagId
	GROUP BY C.ContentId
	)
	SELECT F.Id, C.Subject, C.Body, C.AuthorName, F.TAGS FROM Forums_CTE F
	JOIN activeforums_Content C ON C.ContentId = F.Id
	WHERE @authorId = -1 OR C.AuthorId = @authorId
	ORDER BY C.Subject
END
GO
