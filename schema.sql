-- =============================================================================
-- 공통 및 마스터 도메인 (기반 데이터)
-- =============================================================================

create table schools (
    id int generated always as identity primary key,
    name varchar(30) not null unique
);

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
    username varchar(12) not null unique,
    password char(60) not null,
    avatar_image_key varchar(255),
    bio varchar(500),
    created_at timestamp with time zone default current_timestamp
);

create table student_profiles (
    id int generated always as identity primary key,
    user_id int not null,
    school_id int not null, -- 텍스트 대신 외래키 참조
    grade int not null,
    class_number int not null,
    constraint fk_student_profiles_user
        foreign key (user_id) references users(id) on delete cascade,
    constraint fk_student_profiles_school
        foreign key (school_id) references schools(id)
);

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