package com.telecrm.dto;

import lombok.Data;

/**
 * 联系人输入（从拓客/附近企业创建拨打任务）
 */
@Data
public class ContactInput {
    private String company;
    private String name;
    private String phone;
    private String address;
    private String remark;
}
