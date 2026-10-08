package com.telecrm.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.telecrm.common.PageResult;
import com.telecrm.common.Result;
import com.telecrm.common.UserContext;
import com.telecrm.entity.VipCode;
import com.telecrm.mapper.VipCodeMapper;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * VIP 兑换码管理：批量生成、列表、作废
 */
@RestController
@RequestMapping("/api/vip-code")
public class VipCodeController {

    @Resource
    private VipCodeMapper vipCodeMapper;

    private static final String CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private final Random random = new Random();

    @GetMapping("/list")
    public Result<PageResult<VipCode>> list(
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") long current,
            @RequestParam(defaultValue = "20") long size) {
        LambdaQueryWrapper<VipCode> w = new LambdaQueryWrapper<>();
        if (status != null) w.eq(VipCode::getStatus, status);
        w.orderByDesc(VipCode::getId);
        Page<VipCode> page = new Page<>(current, size);
        Page<VipCode> res = vipCodeMapper.selectPage(page, w);
        return Result.success(new PageResult<>(
                res.getRecords(), res.getTotal(), res.getSize(), res.getCurrent()));
    }

    /** 按套餐批量生成兑换码 */
    @PostMapping("/generate")
    public Result<Integer> generate(@RequestBody GenerateDTO dto) {
        int count = dto.getCount() == null ? 1 : Math.min(dto.getCount(), 500);
        List<VipCode> codes = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            VipCode c = new VipCode();
            c.setCode(genCode());
            c.setPackageId(dto.getPackageId());
            c.setTeamId(UserContext.getTeamId());
            c.setStatus(0);
            codes.add(c);
        }
        vipCodeMapper.insert(codes);
        return Result.success(codes.size());
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        vipCodeMapper.deleteById(id);
        return Result.success();
    }

    /** 兑换（客户端可使用，当前用户兑换） */
    @PostMapping("/redeem")
    public Result<Void> redeem(@RequestBody java.util.Map<String, String> body) {
        String code = body.get("code");
        VipCode c = vipCodeMapper.selectOne(new LambdaQueryWrapper<VipCode>().eq(VipCode::getCode, code));
        if (c == null) throw new com.telecrm.common.BusinessException("兑换码不存在");
        if (c.getStatus() != null && c.getStatus() == 1) {
            throw new com.telecrm.common.BusinessException("兑换码已使用");
        }
        c.setStatus(1);
        c.setUsedBy(UserContext.getUserId());
        c.setUsedAt(LocalDateTime.now());
        vipCodeMapper.updateById(c);
        return Result.success();
    }

    private String genCode() {
        StringBuilder sb = new StringBuilder("VIP");
        for (int i = 0; i < 10; i++) {
            sb.append(CHARS.charAt(random.nextInt(CHARS.length())));
        }
        return sb.toString();
    }

    public static class GenerateDTO {
        private Long packageId;
        private Integer count;

        public Long getPackageId() { return packageId; }
        public void setPackageId(Long packageId) { this.packageId = packageId; }
        public Integer getCount() { return count; }
        public void setCount(Integer count) { this.count = count; }
    }
}
