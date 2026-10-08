package com.telecrm.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.telecrm.common.BusinessException;
import com.telecrm.entity.CallTask;
import com.telecrm.entity.CallTaskItem;
import com.telecrm.mapper.CallTaskItemMapper;
import com.telecrm.mapper.CallTaskMapper;
import com.telecrm.service.CallTaskItemService;
import com.telecrm.dto.ContactInput;
import com.telecrm.service.CallTaskService;
import org.apache.poi.ss.usermodel.*;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import jakarta.annotation.Resource;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.regex.Pattern;

/**
 * 外呼任务服务实现：文件导入 + Excel/CSV/TXT 解析 + 自动识别手机号
 */
@Service
public class CallTaskServiceImpl extends ServiceImpl<CallTaskMapper, CallTask> implements CallTaskService {

    private static final Pattern PHONE = Pattern.compile("^1[3-9]\\d{9}$");
    private static final int MAX = 5000;

    @Resource
    private CallTaskItemService itemService;

    /** 导入文件 → 生成任务 */
    @Override
    public Long importFile(MultipartFile file, String name, String sourceType, Long userId, Long teamId) {
        String filename = file.getOriginalFilename();
        if (filename == null) throw new BusinessException("文件名缺失");
        String ext = filename.contains(".")
                ? filename.substring(filename.lastIndexOf('.') + 1).toLowerCase()
                : "";
        if (!List.of("xls", "xlsx", "csv", "txt").contains(ext)) {
            throw new BusinessException("不支持的文件类型，仅支持 xls/xlsx/csv/txt");
        }

        Parsed parsed = ext.equals("xls") || ext.equals("xlsx")
                ? parseExcel(file)
                : parseCsv(file);

        List<List<String>> rows = parsed.rows;
        if (rows.isEmpty()) throw new BusinessException("文件内容为空或未识别到数据行");
        if (rows.size() > MAX) throw new BusinessException("单次最多导入 " + MAX + " 条，当前 " + rows.size() + " 条");

        int phoneCol = detectPhoneColumn(parsed.headers, rows);
        if (phoneCol < 0) throw new BusinessException("未识别到手机号列，请检查文件内容");

        Map<String, Integer> colMap = buildColumnMap(parsed.headers, rows, phoneCol);

        CallTask task = new CallTask();
        task.setName((name == null || name.isBlank()) ? filename : name);
        task.setSourceType(sourceType == null ? "file" : sourceType);
        task.setTeamId(teamId);
        task.setUserId(userId);
        task.setTotalCount(rows.size());
        task.setCalledCount(0);
        task.setValidCount(0);
        task.setStatus("running");
        save(task);

        List<CallTaskItem> items = new ArrayList<>(rows.size());
        for (List<String> row : rows) {
            CallTaskItem item = new CallTaskItem();
            item.setTaskId(task.getId());
            item.setPhone(getCol(row, colMap.get("phone")));
            item.setName(getCol(row, colMap.get("name")));
            item.setCompany(getCol(row, colMap.get("company")));
            item.setAddress(getCol(row, colMap.get("address")));
            item.setRemark(getCol(row, colMap.get("remark")));
            item.setStatus("pending");
            item.setCallCount(0);
            items.add(item);
        }
        itemService.saveBatch(items);
        return task.getId();
    }

    /** 从联系人列表创建任务（拓客/附近企业加入拨打） */
    @Override
    public Long createFromContacts(List<ContactInput> inputs, String name, String sourceType, Long userId, Long teamId) {
        if (inputs == null || inputs.isEmpty()) throw new BusinessException("联系人不能为空");
        if (inputs.size() > MAX) throw new BusinessException("单次最多 " + MAX + " 条");
        CallTask task = new CallTask();
        task.setName((name == null || name.isBlank()) ? "拓客任务" : name);
        task.setSourceType(sourceType == null ? "bigdata" : sourceType);
        task.setTeamId(teamId);
        task.setUserId(userId);
        task.setTotalCount(inputs.size());
        task.setCalledCount(0);
        task.setValidCount(0);
        task.setStatus("running");
        save(task);
        List<CallTaskItem> items = new ArrayList<>(inputs.size());
        for (ContactInput c : inputs) {
            CallTaskItem item = new CallTaskItem();
            item.setTaskId(task.getId());
            item.setPhone(c.getPhone() == null ? "" : c.getPhone());
            item.setName(c.getName());
            item.setCompany(c.getCompany());
            item.setAddress(c.getAddress());
            item.setRemark(c.getRemark());
            item.setStatus("pending");
            item.setCallCount(0);
            items.add(item);
        }
        itemService.saveBatch(items);
        return task.getId();
    }

    // ---------- 手机号列识别 ----------

    private int detectPhoneColumn(List<String> headers, List<List<String>> rows) {
        // 1. 有表头：表头关键字优先
        if (headers != null) {
            for (int i = 0; i < headers.size(); i++) {
                String h = (headers.get(i) == null ? "" : headers.get(i)).toLowerCase();
                if (h.contains("手机") || h.contains("电话") || h.contains("号码")
                        || h.contains("phone") || h.contains("tel") || h.contains("mobile")) {
                    return i;
                }
            }
        }
        // 2. 无表头或表头无关键字：按数据识别（选命中比例最高列）
        int cols = rows.get(0).size();
        int best = -1;
        double bestRatio = 0.5;
        for (int c = 0; c < cols; c++) {
            int hit = 0;
            for (List<String> row : rows) {
                if (PHONE.matcher(getCol(row, c)).matches()) hit++;
            }
            double ratio = (double) hit / rows.size();
            if (ratio > bestRatio) {
                bestRatio = ratio;
                best = c;
            }
        }
        return best;
    }

    /** 字段列映射：有表头按关键字，无表头按位置默认 */
    private Map<String, Integer> buildColumnMap(List<String> headers, List<List<String>> rows, int phoneCol) {
        Map<String, Integer> map = new HashMap<>();
        map.put("phone", phoneCol);
        int cols = rows.get(0).size();

        if (headers != null) {
            for (int i = 0; i < headers.size() && i < cols; i++) {
                if (i == phoneCol) continue;
                String h = (headers.get(i) == null ? "" : headers.get(i)).toLowerCase();
                if (h.contains("公司") || h.contains("企业") || h.contains("单位") || h.contains("company")) {
                    map.put("company", i);
                } else if (h.contains("姓名") || h.contains("名称") || h.contains("名字") || h.contains("name")) {
                    map.put("name", i);
                } else if (h.contains("地址") || h.contains("住址") || h.contains("address")) {
                    map.put("address", i);
                } else if (h.contains("备注") || h.contains("remark") || h.contains("note")) {
                    map.put("remark", i);
                }
            }
        } else {
            // 无表头：phone 列之外按顺序映射到 name/company/address，其余拼备注
            String[] order = {"name", "company", "address"};
            int oi = 0;
            StringBuilder remarkExtra = new StringBuilder();
            for (int i = 0; i < cols; i++) {
                if (i == phoneCol) continue;
                if (oi < order.length) {
                    map.put(order[oi], i);
                    oi++;
                } else {
                    if (remarkExtra.length() > 0) remarkExtra.append(" ");
                    remarkExtra.append(getCol(rows.get(0), i));
                }
            }
            if (remarkExtra.length() > 0) {
                // 备注列在所有行中统一附加（简化处理：仅标记列索引为-1，构造时再拼接）
                map.put("__extraAll", -1);
            }
        }
        return map;
    }

    // ---------- 文件解析 ----------

    private Parsed parseExcel(MultipartFile file) {
        List<List<String>> rows = new ArrayList<>();
        List<String> headers = null;
        try (Workbook wb = WorkbookFactory.create(file.getInputStream())) {
            Sheet sheet = wb.getSheetAt(0);
            if (sheet == null) return new Parsed(null, rows);
            boolean first = true;
            for (Row row : sheet) {
                List<String> cells = new ArrayList<>();
                int last = row.getLastCellNum();
                for (int c = 0; c <= last; c++) {
                    Cell cell = row.getCell(c, Row.MissingCellPolicy.CREATE_NULL_AS_BLANK);
                    cells.add(getCellValue(cell));
                }
                while (!cells.isEmpty() && cells.get(cells.size() - 1).isEmpty()) {
                    cells.remove(cells.size() - 1);
                }
                if (cells.isEmpty()) continue;
                if (first) {
                    first = false;
                    if (!hasPhoneInRow(cells)) {
                        headers = cells;
                        continue;
                    }
                }
                rows.add(cells);
            }
        } catch (Exception e) {
            throw new BusinessException("Excel解析失败：" + e.getMessage());
        }
        return new Parsed(headers, rows);
    }

    private Parsed parseCsv(MultipartFile file) {
        List<List<String>> rows = new ArrayList<>();
        List<String> headers = null;
        try (BufferedReader br = new BufferedReader(
                new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            boolean first = true;
            while ((line = br.readLine()) != null) {
                if (line.isBlank()) continue;
                List<String> cells = splitLine(line);
                if (first) {
                    first = false;
                    if (!hasPhoneInRow(cells)) {
                        headers = cells;
                        continue;
                    }
                }
                rows.add(cells);
            }
        } catch (Exception e) {
            throw new BusinessException("文件解析失败：" + e.getMessage());
        }
        return new Parsed(headers, rows);
    }

    private List<String> splitLine(String line) {
        String sep = line.contains("\t") ? "\t" : (line.contains(";") ? ";" : ",");
        String[] arr = line.split(sep);
        List<String> cells = new ArrayList<>();
        for (String s : arr) {
            cells.add(s.replace("\"", "").trim());
        }
        return cells;
    }

    private boolean hasPhoneInRow(List<String> cells) {
        for (String c : cells) {
            if (PHONE.matcher(c).matches()) return true;
        }
        return false;
    }

    private String getCellValue(Cell cell) {
        if (cell == null) return "";
        return switch (cell.getCellType()) {
            case STRING -> cell.getStringCellValue().trim();
            case NUMERIC -> {
                if (DateUtil.isCellDateFormatted(cell)) {
                    yield cell.getLocalDateTimeCellValue().toString();
                }
                double d = cell.getNumericCellValue();
                yield (d == Math.floor(d) && !Double.isInfinite(d))
                        ? String.valueOf((long) d) : String.valueOf(d);
            }
            case BOOLEAN -> String.valueOf(cell.getBooleanCellValue());
            default -> "";
        };
    }

    private String getCol(List<String> row, Integer idx) {
        if (idx == null || idx < 0 || idx >= row.size()) return "";
        return row.get(idx);
    }

    /** 解析结果 */
    private static class Parsed {
        final List<String> headers;
        final List<List<String>> rows;

        Parsed(List<String> headers, List<List<String>> rows) {
            this.headers = headers;
            this.rows = rows;
        }
    }
}
