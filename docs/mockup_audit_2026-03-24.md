# Mockup Audit (March 24, 2026)

## สถานะโดยรวม
- โครงสร้างแอปหลักพร้อมใช้งานจริงในหลายฟีเจอร์: auth, feed, chat queue/matching, profile update, daily mood
- ยังมีบางหน้าที่ใช้ข้อมูลจำลอง (mock/hardcoded) หรือสถานะในหน่วยความจำ (ยังไม่ persist)

## จุดที่ยังเป็น Mockup ชัดเจน

### 1) Favorites
- ไฟล์: `lib/features/setting/data/mock/favorite_items_mock.dart`
- สถานะ: ใช้รายการตัวอย่างแบบ hardcoded ทั้งหมด (ข้อความ, วันที่, รูป)
- ความเสี่ยง: ข้อมูลไม่ sync ตามผู้ใช้จริง

### 2) Home Articles
- ไฟล์: `lib/features/home/data/mock/home_articles_mock.dart`
- สถานะ: บทความยังเป็น static content จาก assets
- ความเสี่ยง: ไม่มีระบบจัดการคอนเทนต์หลังบ้าน

### 3) Shop Catalog
- ไฟล์: `lib/features/shop/data/mock/shop_items_mock.dart`
- สถานะ: รายการสินค้าและราคายัง hardcoded
- ความเสี่ยง: ปรับราคา/เพิ่มสินค้าแบบ runtime ไม่ได้

### 4) Conversation Summary Partner
- ไฟล์: `lib/features/chat/data/mock/conversation_partner_mock.dart`
- สถานะ: ชื่อและรูปคู่สนทนาในหน้าสรุปยังเป็นค่า mock
- ความเสี่ยง: แสดงข้อมูลไม่ตรงผู้ใช้จริง

### 5) Pet / Shop State Persistence
- ไฟล์หลัก: `lib/features/pet/view/pet_view.dart`, `lib/features/shop/view/shop_view.dart`
- สถานะ: coins/ownedItems/energy เป็น state ใน memory ผ่าน GetX
- ความเสี่ยง: ปิดแอปแล้วข้อมูลหาย, ไม่ sync ข้ามอุปกรณ์

### 6) Widget Test
- ไฟล์: `test/widget_test.dart`
- สถานะ: ยังเป็น placeholder test
- ความเสี่ยง: coverage ต่ำ, regression จับยาก

## จุดที่ค่อนข้าง Production-ready
- `feed_repository.dart`: เชื่อม Supabase posts/media/reactions และมี moderation
- `home_video_repository.dart`: เชื่อม post media (video) และ upload storage
- `chat_user_service.dart`: realtime chat + queue matching ผ่าน Firestore
- `edit_profile_page.dart`: update profile + auth metadata

## สิ่งที่ควรทำต่อ (เรียงลำดับ)
1. แทนที่ Favorites mock ด้วย table จริง (เช่น `favorites`)
2. แทนที่ conversation summary mock ด้วย profile จาก backend
3. Persist state ของ pet/shop ลง Supabase (coins, inventory, equipped)
4. ย้ายบทความ Home ไป CMS หรือ table บน Supabase
5. เพิ่ม widget/unit tests แบบใช้งานจริง
