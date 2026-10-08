package com.telecrm.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.telecrm.common.BusinessException;
import com.telecrm.common.UserContext;
import com.telecrm.entity.Customer;
import com.telecrm.entity.CustomerProfile;
import com.telecrm.entity.CustomerTransferLog;
import com.telecrm.mapper.CustomerMapper;
import com.telecrm.mapper.CustomerProfileMapper;
import com.telecrm.mapper.CustomerTransferLogMapper;
import com.telecrm.service.CustomerService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.annotation.Resource;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 客户服务实现：列表 / 增删改 / 流转 / 画像
 */
@Service
public class CustomerServiceImpl extends ServiceImpl<CustomerMapper, Customer> implements CustomerService {

    @Resource
    private CustomerTransferLogMapper transferLogMapper;

    @Resource
    private CustomerProfileMapper profileMapper;

    @Override
    public IPage<Customer> pageList(String scope, Long teamId, Long userId,
                                    String keyword, long current, long size) {
        LambdaQueryWrapper<Customer> w = new LambdaQueryWrapper<>();
        w.eq(Customer::getTeamId, teamId);
        if ("mine".equals(scope)) {
            w.eq(Customer::getOwnerUserId, userId);
        } else if ("team".equals(scope)) {
            w.isNotNull(Customer::getOwnerUserId);
        } else { // public 公海
            w.isNull(Customer::getOwnerUserId);
        }
        if (keyword != null && !keyword.isBlank()) {
            w.and(q -> q.like(Customer::getName, keyword).or().like(Customer::getPhone, keyword));
        }
        w.orderByDesc(Customer::getCreatedAt);
        return page(new Page<>(current, size), w);
    }

    // ---------- 新增 / 编辑 / 删除 ----------

    @Override
    public Customer create(Customer customer) {
        if (customer == null) throw new BusinessException("客户信息不能为空");
        String phone = trim(customer.getPhone());
        if (phone.isEmpty()) throw new BusinessException("手机号不能为空");
        customer.setPhone(phone);
        if (customer.getTeamId() == null) customer.setTeamId(UserContext.getTeamId());
        if (customer.getOwnerUserId() == null) customer.setOwnerUserId(UserContext.getUserId());
        if (customer.getStatus() == null || customer.getStatus().isBlank()) customer.setStatus("normal");
        if (customer.getSource() == null || customer.getSource().isBlank()) customer.setSource("manual");
        if (customer.getName() == null) customer.setName("");
        if (customer.getCompany() == null) customer.setCompany("");
        if (customer.getAddress() == null) customer.setAddress("");
        if (customer.getRemark() == null) customer.setRemark("");
        if (customer.getTags() == null) customer.setTags("");

        Long dup = existsPhone(customer.getTeamId(), phone, null);
        if (dup != null) throw new BusinessException("该手机号已存在（客户ID " + dup + "）");

        save(customer);
        writeLog(customer.getId(), null, customer.getOwnerUserId(), "create", "新建客户");
        // 顺带建一条空画像，保证画像页永远可编辑
        getProfile(customer.getId());
        return customer;
    }

    @Override
    public Customer updateCustomer(Long id, Customer patch) {
        if (id == null) throw new BusinessException("客户ID不能为空");
        Customer c = getById(id);
        if (c == null) throw new BusinessException("客户不存在");
        if (patch == null) return c;

        if (patch.getName() != null) c.setName(patch.getName());
        if (patch.getPhone() != null) {
            String p = trim(patch.getPhone());
            if (p.isEmpty()) throw new BusinessException("手机号不能为空");
            Long dup = existsPhone(c.getTeamId(), p, id);
            if (dup != null) throw new BusinessException("该手机号已被其他客户使用");
            c.setPhone(p);
        }
        if (patch.getCompany() != null) c.setCompany(patch.getCompany());
        if (patch.getAddress() != null) c.setAddress(patch.getAddress());
        if (patch.getRemark() != null) c.setRemark(patch.getRemark());
        if (patch.getTags() != null) c.setTags(patch.getTags());
        if (patch.getStatus() != null) c.setStatus(patch.getStatus());
        if (patch.getSource() != null) c.setSource(patch.getSource());
        if (patch.getOwnerUserId() != null) c.setOwnerUserId(patch.getOwnerUserId());
        if (patch.getCustomFieldsJson() != null) c.setCustomFieldsJson(patch.getCustomFieldsJson());

        updateById(c);
        return c;
    }

    @Override
    public void deleteCustomer(Long id) {
        Customer c = getById(id);
        if (c == null) throw new BusinessException("客户不存在");
        removeById(id);
        // 画像一并逻辑删除
        LambdaQueryWrapper<CustomerProfile> pw = new LambdaQueryWrapper<>();
        pw.eq(CustomerProfile::getCustomerId, id);
        profileMapper.delete(pw);
        writeLog(id, c.getOwnerUserId(), null, "delete", "删除客户");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public int batchDelete(List<Long> ids) {
        if (ids == null || ids.isEmpty()) return 0;
        int n = 0;
        for (Long id : ids) {
            if (id == null) continue;
            if (getById(id) == null) continue;
            deleteCustomer(id);
            n++;
        }
        return n;
    }

    /** 同团队内手机号是否已存在（excludeId 用于更新时排除自身） */
    private Long existsPhone(Long teamId, String phone, Long excludeId) {
        LambdaQueryWrapper<Customer> w = new LambdaQueryWrapper<>();
        w.eq(Customer::getTeamId, teamId).eq(Customer::getPhone, phone);
        if (excludeId != null) w.ne(Customer::getId, excludeId);
        Customer one = getOne(w, false);
        return one == null ? null : one.getId();
    }

    @Override
    public void transfer(Long customerId, Long toUserId, Long operatorId) {
        Customer c = getById(customerId);
        if (c == null) throw new BusinessException("客户不存在");
        Long from = c.getOwnerUserId();
        c.setOwnerUserId(toUserId);
        updateById(c);
        writeLog(customerId, from, toUserId, "transfer", "转让");
    }

    @Override
    public void assign(Long customerId, Long toUserId, Long operatorId) {
        Customer c = getById(customerId);
        if (c == null) throw new BusinessException("客户不存在");
        Long from = c.getOwnerUserId();
        c.setOwnerUserId(toUserId);
        updateById(c);
        writeLog(customerId, from, toUserId, "assign", "分配");
    }

    @Override
    public void abandon(Long customerId, Long operatorId) {
        Customer c = getById(customerId);
        if (c == null) throw new BusinessException("客户不存在");
        Long from = c.getOwnerUserId();
        c.setOwnerUserId(null); // 回公海
        updateById(c);
        writeLog(customerId, from, null, "abandon", "放弃回公海");
    }

    // ---------- 客户画像 ----------

    @Override
    public CustomerProfile getProfile(Long customerId) {
        if (customerId == null) throw new BusinessException("客户ID不能为空");
        LambdaQueryWrapper<CustomerProfile> w = new LambdaQueryWrapper<>();
        w.eq(CustomerProfile::getCustomerId, customerId).last("LIMIT 1");
        CustomerProfile p = profileMapper.selectOne(w);
        if (p != null) return p;

        Customer c = getById(customerId);
        if (c == null) throw new BusinessException("客户不存在");

        // 首次访问自动建空画像
        p = new CustomerProfile();
        p.setCustomerId(customerId);
        p.setTeamId(c.getTeamId());
        p.setGender("");
        p.setBirthday("");
        p.setIndustry("");
        p.setPosition("");
        p.setWechat("");
        p.setEmail("");
        p.setSecondPhone("");
        p.setProvince("");
        p.setCity("");
        p.setIntentLevel("");
        p.setBudget("");
        p.setIsDecision(0);
        p.setChannel("");
        p.setProductInterest("");
        p.setPainPoint("");
        p.setCompetitor("");
        p.setProfileTags("");
        p.setSummary("");
        p.setCallCount(0);
        profileMapper.insert(p);
        return p;
    }

    @Override
    public CustomerProfile saveProfile(Long customerId, CustomerProfile profile) {
        Customer c = getById(customerId);
        if (c == null) throw new BusinessException("客户不存在");

        CustomerProfile p = getProfile(customerId);
        // 只允许覆盖业务字段，count/时间由系统维护
        if (profile.getGender() != null) p.setGender(profile.getGender());
        if (profile.getAge() != null) p.setAge(profile.getAge());
        if (profile.getBirthday() != null) p.setBirthday(profile.getBirthday());
        if (profile.getIndustry() != null) p.setIndustry(profile.getIndustry());
        if (profile.getPosition() != null) p.setPosition(profile.getPosition());
        if (profile.getWechat() != null) p.setWechat(profile.getWechat());
        if (profile.getEmail() != null) p.setEmail(profile.getEmail());
        if (profile.getSecondPhone() != null) p.setSecondPhone(profile.getSecondPhone());
        if (profile.getProvince() != null) p.setProvince(profile.getProvince());
        if (profile.getCity() != null) p.setCity(profile.getCity());
        if (profile.getIntentLevel() != null) p.setIntentLevel(profile.getIntentLevel());
        if (profile.getBudget() != null) p.setBudget(profile.getBudget());
        if (profile.getIsDecision() != null) p.setIsDecision(profile.getIsDecision());
        if (profile.getChannel() != null) p.setChannel(profile.getChannel());
        if (profile.getProductInterest() != null) p.setProductInterest(profile.getProductInterest());
        if (profile.getPainPoint() != null) p.setPainPoint(profile.getPainPoint());
        if (profile.getCompetitor() != null) p.setCompetitor(profile.getCompetitor());
        if (profile.getNextFollowAt() != null) p.setNextFollowAt(profile.getNextFollowAt());
        if (profile.getProfileTags() != null) p.setProfileTags(profile.getProfileTags());
        if (profile.getSummary() != null) p.setSummary(profile.getSummary());
        p.setTeamId(c.getTeamId());
        profileMapper.updateById(p);
        return p;
    }

    @Override
    public void touchCall(Long customerId) {
        if (customerId == null) return;
        if (getById(customerId) == null) return;
        CustomerProfile p = getProfile(customerId);
        p.setCallCount((p.getCallCount() == null ? 0 : p.getCallCount()) + 1);
        p.setLastCalledAt(LocalDateTime.now());
        profileMapper.updateById(p);
    }

    @Override
    public Map<Long, CustomerProfile> profileMap(Collection<Long> customerIds) {
        Map<Long, CustomerProfile> map = new HashMap<>();
        if (customerIds == null || customerIds.isEmpty()) return map;
        List<Long> ids = new ArrayList<>();
        for (Long id : customerIds) if (id != null) ids.add(id);
        if (ids.isEmpty()) return map;
        LambdaQueryWrapper<CustomerProfile> w = new LambdaQueryWrapper<>();
        w.in(CustomerProfile::getCustomerId, ids);
        for (CustomerProfile p : profileMapper.selectList(w)) {
            map.put(p.getCustomerId(), p);
        }
        return map;
    }

    private static String trim(String s) {
        return s == null ? "" : s.trim();
    }

    private void writeLog(Long customerId, Long from, Long to, String type, String remark) {
        CustomerTransferLog log = new CustomerTransferLog();
        log.setCustomerId(customerId);
        log.setFromUserId(from);
        log.setToUserId(to);
        log.setType(type);
        log.setRemark(remark);
        transferLogMapper.insert(log);
    }
}
