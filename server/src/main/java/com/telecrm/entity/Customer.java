package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 客户表（支持自定义字段JSON）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("customer")
public class Customer extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long teamId;

    /** 归属坐席ID（公海为null） */
    private Long ownerUserId;

    private String name;

    private String phone;

    private String company;

    private String address;

    private String remark;

    /** 自定义字段JSON */
    private String customFieldsJson;

    /** 来源：import/public_sea/nearby/bigdata */
    private String source;

    /** 状态：normal/follow_up/dead */
    private String status;

    /** 标签，逗号分隔 */
    private String tags;

    /** 是否置顶 0/1（电脑端/手机端均可置顶，列表优先展示） */
    private Integer pinned;

    /** 置顶时间，用于同级排序 */
    private LocalDateTime pinnedAt;
}
