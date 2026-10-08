package com.telecrm.dto;

import lombok.Data;

/**
 * 创建跟进/回访请求
 */
@Data
public class FollowUpDTO {
    private Long customerId;
    private String content;
    private String tag;
}
