/* Create a database */
/* require a excel file */

DROP DATABASE student;
CREATE DATABASE student;
USE student;

CREATE TABLE building_table (
 buildingID CHAR(5) NOT NULL PRIMARY KEY,
 building VARCHAR(40) NOT NULL
);


CREATE TABLE course_table (
 courseID CHAR(10) NOT NULL PRIMARY KEY,
 course VARCHAR(40) NOT NULL,
 buildingID CHAR(5),

 FOREIGN KEY (buildingID) REFERENCES building_table (buildingID)
);

CREATE TABLE gender_table (
 genderID CHAR(5) NOT NULL PRIMARY KEY,
 gender CHAR(4)
);


CREATE TABLE result_table (
 resultID CHAR(10) NOT NULL PRIMARY KEY,
 result VARCHAR(2),
 max INT,
 min INT
);


CREATE TABLE student_table (
 code CHAR(5) NOT NULL PRIMARY KEY,
 name VARCHAR(40) NOT NULL,
 age INT,
 courseID CHAR(5),
 genderID CHAR(5),

 FOREIGN KEY (courseID) REFERENCES course_table (courseID),
 FOREIGN KEY (genderID) REFERENCES gender_table (genderID)
);


CREATE TABLE teacher_table (
 teacherID CHAR(4) NOT NULL PRIMARY KEY,
 name VARCHAR(40) NOT NULL
);


CREATE TABLE subject_table (
 subjectID CHAR(5) NOT NULL PRIMARY KEY,
 subject CHAR(40) NOT NULL,
 teacherID CHAR(5),

 FOREIGN KEY (teacherID) REFERENCES teacher_table (teacherID)
);


CREATE TABLE score_TABLE (
 code CHAR(5) NOT NULL,
 subjectID CHAR(5) NOT NULL,
 score INT,
 date DATE,

 PRIMARY KEY (code,subjectID),

 FOREIGN KEY (code) REFERENCES student_table (code),
 FOREIGN KEY (subjectID) REFERENCES subject_table (subjectID)
);

INSERT INTO result_table(resultID, result, max, min) VALUES
('R001', '不可',59,0),
('R002', '可',69,60),
('R003', '良',79,70),
('R004', '優',100,80);

INSERT INTO building_table (buildingID, building) VALUES
('B001', 'A棟'),
('B002', 'B棟'),
('B003', 'C棟');

INSERT INTO course_table (courseID, course, buildingID) VALUES
('C001', '機械ロボティクス系', 'B001'),
('C002', '情報エレクトロニクス系', 'B002'),
('C003', '都市デザイン系', 'B003');

INSERT INTO gender_table (genderID, gender) VALUES
('G001', '男'),
('G002', '女');

INSERT INTO student_table (code, name, age, courseID, genderID) VALUES
('26401', '山川一郎', 18, 'C003', 'G001'),
('26205', '谷泉太郎', 18, 'C002', 'G001'),
('26132', '海土花子', 18, 'C001', 'G002');

INSERT INTO teacher_table (teacherID, name) VALUES
('T001', '長松次郎'),
('T002', '長松遥'),
('T003', '高田真由'),
('T004', '三浦裕'),
('T005', '上条雄三'),
('T006', '西岡剛');

INSERT INTO subject_table (subjectID, subject, teacherID) VALUES
('S001', '国語', 'T001'),
('S002', '物理', 'T002'),
('S003', '現代社会', 'T003'),
('S004', '電気工学', 'T004'),
('S005', '信号処理', 'T004'),
('S006', '機械力学', 'T005'),
('S007', '計測工学', 'T006');

INSERT INTO score_TABLE (code, subjectID, score, date) VALUES
('26401', 'S001', 65, '2025-06-10'),
('26401', 'S002', 42, '2025-06-11'),
('26401', 'S003', 79, '2025-06-14'),
('26205', 'S002', 76, '2025-06-11'),
('26205', 'S004', 66, '2025-06-12'),
('26205', 'S005', 90, '2025-06-12'),
('26132', 'S002', 87, '2025-06-10'),
('26132', 'S006', 78, '2025-06-11'),
('26132', 'S007', 100, '2025-06-12');

/* show all tables */
SELECT * FROM building_table;
SELECT * FROM course_table;
SELECT * FROM gender_table;
SELECT * FROM result_table;
SELECT * FROM student_table;
SELECT * FROM teacher_table;
SELECT * FROM subject_table;
SELECT * FROM score_TABLE;

SELECT student_table.code, student_table.name, student_table.age,
gender_table.gender, course_table.course, building_table.building,
subject_table.subject, score_TABLE.score, result_table.result,
teacher_table.teacherID, teacher_table.name, score_TABLE.score
FROM student_table
INNER JOIN gender_table ON student_table.genderID = gender_table.genderID
INNER JOIN course_table ON student_table.courseID = course_table.courseID
INNER JOIN building_table ON course_table.buildingID = building_table.buildingID
INNER JOIN score_TABLE ON student_table.code = score_TABLE.code
INNER JOIN subject_table ON subject_table.subjectID = score_TABLE.subjectID
INNER JOIN teacher_table ON subject_table.teacherID = teacher_table.teacherID
INNER JOIN result_table ON score_TABLE.score BETWEEN result_table.min AND result_table.max;