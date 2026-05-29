#!/usr/bin/env python3
"""xcstrings_to_arb.py — PlaySpot 의 Localizable.xcstrings → Flutter ARB 변환기.

PlaySpot(SwiftUI) 의 단일 진실 출처인 Localizable.xcstrings(en/ko) 를
gen_l10n 호환 app_en.arb / app_ko.arb 로 변환한다. (plan_playspot_flutter.md Phase 11)

규칙
- sourceLanguage(en) 기준. ko 누락 시 en → key 순으로 폴백.
- ARB 키는 유효 식별자(^[a-zA-Z][a-zA-Z0-9_]*$)만 채택. 순수 기호/문장 키는 건너뜀.
- iOS 포맷 지정자 변환:
    %@  / %n$@      → {argN}        (String)
    %d  / %n$d      → {argN}        (int)
    %f  / %n$f      → {argN}        (double)
  비위치 지정자는 등장 순서대로 arg1, arg2 … 부여. 위치 지정자는 그 번호 사용.
  플레이스홀더가 있으면 @key 메타데이터에 placeholders 타입을 기록한다.

사용:  python3 scripts/xcstrings_to_arb.py
출력:  lib/l10n/app_en.arb, lib/l10n/app_ko.arb
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.normpath(os.path.join(ROOT, "..", "PlaySpot", "Resources", "Localizable.xcstrings"))
OUT_DIR = os.path.join(ROOT, "lib", "l10n")

IDENT = re.compile(r"^[a-zA-Z][a-zA-Z0-9_]*$")
# %1$@  %2$d  %@  %d  %f  형태를 모두 포착.
SPEC = re.compile(r"%(?:(\d+)\$)?([@dfqsu])")
TYPE_MAP = {"@": "String", "s": "String", "q": "String", "u": "String", "d": "int", "f": "double"}


def convert_value(text):
    """iOS 포맷 문자열 → (ARB 문자열, {argName: type} dict)."""
    placeholders = {}
    seq = [0]

    def repl(m):
        pos, conv = m.group(1), m.group(2)
        idx = int(pos) if pos else (seq[0] + 1)
        seq[0] = max(seq[0], idx)
        name = f"arg{idx}"
        placeholders[name] = TYPE_MAP.get(conv, "String")
        return "{" + name + "}"

    return SPEC.sub(repl, text), placeholders


def main():
    with open(SRC, encoding="utf-8") as f:
        data = json.load(f)

    source_lang = data.get("sourceLanguage", "en")
    strings = data["strings"]

    arb_en = {"@@locale": "en"}
    arb_ko = {"@@locale": "ko"}
    kept = skipped = 0

    for key, entry in strings.items():
        loc = entry.get("localizations")
        if not loc or not IDENT.match(key):
            skipped += 1
            continue
        kept += 1

        def value_for(lang):
            unit = loc.get(lang, {}).get("stringUnit", {})
            return unit.get("value")

        en_raw = value_for(source_lang) or key
        ko_raw = value_for("ko") or en_raw

        en_val, ph = convert_value(en_raw)
        ko_val, _ = convert_value(ko_raw)

        arb_en[key] = en_val
        arb_ko[key] = ko_val
        if ph:
            meta = {"placeholders": {n: {"type": t} for n, t in ph.items()}}
            arb_en["@" + key] = meta

    os.makedirs(OUT_DIR, exist_ok=True)
    with open(os.path.join(OUT_DIR, "app_en.arb"), "w", encoding="utf-8") as f:
        json.dump(arb_en, f, ensure_ascii=False, indent=2)
        f.write("\n")
    with open(os.path.join(OUT_DIR, "app_ko.arb"), "w", encoding="utf-8") as f:
        json.dump(arb_ko, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"source: {SRC}")
    print(f"kept {kept} keys, skipped {skipped} (symbolic/sentence keys)")
    print(f"wrote {OUT_DIR}/app_en.arb, app_ko.arb")


if __name__ == "__main__":
    main()
