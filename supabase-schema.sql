-- ============================================================
-- BUILD QLDA — Supabase schema
-- Chạy toàn bộ file này trong Supabase Dashboard → SQL Editor → New query → Run
-- ============================================================

-- 1. Bảng hồ sơ người dùng (mở rộng auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text default 'Quản lý dự án',
  created_at timestamptz default now()
);

-- Tự động tạo profile khi có user mới đăng ký
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', new.email));
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 2. Bảng dự án
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  investor text,
  start_date date,
  end_date_planned date,
  total_budget numeric default 0,
  status text default 'on_track',        -- on_track | warning | danger
  progress_percent int default 0,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

-- 3. Bảng hạng mục công việc (WBS) — dùng cho tab Tiến độ
create table if not exists public.wbs_items (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references public.projects(id) on delete cascade,
  name text not null,
  planned_percent int default 0,
  actual_percent int default 0,
  sort_order int default 0,
  created_at timestamptz default now()
);

-- 4. Bảng giao dịch thu / chi — dùng cho tab Dòng tiền
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references public.projects(id) on delete cascade,
  type text check (type in ('thu','chi')) not null,
  category text,
  description text,
  amount numeric not null,
  txn_date date default current_date,
  status text default 'cho_duyet',       -- cho_duyet | da_duyet | tu_choi
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

-- ============================================================
-- Row Level Security — mọi user đã đăng nhập đều xem/sửa được
-- (phù hợp cho MVP nội bộ; siết chặt hơn theo vai trò ở bước sau)
-- ============================================================
alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.wbs_items enable row level security;
alter table public.transactions enable row level security;

create policy "profiles_select" on public.profiles for select using (auth.role() = 'authenticated');
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id);

create policy "projects_select" on public.projects for select using (auth.role() = 'authenticated');
create policy "projects_insert" on public.projects for insert with check (auth.role() = 'authenticated');
create policy "projects_update" on public.projects for update using (auth.role() = 'authenticated');

create policy "wbs_select" on public.wbs_items for select using (auth.role() = 'authenticated');
create policy "wbs_insert" on public.wbs_items for insert with check (auth.role() = 'authenticated');
create policy "wbs_update" on public.wbs_items for update using (auth.role() = 'authenticated');

create policy "txn_select" on public.transactions for select using (auth.role() = 'authenticated');
create policy "txn_insert" on public.transactions for insert with check (auth.role() = 'authenticated');
create policy "txn_update" on public.transactions for update using (auth.role() = 'authenticated');

-- ============================================================
-- Dữ liệu mẫu (giống bản demo tĩnh) — để test ngay sau khi kết nối
-- ============================================================
insert into public.projects (name, investor, total_budget, status, progress_percent)
values
  ('Chung cư Riverside', 'CĐT An Phát', 42000, 'on_track', 78),
  ('Nhà máy Long Thành', 'CĐT Kim Long', 68000, 'warning', 45),
  ('Khu đô thị Sunrise', 'CĐT Sunrise Group', 25000, 'on_track', 92),
  ('Trung tâm thương mại Central', 'CĐT Central Retail', 51000, 'danger', 31);

-- Hạng mục WBS cho dự án Riverside
insert into public.wbs_items (project_id, name, planned_percent, actual_percent, sort_order)
select id, x.name, x.planned, x.actual, x.ord
from public.projects, (values
  ('Móng & kết cấu ngầm', 100, 100, 1),
  ('Kết cấu bê tông cốt thép', 90, 82, 2),
  ('Xây tô & hoàn thiện thô', 65, 48, 3),
  ('Cơ điện (M&E)', 40, 22, 4),
  ('Hoàn thiện nội thất', 15, 5, 5)
) as x(name, planned, actual, ord)
where public.projects.name = 'Chung cư Riverside';

-- Giao dịch mẫu cho dự án Riverside
insert into public.transactions (project_id, type, category, description, amount, status, txn_date)
select id, x.type, x.category, x.descr, x.amount, x.status, x.d::date
from public.projects, (values
  ('chi','Vật tư','Thanh toán vật tư thép - đợt 3', 1250, 'da_duyet', '2026-07-12'),
  ('thu','Thanh toán CĐT','CĐT thanh toán đợt 4', 4200, 'da_duyet', '2026-07-11'),
  ('chi','Nhân công','Tạm ứng nhà thầu phụ cơ điện', 860, 'cho_duyet', '2026-07-10'),
  ('chi','Nhân công','Chi phí nhân công tháng 6', 2100, 'da_duyet', '2026-07-09')
) as x(type, category, descr, amount, status, d)
where public.projects.name = 'Chung cư Riverside';
