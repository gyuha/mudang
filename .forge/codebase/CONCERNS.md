---
last_mapped_commit: d3b888938c188b4a3c60d93897ccf31159291c7e
mapped: 2026-06-21
---

# CONCERNS — 기술 부채 · 알려진 위험 · 취약 지점

이 문서는 코드베이스의 우려 사항을 정리한다. 대상은 Godot 4 초기 스캐폴드로, 현재 존재하는 것은 **데이터 레이어뿐**이다: `scripts/data/*.gd`(Resource 클래스 7종), `data/**/*.tres`(스테이지 1개 + 적 4종), `tools/seed_stage1.gd`(EditorScript). 런타임 게임플레이 코드는 한 줄도 없다.

아래 우려는 모두 실제 파일을 읽고 확인한 사실에 근거한다. 아직 만들어지지 않은 시스템에 대한 우려는 "버그"가 아니라 "미구현/미검증"으로 분류한다.

---

## 1. 최대 위험: 설계와 구현의 격차 — 런타임이 아무것도 없음

흐름: **설계 문서(2,099줄) → 데이터 스키마(226줄) → 런타임(0줄)**

가장 큰 위험은 코드 결함이 아니라, **설계된 시스템과 구현된 시스템 사이의 간극** 그 자체다. 프로젝트 부피의 대부분이 설계 문서이고 코드는 극소량이다.

- 설계 문서 `docs/*.md` 12개 합계 ~1,704줄 + `DESIGN.md` 393줄 = 약 2,099줄.
- 구현 코드 `scripts/data/*.gd`(8파일) + `tools/seed_stage1.gd` 합계 **226줄**.
- 설계 문서가 코드를 약 9:1로 압도한다.

구현되지 않은 핵심 시스템(설계만 존재):
- 코어 루프 / 무녀 조작(`docs/01`)
- 동료 AI / 케어 시스템(`docs/02`)
- 혼불 경제 · 성장 · 메타(`docs/03`)
- 예산 채널 스폰 시스템 — `budget_per_sec(t)` 공식은 `stage_def.gd:37-38`에 데이터로만 존재하고, 이를 소비해 실제로 적을 스폰하는 스포너 코드는 없다(`docs/04`).
- 대시보드 / 스테이지 선택 / 6스테이지 메타(`docs/10`).

`docs/05`(데이터 스키마)는 `CompanionDef`, `MudangUpgrade`, `CompanionUpgrade`, `StageModifier`, `HazardDef` 등의 Resource 클래스를 설계로 명시하지만, 이들에 대응하는 `.gd` 파일은 **존재하지 않는다**. `stage_def.gd:34-35`의 `global_rule`/`hazards` 필드는 타입을 구체 클래스가 아닌 `Resource`로 두어 자리만 예약한 상태다(주석에 "슬라이스는 비워둠"으로 명시).

**[높음]** 설계는 완성도 높게 정리되어 있으나, 어느 것도 빌드되거나 실행되어 검증된 적이 없다. 이 단계에서는 "데이터가 Godot에서 로드되는가"조차 미확인이다(§4 참조).

---

## 2. 손작성 `.tres` 직렬화 — Godot 미실행 상태로 작성됨 (UNVERIFIED)

상태: **Godot에서 열어보기 전까지 미검증.**

`data/stages/stage_hwalinseo.tres`를 포함한 모든 `.tres`는 Godot을 실행하지 않고 손으로 작성되었다. 특히 우려되는 것은 타입드 배열(typed-array) 직렬화다.

`stage_hwalinseo.tres:87-89`:
```
objectives = [SubResource("Obj_survive"), SubResource("Obj_defend")]
spawn_pool = [SubResource("SP_mob_low"), SubResource("SP_ghost")]
timeline = [SubResource("TL_90_ghost_group"), ...]
```

대응하는 `stage_def.gd`의 선언은 `Array[ObjectiveDef]`, `Array[SpawnPoolEntry]`, `Array[TimelineEvent]`로 **타입드 배열**이다(`stage_def.gd:12-14`). Godot 4가 인스펙터에서 직렬화할 때 타입드 배열은 보통 `Array[Object]([...])` 형태의 타입 접두를 붙인다. 손작성 파일은 타입 접두 없이 단순 `[...]`로 적혀 있어, 로드 시 타입 검증에서 거부되거나(엄격) 비타입 `Array`로 강등될(관대) 가능성이 있다 — 어느 쪽인지는 실제 로드해 봐야 안다.

추가로 동일한 패턴이 적용된 다른 필드:
- `unlock_requires = []`, `recommended_roles = [&"tank", &"healer"]`(타입 `Array[StringName]`), `hazards = []`(타입 `Array[Resource]`) — `stage_hwalinseo.tres:94-98`.

`.tres` 헤더는 모두 `format=3`이며, `script_class`로 클래스를 참조한다(예: `stage_hwalinseo.tres:1`). `.uid` 파일은 존재하지 않는다(Godot 4.4+가 생성하는 리소스 UID 사이드카 없음). 이는 작성 환경이 Godot을 거치지 않았다는 또 다른 정황이다.

**안전망:** `tools/seed_stage1.gd`가 이 위험에 대한 명시적 대비책으로 존재한다. 파일 상단 주석(`seed_stage1.gd:3-4`)이 "손작성 .tres가 포맷 문제로 안 열리면, 이 스크립트가 동일 데이터를 코드로 빌드해 `res://data/`에 정식 .tres로 재생성"한다고 밝힌다. 이 EditorScript는 `EnemyDef`/`StageDef`를 코드로 빌드하고 `ResourceSaver.save()`로 직렬화하므로(`seed_stage1.gd:45-48`), Godot이 정규 포맷을 출력하게 된다. 단, 이 스크립트 역시 Godot 에디터에서 수동 실행해야 하며 아직 실행 검증되지 않았다.

**[중간]** 타입드 배열 직렬화가 손작성 형태로 깨끗이 로드될지는 불확실. **에디터에서 열어 확인하기 전까지 미검증**으로 둔다. 깨질 경우 `seed_stage1.gd` 실행이 정규 복구 경로다.

---

## 3. 소비되지 않는 필드 — `exp_value`, `level` (사용처 없음)

`enemy_def.gd:17`의 `exp_value: int`는 **어디에서도 읽히지 않는다**. grep 결과 등장 위치는 모두 *쓰기* 또는 *선언*뿐이다:
- 선언: `enemy_def.gd:17`
- 쓰기: `seed_stage1.gd:20`(`e.exp_value = exp_v`)
- 데이터 값: 4개 `.tres`(mob_low=1, ghost_maiden=2, dokkaebi=8, boss_hwalinseo=40)

설계상 진행도(성장)는 EXP가 아니라 **혼불(soulfire) 드랍**에서 온다(`docs/03` 혼불 경제, `DropTable` 리소스가 무녀/동료 혼불 드랍을 담당 — `drop_table.gd`). 필드 주석(`enemy_def.gd:16`)도 "혼불 환산 외 별도 표기용"이라고 스스로 부수적임을 인정한다. 즉 `exp_value`는 혼불 경제와 중복되거나, 현 설계에서 소비처가 없는 사실상 미사용 필드로 보인다.

동일하게 `enemy_def.gd:19`의 `level: int`도 선언과 쓰기(`seed_stage1.gd:21`)만 있고 읽는 코드가 없다. 주석은 "오라 레벨 보정용([docs/01]§2)"이라 하나, 이를 소비하는 런타임이 아직 없다.

**[높음]** `exp_value`·`level`은 현재 코드 기준 소비처 없음. 다만 런타임 미구현 단계이므로 "죽은 코드"로 단정하기보다 "아직 소비되지 않는 예약 필드(특히 `exp_value`는 혼불과 중복 가능성)"로 본다. 본격 성장 시스템 구현 시 어느 채널을 진실의 원천으로 삼을지 결정하고 한쪽을 정리해야 한다.

---

## 4. 자동화 테스트 부재 — 검증이 전적으로 수동 Godot 의존

테스트·CI 파일 탐색 결과 **아무것도 없다**: 테스트 디렉터리 없음, GUT 등 테스트 프레임워크 없음, `*.yml`/`*.yaml` CI 워크플로 없음.

`stage_def.gd:41-49`에 `validate()` 메서드가 있어 데이터 정합성을 점검하지만(duration>0, 스폰/타임라인 비어있지 않음, objectives 비어있지 않음), 이를 호출하는 곳은 `seed_stage1.gd:92-93` 한 군데뿐이며 그마저 에디터에서 수동 실행해야 출력된다.

결과적으로 모든 검증은 **사람이 Godot 에디터를 직접 열어** 데이터가 로드되는지, `validate()`가 PASS하는지 눈으로 확인하는 데 의존한다. 헤드리스 UAT(자동 인수 테스트)는 현재 구성으로 불가능하다 — 실행 가능한 씬도, CI 파이프라인도, 헤드리스 진입점도 없다.

**[높음]** 어떤 변경이든 사람이 Godot을 열기 전에는 회귀를 자동 포착할 수 없다. 특히 §2의 `.tres` 로드 검증이 이 수동 의존에 직접 묶여 있다.

---

## 5. 비밀정보 점검 — 깨끗함

`.gd`, `.tres`, `.godot` 전체를 대상으로 API 키·시크릿·비밀번호·토큰·자격증명·AWS 키 등 정규식 스캔을 수행했다. **민감 정보 없음 (CLEAN).** 데이터 레이어 스캐폴드 특성상 외부 연동이 없어 예상된 결과다.

---

## 6. 사소한 정합성 메모

- **Godot 버전 선언 모호:** `project.godot:9`는 `config/features=PackedStringArray("4.3", "Forward Plus")`로 엔진 기능을 4.3으로 선언한다. 손작성 `.tres`는 `format=3`(Godot 4 공통)을 쓴다. `.uid` 사이드카가 없는 점(§2)은 4.4+ 환경에서 작성되지 않았음을 시사한다. 실제 검증/실행 시 사용할 엔진 버전을 4.3으로 고정할지 명확히 해 두는 편이 안전하다. **[낮음]**
- **`validate()`의 적용 범위 한계:** `StageDef.validate()`는 자기 자신만 점검하고 참조 무결성(예: `timeline`이 가리키는 `EnemyDef`의 존재, `spawn_pool`의 활성 구간 겹침)은 검사하지 않는다. 저작 도구(설계상 EditorPlugin 독, `docs/05`) 구현 시 검증 범위 확장이 필요하다. **[중간]**

---

## 요약

| # | 우려 | 심각도 | 상태 |
|---|------|--------|------|
| 1 | 설계 vs 구현 격차 (런타임 0줄, 코드:설계 ≈ 1:9) | 높음 | 미구현 |
| 2 | 손작성 `.tres` 타입드 배열 직렬화 | 중간 | 미검증(에디터 미실행) |
| 3 | `exp_value`/`level` 소비처 없음 | 높음 | 예약/중복 필드 |
| 4 | 자동화 테스트 부재, 수동 Godot 의존 | 높음 | 미구현 |
| 5 | 비밀정보 | — | 깨끗함 |
| 6 | 엔진 버전 모호 / `validate()` 범위 한계 | 낮음~중간 | 메모 |
