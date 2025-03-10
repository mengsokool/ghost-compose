# Ghost CMS พร้อม Docker Compose

โปรเจกต์นี้จัดเตรียมวิธีการติดตั้ง Ghost CMS อย่างง่ายและอัตโนมัติ โดยใช้ Docker Compose, Nginx และ Let's Encrypt สำหรับใบรับรอง SSL

## สิ่งที่ต้องมี

* เซิร์ฟเวอร์ที่รัน Linux
* ชื่อโดเมนที่จดทะเบียนแล้ว
* สิทธิ์ root บนเซิร์ฟเวอร์
* ติดตั้ง Docker และ Docker Compose แล้ว

## การติดตั้ง

1. **โคลน repository:**

   **Bash**

   ```
   git clone https://github.com/mengsokool/ghost-compose.git
   cd ghost-compose
   ```

2. **รันสคริปต์การติดตั้ง:**

   **Bash**

   ```
   sudo ./setup.sh
   ```

   สคริปต์จะ:

   * ตรวจสอบให้แน่ใจว่า Docker และ Docker Compose ติดตั้งแล้ว
   * ถามชื่อโดเมนและที่อยู่อีเมลของคุณ
   * ถามรหัสผ่าน root ของ MySQL และรหัสผ่านฐานข้อมูล Ghost (พร้อมค่าเริ่มต้น)
   * สร้างไดเร็กทอรีที่จำเป็นและไฟล์ `docker-compose.yml`
   * สร้างไฟล์การกำหนดค่า Nginx
   * รับใบรับรอง SSL จาก Let's Encrypt
   * เริ่มคอนเทนเนอร์ Docker
3. **เข้าถึง Ghost CMS ของคุณ:**
   เมื่อสคริปต์เสร็จสมบูรณ์ คุณสามารถเข้าถึง Ghost CMS ของคุณได้ที่ `https://ชื่อ-โดเมน-ของคุณ.com`

## รายละเอียดสคริปต์

สคริปต์ `setup.sh` จะทำงานต่อไปนี้โดยอัตโนมัติ:

* **การตรวจสอบ Root:** ตรวจสอบให้แน่ใจว่าสคริปต์รันด้วยสิทธิ์ root
* **การติดตั้ง Docker:** ติดตั้ง Docker และ Docker Compose หากยังไม่ได้ติดตั้ง
* **การตรวจสอบอินพุต:** ตรวจสอบว่ามีการระบุโดเมนและอีเมล
* **การตรวจสอบเวอร์ชัน Docker Compose:** ตรวจสอบคำสั่ง docker compose ทั้งรุ่นเก่าและรุ่นใหม่
* **การสร้างไดเร็กทอรี:** สร้างไดเร็กทอรีสำหรับการกำหนดค่า Nginx, ใบรับรอง SSL, ข้อมูล MySQL และเนื้อหา Ghost
* **การกำหนดค่า Docker Compose:** สร้างไฟล์ `docker-compose.yml` เพื่อกำหนดบริการ (Ghost, MySQL, Nginx, Certbot)
* **การกำหนดค่า Nginx:** สร้างไฟล์การกำหนดค่า Nginx เพื่อจัดการการรับส่งข้อมูล HTTP และ HTTPS รวมถึงการจัดการใบรับรอง SSL
* **การสร้างใบรับรอง SSL:** ใช้ Certbot เพื่อรับและต่ออายุใบรับรอง SSL จาก Let's Encrypt
* **การปรับใช้ Docker Compose:** เริ่มคอนเทนเนอร์ Docker โดยใช้ `docker-compose up -d`

## การกำหนดค่า

* **โดเมนและอีเมล:** คุณจะได้รับแจ้งให้ป้อนชื่อโดเมนและที่อยู่อีเมลของคุณระหว่างกระบวนการติดตั้ง
* **รหัสผ่าน MySQL และ Ghost:** คุณสามารถปรับแต่งรหัสผ่าน root ของ MySQL และรหัสผ่านฐานข้อมูล Ghost ได้ระหว่างการติดตั้ง มีค่าเริ่มต้นให้
* **Docker Compose:** สามารถแก้ไขไฟล์ `docker-compose.yml` เพื่อปรับแต่งบริการและการกำหนดค่า
* **Nginx:** สามารถแก้ไขไฟล์การกำหนดค่า Nginx ในไดเร็กทอรี `nginx/conf.d` เพื่อปรับแต่งการตั้งค่าเว็บเซิร์ฟเวอร์

## การอัปเดตใบรับรอง SSL

คอนเทนเนอร์ Certbot ได้รับการกำหนดค่าให้ต่ออายุใบรับรอง SSL โดยอัตโนมัติทุก 6 ชั่วโมง

## การแก้ไขปัญหา

* **สิทธิ์:** ตรวจสอบให้แน่ใจว่าสคริปต์ถูกดำเนินการด้วยสิทธิ์ root
* **การกำหนดค่าโดเมน:** ตรวจสอบว่าระเบียน DNS ของโดเมนของคุณชี้ไปที่ที่อยู่ IP ของเซิร์ฟเวอร์ของคุณ
* **ไฟร์วอลล์:** ตรวจสอบให้แน่ใจว่าพอร์ต 80 และ 443 เปิดอยู่บนไฟร์วอลล์ของเซิร์ฟเวอร์ของคุณ
* **บันทึก Docker:** ตรวจสอบบันทึกคอนเทนเนอร์ Docker เพื่อหาข้อผิดพลาด:

  **Bash**

  ```
  sudo docker logs <ชื่อ-คอนเทนเนอร์>
  ```

  (แทนที่ `<ชื่อ-คอนเทนเนอร์>` ด้วยชื่อคอนเทนเนอร์จริง)

## การสนับสนุน

อย่าลังเลที่จะสนับสนุนโปรเจกต์นี้โดยส่ง pull requests หรือเปิด issues

## ลิขสิทธิ์

โปรเจกต์นี้ได้รับอนุญาตภายใต้ MIT License.

## ผู้เขียน

* Gemini 2.0 Flash