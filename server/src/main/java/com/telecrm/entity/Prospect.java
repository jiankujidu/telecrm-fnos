package com.telecrm.entity;

import lombok.Data;

/**
 * 拓客企业（外部数据源，非持久化）
 */
@Data
public class Prospect {
    private Long id;
    private String company;
    private String legalPerson;
    private String phone;
    private String province;
    private String city;
    private String address;
    private String industry;
    private String scale;
    private String registeredCapital;
    private String foundDate;
    private String businessScope;
    private Double lat;
    private Double lng;
    /** 距离（nearby 接口回填，单位 km） */
    private Double distance;
}
