package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 团队表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("team")
public class Team extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    /** 团队名称 */
    private String name;

    /** 创建者用户ID */
    private Long ownerUserId;

    /** 邀请码 */
    private String inviteCode;

    /** 坐席上限 */
    private Integer maxSeats;

    /** 状态：0正常 1禁用 */
    private Integer status;
}
