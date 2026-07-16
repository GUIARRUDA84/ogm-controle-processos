-- =====================================================================
--  OGM · Controle de Processos — Esquema do banco (Supabase / PostgreSQL)
--  Cole este script inteiro no Supabase → SQL Editor → RUN.
--  Depois, abra o sistema e clique em "Tabelas Auxiliares → Popular dados
--  iniciais" para carregar taxonomia, ODS, órgãos, servidores etc.
-- =====================================================================

-- ---------- TABELAS PRINCIPAIS ----------
create table if not exists processos (
  id                uuid primary key default gen_random_uuid(),
  numero_sei        text,
  data_entrada      date,
  orgao_demandado   text,
  tipo_demanda      text,
  assunto           text,
  tipo_sei          text,
  etiqueta          text,
  link_sei          text,
  area              text,
  subarea           text,
  ods               jsonb default '[]'::jsonb,
  servidor          text,
  unidade_resp      text,
  prazo_interno     date,
  tramitacao_ext    boolean default false,
  ultima_unidade    text,
  doc_tipo          text,
  doc_numero        text,
  doc_data_saida    date,
  lai_situacao      text,
  lai_motivo        text,
  status            text default 'Em análise',
  gera_recomendacao boolean default false,
  observacoes       text,
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);

create table if not exists recomendacoes (
  id           uuid primary key default gen_random_uuid(),
  processo_id  uuid references processos(id) on delete cascade,
  texto        text,
  responsavel  text,
  prazo        date,
  status       text default 'Aberta',
  created_at   timestamptz default now()
);

create table if not exists tratativas (
  id              uuid primary key default gen_random_uuid(),
  recomendacao_id uuid references recomendacoes(id) on delete cascade,
  texto           text,
  autor           text,
  data            date default current_date,
  created_at      timestamptz default now()
);

-- ---------- TABELAS AUXILIARES (editáveis no sistema) ----------
create table if not exists aux_taxonomia (
  id uuid primary key default gen_random_uuid(),
  area text, subarea text, descricao text, ods int
);
create table if not exists aux_ods (
  id uuid primary key default gen_random_uuid(),
  numero int, nome text, descricao text
);
create table if not exists aux_lai_motivos (
  id uuid primary key default gen_random_uuid(),
  situacao text, motivo text, descricao text
);
create table if not exists aux_servidores (
  id uuid primary key default gen_random_uuid(),
  nome text, unidade text
);
create table if not exists aux_unidades (
  id uuid primary key default gen_random_uuid(),
  sigla text, nome text
);
create table if not exists aux_orgaos (
  id uuid primary key default gen_random_uuid(),
  sigla text, nome text
);
create table if not exists aux_tipos_demanda (
  id uuid primary key default gen_random_uuid(), nome text
);
create table if not exists aux_tipos_documento (
  id uuid primary key default gen_random_uuid(), nome text
);
create table if not exists aux_status (
  id uuid primary key default gen_random_uuid(), nome text
);

-- ---------- ACESSO ABERTO (chave anônima) ----------
-- ATENÇÃO: acesso aberto = qualquer pessoa com o link e a chave pública
-- pode ler e gravar. Adequado para uso interno em rede confiável.
-- Para restringir depois, troque estas políticas por regras com login.
do $$
declare t text;
begin
  for t in
    select tablename from pg_tables
    where schemaname='public'
      and tablename in ('processos','recomendacoes','tratativas',
        'aux_taxonomia','aux_ods','aux_lai_motivos','aux_servidores',
        'aux_unidades','aux_orgaos','aux_tipos_demanda','aux_tipos_documento','aux_status')
  loop
    execute format('alter table %I enable row level security;', t);
    execute format('drop policy if exists acesso_aberto on %I;', t);
    execute format($p$create policy acesso_aberto on %I for all
                     to anon, authenticated using (true) with check (true);$p$, t);
  end loop;
end $$;
