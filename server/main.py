import logging
from datetime import datetime, timedelta
from typing import List, Optional
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, EmailStr, Field
from passlib.context import CryptContext
from jose import JWTError, jwt
import asyncpg
from app.core.config import get_settings

settings = get_settings()
DATABASE_URL = settings.database_url
SECRET_KEY = settings.secret_key
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = settings.access_token_expire_minutes

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

app = FastAPI(title="Smart Class Routine & Tasks API", version="2.0.0")

db_pool: Optional[asyncpg.Pool] = None

@app.on_event("startup")
async def startup():
    global db_pool
    try:
        db_pool = await asyncpg.create_pool(DATABASE_URL)
    except Exception:
        logging.exception("Database connection failed")

@app.on_event("shutdown")
async def shutdown():
    if db_pool:
        await db_pool.close()

# --- Auth Helpers ---
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def create_refresh_token(subject: str) -> str:
    return create_access_token(
        {"sub": subject, "type": "refresh"},
        timedelta(days=settings.refresh_token_expire_days),
    )

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None or payload.get("type", "access") != "access":
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    async with db_pool.acquire() as conn:
        user = await conn.fetchrow("SELECT * FROM users WHERE email = $1", email)
        if user is None:
            raise credentials_exception
        return dict(user)

# --- Pydantic Models ---
class UserCreate(BaseModel):
    username: str = Field(min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)

class UserResponse(BaseModel):
    id: int
    username: str
    email: str

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str
    user: UserResponse


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=20)

class ClassroomCreate(BaseModel):
    name: str
    section: Optional[str] = None
    description: Optional[str] = None

class ClassroomResponse(BaseModel):
    id: int
    name: str
    section: Optional[str]
    description: Optional[str]
    owner_id: int
    invite_code: str
    role: str

class RoutineCreate(BaseModel):
    day_of_week: str
    subject: str
    start_time: str
    end_time: str
    room: Optional[str] = None
    instructor: Optional[str] = None

class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    priority: Optional[str] = "medium"
    status: Optional[str] = "pending"

class BusScheduleCreate(BaseModel):
    route_name: str
    departure_time: str
    arrival_time: str
    bus_number: Optional[str] = None
    pickup_point: Optional[str] = None

class CustomScheduleCreate(BaseModel):
    title: str
    event_time: datetime
    description: Optional[str] = None

class PersonalNoteUpdate(BaseModel):
    content: str

class PersonalModificationCreate(BaseModel):
    entity_type: str
    entity_id: int
    json_override: dict

class AlarmCreate(BaseModel):
    event_type: str
    event_id: int
    alarm_time: datetime
    sound: Optional[str] = "default_alarm"

# --- Endpoints ---

@app.post("/auth/register", response_model=Token)
async def register(user: UserCreate):
    async with db_pool.acquire() as conn:
        existing = await conn.fetchrow("SELECT id FROM users WHERE email = $1", user.email)
        if existing:
            raise HTTPException(status_code=400, detail="Email already registered")
        hashed_pw = get_password_hash(user.password)
        row = await conn.fetchrow(
            "INSERT INTO users (username, email, password_hash) VALUES ($1, $2, $3) RETURNING id, username, email",
            user.username, user.email, hashed_pw
        )
        user_res = dict(row)
        access_token = create_access_token(data={"sub": user_res["email"]}, expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
        return {
            "access_token": access_token,
            "refresh_token": create_refresh_token(user_res["email"]),
            "token_type": "bearer",
            "user": user_res,
        }

@app.post("/auth/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    async with db_pool.acquire() as conn:
        user = await conn.fetchrow("SELECT * FROM users WHERE email = $1", form_data.username)
        if not user or not verify_password(form_data.password, user["password_hash"]):
            raise HTTPException(status_code=400, detail="Incorrect email or password")
        user_res = {"id": user["id"], "username": user["username"], "email": user["email"]}
        access_token = create_access_token(data={"sub": user["email"]}, expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
        return {
            "access_token": access_token,
            "refresh_token": create_refresh_token(user_res["email"]),
            "token_type": "bearer",
            "user": user_res,
        }


@app.post("/auth/refresh", response_model=dict)
async def refresh_token(request: RefreshRequest):
    try:
        payload = jwt.decode(request.refresh_token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "refresh" or not payload.get("sub"):
            raise JWTError
        access_token = create_access_token(
            {"sub": payload["sub"]},
            timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
        )
        return {
            "access_token": access_token,
            "refresh_token": create_refresh_token(payload["sub"]),
            "token_type": "bearer",
        }
    except JWTError as error:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
        ) from error

@app.get("/classrooms", response_model=List[ClassroomResponse])
async def get_classrooms(current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        rows = await conn.fetch("""
            SELECT c.*, cm.role FROM classrooms c
            JOIN classroom_members cm ON c.id = cm.classroom_id
            WHERE cm.user_id = $1
        """, current_user["id"])
        return [dict(r) for r in rows]

@app.post("/classrooms", response_model=ClassroomResponse)
async def create_classroom(classroom: ClassroomCreate, current_user: dict = Depends(get_current_user)):
    import uuid
    invite_code = str(uuid.uuid4())[:8].upper()
    async with db_pool.acquire() as conn:
        async with conn.transaction():
            c_row = await conn.fetchrow(
                "INSERT INTO classrooms (name, section, description, owner_id, invite_code) VALUES ($1, $2, $3, $4, $5) RETURNING *",
                classroom.name, classroom.section, classroom.description, current_user["id"], invite_code
            )
            await conn.execute(
                "INSERT INTO classroom_members (classroom_id, user_id, role) VALUES ($1, $2, 'owner')",
                c_row["id"], current_user["id"]
            )
            res = dict(c_row)
            res["role"] = "owner"
            return res

@app.post("/classrooms/join")
async def join_classroom(invite_code: str, role: str = "viewer", current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        classroom = await conn.fetchrow("SELECT * FROM classrooms WHERE invite_code = $1", invite_code.upper())
        if not classroom:
            raise HTTPException(status_code=404, detail="Invalid invite code")
        
        existing = await conn.fetchrow(
            "SELECT * FROM classroom_members WHERE classroom_id = $1 AND user_id = $2",
            classroom["id"], current_user["id"]
        )
        if existing:
            raise HTTPException(status_code=400, detail="Already a member of this classroom")
        
        await conn.execute(
            "INSERT INTO classroom_members (classroom_id, user_id, role) VALUES ($1, $2, $3)",
            classroom["id"], current_user["id"], role
        )
        return {"message": "Successfully joined classroom", "classroom_id": classroom["id"]}

# Routines, Tasks, Bus, Custom schedules, Notes, Modifications, Alarms
@app.get("/classrooms/{classroom_id}/routines")
async def get_routines(classroom_id: int, current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM routines WHERE classroom_id = $1", classroom_id)
        return [dict(r) for r in rows]

@app.post("/classrooms/{classroom_id}/routines")
async def add_routine(classroom_id: int, routine: RoutineCreate, current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        member = await conn.fetchrow("SELECT role FROM classroom_members WHERE classroom_id = $1 AND user_id = $2", classroom_id, current_user["id"])
        if not member or member["role"] not in ["owner", "editor"]:
            raise HTTPException(status_code=403, detail="Permission denied")
        row = await conn.fetchrow(
            "INSERT INTO routines (classroom_id, day_of_week, subject, start_time, end_time, room, instructor, created_by) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *",
            classroom_id, routine.day_of_week, routine.subject, routine.start_time, routine.end_time, routine.room, routine.instructor, current_user["id"]
        )
        return dict(row)

@app.get("/classrooms/{classroom_id}/tasks")
async def get_tasks(classroom_id: int, current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM tasks WHERE classroom_id = $1", classroom_id)
        return [dict(r) for r in rows]

@app.post("/classrooms/{classroom_id}/tasks")
async def add_task(classroom_id: int, task: TaskCreate, current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        member = await conn.fetchrow("SELECT role FROM classroom_members WHERE classroom_id = $1 AND user_id = $2", classroom_id, current_user["id"])
        if not member or member["role"] not in ["owner", "editor"]:
            raise HTTPException(status_code=403, detail="Permission denied")
        row = await conn.fetchrow(
            "INSERT INTO tasks (classroom_id, title, description, due_date, priority, status, created_by) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *",
            classroom_id, task.title, task.description, task.due_date, task.priority, task.status, current_user["id"]
        )
        return dict(row)

@app.get("/classrooms/{classroom_id}/bus-schedules")
async def get_bus_schedules(classroom_id: int, current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM bus_schedules WHERE classroom_id = $1", classroom_id)
        return [dict(r) for r in rows]

@app.post("/classrooms/{classroom_id}/bus-schedules")
async def add_bus_schedule(classroom_id: int, bus: BusScheduleCreate, current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        member = await conn.fetchrow("SELECT role FROM classroom_members WHERE classroom_id = $1 AND user_id = $2", classroom_id, current_user["id"])
        if not member or member["role"] not in ["owner", "editor"]:
            raise HTTPException(status_code=403, detail="Permission denied")
        row = await conn.fetchrow(
            "INSERT INTO bus_schedules (classroom_id, route_name, departure_time, arrival_time, bus_number, pickup_point, created_by) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *",
            classroom_id, bus.route_name, bus.departure_time, bus.arrival_time, bus.bus_number, bus.pickup_point, current_user["id"]
        )
        return dict(row)

@app.get("/classrooms/{classroom_id}/custom-schedules")
async def get_custom_schedules(classroom_id: int, current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM custom_schedules WHERE classroom_id = $1", classroom_id)
        return [dict(r) for r in rows]

@app.post("/classrooms/{classroom_id}/custom-schedules")
async def add_custom_schedule(classroom_id: int, sched: CustomScheduleCreate, current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        member = await conn.fetchrow("SELECT role FROM classroom_members WHERE classroom_id = $1 AND user_id = $2", classroom_id, current_user["id"])
        if not member or member["role"] not in ["owner", "editor"]:
            raise HTTPException(status_code=403, detail="Permission denied")
        row = await conn.fetchrow(
            "INSERT INTO custom_schedules (classroom_id, title, event_time, description, created_by) VALUES ($1, $2, $3, $4, $5) RETURNING *",
            classroom_id, sched.title, sched.event_time, sched.description, current_user["id"]
        )
        return dict(row)

@app.get("/classrooms/{classroom_id}/notes")
async def get_personal_notes(classroom_id: int, current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        row = await conn.fetchrow("SELECT * FROM personal_notes WHERE classroom_id = $1 AND user_id = $2", classroom_id, current_user["id"])
        return dict(row) if row else {"content": ""}

@app.post("/classrooms/{classroom_id}/notes")
async def save_personal_notes(classroom_id: int, note: PersonalNoteUpdate, current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        row = await conn.fetchrow("""
            INSERT INTO personal_notes (classroom_id, user_id, content, updated_at)
            VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
            ON CONFLICT (classroom_id, user_id)
            DO UPDATE SET content = EXCLUDED.content, updated_at = CURRENT_TIMESTAMP
            RETURNING *
        """, classroom_id, current_user["id"], note.content)
        return dict(row)

@app.get("/classrooms/{classroom_id}/modifications")
async def get_personal_modifications(classroom_id: int, current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM personal_modifications WHERE classroom_id = $1 AND user_id = $2", classroom_id, current_user["id"])
        return [dict(r) for r in rows]

@app.post("/classrooms/{classroom_id}/modifications")
async def save_personal_modification(classroom_id: int, mod: PersonalModificationCreate, current_user: dict = Depends(get_current_user)):
    import json
    async with db_pool.acquire() as conn:
        row = await conn.fetchrow("""
            INSERT INTO personal_modifications (classroom_id, user_id, entity_type, entity_id, json_override, updated_at)
            VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
            ON CONFLICT (classroom_id, user_id, entity_type, entity_id)
            DO UPDATE SET json_override = EXCLUDED.json_override, updated_at = CURRENT_TIMESTAMP
            RETURNING *
        """, classroom_id, current_user["id"], mod.entity_type, mod.entity_id, json.dumps(mod.json_override))
        res = dict(row)
        return res

@app.get("/alarms", response_model=List[dict])
async def get_alarms(current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM alarms WHERE user_id = $1", current_user["id"])
        return [dict(r) for r in rows]

@app.post("/alarms", response_model=dict)
async def create_alarm(alarm: AlarmCreate, current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        row = await conn.fetchrow(
            "INSERT INTO alarms (user_id, event_type, event_id, alarm_time, is_enabled, sound) VALUES ($1, $2, $3, $4, TRUE, $5) RETURNING *",
            current_user["id"], alarm.event_type, alarm.event_id, alarm.alarm_time, alarm.sound
        )
        return dict(row)

@app.delete("/alarms/{alarm_id}")
async def delete_alarm(alarm_id: int, current_user: dict = Depends(get_current_user)):
    async with db_pool.acquire() as conn:
        await conn.execute("DELETE FROM alarms WHERE id = $1 AND user_id = $2", alarm_id, current_user["id"])
        return {"message": "Alarm deleted"}
