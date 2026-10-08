package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 业务模板表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("business_template")
public class BusinessTemplate extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    /** 模板名称 */
    private String name;

    /** 行业 */
    private String industry;

    /** 字段JSON */
    private String fieldsJson;

    /** 是否系统内置 */
    private Integer isSystem;
}
