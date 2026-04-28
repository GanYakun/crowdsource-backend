-- 创建应用用户 cs_user，仅授权 crowdsource_db 数据库
-- 最小权限原则：只授予必要的权限

-- 删除已存在的用户（如果存在）
DROP USER IF EXISTS 'cs_user'@'%';
DROP USER IF EXISTS 'cs_user'@'localhost';

-- 创建用户（允许从任何主机连接）
CREATE USER 'cs_user'@'%' IDENTIFIED BY 'csusermysqlpassword123';

-- 授予 crowdsource_db 数据库的所有权限（最小授权）
-- 只授予 SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, INDEX, REFERENCES 权限
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, INDEX, REFERENCES 
ON crowdsource_db.* TO 'cs_user'@'%';

-- 刷新权限
FLUSH PRIVILEGES;

-- 验证权限
SHOW GRANTS FOR 'cs_user'@'%';
