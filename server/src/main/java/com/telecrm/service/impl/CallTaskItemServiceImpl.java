package com.telecrm.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.telecrm.entity.CallTaskItem;
import com.telecrm.mapper.CallTaskItemMapper;
import com.telecrm.service.CallTaskItemService;
import org.springframework.stereotype.Service;

@Service
public class CallTaskItemServiceImpl extends ServiceImpl<CallTaskItemMapper, CallTaskItem>
        implements CallTaskItemService {
}
