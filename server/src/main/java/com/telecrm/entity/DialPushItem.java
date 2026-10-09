package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 云端自动外呼明细：按 seq 顺序逐条拨打
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("dial_push_item")
public class DialPushItem extends BaseEntity {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long taskId;

    /** 拨打顺序 */
    private Integer seq;

    private Long customerId;

    private String name;

    private String phone;

    private String company;

    /** pending/dialing/dialed/skipped/failed */
    private String status;

    /** connected/not_answered/empty/add_customer */
    private String result;

    private Integer duration;

    private String remark;

    /** 实际执行的手机用户 */
    private Long executorId;

    private LocalDateTime startedAt;

    private LocalDateTime finishedAt;
}
