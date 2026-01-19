CREATE TABLE UNIVERSITY (
    Uni_id INT PRIMARY KEY,
    Uni_name VARCHAR(100) UNIQUE,
    Phone VARCHAR(20),
    Email VARCHAR(100) UNIQUE,
    Location VARCHAR(150)
);

CREATE TABLE DEPARTMENT (
    Dep_id INT PRIMARY KEY ,
    Dep_name VARCHAR(100),
    Location VARCHAR(150),
	Country VARCHAR(20),
    Email VARCHAR(100),
    Level_Val VARCHAR(50),
    Uni_id INT NOT NULL,
    FOREIGN KEY (Uni_id) REFERENCES UNIVERSITY(Uni_id)
);

CREATE TABLE INSTRUCTOR (
    Instructor_ID INT PRIMARY KEY,
    Name VARCHAR(100),
    Phone VARCHAR(20),
    Email VARCHAR(100),
    Rank_Val VARCHAR(50),
    Edu_Bsc VARCHAR(100),
    Edu_Msc VARCHAR(100),
    Edu_Phd VARCHAR(100),
    Dep_id INT NOT NULL,
    FOREIGN KEY (Dep_id) REFERENCES DEPARTMENT(Dep_id)
);

CREATE TABLE CURRICULUM (
    Curr_id INT PRIMARY KEY,
    Curr_time INT,
    Total_ects INT,
    Model_of_study VARCHAR(50),
    Dep_id INT NOT NULL,
	Director_id INT,
	FOREIGN KEY (Director_id) REFERENCES INSTRUCTOR(Instructor_ID),
    FOREIGN KEY (Dep_id) REFERENCES DEPARTMENT(Dep_id)
);

CREATE TABLE EXCHANGE_STUDENT (
    S_no INT PRIMARY KEY,
    Sname_Fname VARCHAR(50),
    Sname_Mname VARCHAR(50),
    Sname_Lname VARCHAR(50),
    Major VARCHAR(100),
    Addr VARCHAR(200),
    Phone VARCHAR(20),
    DOB DATE,
    Dep_id INT NOT NULL,
    Since_date DATE,
    FOREIGN KEY (Dep_id) REFERENCES DEPARTMENT(Dep_id)
);

CREATE TABLE COURSE (
    Course_id VARCHAR(20) PRIMARY KEY,
    Course_name VARCHAR(100),
    Semester INT,
    ECTS INT,
    Objective TEXT,
    Language VARCHAR(50),
    Delivers TEXT,
    Hour_Theo INT,
    Hour_Lab INT,
    Hour_Prac INT,
    Curr_id INT NOT NULL,
	Director_id INT,
	FOREIGN KEY (Director_id) REFERENCES INSTRUCTOR(Instructor_ID),
    FOREIGN KEY (Curr_id) REFERENCES CURRICULUM(Curr_id),
	CONSTRAINT chk_ects_valid CHECK (ECTS > 0)
);

CREATE TABLE SECTION (
    Sec_id INT PRIMARY KEY,
    Sec_no VARCHAR(20),
    Year INT,
    Day VARCHAR(15),
    Room_Bldg_no VARCHAR(50),
    Room_Room_no VARCHAR(50),
    Course_id VARCHAR(20) NOT NULL,
    Teacher_id INT NOT NULL,
    Assistant_id INT,
    FOREIGN KEY (Course_id) REFERENCES COURSE(Course_id),
    FOREIGN KEY (Teacher_id) REFERENCES INSTRUCTOR(Instructor_ID),
    FOREIGN KEY (Assistant_id) REFERENCES INSTRUCTOR(Instructor_ID)
);

CREATE TABLE ASSESSMENT (
    Course_id VARCHAR(20),
    Assessment_id INT,
    Term_Percent DECIMAL(5,2),
    End_Term_Percent DECIMAL(5,2),
    PRIMARY KEY (Course_id, Assessment_id),
    FOREIGN KEY (Course_id) REFERENCES COURSE(Course_id) ON DELETE CASCADE,
	CONSTRAINT chk_total_100 CHECK ((Term_Percent + End_Term_Percent) = 100)
);

CREATE TABLE COMPONENT (
    Course_id VARCHAR(20),
    Assessment_id INT,
    Comp_Name VARCHAR(100),
    Type VARCHAR(50),
    Weight DECIMAL(5,2),
    Quantity INT,
    PRIMARY KEY (Course_id, Assessment_id, Comp_Name),
    FOREIGN KEY (Course_id, Assessment_id) REFERENCES ASSESSMENT(Course_id, Assessment_id) ON DELETE CASCADE,
	CONSTRAINT check_type_valid CHECK (Type IN ('Term', 'End_Term'))
);

CREATE TABLE CONTENT (
    Course_id VARCHAR(20) NOT NULL,
    Content_id INT NOT NULL,
    Week INT,
    Subject TEXT,
    Document VARCHAR(255),
	Practice VARCHAR(100),
    Method VARCHAR(100),
    Preparatory VARCHAR(255),
    PRIMARY KEY (Course_id, Content_id),
    FOREIGN KEY (Course_id) REFERENCES COURSE(Course_id) ON DELETE CASCADE
);

CREATE TABLE E_CANDIDATE (
    Dep_id INT,
    S_no INT,
    App_id INT,
    App_date DATE,
    Status VARCHAR(50),
    PRIMARY KEY (Dep_id, S_no, App_id),
    FOREIGN KEY (Dep_id) REFERENCES DEPARTMENT(Dep_id),
    FOREIGN KEY (S_no) REFERENCES EXCHANGE_STUDENT(S_no),
	CONSTRAINT chk_status_valid CHECK (Status IN ('Approved', 'Rejected', 'Pending', 'Conditional'))
);

CREATE TABLE PREREQUISITE (
    Course_id VARCHAR(20),
    Prerequisite_id VARCHAR(20),
    PRIMARY KEY (Course_id, Prerequisite_id),
    FOREIGN KEY (Course_id) REFERENCES COURSE(Course_id),
    FOREIGN KEY (Prerequisite_id) REFERENCES COURSE(Course_id)
);

CREATE TABLE EQUIVALENCY (
    Host_Course_id VARCHAR(20),
    Home_Course_id VARCHAR(20),
	Language_match BOOLEAN,
	ECTS_diff INT,
    Status VARCHAR(50),
    PRIMARY KEY (Host_Course_id, Home_Course_id),
    FOREIGN KEY (Host_Course_id) REFERENCES COURSE(Course_id),
    FOREIGN KEY (Home_Course_id) REFERENCES COURSE(Course_id),
	CONSTRAINT chk_status_valid CHECK (Status IN ('NOT_EQUAL', 'EQUAL'))
);

CREATE TABLE MANDATORY (
    Course_id VARCHAR(20) PRIMARY KEY,
	MandatoryType VARCHAR(20),
    FOREIGN KEY (Course_id) REFERENCES COURSE(Course_id) ON DELETE CASCADE
);

CREATE TABLE ELECTIVE (
    Course_id VARCHAR(20) PRIMARY KEY,
    Group_no INT,
	ElectiveType VARCHAR(20),
    FOREIGN KEY (Course_id) REFERENCES COURSE(Course_id) ON DELETE CASCADE
);

CREATE TABLE TEXTBOOK (
    Course_id VARCHAR(20),
    Textbook_Name VARCHAR(200),
    Edition VARCHAR(100),
    PRIMARY KEY (Course_id, Textbook_Name),
    FOREIGN KEY (Course_id) REFERENCES COURSE(Course_id) ON DELETE CASCADE
);

CREATE TABLE OUTCOME (
    Course_id VARCHAR(20),
    Outcome_Desc TEXT,
	Assesment_Method TEXT,
	Teaching_Method TEXT,
    PRIMARY KEY (Course_id, Outcome_Desc),
    FOREIGN KEY (Course_id) REFERENCES COURSE(Course_id) ON DELETE CASCADE
);

CREATE TABLE DEP_PHONE_NO (
    Dep_id INT,
    Phone_no VARCHAR(20),
    PRIMARY KEY (Dep_id, Phone_no),
    FOREIGN KEY (Dep_id) REFERENCES DEPARTMENT(Dep_id) ON DELETE CASCADE
);

CREATE TABLE DEP_FAX_NO (
    Dep_id INT,
    Fax_no VARCHAR(20),
    PRIMARY KEY (Dep_id, Fax_no),
    FOREIGN KEY (Dep_id) REFERENCES DEPARTMENT(Dep_id) ON DELETE CASCADE
);