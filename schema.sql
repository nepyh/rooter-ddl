-- =============================================================================
-- 공통 및 마스터 도메인 (기반 데이터)
-- =============================================================================

create table publishers (
    id int generated always as identity primary key,
    name varchar(50) not null unique
);

create table subjects (
    id int generated always as identity primary key,
    name varchar(30) not null unique
);

-- =============================================================================
-- 유저 & 인증 도메인
-- =============================================================================

create table users (
    id int generated always as identity primary key,
    email varchar(320) not null unique,
    username varchar(12) not null,
    password char(60) not null,
    avatar_image_key varchar(255),
    bio varchar(500),
    token_version int not null default 0,
    created_at timestamp with time zone default current_timestamp
);

create table student_profiles (
    id int generated always as identity primary key,
    user_id int not null unique, -- 유저당 1개 프로필만 존재 (1:1 관계 보장)
    school_id char(10) not null,
    grade int not null,
    class_number int not null,
    constraint fk_student_profiles_user
        foreign key (user_id) references users(id) on delete cascade
);
-- 참고: study_style varchar(50) 컬럼은 study_style_answers 테이블로 대체되어 제거됨

create table user_unavailable_times (
    id int generated always as identity primary key,
    user_id int not null,
    day_of_week smallint not null, -- EX: 1 = "MONDAY", 2 = "TUESDAY"
    start_time time not null,
    end_time time not null,
    constraint fk_user_unavailable_times_user
        foreign key (user_id) references users(id) on delete cascade,
    constraint chk_day_of_week
        check (day_of_week between 1 and 7)
);

create index idx_student_profiles_user_id on student_profiles(user_id);
create index idx_user_unavailable_times_user_id on user_unavailable_times(user_id);

-- =============================================================================
-- 공부스타일 설문 도메인
-- =============================================================================

create table study_style_answers (
    id int generated always as identity primary key,
    user_id int not null,
    question_number smallint not null, -- 문항 번호 (1~6)
    answer_option smallint not null,   -- 선택한 보기 번호
    constraint fk_study_style_answers_user
        foreign key (user_id) references users(id) on delete cascade,
    constraint uq_study_style_user_question unique (user_id, question_number)
);

create index idx_study_style_answers_user_id on study_style_answers(user_id);

-- =============================================================================
-- 실력 테스트 도메인
-- =============================================================================

create table level_test_results (
    id int generated always as identity primary key,
    user_id int not null,
    subject_id int not null,
    score int not null, -- level(상위권/중위권/하위권)은 score로부터 파생되는 값이므로 컬럼으로 저장하지 않음
    created_at timestamp with time zone default current_timestamp,
    constraint fk_level_test_results_user
        foreign key (user_id) references users(id) on delete cascade,
    constraint fk_level_test_results_subject
        foreign key (subject_id) references subjects(id) on delete cascade
);

create index idx_level_test_results_user_id on level_test_results(user_id);
create index idx_level_test_results_subject_id on level_test_results(subject_id);

-- =============================================================================
-- 교과서 및 과목 도메인
-- =============================================================================

create table textbooks (
    id int generated always as identity primary key,
    subject_id int not null,
    publisher_id int, -- 외래키 참조로 변경
    title varchar(150) not null,
    file_url varchar(500),
    ai_status varchar(20) default 'pending',
    created_at timestamp with time zone default current_timestamp,
    constraint fk_textbooks_subject
        foreign key (subject_id) references subjects(id) on delete cascade,
    constraint fk_textbooks_publisher
        foreign key (publisher_id) references publishers(id) on delete set null,
    constraint chk_ai_status
        check (ai_status in ('pending', 'processing', 'completed', 'failed')) -- 상태값 검증 제약 추가
);

create table chapters (
    id int generated always as identity primary key,
    textbook_id int not null,
    parent_id int,
    chapter_name varchar(150) not null,
    chapter_order int not null,
    constraint fk_chapters_textbook
        foreign key (textbook_id) references textbooks(id) on delete cascade,
    constraint fk_chapters_parent
        foreign key (parent_id) references chapters(id) on delete set null
);

create index idx_textbooks_subject_id on textbooks(subject_id);
create index idx_chapters_textbook_id on chapters(textbook_id);

-- =============================================================================
-- ai 계획 생성 도메인
-- =============================================================================

create table plan_boards (
    id int generated always as identity primary key,
    user_id int not null,
    title varchar(100) not null,
    start_date date not null,
    end_date date not null,
    exam_date date, -- 실제 시험 날짜 (end_date와 별개일 수 있음)
    is_cram_mode boolean not null default false, -- 벼락치기 모드 여부
    created_at timestamp with time zone default current_timestamp,
    constraint fk_plan_boards_user
        foreign key (user_id) references users(id) on delete cascade
);

create table plan_subjects (
    id int generated always as identity primary key,
    plan_board_id int not null,
    textbook_id int not null,
    start_chapter_id int not null,
    end_chapter_id int not null,
    custom_range_text text null,
    constraint fk_plan_subjects_board
        foreign key (plan_board_id) references plan_boards(id) on delete cascade,
    constraint fk_plan_subjects_textbook
        foreign key (textbook_id) references textbooks(id),
    constraint fk_plan_subjects_start_chapter
        foreign key (start_chapter_id) references chapters(id),
    constraint fk_plan_subjects_end_chapter
        foreign key (end_chapter_id) references chapters(id)
);

create table plan_custom_exceptions (
    id int generated always as identity primary key,
    plan_board_id int not null,
    exception_date date not null,
    start_time time not null,
    end_time time not null,
    constraint fk_plan_custom_exceptions_board
        foreign key (plan_board_id) references plan_boards(id) on delete cascade
);

create index idx_plan_boards_user_id on plan_boards(user_id);
create index idx_plan_subjects_board_id on plan_subjects(plan_board_id);
create index idx_plan_custom_exceptions_board_id on plan_custom_exceptions(plan_board_id);

-- =============================================================================
-- ai 분석 결과물 도메인
-- =============================================================================

create table daily_plans (
    id int generated always as identity primary key,
    plan_board_id int not null,
    plan_date date not null,
    constraint fk_daily_plans_board
        foreign key (plan_board_id) references plan_boards(id) on delete cascade
);

create table plan_tasks (
    id int generated always as identity primary key,
    daily_plan_id int not null,
    task_name varchar(150) not null,
    start_time time not null,
    end_time time not null,
    estimated_minutes int not null,
    is_completed boolean default false,
    constraint fk_plan_tasks_daily_plan
        foreign key (daily_plan_id) references daily_plans(id) on delete cascade
);

create index idx_daily_plans_board_id on daily_plans(plan_board_id);
create index idx_plan_tasks_daily_plan_id on plan_tasks(daily_plan_id);

-- =============================================================================
-- 일일 퀴즈 도메인 (오답 기반 재배치 AI 로직의 데이터 소스)
-- =============================================================================

create table daily_quiz_questions (
    id int generated always as identity primary key,
    daily_plan_id int not null,
    question_text text not null,
    constraint fk_daily_quiz_questions_daily_plan
        foreign key (daily_plan_id) references daily_plans(id) on delete cascade
);

create table daily_quiz_choices (
    id int generated always as identity primary key,
    question_id int not null,
    choice_text varchar(200) not null,
    is_correct boolean not null default false,
    constraint fk_daily_quiz_choices_question
        foreign key (question_id) references daily_quiz_questions(id) on delete cascade
);

create table daily_quiz_attempts (
    id int generated always as identity primary key,
    user_id int not null,
    selected_choice_id int not null, -- is_correct는 daily_quiz_choices.is_correct 조인으로 판별 (중복 저장 X)
    created_at timestamp with time zone default current_timestamp,
    constraint fk_daily_quiz_attempts_choice
        foreign key (selected_choice_id) references daily_quiz_choices(id) on delete cascade,
    constraint fk_daily_quiz_attempts_user
        foreign key (user_id) references users(id) on delete cascade
);

create index idx_daily_quiz_questions_daily_plan_id on daily_quiz_questions(daily_plan_id);
create index idx_daily_quiz_choices_question_id on daily_quiz_choices(question_id);
create index idx_daily_quiz_attempts_choice_id on daily_quiz_attempts(selected_choice_id);
create index idx_daily_quiz_attempts_user_id on daily_quiz_attempts(user_id);

-- =============================================================================
-- 일일 피드백 설문 도메인
-- =============================================================================

create table daily_feedback (
    id int generated always as identity primary key,
    daily_plan_id int not null,
    difficulty varchar(10) not null,
    time_spent_minutes int,
    focus_level smallint,
    created_at timestamp with time zone default current_timestamp,
    constraint fk_daily_feedback_daily_plan
        foreign key (daily_plan_id) references daily_plans(id) on delete cascade,
    constraint chk_daily_feedback_difficulty
        check (difficulty in ('쉬움', '적당', '어려움'))
);

create index idx_daily_feedback_daily_plan_id on daily_feedback(daily_plan_id);

-- =============================================================================
-- 학교/시험 시기 도메인 (시험범위 재사용을 위한 기준 테이블)
-- =============================================================================

create table school_exam_periods (
    id int generated always as identity primary key,
    school_id char(10) not null,
    exam_name varchar(100) not null, -- 예: "2026-2학기 중간고사"
    start_date date not null,
    end_date date not null,
    constraint uq_school_exam_period unique (school_id, exam_name)
);

create table school_exam_scopes (
    id int generated always as identity primary key,
    school_exam_period_id int not null,
    subject_id int not null,
    textbook_id int not null,
    start_chapter_id int not null,
    end_chapter_id int not null,
    contributed_by_user_id int not null, -- 처음 입력한 유저
    created_at timestamp with time zone default current_timestamp,
    constraint fk_school_exam_scopes_period
        foreign key (school_exam_period_id) references school_exam_periods(id) on delete cascade,
    constraint fk_school_exam_scopes_subject
        foreign key (subject_id) references subjects(id),
    constraint fk_school_exam_scopes_textbook
        foreign key (textbook_id) references textbooks(id),
    constraint fk_school_exam_scopes_start_chapter
        foreign key (start_chapter_id) references chapters(id),
    constraint fk_school_exam_scopes_end_chapter
        foreign key (end_chapter_id) references chapters(id),
    constraint fk_school_exam_scopes_contributor
        foreign key (contributed_by_user_id) references users(id),
    constraint uq_school_exam_scope unique (school_exam_period_id, subject_id, textbook_id)
);

create index idx_school_exam_scopes_period_id on school_exam_scopes(school_exam_period_id);
create index idx_school_exam_scopes_contributor on school_exam_scopes(contributed_by_user_id);

-- =============================================================================
-- 캘린더 개인 일정 도메인
-- =============================================================================
  
create table calendar_events (
    id int generated always as identity primary key,
    user_id int not null,
    title varchar(100) not null,
    event_date date not null,
    memo varchar(500),
    created_at timestamp with time zone default current_timestamp,
    constraint fk_calendar_events_user
        foreign key (user_id) references users(id) on delete cascade
);

create index idx_calendar_events_user_id on calendar_events(user_id);
create index idx_calendar_events_date on calendar_events(event_date);

-- =============================================================================
-- 알림 도메인
-- =============================================================================

create table user_device_tokens (
    id int generated always as identity primary key,
    user_id int not null,
    token varchar(255) not null unique,
    platform varchar(10) not null,
    created_at timestamp with time zone default current_timestamp,
    constraint fk_user_device_tokens_user
        foreign key (user_id) references users(id) on delete cascade,
    constraint chk_user_device_tokens_platform
        check (platform in ('ANDROID', 'IOS'))
);

create table task_reminder_logs (
    id int generated always as identity primary key,
    plan_task_id int not null unique,
    sent_at timestamp with time zone default current_timestamp,
    constraint fk_task_reminder_logs_task
        foreign key (plan_task_id) references plan_tasks(id) on delete cascade
);
