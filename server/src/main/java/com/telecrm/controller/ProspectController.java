package com.telecrm.controller;

import com.telecrm.common.PageResult;
import com.telecrm.common.Result;
import com.telecrm.entity.Prospect;
import com.telecrm.service.ProspectService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 拓客接口：大数据拓客 + 附近企业
 */
@RestController
@RequestMapping("/api/prospect")
public class ProspectController {

    @Resource
    private ProspectService prospectService;

    /** 大数据拓客：按行业/地区/规模/关键词筛选，分页 */
    @GetMapping("/search")
    public Result<PageResult<Prospect>> search(
            @RequestParam(required = false) String industry,
            @RequestParam(required = false) String region,
            @RequestParam(required = false) String scale,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") long current,
            @RequestParam(defaultValue = "20") long size) {
        return Result.success(prospectService.search(industry, region, scale, keyword, current, size));
    }

    /** 附近企业：按经纬度半径返回，按距离升序 */
    @GetMapping("/nearby")
    public Result<List<Prospect>> nearby(
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(defaultValue = "5") double radius) {
        return Result.success(prospectService.nearby(lat, lng, radius));
    }

    /** 筛选字典：行业/地区/规模 */
    @GetMapping("/dicts")
    public Result<Map<String, Object>> dicts() {
        return Result.success(prospectService.dicts());
    }
}
