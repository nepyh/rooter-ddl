# 🗄️ rooter DB DDL Repository

우리 AI 서비스(`rooter`)의 데이터베이스(DB) 구조 설계도입니다.
백엔드(`rooter-back`) 프로젝트의 서브모듈(Submodule)로 연결되어 사용되며, **psqldef** 도구를 활용하여 단일 설계도 파일로 데이터베이스 상태를 선언형으로 관리합니다.

---

## 🛠️ 기술 스택 (Tech Stack)

- **Database:** PostgreSQL
- **Migration Tool:** psqldef

---

## 🧐 기술 선정 회고 (Decision Log)

### 🔄 Liquibase에서 psqldef로 전환한 이유

초기 코드 베이스에 Liquibase가 일시적으로 도입되었으나, 이는 **팀원 간의 소통 오류**로 인해 기존 기획 문서(`psqldef` 사용)와 다르게 싱크가 어긋났던 부분이었습니다.

멘토링 피드백을 계기로 팀 내 재논의를 거쳐, 원래 기획했던 **psqldef** 방식으로 도구를 확정 및 통일하였습니다. 프로젝트 최상위의 `schema.sql` 단 한 파일만으로 전체 스키마를 관리합니다.

---

## 📂 폴더 구조 (Directory Structure)

```text
rooter-ddl/
├── .github/
│   └── workflows/
│       └── schema-check.yml   # 🤖 PR 스키마 변경 자동 검토 (psqldef dry-run)
├── README.md                  # 📘 본 가이드 문서
└── schema.sql                 # 📄 우리 서비스의 최종 DB 설계도 (통짜 관리)
```

---

## 📋 협업 및 작업 규칙 (Strict Rules)

우리 레포지토리에서 작업할 때 팀원 모두 아래 규칙을 반드시 준수해야 합니다.

### 1. 파일 추가 절대 금지 (오직 schema.sql만 수정)

테이블을 새로 만들거나, 기존 테이블의 컬럼을 추가/수정/삭제할 때 절대 새로운 `.sql` 조각 파일을 생성하지 않습니다.

오직 최상위의 `schema.sql` 파일 하나만 수정하여 데이터베이스 구조를 관리합니다.

---

### 2. DDL 작성 및 보안 규칙

#### 🔐 보안 (비밀번호)

`password` 컬럼은 백엔드에서 bcrypt 해시 처리 후 저장됩니다.

따라서 반드시 아래와 같이 충분한 길이를 확보합니다.

```sql
password VARCHAR(60) NOT NULL
```

---

#### ⚡ 성능 최적화 (인덱스)

PostgreSQL은 외래키(FK)를 생성하더라도 인덱스를 자동 생성하지 않습니다.

따라서 사용자별 데이터 조회가 자주 발생하는 FK 컬럼에는 반드시 인덱스를 생성합니다.

```sql
CREATE INDEX idx_posts_user_id
ON posts(user_id);
```

---

#### ✅ 데이터 정합성 (Enum 매핑)

요일(`day_of_week`) 등 제한된 값만 허용되는 컬럼은 백엔드 Enum 매핑 및 오타 방지를 위해 허용 값을 주석으로 명시합니다.

```sql
day_of_week VARCHAR(10) NOT NULL
-- MONDAY, TUESDAY, WEDNESDAY, THURSDAY,
-- FRIDAY, SATURDAY, SUNDAY
```

---

#### 📝 가독성 (주석 컨벤션)

모든 테이블은 아래 형식의 구분선 주석을 사용합니다.

```sql
-- =========================================================================
-- [번호]. [테이블명] TABLE ([간단한 설명])
-- =========================================================================

CREATE TABLE example (
    id SERIAL PRIMARY KEY
);
```

---

## 📌 스키마 관리 원칙

- 데이터베이스 구조는 `schema.sql` 단일 파일로 관리한다.
- 새로운 DDL 파일을 생성하지 않는다.
- 테이블 생성, 수정, 삭제는 모두 `schema.sql`에서 수행한다.
- FK 컬럼에는 필요한 인덱스를 직접 생성한다.
- Enum 성격의 컬럼은 허용 값을 주석으로 명시한다.
- 주석 컨벤션을 통일하여 가독성을 유지한다.

---

## 🔁 스키마 변경 워크플로우 (PR → 검토 → 운영 적용)

`schema.sql`을 바꾸는 PR은 `schema-check` GitHub Actions가 자동으로 검토합니다.

1. 워킹 브랜치에서 `schema.sql`을 편집한다.
2. PR을 생성한다 → **`schema-check`가 `psqldef --dry-run`으로 "실제 실행될 DDL"을 뽑아 sticky 코멘트로 게시**한다.
   - CI 안에 임시 Postgres를 띄워 `main`의 schema를 재현한 뒤, PR의 schema와 비교한다. (운영 DB에 접속하지 않음 → secret 불필요, 사고 위험 0)
3. 리뷰어가 그 SQL을 확인하고 머지한다.
4. **머지 후, 책임자가 그 SQL을 운영 DB에 직접 실행한다.** (CI는 운영 DB에 자동 적용하지 않는다)
5. 운영 반영이 끝난 상태가 곧 새 `main`이다.

> ⚠️ **`main == 운영 DB` 원칙이 이 워크플로우의 생명줄입니다.** 4번을 건너뛰면 다음 PR의 diff가 거짓이 됩니다.
> 운영 apply 책임자: `TODO(@___)` — 누가 할지 정해서 채워주세요.

### ⛔ 파괴적 변경 (DROP / 타입 변경)

`DROP TABLE`, `DROP COLUMN`, `ALTER COLUMN ... TYPE`처럼 **데이터가 손실될 수 있는 변경**은 PR에 `schema:destructive-ok` 라벨이 없으면 CI가 실패합니다.
리뷰로 영향을 확인한 뒤 라벨을 붙이고 재실행하세요. (실수로 컬럼/테이블을 날리는 것을 막기 위한 안전장치입니다)
