#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成飞牛OS应用图标：优品绿圆角方块 + 白色电话听筒 + CRM 字样"""
from PIL import Image, ImageDraw, ImageFont

FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def make(size):
    S = size
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    # 渐变背景（#22c55e -> #16a34a）
    grad = Image.new("RGBA", (S, S))
    gd = ImageDraw.Draw(grad)
    for y in range(S):
        t = y / float(S - 1)
        gd.line([(0, y), (S, y)],
                fill=(int(34 + (22 - 34) * t),
                      int(197 + (163 - 197) * t),
                      int(94 + (74 - 94) * t), 255))
    r = int(S * 0.22)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=r, fill=255)
    img.paste(grad, (0, 0), mask)

    # 白色经典电话 ☎
    f_phone = ImageFont.truetype(FONT, int(S * 0.52))
    td = ImageDraw.Draw(img)
    bbox = td.textbbox((0, 0), "\u260E", font=f_phone)
    td.text(((S - (bbox[2] - bbox[0])) / 2.0 - bbox[0], S * 0.13 - bbox[1]),
            "\u260E", font=f_phone, fill=(255, 255, 255, 255))

    # CRM 文字
    f = ImageFont.truetype(FONT, int(S * 0.185))
    bbox = td.textbbox((0, 0), "CRM", font=f)
    td.text(((S - (bbox[2] - bbox[0])) / 2.0 - bbox[0], S * 0.76 - bbox[1]),
            "CRM", font=f, fill=(255, 255, 255, 255))
    return img


if __name__ == "__main__":
    base = "/workspace/fnos/telecrm"
    for s in (64, 256):
        im = make(s)
        im.save("%s/ui/images/%d.png" % (base, s))
    make(64).save(base + "/ICON.PNG")
    make(256).save(base + "/ICON_256.PNG")
    print("icons generated")
