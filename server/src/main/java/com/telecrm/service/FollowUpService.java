package com.telecrm.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.telecrm.dto.FollowUpVO;
import com.telecrm.entity.FollowUp;

import java.util.List;

/**
 * 跟进/回访服务
 */
public interface FollowUpService extends IService<FollowUp> {

    /** 创建回访（归属当前坐席） */
    FollowUp add(Long userId, Long customerId, String content, String tag);

    /** 查询当前坐席的全部回访 */
    List<FollowUpVO> listMine(Long userId);

    /** 按客户查询回访 */
    List<FollowUpVO> listByCustomer(Long customerId);

    /** 删除（仅本人） */
    void remove(Long id, Long userId);
}
