package com.telecrm.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.telecrm.common.BusinessException;
import com.telecrm.common.PageResult;
import com.telecrm.common.Result;
import com.telecrm.common.UserContext;
import com.telecrm.entity.Order;
import com.telecrm.entity.Package;
import com.telecrm.mapper.OrderMapper;
import com.telecrm.mapper.PackageMapper;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;

/**
 * 订单管理：列表 / 详情 / 创建 / 模拟支付
 */
@RestController
@RequestMapping("/api/order")
public class OrderController {

    @Resource
    private OrderMapper orderMapper;
    @Resource
    private PackageMapper packageMapper;

    @GetMapping("/list")
    public Result<PageResult<Order>> list(
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") long current,
            @RequestParam(defaultValue = "20") long size) {
        LambdaQueryWrapper<Order> w = new LambdaQueryWrapper<>();
        if (status != null) w.eq(Order::getStatus, status);
        w.orderByDesc(Order::getId);
        Page<Order> page = new Page<>(current, size);
        Page<Order> res = orderMapper.selectPage(page, w);
        return Result.success(new PageResult<>(
                res.getRecords(), res.getTotal(), res.getSize(), res.getCurrent()));
    }

    @GetMapping("/{id}")
    public Result<Order> detail(@PathVariable Long id) {
        return Result.success(orderMapper.selectById(id));
    }

    /** 创建订单（当前用户购买某套餐） */
    @PostMapping
    public Result<Long> create(@RequestBody java.util.Map<String, Long> body) {
        Long packageId = body.get("packageId");
        Package p = packageMapper.selectById(packageId);
        if (p == null) throw new BusinessException("套餐不存在");
        Order o = new Order();
        o.setUserId(UserContext.getUserId());
        o.setTeamId(UserContext.getTeamId());
        o.setPackageId(p.getId());
        o.setAmount(p.getPrice());
        o.setStatus(0);
        orderMapper.insert(o);
        return Result.success(o.getId());
    }

    /** 模拟支付成功 */
    @PostMapping("/{id}/pay")
    public Result<Void> pay(@PathVariable Long id) {
        Order o = orderMapper.selectById(id);
        if (o == null) throw new BusinessException("订单不存在");
        o.setStatus(1);
        o.setPayTime(LocalDateTime.now());
        orderMapper.updateById(o);
        return Result.success();
    }
}
