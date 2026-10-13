# Kế hoạch ProjectNetProg — ứng dụng học tiếng Anh bằng Java, mục tiêu 30 điểm

## 1. Hướng triển khai đã chốt

- **Dự án mới:** `/home/gyga/Project/Personal/ProjectNetProg`.
- **Nhóm:** 3 người; hoàn thành ngày **24/11/2026**.
- **Client:** ứng dụng desktop JavaFX, giao diện tiếng Anh.
- **Server:** Java 21, chạy độc lập; dữ liệu lưu SQLite, media lưu thành file.
- **Mạng:** chỉ dùng API socket chuẩn JDK. Nhóm tự viết giao thức, quản lý kết nối, buffer, truyền nhận, timeout và xử lý lỗi.
- **Xác minh tài khoản:** admin duyệt sau khi đăng ký.
- **Ba vai trò:** `LEARNER`, `TEACHER`, `ADMIN`.

Server dùng `ServerSocketChannel`, `SocketChannel` và `Selector` để quản lý nhiều kết nối, tương ứng với cách dùng `poll()` trong lab C. [Tài liệu Selector](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/nio/channels/Selector.html).

Thư viện ngoài chỉ phục vụ **giao diện, JSON, lưu trữ và kiểm thử**: JavaFX, Jackson, SQLite JDBC, JUnit. Jackson chỉ chuyển đổi dữ liệu JSON; toàn bộ truyền nhận vẫn do code socket của nhóm thực hiện. Không dùng Netty, Spring Web, HTTP/REST, WebSocket, RMI hay thư viện truyền file/chat/voice có sẵn.

Dùng Maven Wrapper với toolchain Java 21 để cả Windows và Linux build cùng phiên bản. Tổ chức ba module `common`, `server`, `client`; `common` chứa định nghĩa message và bộ mã hóa/giải mã dùng chung.

## 2. Ma trận chức năng bao phủ đủ 30 điểm

| Tiêu chí | Điểm | Phần phải hoàn thành và demo |
|---|---:|---|
| Kết nối socket | 2 | Client nhập IP/port, kết nối server trên PC khác; nhiều client hoạt động đồng thời. |
| Log gửi/nhận | 1 | Server ghi mọi message TCP và packet UDP, gồm chiều truyền, thời gian, kết nối, loại message và kết quả. |
| Đăng ký, đăng nhập | 2 | Đăng ký tài khoản chờ duyệt, admin kích hoạt, đăng nhập/đăng xuất, báo lỗi rõ ràng. |
| Chọn trình độ | 1 | `ELEMENTARY`, `INTERMEDIATE`, `ADVANCED`; lưu lựa chọn trên server. |
| Danh sách bài học | 2 | Lọc kết hợp theo chủ đề và trình độ; mở bài học từ danh sách. |
| Học bài | 3 | Có video, audio, đoạn đọc, từ vựng và ngữ pháp; media tải từ server bằng giao thức tự viết. |
| Quiz | 3 | Trắc nghiệm, điền chỗ trống, sắp xếp câu; server chấm điểm và trả lời giải. |
| Exercise | 3 | Viết lại câu, viết đoạn văn, ghi âm bài nói theo chủ đề và nộp cho giáo viên. |
| Game | 2 | Ghép từ/cặp câu, sắp xếp câu, ghép ảnh; thêm puzzle ảnh 3×3 để bao phủ phần mô tả đề tài. |
| Điểm và feedback | 2 | Hệ thống chấm câu hỏi khách quan; giáo viên chấm đoạn văn/bài nói, nhập điểm và nhận xét. |
| Chat | 2 | Chat riêng learner–learner hoặc learner–teacher; tin nhắn đến được đẩy ngay, có lịch sử. |
| Gọi thoại | 2 | Mời gọi, chấp nhận/từ chối, truyền âm thanh hai chiều, kết thúc cuộc gọi. |
| Admin thêm game | 3 | Admin tạo và phát hành game ghép từ, sắp xếp câu; learner tải và chơi nội dung mới ngay. |
| Teacher tạo quiz | 2 | Teacher tạo quiz trắc nghiệm, nhập lựa chọn/đáp án/lời giải, phát hành để learner làm. |
| **Tổng** | **30** | Mỗi dòng có ca kiểm thử và bằng chứng demo riêng. |

**Nghiệp vụ học tập**

- Quiz, game và bài viết lại câu được chấm tại server. Với bài viết lại câu, đối chiếu danh sách đáp án hợp lệ sau khi chuẩn hóa khoảng trắng và chữ hoa/thường.
- Đoạn văn và bài nói có trạng thái `PENDING_REVIEW → GRADED`. Teacher nhập điểm từ 0–100 và nhận xét; learner xem lại trong lịch sử.
- Bài nói là file WAV được ghi âm và nộp. Đây là một luồng riêng với chức năng gọi thoại trực tiếp.
- Khi bắt đầu bài làm, server giữ snapshot nội dung và đáp án để chỉnh sửa nội dung sau này không làm thay đổi kết quả cũ.
- Mỗi lượt làm chỉ có một kết quả; nộp lại cùng lượt không được chấm hoặc tạo bản ghi trùng.

**Giao diện**

Dùng một cửa sổ chính với thanh điều hướng và vùng nội dung thay đổi:

- Learner: Lessons, Quizzes, Exercises, Games, Results, Messages.
- Teacher: Quiz Builder, Submissions, Messages.
- Admin: Account Approval, Game Builder.

Có trạng thái loading, lỗi, mất kết nối, tiến độ tải file và “đang chờ giáo viên chấm”. Các thao tác mạng và file chạy ngoài JavaFX UI thread.

**Dữ liệu demo**

Chuẩn bị 3 chủ đề: **Daily Life, Travel, Work & Study**, mỗi chủ đề có đủ 3 trình độ:

- 9 bài học, mỗi bài đủ năm loại nội dung.
- Mỗi bài có quiz 6 câu, gồm 2 câu cho mỗi dạng.
- Mỗi bài có một bài viết lại câu, một đề viết đoạn văn và một đề nói.
- Mỗi trình độ có nội dung mẫu cho các loại game.
- Có sẵn tài khoản learner, teacher, admin và một tài khoản đang chờ duyệt.

## 3. Kiến trúc và giao thức tự định nghĩa

### Kết nối và xử lý socket

Kiến trúc thuần **client–server**:

```text
JavaFX client ── TCP:5555 ── Java server ── SQLite + media files
             └─ UDP:5556 ── Voice relay ── Client còn lại
```

- Một vòng `Selector` trên server sở hữu các socket TCP và buffer từng kết nối.
- Worker pool 4 thread xử lý nghiệp vụ, đọc/ghi file và hash mật khẩu. Kết quả được đưa về hàng đợi để vòng socket gửi.
- Mỗi client xử lý request theo thứ tự; event chat/voice có thể đến xen giữa các response.
- Truy cập SQLite được đồng bộ theo transaction.
- Client có luồng mạng riêng, hàng đợi gửi và bảng request đang chờ phản hồi.
- Giới hạn ban đầu: **64 kết nối**, kiểm thử với **20 client đồng thời**.

Nhóm phải tự xử lý partial read/write, nhiều message trong một lần đọc, message chưa đủ dữ liệu, client đọc chậm, EOF giữa message và dọn tài nguyên khi ngắt kết nối.

### Giao thức TCP `ELP/1`

Mỗi frame gồm:

```text
[4 byte độ dài body, big-endian][body JSON UTF-8]
```

Body tối đa **64 KiB**. Envelope thống nhất:

```json
{
  "v": 1,
  "kind": "REQUEST",
  "requestId": "UUID",
  "command": "LESSON_LIST",
  "payload": {
    "level": "ELEMENTARY",
    "topicId": 1
  }
}
```

- `kind`: `REQUEST`, `RESPONSE`, `EVENT`.
- Response giữ nguyên `requestId`, thêm `ok` và `error` nếu thất bại.
- Event dùng cho tin nhắn đến, lời mời gọi và thông báo đã chấm bài.
- Mã lỗi chung: `INVALID_MESSAGE`, `UNAUTHENTICATED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `SERVER_BUSY`.

Các nhóm lệnh phải đặc tả trong tài liệu giao thức:

| Nhóm | Lệnh chính |
|---|---|
| Tài khoản | `REGISTER`, `LOGIN`, `LOGOUT`, `ACCOUNT_APPROVE`, `LEVEL_SET` |
| Học tập | `TOPIC_LIST`, `LESSON_LIST`, `LESSON_GET`, `QUIZ_START`, `QUIZ_SUBMIT` |
| Bài tập/feedback | `EXERCISE_SUBMIT`, `SUBMISSION_LIST`, `GRADE_SUBMIT`, `RESULT_LIST` |
| Quản lý nội dung | `QUIZ_CREATE`, `QUIZ_PUBLISH`, `GAME_CREATE`, `GAME_PUBLISH` |
| Game | `GAME_LIST`, `GAME_START`, `GAME_SUBMIT` |
| File | `FILE_INFO`, `FILE_READ`, `UPLOAD_BEGIN`, `UPLOAD_CHUNK`, `UPLOAD_FINISH` |
| Chat/voice | `USER_LIST`, `CHAT_SEND`, `CHAT_HISTORY`, `CALL_INVITE`, `CALL_ACCEPT`, `CALL_REJECT`, `CALL_END` |
| Kết nối | `PING`, `PONG` |

File được chia thành chunk **32 KiB**, mã hóa Base64 trong payload. Server kiểm tra offset, kích thước và SHA-256 khi hoàn tất. Client dùng `fileId`, không gửi đường dẫn tùy ý trên server.

Video/audio được tải đầy đủ về cache rồi phát bằng JavaFX từ file cục bộ. Chọn MP4 H.264/AAC và WAV PCM, kiểm thử trên cả hai hệ điều hành ngay tuần đầu. [Định dạng JavaFX Media hỗ trợ](https://openjfx.io/javadoc/21/javafx.media/javafx/scene/media/package-summary.html).

### Trạng thái, quyền và lỗi

- Kết nối: `DISCONNECTED → CONNECTED → AUTHENTICATED`.
- Tài khoản: `PENDING → ACTIVE`; chỉ tài khoản `ACTIVE` được đăng nhập.
- Vai trò và danh tính lấy từ session gắn với kết nối; server không tin role/user ID tự khai báo trong request.
- Một tài khoản có một phiên đăng nhập hoạt động. Ngắt kết nối giải phóng phiên; reconnect yêu cầu đăng nhập lại.
- Password lưu bằng PBKDF2 với salt ngẫu nhiên của JDK.
- Timeout request 10 giây; heartbeat mỗi 5 giây, đóng kết nối sau 20 giây không phản hồi.
- Sau timeout thao tác thay đổi dữ liệu, client đọc lại trạng thái. Các lệnh nộp bài, gửi chat và tạo nội dung có ID chống xử lý trùng.

### Gọi thoại qua UDP

- TCP điều khiển lời mời và vòng đời cuộc gọi.
- Âm thanh dùng **PCM 16-bit, mono, 16 kHz**, mỗi packet chứa 20 ms âm thanh.
- Java Sound chỉ thu/phát âm thanh; nhóm tự đóng gói và gửi UDP. [API thu âm của JDK](https://docs.oracle.com/en/java/javase/21/docs/api/java.desktop/javax/sound/sampled/TargetDataLine.html).
- Packet gồm version, loại packet, call ID, token từng người, sequence, timestamp và dữ liệu PCM.
- Client đăng ký địa chỉ UDP bằng token server cấp; server kiểm tra quyền tham gia rồi chuyển tiếp tới người còn lại.
- Bộ đệm phát khoảng 60 ms; bỏ gói trễ/trùng, chèn im lặng khi thiếu gói.
- Trạng thái: `IDLE → RINGING → CONNECTING → ACTIVE → ENDED`.
- Mỗi người có tối đa một cuộc gọi; lời mời hết hạn sau 30 giây. Mất kết nối điều khiển sẽ kết thúc cuộc gọi.

**Logging:** ghi từng message TCP và packet UDP nhận/gửi. Với file và âm thanh, ghi ID, sequence/offset và số byte; mật khẩu được che. Log chạy ở luồng riêng để không chặn vòng socket.

## 4. Phân công và lịch làm

| Thành viên | Trách nhiệm chính |
|---|---|
| **A — Server & protocol** | Codec dùng chung, server socket, tài khoản/quyền, database, chấm điểm, logging. |
| **B — Learning client** | JavaFX shell, lessons, quiz, exercises, games, màn teacher/admin. |
| **C — Communication & media** | Client transport, truyền file, media player, ghi âm, chat/voice và kiểm thử liên máy. |

A và C thống nhất giao thức trước; B xây màn hình theo message đã chốt. Mỗi tuần phải tích hợp một luồng thật từ GUI qua socket đến database.

| Thời gian năm 2026 | Kết quả phải đạt |
|---|---|
| **13–20/10** | Maven modules, codec, kết nối hai PC, log, đăng ký–duyệt–đăng nhập. Thử phát video và truyền âm thanh UDP tối thiểu trên Windows/Linux. Hoàn thành tài liệu review. |
| **21–27/10** | Danh sách bài học, lọc trình độ/chủ đề, truyền media, lesson player và đủ ba dạng quiz chạy xuyên suốt client–server. |
| **28/10–03/11** | Ba dạng exercise, upload bài nói, teacher chấm và learner xem kết quả; teacher tạo/phát hành quiz. |
| **04–10/11** | Các game, admin thêm hai loại game bắt buộc; chat trực tiếp và lịch sử. |
| **11–17/11** | Hoàn thiện cuộc gọi hai chiều, timeout/busy/reject; sửa lỗi tích hợp, kiểm thử tải file đồng thời chat/voice. |
| **18–23/11** | Đóng băng tính năng, kiểm thử đủ 14 tiêu chí, sửa lỗi, đóng gói Windows/Linux, quay video và tập demo. |
| **24/11** | Bản nộp gồm source, hướng dẫn chạy, đặc tả giao thức, báo cáo kiểm thử và bằng chứng demo. |

**Chuẩn bị review**

- Hoàn thành **3 slide giới thiệu đề tài trước 20/10**: nhóm và tên đề tài; người dùng/vấn đề; chức năng và mục tiêu.
- Chuẩn bị design review theo mốc sớm **21/10**; nếu nhóm thuộc lượt **28/10**, dùng thời gian còn lại để sửa và bổ sung demo.
- Bộ design review phải có: kiến trúc, vai trò/chức năng, định dạng message, bảng lệnh, state machine, luồng xử lý và sequence diagram.
- Chọn ba luồng để trình bày kỹ: đăng ký–duyệt–đăng nhập; làm quiz–nộp–chấm; mời gọi–truyền UDP–kết thúc.
- Xác nhận với giảng viên cách admin duyệt tài khoản và phạm vi thư viện phi mạng.

## 5. Kiểm thử và điều kiện hoàn thành

- **Protocol:** chia header/body thành nhiều lần gửi, gộp nhiều frame, sai JSON, vượt giới hạn, ngắt giữa frame, response đến cùng event.
- **Tài khoản/quyền:** trùng username, sai password, chưa duyệt, learner gửi lệnh admin/teacher, xem hoặc sửa bài của người khác.
- **Học tập:** đủ ba dạng quiz/exercise; đáp án biết trước cho điểm đúng; nộp trùng chỉ tạo một kết quả; sửa nội dung không đổi lịch sử.
- **Nội dung mới:** teacher tạo quiz và admin tạo game qua GUI; learner khác tải được ngay.
- **File/media:** kiểm tra checksum, upload dở, file hỏng, phát video/audio và ghi âm trên Windows/Linux.
- **Chat/voice:** hai chiều, nhiều người online, người nhận offline, busy/reject/timeout, mất gói UDP và ngắt mạng giữa cuộc gọi.
- **Tải:** 20 client; một client đọc chậm hoặc tải video không làm treo chat và giao diện.
- **Lưu trữ/log:** restart server vẫn còn tài khoản, nội dung, bài làm, feedback và chat; đối chiếu log với chuỗi thao tác demo.

Nghiệm thu kết nối trên ít nhất **hai PC vật lý khác nhau**. Buổi demo đầy đủ dùng **ba PC của nhóm**: một server, một learner client và một teacher/admin client, có tai nghe để thử thoại.

Dự án hoàn thành khi **cả 14 dòng của bảng 30 điểm đều có luồng hoạt động thật qua socket, dữ liệu lưu trên server và bằng chứng kiểm thử**.
