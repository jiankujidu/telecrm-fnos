package com.telecrm.service.impl;

import com.telecrm.common.PageResult;
import com.telecrm.entity.Prospect;
import com.telecrm.service.ProspectService;
import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 拓客服务实现：内置 mock 企业数据，支持筛选与附近检索。
 * 接入真实数据源（工商库 / 地图 POI）时替换 init() 与 nearby/search 即可。
 */
@Service
public class ProspectServiceImpl implements ProspectService {

    private final List<Prospect> DATA = new ArrayList<>();

    private static final String[] INDUSTRIES = {"信息技术", "电子商务", "教育培训", "餐饮管理", "建筑工程",
            "医疗健康", "金融服务", "物流运输", "文化传媒", "智能制造"};
    private static final String[] SCALES = {"0-20人", "20-100人", "100-500人", "500人以上"};
    private static final String[] PREFIX = {"鑫源", "华瑞", "盛通", "博远", "智联", "恒达", "佳和", "瑞祥",
            "天成", "宏图", "创想", "云图", "锦程", "德盛", "正泰", "鼎峰", "聚信", "众合"};
    private static final String[] SUFFIX = {"科技有限公司", "信息技术有限公司", "商贸有限公司", "实业有限公司",
            "网络科技有限公司", "电子商务有限公司", "智能科技有限公司"};
    private static final String[] XING = {"王", "李", "张", "刘", "陈", "杨", "黄", "赵", "周", "吴", "徐", "孙", "马", "朱", "胡"};
    private static final String[] MING = {"伟", "芳", "娜", "敏", "静", "丽", "强", "磊", "军", "洋",
            "勇", "艳", "杰", "娟", "涛", "明", "超", "霞", "建国", "志强"};
    // 城市：省, 市, 纬度, 经度
    private static final String[][] CITIES = {
            {"广东省", "深圳市", "22.5431", "114.0579"},
            {"广东省", "广州市", "23.1291", "113.2644"},
            {"广东省", "东莞市", "23.0210", "113.7518"},
            {"广东省", "珠海市", "22.2710", "113.5767"},
            {"广东省", "佛山市", "23.0218", "113.1219"},
            {"北京市", "北京市", "39.9042", "116.4074"},
            {"上海市", "上海市", "31.2304", "121.4737"},
            {"浙江省", "杭州市", "30.2741", "120.1551"},
            {"江苏省", "南京市", "32.0603", "118.7969"},
    };

    @PostConstruct
    public void init() {
        Random r = new Random(20241007L);
        long id = 1;
        for (String[] c : CITIES) {
            String province = c[0], city = c[1];
            double baseLat = Double.parseDouble(c[2]);
            double baseLng = Double.parseDouble(c[3]);
            int n = 5 + r.nextInt(3);
            for (int k = 0; k < n; k++) {
                Prospect p = new Prospect();
                String prefix = PREFIX[r.nextInt(PREFIX.length)];
                String industry = INDUSTRIES[r.nextInt(INDUSTRIES.length)];
                String suffix = SUFFIX[r.nextInt(SUFFIX.length)];
                p.setId(id++);
                p.setCompany(prefix + industry + suffix);
                p.setLegalPerson(XING[r.nextInt(XING.length)] + MING[r.nextInt(MING.length)]);
                p.setPhone("1" + (3 + r.nextInt(7)) + String.format("%09d", r.nextInt(1_000_000_000)));
                p.setProvince(province);
                p.setCity(city);
                p.setAddress(city + randomDistrict(r) + randomRoad(r) + (1 + r.nextInt(200)) + "号");
                p.setIndustry(industry);
                p.setScale(SCALES[r.nextInt(SCALES.length)]);
                p.setRegisteredCapital((50 + r.nextInt(1950)) + "万元");
                p.setFoundDate("20" + (5 + r.nextInt(19)) + "-" + pad(r.nextInt(12) + 1) + "-" + pad(r.nextInt(28) + 1));
                p.setBusinessScope(industry + "相关产品的技术开发、技术咨询、销售与服务");
                p.setLat(baseLat + (r.nextDouble() - 0.5) * 0.08);
                p.setLng(baseLng + (r.nextDouble() - 0.5) * 0.08);
                DATA.add(p);
            }
        }
    }

    private String randomDistrict(Random r) {
        String[] d = {"福田区", "南山区", "宝安区", "龙岗区", "罗湖区", "龙华区", "天河区", "越秀区", "高新区", "滨江区"};
        return d[r.nextInt(d.length)];
    }

    private String randomRoad(Random r) {
        String[] d = {"科技路", "创业大道", "工业一路", "人民南路", "建设北路", "金园路", "迎宾大道", "光华街"};
        return d[r.nextInt(d.length)];
    }

    private String pad(int v) {
        return v < 10 ? "0" + v : String.valueOf(v);
    }

    @Override
    public PageResult<Prospect> search(String industry, String region, String scale, String keyword, long current, long size) {
        final String kw = keyword == null ? "" : keyword.trim();
        List<Prospect> filtered = DATA.stream().filter(p -> {
            if (industry != null && !industry.isEmpty() && !industry.equals(p.getIndustry())) return false;
            if (region != null && !region.isEmpty() && !region.equals(p.getProvince() + "-" + p.getCity())) return false;
            if (scale != null && !scale.isEmpty() && !scale.equals(p.getScale())) return false;
            if (!kw.isEmpty()) {
                if (!(contains(p.getCompany(), kw) || contains(p.getLegalPerson(), kw) || contains(p.getAddress(), kw))) {
                    return false;
                }
            }
            return true;
        }).collect(Collectors.toList());

        long total = filtered.size();
        int from = (int) ((current - 1) * size);
        if (from < 0) from = 0;
        int to = Math.min(from + (int) size, filtered.size());
        List<Prospect> pageList = from >= filtered.size()
                ? Collections.emptyList()
                : new ArrayList<>(filtered.subList(from, to));
        return new PageResult<>(pageList, total, size, current);
    }

    @Override
    public List<Prospect> nearby(double lat, double lng, double radiusKm) {
        List<Prospect> res = new ArrayList<>();
        for (Prospect p : DATA) {
            double d = haversine(lat, lng, p.getLat(), p.getLng());
            if (d <= radiusKm) {
                Prospect c = copy(p);
                c.setDistance(Math.round(d * 100.0) / 100.0);
                res.add(c);
            }
        }
        res.sort(Comparator.comparing(Prospect::getDistance, Comparator.nullsLast(Double::compareTo)));
        return res;
    }

    @Override
    public Map<String, Object> dicts() {
        Map<String, Object> m = new HashMap<>();
        m.put("industries", new ArrayList<>(Arrays.asList(INDUSTRIES)));
        Set<String> regions = new TreeSet<>();
        for (Prospect p : DATA) regions.add(p.getProvince() + "-" + p.getCity());
        m.put("regions", new ArrayList<>(regions));
        m.put("scales", new ArrayList<>(Arrays.asList(SCALES)));
        return m;
    }

    private Prospect copy(Prospect p) {
        Prospect c = new Prospect();
        c.setId(p.getId());
        c.setCompany(p.getCompany());
        c.setLegalPerson(p.getLegalPerson());
        c.setPhone(p.getPhone());
        c.setProvince(p.getProvince());
        c.setCity(p.getCity());
        c.setAddress(p.getAddress());
        c.setIndustry(p.getIndustry());
        c.setScale(p.getScale());
        c.setRegisteredCapital(p.getRegisteredCapital());
        c.setFoundDate(p.getFoundDate());
        c.setBusinessScope(p.getBusinessScope());
        c.setLat(p.getLat());
        c.setLng(p.getLng());
        return c;
    }

    private boolean contains(String s, String kw) {
        return s != null && s.toLowerCase().contains(kw.toLowerCase());
    }

    private double haversine(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
