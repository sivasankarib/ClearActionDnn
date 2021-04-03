

create PROCEDURE [dbo].[ClearAction_GetEmailSubscripion]
AS
BEGIN
declare  @table table(Email varchar(max))

insert into @table
  select [Email] from [ClearChoice_ProfileResponse]  pr
  inner join [ClearChoice_ProfileResponseOption] pro on pro.ProfileResponseID=pr.ProfileResponseId
  inner join users u on u.userid=pr.UserID where pr.QuestionId=28 and pro.[QuestionOptionID]=98 and IsActive=1
	SELECT STUFF((SELECT ',' + Email
            FROM @table
            FOR XML PATH('')) ,1,1,'') AS Txt
END

