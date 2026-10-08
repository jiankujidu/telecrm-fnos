package com.telecrm.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.telecrm.common.Result;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.OutputStream;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * 数据备份与恢复：把全部业务表导出成一个 JSON 文件；需要时可原样导回，避免数据丢失。
 *
 * 导出：GET  /api/backup/export
 * 恢复：POST /api/backup/import  (multipart: file, mode=overwrite|append)
 * 预览：POST /api/backup/preview (只统计每个表多少条，不写库)
 */
@RestController
@RequestMapping("/api/backup")
public class BackupController {

    /** 备份涉及的表，按依赖顺序排列（order 是 MySQL 保留字，必须反引号） */
    private static final String[] TABLES = {
            "team", "user", "team_member",
            "customer", "customer_profile", "follow_up", "customer_transfer_log",
            "call_task", "call_task_item", "call_record",
            "business_template", "custom_field", "package", "`order`", "vip_code",
    };

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss");
    private static final DateTimeFormatter TS = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    @Resource
    private JdbcTemplate jdbc;

    private final ObjectMapper mapper = new ObjectMapper();

    private static String bare(String t) {
        return t.replace("`", "");
    }

    /** 导出全库为 JSON 文件下载 */
    @GetMapping("/export")
    public void export(HttpServletResponse response) throws Exception {
        response.setContentType("application/json;charset=UTF-8");
        String stamp = LocalDateTime.now().format(FMT);
        String filename = "telecrm-backup-" + stamp + ".json";
        response.setHeader("Content-Disposition",
                "attachment; filename=\"" + filename + "\"; filename*=UTF-8''"
                        + URLEncoder.encode(filename, StandardCharsets.UTF_8));

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("app", "telecrm");
        out.put("version", 1);
        out.put("exportedAt", LocalDateTime.now().format(TS));
        Map<String, Object> tables = new LinkedHashMap<>();
        int total = 0;
        for (String t : TABLES) {
            List<Map<String, Object>> rows = dumpTable(t);
            tables.put(bare(t), rows);
            total += rows.size();
        }
        out.put("tables", tables);
        out.put("totalRows", total);

        try (OutputStream os = response.getOutputStream()) {
            mapper.enable(SerializationFeature.INDENT_OUTPUT);
            // 逐表写出，避免一次性在内存里拼超大字符串
            os.write(("{\n  \"app\": \"telecrm\",\n  \"version\": 1,\n  \"exportedAt\": \""
                    + out.get("exportedAt") + "\",\n  \"totalRows\": " + total
                    + ",\n  \"tables\": {\n").getBytes(StandardCharsets.UTF_8));
            int i = 0;
            for (String t : TABLES) {
                List<Map<String, Object>> rows = (List<Map<String, Object>>) tables.get(bare(t));
                os.write(("    \"" + bare(t) + "\": ").getBytes(StandardCharsets.UTF_8));
                os.write(mapper.writeValueAsBytes(rows));
                os.write((++i < TABLES.length ? ",\n" : "\n").getBytes(StandardCharsets.UTF_8));
            }
            os.write("  }\n}\n".getBytes(StandardCharsets.UTF_8));
        }
    }

    /** 读取一张表的全部有效数据（有 deleted 列则只取未删除） */
    private List<Map<String, Object>> dumpTable(String table) {
        try {
            String sql = hasColumn(table, "deleted")
                    ? "SELECT * FROM " + table + " WHERE deleted = 0"
                    : "SELECT * FROM " + table;
            List<Map<String, Object>> rows = jdbc.queryForList(sql);
            List<Map<String, Object>> norm = new ArrayList<>(rows.size());
            for (Map<String, Object> r : rows) {
                Map<String, Object> m = new LinkedHashMap<>();
                r.forEach((k, v) -> m.put(k, normalizeOut(v)));
                norm.add(m);
            }
            return norm;
        } catch (Exception e) {
            // 表不存在（老库未升级）时跳过，保证备份不中断
            return Collections.emptyList();
        }
    }

    private boolean hasColumn(String table, String col) {
        try {
            Integer n = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM information_schema.COLUMNS "
                            + "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?",
                    Integer.class, bare(table), col);
            return n != null && n > 0;
        } catch (Exception e) {
            return false;
        }
    }

    private static Object normalizeOut(Object v) {
        if (v == null) return null;
        if (v instanceof LocalDateTime) return ((LocalDateTime) v).format(TS);
        if (v instanceof java.sql.Date) return v.toString();
        if (v instanceof Timestamp) {
            Timestamp ts = (Timestamp) v;
            return ts.toLocalDateTime().format(TS);
        }
        if (v instanceof BigDecimal) return v.toString();
        if (v instanceof byte[]) return new String((byte[]) v, StandardCharsets.UTF_8);
        return v;
    }

    /** 预览备份文件：返回每个表的条数，不写库 */
    @PostMapping("/preview")
    public Result<Map<String, Object>> preview(@RequestParam("file") MultipartFile file) {
        Map<String, Object> root = readBackup(file);
        Map<String, Object> tables = (Map<String, Object>) root.get("tables");
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("exportedAt", root.get("exportedAt"));
        res.put("version", root.get("version"));
        Map<String, Integer> counts = new LinkedHashMap<>();
        int total = 0;
        if (tables != null) {
            for (Map.Entry<String, Object> e : tables.entrySet()) {
                int n = (e.getValue() instanceof List) ? ((List<?>) e.getValue()).size() : 0;
                counts.put(e.getKey(), n);
                total += n;
            }
        }
        res.put("counts", counts);
        res.put("totalRows", total);
        return Result.success(res);
    }

    /**
     * 恢复备份。
     * mode=overwrite（默认）：先清空这些表再写入，结果与备份文件一致
     * mode=append：只插入当前不存在的 id
     */
    @PostMapping("/import")
    public Result<Map<String, Object>> restore(@RequestParam("file") MultipartFile file,
                                               @RequestParam(defaultValue = "overwrite") String mode) {
        Map<String, Object> root = readBackup(file);
        Map<String, Object> tables = (Map<String, Object>) root.get("tables");
        if (tables == null || tables.isEmpty()) {
            throw new IllegalArgumentException("备份文件里没有 tables 数据");
        }
        boolean overwrite = !"append".equalsIgnoreCase(mode);

        Map<String, Object> res = new LinkedHashMap<>();
        Map<String, Integer> inserted = new LinkedHashMap<>();
        List<String> skipped = new ArrayList<>();
        int total = 0;

        for (String t : TABLES) {
            String name = bare(t);
            Object v = tables.get(name);
            if (!(v instanceof List) || ((List<?>) v).isEmpty()) {
                continue;
            }
            List<Map<String, Object>> rows = castRows(v);
            try {
                if (overwrite) {
                    jdbc.execute("DELETE FROM " + t);
                }
                int n = insertRows(t, rows, overwrite);
                inserted.put(name, n);
                total += n;
            } catch (Exception e) {
                skipped.add(name + "（" + e.getMessage() + "）");
            }
        }
        res.put("mode", overwrite ? "overwrite" : "append");
        res.put("inserted", inserted);
        res.put("totalRows", total);
        res.put("skipped", skipped);
        return Result.success(res);
    }

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> castRows(Object v) {
        List<Map<String, Object>> rows = new ArrayList<>();
        for (Object o : (List<?>) v) {
            if (o instanceof Map) rows.add((Map<String, Object>) o);
        }
        return rows;
    }

    /** 批量写入一张表；append 模式下跳过已存在的 id */
    private int insertRows(String table, List<Map<String, Object>> rows, boolean overwrite) {
        if (rows.isEmpty()) return 0;
        Set<String> cols = new LinkedHashSet<>();
        for (Map<String, Object> r : rows) cols.addAll(r.keySet());
        // deleted 列由系统给默认值，避免备份里的 1 被写进去导致数据"消失"
        List<String> colList = new ArrayList<>(cols);

        String sql = buildInsert(table, colList);
        int n = 0;
        List<Object[]> batch = new ArrayList<>();
        for (Map<String, Object> r : rows) {
            if (!overwrite && r.get("id") != null && existsId(table, r.get("id"))) continue;
            Object[] args = new Object[colList.size()];
            for (int i = 0; i < colList.size(); i++) args[i] = normalizeIn(r.get(colList.get(i)));
            batch.add(args);
            n++;
        }
        if (!batch.isEmpty()) jdbc.batchUpdate(sql, batch);
        return n;
    }

    private static String buildInsert(String table, List<String> cols) {
        StringBuilder sb = new StringBuilder("INSERT INTO ").append(table).append(" (");
        for (int i = 0; i < cols.size(); i++) {
            if (i > 0) sb.append(", ");
            sb.append('`').append(cols.get(i)).append('`');
        }
        sb.append(") VALUES (");
        for (int i = 0; i < cols.size(); i++) {
            if (i > 0) sb.append(", ");
            sb.append('?');
        }
        return sb.append(')').toString();
    }

    private boolean existsId(String table, Object id) {
        try {
            Integer n = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM " + table + " WHERE id = ?", Integer.class, id);
            return n != null && n > 0;
        } catch (Exception e) {
            return false;
        }
    }

    /** JSON 里的时间是字符串，需还原成 JDBC 认识的类型 */
    private static Object normalizeIn(Object v) {
        if (v == null) return null;
        if (v instanceof String) {
            String s = (String) v;
            if (s.length() == 19 && s.charAt(4) == '-' && s.charAt(10) == ' ') {
                try {
                    return Timestamp.valueOf(LocalDateTime.parse(s.replace(' ', 'T')));
                } catch (Exception ignore) {
                }
            }
            return s;
        }
        if (v instanceof Boolean) return ((Boolean) v) ? 1 : 0;
        return v;
    }

    private Map<String, Object> readBackup(MultipartFile file) {
        if (file == null || file.isEmpty()) throw new IllegalArgumentException("请先选择备份文件");
        String name = file.getOriginalFilename() == null ? "" : file.getOriginalFilename().toLowerCase();
        if (!name.endsWith(".json")) throw new IllegalArgumentException("只支持 .json 备份文件");
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> m = mapper.readValue(file.getBytes(), Map.class);
            return m;
        } catch (Exception e) {
            throw new IllegalArgumentException("备份文件解析失败：" + e.getMessage());
        }
    }
}
