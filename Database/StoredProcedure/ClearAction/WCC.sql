
alter PROCEDURE [dbo].[WCC_GetInsightSubject]        
 @key varchar(max)      
AS      
    
    
    
select title FROM     
[WCC_Posts]    
Where    
[WCCId]=@key    
   


alter PROCEDURE [dbo].[WCC_GetInsightPresenter]        
 @key varchar(max)      
AS      
    
    
    
select [PresenterName] FROM     
[WCC_Posts]    
Where    
[WCCId]=@key    
   