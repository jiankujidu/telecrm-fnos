package com.telecrm.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 跟进/回访视图对象（附带客户名称与手机号）
 */
@Data
public class FollowUpVO {
    private Long id;
    private Long customerId;
    private String customerName;
    private String phone;
    private String content;
    private String tag;
    private LocalDateTime createdAt;
}
