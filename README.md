# Smart Class Routine & Tasks Management System

A high-performance, scalable Smart Class Routine and Tasks Management System built with **Flutter** (Frontend) and **PostgreSQL + FastAPI** (Backend).

## Features

- **Classrooms Management:** Create classrooms or join via invite codes.
- **Collaborator & Viewer Roles:** Owners can add editor collaborators; fellow classmates can join as viewers.
- **Comprehensive Schedules:**
  - Class Routines (Days, Times, Rooms, Instructors)
  - Tasks & Assignments (Priorities, Due Dates, Status tracking)
  - Bus Schedules (Routes, Departure/Arrival times, Pickup points)
  - Custom Schedules / Events
- **Dynamic Alarm Systems:** Per-user alarm configuration and local notifications.
- **Personal Notes & Modifications:** Every user can add private notes and personal overrides that do not affect others.

---

## Getting Started

### 1. Database Setup (PostgreSQL)
Ensure PostgreSQL is installed and running. Create a database named `classapp`:
```sql
CREATE DATABASE classapp;
```
Execute the schema setup script located at `server/schema.sql`:
```bash
psql -U postgres -d classapp -f server/schema.sql
```

### 2. Backend Setup (FastAPI)
Navigate to the `server` directory, install dependencies, and run the FastAPI server:
```bash
cd server
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 3. Flutter App Setup
Ensure Flutter SDK is installed. Navigate to the project root directory:
```bash
flutter pub get
flutter run
```
