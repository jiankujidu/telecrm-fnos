package com.telecrm.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.telecrm.entity.Customer;
import com.telecrm.entity.CustomerProfile;

import java.util.Collection;
import java.util.List;
import java.util.Map;

/**
 * 客户服务：列表(我的/团队/公海)、增删改、流转、分配、放弃、画像
 */
public interface CustomerService extends IService<Customer> {

    /** 按范围分页查询客户 */
    IPage<Customer> pageList(String scope, Long teamId, Long userId,
                             String keyword, long current, long size);

    /** 置顶 / 取消置顶（电脑端、手机端通用） */
    void togglePin(Long id, boolean pin);

    /** 新建客户（手机号在本团队内判重） */
    Customer create(Customer customer);

    /** 更新客户基本信息（null 字段不覆盖） */
    Customer updateCustomer(Long id, Customer patch);

    /** 删除客户（逻辑删除） */
    void deleteCustomer(Long id);

    /** 批量删除客户 */
    int batchDelete(List<Long> ids);

    /** 转让客户 */
    void transfer(Long customerId, Long toUserId, Long operatorId);

    /** 公海分配给坐席 */
    void assign(Long customerId, Long toUserId, Long operatorId);

    /** 放弃客户（回公海） */
    void abandon(Long customerId, Long operatorId);

    /** 读取客户画像（不存在则创建空画像） */
    CustomerProfile getProfile(Long customerId);

    /** 保存客户画像（不存在则创建） */
    CustomerProfile saveProfile(Long customerId, CustomerProfile profile);

    /** 拨打后累计次数与最近拨打时间 */
    void touchCall(Long customerId);

    /** 批量查询画像，key = customerId */
    Map<Long, CustomerProfile> profileMap(Collection<Long> customerIds);
}
