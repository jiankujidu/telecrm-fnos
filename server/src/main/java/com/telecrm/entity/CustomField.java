package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 自定义字段表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("custom_field")
public class CustomField extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long teamId;

    /** 字段名称 */
    private String name;

    /** 字段key */
    private String fieldKey;

    /** 类型：text/number/select/date/textarea */
    private String type;

    /** 选项JSON（select用） */
    private String options;

    /** 排序 */
    private Integer sort;
}
