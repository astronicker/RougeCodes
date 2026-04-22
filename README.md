# Rouge Codes learning App (Flutter + Firebase)

A modern Learning app built with **Flutter**, **Firebase Firestore**, and **Provider** for state management.  
This app helps manage batches, students, schedules, and resources in a clean and scalable way.

---

## 🚀 Features

- 📦 Create batches with:
    - Day selection (Mon–Sun)
    - Start & End time
- 👨‍🎓 Assign multiple students from users collection
- 🔗 Add multiple links/resources to batches
- 📊 Real-time dashboard (Upcoming, Live, Completed)
- 👥 Batch-wise student management
- 🔥 Firestore real-time updates
- 🧠 Provider based state management

---

## 🏗️ Project Structure
```bash
lib/
├── core
│   ├── models
│   │   ├── app_user.dart
│   │   └── batch_models.dart
│   └── providers
│       ├── navigation_provider.dart
│       └── session_provider.dart
├── firebase_options.dart
├── home
│   ├── home.dart
│   └── provider
│       └── batch_provider.dart
├── layout
│   ├── alert_dialog.dart
│   └── main_layout.dart
├── main.dart
├── pages
│   ├── authentication
│   │   └── login.dart
│   └── welcome.dart
├── services
│   ├── batch_service.dart
│   └── student_service.dart
├── students
│   ├── provider
│   │   └── student_provider.dart
│   └── students.dart
└── users
    └── user_dashboard_page.dart
```
---

## 🗂️ Firestore Database Design

### 🔹 `batches` Collection
``` bash
batches/
├── name: ""
├── days: [""]
├── schedule: ""
├── startAt: Timestamp
├── endAt: Timestamp
├── startHour: 12:00
├── startMinute: 0
├── endHour: 12:00
├── endMinute: 0
├── enrollmentCount: 1
├── resources: []
├── createdAt: Timestamp
├── updatedAt: Timestamp
```
---

### 🔹 `batch_enrollments` Collection
```bash
batch_enrollments/
├── batchId: ""
├── batchName: ""
├── userId: ""
├── userName: ""
├── userEmail: ""
├── createdAt: Timestamp
├── updatedAt: Timestamp
```
---

### 🔹 `users` Collection
```bash
users/
├── uid: ""
├── name: ""
├── email: ""
├── role: ""
├── activeBatchIds: []
├── attendancePresentCount: 1
├── attendanceAbsentCount: 0
├── attendanceRate: 100
├── isArchived: true
├── createdAt: Timestamp
├── updatedAt: Timestamp
```
---

#### 📍 Subcollection: `attendance`
```bash
users/{userId}/attendance/
├── date
├── status (present/absent)
```

---

## 🧠 State Management

This project uses **Provider** for scalable and reactive state handling.

### Providers Used:
- `BatchProvider` → Batch logic & stats
- `StudentProvider` → Student management
- `SessionProvider` → Auth/session handling
- `NavigationProvider` → App navigation state

---

## ⚙️ Services Layer

All Firestore logic is separated into services:

### `BatchService`
- Create batch
- Delete batch
- Assign students
- Add links/resources
- Fetch batches

### `StudentService`
- Manage student data
- Attendance handling (extendable)

---

## 📱 UI Overview

- Material 3 based clean UI
- Bottom sheets for:
    - Create batch
    - Manage students
    - Add links
- Multi select user assignment
- Real time updates with StreamBuilder
- Perform CRUD operations

---

## 🛠️ Tech Stack

- **Flutter**
- **Firebase Firestore**
- **Provider**

---

## ▶️ Getting Started
- git clone **https://github.com/astronicker/RougeCodes.git**
- cd RougeCodes
- flutter pub get
- flutter run

## 🔐 Firebase Setup
- Create Firebase project
- Enable Firestore
- Add google-services.json / GoogleService-Info.plist
- Configure firebase_options.dart

## 📌 Notes
- Designed for scalability
- Easily extendable for:
- Attendance tracking
- Notifications
- Payments
- Live classes integration

## 🔮 Future Improvements
- 📅 Attendance analytics dashboard
- 🔔 Batch-wise notifications (reminders, updates)
- 🔍 Search & filtering (batches, students, links)
- 📄 Pagination / lazy loading for large datasets
- 🔒 Move critical database operations to backend
- 🛡️ Firestore Security Rules hardening
- 🔑 Firebase Authentication enforcement
- 🧯 Error handling & monitoring