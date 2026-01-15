
-- =============================================
-- 1. TẠO 10 USERS (Sử dụng Procedure để test cả log đăng ký)
-- =============================================
CALL sp_register_user('nguyenvanan', 'pass123', 'an.nguyen@example.com');
CALL sp_register_user('tranthib', 'pass123', 'b.tran@example.com');
CALL sp_register_user('levanc', 'pass123', 'c.le@example.com');
CALL sp_register_user('phamthid', 'pass123', 'd.pham@example.com');
CALL sp_register_user('hoangvane', 'pass123', 'e.hoang@example.com');
CALL sp_register_user('dothif', 'pass123', 'f.do@example.com');
CALL sp_register_user('vuongvang', 'pass123', 'g.vuong@example.com');
CALL sp_register_user('ngothih', 'pass123', 'h.ngo@example.com');
CALL sp_register_user('buiyi', 'pass123', 'i.bui@example.com');
CALL sp_register_user('lythik', 'pass123', 'k.ly@example.com');

-- =============================================
-- 2. TẠO 10 BÀI VIẾT (Sử dụng Procedure để test check content rỗng)
-- =============================================
-- User 1 đăng 3 bài
CALL sp_create_post(1, 'Hôm nay trời đẹp quá, đi code SQL thôi!');
CALL sp_create_post(1, 'Có ai biết cách fix lỗi Foreign Key không?');
CALL sp_create_post(1, 'Check in tại quán cà phê Highland.');

-- User 2 đăng 2 bài
CALL sp_create_post(2, 'Vừa mua được con xe mới, vui quá anh em ơi.');
CALL sp_create_post(2, 'Cần tìm đồng đội leo rank tối nay.');

-- Các user khác đăng rải rác
CALL sp_create_post(3, 'Cuối tuần này có ai đi phượt không?');
CALL sp_create_post(4, 'Món bún chả hôm nay ngon tuyệt.');
CALL sp_create_post(5, 'Review phim Mai: Quá xúc động.');
CALL sp_create_post(6, 'Đang học Java Spring Boot, khó quá.');
CALL sp_create_post(7, 'Chúc mọi người ngày mới tốt lành!');

-- =============================================
-- 3. TẠO 10 COMMENT (Dùng INSERT vì chưa có Procedure cho Comment)
-- =============================================
INSERT INTO Comments(post_id, user_id, content) VALUES
(1, 2, 'Đúng rồi, thời tiết này code là nhất.'),
(1, 3, 'Đi uống bia không bác ơi?'),
(2, 4, 'Lỗi gì đấy? Chụp màn hình gửi xem nào.'),
(2, 5, 'Chắc quên SET FOREIGN_KEY_CHECKS = 0 rồi.'),
(3, 2, 'Quán nào đấy? Nhìn view đẹp thế.'),
(4, 1, 'Chúc mừng nhé, rửa xe thôi!'),
(5, 6, 'Rank gì rồi? Tui Bạch Kim nè.'),
(6, 7, 'Đi Tam Đảo không?'),
(8, 9, 'Phim đấy xem khóc hết nước mắt.'),
(9, 10, 'Cố lên, Spring Boot hay mà.');

-- =============================================
-- 4. TẠO 10 LƯỢT LIKE (Sử dụng Procedure để test trigger tăng like_count)
-- =============================================
-- Bài 1 được nhiều người like
CALL sp_like_post(2, 1);
CALL sp_like_post(3, 1);
CALL sp_like_post(4, 1);
CALL sp_like_post(5, 1);

-- Bài 2 được vài like
CALL sp_like_post(1, 2);
CALL sp_like_post(3, 2);

-- Các bài khác
CALL sp_like_post(1, 4); -- User 1 like bài user 2
CALL sp_like_post(2, 4); -- User 2 like bài user 2
CALL sp_like_post(8, 9);
CALL sp_like_post(9, 6);

-- =============================================
-- 5. TẠO QUAN HỆ BẠN BÈ (10 cặp - Test pending và accepted)
-- =============================================
-- Các cặp đã chấp nhận kết bạn (Accepted)
CALL sp_send_friend_request(1, 2); 
CALL sp_accept_friend_request(1, 2); -- 1 và 2 là bạn

CALL sp_send_friend_request(1, 3);
CALL sp_accept_friend_request(1, 3); -- 1 và 3 là bạn

CALL sp_send_friend_request(2, 3);
CALL sp_accept_friend_request(2, 3); -- 2 và 3 là bạn

CALL sp_send_friend_request(4, 5);
CALL sp_accept_friend_request(4, 5); -- 4 và 5 là bạn

CALL sp_send_friend_request(6, 7);
CALL sp_accept_friend_request(6, 7); -- 6 và 7 là bạn

-- Các cặp đang chờ (Pending)
CALL sp_send_friend_request(1, 4); -- 1 gửi cho 4 (Pending)
CALL sp_send_friend_request(1, 5); -- 1 gửi cho 5 (Pending)
CALL sp_send_friend_request(2, 6); -- 2 gửi cho 6 (Pending)
CALL sp_send_friend_request(8, 9); -- 8 gửi cho 9 (Pending)
CALL sp_send_friend_request(10, 1); -- 10 gửi cho 1 (Pending)
