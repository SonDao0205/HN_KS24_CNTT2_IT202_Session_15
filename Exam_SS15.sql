/*
 * DATABASE SETUP - SESSION 15 EXAM
 * Database: StudentManagement
 */

DROP DATABASE IF EXISTS StudentManagement;
CREATE DATABASE StudentManagement;
USE StudentManagement;

-- =============================================
-- 1. TABLE STRUCTURE
-- =============================================

-- Table: Students
CREATE TABLE Students (
    StudentID CHAR(5) PRIMARY KEY,
    FullName VARCHAR(50) NOT NULL,
    TotalDebt DECIMAL(10,2) DEFAULT 0
);

-- Table: Subjects
CREATE TABLE Subjects (
    SubjectID CHAR(5) PRIMARY KEY,
    SubjectName VARCHAR(50) NOT NULL,
    Credits INT CHECK (Credits > 0)
);

-- Table: Grades
CREATE TABLE Grades (
    StudentID CHAR(5),
    SubjectID CHAR(5),
    Score DECIMAL(4,2) CHECK (Score BETWEEN 0 AND 10),
    PRIMARY KEY (StudentID, SubjectID),
    CONSTRAINT FK_Grades_Students FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    CONSTRAINT FK_Grades_Subjects FOREIGN KEY (SubjectID) REFERENCES Subjects(SubjectID)
);

-- Table: GradeLog
CREATE TABLE GradeLog (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    StudentID CHAR(5),
    OldScore DECIMAL(4,2),
    NewScore DECIMAL(4,2),
    ChangeDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 2. SEED DATA
-- =============================================

-- Insert Students
INSERT INTO Students (StudentID, FullName, TotalDebt) VALUES 
('SV01', 'Ho Khanh Linh', 5000000),
('SV03', 'Tran Thi Khanh Huyen', 0);

-- Insert Subjects
INSERT INTO Subjects (SubjectID, SubjectName, Credits) VALUES 
('SB01', 'Co so du lieu', 3),
('SB02', 'Lap trinh Java', 4),
('SB03', 'Lap trinh C', 3);

-- Insert Grades
INSERT INTO Grades (StudentID, SubjectID, Score) VALUES 
('SV01', 'SB01', 8.5), -- Passed
('SV03', 'SB02', 3.0); -- Failed

-- End of File

-- Câu 1 (Trigger - 2đ): Nhà trường yêu cầu điểm số (Score) nhập vào hệ thống phải luôn hợp lệ (từ 0 đến 10). Hãy viết một Trigger có tên tg_CheckScore chạy trước khi thêm (BEFORE INSERT) dữ liệu vào bảng Grades.
-- Nếu người dùng nhập Score < 0 thì tự động gán về 0.
-- Nếu người dùng nhập Score > 10 thì tự động gán về 10

DELIMITER $$
CREATE TRIGGER tg_CheckScore 
BEFORE INSERT
ON Grades 
FOR EACH ROW 
BEGIN
    IF new.Score < 0 THEN 
        SET new.Score = 0;
    ELSEIF new.Score > 10 THEN 
        SET new.Score = 10;
	ELSE
		SET new.Score = new.Score;
    END IF;
END $$
DELIMITER ;


-- Câu 2 (Transaction - 2đ): Viết một đoạn script sử dụng Transaction để thêm một sinh viên mới. Yêu cầu đảm bảo tính trọn vẹn "All or Nothing" của dữ liệu:
-- Bắt đầu Transaction.
-- Thêm sinh viên mới vào bảng Students: StudentID = 'SV02', FullName = 'Ha Bich Ngoc'.
-- Cập nhật nợ học phí (TotalDebt) cho sinh viên này là 5,000,000.
-- Xác nhận (COMMIT) Transaction.

START TRANSACTION;

	INSERT INTO Students (StudentID, FullName, TotalDebt) 
	VALUES ('SV02', 'Ha Bich Ngoc', 0);

	UPDATE Students 
	SET TotalDebt = 5000000 
	WHERE StudentID = 'SV02';

COMMIT;

-- Câu 3 (Trigger - 1.5đ): Để chống tiêu cực trong thi cử, mọi hành động sửa đổi điểm số cần được ghi lại. Hãy viết Trigger tên tg_LogGradeUpdate chạy sau khi cập nhật (AFTER UPDATE) trên bảng Grades.
-- Yêu cầu: Khi điểm số thay đổi, hãy tự động chèn một dòng vào bảng GradeLog với các thông tin: StudentID, OldScore (lấy từ OLD), NewScore (lấy từ NEW), và ChangeDate là thời gian hiện tại (NOW()).
DELIMITER $$
CREATE TRIGGER tg_LogGradeUpdate
AFTER UPDATE ON Grades
FOR EACH ROW
BEGIN
    IF old.Score <> new.Score THEN
        INSERT INTO GradeLog (StudentID, OldScore, NewScore, ChangeDate)
        VALUES (old.StudentID, old.Score, new.Score, NOW());
    END IF;
END $$
DELIMITER ;

-- Câu 4 (Transaction & Procedure cơ bản - 1.5đ): Viết một Stored Procedure đơn giản tên sp_PayTuition thực hiện việc đóng học phí cho sinh viên 'SV01' với số tiền 2,000,000.
-- Bắt đầu Transaction.
-- Trừ 2,000,000 trong cột TotalDebt của bảng Students (StudentID = 'SV01').
-- Kiểm tra logic: Nếu sau khi trừ, TotalDebt < 0, hãy ROLLBACK để hủy bỏ. Ngược lại, hãy COMMIT.
DELIMITER $$
CREATE PROCEDURE sp_PayTuition()
BEGIN
    DECLARE temp_debt DECIMAL(10,2);
    START TRANSACTION;
    
    UPDATE Students 
    SET TotalDebt = TotalDebt - 2000000 
    WHERE StudentID = 'SV01';
    
    
    SELECT TotalDebt INTO temp_debt FROM Students WHERE StudentID = 'SV01';
    
    
    IF temp_debt < 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Lỗi: tiền đóng vượt quá số nợ.';
    ELSE
        COMMIT;
    END IF;
END $$
DELIMITER ;

-- Câu 5 (Trigger nâng cao - 1.5đ): Viết Trigger tên tg_PreventPassUpdate.
-- Quy tắc nghiệp vụ: Sinh viên đã qua môn (Điểm cũ >= 4.0) thì không được phép sửa điểm nữa để đảm bảo tính minh bạch.
-- Yêu cầu: Viết trigger BEFORE UPDATE trên bảng Grades. Nếu OldScore (OLD.Score) >= 4.0, hãy hủy thao tác cập nhật bằng cách phát sinh lỗi (Sử dụng SIGNAL SQLSTATE với thông báo lỗi tùy ý).
DELIMITER $$
CREATE TRIGGER tg_PreventPassUpdate
BEFORE UPDATE ON Grades
FOR EACH ROW
BEGIN
    IF old.Score >= 4.0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: không được phép sửa!!';
    END IF;
END $$
DELIMITER ;


-- Câu 6 (Stored Procedure & Transaction - 1.5đ): Viết một Stored Procedure tên sp_DeleteStudentGrade nhận vào p_StudentID và p_SubjectID. Thủ tục này thực hiện việc sinh viên xin hủy môn học nhưng phải đảm bảo an toàn dữ liệu:
-- Bắt đầu Transaction.
-- Lưu điểm hiện tại của sinh viên vào bảng GradeLog (Ghi chú: coi như điểm mới NewScore là NULL) để lưu vết trước khi xóa.
-- Thực hiện lệnh xóa (DELETE) dòng dữ liệu tương ứng trong bảng Grades.
-- Kiểm tra: Nếu không tìm thấy dòng dữ liệu nào được xóa (dùng hàm ROW_COUNT() trả về 0), hãy ROLLBACK.
-- Nếu xóa thành công, hãy COMMIT.
DELIMITER $$
CREATE PROCEDURE sp_DeleteStudentGrade(IN p_StudentID CHAR(5), IN p_SubjectID CHAR(5))
BEGIN
    DECLARE temp_oldScore DECIMAL(4,2);

    START TRANSACTION;

    SELECT Score INTO temp_oldScore 
    FROM Grades 
    WHERE StudentID = p_StudentID AND SubjectID = p_SubjectID;

    IF temp_oldScore IS NOT NULL THEN
        INSERT INTO GradeLog (StudentID, OldScore, NewScore, ChangeDate)
        VALUES (p_StudentID, temp_oldScore, NULL, NOW());
    END IF;

    DELETE FROM Grades 
    WHERE StudentID = p_StudentID AND SubjectID = p_SubjectID;

    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Lỗi: xoá thất bại.';
    ELSE
        COMMIT;
    END IF;
END $$
DELIMITER ;
