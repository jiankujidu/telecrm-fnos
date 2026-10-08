package com.telecrm.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.telecrm.common.BusinessException;
import com.telecrm.dto.FollowUpVO;
import com.telecrm.entity.Customer;
import com.telecrm.entity.FollowUp;
import com.telecrm.mapper.CustomerMapper;
import com.telecrm.mapper.FollowUpMapper;
import com.telecrm.service.FollowUpService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class FollowUpServiceImpl extends ServiceImpl<FollowUpMapper, FollowUp> implements FollowUpService {

    @Resource
    private CustomerMapper customerMapper;

    @Override
    public FollowUp add(Long userId, Long customerId, String content, String tag) {
        if (customerId == null) throw new BusinessException("缺少客户信息，无法创建回访");
        FollowUp f = new FollowUp();
        f.setUserId(userId);
        f.setCustomerId(customerId);
        f.setContent(content);
        f.setTag(tag);
        save(f);
        return f;
    }

    @Override
    public List<FollowUpVO> listMine(Long userId) {
        List<FollowUp> list = list(new LambdaQueryWrapper<FollowUp>()
                .eq(FollowUp::getUserId, userId)
                .orderByDesc(FollowUp::getCreatedAt));
        return toVO(list);
    }

    @Override
    public List<FollowUpVO> listByCustomer(Long customerId) {
        List<FollowUp> list = list(new LambdaQueryWrapper<FollowUp>()
                .eq(FollowUp::getCustomerId, customerId)
                .orderByDesc(FollowUp::getCreatedAt));
        return toVO(list);
    }

    @Override
    public void remove(Long id, Long userId) {
        FollowUp f = getById(id);
        if (f == null) return;
        if (!userId.equals(f.getUserId())) throw new BusinessException("只能删除自己的回访记录");
        removeById(id);
    }

    private List<FollowUpVO> toVO(List<FollowUp> list) {
        List<FollowUpVO> res = new ArrayList<>();
        for (FollowUp f : list) {
            FollowUpVO v = new FollowUpVO();
            v.setId(f.getId());
            v.setCustomerId(f.getCustomerId());
            v.setContent(f.getContent());
            v.setTag(f.getTag());
            v.setCreatedAt(f.getCreatedAt());
            Customer c = f.getCustomerId() != null ? customerMapper.selectById(f.getCustomerId()) : null;
            v.setCustomerName(c == null ? "未知客户" : (c.getName() == null ? "" : c.getName()));
            v.setPhone(c == null ? "" : (c.getPhone() == null ? "" : c.getPhone()));
            res.add(v);
        }
        return res;
    }
}
