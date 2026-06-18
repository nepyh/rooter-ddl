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
├── README.md    # 📘 본 가이드 문서
└── schema.sql   # 📄 우리 서비스의 최종 DB 설계도 (통짜 관리)
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
