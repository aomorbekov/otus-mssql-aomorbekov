CREATE TABLE [Roles] (
  [RoleID] int PRIMARY KEY,
  [RoleName] string NOT NULL
)
GO

CREATE TABLE [Users] (
  [UserID] int PRIMARY KEY,
  [FullName] string NOT NULL,
  [Email] string NOT NULL,
  [Login] string NOT NULL,
  [RoleID] int NOT NULL
)
GO

CREATE TABLE [OperatingSystems] (
  [OSID] int PRIMARY KEY,
  [OSName] string NOT NULL,
  [OSVersion] string NOT NULL
)
GO

CREATE TABLE [Servers] (
  [ServerID] int PRIMARY KEY,
  [HostName] string NOT NULL,
  [IPAddress] string NOT NULL,
  [Environment] string NOT NULL,
  [OSID] int NOT NULL,
  [ResponsibleUserID] int NOT NULL
)
GO

CREATE TABLE [ServiceTypes] (
  [ServiceTypeID] int PRIMARY KEY,
  [ServiceTypeName] string NOT NULL
)
GO

CREATE TABLE [Services] (
  [ServiceID] int PRIMARY KEY,
  [ServerID] int NOT NULL,
  [ServiceTypeID] int NOT NULL,
  [ServiceName] string NOT NULL,
  [Port] int,
  [IsActive] boolean NOT NULL
)
GO

CREATE TABLE [MetricTypes] (
  [MetricTypeID] int PRIMARY KEY,
  [MetricName] string NOT NULL,
  [Unit] string NOT NULL
)
GO

CREATE TABLE [ServerMetrics] (
  [MetricID] int PRIMARY KEY,
  [ServerID] int NOT NULL,
  [MetricTypeID] int NOT NULL,
  [MetricValue] decimal NOT NULL,
  [CollectedAt] datetime NOT NULL
)
GO

CREATE TABLE [Statuses] (
  [StatusID] int PRIMARY KEY,
  [StatusName] string NOT NULL
)
GO

CREATE TABLE [Incidents] (
  [IncidentID] int PRIMARY KEY,
  [ServerID] int NOT NULL,
  [ServiceID] int,
  [StatusID] int NOT NULL,
  [Title] string NOT NULL,
  [Description] string,
  [CreatedAt] datetime NOT NULL,
  [ResolvedAt] datetime
)
GO

CREATE TABLE [NotificationTypes] (
  [NotificationTypeID] int PRIMARY KEY,
  [TypeName] string NOT NULL
)
GO

CREATE TABLE [Notifications] (
  [NotificationID] int PRIMARY KEY,
  [IncidentID] int NOT NULL,
  [UserID] int NOT NULL,
  [NotificationTypeID] int NOT NULL,
  [SentAt] datetime NOT NULL,
  [DeliveryStatus] string NOT NULL
)
GO

ALTER TABLE [Users] ADD FOREIGN KEY ([RoleID]) REFERENCES [Roles] ([RoleID])
GO

ALTER TABLE [Servers] ADD FOREIGN KEY ([OSID]) REFERENCES [OperatingSystems] ([OSID])
GO

ALTER TABLE [Servers] ADD FOREIGN KEY ([ResponsibleUserID]) REFERENCES [Users] ([UserID])
GO

ALTER TABLE [Services] ADD FOREIGN KEY ([ServerID]) REFERENCES [Servers] ([ServerID])
GO

ALTER TABLE [Services] ADD FOREIGN KEY ([ServiceTypeID]) REFERENCES [ServiceTypes] ([ServiceTypeID])
GO

ALTER TABLE [ServerMetrics] ADD FOREIGN KEY ([ServerID]) REFERENCES [Servers] ([ServerID])
GO

ALTER TABLE [ServerMetrics] ADD FOREIGN KEY ([MetricTypeID]) REFERENCES [MetricTypes] ([MetricTypeID])
GO

ALTER TABLE [Incidents] ADD FOREIGN KEY ([ServerID]) REFERENCES [Servers] ([ServerID])
GO

ALTER TABLE [Incidents] ADD FOREIGN KEY ([ServiceID]) REFERENCES [Services] ([ServiceID])
GO

ALTER TABLE [Incidents] ADD FOREIGN KEY ([StatusID]) REFERENCES [Statuses] ([StatusID])
GO

ALTER TABLE [Notifications] ADD FOREIGN KEY ([IncidentID]) REFERENCES [Incidents] ([IncidentID])
GO

ALTER TABLE [Notifications] ADD FOREIGN KEY ([UserID]) REFERENCES [Users] ([UserID])
GO

ALTER TABLE [Notifications] ADD FOREIGN KEY ([NotificationTypeID]) REFERENCES [NotificationTypes] ([NotificationTypeID])
GO
