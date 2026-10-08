package com.telecrm.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.telecrm.dto.ContactInput;
import com.telecrm.entity.CallTask;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

/**
 * 外呼任务服务
 */
public interface CallTaskService extends IService<CallTask> {

    /**
     * 导入文件生成拨打任务
     * @return 任务ID
     */
    Long importFile(MultipartFile file, String name, String sourceType, Long userId, Long teamId);

    /**
     * 从联系人列表创建拨打任务（拓客/附近企业加入拨打）
     * @return 任务ID
     */
    Long createFromContacts(List<ContactInput> inputs, String name, String sourceType, Long userId, Long teamId);
}
