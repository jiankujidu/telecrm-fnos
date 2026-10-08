package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 客户跟进记录表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("follow_up")
public class FollowUp extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long customerId;

    private Long userId;

    /** 跟进内容 */
    private String content;

    /** 跟进标签 */
    private String tag;
}
