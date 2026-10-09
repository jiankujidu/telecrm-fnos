package com.telecrm.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.telecrm.common.BusinessException;
import com.telecrm.common.UserContext;
import com.telecrm.entity.Customer;
import com.telecrm.entity.DialPushItem;
import com.telecrm.entity.DialPushTask;
import com.telecrm.mapper.CustomerMapper;
import com.telecrm.mapper.DialPushItemMapper;
import com.telecrm.mapper.DialPushTaskMapper;
import jakarta.annotation.Resource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 云端自动外呼：电脑端下发任务，手机端轮询取号执行。
 * 后端是「大脑」——顺序、间隔、暂停全部由后端决定，手机只是执行器。
 */
@Service
public class DialPushService extends ServiceImpl<DialPushTaskMapper, DialPushTask> {

    @Resource
    private DialPushItemMapper itemMapper;

    @Resource
    private CustomerMapper customerMapper;

    @Resource
    private JdbcTemplate jdbc;

    private static final int MAX_ITEMS = 2000;

    // ---------- 创建任务 ----------

    @Transactional(rollbackFor = Exception.class)
    public DialPushTask create(String scope, String keyword, Long startCustomerId,
                               Integer limit, Integer intervalSeconds, Long targetUserId,
                               String name) {
        Long teamId = UserContext.getTeamId();
        Long userId = UserContext.getUserId();

        // 1) 拉出客户（按创建时间倒序，与列表页一致）
        LambdaQueryWrapper<Customer> w = new LambdaQueryWrapper<>();
        w.eq(Customer::getTeamId, teamId);
        if ("mine".equals(scope)) {
            w.eq(Customer::getOwnerUserId, userId);
        } else if ("team".equals(scope)) {
            w.isNotNull(Customer::getOwnerUserId);
        } else {
            w.isNull(Customer::getOwnerUserId);
        }
        if (keyword != null && !keyword.isBlank()) {
            w.and(q -> q.like(Customer::getName, keyword)
                    .or().like(Customer::getPhone, keyword)
                    .or().like(Customer::getCompany, keyword));
        }
        w.orderByDesc(Customer::getCreatedAt);
        List<Customer> all = customerMapper.selectList(w);
        if (all.isEmpty()) throw new BusinessException("没有符合条件的客户");

        // 2) 起点：从指定客户开始（含该客户）
        int from = 0;
        if (startCustomerId != null) {
            for (int i = 0; i < all.size(); i++) {
                if (all.get(i).getId().equals(startCustomerId)) {
                    from = i;
                    break;
                }
            }
        }
        int n = limit == null || limit <= 0 ? 200 : Math.min(limit, MAX_ITEMS);
        List<Customer> picked = new ArrayList<>();
        for (int i = from; i < all.size() && picked.size() < n; i++) {
            picked.add(all.get(i));
        }
        if (picked.isEmpty()) throw new BusinessException("从该客户起没有可拨打的数据");

        // 3) 建任务
        DialPushTask t = new DialPushTask();
        t.setTeamId(teamId);
        t.setUserId(userId);
        t.setTargetUserId(targetUserId);
        t.setName(name == null || name.isBlank()
                ? "自动外呼 " + LocalDateTime.now().toString().substring(0, 16).replace('T', ' ')
                : name);
        t.setScope(scope == null ? "mine" : scope);
        t.setKeyword(keyword == null ? "" : keyword);
        t.setStartCustomerId(startCustomerId);
        t.setIntervalSeconds(intervalSeconds == null ? 15 : Math.max(0, Math.min(intervalSeconds, 600)));
        t.setStatus("pending");
        t.setTotalCount(picked.size());
        t.setDialedCount(0);
        t.setConnectedCount(0);
        save(t);

        // 4) 建明细
        int seq = 1;
        for (Customer c : picked) {
            DialPushItem it = new DialPushItem();
            it.setTaskId(t.getId());
            it.setSeq(seq++);
            it.setCustomerId(c.getId());
            it.setName(c.getName());
            it.setPhone(c.getPhone());
            it.setCompany(c.getCompany());
            it.setStatus("pending");
            it.setResult("");
            it.setDuration(0);
            it.setRemark("");
            itemMapper.insert(it);
        }
        return t;
    }

    // ---------- 查询 ----------

    public List<DialPushTask> listTasks() {
        LambdaQueryWrapper<DialPushTask> w = new LambdaQueryWrapper<>();
        w.eq(DialPushTask::getTeamId, UserContext.getTeamId())
                .orderByDesc(DialPushTask::getCreatedAt);
        return list(w);
    }

    public DialPushTask task(Long id) {
        DialPushTask t = getById(id);
        if (t == null) throw new BusinessException("任务不存在");
        return t;
    }

    public List<DialPushItem> items(Long taskId) {
        LambdaQueryWrapper<DialPushItem> w = new LambdaQueryWrapper<>();
        w.eq(DialPushItem::getTaskId, taskId).orderByAsc(DialPushItem::getSeq);
        return itemMapper.selectList(w);
    }

    public Map<String, Object> progress(Long taskId) {
        DialPushTask t = getById(taskId);
        if (t == null) throw new BusinessException("任务不存在");
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", t.getId());
        m.put("name", t.getName());
        m.put("status", t.getStatus());
        m.put("total", t.getTotalCount());
        m.put("dialed", t.getDialedCount());
        m.put("connected", t.getConnectedCount());
        m.put("intervalSeconds", t.getIntervalSeconds());
        m.put("startedAt", t.getStartedAt());
        m.put("finishedAt", t.getFinishedAt());
        DialPushItem cur = t.getCurrentItemId() == null ? null : itemMapper.selectById(t.getCurrentItemId());
        if (cur != null) {
            Map<String, Object> c = new LinkedHashMap<>();
            c.put("itemId", cur.getId());
            c.put("customerId", cur.getCustomerId());
            c.put("name", cur.getName());
            c.put("phone", cur.getPhone());
            c.put("company", cur.getCompany());
            c.put("status", cur.getStatus());
            c.put("result", cur.getResult());
            c.put("seq", cur.getSeq());
            m.put("current", c);
        }
        return m;
    }

    // ---------- 控制 ----------

    public void control(Long id, String action) {
        DialPushTask t = getById(id);
        if (t == null) throw new BusinessException("任务不存在");
        switch (action) {
            case "start" -> {
                if ("running".equals(t.getStatus())) return;
                t.setStatus("running");
                if (t.getStartedAt() == null) t.setStartedAt(LocalDateTime.now());
                // 重新开始：把 dialing 未完成的退回 pending
                jdbc.update("UPDATE dial_push_item SET status='pending', executor_id=NULL"
                        + " WHERE task_id=? AND status='dialing' AND deleted=0", id);
            }
            case "pause" -> {
                if (!"running".equals(t.getStatus())) throw new BusinessException("只有进行中的任务能暂停");
                t.setStatus("paused");
            }
            case "resume" -> {
                if (!"paused".equals(t.getStatus())) throw new BusinessException("只有已暂停的任务能继续");
                t.setStatus("running");
            }
            case "stop" -> {
                t.setStatus("finished");
                t.setFinishedAt(LocalDateTime.now());
                t.setCurrentItemId(null);
            }
            case "cancel" -> {
                t.setStatus("cancelled");
                t.setFinishedAt(LocalDateTime.now());
                t.setCurrentItemId(null);
            }
            default -> throw new BusinessException("不支持的操作：" + action);
        }
        updateById(t);
    }

    @Transactional(rollbackFor = Exception.class)
    public void remove(Long id) {
        DialPushTask t = getById(id);
        if (t == null) return;
        removeById(id);
        jdbc.update("UPDATE dial_push_item SET deleted=1 WHERE task_id=?", id);
    }

    /** 跳过当前这条（电脑端「下一条」） */
    public void skip(Long taskId, Long itemId) {
        jdbc.update("UPDATE dial_push_item SET status='skipped', finished_at=NOW()"
                + " WHERE id=? AND task_id=? AND deleted=0", itemId, taskId);
        DialPushTask t = getById(taskId);
        if (t != null && itemId.equals(t.getCurrentItemId())) {
            t.setCurrentItemId(null);
            updateById(t);
        }
    }

    // ---------- 手机端：取号 / 上报 ----------

    /**
     * 手机端轮询：取下一个该拨的号码。
     * 返回：
     *   {status:"none"}                 没有任务
     *   {status:"paused"}               任务已暂停
     *   {status:"wait", seconds:N}      还在间隔等待中
     *   {status:"dial", ...号码信息}     该拨这个号
     *   {status:"finished"}             全部拨完
     */
    public Map<String, Object> next(Long executorId) {
        Long teamId = UserContext.getTeamId();
        Map<String, Object> r = new LinkedHashMap<>();

        // 1) 找到属于我的 running 任务（优先指定给我的，其次未指定的）
        Long taskId = findRunningTaskId(teamId, executorId);
        if (taskId == null) {
            r.put("status", "none");
            return r;
        }
        DialPushTask t = getById(taskId);

        // 2) 我手上是否还有拨了一半的（App 重启/掉线恢复）
        DialPushItem holding = currentHolding(taskId, executorId);
        if (holding != null) {
            t.setCurrentItemId(holding.getId());
            updateById(t);
            return dialPayload(t, holding, 0);
        }

        // 3) 间隔控制：距上一通拨出不足 intervalSeconds 就继续等
        if (t.getIntervalSeconds() != null && t.getIntervalSeconds() > 0 && t.getLastDialedAt() != null) {
            long passed = java.time.Duration.between(t.getLastDialedAt(), LocalDateTime.now()).getSeconds();
            long left = t.getIntervalSeconds() - passed;
            if (left > 0) {
                r.put("status", "wait");
                r.put("seconds", left);
                r.put("taskId", t.getId());
                r.put("taskName", t.getName());
                r.put("dialed", t.getDialedCount());
                r.put("total", t.getTotalCount());
                return r;
            }
        }

        // 4) 原子领取下一条 pending（防止多台手机重复拨同一个号）
        int n = jdbc.update(
                "UPDATE dial_push_item SET status='dialing', executor_id=?, started_at=NOW() "
                        + "WHERE id = (SELECT id FROM (SELECT id FROM dial_push_item "
                        + "WHERE task_id=? AND status='pending' AND deleted=0 ORDER BY seq LIMIT 1) x)",
                executorId, taskId);
        if (n == 0) {
            // 没有 pending 了 → 任务结束
            t.setStatus("finished");
            t.setFinishedAt(LocalDateTime.now());
            t.setCurrentItemId(null);
            updateById(t);
            r.put("status", "finished");
            r.put("taskId", t.getId());
            r.put("dialed", t.getDialedCount());
            r.put("total", t.getTotalCount());
            return r;
        }

        DialPushItem item = currentHolding(taskId, executorId);
        if (item == null) {
            r.put("status", "none");
            return r;
        }
        t.setCurrentItemId(item.getId());
        t.setLastDialedAt(LocalDateTime.now());
        updateById(t);
        return dialPayload(t, item, t.getIntervalSeconds() == null ? 0 : t.getIntervalSeconds());
    }

    private Long findRunningTaskId(Long teamId, Long executorId) {
        List<Long> ids = jdbc.queryForList(
                "SELECT id FROM dial_push_task WHERE team_id=? AND status='running' AND deleted=0 "
                        + "ORDER BY (target_user_id IS NULL) ASC, id DESC",
                Long.class, teamId);
        for (Long id : ids) {
            DialPushTask t = getById(id);
            if (t == null) continue;
            if (t.getTargetUserId() == null || t.getTargetUserId().equals(executorId)) {
                return id;
            }
        }
        return null;
    }

    /** 手机端用：判断是否有「指派给我、但已暂停」的任务，便于 App 显示暂停状态 */
    public Long findPausedTaskId(Long teamId, Long executorId) {
        List<Long> ids = jdbc.queryForList(
                "SELECT id FROM dial_push_task WHERE team_id=? AND status='paused' AND deleted=0 "
                        + "ORDER BY id DESC",
                Long.class, teamId);
        for (Long id : ids) {
            DialPushTask t = getById(id);
            if (t == null) continue;
            if (t.getTargetUserId() == null || t.getTargetUserId().equals(executorId)) {
                return id;
            }
        }
        return null;
    }

    private DialPushItem currentHolding(Long taskId, Long executorId) {
        List<DialPushItem> l = itemMapper.selectList(new LambdaQueryWrapper<DialPushItem>()
                .eq(DialPushItem::getTaskId, taskId)
                .eq(DialPushItem::getExecutorId, executorId)
                .eq(DialPushItem::getStatus, "dialing")
                .orderByAsc(DialPushItem::getSeq)
                .last("LIMIT 1"));
        return l.isEmpty() ? null : l.get(0);
    }

    private Map<String, Object> dialPayload(DialPushTask t, DialPushItem it, int interval) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("status", "dial");
        m.put("taskId", t.getId());
        m.put("taskName", t.getName());
        m.put("itemId", it.getId());
        m.put("seq", it.getSeq());
        m.put("total", t.getTotalCount());
        m.put("dialed", t.getDialedCount());
        m.put("intervalSeconds", interval);
        m.put("customerId", it.getCustomerId());
        m.put("name", it.getName());
        m.put("phone", it.getPhone());
        m.put("company", it.getCompany());
        return m;
    }

    /** 手机上报通话结果 */
    @Transactional(rollbackFor = Exception.class)
    public void report(Long taskId, Long itemId, String result, Integer duration, String remark, Long executorId) {
        DialPushItem it = itemMapper.selectById(itemId);
        if (it == null) throw new BusinessException("明细不存在");
        it.setStatus("dialed");
        it.setResult(result == null ? "" : result);
        it.setDuration(duration == null ? 0 : duration);
        it.setRemark(remark == null ? "" : remark);
        it.setExecutorId(executorId);
        it.setFinishedAt(LocalDateTime.now());
        itemMapper.updateById(it);

        DialPushTask t = getById(taskId);
        if (t != null) {
            t.setDialedCount((t.getDialedCount() == null ? 0 : t.getDialedCount()) + 1);
            if ("connected".equals(result) || "add_customer".equals(result)) {
                t.setConnectedCount((t.getConnectedCount() == null ? 0 : t.getConnectedCount()) + 1);
            }
            if (itemId.equals(t.getCurrentItemId())) t.setCurrentItemId(null);
            updateById(t);
        }

        // 同步写一条通话记录，报表里也能看到
        if (it.getCustomerId() != null || it.getPhone() != null) {
            try {
                jdbc.update(
                        "INSERT INTO call_record (team_id, user_id, customer_id, phone, duration, result, remark, called_at, created_at, updated_at, deleted) "
                                + "VALUES (?,?,?,?,?,?,?,NOW(),NOW(),NOW(),0)",
                        UserContext.getTeamId(), executorId, it.getCustomerId(),
                        it.getPhone(), it.getDuration(), it.getResult(),
                        (it.getRemark() == null || it.getRemark().isBlank())
                                ? "【自动外呼】" + t.getName() : "【自动外呼】" + it.getRemark());
            } catch (Exception ignore) {
                // 通话记录写入失败不影响任务推进
            }
        }
    }

    /** 手机放弃当前这条（异常/无人接听不想标记） */
    public void release(Long taskId, Long itemId, Long executorId) {
        jdbc.update("UPDATE dial_push_item SET status='pending', executor_id=NULL, started_at=NULL "
                + "WHERE id=? AND task_id=? AND executor_id=? AND status='dialing' AND deleted=0",
                itemId, taskId, executorId);
        DialPushTask t = getById(taskId);
        if (t != null && itemId.equals(t.getCurrentItemId())) {
            t.setCurrentItemId(null);
            updateById(t);
        }
    }
}
