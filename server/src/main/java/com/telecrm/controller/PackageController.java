package com.telecrm.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.telecrm.common.Result;
import com.telecrm.entity.Package;
import com.telecrm.mapper.PackageMapper;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 套餐产品管理（后台 CRUD）
 */
@RestController
@RequestMapping("/api/package")
public class PackageController {

    @Resource
    private PackageMapper packageMapper;

    @GetMapping("/list")
    public Result<List<Package>> list(@RequestParam(required = false) Integer status) {
        LambdaQueryWrapper<Package> w = new LambdaQueryWrapper<>();
        if (status != null) w.eq(Package::getStatus, status);
        w.orderByDesc(Package::getId);
        return Result.success(packageMapper.selectList(w));
    }

    @PostMapping
    public Result<Void> add(@RequestBody Package p) {
        packageMapper.insert(p);
        return Result.success();
    }

    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @RequestBody Package p) {
        p.setId(id);
        packageMapper.updateById(p);
        return Result.success();
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        packageMapper.deleteById(id);
        return Result.success();
    }
}
