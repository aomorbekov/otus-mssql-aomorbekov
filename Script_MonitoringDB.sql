-- ПРОЕКТ: Система БД для ИТ-Мониторинга (MonitoringDB)
use master;
go

-- Создание БД (если существует - удаляю для чистого старта)
if db_id('MonitoringDB') is not null
begin
    alter database MonitoringDB set single_user with rollback immediate;
    drop database MonitoringDB;
end
go

create database MonitoringDB;
go

use MonitoringDB;
go

-- 1: СЕКЦИОНИРОВАНИЕ (PARTITIONING)
create partition function pf_Metrics_Monthly (datetime2)
as range right for values (
    '2026-02-01', '2026-03-01', '2026-04-01', '2026-05-01', '2026-06-01'
);
go

create partition scheme ps_Metrics_Monthly
as partition pf_Metrics_Monthly all to ([PRIMARY]);
go

-- 2: ТАБЛИЦЫ - СПРАВОЧНИКИ
create table Roles (
    RoleID tinyint identity(1,1) constraint PK_Roles primary key,
    RoleName nvarchar(50) not null constraint UQ_Roles_Name unique
);

create table Statuses (
    StatusID tinyint identity(1,1) constraint PK_Statuses primary key,
    StatusName nvarchar(50) not null constraint UQ_Statuses_Name unique
);

create table Severities (
    SeverityID tinyint identity(1,1) constraint PK_Severities primary key,
    SeverityName nvarchar(50) not null constraint UQ_Severities_Name unique
);

create table MetricTypes (
    MetricTypeID tinyint identity(1,1) constraint PK_MetricTypes primary key,
    MetricName nvarchar(100) not null constraint UQ_MetricTypes_Name unique,
    Unit varchar(20) not null
);

create table OperatingSystems (
    OSID tinyint identity(1,1) constraint PK_OperatingSystems primary key,
    OSName nvarchar(100) not null constraint UQ_OperatingSystems_Name unique
);
go

-- 3: ТАБЛИЦЫ - ИНВЕНТАРИЗАЦИЯ (CMDB)
create table Users (
    UserID int identity(1,1) constraint PK_Users primary key,
    RoleID tinyint not null constraint FK_Users_Roles foreign key references Roles(RoleID),
    UserName nvarchar(100) not null,
    Email varchar(150) not null constraint UQ_Users_Email unique,
    IsActive bit not null constraint DF_Users_IsActive default 1
);

create table Servers (
    ServerID int identity(1,1) constraint PK_Servers primary key,
    HostName varchar(100) not null constraint UQ_Servers_HostName unique,
    IPAddress varchar(15) not null,
    Environment varchar(50) not null constraint CHK_Servers_Environment check (Environment in ('Prod', 'Dev', 'Test', 'Stage')),
    OSID tinyint constraint FK_Servers_OS foreign key references OperatingSystems(OSID)
);
create nonclustered index IX_Servers_OSID on Servers(OSID);

create table Services (
    ServiceID int identity(1,1) constraint PK_Services primary key,
    ServerID int not null constraint FK_Services_Servers foreign key references Servers(ServerID) on delete cascade,
    ServiceName nvarchar(100) not null,
    Port int null
);
go

-- 4: ТАБЛИЦЫ - ТРАНЗАКЦИИ (МЕТРИКИ И ИНЦИДЕНТЫ)
create table ServerMetrics (
    MetricID bigint identity(1,1),
    ServerID int not null constraint FK_Metrics_Servers foreign key references Servers(ServerID),
    MetricTypeID tinyint not null constraint FK_Metrics_Types foreign key references MetricTypes(MetricTypeID),
    MetricValue decimal(10,2) not null,
    MeasuredAt datetime2 not null constraint DF_Metrics_MeasuredAt default sysdatetime(),
    constraint PK_ServerMetrics primary key clustered (MeasuredAt, MetricID)
) on ps_Metrics_Monthly(MeasuredAt);

-- Архив для переключения секций (Partition Switching)
create table ServerMetrics_Archive (
    MetricID bigint identity(1,1),
    ServerID int not null,
    MetricTypeID tinyint not null,
    MetricValue decimal(10,2) not null,
    MeasuredAt datetime2 not null,
    constraint PK_ServerMetrics_Archive primary key clustered (MeasuredAt, MetricID)
) on ps_Metrics_Monthly(MeasuredAt);

create table Incidents (
    IncidentID bigint identity(1,1) constraint PK_Incidents primary key,
    ServerID int not null constraint FK_Incidents_Servers foreign key references Servers(ServerID),
    ServiceID int null constraint FK_Incidents_Services foreign key references Services(ServiceID),
    StatusID tinyint not null constraint FK_Incidents_Statuses foreign key references Statuses(StatusID),
    SeverityID tinyint not null constraint FK_Incidents_Severities foreign key references Severities(SeverityID),
    Title nvarchar(200) not null,
    Description nvarchar(max) null,
    CreatedAt datetime2 not null constraint DF_Incidents_CreatedAt default sysdatetime(),
    ResolvedAt datetime2 null
);
create nonclustered index IX_Incidents_Status on Incidents(StatusID) include (CreatedAt);

create table IncidentComments (
    CommentID bigint identity(1,1) constraint PK_IncidentComments primary key,
    IncidentID bigint not null constraint FK_Comments_Incidents foreign key references Incidents(IncidentID) on delete cascade,
    UserID int not null constraint FK_Comments_Users foreign key references Users(UserID),
    CommentText nvarchar(max) not null,
    CreatedAt datetime2 not null constraint DF_Comments_CreatedAt default sysdatetime()
);
go

-- 5: ФУНКЦИИ И ПРЕДСТАВЛЕНИЯ (VIEWS)
create function fn_GetIncidentDuration (@IncidentID bigint)
returns int
as
begin
    declare @DurationMinutes int;
    declare @CreatedAt datetime2;
    declare @ResolvedAt datetime2;

    select @CreatedAt = CreatedAt, @ResolvedAt = isnull(ResolvedAt, sysdatetime())
    from Incidents where IncidentID = @IncidentID;

    set @DurationMinutes = datediff(minute, @CreatedAt, @ResolvedAt);
    return @DurationMinutes;
end;
go

create view vw_ActiveIncidents as
select 
    i.IncidentID, s.HostName, sv.ServiceName, st.StatusName, sev.SeverityName, i.Title, i.CreatedAt,
    dbo.fn_GetIncidentDuration(i.IncidentID) as DowntimeMinutes
from Incidents i
join Servers s on i.ServerID = s.ServerID
left join Services sv on i.ServiceID = sv.ServiceID
join Statuses st on i.StatusID = st.StatusID
join Severities sev on i.SeverityID = sev.SeverityID
where i.StatusID != 3; 
go

create view vw_ServerHealth as
select 
    s.HostName, s.Environment, os.OSName,
    count(case when i.StatusID = 1 then 1 end) as NewIncidents,
    count(case when i.StatusID = 2 then 1 end) as InProgressIncidents
from Servers s
left join OperatingSystems os on s.OSID = os.OSID
left join Incidents i on s.ServerID = i.ServerID
group by s.HostName, s.Environment, os.OSName;
go

-- 6: ХРАНИМЫЕ ПРОЦЕДУРЫ И ТРИГГЕРЫ
create procedure sp_AddServerMetric
    @ServerID int, @MetricTypeID tinyint, @MetricValue decimal(10,2)
as
begin
    set nocount on;
    insert into ServerMetrics (ServerID, MetricTypeID, MetricValue)
    values (@ServerID, @MetricTypeID, @MetricValue);
end;
go

create procedure sp_CreateIncident
    @ServerID int,
    @ServiceID int = NULL,
    @SeverityID tinyint,
    @Title nvarchar(255),
    @Description nvarchar(max),
    @CreatedByUserID int
as
begin
    set nocount on;

    -- ЗАЩИТА ОТ ДУБЛЕЙ (Alert Storm Protection)
    declare @ExistingIncidentID bigint;

    select @ExistingIncidentID = IncidentID 
    from Incidents 
    where ServerID = @ServerID 
      and Title = @Title 
      and StatusID in (1, 2); -- Ищем только Новые (1) или В работе (2)

    -- Если открытая авария уже есть, просто пишем комментарий и выходим
    if @ExistingIncidentID is not null
    begin
        insert into IncidentComments (IncidentID, UserID, CommentText)
        values (@ExistingIncidentID, @CreatedByUserID, N'Повторное срабатывание алерта: проблема все еще актуальна.');
        return; 
    end

    -- СОЗДАНИЕ НОВОЙ АВАРИИ (если дублей нет)
    begin try
        begin transaction;
        
        declare @NewIncidentID bigint;
        
        insert into Incidents (ServerID, ServiceID, StatusID, SeverityID, Title, Description, CreatedAt)
        values (@ServerID, @ServiceID, 1, @SeverityID, @Title, @Description, sysdatetime());
        
        set @NewIncidentID = scope_identity();

        insert into IncidentComments (IncidentID, UserID, CommentText)
        values (@NewIncidentID, @CreatedByUserID, N'Инцидент автоматически зарегистрирован системой мониторинга.');

        commit transaction;
    end try
    begin catch
        if @@trancount > 0 rollback transaction;
        throw;
    end catch
end;
go

create procedure sp_UpdateIncidentStatus
    @IncidentID bigint, @NewStatusID tinyint, @UserID int, @CommentText nvarchar(max)
as
begin
    set nocount on;
    begin try
        begin transaction; 
        update Incidents
        set StatusID = @NewStatusID, ResolvedAt = case when @NewStatusID = 3 then sysdatetime() else ResolvedAt end
        where IncidentID = @IncidentID;

        insert into IncidentComments (IncidentID, UserID, CommentText)
        values (@IncidentID, @UserID, @CommentText);
        commit transaction; 
    end try
    begin catch
        if @@trancount > 0 rollback transaction; 
        throw;
    end catch
end;
go

create procedure sp_PurgeOldMetrics @TargetDate datetime2
as
begin
    set nocount on;
    declare @PartitionNumber int = $partition.pf_Metrics_Monthly(@TargetDate);
    truncate table ServerMetrics_Archive;
    alter table ServerMetrics switch partition @PartitionNumber to ServerMetrics_Archive partition @PartitionNumber;
    truncate table ServerMetrics_Archive;
end;
go

create procedure sp_AutoResolveIncident
    @ServerID int,
    @Title nvarchar(255),
    @ResolvedByUserID int -- ID системного аккаунта (например, 999)
as
begin
    set nocount on;

    declare @ExistingIncidentID bigint;

    -- Ищем открытую аварию (Новая или В работе) с таким же заголовком
    select @ExistingIncidentID = IncidentID 
    from Incidents 
    where ServerID = @ServerID 
      and Title = @Title 
      and StatusID in (1, 2); 

    -- Если такая авария есть — закрываем её
    if @ExistingIncidentID is not null
    begin
        begin try
            begin transaction;
            
            -- Переводим статус в 3 (Закрыто)
            update Incidents
            set StatusID = 3
            where IncidentID = @ExistingIncidentID;

            -- Оставляем системный комментарий
            insert into IncidentComments (IncidentID, UserID, CommentText)
            values (@ExistingIncidentID, @ResolvedByUserID, N'Автовосстановление: Метрики вернулись в норму. Инцидент закрыт автоматически.');

            commit transaction;
        end try
        begin catch
            if @@trancount > 0 rollback transaction;
            throw;
        end catch
    end
end;
go

create trigger trg_IncidentStatusGuard
on Incidents
after update
as
begin
    set nocount on;
    if exists (select 1 from inserted i join deleted d on i.IncidentID = d.IncidentID where d.StatusID in (3, 4) and i.StatusID = 1)
    begin
        raiserror(N'Ошибка бизнес-логики: откат решенного инцидента обратно в статус "Новый" запрещен!', 16, 1);
        rollback transaction;
    end
end;
go

-- 7: БЕЗОПАСНОСТЬ (РОЛИ И ПРАВА)
create role MonitoringAppRole;
grant execute on object::sp_AddServerMetric to MonitoringAppRole;
grant execute on object::sp_CreateIncident to MonitoringAppRole;
grant execute on object::sp_UpdateIncidentStatus to MonitoringAppRole;
grant execute on object::sp_PurgeOldMetrics to MonitoringAppRole;
grant select on object::vw_ActiveIncidents to MonitoringAppRole;
grant select on object::vw_ServerHealth to MonitoringAppRole;
go

-- 8: НАПОЛНЕНИЕ СПРАВОЧНИКОВ (DICTIONARIES DML)
insert into Roles (RoleName) values (N'Администратор'), (N'Дежурный инженер'), (N'Аналитик');
insert into Statuses (StatusName) values (N'Новый'), (N'В работе'), (N'Решен'), (N'Закрыт');
insert into Severities (SeverityName) values (N'Низкий'), (N'Средний'), (N'Высокий'), (N'Критичный');
insert into MetricTypes (MetricName, Unit) values (N'Загрузка CPU', '%'), (N'Использование RAM', 'MB'), (N'Свободное место на диске', '%'), (N'Сетевой пинг', 'ms');
insert into OperatingSystems (OSName) values (N'Windows Server 2019'), (N'Windows Server 2022'), (N'Ubuntu 22.04 LTS'), (N'CentOS 8');

insert into Users (RoleID, UserName, Email) values 
(1, N'Аскар Аскаров', 'askarov.askar@company.local'),
(2, N'Серик Сериков', 'serikov.s@company.local'),
(2, N'Айбек Айбеков', 'aibekov.a@company.local');
go