package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * VIP兑换码表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("vip_code")
public class VipCode extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    /** 兑换码 */
    private String code;

    private Long packageId;

    private Long teamId;

    /** 使用者 */
    private Long usedBy;

    /** 使用时间 */
    private LocalDateTime usedAt;

    /** 状态：0未使用 1已使用 */
    private Integer status;
}
