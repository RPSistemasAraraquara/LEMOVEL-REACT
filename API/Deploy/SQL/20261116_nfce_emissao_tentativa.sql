-- Pré-requisito para ativar a versão da API que reserva a NFC-e antes da transmissão.
-- Execute no banco usado pela API, com uma conta de implantação autorizada no schema public.
-- Se a API usa uma role diferente da proprietária da tabela, conceda SELECT, INSERT e DELETE.
-- A tabela guarda XML fiscal. Restrinja acesso e preserve as tentativas pendentes no rollback do EXE.

BEGIN;
SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '30s';

CREATE TABLE IF NOT EXISTS public.nfce_emissao_tentativa (
    emp_001 integer NOT NULL,
    ven_001 integer NOT NULL,
    chave varchar(44) NOT NULL,
    xml_assinado text NOT NULL,
    ambiente smallint NOT NULL,
    contingencia boolean NOT NULL,
    registrada_em timestamptz NOT NULL DEFAULT current_timestamp,
    CONSTRAINT nfce_emissao_tentativa_pkey PRIMARY KEY (emp_001, ven_001),
    CONSTRAINT nfce_emissao_tentativa_ambiente_chave_key UNIQUE (ambiente, chave),
    CONSTRAINT nfce_emissao_tentativa_chave_ck CHECK (chave ~ '^[0-9]{44}$'),
    CONSTRAINT nfce_emissao_tentativa_xml_ck CHECK (btrim(xml_assinado) <> ''),
    CONSTRAINT nfce_emissao_tentativa_ambiente_ck CHECK (ambiente IN (1, 2))
);

COMMIT;
