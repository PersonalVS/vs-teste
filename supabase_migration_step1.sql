-- ═══════════════════════════════════════════════════════════════
-- MIGRAÇÃO — Etapa 1: multiusuário com Supabase Auth + RLS
-- Rode isso inteiro no SQL Editor do seu projeto Supabase.
-- Pode rodar mais de uma vez sem problema (usa IF NOT EXISTS / OR REPLACE).
-- ═══════════════════════════════════════════════════════════════

-- 1) Adiciona a coluna user_id nas tabelas existentes.
--    default = auth.uid() → se o app esquecer de enviar, o Postgres
--    preenche sozinho com o usuário autenticado da sessão (piloto automático).
alter table public.students
  add column if not exists user_id uuid references auth.users(id) on delete cascade default auth.uid();

alter table public.app_data
  add column if not exists user_id uuid references auth.users(id) on delete cascade default auth.uid();

-- 2) IMPORTANTE — dados antigos (seus alunos atuais, sem dono ainda):
--    Depois de criar SUA conta pela tela de cadastro do app, rode isto
--    trocando 'SEU_USER_ID_AQUI' pelo seu UUID
--    (Authentication → Users → copie o UUID do seu usuário):
--
--  update public.students set user_id = 'SEU_USER_ID_AQUI' where user_id is null;
--  update public.app_data  set user_id = 'SEU_USER_ID_AQUI' where user_id is null;

-- 3) app_data tinha "key" como identificador único global; agora precisa
--    ser único por usuário (cada personal tem sua própria "attendance", "schedule" etc).
alter table public.app_data drop constraint if exists app_data_pkey;
alter table public.app_data add primary key (user_id, key);

-- 4) Liga Row Level Security — a partir daqui, NINGUÉM lê/escreve linha
--    de outro usuário, nem por engano, nem via anon key vazada.
alter table public.students enable row level security;
alter table public.app_data  enable row level security;

-- 5) Policies: cada usuário só enxerga e só grava as próprias linhas.
drop policy if exists "students_owner_all" on public.students;
create policy "students_owner_all" on public.students
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "app_data_owner_all" on public.app_data;
create policy "app_data_owner_all" on public.app_data
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 6) (Recomendado, mas só depois do passo 2 acima) tornar user_id obrigatório:
-- alter table public.students set not null user_id;
-- alter table public.app_data  set not null user_id;
