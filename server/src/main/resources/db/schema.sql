-- 固定客户端字符集，避免中文被 latin1 误读导致乱码

-- 电销CRM 数据库结构（MySQL 5.7 / 8.0 通用）
-- 编码：utf8mb4


-- 用户表
CREATE TABLE IF NOT EXISTS `user` (
  `id`              BIGINT       NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `phone`           VARCHAR(20)  NOT NULL COMMENT '手机号(登录账号)',
  `password_hash`   VARCHAR(100) NOT NULL COMMENT '密码哈希',
  `nickname`        VARCHAR(50)  DEFAULT '' COMMENT '昵称',
  `avatar`          VARCHAR(255) DEFAULT '' COMMENT '头像URL',
  `status`          TINYINT      DEFAULT 0 COMMENT '0正常 1禁用',
  `current_team_id` BIGINT       DEFAULT NULL COMMENT '当前团队',
  `created_at`      DATETIME     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         TINYINT      DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 团队表
CREATE TABLE IF NOT EXISTS `team` (
  `id`          BIGINT      NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(50) NOT NULL COMMENT '团队名称',
  `owner_user_id` BIGINT    NOT NULL COMMENT '创建者',
  `invite_code` VARCHAR(20) DEFAULT '' COMMENT '邀请码',
  `max_seats`   INT         DEFAULT 50 COMMENT '坐席上限',
  `status`      TINYINT     DEFAULT 0 COMMENT '0正常 1禁用',
  `created_at`  DATETIME    DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`     TINYINT     DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_invite` (`invite_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='团队表';

-- 团队成员表
CREATE TABLE IF NOT EXISTS `team_member` (
  `id`        BIGINT   NOT NULL AUTO_INCREMENT,
  `team_id`   BIGINT   NOT NULL,
  `user_id`   BIGINT   NOT NULL,
  `role`      VARCHAR(20) NOT NULL DEFAULT 'member' COMMENT 'owner/admin/group_leader/member',
  `nickname`  VARCHAR(50) DEFAULT '' COMMENT '团队内昵称',
  `status`    TINYINT  DEFAULT 0 COMMENT '0正常 1退出',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`   TINYINT  DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_team_user` (`team_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='团队成员表';

-- 客户表
CREATE TABLE IF NOT EXISTS `customer` (
  `id`               BIGINT       NOT NULL AUTO_INCREMENT,
  `team_id`          BIGINT       NOT NULL,
  `owner_user_id`    BIGINT       DEFAULT NULL COMMENT '归属坐席(公海为null)',
  `name`             VARCHAR(50)  DEFAULT '' COMMENT '姓名',
  `phone`            VARCHAR(20)  NOT NULL COMMENT '电话',
  `company`          VARCHAR(100) DEFAULT '' COMMENT '公司',
  `address`          VARCHAR(255) DEFAULT '' COMMENT '地址',
  `remark`           VARCHAR(500) DEFAULT '' COMMENT '备注',
  `custom_fields_json` TEXT       COMMENT '自定义字段JSON',
  `source`           VARCHAR(20)  DEFAULT 'import' COMMENT 'import/public_sea/nearby/bigdata',
  `status`           VARCHAR(20)  DEFAULT 'normal' COMMENT 'normal/follow_up/dead',
  `tags`             VARCHAR(255) DEFAULT '' COMMENT '标签逗号分隔',
  `created_at`       DATETIME     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`          TINYINT      DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_team_owner` (`team_id`, `owner_user_id`),
  KEY `idx_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='客户表';

-- 客户画像表（打电话时整理客户信息用，一个客户一条画像）
CREATE TABLE IF NOT EXISTS `customer_profile` (
  `id`               BIGINT       NOT NULL AUTO_INCREMENT,
  `customer_id`      BIGINT       NOT NULL COMMENT '客户ID',
  `team_id`          BIGINT       NOT NULL COMMENT '团队ID',
  `gender`           VARCHAR(10)  DEFAULT '' COMMENT '性别 男/女/未知',
  `age`              INT          DEFAULT NULL COMMENT '年龄',
  `birthday`         VARCHAR(20)  DEFAULT '' COMMENT '生日',
  `industry`         VARCHAR(50)  DEFAULT '' COMMENT '行业',
  `position`         VARCHAR(50)  DEFAULT '' COMMENT '职位',
  `wechat`           VARCHAR(64)  DEFAULT '' COMMENT '微信号',
  `email`            VARCHAR(100) DEFAULT '' COMMENT '邮箱',
  `second_phone`     VARCHAR(20)  DEFAULT '' COMMENT '备用电话',
  `province`         VARCHAR(50)  DEFAULT '' COMMENT '省份',
  `city`             VARCHAR(50)  DEFAULT '' COMMENT '城市',
  `intent_level`     VARCHAR(20)  DEFAULT '' COMMENT '意向等级 A/B/C/D',
  `budget`           VARCHAR(50)  DEFAULT '' COMMENT '预算',
  `is_decision`      TINYINT      DEFAULT 0 COMMENT '是否决策人 0否 1是',
  `channel`          VARCHAR(50)  DEFAULT '' COMMENT '来源渠道',
  `product_interest` VARCHAR(255) DEFAULT '' COMMENT '感兴趣产品',
  `pain_point`       VARCHAR(500) DEFAULT '' COMMENT '客户痛点',
  `competitor`       VARCHAR(100) DEFAULT '' COMMENT '在用竞品',
  `next_follow_at`   DATETIME     DEFAULT NULL COMMENT '下次跟进时间',
  `call_count`       INT          DEFAULT 0 COMMENT '累计拨打次数',
  `last_called_at`   DATETIME     DEFAULT NULL COMMENT '最近拨打时间',
  `profile_tags`     VARCHAR(255) DEFAULT '' COMMENT '画像标签，逗号分隔',
  `summary`          TEXT         COMMENT '画像小结',
  `created_at`       DATETIME     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`          TINYINT      DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_customer` (`customer_id`),
  KEY `idx_team` (`team_id`),
  KEY `idx_intent` (`intent_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='客户画像表';

-- 客户跟进记录
CREATE TABLE IF NOT EXISTS `follow_up` (
  `id`         BIGINT   NOT NULL AUTO_INCREMENT,
  `customer_id` BIGINT  NOT NULL,
  `user_id`    BIGINT   NOT NULL,
  `content`    VARCHAR(1000) DEFAULT '' COMMENT '跟进内容',
  `tag`        VARCHAR(50) DEFAULT '' COMMENT '跟进标签',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`    TINYINT  DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_customer` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='客户跟进记录表';

-- 客户流转记录
CREATE TABLE IF NOT EXISTS `customer_transfer_log` (
  `id`          BIGINT   NOT NULL AUTO_INCREMENT,
  `customer_id` BIGINT   NOT NULL,
  `from_user_id` BIGINT  DEFAULT NULL,
  `to_user_id`  BIGINT   DEFAULT NULL,
  `type`        VARCHAR(20) NOT NULL COMMENT 'assign/transfer/abandon/delete',
  `remark`      VARCHAR(255) DEFAULT '' COMMENT '备注',
  `created_at`  DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`    TINYINT  DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_customer` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='客户流转记录表';

-- 外呼任务表
CREATE TABLE IF NOT EXISTS `call_task` (
  `id`           BIGINT   NOT NULL AUTO_INCREMENT,
  `team_id`      BIGINT   NOT NULL,
  `user_id`      BIGINT   NOT NULL,
  `name`         VARCHAR(100) NOT NULL COMMENT '任务名称',
  `source_type`  VARCHAR(20)  DEFAULT 'file' COMMENT 'file/bigdata/nearby/public_sea',
  `status`       VARCHAR(20)  DEFAULT 'pending' COMMENT 'pending/running/finished',
  `total_count`  INT      DEFAULT 0 COMMENT '总条数',
  `called_count` INT      DEFAULT 0 COMMENT '已拨打数',
  `valid_count`  INT      DEFAULT 0 COMMENT '有效客户数',
  `created_at`   DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`      TINYINT  DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_team_user` (`team_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='外呼任务表';

-- 外呼任务明细表
CREATE TABLE IF NOT EXISTS `call_task_item` (
  `id`            BIGINT   NOT NULL AUTO_INCREMENT,
  `task_id`       BIGINT   NOT NULL,
  `customer_id`   BIGINT   DEFAULT NULL,
  `name`          VARCHAR(50)  DEFAULT '' COMMENT '姓名',
  `phone`         VARCHAR(20)  NOT NULL COMMENT '电话',
  `company`       VARCHAR(100) DEFAULT '' COMMENT '公司',
  `address`       VARCHAR(255) DEFAULT '' COMMENT '地址',
  `remark`        VARCHAR(500) DEFAULT '' COMMENT '备注',
  `status`        VARCHAR(20)  DEFAULT 'pending' COMMENT 'pending/called/invalid/no_answer/follow_up',
  `call_result`   VARCHAR(20)  DEFAULT '' COMMENT 'empty/connected/not_answered/add_customer',
  `call_count`    INT      DEFAULT 0 COMMENT '拨打次数',
  `last_call_at`  DATETIME DEFAULT NULL COMMENT '最近拨打时间',
  `created_at`    DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`       TINYINT  DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='外呼任务明细表';

-- 通话记录表
CREATE TABLE IF NOT EXISTS `call_record` (
  `id`            BIGINT   NOT NULL AUTO_INCREMENT,
  `team_id`       BIGINT   DEFAULT NULL COMMENT '团队ID(团队级报表统计)',
  `task_item_id`  BIGINT   DEFAULT NULL,
  `user_id`       BIGINT   NOT NULL,
  `customer_id`   BIGINT   DEFAULT NULL,
  `phone`         VARCHAR(20) NOT NULL COMMENT '电话',
  `duration`      INT      DEFAULT 0 COMMENT '通话时长(秒)',
  `result`        VARCHAR(20) DEFAULT '' COMMENT 'empty/connected/not_answered/add_customer',
  `recording_url` VARCHAR(255) DEFAULT '' COMMENT '录音URL',
  `remark`        VARCHAR(500) DEFAULT '' COMMENT '备注',
  `tag`           VARCHAR(50) DEFAULT '' COMMENT '快捷备注标签',
  `called_at`     DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '拨打时间',
  `created_at`    DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`       TINYINT  DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_user` (`user_id`),
  KEY `idx_team` (`team_id`),
  KEY `idx_called_at` (`called_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='通话记录表';

-- 云端自动外呼任务（电脑端下发，手机端执行）
CREATE TABLE IF NOT EXISTS `dial_push_task` (
  `id`               BIGINT       NOT NULL AUTO_INCREMENT,
  `team_id`          BIGINT       NOT NULL,
  `user_id`          BIGINT       NOT NULL COMMENT '创建人（电脑端坐席）',
  `target_user_id`   BIGINT       DEFAULT NULL COMMENT '指定由哪台手机执行（null=任意空闲手机）',
  `name`             VARCHAR(100) DEFAULT '' COMMENT '任务名称',
  `scope`            VARCHAR(20)  DEFAULT 'mine' COMMENT '客户范围 mine/team/public',
  `keyword`          VARCHAR(100) DEFAULT '' COMMENT '创建时的筛选关键词',
  `start_customer_id` BIGINT      DEFAULT NULL COMMENT '从哪个客户开始拨打',
  `interval_seconds` INT          DEFAULT 15 COMMENT '两通之间间隔秒数（0=不等待）',
  `status`           VARCHAR(20)  DEFAULT 'pending' COMMENT 'pending/running/paused/finished/cancelled',
  `total_count`      INT          DEFAULT 0,
  `dialed_count`     INT          DEFAULT 0,
  `connected_count`  INT          DEFAULT 0,
  `current_item_id`  BIGINT       DEFAULT NULL COMMENT '当前正在拨打的明细ID',
  `last_dialed_at`   DATETIME     DEFAULT NULL COMMENT '上一通拨出时间（后端据此控制间隔）',
  `started_at`       DATETIME     DEFAULT NULL,
  `finished_at`      DATETIME     DEFAULT NULL,
  `created_at`       DATETIME     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`          TINYINT      DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_team` (`team_id`),
  KEY `idx_status` (`status`),
  KEY `idx_target` (`target_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='云端自动外呼任务表';

-- 云端自动外呼明细（按 seq 顺序拨打）
CREATE TABLE IF NOT EXISTS `dial_push_item` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT,
  `task_id`     BIGINT       NOT NULL,
  `seq`         INT          DEFAULT 0 COMMENT '拨打顺序',
  `customer_id` BIGINT       DEFAULT NULL,
  `name`        VARCHAR(50)  DEFAULT '',
  `phone`       VARCHAR(20)  NOT NULL COMMENT '拨打号码',
  `company`     VARCHAR(100) DEFAULT '',
  `status`      VARCHAR(20)  DEFAULT 'pending' COMMENT 'pending/dialing/dialed/skipped/failed',
  `result`      VARCHAR(20)  DEFAULT '' COMMENT 'connected/not_answered/empty/add_customer',
  `duration`    INT          DEFAULT 0 COMMENT '通话时长(秒)',
  `remark`      VARCHAR(500) DEFAULT '' COMMENT '标记备注',
  `executor_id` BIGINT       DEFAULT NULL COMMENT '执行的手机用户ID',
  `started_at`  DATETIME     DEFAULT NULL,
  `finished_at` DATETIME     DEFAULT NULL,
  `created_at`  DATETIME     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`     TINYINT      DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_id`),
  KEY `idx_task_status` (`task_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='云端自动外呼明细表';

-- 业务模板表
CREATE TABLE IF NOT EXISTS `business_template` (
  `id`          BIGINT   NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(50) NOT NULL COMMENT '模板名称',
  `industry`    VARCHAR(50) DEFAULT '' COMMENT '行业',
  `fields_json` TEXT COMMENT '字段JSON',
  `is_system`   TINYINT  DEFAULT 1 COMMENT '是否系统内置',
  `created_at`  DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`     TINYINT  DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='业务模板表';

-- 自定义字段表
CREATE TABLE IF NOT EXISTS `custom_field` (
  `id`        BIGINT   NOT NULL AUTO_INCREMENT,
  `team_id`   BIGINT   NOT NULL,
  `name`      VARCHAR(50) NOT NULL COMMENT '字段名称',
  `field_key` VARCHAR(50) NOT NULL COMMENT '字段key',
  `type`      VARCHAR(20) DEFAULT 'text' COMMENT 'text/number/select/date/textarea',
  `options`   TEXT COMMENT '选项JSON',
  `sort`      INT      DEFAULT 0 COMMENT '排序',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`   TINYINT  DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_team` (`team_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='自定义字段表';

-- 套餐产品表
CREATE TABLE IF NOT EXISTS `package` (
  `id`            BIGINT   NOT NULL AUTO_INCREMENT,
  `name`          VARCHAR(50) NOT NULL COMMENT '套餐名称',
  `type`          VARCHAR(20) DEFAULT 'vip' COMMENT 'vip/minutes',
  `price`         BIGINT   DEFAULT 0 COMMENT '价格(分)',
  `minutes`       BIGINT   DEFAULT 0 COMMENT '通话分钟',
  `duration_days` INT      DEFAULT 0 COMMENT '有效天数',
  `status`        TINYINT  DEFAULT 0 COMMENT '0上架 1下架',
  `created_at`    DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`       TINYINT  DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='套餐产品表';

-- 订单表
CREATE TABLE IF NOT EXISTS `order` (
  `id`         BIGINT   NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT   NOT NULL,
  `team_id`    BIGINT   DEFAULT NULL,
  `package_id` BIGINT   DEFAULT NULL,
  `amount`     BIGINT   DEFAULT 0 COMMENT '金额(分)',
  `status`     TINYINT  DEFAULT 0 COMMENT '0待支付 1已支付 2已取消',
  `pay_time`   DATETIME DEFAULT NULL COMMENT '支付时间',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`    TINYINT  DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单表';

-- VIP兑换码表
CREATE TABLE IF NOT EXISTS `vip_code` (
  `id`         BIGINT   NOT NULL AUTO_INCREMENT,
  `code`       VARCHAR(50) NOT NULL COMMENT '兑换码',
  `package_id` BIGINT   DEFAULT NULL,
  `team_id`    BIGINT   DEFAULT NULL,
  `used_by`    BIGINT   DEFAULT NULL COMMENT '使用者',
  `used_at`    DATETIME DEFAULT NULL COMMENT '使用时间',
  `status`     TINYINT  DEFAULT 0 COMMENT '0未使用 1已使用',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`    TINYINT  DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='VIP兑换码表';

-- v1.2.1 客户置顶：电脑端/手机端均可置顶，列表置顶优先排序
ALTER TABLE `customer` ADD COLUMN `pinned`     TINYINT  NOT NULL DEFAULT 0 COMMENT '是否置顶 0/1';
ALTER TABLE `customer` ADD COLUMN `pinned_at`  DATETIME DEFAULT NULL COMMENT '置顶时间（用于同级排序）';
