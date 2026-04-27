-- 众包小程序数据库表设计

CREATE DATABASE IF NOT EXISTS crowdsource DEFAULT CHARACTER SET utf8mb4;
USE crowdsource;

-- 用户表
CREATE TABLE `user` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `open_id`     VARCHAR(64)  COMMENT '微信openId',
    `phone`       VARCHAR(20)  COMMENT '手机号',
    `nickname`    VARCHAR(64)  NOT NULL COMMENT '昵称',
    `avatar`      VARCHAR(255) COMMENT '头像URL',
    `role`        TINYINT      NOT NULL DEFAULT 2 COMMENT '角色: 1=管理员 2=发单人 3=接单人',
    `status`      TINYINT      NOT NULL DEFAULT 1 COMMENT '状态: 1=正常 2=禁用',
    `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_open_id` (`open_id`),
    UNIQUE KEY `uk_phone` (`phone`)
) COMMENT '用户表';

-- 用户详情表（接单人专属信息）
CREATE TABLE `user_profile` (
    `id`              BIGINT       NOT NULL AUTO_INCREMENT,
    `user_id`         BIGINT       NOT NULL COMMENT '用户ID',
    `real_name`       VARCHAR(32)  COMMENT '真实姓名',
    `bio`             VARCHAR(500) COMMENT '个人简介',
    `tech_stack`      JSON         COMMENT '技术栈列表 ["Java","Vue"]',
    `skill_tags`      JSON         COMMENT '技能标签ID列表',
    `price_min`       DECIMAL(10,2) COMMENT '接单最低价格',
    `price_max`       DECIMAL(10,2) COMMENT '接单最高价格',
    `prefer_types`    JSON         COMMENT '偏好任务类型 ["开发","设计"]',
    `rating`          DECIMAL(3,1) NOT NULL DEFAULT 5.0 COMMENT '评分',
    `order_count`     INT          NOT NULL DEFAULT 0 COMMENT '完成接单数',
    `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_id` (`user_id`)
) COMMENT '用户详情表';

-- 标签表
CREATE TABLE `tag` (
    `id`         BIGINT      NOT NULL AUTO_INCREMENT,
    `name`       VARCHAR(32) NOT NULL COMMENT '标签名',
    `category`   VARCHAR(32) COMMENT '分类: tech/type/other',
    `created_at` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_name` (`name`)
) COMMENT '标签表';

-- 任务表
CREATE TABLE `task` (
    `id`           BIGINT        NOT NULL AUTO_INCREMENT COMMENT '任务ID',
    `publisher_id` BIGINT        NOT NULL COMMENT '发布人ID',
    `title`        VARCHAR(128)  NOT NULL COMMENT '任务标题',
    `description`  TEXT          NOT NULL COMMENT '任务描述',
    `type`         VARCHAR(32)   NOT NULL COMMENT '任务类型: 开发/设计/测试/运营等',
    `budget_min`   DECIMAL(10,2) NOT NULL COMMENT '预算下限',
    `budget_max`   DECIMAL(10,2) NOT NULL COMMENT '预算上限',
    `deadline`     DATE          COMMENT '截止日期',
    `status`       TINYINT       NOT NULL DEFAULT 1 COMMENT '状态: 1=待审核 2=招募中 3=进行中 4=已完成 5=已下架',
    `worker_id`    BIGINT        COMMENT '接单人ID',
    `created_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_publisher_id` (`publisher_id`),
    KEY `idx_status` (`status`)
) COMMENT '任务表';

-- 任务标签关联表
CREATE TABLE `task_tag` (
    `task_id` BIGINT NOT NULL,
    `tag_id`  BIGINT NOT NULL,
    PRIMARY KEY (`task_id`, `tag_id`)
) COMMENT '任务标签关联表';

-- 接单申请表
CREATE TABLE `task_application` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT,
    `task_id`     BIGINT       NOT NULL COMMENT '任务ID',
    `applicant_id` BIGINT      NOT NULL COMMENT '申请人ID',
    `message`     VARCHAR(500) COMMENT '申请留言',
    `price`       DECIMAL(10,2) COMMENT '报价',
    `status`      TINYINT      NOT NULL DEFAULT 1 COMMENT '状态: 1=待处理 2=已接受 3=已拒绝',
    `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_task_applicant` (`task_id`, `applicant_id`),
    KEY `idx_applicant_id` (`applicant_id`)
) COMMENT '接单申请表';

-- 通知表
CREATE TABLE `notification` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT,
    `user_id`     BIGINT       NOT NULL COMMENT '接收人ID',
    `type`        VARCHAR(32)  NOT NULL COMMENT '类型: NEW_TASK/MATCH/APPLY_RESULT/TASK_UPDATE',
    `title`       VARCHAR(128) NOT NULL COMMENT '通知标题',
    `content`     VARCHAR(500) NOT NULL COMMENT '通知内容',
    `ref_id`      BIGINT       COMMENT '关联ID（任务ID等）',
    `is_read`     TINYINT      NOT NULL DEFAULT 0 COMMENT '是否已读: 0=未读 1=已读',
    `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_is_read` (`is_read`)
) COMMENT '通知表';

-- 初始化标签数据
INSERT INTO `tag` (`name`, `category`) VALUES
('Java', 'tech'), ('Python', 'tech'), ('Vue', 'tech'), ('React', 'tech'),
('Node.js', 'tech'), ('MySQL', 'tech'), ('Redis', 'tech'), ('Spring Boot', 'tech'),
('Android', 'tech'), ('iOS', 'tech'), ('小程序', 'tech'), ('UI设计', 'tech'),
('开发', 'type'), ('设计', 'type'), ('测试', 'type'), ('运营', 'type'), ('数据分析', 'type');
