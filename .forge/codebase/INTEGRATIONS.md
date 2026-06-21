---
last_mapped_commit: d3b888938c188b4a3c60d93897ccf31159291c7e
mapped: 2026-06-21
---

# INTEGRATIONS

**외부 연동이 전혀 없다.** 이 프로젝트는 오프라인 싱글플레이어 Godot 4 게임의 초기 골격이며, 현재 코드 베이스에는 어떤 종류의 외부 서비스 연동도 존재하지 않는다. [높음]

확인 결과(저장소 전체 파일을 직접 조사):

- 외부 API / HTTP 클라이언트: 없음. `HTTPRequest`, `HTTPClient`, REST/네트워크 호출 코드가 전무하다.
- 데이터베이스: 없음. 영속 데이터는 디스크의 Godot Resource 파일(`data/**/*.tres`)뿐이며, 외부 DB나 ORM이 없다.
- 인증 / 인가: 없음. 계정, 로그인, 토큰, OAuth 관련 코드가 없다.
- 웹훅 / 이벤트 수신: 없음.
- 서드파티 서비스(분석, 결제, 광고, 클라우드 저장, 멀티플레이어 백엔드 등): 없음.
- SDK / 외부 패키지: 없음(`addons/`, `*.gdextension`, 패키지 매니페스트 모두 부재 — 자세한 근거는 `.forge/codebase/STACK.md`의 "의존성" 절 참조).

유일한 외부 자원 접근은 로컬 파일 시스템 입출력이다. `tools/seed_stage1.gd`가 `DirAccess.make_dir_recursive_absolute()`와 `ResourceSaver.save()`로 `res://data/`에 `.tres`를 생성/저장하는 것이 전부이며, 이는 에디터 전용 로컬 디스크 쓰기일 뿐 외부 연동이 아니다. [높음]

향후 슬라이스에서 연동이 추가되기 전까지 이 문서는 "연동 없음" 상태로 남는다.
