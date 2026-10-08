package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 套餐产品表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("`package`")
public class Package extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    /** 套餐名称 */
    private String name;

    /** 类型：vip/minutes */
    private String type;

    /** 价格（分） */
    private Long price;

    /** 通话分钟 */
    private Long minutes;

    /** 有效天数 */
    private Integer durationDays;

    /** 状态：0上架 1下架 */
    private Integer status;
}
