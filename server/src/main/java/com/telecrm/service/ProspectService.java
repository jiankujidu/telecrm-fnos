package com.telecrm.service;

import com.telecrm.common.PageResult;
import com.telecrm.entity.Prospect;

import java.util.List;
import java.util.Map;

/**
 * 拓客服务：大数据拓客 + 附近企业（mock 数据源）
 */
public interface ProspectService {

    /** 大数据拓客：按行业/地区/规模/关键词筛选，分页 */
    PageResult<Prospect> search(String industry, String region, String scale, String keyword, long current, long size);

    /** 附近企业：按经纬度半径返回，按距离升序 */
    List<Prospect> nearby(double lat, double lng, double radiusKm);

    /** 筛选字典：行业/地区/规模 */
    Map<String, Object> dicts();
}
