/****** Object:  StoredProcedure [dbo].[CA_GetConnectionsByUserID]    Script Date: 26-02-2021 6.04.53 PM ******/
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
	 WHERE  STATUS=2    
	 AND    
	 ( 
 
	 UserID=@UserID
 
	 AND

	 RelatedUserID in 
	 (
 
			SELECT USERID FROM Users Where
			UserName IN
			(
			SELECT Username FROM aspnet_Users  AU INNER JOIN aspnet_Membership AM
			ON AU.UserId=AM.UserId
			WHERE
			AM.CreateDate<>AM.LastLoginDate

		
			)
 
		)
 
	 )    
   
	 UNION  
  
	SELECT   
	UserRelationshipID,RelatedUserID as [UserID],UserId as [RelatedUserID],RelationShipID,Status,CreatedByUserID,CreatedOnDate  
	 , LastModifiedByUserID,LastModifiedOnDate  
	 FROM UserRelationships    
	 WHERE  STATUS=2    
	 AND    
	 ( 
		RelatedUserID=@UserID
 
	 AND

	 USERID in (
 
			SELECT USERID FROM Users Where
			UserName IN
			(
			SELECT Username FROM aspnet_Users  AU INNER JOIN aspnet_Membership AM
			ON AU.UserId=AM.UserId
			WHERE
			AM.CreateDate<>AM.LastLoginDate

		
			)
 
		)
 
	 )    
	END  