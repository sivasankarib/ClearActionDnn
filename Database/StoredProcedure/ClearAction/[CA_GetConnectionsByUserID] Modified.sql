/****** Object:  StoredProcedure [dbo].[CA_GetConnectionsByUserID]    Script Date: 24-03-2021 04:29:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	ALTER PROCEDURE [dbo].[CA_GetConnectionsByUserID]     
	 @UserID int    
	AS    
	BEGIN    
	 SELECT UserRelationshipID,UserId,RelatedUserID,RelationShipID,Status,CreatedByUserID,CreatedOnDate  
	 , LastModifiedByUserID,LastModifiedOnDate  
	  FROM UserRelationships    

	END  