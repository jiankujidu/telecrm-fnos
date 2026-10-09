package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 云端自动外呼任务：电脑端创建并下发，手机端轮询取号执行
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("dial_push_task")
public class DialPushTask extends BaseEntity {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long teamId;

    /** 创建人（电脑端坐席） */
    private Long userId;

    /** 指定由哪台手机执行（null = 任意空闲手机） */
    private Long targetUserId;

    private String name;

    /** 客户范围 mine/team/public */
    private String scope;

    private String keyword;

    /** 从哪个客户开始拨打 */
    private Long startCustomerId;

    /** 两通之间间隔秒数 */
    private Integer intervalSeconds;

    /** pending/running/paused/finished/cancelled */
    private String status;

    private Integer totalCount;

    private Integer dialedCount;

    private Integer connectedCount;

    private Long currentItemId;

    /** 上一通拨出时间，后端据此控制间隔 */
    private LocalDateTime lastDialedAt;

    private LocalDateTime startedAt;

    private LocalDateTime finishedAt;
}
