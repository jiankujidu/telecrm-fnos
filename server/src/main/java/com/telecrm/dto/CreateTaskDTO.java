package com.telecrm.dto;

import lombok.Data;

import java.util.List;

/**
 * 从联系人创建任务请求
 */
@Data
public class CreateTaskDTO {
    private String name;
    private String sourceType;
    private List<ContactInput> items;
}
