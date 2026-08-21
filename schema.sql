-- ============================================================
-- PT 고객관리 스키마 (Supabase / PostgreSQL)
-- Supabase 대시보드 > SQL Editor 에 통째로 붙여넣고 RUN
-- ============================================================

-- 1) 회원 -------------------------------------------------
create table if not exists public.crm_members (
  id          bigint generated always as identity primary key,
  uid         uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name        text not null,
  phone       text,
  trainer     text,
  memo        text,
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);

-- 2) 등록(결제) 1건 = 회차 묶음 --------------------------
create table if not exists public.crm_packages (
  id          bigint generated always as identity primary key,
  uid         uuid not null default auth.uid() references auth.users(id) on delete cascade,
  member_id   bigint not null references public.crm_members(id) on delete cascade,
  total       integer not null default 0,      -- 등록 회차
  price       integer not null default 0,      -- 결제 금액(원)
  method      text,                            -- 카드 / 현금 / 계좌
  start_date  date,
  expire_date date,
  memo        text,
  created_at  timestamptz not null default now()
);

-- 3) 예약 / 출결 ------------------------------------------
create table if not exists public.crm_bookings (
  id          bigint generated always as identity primary key,
  uid         uuid not null default auth.uid() references auth.users(id) on delete cascade,
  member_id   bigint not null references public.crm_members(id) on delete cascade,
  start_at    timestamptz not null,
  end_at      timestamptz not null,
  status      text not null default '예약',    -- 예약 | 완료 | 노쇼
  gcal_id     text,                            -- 구글 캘린더 event id
  memo        text,
  created_at  timestamptz not null default now()
);

create index if not exists crm_members_uid_idx   on public.crm_members(uid);
create index if not exists crm_packages_mem_idx  on public.crm_packages(member_id);
create index if not exists crm_bookings_mem_idx  on public.crm_bookings(member_id);
create index if not exists crm_bookings_start_idx on public.crm_bookings(start_at);
create unique index if not exists crm_bookings_gcal_idx on public.crm_bookings(gcal_id) where gcal_id is not null;

-- 4) RLS: 로그인한 본인 데이터만 --------------------------
alter table public.crm_members  enable row level security;
alter table public.crm_packages enable row level security;
alter table public.crm_bookings enable row level security;

drop policy if exists own_crm_members  on public.crm_members;
drop policy if exists own_crm_packages on public.crm_packages;
drop policy if exists own_crm_bookings on public.crm_bookings;

create policy own_crm_members  on public.crm_members
  for all using (uid = auth.uid()) with check (uid = auth.uid());
create policy own_crm_packages on public.crm_packages
  for all using (uid = auth.uid()) with check (uid = auth.uid());
create policy own_crm_bookings on public.crm_bookings
  for all using (uid = auth.uid()) with check (uid = auth.uid());
