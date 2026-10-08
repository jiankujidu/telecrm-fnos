package com.telecrm.dto;

import lombok.Data;

import java.io.Serializable;

/**
 * 通话记录提交参数
 */
@Data
public class CallRecordDTO implements Serializable {
    /** 关联任务明细ID */
    private Long taskItemId;
    /** 关联客户ID */
    private Long customerId;
    /** 号码 */
    private String phone;
    /** 通话时长(秒) */
    private Integer duration;
    /** 结果：empty/connected/not_answered/add_customer */
    private String result;
    /** 备注 */
    private String remark;
    /** 快捷备注标签 */
    private String tag;
}
