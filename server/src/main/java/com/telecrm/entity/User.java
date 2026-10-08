package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 用户表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("user")
public class User extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    /** 手机号（登录账号） */
    private String phone;

    /** 密码哈希 */
    private String passwordHash;

    /** 昵称 */
    private String nickname;

    /** 头像URL */
    private String avatar;

    /** 状态：0正常 1禁用 */
    private Integer status;

    /** 当前所在团队ID */
    private Long currentTeamId;
}
