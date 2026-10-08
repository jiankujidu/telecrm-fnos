-- 固定客户端字符集，避免中文被 latin1 误读导致乱码

-- 电销CRM 示例数据

-- 演示团队
INSERT INTO `team` (`id`, `name`, `owner_user_id`, `invite_code`, `max_seats`, `status`)
VALUES (10001, '演示销售团队', 20001, 'DXB2026', 50, 0)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 演示用户（密码：123456，BCrypt哈希）
INSERT INTO `user` (`id`, `phone`, `password_hash`, `nickname`, `status`, `current_team_id`)
VALUES
  (20001, '13800000001', '$2a$10$u1hrKWr5tCVRZJvAVnYfOu4y/tZ4GDr5.Zokqlu2o5k5P5Oo3AkOC', '团队主', 0, 10001),
  (20002, '13800000002', '$2a$10$u1hrKWr5tCVRZJvAVnYfOu4y/tZ4GDr5.Zokqlu2o5k5P5Oo3AkOC', '张三', 0, 10001),
  (20003, '13800000003', '$2a$10$u1hrKWr5tCVRZJvAVnYfOu4y/tZ4GDr5.Zokqlu2o5k5P5Oo3AkOC', '李四', 0, 10001)
ON DUPLICATE KEY UPDATE `nickname` = VALUES(`nickname`);

-- 团队成员
INSERT INTO `team_member` (`id`, `team_id`, `user_id`, `role`, `nickname`, `status`)
VALUES
  (30001, 10001, 20001, 'owner', '团队主', 0),
  (30002, 10001, 20002, 'member', '张三', 0),
  (30003, 10001, 20003, 'member', '李四', 0)
ON DUPLICATE KEY UPDATE `role` = VALUES(`role`);

-- 套餐产品（价格以分为单位）
INSERT INTO `package` (`id`, `name`, `type`, `price`, `minutes`, `duration_days`, `status`)
VALUES
  (40001, 'VIP月卡', 'vip', 9900, 0, 30, 0),
  (40002, '通话分钟包1000', 'minutes', 4900, 1000, 90, 0)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 系统内置业务模板示例（教育行业）
INSERT INTO `business_template` (`id`, `name`, `industry`, `fields_json`, `is_system`)
VALUES (50001, 'K12教育拉新', '教育', '[{"key":"grade","name":"年级","type":"select","options":["一年级","二年级","三年级"]},{"key":"intent","name":"意向度","type":"select","options":["高","中","低"]}]', 1)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 自定义字段示例
INSERT INTO `custom_field` (`id`, `team_id`, `name`, `field_key`, `type`, `options`, `sort`)
VALUES (60001, 10001, '意向产品', 'product', 'select', '["A套餐","B套餐","C套餐"]', 1)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 固定客户端字符集，避免中文被 latin1 误读导致乱码

-- 演示业务数据：客户 / 外呼任务 / 通话记录 / 跟进（可直接观察报表效果）

INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70001,10001,20001,'冯娟','13033533270','华瑞电子商务实业有限公司','上海市福田区创业大道176号','首次联系，待跟进','import','follow_up','同行','2026-09-17 22:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70002,10001,20002,'李小梅','16636799733','宏图教育培训信息技术有限公司','深圳市滨江区迎宾大道136号','首次联系，待跟进','import','normal','同行','2026-09-24 13:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70003,10001,20003,'陈磊','15709417425','鑫源餐饮管理智能科技有限公司','上海市高新区金园路109号','首次联系，待跟进','import','normal','老板本人','2026-09-17 15:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70004,10001,NULL,'朱娜','18872025034','众合建筑工程智能科技有限公司','北京市天河区创业大道108号','首次联系，待跟进','import','normal','已报价,观望中','2026-09-22 13:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70005,10001,20001,'张大海','17253134531','恒达医疗健康商贸有限公司','杭州市高新区人民南路98号','首次联系，待跟进','import','normal','','2026-09-29 20:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70006,10001,20002,'曾勇','15159639643','德盛餐饮管理实业有限公司','上海市福田区科技路37号','首次联系，待跟进','import','follow_up','已报价,意向高','2026-09-23 16:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70007,10001,20003,'吴霞','13460818785','正泰教育培训网络科技有限公司','北京市高新区工业一路30号','首次联系，待跟进','import','follow_up','需回访,观望中','2026-10-03 20:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70008,10001,NULL,'陈军','14471677852','正泰电子商务智能科技有限公司','北京市龙华区创业大道195号','首次联系，待跟进','import','follow_up','观望中','2026-10-07 20:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70009,10001,20001,'何洋','18119196334','宏图信息技术科技有限公司','杭州市龙岗区人民南路26号','首次联系，待跟进','import','normal','同行','2026-09-22 22:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70010,10001,20002,'冯霞','19840380460','聚信物流运输网络科技有限公司','东莞市天河区科技路42号','首次联系，待跟进','import','normal','需回访','2026-09-19 16:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70011,10001,20003,'唐军','17603426335','德盛教育培训科技有限公司','杭州市滨江区创业大道190号','首次联系，待跟进','import','follow_up','老板本人','2026-10-03 13:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70012,10001,NULL,'曾大海','14724245755','智联智能制造实业有限公司','上海市龙华区科技路16号','首次联系，待跟进','import','follow_up','同行,需回访','2026-10-05 19:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70013,10001,20001,'唐洋','15526921903','智联建筑工程信息技术有限公司','杭州市福田区工业一路106号','首次联系，待跟进','import','normal','','2026-09-24 18:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70014,10001,20002,'林娟','13543482447','正泰餐饮管理智能科技有限公司','北京市宝安区建设北路160号','首次联系，待跟进','import','normal','','2026-09-29 23:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70015,10001,20003,'王雅雯','14522256383','博远建筑工程科技有限公司','杭州市越秀区科技路47号','首次联系，待跟进','import','normal','','2026-09-20 00:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70016,10001,NULL,'张勇','16303411189','鑫源教育培训信息技术有限公司','深圳市滨江区建设北路122号','首次联系，待跟进','import','follow_up','','2026-10-07 19:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70017,10001,20001,'邓伟','15029043916','鼎峰医疗健康网络科技有限公司','上海市滨江区科技路171号','首次联系，待跟进','import','normal','同行','2026-09-30 18:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70018,10001,20002,'罗娟','19960571782','盛通电子商务实业有限公司','珠海市高新区工业一路80号','首次联系，待跟进','import','normal','观望中','2026-10-01 15:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70019,10001,20003,'韩雨欣','15670950209','华瑞文化传媒网络科技有限公司','北京市龙岗区科技路2号','首次联系，待跟进','import','dead','','2026-10-01 15:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70020,10001,NULL,'徐芳','18760749166','恒达物流运输智能科技有限公司','广州市南山区光华街99号','首次联系，待跟进','import','follow_up','观望中','2026-10-07 19:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70021,10001,20001,'宋小梅','16901511446','天成教育培训商贸有限公司','南京市天河区金园路12号','首次联系，待跟进','import','normal','','2026-09-19 15:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70022,10001,20002,'曾娜','15995376394','聚信信息技术商贸有限公司','深圳市滨江区迎宾大道96号','首次联系，待跟进','import','follow_up','观望中','2026-09-20 00:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70023,10001,20003,'朱超','18001552130','华瑞物流运输商贸有限公司','佛山市高新区创业大道130号','首次联系，待跟进','import','normal','观望中,已报价','2026-09-21 13:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70024,10001,NULL,'朱建国','18297215466','瑞祥建筑工程网络科技有限公司','杭州市宝安区光华街88号','首次联系，待跟进','import','follow_up','','2026-09-23 20:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70025,10001,20001,'周明','13839023934','云图建筑工程信息技术有限公司','上海市龙岗区人民南路180号','首次联系，待跟进','import','follow_up','观望中','2026-09-30 16:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70026,10001,20002,'韩洋','14699898422','瑞祥教育培训网络科技有限公司','上海市龙岗区光华街92号','首次联系，待跟进','import','dead','已报价','2026-09-20 23:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70027,10001,20003,'李超','18194888841','聚信智能制造科技有限公司','佛山市龙岗区工业一路154号','首次联系，待跟进','import','dead','老板本人,需回访','2026-10-07 14:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70028,10001,NULL,'周静','18527018752','云图教育培训实业有限公司','深圳市福田区建设北路176号','首次联系，待跟进','import','normal','需回访','2026-09-24 13:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70029,10001,20001,'徐强','16872713335','天成物流运输信息技术有限公司','杭州市天河区金园路152号','首次联系，待跟进','import','follow_up','老板本人,已报价','2026-09-18 19:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70030,10001,20002,'胡洋','14379641904','锦程教育培训科技有限公司','佛山市龙华区迎宾大道193号','首次联系，待跟进','import','normal','','2026-09-20 15:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70031,10001,20003,'梁大海','16460776401','博远教育培训智能科技有限公司','南京市龙华区迎宾大道40号','首次联系，待跟进','import','dead','同行,老板本人','2026-09-26 18:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70032,10001,NULL,'孙雅雯','19815101713','恒达建筑工程网络科技有限公司','佛山市龙岗区建设北路139号','首次联系，待跟进','import','dead','','2026-10-06 17:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70033,10001,20001,'朱霞','13997191710','智联餐饮管理商贸有限公司','佛山市宝安区迎宾大道179号','首次联系，待跟进','import','follow_up','需回访','2026-09-19 14:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70034,10001,20002,'朱静','14578370630','锦程医疗健康智能科技有限公司','珠海市越秀区创业大道43号','首次联系，待跟进','import','follow_up','意向高','2026-09-28 19:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70035,10001,20003,'何军','15241453038','天成电子商务信息技术有限公司','北京市南山区光华街147号','首次联系，待跟进','import','dead','','2026-09-30 23:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70036,10001,NULL,'许芳','15027085674','众合建筑工程智能科技有限公司','南京市福田区光华街165号','首次联系，待跟进','import','normal','','2026-09-30 13:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70037,10001,20001,'周磊','17369022690','博远金融服务智能科技有限公司','深圳市福田区金园路196号','首次联系，待跟进','import','normal','老板本人','2026-10-05 15:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70038,10001,20002,'周建国','14209907509','正泰金融服务网络科技有限公司','广州市滨江区科技路36号','首次联系，待跟进','import','normal','','2026-09-23 00:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70039,10001,20003,'林杰','13615669333','创想电子商务网络科技有限公司','佛山市龙华区金园路164号','首次联系，待跟进','import','normal','老板本人','2026-09-30 23:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70040,10001,NULL,'周志强','16111860908','华瑞文化传媒信息技术有限公司','上海市滨江区科技路139号','首次联系，待跟进','import','normal','观望中,已报价','2026-09-18 21:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70041,10001,20001,'曾雨欣','19593121834','聚信金融服务信息技术有限公司','佛山市宝安区人民南路69号','首次联系，待跟进','import','dead','','2026-10-06 00:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70042,10001,20002,'黄明','18924921245','创想智能制造信息技术有限公司','东莞市南山区人民南路125号','首次联系，待跟进','import','normal','观望中','2026-09-30 00:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70043,10001,20003,'何勇','14868839000','云图餐饮管理网络科技有限公司','北京市滨江区创业大道108号','首次联系，待跟进','import','follow_up','已报价,意向高','2026-09-28 23:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70044,10001,NULL,'孙涛','13329483244','宏图教育培训网络科技有限公司','珠海市龙华区创业大道124号','首次联系，待跟进','import','normal','已报价','2026-10-05 22:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70045,10001,20001,'许洋','14416328000','宏图餐饮管理实业有限公司','北京市南山区创业大道164号','首次联系，待跟进','import','normal','','2026-09-23 23:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70046,10001,20002,'周涛','19277342535','宏图建筑工程科技有限公司','上海市高新区金园路3号','首次联系，待跟进','import','normal','','2026-09-21 19:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70047,10001,20003,'谢艳','19484409704','德盛建筑工程实业有限公司','上海市天河区建设北路43号','首次联系，待跟进','import','follow_up','同行','2026-09-24 22:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70048,10001,NULL,'赵杰','19582068002','云图金融服务科技有限公司','南京市福田区科技路80号','首次联系，待跟进','import','normal','已报价,老板本人','2026-09-23 14:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70049,10001,20001,'吴建国','14760890232','众合信息技术信息技术有限公司','上海市龙岗区迎宾大道23号','首次联系，待跟进','import','follow_up','观望中','2026-09-17 12:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70050,10001,20002,'杨雨欣','18373790835','恒达电子商务信息技术有限公司','深圳市宝安区光华街24号','首次联系，待跟进','import','normal','老板本人,已报价','2026-09-21 17:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70051,10001,20003,'韩霞','19654714155','聚信文化传媒商贸有限公司','北京市福田区科技路5号','首次联系，待跟进','import','follow_up','意向高,同行','2026-09-18 12:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70052,10001,NULL,'刘丽','15657012102','正泰医疗健康科技有限公司','南京市南山区人民南路118号','首次联系，待跟进','import','follow_up','同行,意向高','2026-10-01 17:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70053,10001,20001,'孙思远','17002744297','恒达电子商务信息技术有限公司','东莞市龙华区创业大道192号','首次联系，待跟进','import','follow_up','观望中,老板本人','2026-09-25 20:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70054,10001,20002,'谢丽','16652948188','瑞祥医疗健康网络科技有限公司','深圳市龙岗区工业一路53号','首次联系，待跟进','import','normal','','2026-09-21 17:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70055,10001,20003,'郭霞','15661651145','宏图信息技术科技有限公司','南京市越秀区迎宾大道113号','首次联系，待跟进','import','normal','需回访,老板本人','2026-09-19 19:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70056,10001,NULL,'刘磊','14083148978','盛通物流运输商贸有限公司','佛山市越秀区迎宾大道126号','首次联系，待跟进','import','follow_up','','2026-10-04 20:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70057,10001,20001,'周志强','18792477781','智联物流运输科技有限公司','珠海市滨江区建设北路42号','首次联系，待跟进','import','normal','意向高,观望中','2026-09-24 00:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70058,10001,20002,'彭小梅','18517703076','鑫源物流运输实业有限公司','南京市福田区金园路119号','首次联系，待跟进','import','normal','老板本人','2026-10-07 21:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70059,10001,20003,'宋涛','17006364293','宏图医疗健康科技有限公司','上海市龙岗区科技路158号','首次联系，待跟进','import','follow_up','老板本人,已报价','2026-10-07 22:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `customer` (`id`,`team_id`,`owner_user_id`,`name`,`phone`,`company`,`address`,`remark`,`source`,`status`,`tags`,`created_at`)
VALUES (70060,10001,NULL,'陈芳','15320687116','锦程医疗健康信息技术有限公司','深圳市滨江区科技路81号','首次联系，待跟进','import','dead','意向高,已报价','2026-09-17 14:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);

INSERT INTO `call_task` (`id`,`team_id`,`user_id`,`name`,`source_type`,`status`,`total_count`,`called_count`,`valid_count`,`created_at`)
VALUES (80001,10001,20001,'10月企业名录外呼','file','running',40,26,7,'2026-10-06 00:00:00')
  ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90001,80001,'冯丽','16625941468','锦程智能制造实业有限公司','上海市龙华区迎宾大道96号','','no_answer','not_answered',3,'2026-10-07 23:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90002,80001,'李艳','14508424485','华瑞电子商务信息技术有限公司','广州市福田区建设北路99号','','called','connected',3,'2026-10-06 19:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90003,80001,'曾艳','15367809060','鼎峰文化传媒实业有限公司','东莞市福田区科技路91号','','called','connected',3,'2026-10-06 17:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90004,80001,'徐思远','15113829220','正泰电子商务网络科技有限公司','广州市龙华区金园路165号','','pending','',0,NULL)
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90005,80001,'徐丽','17646942872','众合医疗健康商贸有限公司','佛山市高新区光华街36号','','called','connected',3,'2026-10-07 22:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90006,80001,'邓丽','15098192131','正泰教育培训信息技术有限公司','东莞市龙岗区金园路153号','','called','connected',1,'2026-10-05 22:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90007,80001,'张大海','15807410545','创想智能制造实业有限公司','佛山市越秀区创业大道4号','','no_answer','not_answered',2,'2026-10-07 21:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90008,80001,'罗芳','16597682928','聚信教育培训智能科技有限公司','东莞市宝安区工业一路42号','','pending','',0,NULL)
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90009,80001,'林勇','13164421107','鑫源智能制造实业有限公司','珠海市宝安区光华街147号','','follow_up','add_customer',1,'2026-10-07 21:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90010,80001,'吴子豪','19573385036','创想智能制造网络科技有限公司','广州市天河区人民南路92号','','no_answer','not_answered',2,'2026-10-06 17:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90011,80001,'曾娟','13676626571','鑫源智能制造实业有限公司','东莞市滨江区人民南路101号','','called','connected',1,'2026-10-05 18:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90012,80001,'郑思远','16335229496','佳和物流运输商贸有限公司','上海市滨江区迎宾大道51号','','pending','',0,NULL)
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90013,80001,'邓雨欣','18831577370','华瑞医疗健康网络科技有限公司','深圳市龙岗区创业大道95号','','called','connected',2,'2026-10-07 22:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90014,80001,'王子豪','17255617408','华瑞文化传媒智能科技有限公司','深圳市高新区工业一路24号','','follow_up','add_customer',2,'2026-10-05 19:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90015,80001,'罗娟','18100502938','众合文化传媒实业有限公司','上海市高新区人民南路57号','','pending','',0,NULL)
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90016,80001,'许思远','19583168585','宏图文化传媒科技有限公司','佛山市龙岗区创业大道17号','','called','connected',3,'2026-10-05 21:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90017,80001,'许涛','19372492404','宏图物流运输信息技术有限公司','杭州市天河区人民南路36号','','pending','',0,NULL)
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90018,80001,'胡子豪','17048005037','德盛餐饮管理科技有限公司','佛山市龙岗区工业一路178号','','follow_up','add_customer',2,'2026-10-05 22:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90019,80001,'李雨欣','19146395015','恒达金融服务信息技术有限公司','杭州市龙岗区创业大道142号','','follow_up','add_customer',2,'2026-10-06 20:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90020,80001,'胡芳','14586977495','众合智能制造网络科技有限公司','上海市福田区建设北路130号','','called','connected',2,'2026-10-05 22:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90021,80001,'王磊','14411966132','鼎峰电子商务实业有限公司','上海市高新区建设北路62号','','called','connected',3,'2026-10-05 19:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90022,80001,'罗霞','16342861839','聚信智能制造实业有限公司','北京市福田区光华街157号','','pending','',0,NULL)
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90023,80001,'彭艳','18438917042','盛通文化传媒网络科技有限公司','广州市天河区工业一路109号','','follow_up','add_customer',2,'2026-10-07 23:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90024,80001,'谢娜','18075904621','德盛教育培训商贸有限公司','深圳市高新区工业一路93号','','follow_up','add_customer',1,'2026-10-05 16:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90025,80001,'李洋','18957477261','聚信文化传媒信息技术有限公司','南京市天河区建设北路12号','','no_answer','not_answered',2,'2026-10-05 19:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90026,80001,'林磊','19945953764','博远信息技术网络科技有限公司','佛山市越秀区创业大道94号','','pending','',0,NULL)
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90027,80001,'许芳','18394708578','众合智能制造信息技术有限公司','上海市高新区迎宾大道24号','','follow_up','add_customer',2,'2026-10-05 20:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90028,80001,'林子豪','18170437822','鼎峰物流运输实业有限公司','南京市福田区迎宾大道100号','','follow_up','add_customer',2,'2026-10-07 21:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90029,80001,'杨芳','13241020382','创想文化传媒商贸有限公司','北京市龙华区建设北路145号','','pending','',0,NULL)
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90030,80001,'陈雅雯','14399426302','众合金融服务智能科技有限公司','东莞市宝安区建设北路157号','','follow_up','add_customer',2,'2026-10-07 17:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90031,80001,'孙静','18283897519','创想金融服务实业有限公司','南京市龙岗区建设北路196号','','called','connected',3,'2026-10-07 22:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90032,80001,'唐子豪','17323380549','云图物流运输商贸有限公司','广州市天河区光华街84号','','follow_up','add_customer',3,'2026-10-06 20:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90033,80001,'孙思远','17093006346','正泰建筑工程信息技术有限公司','深圳市福田区金园路153号','','called','connected',3,'2026-10-07 15:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90034,80001,'高超','17960379687','宏图餐饮管理智能科技有限公司','南京市天河区创业大道138号','','follow_up','add_customer',3,'2026-10-05 18:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90035,80001,'曹大海','17004721783','正泰餐饮管理智能科技有限公司','广州市龙华区建设北路71号','','called','connected',1,'2026-10-07 20:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90036,80001,'曹雅雯','17524773443','创想餐饮管理信息技术有限公司','深圳市高新区工业一路58号','','pending','',0,NULL)
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90037,80001,'宋艳','15112929128','佳和建筑工程信息技术有限公司','上海市越秀区金园路83号','','follow_up','add_customer',3,'2026-10-07 17:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90038,80001,'李勇','18913936096','恒达物流运输实业有限公司','杭州市宝安区创业大道129号','','no_answer','not_answered',1,'2026-10-07 16:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90039,80001,'张涛','19611513058','锦程餐饮管理网络科技有限公司','广州市宝安区科技路18号','','called','connected',1,'2026-10-06 22:00:00')
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_task_item` (`id`,`task_id`,`name`,`phone`,`company`,`address`,`remark`,`status`,`call_result`,`call_count`,`last_call_at`)
VALUES (90040,80001,'唐雅雯','16153534771','云图文化传媒信息技术有限公司','珠海市高新区工业一路88号','','pending','',0,NULL)
  ON DUPLICATE KEY UPDATE `company` = VALUES(`company`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110001,10001,NULL,20003,70052,'15657012102',195,'connected','系统自动生成演示话单','意向高','2026-10-08 00:00:42')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110002,10001,90036,20002,70021,'16901511446',198,'connected','系统自动生成演示话单','意向高','2026-10-08 00:24:42')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110003,10001,90035,20001,70016,'16303411189',0,'not_answered','系统自动生成演示话单','','2026-10-08 00:18:42')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110004,10001,90018,20003,70017,'15029043916',282,'connected','系统自动生成演示话单','需回访','2026-10-08 00:24:42')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110005,10001,NULL,20003,70005,'17253134531',0,'not_answered','系统自动生成演示话单','','2026-10-08 00:18:42')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110006,10001,NULL,20002,70042,'18924921245',0,'empty','系统自动生成演示话单','无意向','2026-10-08 00:33:42')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110007,10001,NULL,20003,70051,'19654714155',120,'connected','系统自动生成演示话单','已报价','2026-10-07 23:57:42')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110008,10001,90040,20003,70001,'13033533270',0,'empty','系统自动生成演示话单','无意向','2026-10-08 00:11:42')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110009,10001,NULL,20003,70028,'18527018752',0,'not_answered','系统自动生成演示话单','','2026-10-08 00:11:42')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110010,10001,90015,20001,70006,'15159639643',195,'connected','系统自动生成演示话单','意向高','2026-10-08 00:00:42')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110011,10001,90037,20002,70052,'15657012102',183,'connected','系统自动生成演示话单','已报价','2026-10-08 00:02:42')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110012,10001,90018,20002,70004,'18872025034',119,'connected','系统自动生成演示话单','无意向','2026-10-08 00:27:42')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110013,10001,NULL,20001,70007,'13460818785',305,'add_customer','系统自动生成演示话单','意向高','2026-10-08 00:07:42')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110014,10001,NULL,20003,70003,'15709417425',0,'not_answered','系统自动生成演示话单','','2026-10-07 10:50:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110015,10001,NULL,20002,70020,'18760749166',31,'connected','系统自动生成演示话单','已报价','2026-10-07 10:21:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110016,10001,NULL,20002,70034,'14578370630',100,'connected','系统自动生成演示话单','需回访','2026-10-07 13:11:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110017,10001,NULL,20002,70028,'18527018752',162,'connected','系统自动生成演示话单','无意向','2026-10-07 17:27:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110018,10001,90005,20003,70023,'18001552130',276,'connected','系统自动生成演示话单','已报价','2026-10-07 15:38:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110019,10001,NULL,20003,70033,'13997191710',75,'add_customer','系统自动生成演示话单','意向高','2026-10-07 16:44:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110020,10001,NULL,20002,70020,'18760749166',278,'add_customer','系统自动生成演示话单','无意向','2026-10-07 19:39:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110021,10001,NULL,20003,70005,'17253134531',241,'add_customer','系统自动生成演示话单','无意向','2026-10-07 17:14:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110022,10001,90040,20002,70023,'18001552130',70,'connected','系统自动生成演示话单','已报价','2026-10-07 15:55:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110023,10001,NULL,20002,70059,'17006364293',224,'add_customer','系统自动生成演示话单','已报价','2026-10-07 17:17:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110024,10001,NULL,20001,70021,'16901511446',163,'connected','系统自动生成演示话单','无意向','2026-10-07 19:16:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110025,10001,90008,20003,70017,'15029043916',39,'connected','系统自动生成演示话单','已报价','2026-10-07 10:21:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110026,10001,NULL,20001,70016,'16303411189',251,'connected','系统自动生成演示话单','已报价','2026-10-07 15:03:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110027,10001,90009,20001,70049,'14760890232',162,'connected','系统自动生成演示话单','意向高','2026-10-07 12:16:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110028,10001,90032,20003,70040,'16111860908',26,'add_customer','系统自动生成演示话单','无意向','2026-10-07 18:59:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110029,10001,90013,20001,70043,'14868839000',166,'add_customer','系统自动生成演示话单','无意向','2026-10-07 18:15:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110030,10001,NULL,20003,70017,'15029043916',266,'connected','系统自动生成演示话单','已报价','2026-10-07 12:08:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110031,10001,90012,20001,70005,'17253134531',312,'connected','系统自动生成演示话单','需回访','2026-10-07 16:50:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110032,10001,NULL,20001,70001,'13033533270',87,'connected','系统自动生成演示话单','已报价','2026-10-07 15:05:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110033,10001,NULL,20003,70015,'14522256383',41,'connected','系统自动生成演示话单','无意向','2026-10-07 19:59:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110034,10001,NULL,20003,70049,'14760890232',164,'connected','系统自动生成演示话单','意向高','2026-10-07 15:17:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110035,10001,NULL,20003,70030,'14379641904',56,'add_customer','系统自动生成演示话单','需回访','2026-10-07 16:30:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110036,10001,90011,20003,70057,'18792477781',252,'connected','系统自动生成演示话单','需回访','2026-10-07 14:33:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110037,10001,NULL,20001,70050,'18373790835',0,'not_answered','系统自动生成演示话单','','2026-10-07 12:29:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110038,10001,NULL,20003,70034,'14578370630',0,'empty','系统自动生成演示话单','已报价','2026-10-06 19:29:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110039,10001,90034,20002,70009,'18119196334',0,'empty','系统自动生成演示话单','需回访','2026-10-06 14:55:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110040,10001,90030,20003,70049,'14760890232',0,'not_answered','系统自动生成演示话单','','2026-10-06 13:39:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110041,10001,NULL,20001,70013,'15526921903',84,'connected','系统自动生成演示话单','无意向','2026-10-06 19:31:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110042,10001,90035,20002,70005,'17253134531',119,'add_customer','系统自动生成演示话单','意向高','2026-10-06 16:44:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110043,10001,90010,20001,70056,'14083148978',239,'connected','系统自动生成演示话单','无意向','2026-10-06 10:02:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110044,10001,NULL,20002,70017,'15029043916',50,'connected','系统自动生成演示话单','无意向','2026-10-06 14:00:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110045,10001,NULL,20002,70030,'14379641904',0,'not_answered','系统自动生成演示话单','','2026-10-06 12:22:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110046,10001,NULL,20001,70054,'16652948188',191,'connected','系统自动生成演示话单','已报价','2026-10-06 12:12:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110047,10001,90026,20001,70025,'13839023934',91,'connected','系统自动生成演示话单','需回访','2026-10-06 10:00:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110048,10001,90030,20001,70042,'18924921245',0,'not_answered','系统自动生成演示话单','','2026-10-06 09:49:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110049,10001,NULL,20002,70011,'17603426335',87,'connected','系统自动生成演示话单','意向高','2026-10-06 17:26:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110050,10001,NULL,20002,70003,'15709417425',92,'add_customer','系统自动生成演示话单','无意向','2026-10-06 19:06:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110051,10001,NULL,20001,70014,'13543482447',0,'not_answered','系统自动生成演示话单','','2026-10-06 13:22:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110052,10001,NULL,20003,70006,'15159639643',163,'connected','系统自动生成演示话单','已报价','2026-10-06 10:40:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110053,10001,90002,20001,70033,'13997191710',0,'empty','系统自动生成演示话单','需回访','2026-10-06 13:21:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110054,10001,NULL,20001,70011,'17603426335',115,'connected','系统自动生成演示话单','无意向','2026-10-06 10:03:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110055,10001,NULL,20001,70039,'13615669333',132,'connected','系统自动生成演示话单','需回访','2026-10-06 18:07:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110056,10001,NULL,20003,70033,'13997191710',308,'connected','系统自动生成演示话单','需回访','2026-10-06 09:29:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110057,10001,90038,20001,70025,'13839023934',256,'connected','系统自动生成演示话单','需回访','2026-10-06 19:49:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110058,10001,NULL,20001,70011,'17603426335',223,'connected','系统自动生成演示话单','需回访','2026-10-06 16:22:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110059,10001,NULL,20002,70048,'19582068002',291,'connected','系统自动生成演示话单','已报价','2026-10-06 12:05:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110060,10001,90023,20003,70005,'17253134531',218,'connected','系统自动生成演示话单','意向高','2026-10-06 19:23:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110061,10001,90010,20001,70001,'13033533270',0,'not_answered','系统自动生成演示话单','','2026-10-06 18:22:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110062,10001,NULL,20002,70018,'19960571782',0,'empty','系统自动生成演示话单','无意向','2026-10-06 11:17:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110063,10001,NULL,20001,70022,'15995376394',79,'connected','系统自动生成演示话单','无意向','2026-10-05 09:50:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110064,10001,NULL,20002,70014,'13543482447',0,'empty','系统自动生成演示话单','意向高','2026-10-05 09:40:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110065,10001,NULL,20002,70027,'18194888841',204,'connected','系统自动生成演示话单','需回访','2026-10-05 17:24:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110066,10001,NULL,20002,70004,'18872025034',239,'connected','系统自动生成演示话单','已报价','2026-10-05 15:39:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110067,10001,NULL,20003,70015,'14522256383',112,'add_customer','系统自动生成演示话单','需回访','2026-10-05 17:30:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110068,10001,NULL,20003,70006,'15159639643',0,'not_answered','系统自动生成演示话单','','2026-10-05 14:03:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110069,10001,90028,20001,70016,'16303411189',0,'not_answered','系统自动生成演示话单','','2026-10-05 17:34:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110070,10001,90003,20003,70055,'15661651145',34,'connected','系统自动生成演示话单','已报价','2026-10-05 15:37:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110071,10001,NULL,20003,70002,'16636799733',184,'connected','系统自动生成演示话单','无意向','2026-10-05 12:35:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110072,10001,90018,20001,70047,'19484409704',134,'connected','系统自动生成演示话单','已报价','2026-10-05 09:16:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110073,10001,NULL,20001,70022,'15995376394',201,'connected','系统自动生成演示话单','意向高','2026-10-05 10:53:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110074,10001,NULL,20003,70028,'18527018752',203,'add_customer','系统自动生成演示话单','无意向','2026-10-05 11:08:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110075,10001,NULL,20003,70009,'18119196334',0,'empty','系统自动生成演示话单','无意向','2026-10-05 15:50:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110076,10001,NULL,20003,70022,'15995376394',0,'not_answered','系统自动生成演示话单','','2026-10-05 17:20:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110077,10001,NULL,20002,70018,'19960571782',42,'add_customer','系统自动生成演示话单','已报价','2026-10-04 18:03:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110078,10001,NULL,20003,70029,'16872713335',264,'connected','系统自动生成演示话单','无意向','2026-10-04 15:58:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110079,10001,NULL,20001,70045,'14416328000',49,'add_customer','系统自动生成演示话单','无意向','2026-10-04 19:51:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110080,10001,NULL,20001,70055,'15661651145',234,'add_customer','系统自动生成演示话单','意向高','2026-10-04 18:56:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110081,10001,NULL,20003,70043,'14868839000',0,'empty','系统自动生成演示话单','无意向','2026-10-04 15:18:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110082,10001,NULL,20001,70006,'15159639643',0,'not_answered','系统自动生成演示话单','','2026-10-04 15:56:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110083,10001,90007,20001,70036,'15027085674',44,'connected','系统自动生成演示话单','已报价','2026-10-04 15:58:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110084,10001,90037,20003,70060,'15320687116',241,'connected','系统自动生成演示话单','无意向','2026-10-04 19:52:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110085,10001,90011,20002,70020,'18760749166',220,'add_customer','系统自动生成演示话单','需回访','2026-10-04 16:07:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110086,10001,90038,20001,70056,'14083148978',131,'connected','系统自动生成演示话单','无意向','2026-10-04 13:35:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110087,10001,NULL,20001,70014,'13543482447',0,'not_answered','系统自动生成演示话单','','2026-10-04 18:44:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110088,10001,90018,20003,70032,'19815101713',0,'empty','系统自动生成演示话单','意向高','2026-10-04 11:25:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110089,10001,90017,20002,70012,'14724245755',177,'connected','系统自动生成演示话单','无意向','2026-10-04 19:09:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110090,10001,NULL,20002,70035,'15241453038',293,'add_customer','系统自动生成演示话单','无意向','2026-10-04 19:27:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110091,10001,NULL,20003,70048,'19582068002',243,'connected','系统自动生成演示话单','意向高','2026-10-03 16:36:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110092,10001,90034,20003,70010,'19840380460',0,'not_answered','系统自动生成演示话单','','2026-10-03 13:20:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110093,10001,90035,20003,70002,'16636799733',277,'add_customer','系统自动生成演示话单','意向高','2026-10-03 16:41:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110094,10001,90013,20003,70013,'15526921903',0,'not_answered','系统自动生成演示话单','','2026-10-03 12:53:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110095,10001,90020,20003,70024,'18297215466',220,'connected','系统自动生成演示话单','已报价','2026-10-03 17:16:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110096,10001,NULL,20002,70043,'14868839000',48,'connected','系统自动生成演示话单','已报价','2026-10-03 10:34:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110097,10001,NULL,20002,70047,'19484409704',204,'connected','系统自动生成演示话单','无意向','2026-10-03 13:50:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110098,10001,90023,20002,70007,'13460818785',147,'connected','系统自动生成演示话单','需回访','2026-10-03 11:26:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110099,10001,NULL,20003,70039,'13615669333',303,'connected','系统自动生成演示话单','无意向','2026-10-03 19:39:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110100,10001,90019,20001,70040,'16111860908',60,'connected','系统自动生成演示话单','无意向','2026-10-03 13:58:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110101,10001,90006,20002,70036,'15027085674',0,'not_answered','系统自动生成演示话单','','2026-10-03 13:31:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110102,10001,90031,20003,70013,'15526921903',0,'empty','系统自动生成演示话单','意向高','2026-10-03 19:00:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110103,10001,90011,20003,70056,'14083148978',302,'connected','系统自动生成演示话单','意向高','2026-10-03 19:45:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110104,10001,NULL,20002,70002,'16636799733',0,'empty','系统自动生成演示话单','意向高','2026-10-03 11:09:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110105,10001,NULL,20003,70008,'14471677852',201,'connected','系统自动生成演示话单','已报价','2026-10-03 09:20:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110106,10001,90016,20002,70056,'14083148978',177,'add_customer','系统自动生成演示话单','需回访','2026-10-03 14:07:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110107,10001,NULL,20002,70004,'18872025034',228,'connected','系统自动生成演示话单','已报价','2026-10-03 19:10:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110108,10001,90026,20002,70058,'18517703076',0,'not_answered','系统自动生成演示话单','','2026-10-03 09:34:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110109,10001,NULL,20003,70057,'18792477781',270,'add_customer','系统自动生成演示话单','已报价','2026-10-03 09:52:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110110,10001,90024,20002,70050,'18373790835',292,'connected','系统自动生成演示话单','意向高','2026-10-02 18:10:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110111,10001,90038,20003,70019,'15670950209',0,'not_answered','系统自动生成演示话单','','2026-10-02 17:23:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110112,10001,90019,20002,70007,'13460818785',0,'empty','系统自动生成演示话单','意向高','2026-10-02 12:59:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110113,10001,NULL,20001,70057,'18792477781',0,'empty','系统自动生成演示话单','需回访','2026-10-02 16:01:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110114,10001,NULL,20003,70033,'13997191710',0,'not_answered','系统自动生成演示话单','','2026-10-02 19:58:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110115,10001,NULL,20001,70046,'19277342535',0,'not_answered','系统自动生成演示话单','','2026-10-02 14:06:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110116,10001,90033,20001,70001,'13033533270',270,'connected','系统自动生成演示话单','无意向','2026-10-02 17:06:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110117,10001,NULL,20001,70007,'13460818785',78,'connected','系统自动生成演示话单','无意向','2026-10-02 15:55:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110118,10001,90008,20001,70030,'14379641904',0,'not_answered','系统自动生成演示话单','','2026-10-02 10:58:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110119,10001,NULL,20003,70020,'18760749166',0,'empty','系统自动生成演示话单','已报价','2026-10-02 15:55:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110120,10001,NULL,20002,70030,'14379641904',209,'connected','系统自动生成演示话单','无意向','2026-10-02 16:00:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110121,10001,NULL,20003,70014,'13543482447',0,'not_answered','系统自动生成演示话单','','2026-10-02 12:10:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110122,10001,90003,20002,70045,'14416328000',49,'connected','系统自动生成演示话单','已报价','2026-10-02 13:21:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110123,10001,NULL,20001,70002,'16636799733',0,'not_answered','系统自动生成演示话单','','2026-10-02 17:27:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110124,10001,NULL,20002,70016,'16303411189',138,'connected','系统自动生成演示话单','已报价','2026-10-02 12:53:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110125,10001,NULL,20002,70029,'16872713335',0,'empty','系统自动生成演示话单','意向高','2026-10-02 09:19:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `call_record` (`id`,`team_id`,`task_item_id`,`user_id`,`customer_id`,`phone`,`duration`,`result`,`remark`,`tag`,`called_at`)
VALUES (110126,10001,90001,20002,70039,'13615669333',0,'empty','系统自动生成演示话单','需回访','2026-10-02 19:30:00')
  ON DUPLICATE KEY UPDATE `duration` = VALUES(`duration`);
INSERT INTO `follow_up` (`id`,`customer_id`,`user_id`,`content`,`tag`,`created_at`)
VALUES (120001,70021,20001,'客户对套餐有兴趣，下周再联系','普通','2026-10-05 18:00:00')
  ON DUPLICATE KEY UPDATE `content` = VALUES(`content`);
INSERT INTO `follow_up` (`id`,`customer_id`,`user_id`,`content`,`tag`,`created_at`)
VALUES (120002,70031,20003,'已发报价单，等待回复','普通','2026-09-29 20:00:00')
  ON DUPLICATE KEY UPDATE `content` = VALUES(`content`);
INSERT INTO `follow_up` (`id`,`customer_id`,`user_id`,`content`,`tag`,`created_at`)
VALUES (120003,70023,20003,'意向一般，先放入长期跟进','观望','2026-10-01 21:00:00')
  ON DUPLICATE KEY UPDATE `content` = VALUES(`content`);
INSERT INTO `follow_up` (`id`,`customer_id`,`user_id`,`content`,`tag`,`created_at`)
VALUES (120004,70031,20003,'意向一般，先放入长期跟进','重点','2026-09-28 19:00:00')
  ON DUPLICATE KEY UPDATE `content` = VALUES(`content`);
INSERT INTO `follow_up` (`id`,`customer_id`,`user_id`,`content`,`tag`,`created_at`)
VALUES (120005,70050,20002,'约了下周三上门拜访','普通','2026-10-01 16:00:00')
  ON DUPLICATE KEY UPDATE `content` = VALUES(`content`);
INSERT INTO `follow_up` (`id`,`customer_id`,`user_id`,`content`,`tag`,`created_at`)
VALUES (120006,70033,20001,'电话未接，短信已发送','重点','2026-09-29 15:00:00')
  ON DUPLICATE KEY UPDATE `content` = VALUES(`content`);
INSERT INTO `follow_up` (`id`,`customer_id`,`user_id`,`content`,`tag`,`created_at`)
VALUES (120007,70057,20001,'意向一般，先放入长期跟进','普通','2026-09-29 19:00:00')
  ON DUPLICATE KEY UPDATE `content` = VALUES(`content`);
INSERT INTO `follow_up` (`id`,`customer_id`,`user_id`,`content`,`tag`,`created_at`)
VALUES (120008,70002,20002,'意向一般，先放入长期跟进','重点','2026-10-07 23:00:00')
  ON DUPLICATE KEY UPDATE `content` = VALUES(`content`);
INSERT INTO `follow_up` (`id`,`customer_id`,`user_id`,`content`,`tag`,`created_at`)
VALUES (120009,70015,20003,'约了下周三上门拜访','观望','2026-10-04 21:00:00')
  ON DUPLICATE KEY UPDATE `content` = VALUES(`content`);
INSERT INTO `follow_up` (`id`,`customer_id`,`user_id`,`content`,`tag`,`created_at`)
VALUES (120010,70042,20002,'已发报价单，等待回复','观望','2026-10-05 16:00:00')
  ON DUPLICATE KEY UPDATE `content` = VALUES(`content`);

