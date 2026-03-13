/*
PROJETO: Sistema de Adoção de Animais - Etapa 4 (Constraints)
ALUNO: Weber Fernandes da Silva
DISCIPLINA: Projeto de Banco de Dados
*/

CREATE SCHEMA IF NOT EXISTS exemplo;
SET search_path TO exemplo;

-- Limpeza (para rodar várias vezes)
DROP TABLE IF EXISTS adotante CASCADE;
DROP TABLE IF EXISTS animal CASCADE;
DROP TABLE IF EXISTS adocao CASCADE;
DROP TABLE IF EXISTS telefone CASCADE;
DROP TABLE IF EXISTS historico_animal CASCADE;

-- -----------------------------
-- TABELAS
-- -----------------------------

-- ADOTANTE
create table adotante (
    id SERIAL primary key,
    nome varchar(100) not null,
    cpf varchar(11) not null UNIQUE,
    endereco varchar(255) not null,
    idade integer not null, 
    tipo_moradia varchar(10),
    area_util_m2 decimal(10,2), -- Área útil para validar animais de grande porte
    possui_criancas boolean default false, -- Regra de presença de crianças
    possui_outros_animais boolean default false,
    -- CONSTRAINT CHECK PARA VALIDAR SE ADOTANTE É MAIOR DE 18 ANOS E VALIDAR O TIPO DE MORADIA
    CONSTRAINT ck_idade_minima CHECK (idade >= 18), -- (Alterei para essa linha após ver o ex do prof. na aula)
    CONSTRAINT ck_tipo_moradia CHECK (tipo_moradia IN ('CASA', 'APTO')) -- (Alterei para essa linha após ver o ex do prof. na aula)
);

-- ANIMAL
create table animal (
    id SERIAL primary key,
    nome varchar(50) not null,
    especie varchar(10) not null, -- Alterei o nome de 'TIPO' para 'ESPECIE' conforme consta na documentação de requisitos
    raca varchar(20) not null,
    genero varchar(10) not null,
    idade_meses integer not null, -- Usado para definir taxa (Filhote/Senior)
    porte varchar(1),
    temperamento varchar(50), -- Exemplos possíveis: Dócil, Agitado, Arisco etc
    status varchar(20) default 'DISPONIVEL' NOT NULL, -- Status possíveis: DISPONIVEL, RESERVADO, ADOTADO, DEVOLVIDO, QUARENTENA, INADOTAVEL
    -- CONSTRAINT CHECK PARA GARANTIR QUE A IDADE DO ANIMAL SEJA VÁLIDA, STATUS DO ANIMAL ESTEJA ENTRE OS REQUISITOS E O PORTE
    CONSTRAINT ck_idade_animal CHECK (idade_meses >= 0),
    CONSTRAINT ck_status_animal CHECK (status IN ('DISPONIVEL', 'RESERVADO', 'ADOTADO', 'DEVOLVIDO', 'QUARENTENA', 'INADOTAVEL')),
    CONSTRAINT ck_porte_animal CHECK (porte IN ('P', 'M', 'G'))
);

-- TELEFONE
create table telefone (
    id SERIAL primary key,
    numero varchar(20) not null,
    id_adotante integer not null, 
    foreign key (id_adotante) references adotante(id) on delete cascade on update cascade
);

-- ADOCAO (Implementado 'valor_taxa' e 'termo_aceito', conforme requisitos 3)
create table adocao (
    id SERIAL primary key,
    id_adotante integer not null,
    id_animal integer not null,
    data_adocao date default current_date,
    valor_taxa DECIMAL (10,2) NOT NULL, -- Estratégia de taxas
    termo_aceito BOOLEAN DEFAULT TRUE, -- Termo de aceite de adoção
    foreign key (id_adotante) references adotante(id) on delete restrict on update cascade,
    foreign key (id_animal) references animal(id) on delete restrict on update cascade
);

-- HISTÓRICO DO ANIMAL (Implementado a tabela para constar o histórico do animal, conforme requisitos 1 e 5)
CREATE TABLE historico_animal (
	id SERIAL PRIMARY KEY,
    id_animal INTEGER NOT NULL,
    evento VARCHAR(100) NOT NULL, -- Ex: 'VACINA', 'MUDANCA_STATUS', 'DEVOLUCAO', 'DOENTE'
    descricao TEXT,
    data_evento date DEFAULT current_date,
    FOREIGN KEY (id_animal) REFERENCES animal(id) ON DELETE CASCADE
);

-- -----------------------------
-- INSERTS
-- -----------------------------

-- INSERINDOS DADOS DE ADOTANTES (MÍNIMO 3)
INSERT INTO adotante (nome, cpf, endereco, idade, tipo_moradia, area_util_m2, possui_criancas, possui_outros_animais) VALUES
('Carlos Silva', '11122233344', 'Rua das Flores, 123', 35, 'CASA', 120.00, true, true),
('Mariana Souza', '55566677788', 'Av. Beira Mar, 500', 22, 'APTO', 45.00, false, false), -- Apto pequeno, ideal para pet porte P
('Roberto Lima', '99988877766', 'Rua da Serra, 45', 50, 'CASA', 300.00, false, true);

-- INSERINDO DADOS DOS ANIMAIS (MÍNIMO 6 PARA ABRANGER CADA STATUS POSSÍVEL)
INSERT INTO animal (nome, especie, raca, genero, idade_meses, porte, temperamento, status) VALUES
('Rex', 'Cachorro', 'Labrador', 'Macho', 24, 'G', 'Agitado', 'ADOTADO'),
('Mia', 'Gato', 'Siamês', 'Fêmea', 12, 'P', 'Dócil', 'DISPONIVEL'),
('Thor', 'Cachorro', 'Vira-lata', 'Macho', 60, 'M', 'Dócil', 'INADOTAVEL'),
('Bob', 'Cachorro', 'Bulldog', 'Macho', 5, 'P', 'Teimoso', 'QUARENTENA'),
('Antony', 'Cachorro', 'Shih Tzu', 'Macho', 12, 'P', 'Calmo', 'RESERVADO'),
('Hank', 'Cachorro', 'Pastor Alemão', 'Macho', 18, 'G', 'Bravo', 'DEVOLVIDO');

-- DADOS DE TELEFONES
INSERT INTO telefone (numero, id_adotante) VALUES 
('(85) 99999-1111', 1), -- CARLOS
('(85) 98888-2222', 2), -- MARIANA
('(88) 97777-3333', 3); -- ROBERTO

-- DADOS DE ADOÇÃO
INSERT INTO adocao (id_adotante, id_animal, data_adocao, valor_taxa, termo_aceito) VALUES 
(1, 1, '2026-01-21', 150.00, TRUE), -- CARLOS ADOTOU REX
(2, 5, '2026-02-02', 100.00, TRUE); -- MARIANA ADOTOU ANTONY

-- DADOS DE HISTORICO DO ANIMAL
INSERT INTO historico_animal (id_animal, evento, descricao) VALUES
(1, 'ENTRADA', 'Animal resgatado na rua e disponível para triagem'), -- Rex
(2, 'VACINA', 'Vacina V8 aplicada com sucesso'), -- Mia
(4, 'DOENTE', 'Animal em observação por sintomas de gripe'), -- Bob
(6, 'DEVOLUCAO', 'Motivo: Adotante mudou-se para local sem espaço'); -- Hank

-- -----------------------------
-- CONSULTAS
-- -----------------------------

-- Consulta 1: Perfil dos Adotantes e Contato (utilizando INNER JOIN)para listar dados e 
-- verificar elegibilidade (ex: quem mora em CASA)
SELECT 
    a.nome AS Adotante,
    a.tipo_moradia,
    a.possui_criancas,
    t.numero AS Contato
FROM adotante a
JOIN telefone t ON a.id = t.id_adotante;

-- Consulta 2: Relatório de Adoções com Detalhes do Animal (também utilizando INNER JOIN)com o objetivo de 
-- ver se o animal adotado condiz com o porte esperado
SELECT 
    adt.nome AS Dono,
    ani.nome AS Nome_Pet,
    ani.raca,
    ani.porte,
    adoc.data_adocao
FROM adocao adoc
JOIN adotante adt ON adoc.id_adotante = adt.id
JOIN animal ani ON adoc.id_animal = ani.id;

-- Consulta 3: Status Geral (com LEFT JOIN)para listar todos os animais cadastrados e saber se já foram adotados ou não.
-- Animais em QUARENTENA ou DISPONIVEL aparecerão com data_adocao NULL.
SELECT 
    ani.nome,
    ani.status,
    ani.temperamento,
    adoc.data_adocao
FROM animal ani
LEFT JOIN adocao adoc ON ani.id = adoc.id_animal;

-- Consulta 4: Animais Disponíveis para Apartamento para filtrar animais de porte Pequeno (P) que estão DISPONIVEIS.
SELECT 
    nome, 
    especie, 
    raca 
FROM animal
WHERE status = 'DISPONIVEL' AND porte = 'P';

-- Consulta 5: Adotantes Potenciais para Cães de Guarda com o objetivo de buscar adotantes 
-- que moram em CASA e têm área útil maior que 100m2.
SELECT 
    nome, 
    area_util_m2,
    tipo_moradia
FROM adotante
WHERE tipo_moradia = 'CASA' AND area_util_m2 > 100;


-- Consulta 6: Verificando os dados do animal de pequeno porte independente do status
SELECT
	nome,
	especie,
	raca,
	idade_meses,
	temperamento
FROM animal
WHERE porte = 'P';

-- Consulta 7: Verificar o histórico do animal
SELECT
	ani.nome AS Animal,
	ani.especie,
	hist.evento,
	hist.descricao,
	hist.data_evento
FROM animal ani
JOIN historico_animal hist ON ani.id = hist.id_animal
ORDER BY hist.data_evento DESC, ani.nome;

-- ===============================
-- VIEW - Mesmo da Consulta 2, verifica o relatório de adoção dos animais. Aqui foi inserido uma linha a mais para diferenciar da consulta, adicionado também o ID.
-- ===============================

CREATE view vw_historico_adocoes as
SELECT 
	adt.id as id_adocao,
    adt.nome AS Dono,
    ani.nome AS Nome_Pet,
    ani.raca,
    ani.porte,
    adoc.data_adocao
FROM adocao adoc
JOIN adotante adt ON adoc.id_adotante = adt.id
JOIN animal ani ON adoc.id_animal = ani.id;

-- ===============================
-- VIEW MATERIALIZADA - Verifica a quantidade de animais por tipo e porte.
-- ===============================

CREATE MATERIALIZED VIEW mv_estatisticas_animais as
select
	especie,
	porte,
	COUNT(*) as total_animais
from animal
group by especie, porte;


-- ===============================
-- TRIGGERS
-- ===============================

-- BEFORE
-- Função que verifica a disponibilidade do animal que está sendo adotado
CREATE FUNCTION fn_validar_disponibilidade_animal()
returns trigger
as $$
declare
	v_status_atual VARCHAR(20);
begin
	select status into v_status_atual from animal where id = new.id_animal;
	if v_status_atual != 'DISPONIVEL' then
		raise exception 'Adoção não permitida: o animal selecionado não está DISPONÍVEL para adoção.';
	end if;
	return new;
end

$$ language plpgsql;

CREATE TRIGGER trg_before_insert_adocao
before insert on adocao
for each row
execute function fn_validar_disponibilidade_animal();

-- AFTER
--Função que atualiza o status do animal para 'ADOTADO' após registrar a adoção
create function fn_atualizar_status_pos_adocao()
returns trigger
as $$
begin
	update animal
	set status = 'ADOTADO'
	where id = new.id_animal;

	return new;
end

$$ language plpgsql;

create trigger trg_after_insert_adocao
after insert on adocao
for each row
execute function fn_atualizar_status_pos_adocao();


-- ===============================
-- PROCEDURE
-- ===============================

-- Registra a devolução do animal, alterando o status para 'DEVOLVIDO'

CREATE PROCEDURE registrar_devolucao_animal(p_id_animal INT)
language plpgsql
as $$
begin
	update animal
	set status = 'DEVOLVIDO'
	where id = p_id_animal;
	raise notice 'Animal ID % foi marcado como DEVOLVIDO com sucesso.', p_id_animal;
end
$$;

-- ===============================
-- TESTANDO A VIEW, MATERIALIZED VIEW E PROCEDURE
-- ===============================

select * from vw_historico_adocoes;
select * from mv_estatisticas_animais;
refresh materialized view mv_estatisticas_animais;
call registrar_devolucao_animal(1);

-- ===============================
-- USANDO EXPLAIN E EXPLAIN ANALYZE
-- ===============================

-- Consulta 3: Status Geral (com LEFT JOIN)para listar todos os animais cadastrados e saber se já foram adotados ou não.
-- Animais em QUARENTENA ou DISPONIVEL aparecerão com data_adocao NULL.
explain analyze
SELECT 
    ani.nome,
    ani.status,
    ani.temperamento,
    adoc.data_adocao
FROM animal ani
LEFT JOIN adocao adoc ON ani.id = adoc.id_animal;

-- Consulta 4: Animais Disponíveis para Apartamento para filtrar animais de porte Pequeno (P) que estão DISPONIVEIS.
explain analyze
SELECT 
    nome, 
    especie, 
    raca 
FROM animal
WHERE status = 'DISPONIVEL' AND porte = 'P';

-- Consulta 5: Adotantes Potenciais para Cães de Guarda com o objetivo de buscar adotantes 
-- que moram em CASA e têm área útil maior que 100m2.
explain analyze
SELECT 
    nome, 
    area_util_m2,
    tipo_moradia
FROM adotante
WHERE tipo_moradia = 'CASA' AND area_util_m2 > 100;

-- ===============================
-- APLICANDO ÍNDICES PARA OTIMIZAÇÃO
-- ===============================

create index idx_adocao_id_animal ON adocao(id_animal);
create index idx_animal_status_porte on animal(status,porte);
create index idx_adotante_moradia_area on adotante(tipo_moradia, area_util_m2);