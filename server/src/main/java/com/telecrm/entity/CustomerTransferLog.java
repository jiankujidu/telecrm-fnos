package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 客户流转记录表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("customer_transfer_log")
public class CustomerTransferLog extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long customerId;

    private Long fromUserId;

    private Long toUserId;

    /** 类型：assign/transfer/abandon/delete */
    private String type;

    /** 备注 */
    private String remark;
}
