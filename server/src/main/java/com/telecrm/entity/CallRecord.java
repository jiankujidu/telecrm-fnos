package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 通话记录表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("call_record")
public class CallRecord extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long teamId;

    private Long taskItemId;

    private Long userId;

    private Long customerId;

    private String phone;

    /** 通话时长（秒） */
    private Integer duration;

    /** 结果：empty/connected/not_answered/add_customer */
    private String result;

    /** 录音URL */
    private String recordingUrl;

    /** 备注 */
    private String remark;

    /** 快捷备注标签 */
    private String tag;

    /** 拨打时间 */
    private LocalDateTime calledAt;
}
