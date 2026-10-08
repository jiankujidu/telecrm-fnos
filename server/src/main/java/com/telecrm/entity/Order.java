package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 订单表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("`order`")
public class Order extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long userId;

    private Long teamId;

    private Long packageId;

    /** 金额（分） */
    private Long amount;

    /** 状态：0待支付 1已支付 2已取消 */
    private Integer status;

    /** 支付时间 */
    private LocalDateTime payTime;
}
