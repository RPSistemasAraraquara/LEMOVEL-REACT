-- QA - idempotencia de lancamento mobile / producao duplicada
-- Ajuste os filtros de emp_001 e ven_001 conforme o cliente/teste.

-- 1) Estrutura esperada apos o primeiro lancamento com APP atualizado.
select column_name, data_type, character_maximum_length
from information_schema.columns
where table_schema = current_schema()
  and lower(table_name) = 'vendaitem'
  and lower(column_name) = 'id_lancamento_mobile';

select indexname, indexdef
from pg_indexes
where schemaname = current_schema()
  and indexname = 'ux_vendaitem_lanc_mobile';

-- 2) Nao pode existir mais de uma linha para a mesma chave mobile.
select emp_001,
       ven_001,
       id_lancamento_mobile,
       count(*) as qtd,
       min(ite_001) as primeiro_item,
       max(ite_001) as ultimo_item
from vendaitem
where id_lancamento_mobile is not null
group by emp_001, ven_001, id_lancamento_mobile
having count(*) > 1
order by qtd desc, emp_001, ven_001;

-- 3) Validacao focada do script PowerShell:
-- Troque os valores abaixo pelo retorno exibido no terminal.
/*
select id_lancamento_mobile,
       count(*) as qtd,
       min(ite_001) as primeiro_item,
       max(ite_001) as ultimo_item,
       bool_or(pendenteimpressao and not produtoimpresso) as ficou_pendente_producao
from vendaitem
where emp_001 = 1
  and ven_001 = 123
  and id_lancamento_mobile = 'qa-idem-YYYYMMDDHHMMSS-XXXXXXXX'
group by id_lancamento_mobile;
*/

-- 4) Foto operacional da fila de producao da venda investigada.
-- Troque emp_001/ven_001 para a venda do cliente.
/*
select emp_001,
       ven_001,
       count(*) filter (where pendenteimpressao = true and produtoimpresso = false) as pendentes_producao,
       count(*) filter (where produtoimpresso = true) as ja_impressos,
       count(*) as total_itens
from vendaitem
where emp_001 = 1
  and ven_001 = 123
group by emp_001, ven_001;
*/
