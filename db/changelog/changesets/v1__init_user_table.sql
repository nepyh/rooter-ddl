-- ================================
-- 1. USERS TABLE 
-- ================================

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(12) UNIQUE,
    password VARCHAR(20),
    email VARCHAR(320) NOT NULL UNIQUE,
    
    school_name VARCHAR(100),
    grade INT,
    class_number INT,
    
    textbook_subject VARCHAR(255),
    exam_range TEXT,
    exam_date DATE,
    
    profile_image_url VARCHAR(500),
    bio VARCHAR(255),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================
-- 2. USER UNAVAILABLE TIMES TABLE 
-- ================================

CREATE TABLE user_unavailable_times (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    day_of_week VARCHAR(10) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    
    CONSTRAINT fk_user_unavailable_time_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(id) 
        ON DELETE CASCADE
);