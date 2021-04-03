/****** Object:  StoredProcedure [dbo].[Blog_GetBlog_With_Tags]    Script Date: 6/11/2020 8:55:38 AM ******/
DROP PROCEDURE IF EXISTS [dbo].[Blog_GetBlog_With_Tags]
GO
/****** Object:  StoredProcedure [dbo].[Blog_GetBlog_With_Tags]    Script Date: 6/11/2020 8:55:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Rakesh
-- Create Date: 06/11/2020
-- Description: Get list of Insights with assigned tags
-- exec Blog_GetBlog_With_Tags
-- =============================================
CREATE PROCEDURE [dbo].[Blog_GetBlog_With_Tags]
(
    -- Add the parameters for the stored procedure here
    @userId INT = -1
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

    -- Insert statements for procedure here
	SELECT P.ContentItemId AS Id,  P.Title, STRING_AGG(TT.Name, ', ') As Tags FROM Blog_Posts P
	JOIN ContentItems_Tags T ON P.ContentItemId = T.ContentItemID
	JOIN Taxonomy_Terms TT ON TT.TermID = T.TermID
	WHERE @userid = -1 or P.CreatedByUserID = @userid
	GROUP BY P.ContentItemId, P.Title
END
GO