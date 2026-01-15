DROP DATABASE IF EXISTS Mini_Social_Network;
CREATE DATABASE Mini_Social_Network;
USE Mini_Social_Network;

CREATE TABLE Users(
	user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    like_count INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES Posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Likes (
    user_id INT NOT NULL,
    post_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, post_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES Posts(post_id) ON DELETE CASCADE
);

CREATE TABLE Friends (
    user_id INT NOT NULL,
    friend_id INT NOT NULL,
    status VARCHAR(20) CHECK (status IN ('pending', 'accepted')) DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, friend_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (friend_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Bài 1: Đăng Ký Thành Viên
-- Tạo bảng user_log (log_id, user_id, action, log_time).
CREATE TABLE user_log(
	log_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    action VARCHAR(255),
    log_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Stored Procedure sp_register_user(p_username, p_password, p_email) với kiểm tra trùng → SIGNAL lỗi.
DELIMITER $$
CREATE PROCEDURE sp_register_user(p_username VARCHAR(255), p_password VARCHAR(255), p_email VARCHAR(255))
BEGIN
	
    IF EXISTS (SELECT 1 FROM Users WHERE username = p_username ) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi : Trùng username!';
    END IF;
    
	IF EXISTS (SELECT 1 FROM Users WHERE email = p_email ) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi : Trùng email!';
    END IF;
    
    INSERT INTO Users(username,password,email) VALUE
    (p_username,p_password,p_email);
    
END $$
DELIMITER ;

-- Trigger AFTER INSERT trên Users ghi vào user_log.
DELIMITER $$
CREATE TRIGGER tg_after_insert_user
AFTER INSERT
ON Users
FOR EACH ROW
BEGIN
	
    INSERT INTO user_log(user_id,action) VALUE
    (new.user_id,'User Register!');
    
END $$
DELIMITER ;

-- Kiểm tra và demo:
-- Đăng ký 3-4 user thành công → SELECT Users và user_log.
CALL sp_register_user('sondao','123456','sondao@gmail.com');
CALL sp_register_user('hungpham','123456','hungpham@gmail.com');
CALL sp_register_user('sondao1','123456','sondao1@gmail.com');
CALL sp_register_user('sondao2','123456','sondao2@gmail.com');
-- Đăng ký trùng username/email → kiểm tra lỗi SIGNAL và bảng không thêm bản ghi.
CALL sp_register_user('sondao','123456','sondao1@gmail.com');
CALL sp_register_user('giahuy','123456','sondao@gmail.com');
-- kiểm tra kết quả
SELECT *
FROM Users;
SELECT *
FROM user_log;


-- Bài 2: Đăng Bài Viết
-- Tạo bảng post_log
CREATE TABLE post_log(
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    post_id INT,
    action VARCHAR(255),
    log_time DATETIME DEFAULT CURRENT_TIMESTAMP
);
-- Stored Procedure sp_create_post(p_user_id, p_content) kiểm tra content không rỗng.
DELIMITER $$
CREATE PROCEDURE sp_create_post(p_user_id INT, p_content TEXT)
BEGIN

	IF LENGTH(TRIM(p_content)) = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi : Content không được để trống!';
    END IF;
	
	INSERT INTO Posts(user_id,content) VALUE
    (p_user_id, p_content);
	
END $$
DELIMITER ;

-- Trigger AFTER INSERT trên Posts ghi log.
DELIMITER $$
CREATE TRIGGER tg_after_post
AFTER INSERT
ON Posts
FOR EACH ROW
BEGIN
	
	INSERT INTO post_log(user_id,post_id,action) VALUE
    (new.user_id,new.post_id,'Create Post');
    
END $$
DELIMITER ;

-- Kiểm tra và demo:
-- Đăng 5-6 bài viết → SELECT Posts và log.
CALL sp_create_post(1,'Bài viết 1');
CALL sp_create_post(1,'Bài viết 3');
CALL sp_create_post(2,'Bài viết 2');
CALL sp_create_post(3,'Bài viết 4');
CALL sp_create_post(4,'Bài viết 5');
-- Đăng bài với content rỗng → kiểm tra lỗi.
CALL sp_create_post(3,'');

-- kiểm tra
SELECT *
FROM Posts;

SELECT *
FROM post_log;

-- Bài 3: Thích Bài Viết
DELIMITER $$
CREATE PROCEDURE sp_like_post(p_user_id INT, p_post_id INT)
BEGIN 

	INSERT INTO Likes(user_id,post_id) VALUE
    (p_user_id, p_post_id);

END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE sp_unlike_post(p_user_id INT, p_post_id INT)
BEGIN 

    DELETE FROM Likes
    WHERE user_id = p_user_id AND post_id = p_post_id;

END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER tg_after_like 
AFTER INSERT
ON Likes
FOR EACH ROW
BEGIN
	-- cập nhật like_count
	UPDATE Posts
    SET like_count = like_count + 1
    WHERE post_id = new.post_id;

	-- lưu log
	INSERT INTO user_log(user_id, action) VALUE
    (new.user_id, 'User Like Post');
END $$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER tg_after_delete_like 
AFTER DELETE
ON Likes
FOR EACH ROW
BEGIN
	-- cập nhật like_count
	UPDATE Posts
    SET like_count = like_count - 1
    WHERE post_id = old.post_id;
    
	-- lưu log
	INSERT INTO user_log(user_id, action) VALUE
    (old.user_id, 'User Unlike Post');
END $$
DELIMITER ;


-- Kiểm tra và demo:
-- Like vài bài → kiểm tra like_count tăng.
CALL sp_like_post(1,1);
CALL sp_like_post(1,2);
CALL sp_like_post(2,3);
CALL sp_like_post(3,1);
-- Unlike → kiểm tra giảm.
CALL sp_unlike_post(1,2);
-- Like trùng → PRIMARY KEY ngăn chặn.
CALL sp_like_post(1,1);
-- kiểm tra
SELECT * 
FROM Posts;

SELECT * 
FROM Likes;

-- Bài 4: Gửi Lời Mời Kết Bạn
-- INSERT vào Friends với status = 'pending'.
DELIMITER $$
CREATE PROCEDURE sp_send_friend_request(p_sender_id INT, p_receiver_id INT)
BEGIN
	-- Kiểm tra hợp lệ (không tự gửi, không trùng).
	IF p_sender_id = p_receiver_id THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi : Không thể tự gửi lời mời kết bạn cho chính mình!';
    END IF;
	
    INSERT INTO Friends(user_id,friend_id) VALUE
    (p_sender_id,p_receiver_id);
    
END $$
DELIMITER ;

-- Trigger AFTER INSERT trên Friends ghi log.

DELIMITER $$
CREATE TRIGGER tg_after_send_request
AFTER INSERT
ON Friends
FOR EACH ROW
BEGIN

    IF new.status = 'pending' THEN
        INSERT INTO user_log(user_id, action) VALUES
        (new.user_id, CONCAT('User sent friend request to: ', new.friend_id));
        
        INSERT INTO user_log(user_id, action) VALUES -- Lưu ý: cột đầu là log_id (auto), cột 2 là user_id
        (new.friend_id, CONCAT('User received friend request from: ', new.user_id));
    END IF;
    
END $$
DELIMITER ;

-- Kiểm tra và demo:

-- Gửi vài lời mời hợp lệ → SELECT Friends.
CALL sp_send_friend_request(1,2);
CALL sp_send_friend_request(1,3);
-- Gửi không hợp lệ (tự gửi, trùng) → kiểm tra lỗi.
CALL sp_send_friend_request(1,1);
CALL sp_send_friend_request(1,2);
-- kiểm tra
SELECT *
FROM Friends;

-- Bài 5: Chấp Nhận Lời Mời Kết Bạn

DELIMITER $$
CREATE PROCEDURE sp_accept_friend_request(p_sender_id INT, p_receiver_id INT)
BEGIN
    
	IF p_sender_id = p_receiver_id THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi : id không hợp lệ!';
    END IF;
    
	UPDATE Friends 
	SET status = 'accepted' 
	WHERE user_id = p_sender_id AND friend_id = p_receiver_id;
    
	IF NOT EXISTS (SELECT 1 FROM Friends WHERE user_id = p_receiver_id AND friend_id = p_sender_id) THEN
		INSERT INTO Friends(user_id, friend_id, status) VALUES 
		(p_receiver_id, p_sender_id, 'accepted');
	ELSE
		UPDATE Friends 
		SET status = 'accepted' 
		WHERE user_id = p_receiver_id AND friend_id = p_sender_id;
	END IF;

END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER tg_update_accept_request
AFTER UPDATE
ON Friends
FOR EACH ROW
BEGIN

	INSERT INTO user_log(user_id,action) VALUE
    (new.user_id,CONCAT('User accept friend request friend id : ',new.friend_id));

	INSERT INTO user_log(user_id,action) VALUE
    (new.friend_id,CONCAT(new.user_id, ' had accepted friend request'));

END $$
DELIMITER ;

-- Kiểm tra và demo:
-- Gửi lời mời → chấp nhận → kiểm tra cả hai chiều đều 'accepted'.
CALL sp_accept_friend_request(1,2);
CALL sp_accept_friend_request(1,3);
-- kiểm tra
SELECT * FROM Friends;
SELECT * FROM user_log;


-- Bài 6: Quản Lý Mối Quan Hệ Bạn Bè
DELIMITER $$
CREATE PROCEDURE sp_unfriend(p_user_id INT, p_friend_id INT)
BEGIN

	START TRANSACTION;
		IF (p_user_id = p_friend_id) THEN
			ROLLBACK;
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Lỗi : id không hợp lệ!';
		END IF;
		
		DELETE FROM Friends
		WHERE (user_id = p_user_id AND friend_id = p_friend_id)
		OR (user_id = p_friend_id AND friend_id = p_user_id);
	COMMIT;
    
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER tg_unfriend
AFTER DELETE
ON Friends
FOR EACH ROW
BEGIN
	INSERT INTO user_log(user_id,action) VALUE
    (old.user_id,CONCAT('User have unfriend friend id : ',old.friend_id));
END $$
DELIMITER ;

-- Kiểm tra và demo:

-- Cập nhật/xóa mối quan hệ → kiểm tra dữ liệu nhất quán.
CALL sp_unfriend(1,2);
-- Gây lỗi
CALL sp_unfriend(1,1);

SELECT * FROM Friends;

-- Bài 7: Quản Lý Xóa Bài Viết

DELIMITER $$
CREATE PROCEDURE sp_delete_post(p_post_id INT, p_user_id INT) 
BEGIN
	START TRANSACTION;
	IF NOT EXISTS (SELECT 1 FROM Posts WHERE user_id = p_user_id AND post_id = p_post_id) THEN
		ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi : id không hợp lệ!';
    END IF;

	DELETE FROM Likes
    WHERE post_id = p_post_id;
    
    DELETE FROM Comments
    WHERE post_id = p_post_id;

    DELETE FROM Posts
    WHERE user_id = p_user_id AND post_id = p_post_id;
	COMMIT;
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER tg_after_delete_post
AFTER DELETE
ON Posts
FOR EACH ROW
BEGIN
	
    INSERT INTO post_log(user_id,post_id,action) VALUE
    (old.user_id,old.post_id,'Post has been deleted!');
END $$
DELIMITER ;

-- kiểm tra
CALL sp_delete_post(1,1);

-- thất bại
CALL sp_delete_post(1,3);

SELECT * FROM Posts;

-- Bài 8: Quản Lý Xóa Tài Khoản Người Dùng
DELIMITER $$
CREATE PROCEDURE sp_delete_user(p_user_id INT)
BEGIN
	START TRANSACTION;
	IF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = p_user_id) THEN
		ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi : id không hợp lệ!';
    END IF;
    
    DELETE FROM Posts
    WHERE user_id = p_user_id;
    
    DELETE FROM Likes
    WHERE user_id = p_user_id;
    
    DELETE FROM Friends
    WHERE user_id = p_user_id;
    
    DELETE FROM Comments
    WHERE user_id = p_user_id;
    
	DELETE FROM Users
    WHERE user_id = p_user_id;
	COMMIT;
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER tg_after_delete_user
AFTER DELETE
ON Users
FOR EACH ROW
BEGIN
	
    INSERT INTO user_log(user_id,action) VALUE
    (old.user_id,'User has been deleted!');
END $$
DELIMITER ;
-- kiểm tra
CALL sp_delete_user(1);

-- thất bại
CALL sp_delete_user(999);

SELECT * FROM Posts WHERE user_id = 1;
