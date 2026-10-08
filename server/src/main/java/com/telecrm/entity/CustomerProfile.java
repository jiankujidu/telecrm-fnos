package com.telecrm.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.telecrm.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 客户画像：打电话过程中整理出的客户详细信息，一个客户一条
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("customer_profile")
public class CustomerProfile extends BaseEntity {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long customerId;

    private Long teamId;

    /** 性别：男/女/未知 */
    private String gender;

    private Integer age;

    private String birthday;

    /** 行业 */
    private String industry;

    /** 职位 */
    private String position;

    private String wechat;

    private String email;

    /** 备用电话 */
    private String secondPhone;

    private String province;

    private String city;

    /** 意向等级 A/B/C/D */
    private String intentLevel;

    private String budget;

    /** 是否决策人 0否 1是 */
    private Integer isDecision;

    /** 来源渠道 */
    private String channel;

    /** 感兴趣产品 */
    private String productInterest;

    /** 客户痛点 */
    private String painPoint;

    /** 在用竞品 */
    private String competitor;

    /** 下次跟进时间 */
    private LocalDateTime nextFollowAt;

    /** 累计拨打次数 */
    private Integer callCount;

    /** 最近拨打时间 */
    private LocalDateTime lastCalledAt;

    /** 画像标签，逗号分隔 */
    private String profileTags;

    /** 画像小结 */
    private String summary;
}
