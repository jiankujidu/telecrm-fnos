package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 外呼任务表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("call_task")
public class CallTask extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long teamId;

    private Long userId;

    /** 任务名称 */
    private String name;

    /** 来源类型：file/bigdata/nearby/public_sea */
    private String sourceType;

    /** 状态：pending/running/finished */
    private String status;

    /** 总条数 */
    private Integer totalCount;

    /** 已拨打数 */
    private Integer calledCount;

    /** 有效客户数 */
    private Integer validCount;
}
