package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 外呼任务明细表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("call_task_item")
public class CallTaskItem extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long taskId;

    /** 关联客户ID */
    private Long customerId;

    private String name;

    private String phone;

    private String company;

    private String address;

    private String remark;

    /** 状态：pending/called/invalid/no_answer/follow_up */
    private String status;

    /** 拨打结果：empty/connected/not_answered/add_customer */
    private String callResult;

    /** 拨打次数 */
    private Integer callCount;

    /** 最近拨打时间 */
    private LocalDateTime lastCallAt;
}
