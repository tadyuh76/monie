create table public.groups (
  group_id uuid not null default extensions.uuid_generate_v4 (),
  admin_id uuid null,
  name character varying(100) not null,
  description text null,
  is_settled boolean null,
  constraint groups_pkey primary key (group_id),
  constraint groups_admin_id_fkey foreign KEY (admin_id) references users (user_id) on delete set null
) TABLESPACE pg_default;

create table public.accounts (
  account_id uuid not null default extensions.uuid_generate_v4 (),
  user_id uuid not null,
  name character varying(100) not null,
  type character varying(30) not null,
  balance numeric(15, 2) null default 0,
  currency character varying(3) null default 'USD'::character varying,
  color character varying(20) null,
  archived boolean null default false,
  pinned boolean null default false,
  constraint accounts_pkey primary key (account_id),
  constraint accounts_user_id_fkey foreign KEY (user_id) references users (user_id) on delete CASCADE
) TABLESPACE pg_default;

create table public.budgets (
  budget_id uuid not null default extensions.uuid_generate_v4 (),
  user_id uuid not null,
  name character varying(100) not null,
  amount numeric(15, 2) not null,
  start_date date not null,
  end_date date null,
  is_recurring boolean null default false,
  is_saving boolean null default false,
  frequency character varying(20) null,
  color character varying(20) null,
  constraint budgets_pkey primary key (budget_id),
  constraint budgets_user_id_fkey foreign KEY (user_id) references users (user_id) on delete CASCADE
) TABLESPACE pg_default;

create table public.group_members (
  group_id uuid not null,
  user_id uuid not null,
  role character varying(30) null default 'member'::character varying,
  constraint group_members_pkey primary key (group_id, user_id),
  constraint group_members_group_id_fkey foreign KEY (group_id) references groups (group_id) on delete CASCADE,
  constraint group_members_user_id_fkey foreign KEY (user_id) references users (user_id) on delete CASCADE
) TABLESPACE pg_default;

create table public.group_transactions (
  group_transaction_id uuid not null default extensions.uuid_generate_v4 (),
  group_id uuid not null,
  transaction_id uuid not null,
  status character varying(30) null default 'pending'::character varying,
  approved_at timestamp with time zone null,
  constraint group_transactions_pkey primary key (group_transaction_id),
  constraint group_transactions_group_id_fkey foreign KEY (group_id) references groups (group_id) on delete CASCADE,
  constraint group_transactions_transaction_id_fkey foreign KEY (transaction_id) references transactions (transaction_id) on delete CASCADE
) TABLESPACE pg_default;

create table public.notifications (
  notification_id uuid not null default gen_random_uuid (),
  user_id uuid not null,
  amount numeric(15, 2) null,
  type text not null,
  title text not null,
  message text null,
  is_read boolean null default false,
  created_at timestamp with time zone null default timezone ('utc'::text, now()),
  constraint notifications_pkey primary key (notification_id),
  constraint notifications_user_id_fkey foreign KEY (user_id) references users (user_id) on delete CASCADE,
  constraint notifications_type_check check (
    (
      type = any (
        array[
          'group_transaction'::text,
          'group_settlement'::text,
          'budget_alert'::text,
          'general'::text
        ]
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_notifications_user_id on public.notifications using btree (user_id) TABLESPACE pg_default;

create index IF not exists idx_notifications_created_at on public.notifications using btree (created_at desc) TABLESPACE pg_default;

create index IF not exists idx_notifications_is_read on public.notifications using btree (is_read) TABLESPACE pg_default;

create index IF not exists idx_notifications_user_unread on public.notifications using btree (user_id, is_read) TABLESPACE pg_default
where
  (is_read = false);

create table public.transactions (
  transaction_id uuid not null default extensions.uuid_generate_v4 (),
  account_id uuid null,
  budget_id uuid null,
  user_id uuid not null,
  amount numeric(15, 2) not null,
  date timestamp with time zone null default CURRENT_TIMESTAMP,
  title character varying(255) null,
  description text null,
  category_name character varying(100) null,
  color character varying(30) null,
  is_recurring boolean null default false,
  receipt_url character varying(255) null,
  constraint transactions_pkey primary key (transaction_id),
  constraint transactions_account_id_fkey foreign KEY (account_id) references accounts (account_id) on delete set null,
  constraint transactions_budget_id_fkey foreign KEY (budget_id) references budgets (budget_id) on delete set null,
  constraint transactions_user_id_fkey foreign KEY (user_id) references users (user_id) on delete CASCADE
) TABLESPACE pg_default;

create table public.users (
  user_id uuid not null default extensions.uuid_generate_v4 (),
  email character varying(100) not null,
  display_name character varying(50) null,
  profile_image_url character varying(255) null,
  color_mode character varying(20) null default 'light'::character varying,
  language character varying(20) null default 'en'::character varying,
  fcm_token text null,
  daily_reminder_time character varying(5) null default '22:10'::character varying,
  time_format character varying(10) null default '24h'::character varying,
  timezone character varying(50) null,
  notifications_enabled boolean null default true,
  constraint users_pkey primary key (user_id),
  constraint users_email_key unique (email)
) TABLESPACE pg_default;

create index IF not exists idx_users_fcm_token on public.users using btree (fcm_token) TABLESPACE pg_default
where
  (fcm_token is not null);