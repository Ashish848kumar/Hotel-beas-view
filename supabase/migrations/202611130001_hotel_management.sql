create extension if not exists pgcrypto;
create extension if not exists btree_gist;
create type public.staff_role as enum ('OWNER','FRONT_DESK','HOUSEKEEPING');
create type public.room_status as enum ('AVAILABLE','RESERVED','OCCUPIED','CLEANING','MAINTENANCE');
create type public.reservation_status as enum ('CONFIRMED','CANCELLED','CHECKED_IN','COMPLETED');

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '', role public.staff_role not null default 'FRONT_DESK',
 active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.rooms (
 id uuid primary key default gen_random_uuid(), room_number text not null unique,
 floor integer, room_type text, layout_x integer, layout_y integer,
 status public.room_status not null default 'AVAILABLE', active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check (layout_x is null or layout_x >= 0), check (layout_y is null or layout_y >= 0)
);
insert into public.rooms(room_number) select 'Room '||lpad(n::text,2,'0') from generate_series(1,30) n;
create table public.guests (
 id uuid primary key default gen_random_uuid(), full_name text not null check(length(trim(full_name)) between 1 and 200),
 mobile text not null check(length(trim(mobile)) between 5 and 30), email text, address text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.reservations (
 id uuid primary key default gen_random_uuid(), booking_reference text not null unique default upper(encode(gen_random_bytes(5),'hex')),
 room_id uuid not null references public.rooms(id), guest_id uuid not null references public.guests(id),
 arrival_date date not null, departure_date date not null, number_of_guests integer not null default 1 check(number_of_guests between 1 and 30),
 status public.reservation_status not null default 'CONFIRMED', notes text,
 created_by uuid references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(departure_date > arrival_date),
 exclude using gist (room_id with =, daterange(arrival_date,departure_date,'[)') with &&) where (status in ('CONFIRMED','CHECKED_IN'))
);
create table public.stays (
 id uuid primary key default gen_random_uuid(), reservation_id uuid unique references public.reservations(id),
 room_id uuid not null references public.rooms(id), guest_id uuid not null references public.guests(id),
 actual_checkin timestamptz not null default now(), actual_checkout timestamptz,
 checkin_by uuid references public.profiles(id), checkout_by uuid references public.profiles(id),
 created_at timestamptz not null default now(), check(actual_checkout is null or actual_checkout >= actual_checkin)
);
create unique index one_open_stay_per_room on public.stays(room_id) where actual_checkout is null;
create table public.housekeeping_tasks (
 id uuid primary key default gen_random_uuid(), room_id uuid not null references public.rooms(id),
 assigned_to uuid references public.profiles(id), status text not null default 'PENDING' check(status in ('PENDING','IN_PROGRESS','DONE')),
 notes text, created_at timestamptz not null default now(), completed_at timestamptz
);
create table public.audit_logs (
 id bigint generated always as identity primary key, actor_id uuid references public.profiles(id),
 action text not null, entity_type text not null, entity_id uuid, details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);

create function public.current_role() returns public.staff_role language sql stable security definer set search_path=public as $$
 select role from public.profiles where id=auth.uid() and active=true
$$;
create function public.has_role(roles public.staff_role[]) returns boolean language sql stable security definer set search_path=public as $$
 select coalesce(public.current_role()=any(roles),false)
$$;
revoke all on function public.current_role() from public;
grant execute on function public.current_role() to authenticated;
revoke all on function public.has_role(public.staff_role[]) from public;
grant execute on function public.has_role(public.staff_role[]) to authenticated;

alter table public.profiles enable row level security;
alter table public.rooms enable row level security;
alter table public.guests enable row level security;
alter table public.reservations enable row level security;
alter table public.stays enable row level security;
alter table public.housekeeping_tasks enable row level security;
alter table public.audit_logs enable row level security;

create policy profile_self_read on public.profiles for select to authenticated using(id=auth.uid() or public.has_role(array['OWNER']::public.staff_role[]));
create policy profile_owner_update on public.profiles for update to authenticated using(public.has_role(array['OWNER']::public.staff_role[])) with check(public.has_role(array['OWNER']::public.staff_role[]));
create policy rooms_read_staff on public.rooms for select to authenticated using(public.has_role(array['OWNER','FRONT_DESK','HOUSEKEEPING']::public.staff_role[]));
create policy rooms_owner_write on public.rooms for all to authenticated using(public.has_role(array['OWNER']::public.staff_role[])) with check(public.has_role(array['OWNER']::public.staff_role[]));
create policy rooms_housekeeping_status on public.rooms for update to authenticated using(public.has_role(array['HOUSEKEEPING']::public.staff_role[])) with check(public.has_role(array['HOUSEKEEPING']::public.staff_role[]));
create policy guest_read_frontdesk_owner on public.guests for select to authenticated using(public.has_role(array['OWNER','FRONT_DESK']::public.staff_role[]));
create policy guest_write_frontdesk_owner on public.guests for all to authenticated using(public.has_role(array['OWNER','FRONT_DESK']::public.staff_role[])) with check(public.has_role(array['OWNER','FRONT_DESK']::public.staff_role[]));
create policy reservations_read_frontdesk_owner on public.reservations for select to authenticated using(public.has_role(array['OWNER','FRONT_DESK']::public.staff_role[]));
create policy reservations_write_frontdesk_owner on public.reservations for all to authenticated using(public.has_role(array['OWNER','FRONT_DESK']::public.staff_role[])) with check(public.has_role(array['OWNER','FRONT_DESK']::public.staff_role[]));
create policy stays_read_frontdesk_owner on public.stays for select to authenticated using(public.has_role(array['OWNER','FRONT_DESK']::public.staff_role[]));
create policy stays_write_frontdesk_owner on public.stays for all to authenticated using(public.has_role(array['OWNER','FRONT_DESK']::public.staff_role[])) with check(public.has_role(array['OWNER','FRONT_DESK']::public.staff_role[]));
create policy task_staff_read on public.housekeeping_tasks for select to authenticated using(public.has_role(array['OWNER','FRONT_DESK','HOUSEKEEPING']::public.staff_role[]));
create policy task_owner_write on public.housekeeping_tasks for all to authenticated using(public.has_role(array['OWNER']::public.staff_role[])) with check(public.has_role(array['OWNER']::public.staff_role[]));
create policy task_housekeeping_update on public.housekeeping_tasks for update to authenticated using(public.has_role(array['HOUSEKEEPING']::public.staff_role[])) with check(public.has_role(array['HOUSEKEEPING']::public.staff_role[]));
create policy audit_owner_read on public.audit_logs for select to authenticated using(public.has_role(array['OWNER']::public.staff_role[]));
create policy audit_staff_insert on public.audit_logs for insert to authenticated with check(actor_id=auth.uid());

create function public.set_room_status(p_room_id uuid,p_status public.room_status,p_reason text default null) returns void
language plpgsql security definer set search_path=public as $$
declare actor_role public.staff_role;
begin
 actor_role:=public.current_role();
 if actor_role is null then raise exception 'Authentication required'; end if;
 if actor_role='HOUSEKEEPING' and p_status not in ('CLEANING','AVAILABLE','MAINTENANCE') then raise exception 'Permission denied'; end if;
 if actor_role not in ('OWNER','HOUSEKEEPING') then raise exception 'Permission denied'; end if;
 if p_status='AVAILABLE' and exists(select 1 from public.stays where room_id=p_room_id and actual_checkout is null) then raise exception 'Room has an open stay'; end if;
 update public.rooms set status=p_status,updated_at=now() where id=p_room_id and active;
 if not found then raise exception 'Room not found'; end if;
 insert into public.audit_logs(actor_id,action,entity_type,entity_id,details) values(auth.uid(),'ROOM_STATUS_CHANGED','room',p_room_id,jsonb_build_object('status',p_status,'reason',p_reason));
end $$;
revoke all on function public.set_room_status(uuid,public.room_status,text) from public;
grant execute on function public.set_room_status(uuid,public.room_status,text) to authenticated;

create function public.check_in(p_reservation_id uuid) returns uuid language plpgsql security definer set search_path=public as $$
declare r public.reservations; new_stay uuid;
begin
 if not public.has_role(array['OWNER','FRONT_DESK']::public.staff_role[]) then raise exception 'Permission denied'; end if;
 select * into r from public.reservations where id=p_reservation_id for update;
 if not found or r.status<>'CONFIRMED' then raise exception 'Reservation is not available for check-in'; end if;
 if exists(select 1 from public.stays where room_id=r.room_id and actual_checkout is null) then raise exception 'Room is occupied'; end if;
 insert into public.stays(reservation_id,room_id,guest_id,checkin_by) values(r.id,r.room_id,r.guest_id,auth.uid()) returning id into new_stay;
 update public.reservations set status='CHECKED_IN',updated_at=now() where id=r.id;
 update public.rooms set status='OCCUPIED',updated_at=now() where id=r.room_id;
 insert into public.audit_logs(actor_id,action,entity_type,entity_id,details) values(auth.uid(),'CHECK_IN','stay',new_stay,jsonb_build_object('room_id',r.room_id,'reservation_id',r.id));
 return new_stay;
end $$;
revoke all on function public.check_in(uuid) from public;
grant execute on function public.check_in(uuid) to authenticated;

create function public.check_out(p_stay_id uuid) returns void language plpgsql security definer set search_path=public as $$
declare s public.stays;
begin
 if not public.has_role(array['OWNER','FRONT_DESK']::public.staff_role[]) then raise exception 'Permission denied'; end if;
 select * into s from public.stays where id=p_stay_id for update;
 if not found or s.actual_checkout is not null then raise exception 'Stay is not open'; end if;
 update public.stays set actual_checkout=now(),checkout_by=auth.uid() where id=s.id;
 update public.rooms set status='CLEANING',updated_at=now() where id=s.room_id;
 update public.reservations set status='COMPLETED',updated_at=now() where id=s.reservation_id;
 insert into public.audit_logs(actor_id,action,entity_type,entity_id,details) values(auth.uid(),'CHECK_OUT','stay',s.id,jsonb_build_object('room_id',s.room_id));
 insert into public.housekeeping_tasks(room_id) values(s.room_id);
end $$;
revoke all on function public.check_out(uuid) from public;
grant execute on function public.check_out(uuid) to authenticated;
