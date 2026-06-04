-- 1. 유저(회원) 정보를 담는 메인 테이블
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,                         -- 시스템 내부용 고유 번호 (자동 증가)
    
    -- [계정 등록 페이지 관련 정보]
    username VARCHAR(10) NOT NULL UNIQUE,         -- 아이디 (조건: 10자 이하, 중복 허용 X)
    email VARCHAR(320) NOT NULL UNIQUE,           -- 이메일 (중복 허용 X)
    google_id VARCHAR(255) UNIQUE,                -- 구글 로그인 유저를 식별하기 위한 ID
    password VARCHAR(20) NOT NULL,                -- 비밀번호 (암호화되어 저장될 공간)
    
    -- [학교 및 학업 정보]
    school_name VARCHAR(100),                      -- 학교 선택 (API에서 가져온 학교 이름)
    grade INT,                                     -- 학년 (1, 2, 3학년 선택)
    class_number INT,                              -- 반 입력
    textbook_subject VARCHAR(255),                 -- 시험과목 교과서 선택 값
    exam_range TEXT,                               -- 교과서별 범위 선택 값
    exam_date DATE,                                -- 시험 날짜
    
    -- [마이페이지 관련 정보]
    profile_image_url VARCHAR(500),                -- 유저 프로필 사진 URL
    bio VARCHAR(255),                              -- 유저 소개 글
    
    -- [시스템 관리용]
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- 가입 일시
);

-- 2. 공부 불가능 시간 데이터를 저장할 별도 테이블 (옵션)
-- 한 유저가 월~일요일까지 여러 개의 불가능 시간을 드래그해서 지정하므로, 
-- 유저 테이블에 한 칸으로 넣기보다 별도 테이블로 분리하는 것이 정석입니다.
CREATE TABLE IF NOT EXISTS user_unavailable_times (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- 어느 유저의 스케줄인지 연결
    day_of_week VARCHAR(10) NOT NULL,                            -- 요일 (월~일)
    start_time TIME NOT NULL,                                    -- 공부 불가능 시작 시간
    end_time TIME NOT NULL                                       -- 공부 불가능 종료 시간
);