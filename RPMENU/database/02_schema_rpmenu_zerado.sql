--
-- PostgreSQL database dump
--

\restrict BfupHwy5q0l0XZvidnfoO8bHTVG5UDZ3lTbjVhu9lKMPScT3RLpePB1lXs11zWf

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: aplicar_acrescimo_proporcional_vendaitem(integer, integer, numeric); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.aplicar_acrescimo_proporcional_vendaitem(IN p_idvenda integer, IN p_idempresa integer, IN p_total_acrescimo numeric)
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
    v_valor_total NUMERIC(15,2); 
    v_total_base NUMERIC(15,2); 
    v_total_cents INTEGER;  -- total a distribuir em centavos
BEGIN 
    v_valor_total := ROUND(ABS(p_total_acrescimo), 2); 
    
    -- Base de rateio (somente itens elegíveis com sit_001 = 4)
    SELECT COALESCE(SUM(ite_005), 0.0) 
      INTO v_total_base 
      FROM vendaitem 
     WHERE ven_001 = p_idvenda 
       AND emp_001 = p_idempresa 
       AND sit_001 = 4 
       AND ite_005 >= 0; 
        
    -- Sai se não há nada para ratear
    IF v_valor_total = 0 THEN 
        RETURN; 
    END IF;    
    
    -- Converte o total para centavos (trabalha com inteiros = precisão máxima)
    v_total_cents := ROUND(v_valor_total * 100); 
    
    WITH base_itens AS (
        SELECT ite_001, COALESCE(ite_005, 0) AS base_item 
          FROM vendaitem 
         WHERE ven_001 = p_idvenda 
           AND emp_001 = p_idempresa 
           AND sit_001 = 4 
           AND ite_005 >= 0
    ), 
    calc AS (
        -- Calcula valores proporcionais exatos em centavos
        SELECT b.ite_001,
               b.base_item,
               -- Valor exato proporcional: (total_cents * base_item / total_base)
               (v_total_cents::NUMERIC * b.base_item / NULLIF(v_total_base, 0)) AS exato_cents,
               -- Parte inteira (piso)
               FLOOR(v_total_cents::NUMERIC * b.base_item / NULLIF(v_total_base, 0))::INTEGER AS piso,
               -- Parte fracionária (para distribuição do resto)
               (v_total_cents::NUMERIC * b.base_item / NULLIF(v_total_base, 0)) - FLOOR(v_total_cents::NUMERIC * b.base_item / NULLIF(v_total_base, 0)) AS frac
          FROM base_itens b
    ), 
    soma AS (
        -- Soma todos os valores "piso"
        SELECT COALESCE(SUM(piso), 0) AS soma_piso FROM calc
    ), 
    resto AS (
        -- Calcula resto a ser distribuído (protege contra valores negativos)
        SELECT GREATEST(v_total_cents - (SELECT soma_piso FROM soma), 0) AS resto_cents
    ), 
    ordenado AS (
        -- Ordena por maior fração para distribuir o resto
        SELECT c.*, ROW_NUMBER() OVER (ORDER BY c.frac DESC, c.ite_001 ASC) AS rn,
               (SELECT resto_cents FROM resto) AS resto_cents
          FROM calc c
    ), 
    final_rateio AS (
        -- Distribui o resto: +1 centavo para os maiores restos
        SELECT ite_001, (piso + CASE WHEN rn <= resto_cents THEN 1 ELSE 0 END)::INTEGER AS total_cents
          FROM ordenado
    ), 
    aplicar AS (
        -- LEFT JOIN garante que TODOS os itens sejam atualizados (0 ou valor)
        SELECT b.ite_001, COALESCE(f.total_cents, 0) AS total_cents
          FROM base_itens b
          LEFT JOIN final_rateio f USING (ite_001)
    ) 
    -- UPDATE único: converte centavos de volta para reais
    UPDATE vendaitem v 
       SET AcrescimoRateio = (a.total_cents::NUMERIC / 100.0) 
      FROM aplicar a 
     WHERE v.ven_001 = p_idvenda 
       AND v.emp_001 = p_idempresa 
       AND v.sit_001 = 4 
       AND v.ite_001 = a.ite_001; 
       
END; 
$$;


--
-- Name: aplicar_desconto_proporcional_vendaitem(integer, integer, numeric); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.aplicar_desconto_proporcional_vendaitem(IN p_idvenda integer, IN p_idempresa integer, IN p_total_desconto numeric)
    LANGUAGE plpgsql
    AS $$

DECLARE
    v_valor_total NUMERIC(15,2);
    v_total_base NUMERIC(15,2);
    v_total_cents INTEGER;  -- total a distribuir em centavos
BEGIN
    v_valor_total := ROUND(ABS(p_total_desconto), 2);

  -- Se não há taxa, apenas zera e sai
    IF v_valor_total = 0 THEN
        UPDATE vendaitem
        SET DescontoRateio = 0
        WHERE ven_001 = p_idvenda AND emp_001 = p_idempresa;
        RETURN;
    END IF;

    -- Base de rateio (somente itens elegíveis com sit_001 = 4)
    SELECT COALESCE(SUM(ite_005), 0.0)
      INTO v_total_base
      FROM vendaitem
     WHERE ven_001 = p_idvenda
       AND emp_001 = p_idempresa
       AND sit_001 = 4
       AND ite_005 >= 0;

    -- Limita o desconto ao total da base
    IF v_valor_total > v_total_base THEN
        v_valor_total := v_total_base;
    END IF;

    -- Se não há base para ratear, zera tudo e sai
    IF v_total_base = 0 THEN
        UPDATE vendaitem
        SET DescontoRateio = 0
        WHERE ven_001 = p_idvenda AND emp_001 = p_idempresa;
        RETURN;
    END IF;

    -- Converte o total para centavos (trabalha com inteiros = precisão máxima)
    v_total_cents := ROUND(v_valor_total * 100);

    WITH base_itens AS (
        SELECT ite_001, COALESCE(ite_005, 0) AS base_item
          FROM vendaitem
         WHERE ven_001 = p_idvenda
           AND emp_001 = p_idempresa
           AND sit_001 = 4
           AND ite_005 >= 0
    ),
    calc AS (
        -- Calcula valores proporcionais exatos em centavos
        SELECT b.ite_001,
               b.base_item,
               -- Valor exato proporcional: (total_cents * base_item / total_base)
               (v_total_cents::NUMERIC * b.base_item / NULLIF(v_total_base, 0)) AS exato_cents,
               -- Parte inteira (piso)
               FLOOR(v_total_cents::NUMERIC * b.base_item / NULLIF(v_total_base, 0))::INTEGER AS piso,
               -- Parte fracionária (para distribuição do resto)
               (v_total_cents::NUMERIC * b.base_item / NULLIF(v_total_base, 0)) - FLOOR(v_total_cents::NUMERIC * b.base_item / NULLIF(v_total_base, 0)) AS frac
          FROM base_itens b
    ),
    soma AS (
        -- Soma todos os valores "piso"
        SELECT COALESCE(SUM(piso), 0) AS soma_piso FROM calc
    ),
    resto AS (
        -- Calcula resto a ser distribuído (protege contra valores negativos)
        SELECT GREATEST(v_total_cents - (SELECT soma_piso FROM soma), 0) AS resto_cents
    ),
    ordenado AS (
        -- Ordena por maior fração para distribuir o resto
        SELECT c.*, ROW_NUMBER() OVER (ORDER BY c.frac DESC, c.ite_001 ASC) AS rn,
               (SELECT resto_cents FROM resto) AS resto_cents
          FROM calc c
    ),
    final_rateio AS (
        -- Distribui o resto: +1 centavo para os maiores restos
        SELECT ite_001, (piso + CASE WHEN rn <= resto_cents THEN 1 ELSE 0 END)::INTEGER AS total_cents
          FROM ordenado
    ),
    aplicar AS (
        -- LEFT JOIN garante que TODOS os itens sejam atualizados (0 ou valor)
        SELECT b.ite_001, COALESCE(f.total_cents, 0) AS total_cents
          FROM base_itens b
          LEFT JOIN final_rateio f USING (ite_001)
    )
    -- UPDATE único: converte centavos de volta para reais
    UPDATE vendaitem v
       SET DescontoRateio = (a.total_cents::NUMERIC / 100.0)
      FROM aplicar a
     WHERE v.ven_001 = p_idvenda
       AND v.emp_001 = p_idempresa
       AND v.sit_001 = 4
       AND v.ite_001 = a.ite_001;

END;
$$;


--
-- Name: atualizar_taxa_garcom(integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.atualizar_taxa_garcom(IN p_ven_001 integer, IN p_emp_001 integer)
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
    v_tipo character(1);          -- Tipo da venda: 'M' (mesa), 'C' (comanda), etc.
    v_ignorar boolean;            -- Flag que indica se deve ignorar a taxa de garçom
    v_taxa_percentual numeric(10,4) := 0;  -- Percentual da taxa de garçom a ser aplicada
    v_adicional_mesa boolean;     -- Indica se deve aplicar taxa para mesa
    v_adicional_comanda boolean;  -- Indica se deve aplicar taxa para comanda
BEGIN 
    -- Busca o tipo da venda e se ela deve ignorar a taxa de garçom
    SELECT ven_024, ignorar_taxa_garcom 
      INTO v_tipo, v_ignorar 
      FROM venda 
     WHERE ven_001 = p_ven_001 
       AND emp_001 = p_emp_001; 
    
    -- Caso a venda deva ignorar a taxa de garçom, zera os campos correspondentes
    IF v_ignorar THEN 
        UPDATE venda 
           SET taxa_percentual_garcom = 0,
               taxa_valor_garcom = 0 
         WHERE ven_001 = p_ven_001 
           AND emp_001 = p_emp_001; 
    ELSE 
        -- Caso o tipo seja 'M' (mesa), busca as configurações de taxa da empresa para mesa
        IF v_tipo = 'M' THEN 
            SELECT taxa_adicional_mesa, taxa_servico_mesa 
              INTO v_adicional_mesa, v_taxa_percentual 
              FROM empresas 
             WHERE emp_001 = p_emp_001; 
            
            -- Se a empresa não utiliza taxa adicional para mesa, zera o percentual
            IF NOT v_adicional_mesa THEN 
                v_taxa_percentual := 0; 
            END IF; 
        
        -- Caso o tipo seja 'C' (comanda), busca as configurações de taxa da empresa para comanda
        ELSIF v_tipo = 'C' THEN 
            SELECT taxa_adicional_comanda, taxa_servico_comanda 
              INTO v_adicional_comanda, v_taxa_percentual 
              FROM empresas 
             WHERE emp_001 = p_emp_001; 
            
            -- Se a empresa não utiliza taxa adicional para comanda, zera o percentual
            IF NOT v_adicional_comanda THEN 
                v_taxa_percentual := 0; 
            END IF; 
        ELSE 
            -- Se o tipo não for 'M' nem 'C', considera taxa zero por padrão
            v_taxa_percentual := 0; 
        END IF; 
        
        -- Atualiza a venda com o percentual calculado e o valor correspondente da taxa de garçom
        UPDATE venda v 
           SET taxa_percentual_garcom = v_taxa_percentual, 
               
               -- Cálculo do valor da taxa de garçom:
               -- Soma dos valores dos itens da venda (com status 4), que não são marcados como "não taxáveis"
               -- multiplica pelo percentual da taxa, e arredonda com 2 casas decimais
               taxa_valor_garcom = ROUND( 
                   ( 
                     SELECT COALESCE(SUM(vi.ite_005), 0) 
                       FROM vendaitem vi 
                       JOIN materiais m ON m.mat_001 = vi.mat_001 AND m.emp_001 = vi.emp_001 
                      WHERE vi.ven_001 = v.ven_001 
                        AND vi.emp_001 = v.emp_001 
                        AND vi.sit_001 = 4  -- Status do item (ex: "finalizado", "ativo", etc.)
                        AND COALESCE(m.b_nao_taxa, false) = false  -- Apenas itens que permitem cobrança de taxa
                   ) * (COALESCE(v_taxa_percentual, 0)::numeric / 100.0) 
                 , 2)  -- Arredonda para 2 casas decimais
         WHERE v.ven_001 = p_ven_001 
           AND v.emp_001 = p_emp_001; 
    END IF; 
END; 
$$;


--
-- Name: categoria_opcionais_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.categoria_opcionais_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
      IF EXISTS (
          SELECT 1
            FROM public.configuracao_funcionamento cf
           WHERE cf.id_empresa = NEW.emp_001
             AND (
                  COALESCE(cf.utiliza_controle_rpfood, false)
               OR COALESCE(cf.utiliza_controle_rpmenu, false)
             )
      ) THEN
          INSERT INTO public.transf_rp_food_menu (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar)
          VALUES ('CATEGORIASOPCIONAIS', NEW.id, NEW.emp_001, NULL, NULL)
          ON CONFLICT DO NOTHING;
      END IF;

      RETURN NEW;
  END;
  $$;


--
-- Name: categoria_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.categoria_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
      IF EXISTS (
          SELECT 1
            FROM public.configuracao_funcionamento cf
           WHERE cf.id_empresa = NEW.emp_001
             AND (
                  COALESCE(cf.utiliza_controle_rpfood, false)
               OR COALESCE(cf.utiliza_controle_rpmenu, false)
             )
      ) THEN
          INSERT INTO public.transf_rp_food_menu (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar)
          VALUES ('CATEGORIAS', NEW.cat_001, NEW.emp_001, NULL, NULL)
          ON CONFLICT DO NOTHING;
      END IF;

      RETURN NEW;
  END;
  $$;


--
-- Name: cloud_bairro_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_bairro_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('BAIRRO', OLD.emp_001, OLD.bai_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('BAIRRO', NEW.emp_001, NEW.bai_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_balanca_info_extra_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_balanca_info_extra_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('BALANCA_INFO_EXTRA', OLD.emp_001, OLD.inf_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('BALANCA_INFO_EXTRA', NEW.emp_001, NEW.inf_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_balanca_info_nutri_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_balanca_info_nutri_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('BALANCA_INFO_NUTRI', OLD.emp_001, OLD.nut_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('BALANCA_INFO_NUTRI', NEW.emp_001, NEW.nut_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_caixa_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_caixa_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('CAIXA', OLD.id_empresa, OLD.id_caixa, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('CAIXA', NEW.id_empresa, NEW.id_caixa, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_caixainformado_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_caixainformado_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('CAIXAINFORMADO', OLD.id_empresa, OLD.id_caixa, OLD.id_formapgto, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('CAIXAINFORMADO', NEW.id_empresa, NEW.id_caixa, NEW.id_formapgto, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_caixaitem_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_caixaitem_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('CAIXAITEM', OLD.id_empresa, OLD.id_caixa, OLD.item, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('CAIXAITEM', NEW.id_empresa, NEW.id_caixa, NEW.item, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_categoria_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_categoria_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('CATEGORIA', OLD.emp_001, OLD.cat_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('CATEGORIA', NEW.emp_001, NEW.cat_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_clientes_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_clientes_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('CLIENTES', OLD.emp_001, OLD.cli_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('CLIENTES', NEW.emp_001, NEW.cli_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_comanda_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_comanda_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('COMANDA', OLD.emp_001, OLD.com_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('COMANDA', NEW.emp_001, NEW.com_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_composicao_fornecedor_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_composicao_fornecedor_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('COMPOSICAO_FORNECEDOR', OLD.id_empresa, OLD.id_composicao, OLD.id_fornecedor, OLD.codigo_fornecedor, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('COMPOSICAO_FORNECEDOR', NEW.id_empresa, NEW.id_composicao, NEW.id_fornecedor, NEW.codigo_fornecedor, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_composicao_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_composicao_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('COMPOSICAO', OLD.id_empresa, OLD.id_composicao, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('COMPOSICAO', NEW.id_empresa, NEW.id_composicao, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_conta_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_conta_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('CONTA', OLD.id_empresa, OLD.id_conta, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('CONTA', NEW.id_empresa, NEW.id_conta, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_contacorrente_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_contacorrente_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('CONTACORRENTE', OLD.id_empresa, OLD.id_contacorrente, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('CONTACORRENTE', NEW.id_empresa, NEW.id_contacorrente, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_cpagar_parcela_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_cpagar_parcela_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('CPAGAR_PARCELA', OLD.id_empresa, OLD.id_cpagar, OLD.parcela, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('CPAGAR_PARCELA', NEW.id_empresa, NEW.id_cpagar, NEW.parcela, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_cpagar_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_cpagar_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('CPAGAR', OLD.id_empresa, OLD.id_cpagar, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('CPAGAR', NEW.id_empresa, NEW.id_cpagar, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_creceber_parcela_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_creceber_parcela_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('CRECEBER_PARCELA', OLD.id_empresa, OLD.id_creceber, OLD.parcela, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('CRECEBER_PARCELA', NEW.id_empresa, NEW.id_creceber, NEW.parcela, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_creceber_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_creceber_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('CRECEBER', OLD.id_empresa, OLD.id_creceber, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('CRECEBER', NEW.id_empresa, NEW.id_creceber, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_devolucaoitem_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_devolucaoitem_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('DEVOLUCAOITEM', OLD.id_empresa, OLD.id_devolucaoitem, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('DEVOLUCAOITEM', NEW.id_empresa, NEW.id_devolucaoitem, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_empresas_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_empresas_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF COALESCE(OLD.utiliza_rpcheff_cloud, false) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('EMPRESAS', OLD.emp_001, OLD.emp_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF COALESCE(NEW.utiliza_rpcheff_cloud, false) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('EMPRESAS', NEW.emp_001, NEW.emp_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_encerravenda_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_encerravenda_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('ENCERRAVENDA', OLD.emp_001, OLD.enc_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('ENCERRAVENDA', NEW.emp_001, NEW.enc_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_encerravendaitem_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_encerravendaitem_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('ENCERRAVENDAITEM', OLD.emp_001, OLD.enc_001, OLD.ite_001, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('ENCERRAVENDAITEM', NEW.emp_001, NEW.enc_001, NEW.ite_001, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_eventos_mesas_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_eventos_mesas_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('EVENTOS_MESAS', OLD.emp_001, OLD.id_evento, OLD.numero_mesa, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('EVENTOS_MESAS', NEW.emp_001, NEW.id_evento, NEW.numero_mesa, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_eventos_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_eventos_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('EVENTOS', OLD.emp_001, OLD.id_evento, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('EVENTOS', NEW.emp_001, NEW.id_evento, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_execucoes_estoque_item_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_execucoes_estoque_item_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('EXECUCOES_ESTOQUE_ITEM', OLD.id_empresa, OLD.id_mestre, OLD.item, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('EXECUCOES_ESTOQUE_ITEM', NEW.id_empresa, NEW.id_mestre, NEW.item, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_execucoes_estoque_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_execucoes_estoque_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('EXECUCOES_ESTOQUE', OLD.id_empresa, OLD.id, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('EXECUCOES_ESTOQUE', NEW.id_empresa, NEW.id, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_formapgto_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_formapgto_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('FORMAPGTO', OLD.emp_001, OLD.for_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('FORMAPGTO', NEW.emp_001, NEW.for_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_fornecedor_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_fornecedor_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('FORNECEDOR', OLD.id_empresa, OLD.id_fornecedor, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('FORNECEDOR', NEW.id_empresa, NEW.id_fornecedor, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_materiais_fornecedor_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_materiais_fornecedor_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('MATERIAIS_FORNECEDOR', OLD.id_empresa, OLD.id_material, OLD.id_fornecedor, OLD.codigo_fornecedor, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('MATERIAIS_FORNECEDOR', NEW.id_empresa, NEW.id_material, NEW.id_fornecedor, NEW.codigo_fornecedor, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_materiais_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_materiais_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('MATERIAIS', OLD.emp_001, OLD.mat_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('MATERIAIS', NEW.emp_001, NEW.mat_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_mesa_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_mesa_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('MESA', OLD.emp_001, OLD.mes_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('MESA', NEW.emp_001, NEW.mes_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_movimento_estoque_composicao_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_movimento_estoque_composicao_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('MOVIMENTO_ESTOQUE_COMPOSICAO', OLD.id_empresa, OLD.id_movimento_composicao, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('MOVIMENTO_ESTOQUE_COMPOSICAO', NEW.id_empresa, NEW.id_movimento_composicao, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_movimento_estoque_opcional_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_movimento_estoque_opcional_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('MOVIMENTO_ESTOQUE_OPCIONAL', OLD.id_empresa, OLD.id_movimento_opcional, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('MOVIMENTO_ESTOQUE_OPCIONAL', NEW.id_empresa, NEW.id_movimento_opcional, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_movimentocontacliente_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_movimentocontacliente_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('MOVIMENTOCONTACLIENTE', OLD.id_empresa, OLD.id_movimento, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('MOVIMENTOCONTACLIENTE', NEW.id_empresa, NEW.id_movimento, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_movimentocontacorrente_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_movimentocontacorrente_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('MOVIMENTOCONTACORRENTE', OLD.id_empresa, OLD.id_movimento, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('MOVIMENTOCONTACORRENTE', NEW.id_empresa, NEW.id_movimento, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_movimentoestoque_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_movimentoestoque_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('MOVIMENTOESTOQUE', OLD.id_empresa, OLD.id_movimento, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('MOVIMENTOESTOQUE', NEW.id_empresa, NEW.id_movimento, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_nota_entrada_item_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_nota_entrada_item_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('NOTA_ENTRADA_ITEM', OLD.id_empresa, OLD.id_nota_entrada, OLD.item, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('NOTA_ENTRADA_ITEM', NEW.id_empresa, NEW.id_nota_entrada, NEW.item, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_nota_entrada_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_nota_entrada_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('NOTA_ENTRADA', OLD.id_empresa, OLD.id_nota_entrada, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('NOTA_ENTRADA', NEW.id_empresa, NEW.id_nota_entrada, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_nota_saida_item_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_nota_saida_item_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('NOTA_SAIDA_ITEM', OLD.id_empresa, OLD.id_nota_saida, OLD.item, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('NOTA_SAIDA_ITEM', NEW.id_empresa, NEW.id_nota_saida, NEW.item, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_nota_saida_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_nota_saida_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('NOTA_SAIDA', OLD.id_empresa, OLD.id_nota_saida, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('NOTA_SAIDA', NEW.id_empresa, NEW.id_nota_saida, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_opcional_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_opcional_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('OPCIONAL', OLD.id_empresa, OLD.id_opcional, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('OPCIONAL', NEW.id_empresa, NEW.id_opcional, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_pedido_compra_item_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_pedido_compra_item_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('PEDIDO_COMPRA_ITEM', OLD.id_empresa, OLD.id_pedido, OLD.item, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('PEDIDO_COMPRA_ITEM', NEW.id_empresa, NEW.id_pedido, NEW.item, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_pedido_compra_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_pedido_compra_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('PEDIDO_COMPRA', OLD.id_empresa, OLD.id, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('PEDIDO_COMPRA', NEW.id_empresa, NEW.id, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_setor_estoque_composicao_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_setor_estoque_composicao_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('SETOR_ESTOQUE_COMPOSICAO', OLD.id_empresa, OLD.id_composicao, OLD.id_setor, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('SETOR_ESTOQUE_COMPOSICAO', NEW.id_empresa, NEW.id_composicao, NEW.id_setor, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_setor_estoque_material_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_setor_estoque_material_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('SETOR_ESTOQUE_MATERIAL', OLD.id_empresa, OLD.id_material, OLD.id_setor, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('SETOR_ESTOQUE_MATERIAL', NEW.id_empresa, NEW.id_material, NEW.id_setor, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_setor_estoque_opcional_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_setor_estoque_opcional_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('SETOR_ESTOQUE_OPCIONAL', OLD.id_empresa, OLD.id_opcional, OLD.id_setor, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('SETOR_ESTOQUE_OPCIONAL', NEW.id_empresa, NEW.id_opcional, NEW.id_setor, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_setor_estoque_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_setor_estoque_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('SETOR_ESTOQUE', OLD.id_empresa, OLD.id_setor, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('SETOR_ESTOQUE', NEW.id_empresa, NEW.id_setor, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_subcategoria_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_subcategoria_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('SUBCATEGORIA', OLD.emp_001, OLD.sub_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('SUBCATEGORIA', NEW.emp_001, NEW.sub_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_tara_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_tara_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('TARA', OLD.emp_001, OLD.tar_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('TARA', NEW.emp_001, NEW.tar_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_terminais_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_terminais_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('TERMINAIS', OLD.emp_001, OLD.ter_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('TERMINAIS', NEW.emp_001, NEW.ter_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_tipo_movimento_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_tipo_movimento_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('TIPO_MOVIMENTO', OLD.id_empresa, OLD.id_movimento, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('TIPO_MOVIMENTO', NEW.id_empresa, NEW.id_movimento, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_trocogarcom_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_trocogarcom_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('TROCOGARCOM', OLD.id_empresa, OLD.id_venda, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('TROCOGARCOM', NEW.id_empresa, NEW.id_venda, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_unidades_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_unidades_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('UNIDADES', OLD.emp_001, OLD.uni_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('UNIDADES', NEW.emp_001, NEW.uni_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_usu_movimento_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_usu_movimento_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('USU_MOVIMENTO', OLD.id_empresa, OLD.id, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('USU_MOVIMENTO', NEW.id_empresa, NEW.id, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_usuarios_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_usuarios_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('USUARIOS', OLD.emp_001, OLD.usu_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('USUARIOS', NEW.emp_001, NEW.usu_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_venda_pag_antecipado_itens_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_venda_pag_antecipado_itens_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('VENDA_PAG_ANTECIPADO_ITENS', OLD.id_empresa, OLD.id_mestre, OLD.ite_001, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('VENDA_PAG_ANTECIPADO_ITENS', NEW.id_empresa, NEW.id_mestre, NEW.ite_001, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_venda_pag_antecipado_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_venda_pag_antecipado_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('VENDA_PAG_ANTECIPADO', OLD.id_empresa, OLD.id_venda_pag_antecipado, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('VENDA_PAG_ANTECIPADO', NEW.id_empresa, NEW.id_venda_pag_antecipado, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_venda_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_venda_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('VENDA', OLD.emp_001, OLD.ven_001, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('VENDA', NEW.emp_001, NEW.ven_001, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_vendaitem_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_vendaitem_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.emp_001
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('VENDAITEM', OLD.emp_001, OLD.ven_001, OLD.ite_001, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.emp_001
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('VENDAITEM', NEW.emp_001, NEW.ven_001, NEW.ite_001, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: cloud_vendaitemopcional_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cloud_vendaitemopcional_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
              FROM public.empresas e
             WHERE e.emp_001 = OLD.id_empresa
               AND COALESCE(e.utiliza_rpcheff_cloud, false)
        ) THEN
            INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
            VALUES ('VENDAITEMOPCIONAL', OLD.id_empresa, OLD.id_vendaitemopcional, NULL, NULL, true)
            ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
               SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.empresas e
         WHERE e.emp_001 = NEW.id_empresa
           AND COALESCE(e.utiliza_rpcheff_cloud, false)
    ) THEN
        INSERT INTO public.transf_rpcheff_cloud (tipo, id_empresa, id_registro, id_registro_secundario, auxiliar, registro_deletado)
        VALUES ('VENDAITEMOPCIONAL', NEW.id_empresa, NEW.id_vendaitemopcional, NULL, NULL, false)
        ON CONFLICT (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) DO UPDATE
           SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: configuracaofuncionamento_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.configuracaofuncionamento_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
      INSERT INTO public.transf_rp_food_menu (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar)
      VALUES ('CONFIGURACAOFUNCIONAMENTO', NEW.id, NEW.id_empresa, NULL, NULL)
      ON CONFLICT DO NOTHING;

      RETURN NEW;
  END;
  $$;


--
-- Name: configuracaomercadopago_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.configuracaomercadopago_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
            FROM public.configuracao_funcionamento cf
            WHERE cf.id_empresa = OLD.id_empresa
              AND COALESCE(cf.utiliza_controle_rpfood, FALSE)
        ) THEN
            INSERT INTO public.transf_rp_food_menu AS tr
                (
                    tipo,
                    id_registro,
                    id_empresa,
                    id_registro_secundario,
                    auxiliar,
                    registro_deletado
                )
            VALUES
                (
                    'CONFIGURACAOMERCADOPAGO',
                    OLD.id,
                    OLD.id_empresa,
                    NULL,
                    NULL,
                    TRUE
                )
            ON CONFLICT (
                tipo,
                id_registro,
                id_empresa,
                id_registro_secundario,
                auxiliar
            )
            DO UPDATE
            SET registro_deletado =
                tr.registro_deletado OR EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.configuracao_funcionamento cf
        WHERE cf.id_empresa = NEW.id_empresa
          AND COALESCE(cf.utiliza_controle_rpfood, FALSE)
    ) THEN
        INSERT INTO public.transf_rp_food_menu AS tr
            (
                tipo,
                id_registro,
                id_empresa,
                id_registro_secundario,
                auxiliar,
                registro_deletado
            )
        VALUES
            (
                'CONFIGURACAOMERCADOPAGO',
                NEW.id,
                NEW.id_empresa,
                NULL,
                NULL,
                FALSE
            )
        ON CONFLICT (
            tipo,
            id_registro,
            id_empresa,
            id_registro_secundario,
            auxiliar
        )
        DO UPDATE
        SET registro_deletado =
            tr.registro_deletado OR EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: configuracaorpfood_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.configuracaorpfood_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
      IF EXISTS (
          SELECT 1
            FROM public.configuracao_funcionamento cf
           WHERE cf.id_empresa = NEW.id_empresa
             AND COALESCE(cf.utiliza_controle_rpfood, false)
      ) THEN
          INSERT INTO public.transf_rp_food_menu (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar)
          VALUES ('CONFIGURACAORPFOOD', NEW.id, NEW.id_empresa, NULL, NULL)
          ON CONFLICT DO NOTHING;
      END IF;

      RETURN NEW;
  END;
  $$;


--
-- Name: dblink(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dblink(text, text) RETURNS SETOF record
    LANGUAGE c STRICT
    AS '$libdir/dblink', 'dblink_record';


--
-- Name: dblink_connect(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dblink_connect(text) RETURNS text
    LANGUAGE c STRICT
    AS '$libdir/dblink', 'dblink_connect';


--
-- Name: deleta_registro(character varying, character varying, integer, integer, integer, timestamp without time zone, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deleta_registro(tabela character varying, chave character varying, emp integer, registro integer, usuario integer, dat timestamp without time zone, justificativa character varying, update_sql character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
   sSQL VARCHAR(150);
BEGIN 
   BEGIN
      sSQL := 'UPDATE ' || TABELA || ' SET USU_001_3 = ' || USUARIO || ', DAT_001_3 = ''' || CAST(DAT AS VARCHAR(20)) || '''';
      -------
      IF justificativa <> '' THEN
         sSQL := sSQL || ', ' || justificativa;
      END IF;
      -------
      IF update_SQL <> '' THEN
         sSQL := sSQL || ', ' || update_SQL;
      END IF;
      -------
      sSQL := sSQL || ' WHERE ' || CHAVE || ' = ' || REGISTRO;
      IF EMP > 0 THEN
         sSQL := sSQL || ' AND EMP_001 = ' || EMP;
      END IF;
      -------  
      EXECUTE sSQL;
      -------
      RETURN TRUE;
   EXCEPTION
      WHEN OTHERS THEN 
      BEGIN
         RETURN 0;
         ROLLBACK;
      END;
   END; 
END;
$$;


--
-- Name: empresas_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.empresas_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
      IF EXISTS (
          SELECT 1
            FROM public.configuracao_funcionamento cf
           WHERE cf.id_empresa = NEW.emp_001
             AND (
                  COALESCE(cf.utiliza_controle_rpfood, false)
               OR COALESCE(cf.utiliza_controle_rpmenu, false)
             )
      ) THEN
          INSERT INTO public.transf_rp_food_menu (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar)
          VALUES ('EMPRESAS', NEW.emp_001, NEW.emp_001, NULL, NULL)
          ON CONFLICT DO NOTHING;
      END IF;

      RETURN NEW;
  END;
  $$;


--
-- Name: fn_acompanhamento(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_acompanhamento(emp integer, id integer, tabela integer, OUT cod integer, OUT data_inc timestamp without time zone, OUT tipo character varying, OUT cod_visual character varying, OUT usuario character varying, OUT data timestamp without time zone, OUT observacao character varying) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
   BEGIN
      CREATE LOCAL TEMP TABLE TEMP_ACOMPANHAMENTO(CODIGO INT NULL,
                                                  INCLUSAO TIMESTAMP WITHOUT TIME ZONE NULL,
                                                  TIP VARCHAR(3) NULL,
                                                  COD_VIS VARCHAR(15) NULL,
                                                  USU VARCHAR(40) NULL,
                                                  DAT TIMESTAMP WITHOUT TIME ZONE NULL,
                                                  OBS VARCHAR(50) NULL);
      --------------
      IF TABELA = 1 THEN
         INSERT INTO TEMP_ACOMPANHAMENTO 
            SELECT PED.PED_001, 
                   PED.DAT_001_1,
                   'PED',
                   PED.PED_011, 
                   USU.USU_002,
                   ACO.DAT_001,
                   ACO.ACO_003
                   
            FROM ACOMPANHAMENTO ACO
            LEFT OUTER JOIN USUARIOS USU ON (USU.USU_001 = ACO.USU_001)
            LEFT OUTER JOIN PEDIDOS PED ON (PED.EMP_001 = ACO.EMP_001) AND (PED.PED_001 = ACO.ACO_002)
            WHERE ACO.EMP_001 = EMP
              AND ACO.ACO_002 = ID
              AND ACO.TAB_001 = TABELA
            ORDER BY ACO.ACO_001;
      END IF;
      --------------
      IF TABELA = 2 THEN
         INSERT INTO TEMP_ACOMPANHAMENTO 
            SELECT PED.PED_001, 
                   PED.DAT_001_1,
                   'PED',
                   PED.PED_011, 
                   USU.USU_002,
                   ACO.DAT_001,
                   ACO.ACO_003
                   
            FROM ACOMPANHAMENTO ACO
            LEFT OUTER JOIN USUARIOS USU ON (USU.USU_001 = ACO.USU_001)
            LEFT OUTER JOIN PEDIDOS PED ON (PED.EMP_001 = ACO.EMP_001) AND (PED.PED_001 = ACO.ACO_002)
            WHERE ACO.ACO_001 = (SELECT MAX(ACO_001) 
                                 FROM ACOMPANHAMENTO 
                                 WHERE ACO.EMP_001 = EMP
                                   AND ACO.ACO_002 = ID
                                   AND ACO.TAB_001 = 1);
         ------------------------------------------------
         INSERT INTO TEMP_ACOMPANHAMENTO 
            SELECT ORD.ORD_001, 
                   ORD.DAT_001_1,
                   'ORD',
                   ORD.ORD_002, 
                   USU.USU_002,
                   ACO.DAT_001,
                   ACO.ACO_003
                   
            FROM ACOMPANHAMENTO ACO
            LEFT OUTER JOIN USUARIOS USU ON (USU.USU_001 = ACO.USU_001)
            LEFT OUTER JOIN ORDENS_COMPRA ORD ON (ORD.EMP_001 = ACO.EMP_001) AND (ORD.ORD_001 = ACO.ACO_002)
            WHERE ACO.EMP_001 = EMP
              AND ACO.ACO_002 = ID
              AND ACO.TAB_001 = TABELA
            ORDER BY ACO.ACO_001;
      END IF;
      --------------
      RETURN QUERY SELECT TMP.CODIGO, TMP.INCLUSAO, TMP.TIP, TMP.COD_VIS, TMP.USU, TMP.DAT, TMP.OBS FROM TEMP_ACOMPANHAMENTO TMP;
      DROP TABLE TEMP_ACOMPANHAMENTO;
   END;
$$;


--
-- Name: fn_ajusta_parcelas_oc(integer, integer, numeric, integer, timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_ajusta_parcelas_oc(emp integer, ord integer, val numeric, usu integer, dat timestamp without time zone, entrega integer) RETURNS void
    LANGUAGE plpgsql
    AS $$

DECLARE CUR_PARCELAS CURSOR FOR
      SELECT ODP_004, ODP_001 
      FROM ORDENS_COMPRA_PARCELAS 
      WHERE EMP_001 = EMP 
        AND ORD_001 = ORD 
        AND DAT_001_4 IS NULL
      ORDER BY ODP_001;

DECLARE VALOR_PARC NUMERIC;      
DECLARE PARCELA INT; 
      
BEGIN
   BEGIN
      OPEN CUR_PARCELAS;
      FETCH FIRST FROM CUR_PARCELAS INTO VALOR_PARC, PARCELA;
      --------
      WHILE VAL > 0 LOOP
         IF VAL < VALOR_PARC THEN -- CASO O VALOR PAGO SEJA MENOR IRÁ GERAR OUTRA PARCELA COM A DIFERENÇA DE VALOR
            UPDATE ORDENS_COMPRA_PARCELAS SET
               DAT_001_4 = DAT,
               USU_001_4 = USU,
               ODP_004 = VAL,
               ENT_001 = ENTREGA
            WHERE EMP_001 = EMP
              AND ORD_001 = ORD
              AND ODP_001 = PARCELA; 
            --------
            VAL = VALOR_PARC - VAL;
            --------
            INSERT INTO ORDENS_COMPRA_PARCELAS(EMP_001, ORD_001, ODP_001, ODP_002, ODP_003, ODP_004, USU_001_1, DAT_001_1)
               SELECT ODP.EMP_001,
                      ODP.ORD_001,
                      SEQUENCIADOR('ORDENS_COMPRA_PARCELAS', ODP.EMP_001),
                      ODP.ODP_002,
                      ODP.ODP_003,
                      VAL,
                      USU,
                      NOW()
               FROM ORDENS_COMPRA_PARCELAS ODP
               WHERE ODP.EMP_001 = EMP
                 AND ODP.ORD_001 = ORD
                 AND ODP.ODP_001 = PARCELA;
             --------- 
             VAL = 0;    
         ELSE
            UPDATE ORDENS_COMPRA_PARCELAS SET
               DAT_001_4 = DAT,
               USU_001_4 = USU,
               ENT_001 = ENTREGA
            WHERE EMP_001 = EMP
              AND ORD_001 = ORD
              AND ODP_001 = PARCELA;   
            ---------
            VAL = VAL - VALOR_PARC;
            ---------
            FETCH NEXT FROM CUR_PARCELAS INTO VALOR_PARC, PARCELA;
         END IF;   
      END LOOP;
      ----------
      PERFORM FN_ATUALIZA_SIT_OC_PARCELAS(EMP, ORD);
  EXCEPTION
      WHEN OTHERS THEN 
      BEGIN
         ROLLBACK;
      END;
   END;   
END;
$$;


--
-- Name: fn_atualiza_sit_oc_parcelas(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_atualiza_sit_oc_parcelas(emp integer, ord integer) RETURNS void
    LANGUAGE plpgsql
    AS $$

DECLARE PARCELAS INT; 
DECLARE TOTAL_PARCELAS INT;
      
BEGIN
   BEGIN
      SELECT COUNT(1) INTO PARCELAS
      FROM ORDENS_COMPRA_PARCELAS
      WHERE EMP_001 = EMP
        AND ORD_001 = ORD
        AND DAT_001_4 IS NULL;
      -----------
      IF PARCELAS = 0 THEN -- TODAS ESTÃO PAGAS
         UPDATE ORDENS_COMPRA SET
            ORD_005 = 3
         WHERE EMP_001 = EMP
           AND ORD_001 = ORD;
      ELSE
         SELECT COUNT(1) INTO TOTAL_PARCELAS
         FROM ORDENS_COMPRA_PARCELAS
         WHERE EMP_001 = EMP
           AND ORD_001 = ORD;
         ----------
         IF PARCELAS = TOTAL_PARCELAS THEN -- NENHUMA PARCELA FOI PAGA  
            UPDATE ORDENS_COMPRA SET
               ORD_005 = 1
            WHERE EMP_001 = EMP
              AND ORD_001 = ORD;
         ELSE -- ALGUMAS PARCELAS FORAO PAGAS
            UPDATE ORDENS_COMPRA SET
               ORD_005 = 2
            WHERE EMP_001 = EMP
              AND ORD_001 = ORD;  
         END IF;   
      END IF;
   EXCEPTION
      WHEN OTHERS THEN BEGIN
         ROLLBACK;
      END;
   END;   
END;
$$;


--
-- Name: fn_avalia_forn(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_avalia_forn(emp integer, fornecedor integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
   DECLARE 
      NOTA_MAT INT;
      QUANT_MAT INT;
      ---------
      NOTA_SERV INT;
      QUANT_SERV INT;
      ---------   
      QUANT INT;   
   BEGIN
      SELECT FLOOR(10 -
	   (( (SUM((AVAL.FRQ_002 + 
		    AVAL.FRQ_003) * 4)
	    +  SUM((AVAL.FRQ_004 + 
		    AVAL.FRQ_005) * 2)
	    +  SUM( AVAL.FRQ_006 + 
		    AVAL.FRQ_007 + 
		    AVAL.FRQ_008)) 
	    * 0.6667) / COUNT(1)) + 0.5) AS NOTA
	   , COUNT(1) AS QTDE
      INTO NOTA_MAT, QUANT_MAT
      FROM FORNECEDORES_QUALIDADE AVAL 
      WHERE AVAL.EMP_001 = EMP
	AND AVAL.FOR_001 = FORNECEDOR
	AND AVAL.DAT_001_3 IS NULL
	AND AVAL.FRQ_013 IN (1, 3);
      ---------
      SELECT CAST(SUM((AVAL.FRQ_009 * 5) + 
		      (AVAL.FRQ_010 * 5) + 
		      (AVAL.FRQ_011 * 5) + 
		      (AVAL.FRQ_012 * 5)) / (COUNT(1) * 4) AS INT)  AS NOTA
	     , COUNT(1) AS QTDE
      INTO NOTA_SERV, QUANT_SERV
      FROM FORNECEDORES_QUALIDADE AVAL
      WHERE AVAL.EMP_001 = EMP
	AND AVAL.FOR_001 = FORNECEDOR
	AND AVAL.DAT_001_3 IS NULL
	AND AVAL.FRQ_013 IN (2, 3);
      ---------
      QUANT := SUM(COALESCE(QUANT_MAT, 0) + 
                   COALESCE(QUANT_SERV, 0));
      QUANT := (CASE QUANT WHEN 0 THEN 1 ELSE QUANT END);
      ---------
      RETURN FLOOR((SUM(COALESCE(NOTA_MAT, 0) * 
                        COALESCE(QUANT_MAT, 0)) + 
                    SUM(COALESCE(NOTA_SERV, 0) * 
                        COALESCE(QUANT_SERV, 0))) / 
                    QUANT + 0.5);
   END
$$;


--
-- Name: fn_calcula_acrescimos_itens_venda(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calcula_acrescimos_itens_venda(param_idvenda integer, param_idempresa integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN

    WITH totais AS
    (
        SELECT
            vi.ven_001,
            vi.emp_001,
            vi.ite_001,
            COALESCE(SUM(vio.valor * vi.ite_002), 0.00) AS total_op_item
        FROM vendaitem vi

        LEFT JOIN vendaitemopcional vio
               ON vio.id_venda     = vi.ven_001
              AND vio.id_vendaitem = vi.ite_001
              AND vio.id_empresa   = vi.emp_001
              AND vio.gratis       = FALSE

        WHERE vi.ven_001 = param_idvenda
          AND vi.emp_001 = param_idempresa

        GROUP BY
            vi.ven_001,
            vi.emp_001,
            vi.ite_001
    )

    UPDATE vendaitem vi
       SET ite_005 =
             (vi.ite_002 * vi.ite_003)
             - COALESCE(vi.desconto, 0.00)
             + COALESCE(t.total_op_item, 0.00)
             + COALESCE(vi.ajustes_acrescimo_fracionado, 0.00)
             - (COALESCE(vi.qtderesgatada, 0.00) * vi.ite_003),

           acrescimo =
             COALESCE(t.total_op_item, 0.00)
             + COALESCE(vi.ajustes_acrescimo_fracionado, 0.00)

      FROM totais t

     WHERE vi.ven_001 = t.ven_001
       AND vi.emp_001 = t.emp_001
       AND vi.ite_001 = t.ite_001;

END;
$$;


--
-- Name: fn_calcula_total_venda(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calcula_total_venda(param_idvenda integer, param_idempresa integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
  DECLARE
    total_itens decimal(15,2);  
  BEGIN
    select  fn_total_itens_venda(param_idvenda,  param_idempresa) into total_itens;
    update venda set ven_009=total_itens where  ven_001=param_idvenda and emp_001=param_idempresa;
  END
$$;


--
-- Name: fn_criar_nova_venda(integer, integer, integer, character varying, character varying, integer, numeric, numeric, numeric, integer, character varying, character varying, integer, integer, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_criar_nova_venda(p_emp_001 integer, p_usu_001_1 integer, p_id_caixa_abertura integer, p_terminal_abertura character varying, p_tipo_venda character varying, p_sit_001 integer DEFAULT 0, p_acrescimo numeric DEFAULT 0, p_desconto numeric DEFAULT 0, p_total_venda numeric DEFAULT 0, p_id_cliente integer DEFAULT NULL::integer, p_nome_cliente character varying DEFAULT NULL::character varying, p_cpf_cliente character varying DEFAULT NULL::character varying, p_id_mesa integer DEFAULT NULL::integer, p_id_comanda integer DEFAULT NULL::integer, p_nro_pessoas integer DEFAULT 1, p_nro_couvert_m integer DEFAULT 0, p_nro_couvert_f integer DEFAULT 0, p_id_garcom_abertura integer DEFAULT NULL::integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_ven_001 INTEGER;
BEGIN

    -- Bloqueia a geração de venda para a empresa
    PERFORM pg_advisory_xact_lock(p_emp_001);

    -- Obtém o próximo número da venda
    SELECT COALESCE(MAX(ven_001), 0) + 1
      INTO v_ven_001
      FROM venda
     WHERE emp_001 = p_emp_001;

    INSERT INTO venda (
        ven_001,
        ven_029,
        emp_001,
        ven_004,
        sit_001,
        usu_001_1,
        dat_001_1,
        ven_024,
        ven_008,
        ven_007,
        ven_009,
        id_caixa_abertura,
        terminal_abertura,
        cli_001,
        nome_cliente,
        cpf_cliente,
        ven_025,
        ven_026,
        nro_pessoas,
        nro_couvert_m,
        nro_couvert_f,
        id_garcom_abertura
    )
    VALUES (
        v_ven_001,
        v_ven_001,
        p_emp_001,
        CURRENT_TIMESTAMP,
        p_sit_001,
        p_usu_001_1,
        CURRENT_TIMESTAMP,
        p_tipo_venda,
        p_acrescimo,
        p_desconto,
        p_total_venda,
        p_id_caixa_abertura,
        p_terminal_abertura,
        p_id_cliente,
        p_nome_cliente,
        p_cpf_cliente,
        p_id_mesa,
        p_id_comanda,
        p_nro_pessoas,
        p_nro_couvert_m,
        p_nro_couvert_f,
        p_id_garcom_abertura
    );

    RETURN v_ven_001;

END;
$$;


--
-- Name: fn_grava_cotacao(integer, integer, integer, integer, integer, timestamp without time zone, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_grava_cotacao(emp integer, ped integer, mat integer, forn integer, usu integer, dat timestamp without time zone, valor numeric) RETURNS void
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF (SELECT COUNT(1) 
        FROM PEDIDOS_COTACAO 
        WHERE EMP_001 = EMP 
          AND PED_001 = PED 
          AND MAT_001 = MAT 
          AND FOR_001 = FORN) > 0 THEN 
      ----------------------
      UPDATE PEDIDOS_COTACAO 
         SET PCT_002   = VALOR
           , USU_001_2 = USU
           , DAT_001_2 = DAT
       WHERE EMP_001 = EMP 
         AND PED_001 = PED 
         AND MAT_001 = MAT 
         AND FOR_001 = FORN;
      -----------------------
    ELSE
      -----------------------
      INSERT INTO PEDIDOS_COTACAO(EMP_001, PED_001, MAT_001, FOR_001, PCT_001, PCT_002, USU_001_1, DAT_001_1)
                           VALUES(EMP, PED, MAT, FORN, SEQUENCIADOR('PEDIDOS_COTACAO', EMP), VALOR, USU, NOW());
      -----------------------
    END IF;
  END;
$$;


--
-- Name: fn_imagem_bytea_valida(bytea); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_imagem_bytea_valida(p_img bytea) RETURNS bytea
    LANGUAGE plpgsql IMMUTABLE
    AS $$
  DECLARE
    v_norm bytea;
  BEGIN
    IF p_img IS NULL OR octet_length(p_img) = 0 THEN
      RETURN NULL;
    END IF;

    v_norm := CASE
      WHEN encode(substring(p_img from 1 for 11), 'escape')
           = 'data:image/'
        THEN decode(split_part(convert_from(p_img, 'UTF8'), ',', 2),
                    'base64')
      WHEN encode(substring(p_img from 1 for 8), 'escape') = 'iVBORw0K'
        THEN decode(convert_from(p_img, 'UTF8'), 'base64')
      WHEN encode(substring(p_img from 1 for 4), 'escape') = '/9j/'
        THEN decode(convert_from(p_img, 'UTF8'), 'base64')
      WHEN encode(substring(p_img from 1 for 6), 'escape') = 'R0lGOD'
        THEN decode(convert_from(p_img, 'UTF8'), 'base64')
      ELSE p_img
    END;

    IF v_norm IS NULL OR octet_length(v_norm) < 8 THEN
      RETURN NULL;
    END IF;

    RETURN CASE
      WHEN substring(v_norm from 1 for 4) = decode('89504e47', 'hex')
        THEN v_norm  -- PNG
      WHEN substring(v_norm from 1 for 3) = decode('ffd8ff', 'hex')
        THEN v_norm  -- JPG
      WHEN substring(v_norm from 1 for 4) = decode('47494638', 'hex')
        THEN v_norm  -- GIF
      WHEN substring(v_norm from 1 for 2) = decode('424d', 'hex')
        THEN v_norm  -- BMP
      WHEN substring(v_norm from 1 for 4) = decode('52494646', 'hex')
        THEN v_norm  -- RIFF/WEBP
      ELSE NULL
    END;
  EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
  END;
  $$;


--
-- Name: fn_nome_dia_semana(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_nome_dia_semana(data timestamp without time zone) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
  return (
    select (
      case when data is not null then
        case (SELECT EXTRACT(DOW FROM data)) 
          when 0 then 'Domingo'
          when 1 then 'Segunda'
          when 2 then 'Terça'
          when 3 then 'Quarta'
          when 4 then 'Quinta'
          when 5 then 'Sexta'
          when 6 then 'Sábado'
          end
        else
        null end )
  );
END
$$;


--
-- Name: fn_nova_venda(integer, integer, integer, character, integer, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_nova_venda(param_idempresa integer, param_idcliente integer, param_idusuario integer, param_tipo character, param_idcaixa integer, param_cpf character varying, param_nome character varying, param_terminal character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
 
DECLARE 
    id_venda integer; 
BEGIN 
    SELECT coalesce(max(ven_001),0)+1 into id_venda from venda where emp_001=param_idempresa; 
    INSERT INTO venda (ven_001, ven_029, ven_004, emp_001, cli_001, sit_001, b_taxa_entrega, usu_001_1, dat_001_1, 
                       ven_024, id_caixa_abertura, cpf_cliente, nome_cliente, terminal_abertura) 
    VALUES (id_venda, id_venda, LOCALTIMESTAMP, param_idempresa, param_idcliente, 0, false, param_idusuario, LOCALTIMESTAMP,  
            param_tipo, param_idcaixa, param_cpf, param_nome, param_terminal); 
    RETURN id_venda; 
END 
$$;


--
-- Name: fn_parcelar_valor(numeric, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_parcelar_valor(valor numeric, parcelas integer, casas_decimais integer, OUT valor_parcelado numeric, OUT parcela_unica numeric) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
  DECLARE
    PARC1 NUMERIC(15, 4);
    PARC2 NUMERIC(15, 4);
    CASAS INTEGER;
  BEGIN
    CASAS = (10 ^ CASAS_DECIMAIS);
    PARC1 = (VALOR / PARCELAS) * CASAS;
    PARC1 = ROUND(PARC1, 0);
    PARC1 = PARC1 / CASAS;
    --------
    PARC2 = (PARC1 * (PARCELAS - 1));
    PARC2 = VALOR - PARC2;
    --------
    RETURN QUERY SELECT PARC1, PARC2;  
  END;
$$;


--
-- Name: fn_saldo_caixa(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_saldo_caixa(idcaixa integer, idempresa integer) RETURNS numeric
    LANGUAGE sql
    AS $$select 
--  valor inicial + total_mesa + total_delivery + total_balcao +
--  total_comanda + total_pdv + total_suprimento - total_retirada + 
--  total_outros_creditos - total_outros_debitos - estorno_antecipado + pagamento_antecipado
( c.valor_inicial + 
coalesce(cvmdbc.valor_total, 0.00) + 
coalesce(csupr.valor_total, 0.00) - 
coalesce(cret.valor_total, 0.00) -
coalesce(cest.valor_total, 0.00) +
coalesce(cant.valor_total, 0.00)) 
from caixa c 
left join --mesa, delivery, balcao, comanda, pdv
( select sum(ci.valor) as valor_total,  ci.id_empresa, ci.id_caixa  from caixaitem ci
join venda v on v.ven_001=ci.id_venda and ci.id_empresa=v.emp_001
join encerravenda ev on ev.emp_001=ci.id_empresa and ev.ven_001=ci.id_venda
join encerravendaitem evi on evi.emp_001=ci.id_empresa and evi.enc_001=ev.enc_001 and ci.item_encerravenda=evi.ite_001
join formapgto fp on fp.for_001 = ci.id_formapgto and fp.emp_001 = ci.id_empresa and fp.b_fiado = false
where v.ven_024 in ('M', 'D', 'B', 'C', 'P') and ci.tipo_movimento='E' and ev.sit_001=1 and ci.classificacao='V' and ci.antecipado = false
group by ci.id_empresa, ci.id_caixa ) cvmdbc on c.id_caixa=cvmdbc.id_caixa and c.id_empresa=cvmdbc.id_empresa
left join
(select sum(ci.valor) as valor_total, ci.id_empresa, ci.id_caixa  from caixaitem ci
where tipo_movimento='E' and classificacao in ('S', 'C')
group by ci.id_empresa, ci.id_caixa) csupr on c.id_caixa=csupr.id_caixa and c.id_empresa=csupr.id_empresa
left join 
(select sum(ci.valor) as valor_total, ci.id_empresa, ci.id_caixa  from caixaitem ci
where tipo_movimento='S' and classificacao in ('R', 'D') 
group by ci.id_empresa, ci.id_caixa) cret on c.id_caixa=cret.id_caixa and c.id_empresa=cret.id_empresa

left join 
(select sum(ci.valor) as valor_total, ci.id_empresa, ci.id_caixa  from caixaitem ci
where tipo_movimento='S' and classificacao in ('E') and ci.antecipado = true 
group by ci.id_empresa, ci.id_caixa) cest on c.id_caixa=cest.id_caixa and c.id_empresa=cest.id_empresa

left join 
(select sum(ci.valor) as valor_total, ci.id_empresa, ci.id_caixa  from caixaitem ci
where tipo_movimento='E' and classificacao in ('V') and ci.antecipado = true 
group by ci.id_empresa, ci.id_caixa) cant on c.id_caixa=cant.id_caixa and c.id_empresa=cant.id_empresa

where c.id_empresa=idempresa and c.id_caixa=idcaixa
$$;


--
-- Name: fn_situacoes(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_situacoes(indice integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
   RETURN (SELECT (CASE INDICE
										WHEN 0
											THEN 'DIGITAÇÃO'
										WHEN 1
											THEN 'ENCERRADO(A)'
										WHEN 2
											THEN 'CANCELADO(A)'
										WHEN 3
											THEN 'INATIVO(A)'
										WHEN 4
											THEN 'ATIVO(A)'
										WHEN 5
											THEN 'BLOQUEADO(A)'
										WHEN 6
											THEN 'ENVIADO(A)'
										WHEN 7
											THEN 'PAGO(A)'
										WHEN 8
											THEN 'PENDENTE'
										WHEN 9
											THEN 'APROVADO(A)'
										WHEN 10
											THEN 'AGUARDANDO AUTORIZAÇÃO'
										WHEN 11
											THEN 'AUTORIZADO(A)'
										WHEN 12
											THEN 'NENHUM(A)'
										WHEN 13
											THEN 'PARCIAL'
										WHEN 14
											THEN 'ENTREGUE'
										WHEN 15
											THEN 'AGUARDANDO LIBERAÇÃO'
										WHEN 16
											THEN 'SUSTADO'
										WHEN 17
											THEN 'CUSTODIA'
										WHEN 18
											THEN 'DEPOSITADO'
										WHEN 19
											THEN 'RESERVADO(A)'
										WHEN 20
											THEN 'AGUARDANDO FATURAMENTO'
										WHEN 21
											THEN 'IMPRESSO'		
										WHEN 22
											THEN 'REJEITADO'
										WHEN 23
											THEN 'TRANSMITIDO'
										WHEN 24
											THEN 'CANCELADO'
										ELSE ''     
									END));
END
$$;


--
-- Name: fn_string_opcionais(integer, integer, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_string_opcionais(param_id_venda integer, param_id_item integer, param_id_empresa integer, exibe_valor boolean) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
  
  DECLARE
    str_opcionais varchar :='';
    quebra_linha constant varchar  := E'\r\n';
    rec_opcionais RECORD;  
    cur_opcionais CURSOR (id_ven integer, id_item integer,  id_emp  integer) FOR  
			select 0 as id_opcional,     
			       cast(concat('Obs: ', ite.ite_006) as varchar(200)) as descricao,
			       0.00 as valor
			from vendaitem ite
			where ite.emp_001 = id_emp
			and   ite.ven_001 = id_ven
			and   ite.ite_001 = id_item
			and not ite.sit_001 in (0,1,2,3) and not (ite.ite_006 is null or ite.ite_006='')
			union all

			select 
			vio.id_opcional, 
			cast(concat('Opc: ', o.descricao) as varchar(200)) as descricao, 
			o.valor 
			from vendaitemopcional vio 
			join opcional o on o.id_opcional=vio.id_opcional and o.id_empresa=vio.id_empresa
			where vio.id_venda=id_ven
			and vio.id_empresa=id_emp
			and vio.id_vendaitem = id_item
			order by 1,2;
  BEGIN
    OPEN cur_opcionais(param_id_venda, param_id_item, param_id_empresa);
    LOOP
      -- fetch row into the record
      FETCH cur_opcionais INTO rec_opcionais;
      -- exit when no more row to fetch
      EXIT WHEN NOT FOUND;
      -- build the output
      if exibe_valor then
        str_opcionais := concat(str_opcionais, rec_opcionais.descricao, '(', to_char(rec_opcionais.valor, 'FM999990D00'), ')', quebra_linha);
      else
        str_opcionais := concat(str_opcionais, rec_opcionais.descricao, quebra_linha);
      end if;
      
   END LOOP;
   -- Close the cursor
   CLOSE cur_opcionais;
   return str_opcionais;
   END;
$$;


--
-- Name: fn_total_itens_venda(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_total_itens_venda(param_idvenda integer, param_idempresa integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE total_itens decimal(15,2);
BEGIN
    perform fn_calcula_acrescimos_itens_venda(param_idvenda, param_idempresa);
    SELECT coalesce(SUM( coalesce(ITE.ITE_005,0.00)),0.00) into total_itens FROM VENDAITEM ITE
      WHERE ITE.EMP_001 = param_idempresa
      AND   ITE.VEN_001 = param_idvenda
      AND   not ITE.sit_001 in (0,1,2,3);
      return total_itens;
END
$$;


--
-- Name: formapgto_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.formapgto_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
      IF EXISTS (
          SELECT 1
            FROM public.configuracao_funcionamento cf
           WHERE cf.id_empresa = NEW.emp_001
             AND (
                  COALESCE(cf.utiliza_controle_rpfood, false)
               OR COALESCE(cf.utiliza_controle_rpmenu, false)
             )
      ) THEN
          INSERT INTO public.transf_rp_food_menu (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar)
          VALUES ('FORMAPGTOS', NEW.for_001, NEW.emp_001, NULL, NULL)
          ON CONFLICT DO NOTHING;
      END IF;

      RETURN NEW;
  END;
  $$;


--
-- Name: is_atendimento_disponivel(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_atendimento_disponivel() RETURNS boolean
    LANGUAGE plpgsql
    AS $$                                                                    
  DECLARE                                                                     
  atendimento_disponivel BOOLEAN := false;                                    
  config configuracao_funcionamento%ROWTYPE;                                  
  current_day_of_week INTEGER;                                                
  current_local_time TIME;                                                    
 BEGIN                                                                        
  current_day_of_week := EXTRACT(DOW FROM CURRENT_DATE)::INTEGER;             
 current_local_time := (SELECT Current_Time at time zone 'America/Sao_Paulo'); 
 SELECT * INTO config FROM configuracao_funcionamento LIMIT 1;           
 CASE current_day_of_week                                                
    WHEN 1 THEN                                                          
       atendimento_disponivel := (config.dia_segunda) AND                
          ((current_local_time >= config.segunda_inicio_atendimento AND  
            current_local_time <= config.segunda_fim_atendimento) OR     
   (current_local_time >= config.segunda_inicio_atendimento_p2 AND       
            current_local_time <= config.segunda_fim_atendimento_p2));   
  WHEN 2 THEN                                                            
     atendimento_disponivel := (config.dia_terca) AND                    
        ((current_local_time >= config.terca_inicio_atendimento AND      
         current_local_time <= config.terca_fim_atendimento) OR          
   (current_local_time >= config.terca_inicio_atendimento_p2 AND         
           current_local_time <= config.terca_fim_atendimento_p2));      
  WHEN 3 THEN                                                            
      atendimento_disponivel := (config.dia_quarta) AND                  
        ((current_local_time >= config.quarta_inicio_atendimento AND     
          current_local_time <= config.quarta_fim_atendimento) OR        
  (current_local_time >= config.quarta_inicio_atendimento_p2 AND         
            current_local_time <= config.quarta_fim_atendimento_p2));    
   WHEN 4 THEN                                                           
      atendimento_disponivel := (config.dia_quinta) AND                  
         ((current_local_time >= config.quinta_inicio_atendimento AND    
        current_local_time <= config.quinta_fim_atendimento) OR          
   (current_local_time >= config.quinta_inicio_atendimento_p2 AND        
         current_local_time <= config.quinta_fim_atendimento_p2));       
  WHEN 5 THEN                                                            
      atendimento_disponivel := (config.dia_sexta) AND                   
         ((current_local_time >= config.sexta_inicio_atendimento AND     
           current_local_time <= config.sexta_fim_atendimento) OR        
  (current_local_time >= config.sexta_inicio_atendimento_p2 AND          
           current_local_time <= config.sexta_fim_atendimento_p2));      
  WHEN 6 THEN                                                            
      atendimento_disponivel := (config.dia_sabado) AND                  
        ((current_local_time >= config.sabado_inicio_atendimento AND     
           current_local_time <= config.sabado_fim_atendimento) OR       
  (current_local_time >= config.sabado_inicio_atendimento_p2 AND         
          current_local_time <= config.sabado_fim_atendimento_p2));      
  WHEN 0 THEN                                                            
     atendimento_disponivel := (config.dia_domingo) AND                  
       ((current_local_time >= config.domingo_inicio_atendimento AND     
          current_local_time <= config.domingo_fim_atendimento) OR       
  (current_local_time >= config.domingo_inicio_atendimento_p2 AND        
            current_local_time <= config.domingo_fim_atendimento_p2));   
 END CASE;                                                               
                                                                         
  RETURN atendimento_disponivel;                                         
 END;  $$;


--
-- Name: make_date(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.make_date(year integer, month integer, day integer) RETURNS date
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
SELECT format('%s-%s-%s', year, month, day)::date;
$$;


--
-- Name: materiais_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.materiais_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
      IF EXISTS (
          SELECT 1
            FROM public.configuracao_funcionamento cf
           WHERE cf.id_empresa = NEW.emp_001
             AND (
                  COALESCE(cf.utiliza_controle_rpfood, false)
               OR COALESCE(cf.utiliza_controle_rpmenu, false)
             )
      ) THEN
          INSERT INTO public.transf_rp_food_menu (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar)
          VALUES ('MATERIAIS', NEW.mat_001, NEW.emp_001, NULL, NULL)
          ON CONFLICT DO NOTHING;
      END IF;

      RETURN NEW;
  END;
  $$;


--
-- Name: materiaisopcionais_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.materiaisopcionais_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF EXISTS (
            SELECT 1
            FROM public.configuracao_funcionamento cf
            WHERE cf.id_empresa = OLD.id_empresa
              AND (
                    COALESCE(cf.utiliza_controle_rpfood, FALSE)
                 OR COALESCE(cf.utiliza_controle_rpmenu, FALSE)
              )
        ) THEN
            INSERT INTO public.transf_rp_food_menu
                (
                    tipo,
                    id_registro,
                    id_empresa,
                    id_registro_secundario,
                    auxiliar,
                    registro_deletado
                )
            VALUES
                (
                    'MATERIAISOPCIONAIS',
                    OLD.id_material,
                    OLD.id_empresa,
                    OLD.id_opcional,
                    NULL,
                    TRUE
                )
            ON CONFLICT (
                tipo,
                id_registro,
                id_empresa,
                id_registro_secundario,
                auxiliar
            )
            DO UPDATE
            SET registro_deletado = EXCLUDED.registro_deletado;
        END IF;

        RETURN OLD;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.configuracao_funcionamento cf
        WHERE cf.id_empresa = NEW.id_empresa
          AND (
                COALESCE(cf.utiliza_controle_rpfood, FALSE)
             OR COALESCE(cf.utiliza_controle_rpmenu, FALSE)
          )
    ) THEN
        INSERT INTO public.transf_rp_food_menu
            (
                tipo,
                id_registro,
                id_empresa,
                id_registro_secundario,
                auxiliar,
                registro_deletado
            )
        VALUES
            (
                'MATERIAISOPCIONAIS',
                NEW.id_material,
                NEW.id_empresa,
                NEW.id_opcional,
                NULL,
                FALSE
            )
        ON CONFLICT (
            tipo,
            id_registro,
            id_empresa,
            id_registro_secundario,
            auxiliar
        )
        DO UPDATE
        SET registro_deletado = EXCLUDED.registro_deletado;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: mesa_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mesa_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
      IF EXISTS (
          SELECT 1
            FROM public.configuracao_funcionamento cf
           WHERE cf.id_empresa = NEW.emp_001
             AND COALESCE(cf.utiliza_controle_rpmenu, false)
      ) THEN
          INSERT INTO public.transf_rp_food_menu (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar)
          VALUES ('MESAS', NEW.mes_001, NEW.emp_001, NULL, NULL)
          ON CONFLICT DO NOTHING;
      END IF;

      RETURN NEW;
  END;
  $$;


--
-- Name: opcional_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.opcional_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
      IF EXISTS (
          SELECT 1
            FROM public.configuracao_funcionamento cf
           WHERE cf.id_empresa = NEW.id_empresa
             AND (
                  COALESCE(cf.utiliza_controle_rpfood, false)
               OR COALESCE(cf.utiliza_controle_rpmenu, false)
             )
      ) THEN
          INSERT INTO public.transf_rp_food_menu (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar)
          VALUES ('OPCIONAIS', NEW.id_opcional, NEW.id_empresa, NULL, NULL)
          ON CONFLICT DO NOTHING;
      END IF;

      RETURN NEW;
  END;
  $$;


--
-- Name: proc_recalcular_margem_lucro(integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.proc_recalcular_margem_lucro(IN p_ven_001 integer, IN p_emp_001 integer)
    LANGUAGE sql
    AS $$ 
UPDATE vendaitem AS vi 
SET 
    -- Custos com arredondamento para 2 casas decimais
    custoproduto    = sub.custo_produto_total,
    custocomposicao = sub.custo_composicao_total,
    -- Margem de lucro em percentual
    margemlucro     = sub.margem_calculada 
FROM ( 
    SELECT 
        vi.ite_001, 
        
        -- Cálculo dos custos totais (com arredondamento)
        CASE WHEN vi.b_devolucao THEN 0.00 ELSE ROUND(COALESCE(m.mat_012, 0) * COALESCE(vi.ite_002, 0), 2) END AS custo_produto_total,
        CASE WHEN vi.b_devolucao THEN 0.00 ELSE ROUND(COALESCE(m.mat_006, 0) * COALESCE(vi.ite_002, 0), 2) END AS custo_composicao_total,
        
        -- Cálculo da margem de lucro
        -- Fórmula: ((valor_venda - custo_total) / custo_total) * 100
        CASE 
            WHEN vi.b_devolucao THEN 0.00 
            WHEN (COALESCE(m.mat_012, 0) + COALESCE(m.mat_006, 0)) * COALESCE(vi.ite_002, 0) > 0 
             AND (COALESCE(vi.ite_002, 0) * COALESCE(vi.ite_003, 0) + COALESCE(vi.acrescimo, 0) + COALESCE(vi.acrescimorateio, 0) - COALESCE(vi.desconto, 0) - COALESCE(vi.descontorateio, 0)) > 0
            THEN 100 * (
                ((COALESCE(vi.ite_002, 0) * COALESCE(vi.ite_003, 0) + COALESCE(vi.acrescimo, 0) + COALESCE(vi.acrescimorateio, 0) - COALESCE(vi.desconto, 0) - COALESCE(vi.descontorateio, 0)) 
                 - ((COALESCE(m.mat_012, 0) + COALESCE(m.mat_006, 0)) * COALESCE(vi.ite_002, 0))) 
                / ((COALESCE(m.mat_012, 0) + COALESCE(m.mat_006, 0)) * COALESCE(vi.ite_002, 0))
            )
            ELSE 100
        END AS margem_calculada
    
    FROM vendaitem vi 
    INNER JOIN materiais m ON (
        m.mat_001 = vi.mat_001 AND
        m.emp_001 = p_emp_001
    ) 
    WHERE vi.ven_001 = p_ven_001 
      AND vi.emp_001 = p_emp_001
) AS sub 
-- FILTRO COMPLETO CORRIGIDO (igual ao original)
WHERE vi.ven_001 = p_ven_001 
  AND vi.emp_001 = p_emp_001  
  AND vi.ite_001 = sub.ite_001; 
$$;


--
-- Name: ratearsobraconsumacaominimaporitens(integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.ratearsobraconsumacaominimaporitens(IN p_id_venda integer, IN p_emp_001 integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total_taxa NUMERIC(15,2);
    v_total_base NUMERIC(15,2);
    v_total_cents BIGINT;
    v_soma_pisos BIGINT;
    v_resto_cents BIGINT;
BEGIN
    -- 1) Buscar dados da venda (taxa)
    SELECT COALESCE(sobra_consumacao_minima, 0)
    INTO v_total_taxa
    FROM venda
    WHERE ven_001 = p_id_venda AND emp_001 = p_emp_001;

    -- Se não há taxa, apenas zera e sai
    IF v_total_taxa = 0 THEN
        UPDATE vendaitem
        SET RateioConsumacaoMinima = 0
        WHERE ven_001 = p_id_venda AND emp_001 = p_emp_001;
        RETURN;
    END IF;

    -- 2) Calcular base total dos itens elegíveis
    SELECT COALESCE(SUM(vi.ite_005), 0)
    INTO v_total_base
    FROM vendaitem vi
    WHERE vi.ven_001 = p_id_venda
      AND vi.emp_001 = p_emp_001
      AND vi.sit_001 = 4;

    -- Se não há base para ratear, zera tudo e sai
    IF v_total_base = 0 THEN
        UPDATE vendaitem
        SET RateioConsumacaoMinima = 0
        WHERE ven_001 = p_id_venda AND emp_001 = p_emp_001;
        RETURN;
    END IF;

    -- 3) Converter taxa total para centavos
    v_total_cents := ROUND(v_total_taxa * 100);

    -- 4) Fazer o rateio usando CTE com algoritmo do "maior resto"
    WITH itens_elegiveis AS (
        SELECT
            vi.ite_001,
            vi.ite_005 as base_item,
            (v_total_taxa * vi.ite_005 / v_total_base * 100.0) as cota_exata_cents,
            FLOOR(v_total_taxa * vi.ite_005 / v_total_base * 100.0) as piso_cents,
            (v_total_taxa * vi.ite_005 / v_total_base * 100.0) - FLOOR(v_total_taxa * vi.ite_005 / v_total_base * 100.0) as fracao,
            ROW_NUMBER() OVER (
                ORDER BY (v_total_taxa * vi.ite_005 / v_total_base * 100.0) - FLOOR(v_total_taxa * vi.ite_005 / v_total_base * 100.0) DESC,
                         vi.ite_001 ASC
            ) as rank_resto
        FROM vendaitem vi
        WHERE vi.ven_001 = p_id_venda
          AND vi.emp_001 = p_emp_001
          AND vi.sit_001 = 4
          AND vi.ite_005 > 0
    ),
    rateio_calculado AS (
        SELECT
            ite_001,
            base_item,
            piso_cents,
            CASE
                WHEN rank_resto <= (v_total_cents - (SELECT SUM(piso_cents) FROM itens_elegiveis)) THEN piso_cents + 1
                ELSE piso_cents
            END as valor_final_cents
        FROM itens_elegiveis
    )
    -- 5) Atualizar todos os itens em uma única operação
    UPDATE vendaitem
    SET RateioConsumacaoMinima = CASE
        WHEN rc.valor_final_cents IS NOT NULL THEN rc.valor_final_cents / 100.0
        ELSE 0
    END
    FROM rateio_calculado rc
    WHERE vendaitem.emp_001 = p_emp_001
      AND vendaitem.ven_001 = p_id_venda
      AND vendaitem.ite_001 = rc.ite_001;

    -- 6) Zerar itens não elegíveis
    UPDATE vendaitem
    SET RateioConsumacaoMinima = 0
    WHERE ven_001 = p_id_venda
      AND emp_001 = p_emp_001
      AND ite_001 NOT IN (
          SELECT vi.ite_001
          FROM vendaitem vi
          WHERE vi.ven_001 = p_id_venda
            AND vi.emp_001 = p_emp_001
            AND vi.sit_001 = 4
            AND vi.ite_005 > 0
      );
END;
$$;


--
-- Name: rateartaxaentregaporitensdelivery(integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.rateartaxaentregaporitensdelivery(IN p_id_venda integer, IN p_emp_001 integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total_taxa NUMERIC(15,2);
    v_total_base NUMERIC(15,2);
    v_total_cents BIGINT;
    v_soma_pisos BIGINT;
    v_resto_cents BIGINT;
BEGIN
    -- 1) Buscar dados da venda (taxa)
    SELECT COALESCE(taxaentrega, 0)
    INTO v_total_taxa
    FROM venda 
    WHERE ven_001 = p_id_venda AND emp_001 = p_emp_001;

    -- Se não há taxa, apenas zera e sai
    IF v_total_taxa = 0 THEN
        UPDATE vendaitem 
        SET RateioTaxaEntrega = 0 
        WHERE ven_001 = p_id_venda AND emp_001 = p_emp_001;
        RETURN;
    END IF;

    -- 2) Calcular base total dos itens elegíveis
    SELECT COALESCE(SUM(vi.ite_005), 0)
    INTO v_total_base
    FROM vendaitem vi
    WHERE vi.ven_001 = p_id_venda
      AND vi.emp_001 = p_emp_001
      AND vi.sit_001 = 4;

    -- Se não há base para ratear, zera tudo e sai
    IF v_total_base = 0 THEN
        UPDATE vendaitem 
        SET RateioTaxaEntrega = 0 
        WHERE ven_001 = p_id_venda AND emp_001 = p_emp_001;
        RETURN;
    END IF;

    -- 3) Converter taxa total para centavos
    v_total_cents := ROUND(v_total_taxa * 100);

    -- 4) Fazer o rateio usando CTE com algoritmo do "maior resto"
    WITH itens_elegiveis AS (
        SELECT 
            vi.ite_001,
            vi.ite_005 as base_item,
            (v_total_taxa * vi.ite_005 / v_total_base * 100.0) as cota_exata_cents,
            FLOOR(v_total_taxa * vi.ite_005 / v_total_base * 100.0) as piso_cents,
            (v_total_taxa * vi.ite_005 / v_total_base * 100.0) - FLOOR(v_total_taxa * vi.ite_005 / v_total_base * 100.0) as fracao,
            ROW_NUMBER() OVER (
                ORDER BY 
                    (v_total_taxa * vi.ite_005 / v_total_base * 100.0) - FLOOR(v_total_taxa * vi.ite_005 / v_total_base * 100.0) DESC,
                    vi.ite_001 ASC
            ) as rank_resto
        FROM vendaitem vi
        WHERE vi.ven_001 = p_id_venda
          AND vi.emp_001 = p_emp_001
          AND vi.sit_001 = 4
          AND vi.ite_005 > 0
    ),
    rateio_calculado AS (
        SELECT 
            ite_001,
            piso_cents,
            CASE 
                WHEN rank_resto <= (v_total_cents - (SELECT SUM(piso_cents) FROM itens_elegiveis))
                THEN piso_cents + 1 
                ELSE piso_cents 
            END as valor_final_cents
        FROM itens_elegiveis
    )
    UPDATE vendaitem 
    SET RateioTaxaEntrega = CASE 
        WHEN rc.valor_final_cents IS NOT NULL THEN rc.valor_final_cents / 100.0
        ELSE 0 
    END
    FROM rateio_calculado rc
    WHERE vendaitem.emp_001 = p_emp_001
      AND vendaitem.ven_001 = p_id_venda
      AND vendaitem.ite_001 = rc.ite_001;

    -- 5) Zerar itens não elegíveis
    UPDATE vendaitem 
    SET RateioTaxaEntrega = 0 
    WHERE ven_001 = p_id_venda 
      AND emp_001 = p_emp_001
      AND ite_001 NOT IN (
          SELECT vi.ite_001
          FROM vendaitem vi
          WHERE vi.ven_001 = p_id_venda
            AND vi.emp_001 = p_emp_001
            AND vi.sit_001 = 4
            AND vi.ite_005 > 0
      );

END;
$$;


--
-- Name: rateartaxaformaporitensvenda(integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.rateartaxaformaporitensvenda(IN p_id_venda integer, IN p_emp_001 integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total_taxa NUMERIC(15,2);
    v_total_base NUMERIC(15,2);
    v_total_cents BIGINT;
    v_soma_pisos BIGINT;
    v_resto_cents BIGINT;
BEGIN
    -- 1) Buscar dados da venda (taxa de forma de pagamento)
    SELECT COALESCE(taxajurosformapagamento, 0)
    INTO v_total_taxa
    FROM venda 
    WHERE ven_001 = p_id_venda AND emp_001 = p_emp_001;

    IF v_total_taxa = 0 THEN
        UPDATE vendaitem SET RateioTaxaForma = 0 
        WHERE ven_001 = p_id_venda AND emp_001 = p_emp_001;
        RETURN;
    END IF;

    -- 2) Calcular base total dos itens elegíveis
    SELECT COALESCE(SUM(vi.ite_005), 0)
    INTO v_total_base
    FROM vendaitem vi
    WHERE vi.ven_001 = p_id_venda
      AND vi.emp_001 = p_emp_001
      AND vi.sit_001 = 4
      AND vi.ite_005 >= 0;

    IF v_total_base = 0 THEN
        UPDATE vendaitem SET RateioTaxaForma = 0 
        WHERE ven_001 = p_id_venda AND emp_001 = p_emp_001;
        RETURN;
    END IF;

    -- 3) Converter taxa total para centavos
    v_total_cents := ROUND(v_total_taxa * 100);

    -- 4) Rateio usando algoritmo do maior resto
    WITH itens_elegiveis AS (
        SELECT
            vi.ite_001,
            vi.ite_005 as base_item,
            (v_total_taxa * vi.ite_005 / v_total_base * 100.0) as cota_exata_cents,
            FLOOR(v_total_taxa * vi.ite_005 / v_total_base * 100.0) as piso_cents,
            (v_total_taxa * vi.ite_005 / v_total_base * 100.0) - FLOOR(v_total_taxa * vi.ite_005 / v_total_base * 100.0) as fracao,
            ROW_NUMBER() OVER (
                ORDER BY 
                    (v_total_taxa * vi.ite_005 / v_total_base * 100.0) - FLOOR(v_total_taxa * vi.ite_005 / v_total_base * 100.0) DESC,
                    vi.ite_001 ASC
            ) as rank_resto
        FROM vendaitem vi
        WHERE vi.ven_001 = p_id_venda
          AND vi.emp_001 = p_emp_001
          AND vi.sit_001 = 4
          AND vi.ite_005 > 0
    ),
    rateio_calculado AS (
        SELECT
            ite_001,
            piso_cents,
            CASE
                WHEN rank_resto <= (v_total_cents - (SELECT SUM(piso_cents) FROM itens_elegiveis))
                THEN piso_cents + 1
                ELSE piso_cents
            END as valor_final_cents
        FROM itens_elegiveis
    )
    UPDATE vendaitem
    SET RateioTaxaForma = CASE
        WHEN rc.valor_final_cents IS NOT NULL THEN rc.valor_final_cents / 100.0
        ELSE 0
    END
    FROM rateio_calculado rc
    WHERE vendaitem.emp_001 = p_emp_001
      AND vendaitem.ven_001 = p_id_venda
      AND vendaitem.ite_001 = rc.ite_001;

    -- 5) Zerar itens não elegíveis
    UPDATE vendaitem
    SET RateioTaxaForma = 0
    WHERE ven_001 = p_id_venda
      AND emp_001 = p_emp_001
      AND ite_001 NOT IN (
          SELECT vi.ite_001
          FROM vendaitem vi
          WHERE vi.ven_001 = p_id_venda
            AND vi.emp_001 = p_emp_001
            AND vi.sit_001 = 4
            AND vi.ite_005 > 0
      );
END;
$$;


--
-- Name: rateartaxagarcomporitens(integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.rateartaxagarcomporitens(IN p_id_venda integer, IN p_emp_001 integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total_taxa NUMERIC(15,2);
    v_ignorar BOOLEAN;
    v_total_base NUMERIC(15,2);
    v_total_cents BIGINT;
    v_soma_pisos BIGINT;
    v_resto_cents BIGINT;
BEGIN
    -- 1) Buscar dados da venda (taxa e flag ignorar)
    SELECT COALESCE(taxa_valor_garcom, 0), COALESCE(ignorar_taxa_garcom, false)
    INTO v_total_taxa, v_ignorar
    FROM venda
    WHERE ven_001 = p_id_venda AND emp_001 = p_emp_001;

    IF v_ignorar OR v_total_taxa = 0 THEN
        UPDATE vendaitem SET RateioTaxaGarcom = 0 
        WHERE ven_001 = p_id_venda AND emp_001 = p_emp_001;
        RETURN;
    END IF;

    -- 2) Calcular base total dos itens elegíveis
    SELECT COALESCE(SUM(vi.ite_005), 0)
    INTO v_total_base
    FROM vendaitem vi
    INNER JOIN materiais m ON m.mat_001 = vi.mat_001 AND m.emp_001 = vi.emp_001
    WHERE vi.ven_001 = p_id_venda
      AND vi.emp_001 = p_emp_001
      AND vi.sit_001 = 4
      AND COALESCE(m.b_nao_taxa, false) = false;

    IF v_total_base = 0 THEN
        UPDATE vendaitem SET RateioTaxaGarcom = 0 
        WHERE ven_001 = p_id_venda AND emp_001 = p_emp_001;
        RETURN;
    END IF;

    -- 3) Converter taxa total para centavos
    v_total_cents := ROUND(v_total_taxa * 100);

    -- 4) Rateio usando algoritmo do maior resto
    WITH itens_elegiveis AS (
        SELECT
            vi.ite_001,
            vi.ite_005 as base_item,
            (v_total_taxa * vi.ite_005 / v_total_base * 100.0) as cota_exata_cents,
            FLOOR(v_total_taxa * vi.ite_005 / v_total_base * 100.0) as piso_cents,
            (v_total_taxa * vi.ite_005 / v_total_base * 100.0) - FLOOR(v_total_taxa * vi.ite_005 / v_total_base * 100.0) as fracao,
            ROW_NUMBER() OVER (
                ORDER BY 
                    (v_total_taxa * vi.ite_005 / v_total_base * 100.0) - FLOOR(v_total_taxa * vi.ite_005 / v_total_base * 100.0) DESC,
                    vi.ite_001 ASC
            ) as rank_resto
        FROM vendaitem vi
        INNER JOIN materiais m ON m.mat_001 = vi.mat_001 AND m.emp_001 = vi.emp_001
        WHERE vi.ven_001 = p_id_venda
          AND vi.emp_001 = p_emp_001
          AND vi.sit_001 = 4
          AND COALESCE(m.b_nao_taxa, false) = false
          AND vi.ite_005 > 0
    ),
    rateio_calculado AS (
        SELECT
            ite_001,
            piso_cents,
            CASE
                WHEN rank_resto <= (v_total_cents - (SELECT SUM(piso_cents) FROM itens_elegiveis))
                THEN piso_cents + 1
                ELSE piso_cents
            END as valor_final_cents
        FROM itens_elegiveis
    )
    UPDATE vendaitem
    SET RateioTaxaGarcom = CASE
        WHEN rc.valor_final_cents IS NOT NULL THEN rc.valor_final_cents / 100.0
        ELSE 0
    END
    FROM rateio_calculado rc
    WHERE vendaitem.emp_001 = p_emp_001
      AND vendaitem.ven_001 = p_id_venda
      AND vendaitem.ite_001 = rc.ite_001;

    -- 5) Zerar itens não elegíveis
    UPDATE vendaitem
    SET RateioTaxaGarcom = 0
    WHERE ven_001 = p_id_venda
      AND emp_001 = p_emp_001
      AND ite_001 NOT IN (
          SELECT vi.ite_001
          FROM vendaitem vi
          INNER JOIN materiais m ON m.mat_001 = vi.mat_001 AND m.emp_001 = vi.emp_001
          WHERE vi.ven_001 = p_id_venda
            AND vi.emp_001 = p_emp_001
            AND vi.sit_001 = 4
            AND COALESCE(m.b_nao_taxa, false) = false
            AND vi.ite_005 > 0
      );
END;
$$;


--
-- Name: rateartaxaintegracaoporitensdelivery(integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.rateartaxaintegracaoporitensdelivery(IN p_id_venda integer, IN p_emp_001 integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    v_total_taxa NUMERIC(15,2);
    v_total_base NUMERIC(15,2);
    v_total_cents BIGINT;
    v_soma_pisos BIGINT;
    v_resto_cents BIGINT;
BEGIN
    -- 1) Buscar dados da venda (taxa)
    SELECT COALESCE(integracao_taxa, 0)
    INTO v_total_taxa
    FROM venda
    WHERE ven_001 = p_id_venda AND emp_001 = p_emp_001;

    -- Se não há taxa, apenas zera e sai
    IF v_total_taxa = 0 THEN
        UPDATE vendaitem
        SET RateioTaxaIntegracao = 0
        WHERE ven_001 = p_id_venda AND emp_001 = p_emp_001;
        RETURN;
    END IF;

    -- 2) Calcular base total dos itens elegíveis
    SELECT COALESCE(SUM(vi.ite_005), 0)
    INTO v_total_base
    FROM vendaitem vi
    WHERE vi.ven_001 = p_id_venda
      AND vi.emp_001 = p_emp_001
      AND vi.sit_001 = 4;

    -- Se não há base para ratear, zera tudo e sai
    IF v_total_base = 0 THEN
        UPDATE vendaitem
        SET RateioTaxaIntegracao = 0
        WHERE ven_001 = p_id_venda AND emp_001 = p_emp_001;
        RETURN;
    END IF;

    -- 3) Converter taxa total para centavos
    v_total_cents := ROUND(v_total_taxa * 100);

    -- 4) Fazer o rateio usando CTE com algoritmo do "maior resto"
    WITH itens_elegiveis AS (
        SELECT
            vi.ite_001,
            vi.ite_005 as base_item,
            (v_total_taxa * vi.ite_005 / v_total_base * 100.0) as cota_exata_cents,
            FLOOR(v_total_taxa * vi.ite_005 / v_total_base * 100.0) as piso_cents,
            (v_total_taxa * vi.ite_005 / v_total_base * 100.0) - FLOOR(v_total_taxa * vi.ite_005 / v_total_base * 100.0) as fracao,
            ROW_NUMBER() OVER (
                ORDER BY (v_total_taxa * vi.ite_005 / v_total_base * 100.0) - FLOOR(v_total_taxa * vi.ite_005 / v_total_base * 100.0) DESC,
                         vi.ite_001 ASC
            ) as rank_resto
        FROM vendaitem vi
        WHERE vi.ven_001 = p_id_venda
          AND vi.emp_001 = p_emp_001
          AND vi.sit_001 = 4
          AND vi.ite_005 > 0
    ),
    rateio_calculado AS (
        SELECT
            ite_001,
            base_item,
            piso_cents,
            CASE
                WHEN rank_resto <= (v_total_cents - (SELECT SUM(piso_cents) FROM itens_elegiveis)) THEN piso_cents + 1
                ELSE piso_cents
            END as valor_final_cents
        FROM itens_elegiveis
    )
    -- 5) Atualizar os itens com os valores rateados
    UPDATE vendaitem
    SET RateioTaxaIntegracao = CASE
        WHEN rc.valor_final_cents IS NOT NULL THEN rc.valor_final_cents / 100.0
        ELSE 0
    END
    FROM rateio_calculado rc
    WHERE vendaitem.emp_001 = p_emp_001
      AND vendaitem.ven_001 = p_id_venda
      AND vendaitem.ite_001 = rc.ite_001;

    -- 6) Zerar itens não elegíveis
    UPDATE vendaitem
    SET RateioTaxaIntegracao = 0
    WHERE ven_001 = p_id_venda
      AND emp_001 = p_emp_001
      AND ite_001 NOT IN (
          SELECT vi.ite_001
          FROM vendaitem vi
          WHERE vi.ven_001 = p_id_venda
            AND vi.emp_001 = p_emp_001
            AND vi.sit_001 = 4
            AND vi.ite_005 > 0
      );
END;
$$;


--
-- Name: sequenciador(character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sequenciador(tabela character varying, emp integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
   DECLARE
      sSQL VARCHAR(100);
      iSEQ INTEGER;
   BEGIN 
    --  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;     
      BEGIN     
            SELECT SEQ_001 INTO iSEQ FROM SEQUENCIAS WHERE EMP_001 = EMP AND upper(TBD_001) = upper(TABELA);
            -------
            IF COALESCE(iSEQ, 0) = 0 THEN
               iSEQ := 1;
               INSERT INTO SEQUENCIAS(EMP_001, TBD_001, SEQ_001) VALUES(EMP, upper(TABELA), 1);
            ELSE
               iSEQ := iSEQ + 1;
               UPDATE SEQUENCIAS SET SEQ_001 = iSEQ WHERE EMP_001 = EMP AND upper(TBD_001) = upper(TABELA);                
            END IF;
            -------            
            RETURN iSEQ; 
      EXCEPTION
         WHEN OTHERS THEN BEGIN
            RETURN 0;
            ROLLBACK; 
         END;
      END;
   END;
$$;


--
-- Name: usuarios_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.usuarios_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
      IF EXISTS (
          SELECT 1
            FROM public.configuracao_funcionamento cf
           WHERE cf.id_empresa = NEW.emp_001
             AND (
                  COALESCE(cf.utiliza_controle_rpfood, false)
               OR COALESCE(cf.utiliza_controle_rpmenu, false)
             )
      ) THEN
          INSERT INTO public.transf_rp_food_menu (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar)
          VALUES ('USUARIOS', NEW.usu_001, NEW.emp_001, NULL, NULL)
          ON CONFLICT DO NOTHING;
      END IF;

      RETURN NEW;
  END;
  $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: aliquotas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.aliquotas (
    id integer NOT NULL,
    uf character varying(2) DEFAULT NULL::character varying,
    c_ac numeric(10,2) DEFAULT 0.0,
    c_al numeric(10,2) DEFAULT 0.0,
    c_am numeric(10,2) DEFAULT 0.0,
    c_ap numeric(10,2) DEFAULT 0.0,
    c_ba numeric(10,2) DEFAULT 0.0,
    c_ce numeric(10,2) DEFAULT 0.0,
    c_df numeric(10,2) DEFAULT 0.0,
    c_es numeric(10,2) DEFAULT 0.0,
    c_go numeric(10,2) DEFAULT 0.0,
    c_ma numeric(10,2) DEFAULT 0.0,
    c_mt numeric(10,2) DEFAULT 0.0,
    c_ms numeric(10,2) DEFAULT 0.0,
    c_mg numeric(10,2) DEFAULT 0.0,
    c_pa numeric(10,2) DEFAULT 0.0,
    c_pb numeric(10,2) DEFAULT 0.0,
    c_pr numeric(10,2) DEFAULT 0.0,
    c_pe numeric(10,2) DEFAULT 0.0,
    c_pi numeric(10,2) DEFAULT 0.0,
    c_rn numeric(10,2) DEFAULT 0.0,
    c_rs numeric(10,2) DEFAULT 0.0,
    c_rj numeric(10,2) DEFAULT 0.0,
    c_ro numeric(10,2) DEFAULT 0.0,
    c_rr numeric(10,2) DEFAULT 0.0,
    c_sc numeric(10,2) DEFAULT 0.0,
    c_sp numeric(10,2) DEFAULT 0.0,
    c_se numeric(10,2) DEFAULT 0.0,
    c_to numeric(10,2) DEFAULT 0.0
);


--
-- Name: aliquotas_fcp_uf; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.aliquotas_fcp_uf (
    id integer NOT NULL,
    cuf integer NOT NULL,
    uf character(2) NOT NULL,
    nome_uf character varying(40) NOT NULL,
    aliquota_interestadual numeric(5,2) DEFAULT 0.00 NOT NULL,
    aliquota_interna numeric(5,2) DEFAULT 0.00 NOT NULL
);


--
-- Name: ambiente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ambiente (
    id_ambiente integer NOT NULL,
    id_empresa integer NOT NULL,
    descricao character varying(50),
    id_situacao integer
);


--
-- Name: ambiente_id_ambiente_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ambiente_id_ambiente_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ambiente_id_ambiente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ambiente_id_ambiente_seq OWNED BY public.ambiente.id_ambiente;


--
-- Name: bairro; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bairro (
    bai_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    bai_002 character varying(60) NOT NULL,
    bai_003 numeric(15,2),
    sit_001 integer DEFAULT 4 NOT NULL,
    usu_001_1 integer,
    usu_001_2 integer,
    usu_001_3 integer,
    dat_001_1 timestamp without time zone,
    dat_001_2 timestamp without time zone,
    dat_001_3 timestamp without time zone,
    b_restricao_entrega boolean DEFAULT false NOT NULL
);


--
-- Name: bairro_ceps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bairro_ceps (
    bai_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    cep character varying(9) NOT NULL,
    logradouro character varying(125),
    id_cidade integer,
    cidade_desc character varying(75),
    uf_sigla character varying(2)
);


--
-- Name: balanca_info_extra; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.balanca_info_extra (
    inf_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    descricao character varying(40) NOT NULL,
    extra text NOT NULL,
    sit_001 integer DEFAULT 4 NOT NULL
);


--
-- Name: balanca_info_nutri; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.balanca_info_nutri (
    nut_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    descricao character varying(40) NOT NULL,
    porcao integer NOT NULL,
    un_porcao integer NOT NULL,
    int_med_caseira integer NOT NULL,
    dec_med_caseira integer NOT NULL,
    medida_caseira character varying(2) NOT NULL,
    valor_energetico integer NOT NULL,
    carboidratos numeric(15,1) NOT NULL,
    proteinas numeric(15,1) NOT NULL,
    gorduras_totais numeric(15,1) NOT NULL,
    gorduras_saturadas numeric(15,1) NOT NULL,
    gorduras_trans numeric(15,1) NOT NULL,
    fibra_alimentar numeric(15,1) NOT NULL,
    sodio numeric(15,1) NOT NULL,
    sit_001 integer DEFAULT 4 NOT NULL,
    calcular_automaticamente_porcoes_rdc429 boolean DEFAULT false CONSTRAINT balanca_info_nutri_calcular_automaticamente_porcoes_rd_not_null NOT NULL,
    porcoes_embalagem_rdc429 integer DEFAULT 0 NOT NULL,
    porcao_rdc429 integer DEFAULT 0 NOT NULL,
    un_porcao_rdc429 integer DEFAULT 0 NOT NULL,
    int_med_caseira_rdc429 integer DEFAULT 0 NOT NULL,
    dec_med_caseira_rdc429 integer DEFAULT 0 NOT NULL,
    medida_caseira_rdc429 character varying(2) DEFAULT '00'::character varying NOT NULL,
    valor_energetico_rdc429 integer DEFAULT 0 NOT NULL,
    carboidratos_rdc429 numeric(15,1) DEFAULT '0'::numeric NOT NULL,
    proteinas_rdc429 numeric(15,1) DEFAULT '0'::numeric NOT NULL,
    gorduras_totais_rdc429 numeric(15,1) DEFAULT '0'::numeric NOT NULL,
    gorduras_saturadas_rdc429 numeric(15,1) DEFAULT '0'::numeric NOT NULL,
    gorduras_trans_rdc429 numeric(15,1) DEFAULT '0'::numeric NOT NULL,
    fibra_alimentar_rdc429 numeric(15,1) DEFAULT '0'::numeric NOT NULL,
    sodio_rdc429 numeric(15,1) DEFAULT '0'::numeric NOT NULL,
    acucares_totais_rdc429 numeric(15,1) DEFAULT '0'::numeric NOT NULL,
    acucares_adicionados_rdc429 numeric(15,1) DEFAULT '0'::numeric NOT NULL,
    alto_acucar_rdc429 boolean DEFAULT false NOT NULL,
    alto_gordura_rdc429 boolean DEFAULT false NOT NULL,
    alto_sodio_rdc429 boolean DEFAULT false NOT NULL,
    utiliza_rdc_359_360 boolean DEFAULT true NOT NULL,
    utiliza_rdc_429 boolean DEFAULT false NOT NULL
);


--
-- Name: beneficios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.beneficios (
    ben_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    pontos integer NOT NULL,
    tipo integer NOT NULL,
    desconto_perc numeric(15,2) DEFAULT 0.00
);


--
-- Name: beneficios_ben_001_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.beneficios_ben_001_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: beneficios_ben_001_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.beneficios_ben_001_seq OWNED BY public.beneficios.ben_001;


--
-- Name: bot_sinonimo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bot_sinonimo (
    id_empresa integer NOT NULL,
    termo character varying(60) NOT NULL,
    expansao character varying(120) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    criado_em timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    atualizado_em timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL
);


--
-- Name: cadastro_cliente_pedizap; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cadastro_cliente_pedizap (
    id integer NOT NULL,
    tipo_pessoa character varying(1),
    nome character varying(150),
    razao_social character varying(150),
    contato character varying(150),
    cpfcnpj character varying(20),
    rgie character varying(20),
    isento character varying(1),
    data_nascimento timestamp without time zone,
    sexo character varying(1),
    fone_ddd character varying(5),
    fone character varying(20),
    celular_ddd character varying(5),
    celular character varying(20),
    endereco character varying(200),
    numero character varying(20),
    bairro character varying(100),
    bairro_custom character varying(100),
    complemento character varying(200),
    cep character varying(20),
    cidade character varying(100),
    uf character varying(2),
    pais character varying(60)
);


--
-- Name: caixa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.caixa (
    id_caixa integer NOT NULL,
    id_empresa integer NOT NULL,
    data_abertura timestamp without time zone NOT NULL,
    hora_abertura time without time zone NOT NULL,
    data_fechamento timestamp without time zone,
    hora_fechamento time without time zone,
    valor_inicial numeric(10,2),
    id_usuario integer NOT NULL,
    id_situacao integer,
    observacao bytea,
    valor_informado_dinheiro numeric(10,2) DEFAULT 0,
    valor_informado_cartao numeric(10,2) DEFAULT 0,
    valor_informado_cheque numeric(10,2) DEFAULT 0,
    valor_informado_outros numeric(10,2) DEFAULT 0,
    valor_total numeric(10,2) DEFAULT 0,
    periodo_abertura integer,
    periodo_fechamento integer,
    terminal character varying(100),
    id_usuario_fechamento integer,
    valor_informado_crediario numeric(10,2) DEFAULT 0,
    valor_informado_cartaodeb numeric(10,2) DEFAULT 0,
    valor_informado_alimentacao numeric(10,2) DEFAULT 0,
    valor_informado_refeicao numeric(10,2) DEFAULT 0,
    valor_informado_presente numeric(10,2) DEFAULT 0,
    valor_informado_combustivel numeric(10,2) DEFAULT 0,
    valor_informado_boleto numeric(10,2) DEFAULT 0,
    valor_informado_deposito numeric(10,2) DEFAULT 0,
    valor_informado_pix numeric(10,2) DEFAULT 0,
    valor_informado_transf numeric(10,2) DEFAULT 0,
    valor_informado_fidelidade numeric(10,2) DEFAULT 0
);


--
-- Name: caixainformado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.caixainformado (
    id_caixa integer NOT NULL,
    id_empresa integer NOT NULL,
    id_formapgto integer NOT NULL,
    valor numeric(10,2) DEFAULT 0 NOT NULL
);


--
-- Name: caixaitem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.caixaitem (
    id_caixa integer NOT NULL,
    id_empresa integer NOT NULL,
    item integer NOT NULL,
    tipo_movimento character(1),
    valor numeric(10,2),
    id_venda integer,
    item_encerravenda integer,
    id_formapgto integer,
    id_cpagar integer,
    id_creceber integer,
    data timestamp without time zone,
    hora time without time zone,
    observacao bytea,
    id_encerravenda integer,
    classificacao character(1),
    antecipado boolean DEFAULT false,
    id_usuario integer,
    id_evento integer,
    id_evento_mesa integer
)
WITH (autovacuum_vacuum_scale_factor='0.02', autovacuum_analyze_scale_factor='0.02');


--
-- Name: categoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categoria (
    cat_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    cat_002 character varying(40) NOT NULL,
    sit_001 integer DEFAULT 4 NOT NULL,
    codigo_departamento_balanca integer,
    b_exibir_mobile boolean DEFAULT true,
    b_exibir_web boolean DEFAULT false NOT NULL,
    imagem_db bytea
);


--
-- Name: categoria_opcionais; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categoria_opcionais (
    id integer NOT NULL,
    emp_001 integer DEFAULT 1 NOT NULL,
    descricao character varying(40) NOT NULL,
    sit_001 integer DEFAULT 4 NOT NULL,
    opc_min integer DEFAULT 0 NOT NULL,
    opc_max integer DEFAULT 0 NOT NULL
);


--
-- Name: catraca_mobile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catraca_mobile (
    id integer NOT NULL,
    comanda integer NOT NULL,
    id_empresa integer NOT NULL,
    comando character(1) NOT NULL,
    data timestamp without time zone
);


--
-- Name: catraca_mobile_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.catraca_mobile_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: catraca_mobile_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.catraca_mobile_id_seq OWNED BY public.catraca_mobile.id;


--
-- Name: ceps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ceps (
    cep_002 character varying(9) NOT NULL,
    cep_003 character varying(75) NOT NULL,
    cep_004 character varying(125),
    cid_ibge character varying(10)
);


--
-- Name: cest; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cest (
    cest_codigo character varying(7) NOT NULL,
    cest_descricao character varying(1000),
    cest_anexoxxvii boolean DEFAULT false NOT NULL
);


--
-- Name: cfop; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cfop (
    cfop_codigo character varying(4) NOT NULL,
    cfop_descricao character varying(250),
    cfop_descritivonf character varying(1000)
);


--
-- Name: cfop_conversao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cfop_conversao (
    id integer NOT NULL,
    cfop_produto character varying(4) NOT NULL,
    cfop_entrada character varying(4) NOT NULL
);


--
-- Name: cfop_conversao_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cfop_conversao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cfop_conversao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cfop_conversao_id_seq OWNED BY public.cfop_conversao.id;


--
-- Name: cidades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cidades (
    cid_001 integer NOT NULL,
    cid_002 character varying(75) NOT NULL,
    cid_003 character varying(10),
    est_001 integer NOT NULL,
    aliq_ibs_mun numeric(15,4) DEFAULT '0'::numeric
);


--
-- Name: cidades_temp_ibge; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cidades_temp_ibge (
    cid_002 character varying(75) NOT NULL,
    cid_003 character varying(10) NOT NULL,
    est_001 integer NOT NULL
);


--
-- Name: cidades_transf; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cidades_transf (
    cid_001 integer NOT NULL
);


--
-- Name: clientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes (
    cli_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    cli_002 character varying(90) NOT NULL,
    cli_003 character varying(90),
    cli_004 character varying(20),
    cli_005 character varying(20),
    cli_006 character varying(20),
    cli_007 character varying(200),
    cli_008 character varying(100),
    cli_009 character varying(100),
    sit_001 integer DEFAULT 4 NOT NULL,
    cep_004 character varying(125),
    cep_003 character varying(50),
    cid_001 integer,
    cep_002 character varying(9),
    cli_012 character varying(20),
    cli_013 character varying(20),
    cli_014 character varying(20),
    usu_001_1 integer,
    usu_001_2 integer,
    usu_001_3 integer,
    dat_001_1 timestamp without time zone,
    dat_001_2 timestamp without time zone,
    dat_001_3 timestamp without time zone,
    ram_001 integer,
    for_001 integer,
    con_001 integer,
    cli_017 numeric(15,4),
    bai_001 integer,
    observacao text,
    celular1 character varying(20),
    celular2 character varying(20),
    saldo_atual numeric(15,2),
    limite_credito numeric(15,2),
    pontos_atuais integer,
    cli_018 text,
    cidade_desc character varying(100),
    codigo_fidelidade character varying(100),
    uf character varying(2),
    b_limite_fiado boolean DEFAULT true NOT NULL,
    data_nascimento date,
    email character varying(100),
    obs_bloqueio character varying(200),
    filiacao_mae character varying(80),
    filiacao_pai character varying(80),
    nome_conjuge character varying(80),
    profissao character varying(80),
    estado_civil character varying(20),
    data_consulta_spc date,
    dia_vencimento integer DEFAULT 1,
    num_dias_atraso integer DEFAULT 0,
    num_dias_aviso integer DEFAULT 0,
    taxa_juros numeric(10,2) DEFAULT 0.0,
    id_situacao_spc integer DEFAULT 1,
    tipo_pessoa character varying(1) DEFAULT 'F'::character varying NOT NULL,
    situacao_ie character varying(1) DEFAULT 'I'::character varying NOT NULL,
    sexo character varying(1) DEFAULT 'N'::character varying NOT NULL,
    foto bytea,
    tipo_cliente character varying(1),
    cli_foto bytea,
    firma character varying(100),
    em_haver numeric(15,2) DEFAULT 0.00 NOT NULL,
    turma character varying(20),
    ifood_uuid character varying(50),
    fone_zap character varying(25),
    pontos_fidelidade integer DEFAULT 0 NOT NULL,
    senha_email character varying(100),
    cadastro_rpfood boolean DEFAULT false NOT NULL,
    preco_cliente integer,
    orgao_publico boolean DEFAULT false,
    quero_delivery_customer_id character varying(50),
    origem_integracao character varying(30),
    id_cliente_99food bigint,
    id_pedzap integer,
    id_cliente_anotaai character varying(180),
    id_cliente_deliverydireto character varying(180)
);


--
-- Name: clientes_endereco; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_endereco (
    id_endereco integer NOT NULL,
    cli_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    cep_002 character varying(9),
    cep_003 character varying(50),
    cep_004 character varying(125),
    cli_007 character varying(200),
    cli_008 character varying(100),
    cli_009 character varying(100),
    bai_001 integer,
    cid_001 integer,
    cidade_desc character varying(100),
    uf character varying(2)
);


--
-- Name: clientes_endereco_id_endereco_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_endereco_id_endereco_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_endereco_id_endereco_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_endereco_id_endereco_seq OWNED BY public.clientes_endereco.id_endereco;


--
-- Name: comanda; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comanda (
    com_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    com_002 character varying(40) NOT NULL,
    com_003 integer NOT NULL,
    sit_001 integer DEFAULT 4 NOT NULL,
    usu_001_1 integer,
    dat_001_1 timestamp without time zone,
    status_catraca character varying(1),
    aproximacao_nfc character varying(14)
);


--
-- Name: composicao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.composicao (
    id_composicao integer NOT NULL,
    descricao character varying(100),
    valor_custo numeric(15,2),
    estoque_minimo numeric(15,3) DEFAULT 0.00,
    id_situacao integer,
    id_empresa integer NOT NULL,
    id_unidade integer NOT NULL,
    rendimento numeric(15,2) DEFAULT 100.0,
    codigo_ref character varying(50),
    id_setor integer NOT NULL,
    b_baixar_setor_princ boolean DEFAULT false NOT NULL,
    tipo_item_sped character(2) DEFAULT '01'::bpchar NOT NULL,
    ncm character varying(10),
    ultimo_ajuste_inv_fiscal date,
    usu_ajuste_inv_fiscal integer
);


--
-- Name: composicao_fornecedor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.composicao_fornecedor (
    id_composicao integer NOT NULL,
    id_empresa integer NOT NULL,
    id_fornecedor integer NOT NULL,
    codigo_fornecedor character varying(50) NOT NULL
);


--
-- Name: composicao_id_composicao_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.composicao_id_composicao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: composicao_id_composicao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.composicao_id_composicao_seq OWNED BY public.composicao.id_composicao;


--
-- Name: condicaopagamento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.condicaopagamento (
    id_condicaopagamento integer NOT NULL,
    id_empresa integer NOT NULL,
    descricao character varying(100) NOT NULL,
    id_situacao integer NOT NULL,
    numero_parcelas integer DEFAULT 1 NOT NULL,
    periodicidade integer NOT NULL,
    periodicidade_inicio integer NOT NULL,
    possui_entrada boolean NOT NULL
);


--
-- Name: condicaopagamentoparcela; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.condicaopagamentoparcela (
    id_condicaopagamento integer NOT NULL,
    id_empresa integer NOT NULL,
    nro_parcela integer NOT NULL,
    dias_prazo integer NOT NULL
);


--
-- Name: configuracao_backup; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracao_backup (
    diretorio_backup character varying(255),
    diretorio_backup2 character varying(255),
    caminho_pgdump character varying(255),
    excluir_arquivos_antigos boolean DEFAULT false,
    email_informando_alerta character varying(150)
);


--
-- Name: configuracao_certificado_digital; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracao_certificado_digital (
    id bigint NOT NULL,
    numero_certificado_digital character varying(100) CONSTRAINT configuracao_certificado_di_numero_certificado_digital_not_null NOT NULL,
    cnpj character varying(15) NOT NULL,
    data_validade timestamp without time zone NOT NULL,
    nome_terminal character varying(100) NOT NULL,
    caminho_certificado_digital character varying(255),
    id_cidade integer
);


--
-- Name: configuracao_certificado_digital_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.configuracao_certificado_digital ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.configuracao_certificado_digital_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: configuracao_email; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracao_email (
    id_empresa integer,
    usuario_email character varying(150) NOT NULL,
    senha_email character varying(150) NOT NULL,
    smtp_email character varying(150) NOT NULL,
    porta_email character varying(30),
    tipo_email integer
);


--
-- Name: configuracao_funcionamento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracao_funcionamento (
    dia_segunda boolean DEFAULT false NOT NULL,
    dia_terca boolean DEFAULT false NOT NULL,
    dia_quarta boolean DEFAULT false NOT NULL,
    dia_quinta boolean DEFAULT false NOT NULL,
    dia_sexta boolean DEFAULT false NOT NULL,
    dia_sabado boolean DEFAULT false NOT NULL,
    dia_domingo boolean DEFAULT false NOT NULL,
    segunda_inicio_atendimento time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    terca_inicio_atendimento time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    quarta_inicio_atendimento time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    quinta_inicio_atendimento time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    sexta_inicio_atendimento time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    sabado_inicio_atendimento time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    domingo_inicio_atendimento time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    segunda_fim_atendimento time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    terca_fim_atendimento time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    quarta_fim_atendimento time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    quinta_fim_atendimento time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    sexta_fim_atendimento time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    sabado_fim_atendimento time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    domingo_fim_atendimento time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    utiliza_controle_rpfood boolean DEFAULT false NOT NULL,
    aviso_sonoro_rpfood boolean DEFAULT false NOT NULL,
    utiliza_controle_rpmenu boolean DEFAULT false NOT NULL,
    id integer NOT NULL,
    segunda_inicio_atendimento_p2 time without time zone DEFAULT '00:00:00'::time without time zone CONSTRAINT configuracao_funcionamento_segunda_inicio_atendimento__not_null NOT NULL,
    terca_inicio_atendimento_p2 time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    quarta_inicio_atendimento_p2 time without time zone DEFAULT '00:00:00'::time without time zone CONSTRAINT configuracao_funcionamento_quarta_inicio_atendimento_p_not_null NOT NULL,
    quinta_inicio_atendimento_p2 time without time zone DEFAULT '00:00:00'::time without time zone CONSTRAINT configuracao_funcionamento_quinta_inicio_atendimento_p_not_null NOT NULL,
    sexta_inicio_atendimento_p2 time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    sabado_inicio_atendimento_p2 time without time zone DEFAULT '00:00:00'::time without time zone CONSTRAINT configuracao_funcionamento_sabado_inicio_atendimento_p_not_null NOT NULL,
    domingo_inicio_atendimento_p2 time without time zone DEFAULT '00:00:00'::time without time zone CONSTRAINT configuracao_funcionamento_domingo_inicio_atendimento__not_null NOT NULL,
    segunda_fim_atendimento_p2 time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    terca_fim_atendimento_p2 time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    quarta_fim_atendimento_p2 time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    quinta_fim_atendimento_p2 time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    sexta_fim_atendimento_p2 time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    sabado_fim_atendimento_p2 time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    domingo_fim_atendimento_p2 time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL
);


--
-- Name: configuracao_funcionamento_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configuracao_funcionamento_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: configuracao_funcionamento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.configuracao_funcionamento_id_seq OWNED BY public.configuracao_funcionamento.id;


--
-- Name: configuracao_geral; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracao_geral (
    id_empresa integer NOT NULL,
    aceitar_automaticamente_anotaai boolean DEFAULT false NOT NULL,
    aceitar_automaticamente_99food boolean DEFAULT false NOT NULL,
    aceitar_automaticamente_rpfood boolean DEFAULT false NOT NULL,
    aceitar_automaticamente_pedzap boolean DEFAULT false NOT NULL,
    aceitar_automaticamente_querodelivery boolean DEFAULT false CONSTRAINT configuracao_geral_aceitar_automaticamente_querodelive_not_null NOT NULL
);


--
-- Name: configuracao_rpfood; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracao_rpfood (
    id_empresa integer DEFAULT 1 NOT NULL,
    tempo_retirada_rpfood integer DEFAULT 0 NOT NULL,
    tempo_entrega_rpfood integer DEFAULT 0 NOT NULL,
    id integer NOT NULL,
    modo_acougue boolean DEFAULT false NOT NULL,
    pedido_minimo numeric(15,2) DEFAULT 0.00 NOT NULL,
    utiliza_tipo_entrega_retirada boolean DEFAULT true NOT NULL,
    utiliza_controle_opcionais boolean DEFAULT false NOT NULL,
    utiliza_controle_ceps boolean DEFAULT true,
    integracaomercadopago boolean DEFAULT false NOT NULL
);


--
-- Name: configuracao_rpfood_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configuracao_rpfood_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: configuracao_rpfood_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.configuracao_rpfood_id_seq OWNED BY public.configuracao_rpfood.id;


--
-- Name: configuracao_wattsap; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracao_wattsap (
    id_configuracao bigint NOT NULL,
    id_empresa integer NOT NULL,
    ativo boolean DEFAULT false NOT NULL,
    nome_robo character varying(80) DEFAULT 'RPCOP Virtual'::character varying NOT NULL,
    responder_preco boolean DEFAULT true NOT NULL,
    responder_disponibilidade boolean DEFAULT true NOT NULL,
    responder_horario boolean DEFAULT true NOT NULL,
    responder_endereco boolean DEFAULT true NOT NULL,
    responder_cardapio boolean DEFAULT true NOT NULL,
    responder_forma_pagamento boolean DEFAULT true NOT NULL,
    responder_entrega boolean DEFAULT true NOT NULL,
    responder_status_pedido boolean DEFAULT true NOT NULL,
    permitir_montar_pedido boolean DEFAULT false NOT NULL,
    usar_ia boolean DEFAULT false NOT NULL,
    provedor_ia character varying(40),
    modelo_ia character varying(80),
    prompt_sistema text,
    mensagem_saudacao text,
    mensagem_produto_nao_encontrado text,
    mensagem_nao_entendida text,
    mensagem_fora_horario text,
    mensagem_encaminhamento text,
    encaminhar_atendente boolean DEFAULT true NOT NULL,
    telefone_atendente character varying(20),
    somente_clientes_cadastrados boolean DEFAULT false NOT NULL,
    ignorar_grupos boolean DEFAULT true NOT NULL,
    tempo_entrega_minutos integer,
    tempo_retirada_minutos integer,
    link_pedido character varying(255),
    tempo_sessao_minutos integer DEFAULT 15 NOT NULL,
    limite_mensagens_minuto integer DEFAULT 10 NOT NULL,
    intervalo_consulta_segundos integer DEFAULT 5 NOT NULL,
    ultima_mensagem_timestamp bigint DEFAULT 0 NOT NULL,
    ultima_sincronizacao_em timestamp without time zone,
    ultimo_erro text,
    ultimo_erro_em timestamp without time zone,
    webhook_token_hash character varying(255),
    criado_em timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    atualizado_em timestamp without time zone,
    mensagem_promocao text,
    CONSTRAINT ck_config_wattsap_intervalo_consulta CHECK (((intervalo_consulta_segundos >= 2) AND (intervalo_consulta_segundos <= 60))),
    CONSTRAINT ck_config_wattsap_tempo_entrega CHECK (((tempo_entrega_minutos IS NULL) OR ((tempo_entrega_minutos >= 0) AND (tempo_entrega_minutos <= 1440)))),
    CONSTRAINT ck_config_wattsap_tempo_retirada CHECK (((tempo_retirada_minutos IS NULL) OR ((tempo_retirada_minutos >= 0) AND (tempo_retirada_minutos <= 1440)))),
    CONSTRAINT ck_configuracao_wattsap_limite_mensagens CHECK (((limite_mensagens_minuto >= 1) AND (limite_mensagens_minuto <= 120))),
    CONSTRAINT ck_configuracao_wattsap_tempo_sessao CHECK (((tempo_sessao_minutos >= 1) AND (tempo_sessao_minutos <= 1440)))
);


--
-- Name: configuracao_wattsap_id_configuracao_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configuracao_wattsap_id_configuracao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: configuracao_wattsap_id_configuracao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.configuracao_wattsap_id_configuracao_seq OWNED BY public.configuracao_wattsap.id_configuracao;


--
-- Name: configuracao_web; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracao_web (
    nomebancorpfoodrpmenu character varying(100)
);


--
-- Name: configuracaobalancaeletronica; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracaobalancaeletronica (
    idempresa integer NOT NULL,
    idprodutopadrao integer,
    idproduto1 integer,
    idproduto2 integer,
    idproduto3 integer,
    idprodutovontade integer
);


--
-- Name: configuracaobalancainteligente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracaobalancainteligente (
    idempresa integer NOT NULL,
    idprodutopadrao integer,
    idproduto1 integer,
    idproduto2 integer,
    idproduto3 integer,
    numerocomandainicial integer NOT NULL,
    numerocomandafinal integer NOT NULL
);


--
-- Name: configuracaopagamentobarte; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracaopagamentobarte (
    id integer NOT NULL,
    token character varying(255) NOT NULL,
    id_company integer NOT NULL,
    id_seller integer NOT NULL,
    id_empresa integer NOT NULL,
    id_situacao integer NOT NULL,
    utilizapix boolean DEFAULT false NOT NULL
);


--
-- Name: configuracaopagamentomercadopago; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracaopagamentomercadopago (
    id integer NOT NULL,
    acesstoken character varying(255),
    publickey character varying(255),
    id_situacao integer NOT NULL,
    id_empresa integer NOT NULL
);


--
-- Name: conta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conta (
    id_conta integer NOT NULL,
    id_empresa integer NOT NULL,
    descricao character varying(100) NOT NULL,
    b_pagar boolean DEFAULT true NOT NULL,
    b_receber boolean DEFAULT true NOT NULL,
    id_situacao integer DEFAULT 4 NOT NULL
);


--
-- Name: contacorrente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contacorrente (
    id_contacorrente integer NOT NULL,
    id_empresa integer NOT NULL,
    agencia character varying(20) NOT NULL,
    conta character varying(20) NOT NULL,
    banco character varying(20) NOT NULL,
    saldo numeric(15,2) DEFAULT 0 NOT NULL,
    id_situacao integer DEFAULT 4 NOT NULL,
    observacao character varying(100),
    titular character varying(50)
);


--
-- Name: cpagar; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cpagar (
    id_cpagar integer NOT NULL,
    id_empresa integer NOT NULL,
    data timestamp without time zone NOT NULL,
    id_fornecedor integer NOT NULL,
    id_conta integer NOT NULL,
    id_usuario integer NOT NULL,
    id_usuario_cancelamento integer,
    id_usuario_pagamento integer,
    nota integer,
    descricao character varying(150),
    valor_nota numeric(15,2) NOT NULL,
    valor numeric(15,2) NOT NULL,
    valor_desconto numeric(15,2),
    valor_acrescimo numeric(15,2),
    valor_pago numeric(15,2),
    data_vencimento date NOT NULL,
    data_pagamento timestamp without time zone,
    data_cancelamento timestamp without time zone,
    especie integer,
    documento character varying(20),
    id_situacao integer,
    parcela_nota integer,
    conta_fixa boolean DEFAULT false
);


--
-- Name: cpagar_id_cpagar_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cpagar_id_cpagar_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cpagar_id_cpagar_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cpagar_id_cpagar_seq OWNED BY public.cpagar.id_cpagar;


--
-- Name: cpagar_parcela; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cpagar_parcela (
    id_cpagar integer NOT NULL,
    id_empresa integer NOT NULL,
    parcela integer NOT NULL,
    valor numeric(15,2) NOT NULL,
    data timestamp without time zone NOT NULL,
    id_situacao integer NOT NULL,
    id_usuario integer NOT NULL,
    id_formapgto integer DEFAULT 0 NOT NULL,
    id_contacorrente integer DEFAULT 0 NOT NULL,
    id_caixa integer DEFAULT 0 NOT NULL
);


--
-- Name: creceber; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.creceber (
    id_creceber integer NOT NULL,
    id_empresa integer NOT NULL,
    data timestamp without time zone NOT NULL,
    id_cliente integer,
    id_fornecedor integer,
    id_conta integer NOT NULL,
    id_usuario integer NOT NULL,
    id_usuario_cancelamento integer,
    id_usuario_pagamento integer,
    nota integer,
    descricao character varying(150),
    valor_nota numeric(15,2) NOT NULL,
    valor numeric(15,2) NOT NULL,
    valor_desconto numeric(15,2),
    valor_acrescimo numeric(15,2),
    valor_pago numeric(15,2),
    data_vencimento date NOT NULL,
    data_pagamento timestamp without time zone,
    data_cancelamento timestamp without time zone,
    especie integer,
    documento character varying(20),
    id_situacao integer,
    parcela_nota integer,
    id_venda integer,
    valor_juros numeric(15,2) DEFAULT 0 NOT NULL,
    valor_total numeric(15,2) DEFAULT 0 NOT NULL,
    b_automatica boolean DEFAULT false NOT NULL
);


--
-- Name: creceber_id_creceber_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.creceber_id_creceber_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: creceber_id_creceber_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.creceber_id_creceber_seq OWNED BY public.creceber.id_creceber;


--
-- Name: creceber_parcela; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.creceber_parcela (
    id_creceber integer NOT NULL,
    id_empresa integer NOT NULL,
    parcela integer NOT NULL,
    valor numeric(15,2) NOT NULL,
    data timestamp without time zone NOT NULL,
    id_situacao integer NOT NULL,
    id_usuario integer NOT NULL
);


--
-- Name: csosn_icms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.csosn_icms (
    emp_001 integer NOT NULL,
    cso_codigo integer NOT NULL,
    cso_descricao character varying(255)
);


--
-- Name: cst_cofins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cst_cofins (
    emp_001 integer NOT NULL,
    cof_codigo integer NOT NULL,
    cof_descricao character varying(255)
);


--
-- Name: cst_icms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cst_icms (
    emp_001 integer NOT NULL,
    icm_codigo integer NOT NULL,
    icm_descricao character varying(255)
);


--
-- Name: cst_ipi; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cst_ipi (
    emp_001 integer NOT NULL,
    ipi_codigo integer NOT NULL,
    ipi_descricao character varying(255)
);


--
-- Name: cst_pis; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cst_pis (
    emp_001 integer NOT NULL,
    pis_codigo integer NOT NULL,
    pis_descricao character varying(255)
);


--
-- Name: ctrib_individual; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ctrib_individual (
    codprod integer,
    descricao character varying(255),
    ean character varying(20) NOT NULL,
    fed_cst_pis_cofins_entrada character varying(5),
    fed_cst_pis_cofins_saida character varying(5),
    fed_natureza_receita character varying(10),
    fed_extipi character varying(10),
    fed_ncm character varying(10),
    fed_aliq_ibpt numeric(10,2),
    fed_cest character varying(10),
    fed_al_pis_in numeric(10,2),
    fed_al_pis_out numeric(10,2),
    fed_al_cofins_in numeric(10,2),
    fed_al_cofins_out numeric(10,2),
    fed_law character varying(255),
    fed_al_cfop_out character varying(4),
    est_cst_icms_saida character varying(5),
    est_cst_icms_entrada character varying(5),
    est_per_mva numeric(10,2),
    est_per_mva_inter numeric(10,2),
    est_validade_mva date,
    est_valor_pauta numeric(15,2),
    est_validade_pauta date,
    est_aplica_red_st_saida boolean,
    est_aliq_icms_nfe numeric(10,2),
    est_tipo_item_sped character varying(10),
    est_per_aliq_nf_saida numeric(10,2),
    est_per_aliq_pdv_saida numeric(10,2),
    est_per_reducao_saida numeric(10,2),
    est_per_reducao_entrada numeric(10,2),
    est_per_fcp numeric(10,2),
    est_aliq_ibpt numeric(10,2),
    est_id_inventario integer,
    est_tipo_trib_pdv character varying(5),
    est_tipo_trib_nf character varying(5),
    est_cesta_basica boolean,
    est_mot_deson_entrada character varying(50),
    est_mot_deson_saida character varying(50),
    est_cod_benef_des_entrada character varying(50),
    est_cod_benef_des_saida character varying(50),
    est_cod_benef_ajust_entrada character varying(50),
    est_cod_benef_ajust_saida character varying(50),
    est_aliq_icms_des_entrada numeric(10,2),
    est_aliq_icms_des_saida numeric(10,2),
    est_al_icms_st numeric(10,2),
    est_per_red_saida_st numeric(10,2),
    est_fot numeric(10,2),
    est_law character varying(255),
    ibs_cst character varying(10),
    ibs_classtrib character varying(20),
    ibsuf_pibsuf numeric(10,2),
    ibsuf_pred_aliq numeric(10,2),
    ibsuf_paliq_efet numeric(10,2),
    ibsmun_pibsmun numeric(10,2),
    ibsmun_pred_aliq numeric(10,2),
    ibsmun_paliq_efet numeric(10,2),
    cbs_pcbs numeric(10,2),
    cbs_pred_aliq numeric(10,2),
    cbs_paliq_efet numeric(10,2),
    is_cst character varying(10),
    is_classtrib character varying(20),
    is_pis numeric(10,2),
    data_consulta date DEFAULT CURRENT_DATE NOT NULL,
    hora_consulta time without time zone DEFAULT CURRENT_TIME NOT NULL,
    aliqpisredbenef numeric(10,3) DEFAULT '0'::numeric NOT NULL,
    aliqcofinsredbenef numeric(10,3) DEFAULT '0'::numeric NOT NULL,
    infadfisco character varying(200)
);


--
-- Name: ctrib_lotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ctrib_lotes (
    lote integer NOT NULL,
    id_empresa integer NOT NULL,
    tamanho integer DEFAULT 0 NOT NULL,
    posicao integer DEFAULT 0 NOT NULL,
    data date,
    hora time without time zone
);


--
-- Name: ctrib_lotes_produtos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ctrib_lotes_produtos (
    lote integer NOT NULL,
    posicao integer NOT NULL,
    codprod integer NOT NULL,
    descricao character varying(255),
    ean character varying(20) NOT NULL,
    fed_cst_pis_cofins_entrada character varying(5),
    fed_cst_pis_cofins_saida character varying(5),
    fed_natureza_receita character varying(10),
    fed_extipi character varying(10),
    fed_ncm character varying(10),
    fed_aliq_ibpt numeric(10,2),
    fed_cest character varying(10),
    fed_al_pis_in numeric(10,2),
    fed_al_pis_out numeric(10,2),
    fed_al_cofins_in numeric(10,2),
    fed_al_cofins_out numeric(10,2),
    fed_law character varying(255),
    fed_al_cfop_out character varying(4),
    est_cst_icms_saida character varying(5),
    est_cst_icms_entrada character varying(5),
    est_per_mva numeric(10,2),
    est_per_mva_inter numeric(10,2),
    est_validade_mva date,
    est_valor_pauta numeric(15,2),
    est_validade_pauta date,
    est_aplica_red_st_saida boolean,
    est_aliq_icms_nfe numeric(10,2),
    est_tipo_item_sped character varying(10),
    est_per_aliq_nf_saida numeric(10,2),
    est_per_aliq_pdv_saida numeric(10,2),
    est_per_reducao_saida numeric(10,2),
    est_per_reducao_entrada numeric(10,2),
    est_per_fcp numeric(10,2),
    est_aliq_ibpt numeric(10,2),
    est_id_inventario integer,
    est_tipo_trib_pdv character varying(5),
    est_tipo_trib_nf character varying(5),
    est_cesta_basica boolean,
    est_mot_deson_entrada character varying(50),
    est_mot_deson_saida character varying(50),
    est_cod_benef_des_entrada character varying(50),
    est_cod_benef_des_saida character varying(50),
    est_cod_benef_ajust_entrada character varying(50),
    est_cod_benef_ajust_saida character varying(50),
    est_aliq_icms_des_entrada numeric(10,2),
    est_aliq_icms_des_saida numeric(10,2),
    est_al_icms_st numeric(10,2),
    est_per_red_saida_st numeric(10,2),
    est_fot numeric(10,2),
    est_law character varying(255),
    ibs_cst character varying(10),
    ibs_classtrib character varying(20),
    ibsuf_pibsuf numeric(10,2),
    ibsuf_pred_aliq numeric(10,2),
    ibsuf_paliq_efet numeric(10,2),
    ibsmun_pibsmun numeric(10,2),
    ibsmun_pred_aliq numeric(10,2),
    ibsmun_paliq_efet numeric(10,2),
    cbs_pcbs numeric(10,2),
    cbs_pred_aliq numeric(10,2),
    cbs_paliq_efet numeric(10,2),
    is_cst character varying(10),
    is_classtrib character varying(20),
    is_pis numeric(10,2),
    data_consulta date DEFAULT CURRENT_DATE NOT NULL,
    hora_consulta time without time zone DEFAULT CURRENT_TIME NOT NULL,
    aliqpisredbenef numeric(10,3) DEFAULT '0'::numeric NOT NULL,
    aliqcofinsredbenef numeric(10,3) DEFAULT '0'::numeric NOT NULL,
    infadfisco character varying(200)
);


--
-- Name: desc_tamanho_material; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.desc_tamanho_material (
    id_empresa integer NOT NULL,
    tamanho_p character varying(100),
    tamanho_m character varying(100),
    tamanho_g character varying(100),
    tamanho_gg character varying(100),
    tamanho_extra character varying(100)
);


--
-- Name: devolucaoitem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.devolucaoitem (
    id_venda integer NOT NULL,
    id_empresa integer NOT NULL,
    id_vendaitem integer NOT NULL,
    data timestamp without time zone NOT NULL,
    quantidade numeric(10,4) NOT NULL,
    id_usuario integer NOT NULL,
    id_caixa integer NOT NULL,
    id_devolucaoitem bigint NOT NULL
);


--
-- Name: devolucaoitem_id_devolucaoitem_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.devolucaoitem ALTER COLUMN id_devolucaoitem ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.devolucaoitem_id_devolucaoitem_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: dfe_classtrib_rt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dfe_classtrib_rt (
    id integer NOT NULL,
    cst character varying(3) NOT NULL,
    descricao_cst character varying(500) NOT NULL,
    classtrib character varying(6) NOT NULL,
    descricao_classtrib character varying(2000) NOT NULL,
    predibs numeric(8,5) DEFAULT 0.00000 NOT NULL,
    predcbs numeric(8,5) DEFAULT 0.00000 NOT NULL,
    indtribregular boolean DEFAULT false NOT NULL,
    indcredpresoper boolean DEFAULT false NOT NULL,
    indestornocred boolean DEFAULT false NOT NULL,
    monofasiasujeitaretencao boolean DEFAULT false NOT NULL,
    monofasiaretidaant boolean DEFAULT false NOT NULL,
    monofasiadiferimento boolean DEFAULT false NOT NULL,
    monofasiapadrao boolean DEFAULT false NOT NULL,
    tipoaliquota character varying(50),
    indnfe boolean DEFAULT false NOT NULL,
    indnfce boolean DEFAULT false NOT NULL,
    indcte boolean DEFAULT false NOT NULL,
    indcteos boolean DEFAULT false NOT NULL,
    indbpe boolean DEFAULT false NOT NULL,
    indnf3e boolean DEFAULT false NOT NULL,
    indnfcom boolean DEFAULT false NOT NULL,
    indnfse boolean DEFAULT false NOT NULL,
    indbpetm boolean DEFAULT false NOT NULL,
    indbpeta boolean DEFAULT false NOT NULL,
    indnfag boolean DEFAULT false NOT NULL,
    indnfsvia boolean DEFAULT false NOT NULL,
    indnfabi boolean DEFAULT false NOT NULL,
    indnfgas boolean DEFAULT false NOT NULL,
    inddere boolean DEFAULT false NOT NULL,
    indpercentualdiferencabiocombustivel boolean DEFAULT false NOT NULL,
    inddir boolean DEFAULT false NOT NULL,
    indduimp boolean DEFAULT false NOT NULL,
    tiporeceitabrutasn character varying(100),
    numero_anexo integer,
    url_legislacao character varying(500),
    publicacao timestamp without time zone,
    iniciovigencia timestamp without time zone,
    fimvigencia timestamp without time zone,
    CONSTRAINT dfe_classtrib_rt_classtrib_chk CHECK (((classtrib)::text ~ '^[0-9]{6}$'::text)),
    CONSTRAINT dfe_classtrib_rt_cst_chk CHECK (((cst)::text ~ '^[0-9]{3}$'::text))
);


--
-- Name: dfe_classtrib_rt_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dfe_classtrib_rt_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dfe_classtrib_rt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dfe_classtrib_rt_id_seq OWNED BY public.dfe_classtrib_rt.id;


--
-- Name: dfe_cst_rt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dfe_cst_rt (
    id_cst_ibs_cbs integer NOT NULL,
    cst_ibs_cbs character varying(3) NOT NULL,
    descricao_cst_ibs_cbs character varying(255) NOT NULL,
    indibscbs boolean DEFAULT false NOT NULL,
    indredbc boolean DEFAULT false NOT NULL,
    indredaliq boolean DEFAULT false NOT NULL,
    indtransfcred boolean DEFAULT false NOT NULL,
    inddif boolean DEFAULT false NOT NULL,
    indajustecompet boolean DEFAULT false NOT NULL,
    indibscbsmono boolean DEFAULT false NOT NULL,
    indcredpresibszfm boolean DEFAULT false NOT NULL,
    CONSTRAINT dfe_cst_rt_cst_ibs_cbs_chk CHECK (((cst_ibs_cbs)::text ~ '^[0-9]{3}$'::text))
);


--
-- Name: dfe_cst_rt_id_cst_ibs_cbs_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dfe_cst_rt_id_cst_ibs_cbs_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dfe_cst_rt_id_cst_ibs_cbs_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dfe_cst_rt_id_cst_ibs_cbs_seq OWNED BY public.dfe_cst_rt.id_cst_ibs_cbs;


--
-- Name: dfe_tipo_nfe_creddeb_rt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dfe_tipo_nfe_creddeb_rt (
    dominio character varying(20) NOT NULL,
    codigo character varying(2) NOT NULL,
    descricao character varying(200) NOT NULL,
    finalidade integer NOT NULL,
    tpnf_padrao character(1) DEFAULT 'S'::bpchar NOT NULL,
    exige_doc_ref boolean DEFAULT false NOT NULL,
    exige_item_ref boolean DEFAULT false NOT NULL,
    permite_item_ref boolean DEFAULT false NOT NULL,
    permite_multiplos_docs_item_ref boolean DEFAULT false CONSTRAINT dfe_tipo_nfe_creddeb_rt_permite_multiplos_docs_item_re_not_null NOT NULL,
    permite_tributos_legados boolean DEFAULT false NOT NULL,
    permite_pis_cofins_2026 boolean DEFAULT false NOT NULL,
    permite_ipi boolean DEFAULT false NOT NULL,
    movimenta_estoque boolean DEFAULT false NOT NULL,
    movimenta_financeiro boolean DEFAULT false NOT NULL,
    inicio_vigencia date NOT NULL,
    fim_vigencia date,
    ativo boolean DEFAULT true NOT NULL
);


--
-- Name: empresas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.empresas (
    emp_001 integer NOT NULL,
    emp_002 character varying(80) NOT NULL,
    emp_003 character varying(80),
    emp_004 character varying(20) NOT NULL,
    emp_005 character varying(20),
    emp_006 character varying(20),
    emp_007 character varying(10),
    emp_008 character varying(10),
    sit_001 integer DEFAULT 4 NOT NULL,
    cep_004 character varying(125),
    cep_003 character varying(50),
    cid_001 integer,
    cep_002 character varying(9),
    emp_011 bytea,
    emp_012 integer NOT NULL,
    usu_001_1 integer,
    usu_001_2 integer,
    dat_001_1 timestamp without time zone,
    dat_001_2 timestamp without time zone,
    emp_013 character varying(15),
    emp_014 character varying(80),
    crt_codigo integer,
    aliqfednacionalpadrao numeric(15,2) DEFAULT 0.00,
    aliqestadualpadrao numeric(15,2) DEFAULT 0.00,
    aliqmunicipalpadrao numeric(15,2) DEFAULT 0.00,
    taxadeliverypadrao numeric(15,2) DEFAULT 0.00,
    b_pdv_coletivo boolean DEFAULT false,
    b_permite_fechamento_caixa_venda_aberta boolean DEFAULT false,
    numero_nfce integer DEFAULT 0 NOT NULL,
    serie_nfce integer DEFAULT 0 NOT NULL,
    comissao_vendedor numeric(10,2) DEFAULT 0 NOT NULL,
    b_utiliza_controle_cliente boolean DEFAULT false NOT NULL,
    b_permite_fechamento_caixa_outro_usuario boolean DEFAULT false NOT NULL,
    taxa_juros numeric(10,2) DEFAULT 0 NOT NULL,
    numero_nfe integer DEFAULT 0 NOT NULL,
    serie_nfe integer DEFAULT 0 NOT NULL,
    b_utiliza_controle_ambiente boolean DEFAULT false NOT NULL,
    b_permite_fechamento_caixa_venda_pag_antecipado boolean DEFAULT false CONSTRAINT empresas_b_permite_fechamento_caixa_venda_pag_antecipa_not_null NOT NULL,
    id_conta_padrao_cpagar_nfe integer,
    campo_doc_cliente_cnoturna character varying(1) DEFAULT 'C'::character varying,
    margem_preco_prazo numeric(10,2) DEFAULT 0.0 NOT NULL,
    b_atualiza_custo_material_composicao boolean DEFAULT false NOT NULL,
    b_permite_troco_todas_formas boolean DEFAULT false NOT NULL,
    b_considera_rendimento_entrada_composicao boolean DEFAULT false NOT NULL,
    tipo_calculo_juros integer DEFAULT 1 NOT NULL,
    juros_mora_valor numeric(15,2) DEFAULT 0 NOT NULL,
    juros_mora_percent numeric(15,2) DEFAULT 0 NOT NULL,
    inserir_custos_impostos_importacao_nfe boolean DEFAULT false,
    b_buscar_valores_fechamento_caixa boolean DEFAULT false NOT NULL,
    b_pdv_nao_coletivo boolean DEFAULT true NOT NULL,
    cliente_id_ifood character varying(200),
    cliente_secret_ifood character varying(200),
    utiliza_ifood boolean DEFAULT false NOT NULL,
    usuario_dropbox character varying(100),
    senha_dropbox character varying(100),
    celular character varying(20),
    tempo_alerta_delivery integer DEFAULT 0 NOT NULL,
    cat_padrao_touch integer DEFAULT 1 NOT NULL,
    cnae character varying(10),
    padrao_email integer DEFAULT 0 NOT NULL,
    usuario_email character varying(50),
    senha_email character varying(50),
    smtp_email character varying(50),
    porta_email integer,
    tempo_consumo_mesa integer DEFAULT 0 NOT NULL,
    tempo_consumo_comanda integer DEFAULT 0 NOT NULL,
    b_nfce_terminal boolean DEFAULT false NOT NULL,
    b_casa_noturna boolean DEFAULT false NOT NULL,
    b_casa_cpf boolean DEFAULT true NOT NULL,
    b_casa_rg boolean DEFAULT false NOT NULL,
    b_casa_telefone boolean DEFAULT false NOT NULL,
    b_casa_email boolean DEFAULT false NOT NULL,
    b_casa_sexo boolean DEFAULT false NOT NULL,
    b_casa_data_nascimento boolean DEFAULT false NOT NULL,
    b_casa_reter boolean DEFAULT true NOT NULL,
    casa_porc_reter numeric(10,2) DEFAULT 10.00 NOT NULL,
    casa_controle integer DEFAULT 0 NOT NULL,
    rot_preco4 character varying(20),
    rot_preco5 character varying(20),
    rot_preco6 character varying(20),
    rot_preco7 character varying(20),
    b_nfe_ilimitado boolean DEFAULT true NOT NULL,
    nfe_limitar integer DEFAULT 0 NOT NULL,
    b_verifica_fiscal_prod boolean DEFAULT true NOT NULL,
    b_limitar_qtde_pdv boolean DEFAULT false NOT NULL,
    limite_qtde_pdv integer DEFAULT 0 NOT NULL,
    b_limitar_unit_pdv boolean DEFAULT false NOT NULL,
    limite_unit_pdv numeric(15,2) DEFAULT 0.00 NOT NULL,
    cod_produto_generico character varying(50),
    b_notif_sangria boolean DEFAULT false NOT NULL,
    saldo_sangria numeric(15,2) DEFAULT 0.00 NOT NULL,
    b_auto_completar boolean DEFAULT true NOT NULL,
    contab_nome character varying(100),
    contab_cpf character varying(11),
    contab_crc character varying(15),
    contab_cnpj character varying(14),
    contab_cep character varying(8),
    contab_endereco character varying(60),
    contab_numero character varying(10),
    contab_complemento character varying(60),
    contab_bairro character varying(60),
    contab_fone character varying(11),
    contab_fax character varying(11),
    contab_email character varying(100),
    contab_cod_municipio character varying(7),
    gerar_gtin boolean DEFAULT false NOT NULL,
    b_controla_desconto_max boolean DEFAULT false NOT NULL,
    gerar_lacuna boolean DEFAULT false NOT NULL,
    zap_tipo_tel_contato integer DEFAULT 0 NOT NULL,
    taxa_servico_mesa numeric(10,2) DEFAULT 10.00 NOT NULL,
    taxa_servico_comanda numeric(10,2) DEFAULT 10.00 NOT NULL,
    taxa_servico_casa numeric(10,2) DEFAULT 10.00 NOT NULL,
    rotulo_imp_balcao character varying(20) DEFAULT 'Balcão'::character varying NOT NULL,
    rotulo_imp_bar character varying(20) DEFAULT 'Bar'::character varying NOT NULL,
    rotulo_imp_salao character varying(20) DEFAULT 'Salão'::character varying NOT NULL,
    rotulo_imp_ambiente character varying(20) DEFAULT 'Ambiente'::character varying NOT NULL,
    rotulo_imp_chopeira character varying(20) DEFAULT 'Chopeira'::character varying NOT NULL,
    ifood_token character varying(1000),
    ifood_status character varying(100),
    tel_princ integer DEFAULT 0 NOT NULL,
    b_controle_opc boolean DEFAULT false NOT NULL,
    zap_msg_inatividade boolean DEFAULT true NOT NULL,
    utiliza_corrossel boolean DEFAULT false NOT NULL,
    sint_responsavel character varying(100),
    sint_fone character varying(11),
    sped_perfil character(1) DEFAULT 'A'::bpchar NOT NULL,
    sped_cta character varying(255),
    id_entregador_padrao integer,
    rotulo_imp_extra1 character varying(20) DEFAULT 'Extra 1'::character varying NOT NULL,
    rotulo_imp_extra2 character varying(20) DEFAULT 'Extra 2'::character varying NOT NULL,
    ultima_verificacao_manifesto timestamp without time zone DEFAULT now(),
    taxa_adicional_mesa boolean DEFAULT false NOT NULL,
    couvert_mesa boolean DEFAULT false NOT NULL,
    couvert_obrig_mesa boolean DEFAULT false NOT NULL,
    valor_couvert_masc_mesa numeric(15,2) DEFAULT 0 NOT NULL,
    valor_couvert_fem_mesa numeric(15,2) DEFAULT 0 NOT NULL,
    consumacao_mesa boolean DEFAULT false NOT NULL,
    consumacao_minima_mesa numeric(15,2) DEFAULT 0 NOT NULL,
    taxa_adicional_comanda boolean DEFAULT false NOT NULL,
    couvert_comanda boolean DEFAULT false NOT NULL,
    couvert_obrig_comanda boolean DEFAULT false NOT NULL,
    valor_couvert_masc_comanda numeric(15,2) DEFAULT 0 NOT NULL,
    valor_couvert_fem_comanda numeric(15,2) DEFAULT 0 NOT NULL,
    consumacao_comanda boolean DEFAULT false NOT NULL,
    consumacao_minima_comanda numeric(15,2) DEFAULT 0 NOT NULL,
    rotulo_senha_balcao character varying(10) DEFAULT 'COMANDA'::character varying NOT NULL,
    sangria_exibir_disponivel boolean DEFAULT true NOT NULL,
    b_permite_dev_sangria boolean DEFAULT true NOT NULL,
    ped_compra_atualizar_venda boolean DEFAULT false NOT NULL,
    atualizar_ncm_produtos_nfe boolean DEFAULT false NOT NULL,
    atualizar_aliq_produtos_nfe boolean DEFAULT false NOT NULL,
    atualizar_trib_pre_produtos boolean DEFAULT false NOT NULL,
    utiliza_controle_pontos_sara boolean DEFAULT false NOT NULL,
    utiliza_controle_pontos_delivery boolean DEFAULT false NOT NULL,
    gerar_pontos_sara integer DEFAULT 0 NOT NULL,
    gerar_pontos_delivery integer DEFAULT 0 NOT NULL,
    utiliza_api_zap boolean DEFAULT false NOT NULL,
    api_zap_msg_entrega boolean DEFAULT false NOT NULL,
    api_zap_msg_finalizar boolean DEFAULT false NOT NULL,
    api_zap_instancia character varying(100),
    sped_tipo_contribuinte integer DEFAULT 1 NOT NULL,
    msg_pers_finalizar text,
    utiliza_sped boolean DEFAULT false NOT NULL,
    utiliza_rp_movel boolean DEFAULT false NOT NULL,
    b_nao_compensar_aut boolean DEFAULT false NOT NULL,
    cliente_padrao_pdv integer,
    b_ean_apenas_numeros boolean DEFAULT false NOT NULL,
    b_nao_importar_aliquotas boolean DEFAULT false NOT NULL,
    b_alterar_cfop boolean DEFAULT false NOT NULL,
    utiliza_lecheff boolean DEFAULT false,
    rp_balanca_inteligente boolean DEFAULT false NOT NULL,
    rp_balanca_eletronica boolean DEFAULT false NOT NULL,
    valor_max_nfce_sem_ident numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    utiliza_nfe_saida boolean DEFAULT false NOT NULL,
    rp_movel_integracao_stone boolean DEFAULT false NOT NULL,
    imprime_ficha_individual_mesa boolean DEFAULT false NOT NULL,
    imprime_ficha_individual_comanda boolean DEFAULT false NOT NULL,
    imprime_ficha_individual_balcao boolean DEFAULT false NOT NULL,
    imprime_ficha_individual_pdv boolean DEFAULT false NOT NULL,
    rp_movel_integracao_cielo boolean DEFAULT false,
    rp_movel_integracao_pagbank boolean DEFAULT false,
    habilitar_ref_trib boolean DEFAULT false,
    aliq_cbs numeric(15,4) DEFAULT '0'::numeric,
    api_ctrib_ativa boolean DEFAULT false NOT NULL,
    api_ctrib_aud character varying(100),
    api_ctrib_login character varying(100),
    api_ctrib_senha character varying(100),
    api_ctrib_token character varying(1000),
    api_ctrib_validade_token timestamp without time zone,
    api_ctrib_ambiente integer DEFAULT 0 NOT NULL,
    api_ctrib_envio_auto boolean DEFAULT false NOT NULL,
    api_ctrib_envio_intervalo integer DEFAULT 6 NOT NULL,
    utiliza_integracao_pedzap boolean DEFAULT false NOT NULL,
    api_pedzap_baseurl character varying(100),
    api_pedzap_token character varying(1000),
    utiliza_integracao_querodelivery boolean DEFAULT false NOT NULL,
    api_quero_ambiente integer DEFAULT 0 NOT NULL,
    api_quero_placeid character varying(100),
    api_quero_token character varying(1000),
    utiliza_rpcheff_cloud boolean DEFAULT false NOT NULL,
    utiliza_integracao99food boolean DEFAULT false NOT NULL,
    titulo_taxaentrega_mesa_comanda character varying(50) DEFAULT 'Taxa de Entrega'::character varying NOT NULL,
    integracao_pagame boolean DEFAULT false,
    quantidade_maxima_fracao_produtos integer DEFAULT 4 NOT NULL,
    integracao_nfce boolean DEFAULT false NOT NULL,
    utiliza_integracao_anotaai boolean DEFAULT false NOT NULL,
    utiliza_integracao_deliverydireto boolean DEFAULT false NOT NULL,
    utiliza_cardapiotablet boolean DEFAULT false
);


--
-- Name: encerravenda; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.encerravenda (
    enc_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    ven_001 integer NOT NULL,
    cli_001 integer,
    enc_002 timestamp without time zone,
    enc_003 numeric(10,2),
    for_001 integer NOT NULL,
    con_001 integer,
    enc_004 text,
    enc_005 numeric(10,2),
    sit_001 integer NOT NULL,
    usu_001_1 integer,
    dat_001_1 timestamp without time zone,
    enc_006 numeric(10,2),
    enc_007 numeric(10,2),
    mes_001 integer,
    pdv_codigo integer,
    crt_codigo integer,
    ven_satstatus integer,
    ven_cpfconsum character varying(20),
    total_rt_vbcibscbs numeric(15,4) DEFAULT '0'::numeric,
    total_rt_vibsuf numeric(15,4) DEFAULT '0'::numeric,
    total_rt_vibsmun numeric(15,4) DEFAULT '0'::numeric,
    total_rt_vibs numeric(15,4) DEFAULT '0'::numeric,
    total_rt_vcbs numeric(15,4) DEFAULT '0'::numeric,
    total_rt_vnftot numeric(15,4) DEFAULT '0'::numeric,
    infadfisco character varying(200)
);


--
-- Name: encerravendaitem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.encerravendaitem (
    emp_001 integer NOT NULL,
    enc_001 integer NOT NULL,
    ite_001 integer NOT NULL,
    ite_002 timestamp without time zone,
    ite_003 numeric(10,2),
    ite_004 integer,
    ite_005 numeric(10,2),
    id_formapgto integer,
    sfi_codigo integer,
    troco_dinheiro numeric(15,2) DEFAULT 0.00,
    tef_transacao character varying(255),
    tef_confirmacao character varying(255),
    tef_rede character varying(255),
    tef_campo_11 character varying(255),
    autorizacao character varying(50),
    b_nova_venda boolean DEFAULT false NOT NULL,
    taxa_cartao numeric(15,2) DEFAULT 0.00 NOT NULL,
    acquirerdocument character varying(50),
    hash_terminal character varying(40)
);


--
-- Name: estados; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.estados (
    est_001 integer NOT NULL,
    est_002 character varying(40) NOT NULL,
    est_003 character(2) NOT NULL,
    pai_001 integer NOT NULL,
    codigo_ibge integer,
    aliq_ibs_uf numeric(15,4) DEFAULT '0'::numeric
);


--
-- Name: eventos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos (
    id_evento integer NOT NULL,
    emp_001 integer NOT NULL,
    descricao character varying(40) NOT NULL,
    sit_001 integer DEFAULT 4 NOT NULL,
    data_evento date,
    hora_evento time without time zone,
    mesas_total integer DEFAULT 0 NOT NULL,
    mesas_vendidas integer DEFAULT 0 NOT NULL,
    mesas_disponiveis integer DEFAULT 0 NOT NULL
);


--
-- Name: eventos_detalhes_nfe_rt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos_detalhes_nfe_rt (
    id integer NOT NULL,
    id_evento integer NOT NULL,
    id_empresa integer NOT NULL,
    numero_item integer NOT NULL,
    valor_bc numeric(15,2) DEFAULT 0 NOT NULL,
    ccredpres character varying(2),
    cred_pres_aliq_ibs numeric(15,2) DEFAULT 0 NOT NULL,
    cred_pres_aliq_cbs numeric(15,2) DEFAULT 0 NOT NULL,
    cred_pres_valor_ibs numeric(15,2) DEFAULT 0 NOT NULL,
    cred_pres_valor_cbs numeric(15,2) DEFAULT 0 NOT NULL,
    valor_ibs numeric(15,2) DEFAULT 0 NOT NULL,
    valor_cbs numeric(15,2) DEFAULT 0 NOT NULL,
    quantidade numeric(15,3) DEFAULT 0 NOT NULL,
    credito_ibs numeric(15,2) DEFAULT 0 NOT NULL,
    credito_cbs numeric(15,2) DEFAULT 0 NOT NULL,
    unidade character varying(6),
    doc_ref character varying(50)
);


--
-- Name: eventos_detalhes_nfe_rt_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eventos_detalhes_nfe_rt_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eventos_detalhes_nfe_rt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eventos_detalhes_nfe_rt_id_seq OWNED BY public.eventos_detalhes_nfe_rt.id;


--
-- Name: eventos_mesas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos_mesas (
    id_evento integer NOT NULL,
    emp_001 integer NOT NULL,
    numero_mesa integer NOT NULL,
    rotulo_mesa character varying(10) NOT NULL,
    pessoas integer NOT NULL,
    valor_mesa numeric(15,2) DEFAULT 0 NOT NULL,
    b_vendida boolean DEFAULT false NOT NULL,
    id_forma integer,
    id_caixa_venda integer,
    cliente_nome character varying(90),
    cliente_cpf character varying(20),
    cliente_telefone character varying(20),
    data_venda date,
    hora_venda time without time zone
);


--
-- Name: eventos_nfe_rt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos_nfe_rt (
    id integer NOT NULL,
    id_empresa integer NOT NULL,
    id_usuario integer NOT NULL,
    data_evento timestamp without time zone NOT NULL,
    autor character varying(15) NOT NULL,
    tipo_evento character varying(200) NOT NULL,
    protocolo character varying(40) NOT NULL,
    aceite character(1),
    previsao date,
    chave_nfe character varying(50) NOT NULL
);


--
-- Name: eventos_nfe_rt_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eventos_nfe_rt_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eventos_nfe_rt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eventos_nfe_rt_id_seq OWNED BY public.eventos_nfe_rt.id;


--
-- Name: execucoes_estoque; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.execucoes_estoque (
    id integer NOT NULL,
    id_empresa integer NOT NULL,
    id_usuario integer NOT NULL,
    operacao integer DEFAULT 0 NOT NULL,
    data date,
    hora time without time zone,
    descricao character varying(100),
    b_nfe boolean DEFAULT false NOT NULL,
    total_compra numeric(10,2) DEFAULT 0.00 NOT NULL,
    total_venda numeric(10,2) DEFAULT 0.00 NOT NULL,
    qtde_itens integer DEFAULT 0 NOT NULL,
    qtde_volumes numeric(15,3) DEFAULT 0.000 NOT NULL,
    tipo_valor integer DEFAULT 1 NOT NULL
);


--
-- Name: execucoes_estoque_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.execucoes_estoque_item (
    id_mestre integer NOT NULL,
    item integer NOT NULL,
    id_empresa integer NOT NULL,
    id_material integer NOT NULL,
    quantidade numeric(15,3) DEFAULT 1.0 NOT NULL,
    valor_custo numeric(15,3) DEFAULT 0.0 NOT NULL,
    valor_total_custo numeric(15,3) DEFAULT 0.0 NOT NULL,
    valor_venda numeric(15,3) DEFAULT 0.0 NOT NULL,
    valor_total_venda numeric(15,3) DEFAULT 0.0 NOT NULL,
    obs text
);


--
-- Name: formapgto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.formapgto (
    for_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    for_002 character varying(40) NOT NULL,
    sit_001 integer DEFAULT 4 NOT NULL,
    usu_001_1 integer,
    usu_001_3 integer,
    dat_001_1 timestamp without time zone,
    dat_001_3 timestamp without time zone,
    bandeira_cartao character(1) DEFAULT 'O'::bpchar,
    sfi_codigo integer,
    b_fiado boolean DEFAULT false NOT NULL,
    id_conta integer,
    b_tef boolean DEFAULT false NOT NULL,
    taxa_cartao numeric(15,2),
    prazo_cartao integer,
    utiliza_controle_cartao boolean DEFAULT false NOT NULL,
    id_contacorrente integer,
    emite_fiscal boolean DEFAULT false NOT NULL,
    cnpjcred character varying(14),
    tipo_integracao integer DEFAULT 2 NOT NULL,
    juros numeric(15,2) DEFAULT 0.00 NOT NULL,
    b_cortesia boolean DEFAULT false NOT NULL,
    ifood_code character varying(20),
    atalho integer DEFAULT 0 NOT NULL,
    b_exibir_web boolean DEFAULT false NOT NULL,
    id_partic integer,
    utiliza_integracao_pix boolean DEFAULT false NOT NULL,
    utilizapagamentoonline boolean DEFAULT false NOT NULL,
    permite_pag_parcelado boolean DEFAULT false NOT NULL,
    exibir_forma_app boolean DEFAULT false NOT NULL,
    quero_delivery_code character varying(20),
    pedizap_code character varying(20),
    integracaopagamentoonline boolean DEFAULT false NOT NULL,
    anotaai_code character varying(20)
);


--
-- Name: fornecedor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fornecedor (
    id_fornecedor integer NOT NULL,
    nome_fantasia character varying(100) NOT NULL,
    razao_social character varying(100) NOT NULL,
    id_usuario_cadastro integer NOT NULL,
    id_empresa integer NOT NULL,
    endereco_logradouro character varying(100),
    endereco_numero character varying(20),
    endereco_bairro character varying(100),
    endereco_cidade character varying(100),
    endereco_uf character varying(2),
    endereco_cep character varying(9),
    endereco_complemento character varying(100),
    id_cidade integer,
    telefone1 character varying(20),
    telefone2 character varying(20),
    celular1 character varying(20),
    celular2 character varying(20),
    email character varying(100),
    site character varying(100),
    cnpj character varying(14),
    nome_contato1 character varying(100),
    nome_contato2 character varying(100),
    banco character varying(100),
    agencia character varying(20),
    conta character varying(20),
    data_cadastro timestamp without time zone NOT NULL,
    cpf character varying(11),
    tipo_pessoa character(1) DEFAULT 'J'::bpchar NOT NULL,
    codigo_municipio character varying(20),
    codigo_ibge character varying(20),
    cnae character varying(20),
    inscricao_estadual character varying(20),
    inscricao_municipal character varying(20),
    observacoes text,
    id_situacao integer DEFAULT 4 NOT NULL
);


--
-- Name: galeria_imagens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.galeria_imagens (
    gal_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    tipo_galeria character(1) DEFAULT 'P'::bpchar NOT NULL,
    img bytea,
    tipo_imagem integer DEFAULT 0 NOT NULL
);


--
-- Name: grupos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.grupos AS
 SELECT cat_001 AS codigo,
    emp_001 AS id_empresa,
    cat_002 AS descricao,
    sit_001 AS id_situacao,
    COALESCE(b_exibir_web, false) AS b_exibir_web,
    imagem_db AS img
   FROM public.categoria;


--
-- Name: ibpt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ibpt (
    ncm character varying(20),
    descricao character varying(500),
    ex character varying(20),
    tabela integer,
    aliqfednacional numeric(15,2),
    aliqfedimportado numeric(15,2),
    aliqestadual numeric(15,2),
    aliqmunicipal numeric(15,2),
    ibpt_001 integer DEFAULT 0 NOT NULL,
    b_manual boolean DEFAULT false NOT NULL
);


--
-- Name: ifood_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ifood_log (
    correlationid character varying(50) NOT NULL,
    emp_001 integer DEFAULT 1 NOT NULL,
    data date,
    hora time without time zone,
    shortreference character varying(10),
    cliente character varying(90),
    total numeric(10,2) DEFAULT 0.00 NOT NULL,
    obs text,
    "json" text
);


--
-- Name: ifood_merchants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ifood_merchants (
    mer_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    descricao character varying(40) NOT NULL,
    merchant_id character varying(100) NOT NULL,
    sit_001 integer DEFAULT 4 NOT NULL
);


--
-- Name: ifood_pag; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ifood_pag (
    correlationid character varying(50),
    id_forma integer,
    forma character varying(100),
    valor_forma numeric(10,2) DEFAULT 0.00 NOT NULL,
    changefor numeric(10,2) DEFAULT 0.00 NOT NULL,
    changevalue numeric(10,2) DEFAULT 0.00 NOT NULL,
    prepaid boolean DEFAULT false NOT NULL,
    cardbrand character varying(100),
    authorizationcode character varying(50),
    acquirerdocument character varying(50)
);


--
-- Name: ifood_pedidos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ifood_pedidos (
    correlationid character varying(50) NOT NULL,
    data date,
    hora time without time zone,
    shortreference character varying(10),
    uuid character varying(50),
    idcliente integer,
    cliente character varying(90),
    telefone character varying(20),
    endereco character varying(100),
    nrendereco character varying(10),
    bairro character varying(50),
    cep character varying(10),
    cidade character varying(100),
    complemento character varying(100),
    referencia character varying(200),
    uf character varying(2),
    cpf_cnpj character varying(20),
    deliverymethod character varying(15),
    delivery numeric(10,2) DEFAULT 0.00 NOT NULL,
    desconto numeric(10,2) DEFAULT 0.00 NOT NULL,
    voucher_ifood numeric(10,2) DEFAULT 0.00 NOT NULL,
    additionalfees numeric(10,2) DEFAULT 0.00 NOT NULL,
    sponsorvalue numeric(10,2) DEFAULT 0.00 NOT NULL,
    subtotal numeric(10,2) DEFAULT 0.00 NOT NULL,
    total numeric(10,2) DEFAULT 0.00 NOT NULL,
    scheduled boolean DEFAULT false NOT NULL,
    data_agendamento date,
    hora_agendamento time without time zone,
    extrainfo character varying(100),
    endlinha1 character varying(300),
    endlinha2 character varying(300),
    obs character varying(200),
    "json" text,
    b_em_uso boolean DEFAULT false NOT NULL,
    terminal_uso character varying(40),
    emp_001 integer DEFAULT 1 NOT NULL,
    pickupcode character varying(20),
    delivery_moto numeric(10,2) DEFAULT 0.00 NOT NULL,
    merchant_id character varying(100)
);


--
-- Name: ifood_produtos_mestre; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ifood_produtos_mestre (
    correlationid character varying(50),
    idproduto integer,
    externalcode character varying(10),
    descricao character varying(100),
    quantidade numeric(10,2) DEFAULT 0.00 NOT NULL,
    valor_unitario numeric(10,2) DEFAULT 0.00 NOT NULL,
    valor_acrescimo numeric(10,2) DEFAULT 0.00 NOT NULL,
    valor_total numeric(10,2) DEFAULT 0.00 NOT NULL,
    impressora integer,
    impressora2 integer,
    b_venda_tamanho boolean DEFAULT false NOT NULL,
    tamanho character varying(2),
    item_fracionado integer,
    index integer,
    obs character varying(200),
    flag_encontrado boolean DEFAULT false NOT NULL
);


--
-- Name: ifood_produtos_opc; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ifood_produtos_opc (
    correlationid character varying(50),
    idopcional integer,
    externalcodemestre character varying(20),
    externalcodeopc character varying(20),
    descricao character varying(200),
    descricaoabrev character varying(200),
    quantity numeric(10,2) DEFAULT 0.00 NOT NULL,
    valor numeric(10,2) DEFAULT 0.00 NOT NULL,
    index integer,
    flag_encontrado boolean DEFAULT false NOT NULL
);


--
-- Name: ifood_rejeitados; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ifood_rejeitados (
    id integer NOT NULL,
    correlation_id character varying(50) NOT NULL,
    data timestamp without time zone,
    emp_001 integer DEFAULT 1 NOT NULL
);


--
-- Name: ifood_rejeitados_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ifood_rejeitados_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ifood_rejeitados_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ifood_rejeitados_id_seq OWNED BY public.ifood_rejeitados.id;


--
-- Name: impressaoproducao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.impressaoproducao (
    idproduto integer,
    idempresa integer,
    qtdevendido double precision,
    descricaoproduto character varying(255),
    datalancamento timestamp without time zone,
    produtoimpresso boolean,
    nomegarcom character varying(255),
    idvenda integer,
    tipovenda character varying(50),
    quantidadeviaimpressao integer,
    id integer NOT NULL,
    impressorainterna boolean DEFAULT false NOT NULL
);


--
-- Name: impressaoproducao_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.impressaoproducao_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: impressaoproducao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.impressaoproducao_id_seq OWNED BY public.impressaoproducao.id;


--
-- Name: informativoversao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.informativoversao (
    id integer NOT NULL,
    informacao1 character varying(300),
    informacao2 character varying(300),
    informacao3 character varying(300),
    informacao4 character varying(300),
    informacao5 character varying(300),
    informacao6 character varying(300),
    informacao7 character varying(300),
    versao_atual character varying(30)
);


--
-- Name: informativoversao_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.informativoversao_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: informativoversao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.informativoversao_id_seq OWNED BY public.informativoversao.id;


--
-- Name: inner_catraca; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inner_catraca (
    inner_numero integer DEFAULT 1 NOT NULL,
    digitos integer DEFAULT 14 NOT NULL,
    porta integer DEFAULT 3570 NOT NULL,
    conexao integer DEFAULT 2 NOT NULL,
    equipamento integer DEFAULT 5 NOT NULL,
    leitor integer DEFAULT 2 NOT NULL,
    esquerda boolean DEFAULT true NOT NULL,
    dois_leitores boolean DEFAULT false NOT NULL
);


--
-- Name: integracao99foodconfig; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracao99foodconfig (
    id bigint NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    id_loja_local integer,
    app_shop_id character varying(100) NOT NULL,
    shop_id_99food character varying(100),
    nome_estabelecimento character varying(150),
    endereco character varying(255),
    cidade character varying(120),
    app_id character varying(120),
    nome_aplicativo character varying(150),
    descricao_aplicativo text,
    webhook_url text,
    pais character(2),
    email_aviso character varying(255),
    tipo_aplicativo character varying(40),
    client_id text,
    client_secret text,
    access_token text,
    refresh_token text,
    token_expira_em timestamp without time zone,
    base_url text,
    webhook_secret text,
    ambiente character varying(20) DEFAULT 'producao'::character varying NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    payload jsonb,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp without time zone
);


--
-- Name: integracao99foodconfig_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracao99foodconfig_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracao99foodconfig_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracao99foodconfig_id_seq OWNED BY public.integracao99foodconfig.id;


--
-- Name: integracao99foodfila; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracao99foodfila (
    id bigint NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    app_shop_id character varying(100),
    tipo character varying(50) NOT NULL,
    order_id character varying(120),
    event_id character varying(120),
    payload jsonb,
    tentativas integer DEFAULT 0 NOT NULL,
    max_tentativas integer DEFAULT 5 NOT NULL,
    status character varying(30) DEFAULT 'PENDENTE'::character varying NOT NULL,
    ultimo_erro text,
    executar_em timestamp without time zone DEFAULT now() NOT NULL,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp without time zone
);


--
-- Name: integracao99foodfila_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracao99foodfila_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracao99foodfila_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracao99foodfila_id_seq OWNED BY public.integracao99foodfila.id;


--
-- Name: integracao99foodfinanceirobill; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracao99foodfinanceirobill (
    id bigint NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    app_shop_id character varying(100) NOT NULL,
    chave_financeira character varying(255) NOT NULL,
    shop_id bigint,
    shop_name character varying(255),
    contractor_id bigint,
    contractor_name character varying(255),
    city_id bigint,
    city_name character varying(120),
    order_id character varying(120),
    order_index character varying(80),
    order_type integer DEFAULT 0 NOT NULL,
    delivery_type integer DEFAULT 0 NOT NULL,
    business_ts bigint DEFAULT 0 NOT NULL,
    business_datetime timestamp without time zone,
    meal_original_amount numeric(15,2) DEFAULT 0 NOT NULL,
    shop_activity_outcome numeric(15,2) DEFAULT 0 NOT NULL,
    shop_activity_subsidy numeric(15,2) DEFAULT 0 NOT NULL,
    shop_delivery_amount numeric(15,2) DEFAULT 0 NOT NULL,
    shop_pre_tips numeric(15,2) DEFAULT 0 NOT NULL,
    free_delivery_outcome numeric(15,2) DEFAULT 0 NOT NULL,
    free_delivery_subsidy numeric(15,2) DEFAULT 0 NOT NULL,
    commission_base_amount numeric(15,2) DEFAULT 0 NOT NULL,
    commission_rate integer DEFAULT 0 NOT NULL,
    commission_amount numeric(15,2) DEFAULT 0 NOT NULL,
    commission_subsidy_amount numeric(15,2) DEFAULT 0 CONSTRAINT integracao99foodfinanceirobi_commission_subsidy_amount_not_null NOT NULL,
    b2p_delivery_amount numeric(15,2) DEFAULT 0 NOT NULL,
    pay_commission_amount numeric(15,2) DEFAULT 0 NOT NULL,
    min_value_difference_amount numeric(15,2) DEFAULT 0 CONSTRAINT integracao99foodfinanceirob_min_value_difference_amoun_not_null NOT NULL,
    order_amount numeric(15,2) DEFAULT 0 NOT NULL,
    payment_method integer DEFAULT 0 NOT NULL,
    payment_channel integer DEFAULT 0 NOT NULL,
    payment_method_detail integer DEFAULT 0 NOT NULL,
    card_brand character varying(80),
    cancel_datetime timestamp without time zone,
    cancel_ts bigint DEFAULT 0 NOT NULL,
    cancel_reason integer DEFAULT 0 NOT NULL,
    cash_balance numeric(15,2) DEFAULT 0 NOT NULL,
    meal_voucher_amount numeric(15,2) DEFAULT 0 NOT NULL,
    settlement_amount numeric(15,2) DEFAULT 0 NOT NULL,
    expect_settle_date date,
    day_payment_id character varying(120),
    meal_loss_deduct_amount numeric(15,2) DEFAULT 0 NOT NULL,
    vat_amount numeric(15,2) DEFAULT 0 NOT NULL,
    merchant_appeal_amount numeric(15,2) DEFAULT 0 NOT NULL,
    monthly_service_price numeric(15,2) DEFAULT 0 NOT NULL,
    gmv numeric(15,2) DEFAULT 0 NOT NULL,
    monthly_service_base_price numeric(15,2) DEFAULT 0 CONSTRAINT integracao99foodfinanceirob_monthly_service_base_price_not_null NOT NULL,
    monthly_service_calculation_cycle character varying(40),
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: integracao99foodfinanceirobill_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracao99foodfinanceirobill_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracao99foodfinanceirobill_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracao99foodfinanceirobill_id_seq OWNED BY public.integracao99foodfinanceirobill.id;


--
-- Name: integracao99foodfinanceirosettlement; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracao99foodfinanceirosettlement (
    id bigint NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    app_shop_id character varying(100) NOT NULL,
    chave_financeira character varying(255) NOT NULL,
    week_payment_id character varying(120),
    withdraw_date date,
    withdraw_amount numeric(15,2) DEFAULT 0 NOT NULL,
    liability character varying(120),
    shop_id bigint,
    settle_start_date date,
    settle_end_date date,
    currency character varying(10),
    day_payment_id_list jsonb DEFAULT '[]'::jsonb CONSTRAINT integracao99foodfinanceirosettleme_day_payment_id_list_not_null NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: integracao99foodfinanceirosettlement_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracao99foodfinanceirosettlement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracao99foodfinanceirosettlement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracao99foodfinanceirosettlement_id_seq OWNED BY public.integracao99foodfinanceirosettlement.id;


--
-- Name: integracao99foodhttplog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracao99foodhttplog (
    id bigint NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    app_shop_id character varying(100),
    metodo character varying(10) NOT NULL,
    endpoint text NOT NULL,
    status_code integer,
    request_body jsonb,
    response_body jsonb,
    erro text,
    duracao_ms integer,
    criado_em timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: integracao99foodhttplog_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracao99foodhttplog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracao99foodhttplog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracao99foodhttplog_id_seq OWNED BY public.integracao99foodhttplog.id;


--
-- Name: integracao99foodloja; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracao99foodloja (
    id bigint NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    id_loja_local integer,
    app_shop_id character varying(100) NOT NULL,
    nome character varying(150),
    documento character varying(30),
    payload jsonb,
    ativo boolean DEFAULT true NOT NULL,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp without time zone
);


--
-- Name: integracao99foodloja_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracao99foodloja_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracao99foodloja_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracao99foodloja_id_seq OWNED BY public.integracao99foodloja.id;


--
-- Name: integracao99foodpedido; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracao99foodpedido (
    id bigint NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    id_loja_local integer,
    app_shop_id character varying(100) DEFAULT ''::character varying NOT NULL,
    order_id character varying(120) NOT NULL,
    display_id character varying(60),
    external_order_id character varying(120),
    status integer DEFAULT 0 NOT NULL,
    status_externo character varying(80),
    status_nome character varying(120),
    status_local character varying(40) DEFAULT 'RECEBIDO'::character varying NOT NULL,
    tipo_evento character varying(80),
    tipo_entrega character varying(40),
    canal character varying(40) DEFAULT '99FOOD'::character varying NOT NULL,
    total numeric(15,2) DEFAULT 0 NOT NULL,
    subtotal numeric(15,2) DEFAULT 0 NOT NULL,
    entrega_valor numeric(15,2) DEFAULT 0 NOT NULL,
    desconto numeric(15,2) DEFAULT 0 NOT NULL,
    acrescimo numeric(15,2) DEFAULT 0 NOT NULL,
    valor_itens numeric(15,2) DEFAULT 0 NOT NULL,
    valor_entrega numeric(15,2) DEFAULT 0 NOT NULL,
    valor_desconto numeric(15,2) DEFAULT 0 NOT NULL,
    valor_total numeric(15,2) DEFAULT 0 NOT NULL,
    items_quantity integer DEFAULT 0 NOT NULL,
    pago character(1) DEFAULT 'N'::bpchar NOT NULL,
    pagto_data timestamp without time zone,
    data timestamp without time zone,
    data_pedido timestamp without time zone,
    data_agendamento timestamp without time zone,
    cliente_nome character varying(255),
    cadastro_celular character varying(40),
    cadastro_nome character varying(255),
    cadastro_cpf character varying(30),
    cadastro_email character varying(255),
    entrega_metodo character varying(80),
    entrega_servico character varying(80),
    entrega_descricao character varying(255),
    observacao text,
    end_entrega_endereco character varying(255),
    end_entrega_numero character varying(300),
    end_entrega_complemento character varying(255),
    end_entrega_referencia character varying(255),
    end_entrega_bairro character varying(120),
    end_entrega_cidade character varying(120),
    end_entrega_geolocation character varying(80),
    end_entrega_cep character varying(20),
    end_entrega_uf character varying(20),
    pagto_metodo character varying(80),
    pagto_metodo_nome character varying(120),
    pagto_metododesc text,
    pagto_descricao character varying(120),
    pagto_valorautorizado numeric(15,2) DEFAULT 0 NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    assinatura character varying(255),
    mensagem text,
    pedido_importado boolean DEFAULT false NOT NULL,
    integrado_venda boolean DEFAULT false NOT NULL,
    id_venda_local bigint,
    recebido_em timestamp without time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp without time zone DEFAULT now() NOT NULL,
    fulfillment_mode smallint DEFAULT '0'::smallint NOT NULL,
    takeaway_code character varying(10),
    logistics_cost numeric(15,2) DEFAULT '0'::numeric NOT NULL
);


--
-- Name: integracao99foodpedido_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracao99foodpedido_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracao99foodpedido_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracao99foodpedido_id_seq OWNED BY public.integracao99foodpedido.id;


--
-- Name: integracao99foodpedidocliente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracao99foodpedidocliente (
    id bigint NOT NULL,
    pedido_id bigint,
    id_empresa integer DEFAULT 1 NOT NULL,
    app_shop_id character varying(100),
    order_id character varying(120) NOT NULL,
    cliente_id_externo character varying(120),
    nome character varying(255),
    telefone character varying(40),
    celular character varying(40),
    documento character varying(30),
    email character varying(255),
    payload jsonb,
    criado_em timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: integracao99foodpedidocliente_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracao99foodpedidocliente_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracao99foodpedidocliente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracao99foodpedidocliente_id_seq OWNED BY public.integracao99foodpedidocliente.id;


--
-- Name: integracao99foodpedidoendereco; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracao99foodpedidoendereco (
    id bigint NOT NULL,
    pedido_id bigint,
    id_empresa integer DEFAULT 1 NOT NULL,
    app_shop_id character varying(100),
    order_id character varying(120) NOT NULL,
    descricao character varying(255),
    logradouro character varying(255),
    numero character varying(300),
    complemento character varying(255),
    referencia character varying(255),
    bairro character varying(120),
    cidade character varying(120),
    uf character varying(20),
    cep character varying(20),
    latitude numeric(12,8),
    longitude numeric(12,8),
    geolocation character varying(80),
    payload jsonb,
    criado_em timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: integracao99foodpedidoendereco_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracao99foodpedidoendereco_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracao99foodpedidoendereco_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracao99foodpedidoendereco_id_seq OWNED BY public.integracao99foodpedidoendereco.id;


--
-- Name: integracao99foodpedidoitem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracao99foodpedidoitem (
    id bigint NOT NULL,
    pedido_id bigint,
    id_empresa integer DEFAULT 1 NOT NULL,
    app_shop_id character varying(100),
    order_id character varying(120) NOT NULL,
    numero_item integer NOT NULL,
    item_id character varying(120),
    product_id integer,
    product_code character varying(150),
    product_name character varying(255) NOT NULL,
    description text,
    quantity numeric(15,4) DEFAULT 1 NOT NULL,
    price numeric(15,2) DEFAULT 0 NOT NULL,
    valor_unitario numeric(15,2) DEFAULT 0 NOT NULL,
    valor_total numeric(15,2) DEFAULT 0 NOT NULL,
    desconto numeric(15,2) DEFAULT 0 NOT NULL,
    obs text,
    payload jsonb,
    criado_em timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: integracao99foodpedidoitem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracao99foodpedidoitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracao99foodpedidoitem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracao99foodpedidoitem_id_seq OWNED BY public.integracao99foodpedidoitem.id;


--
-- Name: integracao99foodpedidoopcional; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracao99foodpedidoopcional (
    id bigint NOT NULL,
    pedido_id bigint,
    pedido_item_id bigint,
    id_empresa integer DEFAULT 1 NOT NULL,
    app_shop_id character varying(100),
    order_id character varying(120) NOT NULL,
    numero_item integer,
    item_id character varying(120),
    opcional_id character varying(120),
    product_id integer,
    product_code character varying(150),
    product_name character varying(255) NOT NULL,
    quantity numeric(15,4) DEFAULT 1 NOT NULL,
    price numeric(15,2) DEFAULT 0 NOT NULL,
    valor_unitario numeric(15,2) DEFAULT 0 NOT NULL,
    valor_total numeric(15,2) DEFAULT 0 NOT NULL,
    payload jsonb,
    criado_em timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: integracao99foodpedidoopcional_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracao99foodpedidoopcional_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracao99foodpedidoopcional_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracao99foodpedidoopcional_id_seq OWNED BY public.integracao99foodpedidoopcional.id;


--
-- Name: integracao99foodpedidopagamento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracao99foodpedidopagamento (
    id bigint NOT NULL,
    pedido_id bigint,
    id_empresa integer DEFAULT 1 NOT NULL,
    app_shop_id character varying(100),
    order_id character varying(120) NOT NULL,
    payment_id character varying(120),
    metodo character varying(80),
    metodo_nome character varying(120),
    metodo_desc text,
    metodo_local character varying(80),
    pago character(1) DEFAULT 'N'::bpchar NOT NULL,
    prepaid boolean,
    valor numeric(15,2) DEFAULT 0 NOT NULL,
    valor_autorizado numeric(15,2) DEFAULT 0 NOT NULL,
    troco numeric(15,2),
    bandeira character varying(50),
    autorizacao character varying(100),
    capturado boolean,
    payload jsonb,
    criado_em timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: integracao99foodpedidopagamento_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracao99foodpedidopagamento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracao99foodpedidopagamento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracao99foodpedidopagamento_id_seq OWNED BY public.integracao99foodpedidopagamento.id;


--
-- Name: integracao99foodpedidostatus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracao99foodpedidostatus (
    id bigint NOT NULL,
    pedido_id bigint,
    id_empresa integer DEFAULT 1 NOT NULL,
    app_shop_id character varying(100),
    order_id character varying(120) NOT NULL,
    event_id character varying(120),
    status integer,
    status_externo character varying(80),
    status_nome character varying(120),
    status_local character varying(40),
    origem character varying(30) DEFAULT '99FOOD'::character varying NOT NULL,
    payload jsonb,
    criado_em timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: integracao99foodpedidostatus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracao99foodpedidostatus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracao99foodpedidostatus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracao99foodpedidostatus_id_seq OWNED BY public.integracao99foodpedidostatus.id;


--
-- Name: integracao99foodwebhooklog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracao99foodwebhooklog (
    id bigint NOT NULL,
    id_empresa integer,
    app_shop_id character varying(100),
    event_id character varying(120),
    webhook_id character varying(120),
    event_type character varying(120),
    order_id character varying(120),
    assinatura character varying(255),
    payload jsonb NOT NULL,
    processado boolean DEFAULT false NOT NULL,
    duplicado boolean DEFAULT false NOT NULL,
    erro text,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    processado_em timestamp without time zone
);


--
-- Name: integracao99foodwebhooklog_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracao99foodwebhooklog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracao99foodwebhooklog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracao99foodwebhooklog_id_seq OWNED BY public.integracao99foodwebhooklog.id;


--
-- Name: integracaoanotaaicheckpoint; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoanotaaicheckpoint (
    id bigint NOT NULL,
    config_id bigint,
    id_empresa integer NOT NULL,
    merchant_id character varying(180) NOT NULL,
    tipo character varying(60) NOT NULL,
    cursor_valor text,
    janela_inicio timestamp with time zone,
    janela_fim timestamp with time zone,
    ultimo_inicio_em timestamp with time zone,
    ultimo_sucesso_em timestamp with time zone,
    erro text,
    atualizado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: integracaoanotaaicheckpoint_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoanotaaicheckpoint_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoanotaaicheckpoint_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoanotaaicheckpoint_id_seq OWNED BY public.integracaoanotaaicheckpoint.id;


--
-- Name: integracaoanotaaiconfig; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoanotaaiconfig (
    id bigint NOT NULL,
    id_empresa integer NOT NULL,
    merchant_id character varying(180) NOT NULL,
    ambiente character varying(30) DEFAULT 'PRODUCAO'::character varying NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    contrato_versao character varying(60),
    contrato_validado boolean DEFAULT false NOT NULL,
    contrato_validado_em timestamp with time zone,
    oauth_authorization_url text,
    oauth_token_url text,
    orders_base_url text,
    menu_base_url text,
    partners_base_url text,
    user_agent character varying(300) DEFAULT 'RPCHEFF-AnotaAI/1.0.0 (production; Delphi/13.1)'::character varying NOT NULL,
    client_id character varying(300),
    client_secret_ref character varying(300),
    software_house_client_id character varying(300),
    software_house_client_secret_ref character varying(300),
    software_house_partner_id character varying(180),
    store_id character varying(180),
    store_page_id character varying(180),
    store_token_ref character varying(300),
    store_ifood_id character varying(180),
    access_token_cipher bytea,
    refresh_token_cipher bytea,
    token_type character varying(40),
    scope text,
    token_expires_at timestamp with time zone,
    token_updated_at timestamp with time zone,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    criado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    atualizado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: COLUMN integracaoanotaaiconfig.client_secret_ref; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.integracaoanotaaiconfig.client_secret_ref IS 'Compatibilidade: referencia do Client Secret da software house fora do banco.';


--
-- Name: COLUMN integracaoanotaaiconfig.software_house_client_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.integracaoanotaaiconfig.software_house_client_id IS 'Client ID da software house/integrador no portal integracao.anota.ai.';


--
-- Name: COLUMN integracaoanotaaiconfig.software_house_client_secret_ref; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.integracaoanotaaiconfig.software_house_client_secret_ref IS 'Referencia para Client Secret da software house em cofre/credencial externa; nao salvar texto puro.';


--
-- Name: COLUMN integracaoanotaaiconfig.software_house_partner_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.integracaoanotaaiconfig.software_house_partner_id IS 'Identificador do parceiro/software house quando fornecido pela Anota AI.';


--
-- Name: COLUMN integracaoanotaaiconfig.store_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.integracaoanotaaiconfig.store_id IS 'ID da loja do cliente no admin.anota.ai; deve acompanhar merchant_id.';


--
-- Name: COLUMN integracaoanotaaiconfig.store_page_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.integracaoanotaaiconfig.store_page_id IS 'x-page-id da API v2; extrair do claim idpage do token/JWT da loja no Portal de Integracao.';


--
-- Name: COLUMN integracaoanotaaiconfig.store_token_ref; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.integracaoanotaaiconfig.store_token_ref IS 'Referencia da Chave de integracao/Token da loja do cliente em cofre/credencial externa.';


--
-- Name: COLUMN integracaoanotaaiconfig.store_ifood_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.integracaoanotaaiconfig.store_ifood_id IS 'ID da loja iFood exibido no painel do cliente, usado apenas para rastreio/mapeamento quando necessario.';


--
-- Name: COLUMN integracaoanotaaiconfig.access_token_cipher; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.integracaoanotaaiconfig.access_token_cipher IS 'Usar somente se criptografado por chave externa ao banco.';


--
-- Name: COLUMN integracaoanotaaiconfig.refresh_token_cipher; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.integracaoanotaaiconfig.refresh_token_cipher IS 'Usar somente se criptografado por chave externa ao banco.';


--
-- Name: integracaoanotaaiconfig_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoanotaaiconfig_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoanotaaiconfig_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoanotaaiconfig_id_seq OWNED BY public.integracaoanotaaiconfig.id;


--
-- Name: integracaoanotaaihttplog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoanotaaihttplog (
    id bigint NOT NULL,
    config_id bigint,
    id_empresa integer NOT NULL,
    merchant_id character varying(180),
    operacao character varying(80) NOT NULL,
    metodo_http character varying(10),
    url_sanitizada text,
    status_code integer,
    duracao_ms integer,
    request_hash character(64),
    response_hash character(64),
    erro text,
    criado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: integracaoanotaaihttplog_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoanotaaihttplog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoanotaaihttplog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoanotaaihttplog_id_seq OWNED BY public.integracaoanotaaihttplog.id;


--
-- Name: integracaoanotaaiinbox; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoanotaaiinbox (
    id bigint NOT NULL,
    config_id bigint,
    id_empresa integer NOT NULL,
    merchant_id character varying(180) NOT NULL,
    origem character varying(30) NOT NULL,
    event_id character varying(180),
    order_id character varying(180),
    payload_hash character(64) NOT NULL,
    payload jsonb NOT NULL,
    status_processamento character varying(30) DEFAULT 'PENDENTE'::character varying NOT NULL,
    tentativas integer DEFAULT 0 NOT NULL,
    executar_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    locked_at timestamp with time zone,
    locked_by character varying(120),
    processado_em timestamp with time zone,
    erro text,
    criado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: integracaoanotaaiinbox_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoanotaaiinbox_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoanotaaiinbox_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoanotaaiinbox_id_seq OWNED BY public.integracaoanotaaiinbox.id;


--
-- Name: integracaoanotaaimenusync; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoanotaaimenusync (
    id bigint NOT NULL,
    config_id bigint,
    id_empresa integer NOT NULL,
    merchant_id character varying(180) NOT NULL,
    entity_type character varying(60) NOT NULL,
    local_id character varying(180) NOT NULL,
    external_id character varying(220) NOT NULL,
    remote_id character varying(220),
    content_hash character(64),
    status character varying(30) DEFAULT 'PENDENTE'::character varying NOT NULL,
    ultima_tentativa_em timestamp with time zone,
    ultimo_sucesso_em timestamp with time zone,
    erro text,
    raw_response jsonb,
    atualizado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: integracaoanotaaimenusync_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoanotaaimenusync_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoanotaaimenusync_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoanotaaimenusync_id_seq OWNED BY public.integracaoanotaaimenusync.id;


--
-- Name: integracaoanotaaioutbox; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoanotaaioutbox (
    id bigint NOT NULL,
    config_id bigint,
    id_empresa integer NOT NULL,
    merchant_id character varying(180) NOT NULL,
    order_id character varying(180),
    operacao character varying(80) NOT NULL,
    metodo_http character varying(10),
    endpoint_path text,
    idempotency_key character varying(240) NOT NULL,
    payload jsonb,
    status character varying(30) DEFAULT 'PENDENTE'::character varying NOT NULL,
    tentativas integer DEFAULT 0 NOT NULL,
    executar_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    locked_at timestamp with time zone,
    locked_by character varying(120),
    http_status integer,
    resposta_payload jsonb,
    resposta_texto text,
    resultado_desconhecido boolean DEFAULT false NOT NULL,
    erro text,
    criado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    concluido_em timestamp with time zone
);


--
-- Name: integracaoanotaaioutbox_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoanotaaioutbox_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoanotaaioutbox_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoanotaaioutbox_id_seq OWNED BY public.integracaoanotaaioutbox.id;


--
-- Name: integracaoanotaaipedido; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoanotaaipedido (
    id bigint NOT NULL,
    config_id bigint,
    id_empresa integer NOT NULL,
    merchant_id character varying(180) NOT NULL,
    order_id character varying(180) NOT NULL,
    display_id character varying(120),
    status_externo character varying(120),
    status_local character varying(120),
    tipo_evento character varying(80),
    tipo_pedido character varying(80),
    tipo_entrega character varying(80),
    pedido_agendado boolean DEFAULT false NOT NULL,
    data_pedido timestamp with time zone,
    data_agendamento timestamp with time zone,
    cliente_id_externo character varying(180),
    cliente_nome character varying(255),
    cliente_celular character varying(60),
    cliente_cpf_cnpj character varying(40),
    cliente_email character varying(255),
    end_entrega_endereco character varying(255),
    end_entrega_numero character varying(300),
    end_entrega_complemento character varying(255),
    end_entrega_referencia character varying(255),
    end_entrega_bairro character varying(160),
    end_entrega_cidade character varying(160),
    end_entrega_uf character varying(20),
    end_entrega_cep character varying(20),
    subtotal numeric(15,4) DEFAULT 0 NOT NULL,
    total numeric(15,4) DEFAULT 0 NOT NULL,
    desconto numeric(15,4) DEFAULT 0 NOT NULL,
    acrescimo numeric(15,4) DEFAULT 0 NOT NULL,
    entrega_valor numeric(15,4) DEFAULT 0 NOT NULL,
    pago character varying(1) DEFAULT 'N'::character varying NOT NULL,
    pagto_metodo character varying(120),
    pagto_metodo_nome character varying(160),
    pagto_descricao text,
    pagto_troco numeric(15,4) DEFAULT 0 NOT NULL,
    observacao text,
    mapper_versao character varying(40) DEFAULT 'ANOTAAI_V1'::character varying NOT NULL,
    payload jsonb NOT NULL,
    pedido_importado boolean DEFAULT false NOT NULL,
    integrado_venda boolean DEFAULT false NOT NULL,
    id_venda_local bigint,
    recebido_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    atualizado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: integracaoanotaaipedido_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoanotaaipedido_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoanotaaipedido_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoanotaaipedido_id_seq OWNED BY public.integracaoanotaaipedido.id;


--
-- Name: integracaoanotaaipedidoitem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoanotaaipedidoitem (
    id bigint NOT NULL,
    pedido_id bigint NOT NULL,
    id_empresa integer NOT NULL,
    merchant_id character varying(180) NOT NULL,
    order_id character varying(180) NOT NULL,
    numero_item integer NOT NULL,
    item_id_externo character varying(180),
    product_code character varying(180),
    product_name character varying(255),
    quantidade numeric(15,4) DEFAULT 0 NOT NULL,
    valor_unitario numeric(15,4) DEFAULT 0 NOT NULL,
    valor_total numeric(15,4) DEFAULT 0 NOT NULL,
    desconto numeric(15,4) DEFAULT 0 NOT NULL,
    acrescimo numeric(15,4) DEFAULT 0 NOT NULL,
    observacao text,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: integracaoanotaaipedidoitem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoanotaaipedidoitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoanotaaipedidoitem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoanotaaipedidoitem_id_seq OWNED BY public.integracaoanotaaipedidoitem.id;


--
-- Name: integracaoanotaaipedidoopcional; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoanotaaipedidoopcional (
    id bigint NOT NULL,
    pedido_id bigint NOT NULL,
    pedido_item_id bigint,
    id_empresa integer NOT NULL,
    merchant_id character varying(180) NOT NULL,
    order_id character varying(180) NOT NULL,
    numero_item integer NOT NULL,
    numero_opcional integer NOT NULL,
    opcional_id_externo character varying(180),
    product_code character varying(180),
    product_name character varying(255),
    quantidade numeric(15,4) DEFAULT 0 NOT NULL,
    valor_unitario numeric(15,4) DEFAULT 0 NOT NULL,
    valor_total numeric(15,4) DEFAULT 0 NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: integracaoanotaaipedidoopcional_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoanotaaipedidoopcional_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoanotaaipedidoopcional_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoanotaaipedidoopcional_id_seq OWNED BY public.integracaoanotaaipedidoopcional.id;


--
-- Name: integracaoanotaaipedidostatus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoanotaaipedidostatus (
    id bigint NOT NULL,
    pedido_id bigint NOT NULL,
    id_empresa integer NOT NULL,
    merchant_id character varying(180) NOT NULL,
    order_id character varying(180) NOT NULL,
    status_externo character varying(120),
    status_local character varying(120),
    origem character varying(40) NOT NULL,
    ocorrido_em timestamp with time zone,
    criado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    payload jsonb
);


--
-- Name: integracaoanotaaipedidostatus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoanotaaipedidostatus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoanotaaipedidostatus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoanotaaipedidostatus_id_seq OWNED BY public.integracaoanotaaipedidostatus.id;


--
-- Name: integracaodeliverydiretocatalogomapa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaodeliverydiretocatalogomapa (
    id bigint NOT NULL,
    config_id bigint,
    id_empresa integer NOT NULL,
    delivery_direto_id character varying(180) CONSTRAINT integracaodeliverydiretocatalogomap_delivery_direto_id_not_null NOT NULL,
    entity_type character varying(60) NOT NULL,
    local_id character varying(180) NOT NULL,
    external_id character varying(220),
    custom_code character varying(220),
    content_hash character(64),
    status character varying(30) DEFAULT 'PENDENTE'::character varying NOT NULL,
    ultima_tentativa_em timestamp with time zone,
    ultimo_sucesso_em timestamp with time zone,
    erro text,
    raw_response jsonb,
    atualizado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: integracaodeliverydiretocatalogomapa_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaodeliverydiretocatalogomapa_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaodeliverydiretocatalogomapa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaodeliverydiretocatalogomapa_id_seq OWNED BY public.integracaodeliverydiretocatalogomapa.id;


--
-- Name: integracaodeliverydiretocheckpoint; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaodeliverydiretocheckpoint (
    id bigint NOT NULL,
    config_id bigint,
    id_empresa integer NOT NULL,
    delivery_direto_id character varying(180) NOT NULL,
    tipo character varying(60) NOT NULL,
    cursor_valor text,
    janela_inicio timestamp with time zone,
    janela_fim timestamp with time zone,
    ultimo_inicio_em timestamp with time zone,
    ultimo_sucesso_em timestamp with time zone,
    erro text,
    atualizado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: integracaodeliverydiretocheckpoint_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaodeliverydiretocheckpoint_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaodeliverydiretocheckpoint_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaodeliverydiretocheckpoint_id_seq OWNED BY public.integracaodeliverydiretocheckpoint.id;


--
-- Name: integracaodeliverydiretoconfig; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaodeliverydiretoconfig (
    id bigint NOT NULL,
    id_empresa integer NOT NULL,
    delivery_direto_id character varying(180) NOT NULL,
    nome_loja character varying(180),
    ambiente character varying(30) DEFAULT 'PRODUCAO'::character varying NOT NULL,
    ativo boolean DEFAULT false NOT NULL,
    contrato_versao character varying(60),
    contrato_validado boolean DEFAULT false NOT NULL,
    contrato_validado_em timestamp with time zone,
    base_url text DEFAULT 'https://deliverydireto.com.br'::text NOT NULL,
    admin_token_path character varying(120) DEFAULT '/admin-api/token'::character varying NOT NULL,
    store_token_path character varying(120) DEFAULT '/store-api/token'::character varying NOT NULL,
    admin_base_path character varying(120) DEFAULT '/admin-api/v1'::character varying NOT NULL,
    store_base_path character varying(120) DEFAULT '/store-api/v1'::character varying NOT NULL,
    client_id character varying(300),
    client_secret_ref character varying(300),
    admin_username_ref character varying(300),
    admin_password_ref character varying(300),
    store_username_ref character varying(300),
    store_password_ref character varying(300),
    webhook_url text,
    webhook_secret_ref character varying(300),
    admin_access_token_cipher bytea,
    admin_refresh_token_cipher bytea,
    admin_token_type character varying(40),
    admin_token_expires_at timestamp with time zone,
    admin_token_updated_at timestamp with time zone,
    store_access_token_cipher bytea,
    store_refresh_token_cipher bytea,
    store_token_type character varying(40),
    store_token_expires_at timestamp with time zone,
    store_token_updated_at timestamp with time zone,
    ultimo_polling_pedidos_em timestamp with time zone,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    criado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    atualizado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: TABLE integracaodeliverydiretoconfig; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.integracaodeliverydiretoconfig IS 'Configuracao Delivery Direto por empresa/loja. Nao gravar segredos em texto puro.';


--
-- Name: COLUMN integracaodeliverydiretoconfig.delivery_direto_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.integracaodeliverydiretoconfig.delivery_direto_id IS 'Valor do header X-DeliveryDireto-ID da loja.';


--
-- Name: COLUMN integracaodeliverydiretoconfig.client_secret_ref; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.integracaodeliverydiretoconfig.client_secret_ref IS 'Referencia segura para o CLIENT_SECRET fora do banco.';


--
-- Name: COLUMN integracaodeliverydiretoconfig.webhook_secret_ref; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.integracaodeliverydiretoconfig.webhook_secret_ref IS 'Referencia segura para o segredo usado na validacao HMAC do webhook.';


--
-- Name: integracaodeliverydiretoconfig_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaodeliverydiretoconfig_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaodeliverydiretoconfig_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaodeliverydiretoconfig_id_seq OWNED BY public.integracaodeliverydiretoconfig.id;


--
-- Name: integracaodeliverydiretohttplog; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaodeliverydiretohttplog (
    id bigint NOT NULL,
    config_id bigint,
    id_empresa integer NOT NULL,
    delivery_direto_id character varying(180),
    operacao character varying(80) NOT NULL,
    metodo_http character varying(10),
    url_sanitizada text,
    status_code integer,
    duracao_ms integer,
    request_hash character(64),
    response_hash character(64),
    erro text,
    criado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: integracaodeliverydiretohttplog_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaodeliverydiretohttplog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaodeliverydiretohttplog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaodeliverydiretohttplog_id_seq OWNED BY public.integracaodeliverydiretohttplog.id;


--
-- Name: integracaodeliverydiretooutbox; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaodeliverydiretooutbox (
    id bigint NOT NULL,
    config_id bigint,
    id_empresa integer NOT NULL,
    delivery_direto_id character varying(180) NOT NULL,
    order_id bigint,
    operacao character varying(80) NOT NULL,
    metodo_http character varying(10),
    endpoint_path text,
    idempotency_key character varying(240) NOT NULL,
    payload jsonb,
    status character varying(30) DEFAULT 'PENDENTE'::character varying NOT NULL,
    tentativas integer DEFAULT 0 NOT NULL,
    executar_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    locked_at timestamp with time zone,
    locked_by character varying(120),
    http_status integer,
    resposta_payload jsonb,
    resposta_texto text,
    resultado_desconhecido boolean DEFAULT false NOT NULL,
    erro text,
    criado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    concluido_em timestamp with time zone
);


--
-- Name: integracaodeliverydiretooutbox_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaodeliverydiretooutbox_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaodeliverydiretooutbox_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaodeliverydiretooutbox_id_seq OWNED BY public.integracaodeliverydiretooutbox.id;


--
-- Name: integracaodeliverydiretopedido; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaodeliverydiretopedido (
    id bigint NOT NULL,
    config_id bigint,
    id_empresa integer NOT NULL,
    delivery_direto_id character varying(180) NOT NULL,
    stores_id bigint,
    order_id bigint NOT NULL,
    display_id character varying(120),
    status_externo character varying(120),
    status_local character varying(120),
    tipo_evento character varying(80),
    tipo_pedido character varying(80),
    tipo_entrega character varying(80),
    pedido_agendado boolean DEFAULT false NOT NULL,
    data_pedido timestamp with time zone,
    data_agendamento timestamp with time zone,
    cliente_id_externo character varying(180),
    cliente_nome character varying(255),
    cliente_celular character varying(60),
    cliente_cpf_cnpj character varying(40),
    cliente_email character varying(255),
    end_entrega_endereco character varying(255),
    end_entrega_numero character varying(300),
    end_entrega_complemento character varying(255),
    end_entrega_referencia character varying(255),
    end_entrega_bairro character varying(160),
    end_entrega_cidade character varying(160),
    end_entrega_uf character varying(20),
    end_entrega_cep character varying(20),
    subtotal numeric(15,4) DEFAULT 0 NOT NULL,
    total numeric(15,4) DEFAULT 0 NOT NULL,
    desconto numeric(15,4) DEFAULT 0 NOT NULL,
    acrescimo numeric(15,4) DEFAULT 0 NOT NULL,
    entrega_valor numeric(15,4) DEFAULT 0 NOT NULL,
    pago character varying(1) DEFAULT 'N'::character varying NOT NULL,
    pagto_metodo character varying(120),
    pagto_metodo_nome character varying(160),
    pagto_descricao text,
    pagto_troco numeric(15,4) DEFAULT 0 NOT NULL,
    observacao text,
    mapper_versao character varying(40) DEFAULT 'DELIVERYDIRETO_V1'::character varying NOT NULL,
    payload jsonb NOT NULL,
    pedido_importado boolean DEFAULT false NOT NULL,
    integrado_venda boolean DEFAULT false NOT NULL,
    id_venda_local bigint,
    recebido_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    atualizado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: integracaodeliverydiretopedido_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaodeliverydiretopedido_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaodeliverydiretopedido_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaodeliverydiretopedido_id_seq OWNED BY public.integracaodeliverydiretopedido.id;


--
-- Name: integracaodeliverydiretopedidoitem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaodeliverydiretopedidoitem (
    id bigint NOT NULL,
    pedido_id bigint NOT NULL,
    id_empresa integer NOT NULL,
    delivery_direto_id character varying(180) NOT NULL,
    order_id bigint NOT NULL,
    numero_item integer NOT NULL,
    item_id_externo character varying(180),
    product_code character varying(180),
    product_name character varying(255),
    quantidade numeric(15,4) DEFAULT 0 NOT NULL,
    valor_unitario numeric(15,4) DEFAULT 0 NOT NULL,
    valor_total numeric(15,4) DEFAULT 0 NOT NULL,
    desconto numeric(15,4) DEFAULT 0 NOT NULL,
    acrescimo numeric(15,4) DEFAULT 0 NOT NULL,
    observacao text,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: integracaodeliverydiretopedidoitem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaodeliverydiretopedidoitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaodeliverydiretopedidoitem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaodeliverydiretopedidoitem_id_seq OWNED BY public.integracaodeliverydiretopedidoitem.id;


--
-- Name: integracaodeliverydiretopedidoopcional; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaodeliverydiretopedidoopcional (
    id bigint NOT NULL,
    pedido_id bigint NOT NULL,
    pedido_item_id bigint,
    id_empresa integer NOT NULL,
    delivery_direto_id character varying(180) CONSTRAINT integracaodeliverydiretopedidoopcio_delivery_direto_id_not_null NOT NULL,
    order_id bigint NOT NULL,
    numero_item integer NOT NULL,
    numero_opcional integer NOT NULL,
    opcional_id_externo character varying(180),
    product_code character varying(180),
    product_name character varying(255),
    quantidade numeric(15,4) DEFAULT 0 NOT NULL,
    valor_unitario numeric(15,4) DEFAULT 0 NOT NULL,
    valor_total numeric(15,4) DEFAULT 0 NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: integracaodeliverydiretopedidoopcional_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaodeliverydiretopedidoopcional_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaodeliverydiretopedidoopcional_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaodeliverydiretopedidoopcional_id_seq OWNED BY public.integracaodeliverydiretopedidoopcional.id;


--
-- Name: integracaodeliverydiretopedidostatus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaodeliverydiretopedidostatus (
    id bigint NOT NULL,
    pedido_id bigint,
    id_empresa integer NOT NULL,
    delivery_direto_id character varying(180) CONSTRAINT integracaodeliverydiretopedidostatu_delivery_direto_id_not_null NOT NULL,
    order_id bigint,
    status_externo character varying(120),
    status_local character varying(120),
    origem character varying(40) NOT NULL,
    ocorrido_em timestamp with time zone,
    criado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    payload jsonb
);


--
-- Name: integracaodeliverydiretopedidostatus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaodeliverydiretopedidostatus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaodeliverydiretopedidostatus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaodeliverydiretopedidostatus_id_seq OWNED BY public.integracaodeliverydiretopedidostatus.id;


--
-- Name: integracaodeliverydiretowebhookinbox; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaodeliverydiretowebhookinbox (
    id bigint NOT NULL,
    config_id bigint,
    id_empresa integer NOT NULL,
    delivery_direto_id character varying(180) CONSTRAINT integracaodeliverydiretowebhookinbo_delivery_direto_id_not_null NOT NULL,
    stores_id bigint,
    orders_id bigint,
    event_type character varying(80) NOT NULL,
    order_status character varying(80),
    payload_sha256 character(64) NOT NULL,
    signature_sha256 character(64),
    raw_body text NOT NULL,
    payload jsonb NOT NULL,
    status_processamento character varying(30) DEFAULT 'PENDENTE'::character varying CONSTRAINT integracaodeliverydiretowebhookin_status_processamento_not_null NOT NULL,
    tentativas integer DEFAULT 0 NOT NULL,
    executar_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    locked_at timestamp with time zone,
    locked_by character varying(120),
    processado_em timestamp with time zone,
    erro text,
    criado_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL
);


--
-- Name: integracaodeliverydiretowebhookinbox_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaodeliverydiretowebhookinbox_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaodeliverydiretowebhookinbox_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaodeliverydiretowebhookinbox_id_seq OWNED BY public.integracaodeliverydiretowebhookinbox.id;


--
-- Name: integracaoifoodconciliacao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoifoodconciliacao (
    id bigint NOT NULL,
    id_empresa integer NOT NULL,
    merchant_id character varying(60) NOT NULL,
    competencia character varying(7) NOT NULL,
    fato_gerador character varying(60),
    tipo_lancamento character varying(60),
    descricao_lancamento character varying(255),
    valor numeric(15,2) DEFAULT 0 NOT NULL,
    base_calculo numeric(15,2),
    percentual_taxa numeric(9,4),
    pedido_associado_ifood character varying(60),
    pedido_associado_curto character varying(30),
    motivo_cancelamento character varying(255),
    descricao_ocorrencia character varying(255),
    data_criacao_pedido timestamp without time zone,
    data_repasse_esperada date,
    valor_transacao numeric(15,2),
    loja_id character varying(60),
    loja_id_curto character varying(30),
    cnpj character varying(20),
    data_faturamento timestamp without time zone,
    data_apuracao_inicio date,
    data_apuracao_fim date,
    valor_cesta_final numeric(15,2),
    responsavel_transacao character varying(30),
    canal_vendas character varying(60),
    impacto_no_repasse boolean,
    parcela_pagamento character varying(30),
    pedido_detalhes character varying(255),
    id_saldo character varying(30),
    metodo_pagamento character varying(60),
    bandeira_pagamento character varying(60),
    criado_em timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: integracaoifoodconciliacao_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoifoodconciliacao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoifoodconciliacao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoifoodconciliacao_id_seq OWNED BY public.integracaoifoodconciliacao.id;


--
-- Name: integracaoifoodconciliacaoimport; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoifoodconciliacaoimport (
    id_empresa integer NOT NULL,
    merchant_id character varying(60) NOT NULL,
    competencia character varying(7) NOT NULL,
    request_id character varying(60),
    status character varying(30),
    total_linhas integer DEFAULT 0 NOT NULL,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp without time zone
);


--
-- Name: integracaoifoodfinanceiroantecipacao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoifoodfinanceiroantecipacao (
    id bigint NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    merchant_id character varying(120) NOT NULL,
    chave_antecipacao character varying(255) NOT NULL,
    anticipation_id character varying(120),
    status character varying(80),
    original_payment_date date,
    anticipated_payment_date date,
    original_payment_amount numeric(15,2) DEFAULT 0 CONSTRAINT integracaoifoodfinanceiroantec_original_payment_amount_not_null NOT NULL,
    anticipated_payment_amount numeric(15,2) DEFAULT 0 CONSTRAINT integracaoifoodfinanceiroan_anticipated_payment_amount_not_null NOT NULL,
    fee_amount numeric(15,2) DEFAULT 0 NOT NULL,
    fee_percentage numeric(15,4) DEFAULT 0 NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp without time zone
);


--
-- Name: integracaoifoodfinanceiroantecipacao_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoifoodfinanceiroantecipacao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoifoodfinanceiroantecipacao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoifoodfinanceiroantecipacao_id_seq OWNED BY public.integracaoifoodfinanceiroantecipacao.id;


--
-- Name: integracaoifoodfinanceiroclosingitem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoifoodfinanceiroclosingitem (
    id bigint NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    merchant_id character varying(120) NOT NULL,
    settlement_chave character varying(255) NOT NULL,
    chave_item character varying(255) NOT NULL,
    closing_item_id character varying(120),
    tipo character varying(80),
    produto character varying(120),
    amount numeric(15,2) DEFAULT 0 NOT NULL,
    status character varying(80),
    transaction_id character varying(120),
    payment_date date,
    bank_name character varying(120),
    bank_number character varying(30),
    branch_code character varying(30),
    account_number character varying(60),
    account_digit character varying(20),
    document_number character varying(40),
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp without time zone
);


--
-- Name: integracaoifoodfinanceiroclosingitem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoifoodfinanceiroclosingitem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoifoodfinanceiroclosingitem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoifoodfinanceiroclosingitem_id_seq OWNED BY public.integracaoifoodfinanceiroclosingitem.id;


--
-- Name: integracaoifoodfinanceiroevento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoifoodfinanceiroevento (
    id bigint NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    merchant_id character varying(120) NOT NULL,
    chave_evento character varying(255) NOT NULL,
    event_id character varying(120),
    order_id character varying(120),
    order_display_id character varying(80),
    competencia character varying(7),
    begin_date date,
    end_date date,
    event_date timestamp without time zone,
    payment_date date,
    event_type character varying(120),
    descricao character varying(255),
    amount numeric(15,2) DEFAULT 0 NOT NULL,
    has_transfer_impact boolean,
    settlement_id character varying(120),
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp without time zone
);


--
-- Name: integracaoifoodfinanceiroevento_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoifoodfinanceiroevento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoifoodfinanceiroevento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoifoodfinanceiroevento_id_seq OWNED BY public.integracaoifoodfinanceiroevento.id;


--
-- Name: integracaoifoodfinanceiroorigem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoifoodfinanceiroorigem (
    id bigint NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    merchant_id character varying(120) NOT NULL,
    settlement_chave character varying(255) NOT NULL,
    closing_item_chave character varying(255) NOT NULL,
    chave_origem character varying(255) NOT NULL,
    origin_id character varying(120),
    order_id character varying(120),
    order_display_id character varying(80),
    tipo character varying(120),
    descricao character varying(255),
    reference_date timestamp without time zone,
    amount numeric(15,2) DEFAULT 0 NOT NULL,
    valor_total_pedido numeric(15,2) DEFAULT 0 NOT NULL,
    valor_taxas numeric(15,2) DEFAULT 0 NOT NULL,
    valor_liquido numeric(15,2) DEFAULT 0 NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp without time zone
);


--
-- Name: integracaoifoodfinanceiroorigem_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoifoodfinanceiroorigem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoifoodfinanceiroorigem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoifoodfinanceiroorigem_id_seq OWNED BY public.integracaoifoodfinanceiroorigem.id;


--
-- Name: integracaoifoodfinanceiroreconciliacao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoifoodfinanceiroreconciliacao (
    id bigint NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    merchant_id character varying(120) NOT NULL,
    competencia character varying(7) NOT NULL,
    chave_reconciliacao character varying(255) CONSTRAINT integracaoifoodfinanceiroreconcili_chave_reconciliacao_not_null NOT NULL,
    status character varying(60),
    download_path text,
    total_linhas integer DEFAULT 0 NOT NULL,
    total_pedidos integer DEFAULT 0 NOT NULL,
    valor_bruto numeric(15,2) DEFAULT 0 NOT NULL,
    valor_taxas numeric(15,2) DEFAULT 0 NOT NULL,
    valor_liquido numeric(15,2) DEFAULT 0 NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp without time zone
);


--
-- Name: integracaoifoodfinanceiroreconciliacao_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoifoodfinanceiroreconciliacao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoifoodfinanceiroreconciliacao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoifoodfinanceiroreconciliacao_id_seq OWNED BY public.integracaoifoodfinanceiroreconciliacao.id;


--
-- Name: integracaoifoodfinanceiroreconciliacaolinha; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoifoodfinanceiroreconciliacaolinha (
    id bigint NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    merchant_id character varying(120) CONSTRAINT integracaoifoodfinanceiroreconciliacaolinh_merchant_id_not_null NOT NULL,
    reconciliacao_chave character varying(255) CONSTRAINT integracaoifoodfinanceiroreconcili_reconciliacao_chave_not_null NOT NULL,
    chave_linha character varying(255) CONSTRAINT integracaoifoodfinanceiroreconciliacaolinh_chave_linha_not_null NOT NULL,
    competencia character varying(7),
    order_id character varying(120),
    order_display_id character varying(80),
    data_pedido timestamp without time zone,
    data_repasse date,
    tipo_lancamento character varying(120),
    descricao character varying(255),
    impacto_no_repasse boolean,
    valor_bruto numeric(15,2) DEFAULT 0 CONSTRAINT integracaoifoodfinanceiroreconciliacaolinh_valor_bruto_not_null NOT NULL,
    valor_taxas numeric(15,2) DEFAULT 0 CONSTRAINT integracaoifoodfinanceiroreconciliacaolinh_valor_taxas_not_null NOT NULL,
    valor_liquido numeric(15,2) DEFAULT 0 CONSTRAINT integracaoifoodfinanceiroreconciliacaoli_valor_liquido_not_null NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp without time zone
);


--
-- Name: integracaoifoodfinanceiroreconciliacaolinha_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoifoodfinanceiroreconciliacaolinha_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoifoodfinanceiroreconciliacaolinha_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoifoodfinanceiroreconciliacaolinha_id_seq OWNED BY public.integracaoifoodfinanceiroreconciliacaolinha.id;


--
-- Name: integracaoifoodfinanceirosettlement; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoifoodfinanceirosettlement (
    id bigint NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    merchant_id character varying(120) NOT NULL,
    chave_financeira character varying(255) NOT NULL,
    consulta_inicio date,
    consulta_fim date,
    begin_date date,
    end_date date,
    balance numeric(15,2) DEFAULT 0 NOT NULL,
    settlement_id character varying(120),
    tipo character varying(80),
    produto character varying(120),
    amount numeric(15,2) DEFAULT 0 NOT NULL,
    status character varying(80),
    transaction_id character varying(120),
    payment_date date,
    start_date_calculation date,
    end_date_calculation date,
    bank_name character varying(120),
    bank_number character varying(30),
    branch_code character varying(30),
    account_number character varying(60),
    account_digit character varying(20),
    document_number character varying(40),
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp without time zone
);


--
-- Name: integracaoifoodfinanceirosettlement_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoifoodfinanceirosettlement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoifoodfinanceirosettlement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoifoodfinanceirosettlement_id_seq OWNED BY public.integracaoifoodfinanceirosettlement.id;


--
-- Name: integracaoifoodfinanceirovenda; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaoifoodfinanceirovenda (
    id bigint NOT NULL,
    id_empresa integer DEFAULT 1 NOT NULL,
    merchant_id character varying(120) NOT NULL,
    sale_id character varying(120) NOT NULL,
    short_id character varying(80),
    created_at timestamp without time zone,
    current_status character varying(80),
    sales_channel character varying(80),
    sale_gross_bag numeric(15,2) DEFAULT 0 NOT NULL,
    sale_gross_delivery_fee numeric(15,2) DEFAULT 0 NOT NULL,
    sale_gross_service_fee numeric(15,2) DEFAULT 0 NOT NULL,
    sale_gross_total numeric(15,2) DEFAULT 0 NOT NULL,
    sale_balance numeric(15,2) DEFAULT 0 NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    criado_em timestamp without time zone DEFAULT now() NOT NULL,
    atualizado_em timestamp without time zone
);


--
-- Name: integracaoifoodfinanceirovenda_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaoifoodfinanceirovenda_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaoifoodfinanceirovenda_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaoifoodfinanceirovenda_id_seq OWNED BY public.integracaoifoodfinanceirovenda.id;


--
-- Name: integracaostonepagarme; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaostonepagarme (
    accountid character varying(255) NOT NULL,
    cnpj character varying(14) NOT NULL,
    secretkey character varying(255),
    servicereferername character varying(255),
    deviceserialnumber character varying(50),
    accesstoken text,
    modointegracao character varying(20) DEFAULT 'core_v5'::character varying NOT NULL,
    hubenvironment character varying(10) DEFAULT 'live'::character varying NOT NULL,
    accesstokenexpiraem timestamp without time zone,
    refreshtoken text,
    hubauthorizationurl text,
    hubtokenurl text,
    hubclientid character varying(255),
    hubclientsecretref character varying(255),
    hubredirecturi text,
    hubscopes text,
    hubstate character varying(100),
    hubstateexpiraem timestamp without time zone,
    oauthatualizadoem timestamp without time zone,
    oauthmensagemerro text,
    apibaseurl text,
    hubpublicappkey text,
    webhookhubativo boolean DEFAULT false NOT NULL,
    webhookhubbaseurl text,
    webhookhubclienttoken text,
    webhookhubpendinglimit integer DEFAULT 10 NOT NULL,
    CONSTRAINT integracaostonepagarme_webhookhubpendinglimit_chk CHECK (((webhookhubpendinglimit >= 1) AND (webhookhubpendinglimit <= 50)))
);


--
-- Name: integracaostonepagarme_charge; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaostonepagarme_charge (
    id bigint NOT NULL,
    id_empresa integer NOT NULL,
    id_pedido bigint,
    id_venda integer,
    orderid character varying(100) NOT NULL,
    chargeid character varying(100) NOT NULL,
    transactionid character varying(100),
    valorcentavos integer NOT NULL,
    valorpagocentavos integer,
    status character varying(50),
    paymentmethod character varying(50),
    authorizationcode character varying(100),
    schemename character varying(50),
    installmentquantity integer,
    installmenttype character varying(30),
    paidat timestamp without time zone,
    payload text,
    criadoem timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    atualizadoem timestamp without time zone
);


--
-- Name: integracaostonepagarme_charge_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaostonepagarme_charge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaostonepagarme_charge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaostonepagarme_charge_id_seq OWNED BY public.integracaostonepagarme_charge.id;


--
-- Name: integracaostonepagarme_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaostonepagarme_log (
    id bigint NOT NULL,
    id_empresa integer,
    id_venda integer,
    id_formapgto integer,
    operacao character varying(50),
    orderid character varying(100),
    chargeid character varying(100),
    status character varying(50),
    statuscode integer,
    requisicao text,
    resposta text,
    mensagemerro text,
    criadoem timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL
);


--
-- Name: integracaostonepagarme_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaostonepagarme_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaostonepagarme_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaostonepagarme_log_id_seq OWNED BY public.integracaostonepagarme_log.id;


--
-- Name: integracaostonepagarme_pedido; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaostonepagarme_pedido (
    id bigint NOT NULL,
    id_empresa integer NOT NULL,
    id_venda integer NOT NULL,
    id_formapgto integer NOT NULL,
    orderid character varying(100),
    ordercode character varying(100),
    idempotencykey character varying(150) NOT NULL,
    valorcentavos integer NOT NULL,
    status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    closed boolean DEFAULT false NOT NULL,
    tipofluxo character varying(30) DEFAULT 'pedido_direto'::character varying NOT NULL,
    chargeid character varying(100),
    chargestatus character varying(50),
    statuscode integer,
    requisicao text,
    resposta text,
    mensagemerro text,
    criadoem timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    atualizadoem timestamp without time zone
);


--
-- Name: integracaostonepagarme_pedido_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaostonepagarme_pedido_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaostonepagarme_pedido_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaostonepagarme_pedido_id_seq OWNED BY public.integracaostonepagarme_pedido.id;


--
-- Name: integracaostonepagarme_webhook; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integracaostonepagarme_webhook (
    id bigint NOT NULL,
    id_empresa integer,
    webhookid character varying(100),
    eventtype character varying(80),
    orderid character varying(100),
    chargeid character varying(100),
    transactionid character varying(100),
    valorcentavos integer,
    valorpagocentavos integer,
    status character varying(50),
    payload text NOT NULL,
    processado boolean DEFAULT false NOT NULL,
    duplicado boolean DEFAULT false NOT NULL,
    erro text,
    criadoem timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    processadoem timestamp without time zone
);


--
-- Name: integracaostonepagarme_webhook_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integracaostonepagarme_webhook_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integracaostonepagarme_webhook_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integracaostonepagarme_webhook_id_seq OWNED BY public.integracaostonepagarme_webhook.id;


--
-- Name: justificativa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.justificativa (
    id_justificativa integer NOT NULL,
    id_empresa integer NOT NULL,
    id_situacao integer DEFAULT 4 NOT NULL,
    descricao character varying(200) NOT NULL
);


--
-- Name: justificativa_id_justificativa_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.justificativa_id_justificativa_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: justificativa_id_justificativa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.justificativa_id_justificativa_seq OWNED BY public.justificativa.id_justificativa;


--
-- Name: lista_acessos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lista_acessos (
    acs_001 integer NOT NULL,
    acs_002 integer NOT NULL,
    acs_003 character varying(40) NOT NULL,
    acs_004 numeric(1,0) DEFAULT 1 NOT NULL
);


--
-- Name: lista_servicos_iss; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lista_servicos_iss (
    codigo character varying(5) NOT NULL,
    descricao character varying(200) NOT NULL
);


--
-- Name: log_backup; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_backup (
    id integer NOT NULL,
    data timestamp without time zone,
    tamanho_arquivo character varying(100),
    tempo_backup character varying(100),
    caminho_backup character varying(255),
    data_abreviada date
);


--
-- Name: log_backup_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.log_backup_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_backup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.log_backup_id_seq OWNED BY public.log_backup.id;


--
-- Name: log_erro; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_erro (
    id integer NOT NULL,
    tabela_banco_dados character varying(100),
    data timestamp without time zone,
    mensagem_erro character varying(255),
    observacao character varying(255)
);


--
-- Name: log_erro_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.log_erro_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_erro_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.log_erro_id_seq OWNED BY public.log_erro.id;


--
-- Name: log_manifesto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_manifesto (
    codigo_erro integer,
    data timestamp without time zone,
    id integer NOT NULL,
    cnpj character varying(100)
);


--
-- Name: log_manifesto_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.log_manifesto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_manifesto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.log_manifesto_id_seq OWNED BY public.log_manifesto.id;


--
-- Name: log_transf_mesa_comanda; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_transf_mesa_comanda (
    id integer NOT NULL,
    id_empresa integer NOT NULL,
    data timestamp without time zone,
    id_usuario integer NOT NULL,
    id_venda_origem integer NOT NULL,
    tipo_origem character(1) NOT NULL,
    numero_origem integer NOT NULL,
    id_venda_destino integer NOT NULL,
    tipo_destino character(1) NOT NULL,
    numero_destino integer NOT NULL,
    id_material integer,
    rotina integer NOT NULL,
    observacao character varying(200) NOT NULL
);


--
-- Name: log_transf_mesa_comanda_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.log_transf_mesa_comanda_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_transf_mesa_comanda_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.log_transf_mesa_comanda_id_seq OWNED BY public.log_transf_mesa_comanda.id;


--
-- Name: log_versao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_versao (
    versao character varying(10),
    data_lancamento timestamp without time zone,
    data_atualizacao timestamp without time zone
);


--
-- Name: lotes_materiais; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lotes_materiais (
    id integer NOT NULL,
    id_material integer NOT NULL,
    id_empresa integer NOT NULL,
    quantidade numeric(15,3),
    data date NOT NULL,
    data_vencimento date NOT NULL,
    lote character varying(50) NOT NULL,
    id_usuario_lancamento integer NOT NULL,
    vendido boolean DEFAULT false NOT NULL,
    quantidade_baixada numeric(15,3) DEFAULT 0,
    quantidade_devolvida numeric(15,3) DEFAULT 0,
    quantidade_perda numeric(15,3) DEFAULT 0
);


--
-- Name: lotes_materiais_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lotes_materiais_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lotes_materiais_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lotes_materiais_id_seq OWNED BY public.lotes_materiais.id;


--
-- Name: manifestacao_fiscal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.manifestacao_fiscal (
    numero_nota_fiscal integer NOT NULL,
    data_emissao date,
    emitente character varying(200),
    chave_acesso character varying(100) NOT NULL,
    valor numeric(15,3) DEFAULT 0,
    nsu integer NOT NULL,
    situacao_nfe character varying(20),
    cnpj_destinatario character varying(100),
    baixada boolean DEFAULT false,
    serie integer NOT NULL,
    data_sincronizacao timestamp without time zone,
    id integer NOT NULL,
    tipo_nfe integer,
    ciencia_operacao integer DEFAULT 0 NOT NULL,
    cnpj_emp_004 character varying(100)
);


--
-- Name: manifestacao_fiscal_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.manifestacao_fiscal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: manifestacao_fiscal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.manifestacao_fiscal_id_seq OWNED BY public.manifestacao_fiscal.id;


--
-- Name: materiais; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materiais (
    mat_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    mat_003 character varying(100) NOT NULL,
    mat_004 character varying(50),
    uni_001 integer NOT NULL,
    mat_008 numeric(15,2) DEFAULT 0 NOT NULL,
    sit_001 integer DEFAULT 4 NOT NULL,
    usu_001_1 integer,
    usu_001_2 integer,
    usu_001_3 integer,
    dat_001_1 timestamp without time zone,
    dat_001_2 timestamp without time zone,
    dat_001_3 timestamp without time zone,
    mat_006 numeric(15,4),
    mat_012 numeric(15,4),
    mat_014 numeric(15,2),
    mat_015 numeric(15,2),
    gar_001 integer,
    cat_001 integer,
    mat_018 numeric(15,2),
    mat_020 numeric(10,2),
    mat_021 integer,
    orm_codigo integer,
    cfop_consumidor character varying(4),
    cfop_revendedor character varying(4),
    icms numeric(15,2),
    iva numeric(15,2),
    redbasecalcst numeric(15,2),
    redbasecalcicms numeric(15,2),
    cst_consumidor integer,
    cst_revendedor integer,
    ipi numeric(15,2),
    pis_codigo integer,
    pis numeric(15,2),
    cofins numeric(15,2),
    pis_codigo_entrada integer,
    pis_codigo_saida integer,
    cof_codigo_entrada integer,
    cof_codigo_saida integer,
    ncm character varying(10),
    cso_codigo integer,
    mat_aliqmunicipal numeric(15,2),
    mat_aliqestadual numeric(15,2),
    mat_aliqfederal numeric(15,2),
    tempo_producao integer DEFAULT 0,
    tipo_producao character varying(1) DEFAULT 'P'::character varying,
    valor_tam_p numeric(15,2) DEFAULT 0.00,
    valor_tam_m numeric(15,2) DEFAULT 0.00,
    valor_tam_g numeric(15,2) DEFAULT 0.00,
    valor_tam_gg numeric(15,2) DEFAULT 0.00,
    b_venda_tamanho boolean DEFAULT false,
    tamanho_padrao character varying(2) DEFAULT 'M'::character varying,
    valor_tam_extra numeric(15,2) DEFAULT 0.00,
    b_peso_balanca boolean DEFAULT false NOT NULL,
    b_exporta_peso_balanca boolean DEFAULT false NOT NULL,
    cest character varying(7),
    b_exige_alterar_preco_venda boolean DEFAULT false NOT NULL,
    dias_validade integer,
    tara_balanca numeric(10,3) DEFAULT 0.0,
    codigo_anp character varying(20),
    id_fornecedor integer,
    cfop_venda_outra_uf character varying(4),
    cfop_devolucao character varying(4),
    cfop_devolucao_outra_uf character varying(4),
    cfop_garantia character varying(4),
    cfop_garantia_outra_uf character varying(4),
    id_setor integer NOT NULL,
    valor_tabela2 numeric(15,2),
    hh_ativar boolean DEFAULT false NOT NULL,
    hh_dia_seg boolean DEFAULT false NOT NULL,
    hh_dia_ter boolean DEFAULT false NOT NULL,
    hh_dia_qua boolean DEFAULT false NOT NULL,
    hh_dia_qui boolean DEFAULT false NOT NULL,
    hh_dia_sex boolean DEFAULT false NOT NULL,
    hh_dia_sab boolean DEFAULT false NOT NULL,
    hh_dia_dom boolean DEFAULT false NOT NULL,
    hh_tipo_mesa boolean DEFAULT false NOT NULL,
    hh_tipo_delivery boolean DEFAULT false NOT NULL,
    hh_tipo_comanda boolean DEFAULT false NOT NULL,
    hh_tipo_balcao boolean DEFAULT false NOT NULL,
    hh_tipo_pdv boolean DEFAULT false NOT NULL,
    hh_inicial time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    hh_final time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    hh_valor numeric(15,2) DEFAULT 0 NOT NULL,
    valor_atacado numeric(15,2) DEFAULT 0 NOT NULL,
    utiliza_combo boolean DEFAULT false,
    tar_001 integer,
    nao_relevante boolean DEFAULT false NOT NULL,
    cnpj_fabricante character varying(14),
    peso_partida_anp numeric(15,3) DEFAULT 0.000,
    sub_001 integer,
    b_proximogratis boolean DEFAULT false NOT NULL,
    qtdeproximogratis integer DEFAULT 1 NOT NULL,
    b_servico boolean DEFAULT false NOT NULL,
    iss numeric(15,2) DEFAULT 0.00 NOT NULL,
    iss_exigibilidade integer,
    iss_incentivo integer,
    iss_servico character varying(5),
    b_restricao boolean DEFAULT false NOT NULL,
    nao_dia_seg boolean DEFAULT false NOT NULL,
    nao_dia_ter boolean DEFAULT false NOT NULL,
    nao_dia_qua boolean DEFAULT false NOT NULL,
    nao_dia_qui boolean DEFAULT false NOT NULL,
    nao_dia_sex boolean DEFAULT false NOT NULL,
    nao_dia_sab boolean DEFAULT false NOT NULL,
    nao_dia_dom boolean DEFAULT false NOT NULL,
    b_balanca_inteligente boolean DEFAULT false NOT NULL,
    b_venda_mobile boolean DEFAULT true,
    preco4 numeric(15,2) DEFAULT 0.0 NOT NULL,
    preco5 numeric(15,2) DEFAULT 0.0 NOT NULL,
    preco6 numeric(15,2) DEFAULT 0.0 NOT NULL,
    preco7 numeric(15,2) DEFAULT 0.0 NOT NULL,
    b_ficha_individual boolean DEFAULT false NOT NULL,
    b_gerarfidelidade boolean DEFAULT false NOT NULL,
    b_resgatefidelidade boolean DEFAULT false NOT NULL,
    qtdepontosgerar integer DEFAULT 1 NOT NULL,
    qtdepontosresgate integer DEFAULT 1 NOT NULL,
    b_permite_frac boolean DEFAULT true NOT NULL,
    tamanho_p character varying(100),
    tamanho_m character varying(100),
    tamanho_g character varying(100),
    tamanho_gg character varying(100),
    tamanho_extra character varying(100),
    peso_bruto numeric(15,3) DEFAULT 0.000 NOT NULL,
    peso_liquido numeric(15,3) DEFAULT 0.000 NOT NULL,
    mat_022 integer,
    ifood_code integer,
    inf_001 integer,
    nut_001 integer,
    b_nao_taxa boolean DEFAULT false NOT NULL,
    opc_min integer DEFAULT 0 NOT NULL,
    opc_max integer DEFAULT 0 NOT NULL,
    b_carrossel boolean DEFAULT false NOT NULL,
    cat_carrossel integer,
    desc_sabor character varying(40),
    etapa1 character varying(40),
    etapa2 character varying(40),
    etapa3 character varying(40),
    etapa4 character varying(40),
    etapa5 character varying(40),
    etapa6 character varying(40),
    tit_etapa1 character varying(40),
    tit_etapa2 character varying(40),
    tit_etapa3 character varying(40),
    tit_etapa4 character varying(40),
    tit_etapa5 character varying(40),
    tit_etapa6 character varying(40),
    cor_etapa1 integer DEFAULT 536870911 NOT NULL,
    cor_etapa2 integer DEFAULT 536870911 NOT NULL,
    cor_etapa3 integer DEFAULT 536870911 NOT NULL,
    cor_etapa4 integer DEFAULT 536870911 NOT NULL,
    cor_etapa5 integer DEFAULT 536870911 NOT NULL,
    cor_etapa6 integer DEFAULT 536870911 NOT NULL,
    met_etapa1 integer,
    met_etapa2 integer,
    met_etapa3 integer,
    met_etapa4 integer,
    met_etapa5 integer,
    met_etapa6 integer,
    min_etapa1 integer DEFAULT 0 NOT NULL,
    min_etapa2 integer DEFAULT 0 NOT NULL,
    min_etapa3 integer DEFAULT 0 NOT NULL,
    min_etapa4 integer DEFAULT 0 NOT NULL,
    min_etapa5 integer DEFAULT 0 NOT NULL,
    min_etapa6 integer DEFAULT 0 NOT NULL,
    max_etapa1 integer DEFAULT 0 NOT NULL,
    max_etapa2 integer DEFAULT 0 NOT NULL,
    max_etapa3 integer DEFAULT 0 NOT NULL,
    max_etapa4 integer DEFAULT 0 NOT NULL,
    max_etapa5 integer DEFAULT 0 NOT NULL,
    max_etapa6 integer DEFAULT 0 NOT NULL,
    gen_codigo character varying(2),
    comissao numeric(15,2) DEFAULT 0 NOT NULL,
    info_tecnicas character varying(350),
    id_tributacao integer,
    imagem_db bytea,
    oferta_web boolean DEFAULT false NOT NULL,
    b_exibir_web boolean DEFAULT false NOT NULL,
    imagem_db_carrossel bytea,
    imagem_db_destaque bytea,
    adrem numeric(15,4) DEFAULT 0 NOT NULL,
    pglp numeric(15,4) DEFAULT 0 NOT NULL,
    pgnn numeric(15,4) DEFAULT 0 NOT NULL,
    pgni numeric(15,4) DEFAULT 0 NOT NULL,
    usaquantidadedecimal boolean DEFAULT false NOT NULL,
    cst_rt_nfe character varying(5) DEFAULT '000'::character varying,
    cst_rt_nfce character varying(5) DEFAULT '000'::character varying,
    cclasstrib_rt_nfe character varying(8) DEFAULT '000001'::character varying,
    cclasstrib_rt_nfce character varying(8) DEFAULT '000001'::character varying,
    rt_param_bc_vlprod boolean DEFAULT true,
    rt_param_bc_vlfrete boolean DEFAULT true,
    rt_param_bc_vlseg boolean DEFAULT true,
    rt_param_bc_vldesp boolean DEFAULT true,
    rt_param_bc_ii boolean DEFAULT true,
    rt_param_bc_is boolean DEFAULT true,
    rt_param_bc_desconto boolean DEFAULT true,
    rt_param_bc_pis boolean DEFAULT true,
    rt_param_bc_cofins boolean DEFAULT true,
    rt_param_bc_icms boolean DEFAULT true,
    rt_param_bc_icmsdest boolean DEFAULT true,
    rt_param_bc_fcp boolean DEFAULT true,
    rt_param_bc_fcpdest boolean DEFAULT true,
    rt_param_bc_icmsmono boolean DEFAULT true,
    rt_param_bc_issqn boolean DEFAULT true,
    api_ctrib_pendente boolean DEFAULT false NOT NULL,
    cbenef character varying(10),
    tipo_item_sped character(2) DEFAULT '00'::bpchar NOT NULL,
    ultimo_ajuste_inv_fiscal date,
    usu_ajuste_inv_fiscal integer,
    aliqpisredbenef numeric(15,3) DEFAULT '0'::numeric NOT NULL,
    aliqcofinsredbenef numeric(15,3) DEFAULT '0'::numeric NOT NULL,
    infadfisco character varying(200)
);


--
-- Name: materiais_combo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materiais_combo (
    id_material integer NOT NULL,
    id_empresa integer NOT NULL,
    id_produto_combo integer NOT NULL,
    quantidade numeric(15,2) DEFAULT 1 NOT NULL,
    preco_venda numeric(15,2) DEFAULT 0 NOT NULL,
    preco_custo numeric(15,2) DEFAULT 0 NOT NULL
);


--
-- Name: materiais_composicao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materiais_composicao (
    id_material integer NOT NULL,
    id_empresa integer NOT NULL,
    quantidade numeric(15,3) DEFAULT 1.000 NOT NULL,
    id_composicao integer NOT NULL
);


--
-- Name: materiais_fornecedor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materiais_fornecedor (
    id_material integer NOT NULL,
    id_empresa integer NOT NULL,
    id_fornecedor integer NOT NULL,
    codigo_fornecedor character varying(50) NOT NULL
);


--
-- Name: materiais_lista_fornecedores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materiais_lista_fornecedores (
    id_material integer NOT NULL,
    id_empresa integer NOT NULL,
    id_fornecedor integer NOT NULL,
    classificacao integer DEFAULT 0 NOT NULL,
    data_compra date,
    preco_compra numeric(15,3),
    numero_nota_fiscal integer,
    version_rec integer DEFAULT 0
);


--
-- Name: materiais_log_precos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materiais_log_precos (
    id integer NOT NULL,
    data timestamp without time zone NOT NULL,
    id_material integer NOT NULL,
    id_empresa integer NOT NULL,
    compra_ant numeric(15,4) DEFAULT 0 NOT NULL,
    compra_new numeric(15,4) DEFAULT 0 NOT NULL,
    venda_ant numeric(15,4) DEFAULT 0 NOT NULL,
    venda_new numeric(15,4) DEFAULT 0 NOT NULL,
    id_usuario integer DEFAULT 1 NOT NULL,
    tela integer DEFAULT 0 NOT NULL
);


--
-- Name: materiais_log_precos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.materiais_log_precos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: materiais_log_precos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.materiais_log_precos_id_seq OWNED BY public.materiais_log_precos.id;


--
-- Name: materiais_opcional; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.materiais_opcional (
    id_material integer NOT NULL,
    id_empresa integer NOT NULL,
    id_opcional integer NOT NULL,
    id_categoria_opc integer
);


--
-- Name: mensagem_wattsap; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mensagem_wattsap (
    id_mensagem bigint NOT NULL,
    id_empresa integer NOT NULL,
    instancia character varying(120) NOT NULL,
    message_id character varying(255) NOT NULL,
    remote_jid character varying(255) NOT NULL,
    telefone character varying(20) NOT NULL,
    nome_contato character varying(150),
    texto text NOT NULL,
    tipo character varying(60),
    message_timestamp bigint NOT NULL,
    status character varying(20) DEFAULT 'PENDENTE'::character varying NOT NULL,
    intencao character varying(40),
    termo_busca character varying(200),
    resposta text,
    tentativas integer DEFAULT 0 NOT NULL,
    erro text,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    recebido_em timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    processado_em timestamp without time zone,
    respondido_em timestamp without time zone,
    atualizado_em timestamp without time zone,
    CONSTRAINT ck_mensagem_wattsap_status CHECK (((status)::text = ANY (ARRAY[('PENDENTE'::character varying)::text, ('PROCESSANDO'::character varying)::text, ('RESPONDIDA'::character varying)::text, ('IGNORADA'::character varying)::text, ('ERRO'::character varying)::text]))),
    CONSTRAINT ck_mensagem_wattsap_tentativas CHECK ((tentativas >= 0))
);


--
-- Name: mensagem_wattsap_id_mensagem_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mensagem_wattsap_id_mensagem_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mensagem_wattsap_id_mensagem_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mensagem_wattsap_id_mensagem_seq OWNED BY public.mensagem_wattsap.id_mensagem;


--
-- Name: mesa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mesa (
    mes_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    mes_002 character varying(40) NOT NULL,
    mes_003 integer NOT NULL,
    sit_001 integer DEFAULT 4 NOT NULL,
    usu_001_1 integer,
    usu_001_2 integer,
    usu_001_3 integer,
    dat_001_1 timestamp without time zone,
    dat_001_2 timestamp without time zone,
    dat_001_3 timestamp without time zone,
    nome_reserva character varying(100),
    telefone_reserva character varying(20),
    data_reserva date,
    hora_reserva time without time zone
);


--
-- Name: migrations_info; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.migrations_info (
    sequence integer NOT NULL,
    version character varying(255),
    datetime timestamp without time zone,
    start_of_execution timestamp without time zone,
    end_of_execution timestamp without time zone,
    duration_of_execution integer
);


--
-- Name: modalidade_icms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modalidade_icms (
    emp_001 integer NOT NULL,
    mod_codigo integer NOT NULL,
    mod_descricao character varying(255)
);


--
-- Name: modalidade_icmsst; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modalidade_icmsst (
    emp_001 integer NOT NULL,
    mst_codigo integer NOT NULL,
    mst_descricao character varying(255)
);


--
-- Name: movimento_estoque_composicao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movimento_estoque_composicao (
    id_empresa integer NOT NULL,
    id_composicao integer NOT NULL,
    id_venda integer,
    id_movimento_composicao integer NOT NULL,
    quantidade numeric(15,3) DEFAULT 1 NOT NULL,
    tipo_movimento character(1) NOT NULL,
    id_usuario integer NOT NULL,
    observacao bytea,
    id_vendaitem integer,
    data timestamp without time zone NOT NULL,
    valor_custo numeric(10,2) DEFAULT 0.0,
    valor_venda numeric(10,2) DEFAULT 0.0,
    id_fornecedor integer,
    id_setor integer,
    id_setor_destino integer,
    quantidade_anterior numeric(15,3) DEFAULT '0'::numeric NOT NULL,
    movimento_fiscal boolean DEFAULT false NOT NULL,
    quantidade_anterior_fiscal numeric(15,3) DEFAULT '0'::numeric CONSTRAINT movimento_estoque_composica_quantidade_anterior_fiscal_not_null NOT NULL,
    movimento_fisico boolean DEFAULT true NOT NULL
);


--
-- Name: movimento_estoque_composicao_id_movimento_composicao_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.movimento_estoque_composicao_id_movimento_composicao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: movimento_estoque_composicao_id_movimento_composicao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.movimento_estoque_composicao_id_movimento_composicao_seq OWNED BY public.movimento_estoque_composicao.id_movimento_composicao;


--
-- Name: movimento_estoque_opcional; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movimento_estoque_opcional (
    id_empresa integer NOT NULL,
    id_opcional integer NOT NULL,
    id_venda integer,
    id_movimento_opcional integer NOT NULL,
    quantidade numeric(15,3) DEFAULT 0 NOT NULL,
    tipo_movimento character(1) NOT NULL,
    id_usuario integer NOT NULL,
    observacao bytea,
    id_vendaitem integer,
    data timestamp without time zone NOT NULL,
    valor_custo numeric(10,2) DEFAULT 0.0,
    valor_venda numeric(10,2) DEFAULT 0.0,
    id_fornecedor integer,
    id_setor integer,
    id_setor_destino integer,
    quantidade_anterior numeric(15,3) DEFAULT '0'::numeric
);


--
-- Name: movimento_estoque_opcional_id_movimento_opcional_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.movimento_estoque_opcional_id_movimento_opcional_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: movimento_estoque_opcional_id_movimento_opcional_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.movimento_estoque_opcional_id_movimento_opcional_seq OWNED BY public.movimento_estoque_opcional.id_movimento_opcional;


--
-- Name: movimentocontacliente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movimentocontacliente (
    id_empresa integer NOT NULL,
    id_cliente integer NOT NULL,
    id_movimento integer NOT NULL,
    id_usuario integer NOT NULL,
    data timestamp without time zone NOT NULL,
    tipo_movimento character(1) NOT NULL,
    valor numeric(15,2) NOT NULL,
    id_venda integer,
    observacao bytea,
    lancamento_manual boolean DEFAULT false NOT NULL,
    tipo character varying(1) DEFAULT 'C'::character varying NOT NULL,
    haver_atual numeric(15,2) DEFAULT 0.00 NOT NULL,
    b_haver_mov_caixa boolean DEFAULT false NOT NULL
);


--
-- Name: movimentocontacliente_id_movimento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.movimentocontacliente_id_movimento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: movimentocontacliente_id_movimento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.movimentocontacliente_id_movimento_seq OWNED BY public.movimentocontacliente.id_movimento;


--
-- Name: movimentocontacorrente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movimentocontacorrente (
    id_empresa integer NOT NULL,
    id_contacorrente integer NOT NULL,
    id_cpagar integer,
    id_creceber integer,
    id_movimento integer NOT NULL,
    valor numeric(15,2) NOT NULL,
    tipo_movimento character(1) NOT NULL,
    id_usuario integer NOT NULL,
    observacao bytea,
    data timestamp without time zone NOT NULL
);


--
-- Name: movimentocontacorrente_id_movimento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.movimentocontacorrente_id_movimento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: movimentocontacorrente_id_movimento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.movimentocontacorrente_id_movimento_seq OWNED BY public.movimentocontacorrente.id_movimento;


--
-- Name: movimentoestoque; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movimentoestoque (
    id_empresa integer NOT NULL,
    id_material integer NOT NULL,
    id_venda integer,
    id_movimento integer NOT NULL,
    quantidade numeric(15,3) DEFAULT 1 NOT NULL,
    tipo_movimento character(1) NOT NULL,
    id_usuario integer NOT NULL,
    observacao bytea,
    id_vendaitem integer,
    data timestamp without time zone NOT NULL,
    valor_custo numeric(10,2) DEFAULT 0.0,
    valor_venda numeric(10,2) DEFAULT 0.0,
    id_fornecedor integer,
    id_setor integer,
    id_setor_destino integer,
    quantidade_anterior numeric(15,3) DEFAULT 0 NOT NULL,
    movimento_fiscal boolean DEFAULT false NOT NULL,
    quantidade_anterior_fiscal numeric(15,3) DEFAULT '0'::numeric NOT NULL,
    movimento_fisico boolean DEFAULT true NOT NULL
)
WITH (autovacuum_vacuum_scale_factor='0.02', autovacuum_analyze_scale_factor='0.02');


--
-- Name: movimentoestoque_id_movimento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.movimentoestoque_id_movimento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: movimentoestoque_id_movimento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.movimentoestoque_id_movimento_seq OWNED BY public.movimentoestoque.id_movimento;


--
-- Name: ncm_cest; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ncm_cest (
    ncm character varying(20),
    cest character varying(20)
);


--
-- Name: ncm_nbs_cclasstrib; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ncm_nbs_cclasstrib (
    ncm_nbs character varying(10) NOT NULL,
    regra_rtc character varying(50) NOT NULL,
    id_participante integer DEFAULT 0 NOT NULL,
    tipo character varying(5) NOT NULL,
    cclasstrib character varying(8) NOT NULL,
    anexo integer,
    artigo integer
);


--
-- Name: nfce_contingencia_erros; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nfce_contingencia_erros (
    id integer NOT NULL,
    id_empresa integer NOT NULL,
    data timestamp without time zone,
    numero_nfce integer NOT NULL,
    serie_nfce integer NOT NULL,
    id_venda integer NOT NULL,
    id_material integer,
    id_usuario integer NOT NULL,
    tipo_erro character varying(20) NOT NULL,
    mensagem_erro text
);


--
-- Name: nfce_contingencia_erros_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nfce_contingencia_erros_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nfce_contingencia_erros_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nfce_contingencia_erros_id_seq OWNED BY public.nfce_contingencia_erros.id;


--
-- Name: nfce_inutilizada; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nfce_inutilizada (
    numero integer NOT NULL,
    serie integer NOT NULL,
    modelo integer NOT NULL,
    id_empresa integer NOT NULL,
    data timestamp without time zone,
    justificativa character varying(100) NOT NULL
);


--
-- Name: nota_entrada; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nota_entrada (
    id_nota_entrada integer NOT NULL,
    id_empresa integer NOT NULL,
    id_fornecedor integer NOT NULL,
    id_usuario integer NOT NULL,
    id_situacao integer DEFAULT 0 NOT NULL,
    numero integer NOT NULL,
    data_emissao date,
    data_entrada date,
    cfop character varying(4),
    serie integer DEFAULT 1,
    valor_icms numeric(10,2) DEFAULT 0,
    valor_base_icms numeric(10,2) DEFAULT 0,
    valor_icms_sub numeric(10,2) DEFAULT 0,
    valor_base_icms_sub numeric(10,2) DEFAULT 0,
    valor_frete numeric(10,2) DEFAULT 0,
    valor_seguro numeric(10,2) DEFAULT 0,
    valor_ipi numeric(10,2) DEFAULT 0,
    valor_despesas numeric(10,2) DEFAULT 0,
    valor_desconto numeric(10,2) DEFAULT 0,
    valor_total numeric(10,2) DEFAULT 0,
    valor_produtos numeric(10,2) DEFAULT 0,
    valor_icms_retido numeric(10,2) DEFAULT 0,
    valor_pis numeric(10,2) DEFAULT 0,
    valor_cofins numeric(10,2) DEFAULT 0,
    chave_autorizacao character varying(100),
    info_complementar text,
    numero_fatura character varying(50),
    tipo_pagamento integer DEFAULT 0 NOT NULL,
    id_transportador integer,
    transp_numero_volumes character varying(50),
    transp_quantidade_volumes integer DEFAULT 1,
    transp_especie character varying(50),
    transp_marca character varying(50),
    transp_peso_liquido numeric(15,3),
    transp_peso_bruto numeric(15,3),
    transp_modalidade integer DEFAULT 1 NOT NULL,
    transp_placa_numero character varying(8),
    transp_placa_uf character varying(2),
    transp_rntc character varying(20),
    id_conta_pagar integer,
    total_rt_vbcibscbs numeric(15,4) DEFAULT '0'::numeric,
    total_rt_vibsuf numeric(15,4) DEFAULT '0'::numeric,
    total_rt_vibsmun numeric(15,4) DEFAULT '0'::numeric,
    total_rt_vibs numeric(15,4) DEFAULT '0'::numeric,
    total_rt_vcbs numeric(15,4) DEFAULT '0'::numeric,
    total_rt_vnftot numeric(15,4) DEFAULT '0'::numeric,
    finalidade integer DEFAULT 0 NOT NULL
);


--
-- Name: nota_entrada_doc_referenciado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nota_entrada_doc_referenciado (
    id_nota_entrada integer NOT NULL,
    id_empresa integer NOT NULL,
    item integer NOT NULL,
    tipo_doc character varying(3) NOT NULL,
    chave_nfe character varying(100),
    numero_ecf integer,
    numero_cupom_ecf integer,
    id_situacao integer DEFAULT 4 NOT NULL
);


--
-- Name: nota_entrada_duplicata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nota_entrada_duplicata (
    id_nota_entrada integer NOT NULL,
    id_empresa integer NOT NULL,
    item integer NOT NULL,
    numero_duplicata character varying(50) NOT NULL,
    data_vencimento date NOT NULL,
    valor numeric(15,2) DEFAULT 0.0 NOT NULL,
    id_situacao integer DEFAULT 4 NOT NULL
);


--
-- Name: nota_entrada_id_nota_entrada_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nota_entrada_id_nota_entrada_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nota_entrada_id_nota_entrada_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nota_entrada_id_nota_entrada_seq OWNED BY public.nota_entrada.id_nota_entrada;


--
-- Name: nota_entrada_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nota_entrada_item (
    id_nota_entrada integer NOT NULL,
    id_empresa integer NOT NULL,
    item integer NOT NULL,
    id_material integer,
    codigo_fornecedor character varying(50),
    descricao_fornecedor character varying(200),
    codigo_ean character varying(20),
    cst integer,
    cfop character varying(4),
    quantidade numeric(10,3) DEFAULT 1 NOT NULL,
    peso_unitario_liquido numeric(10,3) DEFAULT 0 NOT NULL,
    peso_unitario_bruto numeric(10,3) DEFAULT 0 NOT NULL,
    valor_unitario numeric(10,2) DEFAULT 0 NOT NULL,
    valor_total numeric(10,2) DEFAULT 0 NOT NULL,
    valor_frete numeric(10,2) DEFAULT 0 NOT NULL,
    valor_seguro numeric(10,2) DEFAULT 0 NOT NULL,
    valor_despesas numeric(10,2) DEFAULT 0 NOT NULL,
    icms_aliq numeric(10,2) DEFAULT 0 NOT NULL,
    icms_aliq_reducao numeric(10,2) DEFAULT 0 NOT NULL,
    valor_base_icms numeric(10,2) DEFAULT 0 NOT NULL,
    valor_icms numeric(10,2) DEFAULT 0 NOT NULL,
    icms_aliq_sub numeric(10,2) DEFAULT 0 NOT NULL,
    valor_base_icms_sub numeric(10,2) DEFAULT 0 NOT NULL,
    valor_icms_sub numeric(10,2) DEFAULT 0 NOT NULL,
    valor_icms_isento numeric(10,2) DEFAULT 0 NOT NULL,
    valor_icms_nao_trib numeric(10,2) DEFAULT 0 NOT NULL,
    valor_desconto numeric(10,2) DEFAULT 0 NOT NULL,
    tipo_ipi integer DEFAULT 0 NOT NULL,
    ipi_aliq numeric(10,2) DEFAULT 0 NOT NULL,
    pis_aliq numeric(10,2) DEFAULT 0 NOT NULL,
    cofins_aliq numeric(10,2) DEFAULT 0 NOT NULL,
    valor_base_ipi numeric(10,2) DEFAULT 0 NOT NULL,
    valor_base_pis_cofins numeric(10,2) DEFAULT 0 NOT NULL,
    valor_ipi numeric(10,2) DEFAULT 0 NOT NULL,
    id_situacao integer NOT NULL,
    ncm character varying(10),
    valor_pis numeric(10,2) DEFAULT 0 NOT NULL,
    valor_cofins numeric(10,2) DEFAULT 0 NOT NULL,
    unidade character varying(6) NOT NULL,
    serial character varying(100),
    numeracao character varying(100),
    complemento_descricao character varying(200),
    cest character varying(7),
    csosn integer,
    cst_pis integer,
    cst_cofins integer,
    mvast numeric(15,2) DEFAULT 0,
    margem double precision,
    valor_venda double precision,
    tipo_item character varying(1) DEFAULT 'M'::character varying NOT NULL,
    id_composicao integer,
    quantidade_frac numeric(10,3) DEFAULT 0.000 NOT NULL,
    valor_unitario_frac numeric(10,2) DEFAULT 0.00 NOT NULL,
    classificacao integer,
    codigo_anp character varying(20),
    id_setor_entrada integer,
    cst_rt character varying(5),
    cclasstrib_rt character varying(8),
    rt_vbc numeric(15,4) DEFAULT '0'::numeric,
    rt_aliq_ibs_uf numeric(15,4) DEFAULT '0'::numeric,
    rt_aliq_ibs_mun numeric(15,4) DEFAULT '0'::numeric,
    rt_aliq_cbs numeric(15,4) DEFAULT '0'::numeric,
    rt_vibsuf numeric(15,4) DEFAULT '0'::numeric,
    rt_vibsmun numeric(15,4) DEFAULT '0'::numeric,
    rt_vibs numeric(15,4) DEFAULT '0'::numeric,
    rt_vcbs numeric(15,4) DEFAULT '0'::numeric,
    rt_vitem numeric(15,4) DEFAULT '0'::numeric
);


--
-- Name: nota_saida; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nota_saida (
    id_nota_saida integer NOT NULL,
    id_empresa integer NOT NULL,
    id_cliente integer NOT NULL,
    id_usuario integer NOT NULL,
    id_situacao integer DEFAULT 0 NOT NULL,
    numero integer NOT NULL,
    modelo_especie integer NOT NULL,
    data_emissao date,
    data_saida date,
    data_cancelamento date,
    cfop character varying(4),
    serie integer DEFAULT 1,
    valor_icms numeric(10,2) DEFAULT 0,
    valor_base_icms numeric(10,2) DEFAULT 0,
    valor_icms_sub numeric(10,2) DEFAULT 0,
    valor_base_icms_sub numeric(10,2) DEFAULT 0,
    valor_frete numeric(10,2) DEFAULT 0,
    valor_seguro numeric(10,2) DEFAULT 0,
    valor_ipi numeric(10,2) DEFAULT 0,
    valor_despesas numeric(10,2) DEFAULT 0,
    valor_desconto numeric(10,2) DEFAULT 0,
    valor_total numeric(10,2) DEFAULT 0,
    valor_produtos numeric(10,2) DEFAULT 0,
    valor_icms_retido numeric(10,2) DEFAULT 0,
    valor_pis numeric(10,2) DEFAULT 0,
    valor_cofins numeric(10,2) DEFAULT 0,
    chave_autorizacao character varying(100),
    chave_cancelamento character varying(100),
    chave_nf_devolvida character varying(100),
    finalidade integer DEFAULT 0 NOT NULL,
    info_complementar text,
    numero_fatura character varying(50),
    tipo_pagamento integer DEFAULT 0 NOT NULL,
    id_orcamento integer,
    carta_correcao text,
    carta_correcao_sequencial integer,
    id_transportador integer,
    transp_numero_volumes character varying(50),
    transp_quantidade_volumes integer DEFAULT 1,
    transp_especie character varying(50),
    transp_marca character varying(50),
    transp_peso_liquido numeric(15,3),
    transp_peso_bruto numeric(15,3),
    transp_modalidade integer DEFAULT 1 NOT NULL,
    transp_placa_numero character varying(8),
    transp_placa_uf character varying(2),
    transp_rntc character varying(20),
    indpres integer,
    baixou_estoque boolean DEFAULT false,
    valor_ipi_devol numeric(10,2) DEFAULT 0 NOT NULL,
    terminal character varying(100),
    id_exec_estoque integer,
    entrega_nomerazao character varying(60),
    entrega_cnpjcpf character varying(14),
    entrega_ie character varying(14),
    entrega_fone character varying(14),
    entrega_cod_municipio integer,
    entrega_cep character varying(8),
    entrega_endereco character varying(60),
    entrega_numero character varying(60),
    entrega_complemento character varying(60),
    entrega_bairro character varying(60),
    entrega_municipio character varying(60),
    entrega_uf character varying(2),
    xml_cfe text,
    total_rt_vbcibscbs numeric(15,4) DEFAULT '0'::numeric,
    total_rt_vibsuf numeric(15,4) DEFAULT '0'::numeric,
    total_rt_vibsmun numeric(15,4) DEFAULT '0'::numeric,
    total_rt_vibs numeric(15,4) DEFAULT '0'::numeric,
    total_rt_vcbs numeric(15,4) DEFAULT '0'::numeric,
    total_rt_vnftot numeric(15,4) DEFAULT '0'::numeric,
    infadfisco character varying(200),
    indfinal integer DEFAULT 1 NOT NULL,
    iddest integer,
    rt_tpnf_credito character varying(2),
    rt_tpnf_debito character varying(2)
);


--
-- Name: nota_saida_doc_referenciado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nota_saida_doc_referenciado (
    id_nota_saida integer NOT NULL,
    id_empresa integer NOT NULL,
    item integer NOT NULL,
    tipo_doc character varying(3) NOT NULL,
    chave_nfe character varying(100),
    numero_ecf integer,
    numero_cupom_ecf integer,
    id_situacao integer DEFAULT 4 NOT NULL
);


--
-- Name: nota_saida_duplicata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nota_saida_duplicata (
    id_nota_saida integer NOT NULL,
    id_empresa integer NOT NULL,
    item integer NOT NULL,
    numero_duplicata character varying(50) NOT NULL,
    data_vencimento date NOT NULL,
    valor numeric(15,2) DEFAULT 0.0 NOT NULL,
    id_situacao integer DEFAULT 4 NOT NULL
);


--
-- Name: nota_saida_id_nota_saida_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nota_saida_id_nota_saida_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nota_saida_id_nota_saida_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nota_saida_id_nota_saida_seq OWNED BY public.nota_saida.id_nota_saida;


--
-- Name: nota_saida_inutilizada; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nota_saida_inutilizada (
    numero integer NOT NULL,
    serie integer NOT NULL,
    modelo integer NOT NULL,
    id_empresa integer NOT NULL,
    data timestamp without time zone,
    justificativa character varying(100) NOT NULL
);


--
-- Name: nota_saida_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nota_saida_item (
    id_nota_saida integer NOT NULL,
    id_empresa integer NOT NULL,
    item integer NOT NULL,
    id_material integer NOT NULL,
    cst integer NOT NULL,
    cfop character varying(4),
    quantidade numeric(10,3) DEFAULT 1 NOT NULL,
    peso_unitario_liquido numeric(10,3) DEFAULT 0 NOT NULL,
    peso_unitario_bruto numeric(10,3) DEFAULT 0 NOT NULL,
    valor_unitario numeric(10,2) DEFAULT 0 NOT NULL,
    valor_total numeric(10,2) DEFAULT 0 NOT NULL,
    valor_frete numeric(10,2) DEFAULT 0 NOT NULL,
    valor_seguro numeric(10,2) DEFAULT 0 NOT NULL,
    valor_despesas numeric(10,2) DEFAULT 0 NOT NULL,
    b_icms_retido boolean DEFAULT false,
    icms_aliq numeric(10,2) DEFAULT 0 NOT NULL,
    icms_aliq_reducao numeric(10,2) DEFAULT 0 NOT NULL,
    valor_base_icms numeric(10,2) DEFAULT 0 NOT NULL,
    valor_icms numeric(10,2) DEFAULT 0 NOT NULL,
    icms_aliq_sub numeric(10,2) DEFAULT 0 NOT NULL,
    valor_base_icms_sub numeric(10,2) DEFAULT 0 NOT NULL,
    valor_icms_sub numeric(10,2) DEFAULT 0 NOT NULL,
    valor_icms_isento numeric(10,2) DEFAULT 0 NOT NULL,
    valor_icms_nao_trib numeric(10,2) DEFAULT 0 NOT NULL,
    valor_desconto numeric(10,2) DEFAULT 0 NOT NULL,
    tipo_ipi integer DEFAULT 0 NOT NULL,
    ipi_aliq numeric(10,2) DEFAULT 0 NOT NULL,
    pis_aliq numeric(10,2) DEFAULT 0 NOT NULL,
    cofins_aliq numeric(10,2) DEFAULT 0 NOT NULL,
    valor_base_ipi numeric(10,2) DEFAULT 0 NOT NULL,
    valor_base_pis_cofins numeric(10,2) DEFAULT 0 NOT NULL,
    valor_ipi numeric(10,2) DEFAULT 0 NOT NULL,
    id_situacao integer NOT NULL,
    ncm character varying(10) NOT NULL,
    valor_pis numeric(10,2) DEFAULT 0 NOT NULL,
    valor_cofins numeric(10,2) DEFAULT 0 NOT NULL,
    unidade character varying(6) NOT NULL,
    serial character varying(100),
    numeracao character varying(100),
    complemento_descricao character varying(200),
    cest character varying(7),
    csosn integer NOT NULL,
    cst_pis integer NOT NULL,
    cst_cofins integer NOT NULL,
    mvast numeric(15,2) DEFAULT 0 NOT NULL,
    codigo_anp character varying(20),
    efetuar_calculos boolean DEFAULT true NOT NULL,
    atribuir_despesas boolean DEFAULT true NOT NULL,
    valor_ipi_devol numeric(10,2) DEFAULT 0 NOT NULL,
    perc_ipi_devol numeric(10,2) DEFAULT 0 NOT NULL,
    cst_rt character varying(5),
    cclasstrib_rt character varying(8),
    rt_vbc numeric(15,4) DEFAULT '0'::numeric,
    rt_aliq_ibs_uf numeric(15,4) DEFAULT '0'::numeric,
    rt_aliq_ibs_mun numeric(15,4) DEFAULT '0'::numeric,
    rt_aliq_cbs numeric(15,4) DEFAULT '0'::numeric,
    rt_vibsuf numeric(15,4) DEFAULT '0'::numeric,
    rt_vibsmun numeric(15,4) DEFAULT '0'::numeric,
    rt_vibs numeric(15,4) DEFAULT '0'::numeric,
    rt_vcbs numeric(15,4) DEFAULT '0'::numeric,
    rt_vitem numeric(15,4) DEFAULT '0'::numeric,
    rt_param_bc_vlprod boolean DEFAULT true,
    rt_param_bc_vlfrete boolean DEFAULT true,
    rt_param_bc_vlseg boolean DEFAULT true,
    rt_param_bc_vldesp boolean DEFAULT true,
    rt_param_bc_ii boolean DEFAULT true,
    rt_param_bc_is boolean DEFAULT true,
    rt_param_bc_desconto boolean DEFAULT true,
    rt_param_bc_pis boolean DEFAULT true,
    rt_param_bc_cofins boolean DEFAULT true,
    rt_param_bc_icms boolean DEFAULT true,
    rt_param_bc_icmsdest boolean DEFAULT true,
    rt_param_bc_fcp boolean DEFAULT true,
    rt_param_bc_fcpdest boolean DEFAULT true,
    rt_param_bc_icmsmono boolean DEFAULT true,
    rt_param_bc_issqn boolean DEFAULT true,
    cbenef character varying(10),
    aliqpisredbenef numeric(15,3) DEFAULT '0'::numeric NOT NULL,
    aliqcofinsredbenef numeric(15,3) DEFAULT '0'::numeric NOT NULL,
    infadfisco character varying(200),
    chave_original_dev character varying(44),
    item_original_dev integer
);


--
-- Name: nota_saida_pagamentos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nota_saida_pagamentos (
    id_nota_saida integer NOT NULL,
    id_empresa integer NOT NULL,
    item integer NOT NULL,
    id_forma integer NOT NULL,
    valor numeric(15,2) DEFAULT 0.0 NOT NULL,
    autorizacao character varying(50)
);


--
-- Name: opcional; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.opcional (
    id_opcional integer NOT NULL,
    id_empresa integer NOT NULL,
    descricao character varying(100),
    valor numeric(15,2),
    id_situacao integer DEFAULT 4 NOT NULL,
    ifood_code integer,
    opc_p character varying(100),
    opc_m character varying(100),
    opc_g character varying(100),
    opc_gg character varying(100),
    opc_extra character varying(100),
    valor_opc_p numeric(15,2) DEFAULT 0.00,
    valor_opc_m numeric(15,2) DEFAULT 0.00,
    valor_opc_g numeric(15,2) DEFAULT 0.00,
    valor_opc_gg numeric(15,2) DEFAULT 0.00,
    valor_opc_extra numeric(15,2) DEFAULT 0.00,
    tipo integer DEFAULT 0 NOT NULL,
    imagem_db bytea,
    id_setor integer DEFAULT 1 NOT NULL,
    valor_custo numeric(10,2) DEFAULT '0'::numeric
);


--
-- Name: opcional_id_opcional_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.opcional_id_opcional_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: opcional_id_opcional_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.opcional_id_opcional_seq OWNED BY public.opcional.id_opcional;


--
-- Name: origem_mercadoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.origem_mercadoria (
    orm_codigo integer NOT NULL,
    orm_descricao character varying(255)
);


--
-- Name: paf_ecf; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.paf_ecf (
    cnpj_revenda character varying(20),
    cnpj_emitente character varying(20),
    coo character varying(10),
    terminal character varying(20),
    software character varying(2),
    versao_sistema character varying(10),
    rp_movel boolean DEFAULT false NOT NULL,
    rp_food boolean DEFAULT false NOT NULL,
    ifood boolean DEFAULT false NOT NULL,
    sped boolean DEFAULT false NOT NULL,
    conectado boolean DEFAULT false NOT NULL,
    assinatura_arquivos character varying(100) NOT NULL,
    status character varying(100) NOT NULL,
    rpmenu boolean DEFAULT false,
    rp_balanca_inteligente boolean DEFAULT false NOT NULL,
    rp_balanca_eletronica boolean DEFAULT false NOT NULL,
    nfe_saida boolean DEFAULT false NOT NULL,
    rp_movel_integracao_stone boolean DEFAULT false NOT NULL,
    rp_movel_integracao_cielo boolean DEFAULT false,
    rp_movel_integracao_pagbank boolean DEFAULT false,
    pedzap boolean DEFAULT false NOT NULL,
    querodelivery boolean DEFAULT false NOT NULL,
    consulta_tributaria boolean DEFAULT false NOT NULL,
    rpcheffcloud boolean DEFAULT false NOT NULL,
    utiliza_integracao99food boolean DEFAULT false NOT NULL,
    utiliza_rpcop boolean DEFAULT false,
    utiliza_rpmovelnfce boolean DEFAULT false,
    utiliza_anotaai boolean DEFAULT false,
    utiliza_cardapiotablet boolean DEFAULT false
);


--
-- Name: pagamentoonline; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pagamentoonline (
    id integer NOT NULL,
    idempresa integer NOT NULL,
    idvenda integer NOT NULL,
    idcliente integer,
    idautorizacaopagamento character varying(120),
    integracaopagamento character varying(50),
    urlqrcode character varying(155),
    valorpagamentoonline numeric(15,3),
    status character varying(50)
);


--
-- Name: pagamentoonline_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pagamentoonline_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pagamentoonline_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pagamentoonline_id_seq OWNED BY public.pagamentoonline.id;


--
-- Name: paises; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.paises (
    pai_001 integer NOT NULL,
    pai_002 character varying(40) NOT NULL
);


--
-- Name: particip_ip; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.particip_ip (
    pip_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    pip_nome character varying(100) NOT NULL,
    pip_cnpj character varying(14),
    pip_cpf character varying(11),
    pip_endereco character varying(60),
    pip_numero character varying(10),
    pip_complemento character varying(60),
    pip_bairro character varying(60),
    pip_cod_municipio character varying(7),
    sit_001 integer DEFAULT 4 NOT NULL
);


--
-- Name: pedido_compra; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pedido_compra (
    id integer NOT NULL,
    id_empresa integer NOT NULL,
    id_usuario integer NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    data_entrada date,
    hora_entrada time without time zone,
    numero character varying(20) NOT NULL,
    id_fornecedor integer NOT NULL,
    subtotal numeric(10,2) DEFAULT 0.00 NOT NULL,
    acrescimo numeric(10,2) DEFAULT 0.00 NOT NULL,
    desconto numeric(10,2) DEFAULT 0.00 NOT NULL,
    frete numeric(10,2) DEFAULT 0.00 NOT NULL,
    valor numeric(10,2) DEFAULT 0.00 NOT NULL
);


--
-- Name: pedido_compra_duplicata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pedido_compra_duplicata (
    id_pedido integer NOT NULL,
    id_empresa integer NOT NULL,
    item integer NOT NULL,
    numero_duplicata character varying(50) NOT NULL,
    data_vencimento date NOT NULL,
    valor numeric(15,2) DEFAULT 0.0 NOT NULL,
    id_situacao integer DEFAULT 4 NOT NULL
);


--
-- Name: pedido_compra_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pedido_compra_item (
    id_pedido integer NOT NULL,
    item integer NOT NULL,
    id_empresa integer NOT NULL,
    id_material integer NOT NULL,
    quantidade numeric(15,3) DEFAULT 1.0 NOT NULL,
    valor_unitario numeric(15,3) DEFAULT 0.0 NOT NULL,
    valor_total numeric(15,3) DEFAULT 0.0 NOT NULL,
    custo_atual numeric(15,3) DEFAULT 0 NOT NULL,
    margem_atual numeric(15,3) DEFAULT 0 NOT NULL,
    margem_nova numeric(15,3) DEFAULT 0 NOT NULL,
    venda_atual numeric(15,3) DEFAULT 0 NOT NULL,
    venda_novo numeric(15,3) DEFAULT 0 NOT NULL
);


--
-- Name: pedidoitensextras_pedzap; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pedidoitensextras_pedzap (
    id integer NOT NULL,
    price numeric(15,2) NOT NULL,
    quantity integer NOT NULL,
    product_name character varying(255) NOT NULL,
    product_code character varying(50),
    item_id integer NOT NULL,
    product_id integer
);


--
-- Name: pedidoitensextras_pedzap_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.pedidoitensextras_pedzap ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.pedidoitensextras_pedzap_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pedidos_pedzap; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pedidos_pedzap (
    id integer NOT NULL,
    cliente_id integer NOT NULL,
    cliente_nome character varying(255) NOT NULL,
    total numeric(15,2) NOT NULL,
    subtotal numeric(15,2) NOT NULL,
    entrega_valor numeric(15,2) NOT NULL,
    items_quantity integer NOT NULL,
    status integer NOT NULL,
    status_nome character varying(50) NOT NULL,
    pago character(1) NOT NULL,
    pagto_data timestamp without time zone,
    data timestamp without time zone,
    cadastro_celular character varying(20),
    cadastro_nome character varying(255),
    cadastro_cpf character varying(14),
    cadastro_email character varying(255),
    qrcode_id character varying(100),
    config_json jsonb,
    entrega_metodo character varying(50),
    entrega_servico character varying(20),
    entrega_agendam_data timestamp without time zone,
    entrega_agendam_periodo character varying(50),
    entrega_agendam_periodoid integer,
    entrega_descricao character varying(100),
    entregador_id integer,
    entregador_nome character varying(255),
    promocao_id integer,
    promocao_codigo character varying(50),
    promocao_desconto numeric(15,2),
    entrega_desconto numeric(15,2),
    acrescimo_id integer,
    desconto numeric(15,2),
    acrescimo numeric(15,2),
    imposto numeric(15,2),
    wishlist_id integer,
    entrega_prazo_unidade character varying(20),
    entrega_prazo_qtde integer,
    items_desconto numeric(15,2),
    observacao text,
    obs_cancelamento text,
    end_entrega_descricao character varying(255),
    end_entrega_endereco character varying(255),
    end_entrega_numero character varying(20),
    end_entrega_complemento character varying(100),
    end_entrega_referencia character varying(255),
    end_entrega_bairro character varying(255),
    end_entrega_bairro_custom character varying(255),
    end_entrega_cidade character varying(255),
    end_entrega_geolocation character varying(100),
    end_entrega_cep character varying(15),
    end_entrega_uf character(2),
    end_cobranca_endereco character varying(255),
    end_cobranca_numero character varying(20),
    end_cobranca_complemento character varying(100),
    end_cobranca_referencia character varying(255),
    end_cobranca_bairro character varying(255),
    end_cobranca_cidade character varying(255),
    end_cobranca_cep character varying(15),
    end_cobranca_uf character(2),
    pagto_status character varying(50),
    pagto_statusinfo text,
    pagto_metodo character varying(50),
    pagto_metodo_nome character varying(100),
    pagto_metododesc character varying(50),
    pagto_troco numeric(15,2),
    pagto_ref character varying(100),
    pagto_codigo character varying(100),
    pagto_descricao text,
    pagto_bandeira character varying(50),
    pagto_autorizacao character varying(100),
    pagto_valorautorizado numeric(15,2),
    cliente_ip character varying(28),
    pedido_importado boolean DEFAULT false
);


--
-- Name: pedidos_pedzap_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.pedidos_pedzap ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.pedidos_pedzap_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pedidositens_pedzap; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pedidositens_pedzap (
    id integer NOT NULL,
    order_id integer NOT NULL,
    product_id integer NOT NULL,
    quantity integer NOT NULL,
    price numeric(15,2) NOT NULL,
    description character varying(255) NOT NULL,
    product_name character varying(255) NOT NULL,
    product_code character varying(50),
    kit character(1),
    parent_id integer,
    wishlist_itemid integer,
    desconto numeric(15,2),
    weight numeric(15,2),
    altura numeric(15,2),
    comprimento numeric(15,2),
    largura numeric(15,2),
    prazo_entrega integer,
    prazo_unidade character varying(20),
    prazo_usa_quantidade character(1),
    baixado_estoque character(1),
    reservado_estoque character(1),
    complemento character varying(255),
    obs text,
    item_fracionado integer,
    numero_item integer
);


--
-- Name: pedidositens_pedzap_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.pedidositens_pedzap ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.pedidositens_pedzap_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: perfil_consumo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.perfil_consumo (
    id_perfil_consumo integer NOT NULL,
    id_empresa integer NOT NULL,
    descricao character varying(50) NOT NULL,
    valor_consumacao numeric(15,2) DEFAULT 0.0 NOT NULL,
    valor_entrada numeric(15,2) DEFAULT 0.0 NOT NULL,
    id_situacao integer DEFAULT 4 NOT NULL
);


--
-- Name: produtos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.produtos AS
 SELECT mat_001 AS codigo,
    emp_001 AS id_empresa,
    mat_003 AS descricao,
    cat_001 AS codigrupo,
    mat_008 AS valfinal,
    mat_004 AS observacao,
    imagem_db AS img,
    sit_001 AS id_situacao,
    COALESCE(b_exibir_web, false) AS b_venda_web,
    COALESCE(utiliza_combo, false) AS utiliza_combo,
    COALESCE(oferta_web, false) AS b_destaque_web,
    COALESCE(b_permite_frac, true) AS b_permite_frac,
    tamanho_p,
    tamanho_m,
    tamanho_g,
    tamanho_gg,
    tamanho_extra,
    COALESCE(tamanho_padrao, 'M'::character varying) AS tamanho_padrao,
    COALESCE(valor_tam_p, 0.00) AS valor_tam_p,
    COALESCE(valor_tam_m, 0.00) AS valor_tam_m,
    COALESCE(valor_tam_g, 0.00) AS valor_tam_g,
    COALESCE(valor_tam_gg, 0.00) AS valor_tam_gg,
    COALESCE(valor_tam_extra, 0.00) AS valor_tam_extra,
    COALESCE(b_venda_tamanho, false) AS b_venda_tamanho,
    COALESCE(b_carrossel, false) AS b_carrossel,
    false AS utiliza_promocao,
    COALESCE(b_exporta_peso_balanca, false) AS b_exporta_peso_balanca,
    COALESCE(b_peso_balanca, false) AS b_peso_balanca,
    COALESCE(hh_ativar, false) AS utiliza_happy_hour,
    COALESCE(b_restricao, false) AS restringirvenda,
    COALESCE(opc_min, 0) AS opcional_minimo,
    COALESCE(opc_max, 0) AS opcional_maximo
   FROM public.materiais;


--
-- Name: produtos_opcional; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.produtos_opcional AS
 SELECT id_empresa,
    id_material,
    id_opcional,
    NULL::integer AS id_setor,
    0.00::numeric(15,2) AS valor_custo,
    id_categoria_opc
   FROM public.materiais_opcional;


--
-- Name: promocao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.promocao (
    id_promocao integer NOT NULL,
    id_empresa integer NOT NULL,
    id_material integer NOT NULL,
    tipo_desconto integer DEFAULT 0 NOT NULL,
    dia_seg boolean DEFAULT false NOT NULL,
    dia_ter boolean DEFAULT false NOT NULL,
    dia_qua boolean DEFAULT false NOT NULL,
    dia_qui boolean DEFAULT false NOT NULL,
    dia_sex boolean DEFAULT false NOT NULL,
    dia_sab boolean DEFAULT false NOT NULL,
    dia_dom boolean DEFAULT false NOT NULL,
    tipo_mesa boolean DEFAULT false NOT NULL,
    tipo_delivery boolean DEFAULT false NOT NULL,
    tipo_comanda boolean DEFAULT false NOT NULL,
    tipo_balcao boolean DEFAULT false NOT NULL,
    tipo_pdv boolean DEFAULT false NOT NULL,
    desconto_seg_padrao numeric(15,2) DEFAULT 0,
    desconto_seg_tam_p numeric(15,2) DEFAULT 0,
    desconto_seg_tam_m numeric(15,2) DEFAULT 0,
    desconto_seg_tam_g numeric(15,2) DEFAULT 0,
    desconto_seg_tam_gg numeric(15,2) DEFAULT 0,
    desconto_seg_tam_extra numeric(15,2) DEFAULT 0,
    desconto_ter_padrao numeric(15,2) DEFAULT 0,
    desconto_ter_tam_p numeric(15,2) DEFAULT 0,
    desconto_ter_tam_m numeric(15,2) DEFAULT 0,
    desconto_ter_tam_g numeric(15,2) DEFAULT 0,
    desconto_ter_tam_gg numeric(15,2) DEFAULT 0,
    desconto_ter_tam_extra numeric(15,2) DEFAULT 0,
    desconto_qua_padrao numeric(15,2) DEFAULT 0,
    desconto_qua_tam_p numeric(15,2) DEFAULT 0,
    desconto_qua_tam_m numeric(15,2) DEFAULT 0,
    desconto_qua_tam_g numeric(15,2) DEFAULT 0,
    desconto_qua_tam_gg numeric(15,2) DEFAULT 0,
    desconto_qua_tam_extra numeric(15,2) DEFAULT 0,
    desconto_qui_padrao numeric(15,2) DEFAULT 0,
    desconto_qui_tam_p numeric(15,2) DEFAULT 0,
    desconto_qui_tam_m numeric(15,2) DEFAULT 0,
    desconto_qui_tam_g numeric(15,2) DEFAULT 0,
    desconto_qui_tam_gg numeric(15,2) DEFAULT 0,
    desconto_qui_tam_extra numeric(15,2) DEFAULT 0,
    desconto_sex_padrao numeric(15,2) DEFAULT 0,
    desconto_sex_tam_p numeric(15,2) DEFAULT 0,
    desconto_sex_tam_m numeric(15,2) DEFAULT 0,
    desconto_sex_tam_g numeric(15,2) DEFAULT 0,
    desconto_sex_tam_gg numeric(15,2) DEFAULT 0,
    desconto_sex_tam_extra numeric(15,2) DEFAULT 0,
    desconto_sab_padrao numeric(15,2) DEFAULT 0,
    desconto_sab_tam_p numeric(15,2) DEFAULT 0,
    desconto_sab_tam_m numeric(15,2) DEFAULT 0,
    desconto_sab_tam_g numeric(15,2) DEFAULT 0,
    desconto_sab_tam_gg numeric(15,2) DEFAULT 0,
    desconto_sab_tam_extra numeric(15,2) DEFAULT 0,
    desconto_dom_padrao numeric(15,2) DEFAULT 0,
    desconto_dom_tam_p numeric(15,2) DEFAULT 0,
    desconto_dom_tam_m numeric(15,2) DEFAULT 0,
    desconto_dom_tam_g numeric(15,2) DEFAULT 0,
    desconto_dom_tam_gg numeric(15,2) DEFAULT 0,
    desconto_dom_tam_extra numeric(15,2) DEFAULT 0
);


--
-- Name: promocao_id_promocao_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promocao_id_promocao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promocao_id_promocao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.promocao_id_promocao_seq OWNED BY public.promocao.id_promocao;


--
-- Name: quero_delivery_customer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quero_delivery_customer (
    id_pedido character varying(50) NOT NULL,
    customer_id character varying(50),
    name character varying(150),
    document_number character varying(50),
    orders_count integer,
    phone_number character varying(30),
    phone_extension character varying(10)
);


--
-- Name: quero_delivery_delivery; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quero_delivery_delivery (
    id_pedido character varying(50) NOT NULL,
    delivered_by character varying(30),
    estimated_date timestamp without time zone,
    delivered_date timestamp without time zone,
    country character varying(10),
    state character varying(10),
    city character varying(100),
    district character varying(100),
    street character varying(150),
    number character varying(20),
    complement character varying(150),
    reference character varying(150),
    formatted_address text,
    postal_code character varying(20),
    latitude numeric(10,7),
    longitude numeric(10,7)
);


--
-- Name: quero_delivery_discount_sponsorship; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quero_delivery_discount_sponsorship (
    id_pedido character varying(50) NOT NULL,
    sponsor_name character varying(50),
    amount_value numeric(12,2),
    amount_currency character varying(10),
    discount_code character varying(50)
);


--
-- Name: quero_delivery_discounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quero_delivery_discounts (
    id_pedido character varying(50) NOT NULL,
    target character varying(30),
    amount_value numeric(12,2),
    amount_currency character varying(10)
);


--
-- Name: quero_delivery_item_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quero_delivery_item_options (
    id_pedido character varying(50) NOT NULL,
    item_id character varying(50) NOT NULL,
    item_index integer,
    option_id character varying(50),
    option_index integer,
    name character varying(150),
    external_code character varying(50),
    unit character varying(20),
    ean character varying(30),
    calculation_type character varying(30),
    quantity integer,
    special_instructions text,
    unit_price_value numeric(12,2),
    unit_price_currency character varying(10),
    total_price_value numeric(12,2),
    total_price_currency character varying(10)
);


--
-- Name: quero_delivery_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quero_delivery_items (
    id_pedido character varying(50) NOT NULL,
    item_id character varying(50),
    item_index integer,
    name character varying(150),
    external_code character varying(50),
    unit character varying(20),
    ean character varying(30),
    quantity integer,
    special_instructions text,
    unit_price_value numeric(12,2),
    unit_price_currency character varying(10),
    options_price_value numeric(12,2),
    options_price_currency character varying(10),
    total_price_value numeric(12,2),
    total_price_currency character varying(10)
);


--
-- Name: quero_delivery_other_fees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quero_delivery_other_fees (
    id_pedido character varying(50) NOT NULL,
    name character varying(100),
    type character varying(30),
    received_by character varying(30),
    receiver_document character varying(50),
    observation text,
    price_value numeric(12,2),
    price_currency character varying(10)
);


--
-- Name: quero_delivery_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quero_delivery_payments (
    id_pedido character varying(50) NOT NULL,
    prepaid_value numeric(12,2),
    pending_value numeric(12,2),
    method_value numeric(12,2),
    method_currency character varying(10),
    method_type character varying(30),
    method_name character varying(30),
    method_info character varying(100),
    change_for numeric(12,2),
    id_forma integer
);


--
-- Name: quero_delivery_pedidos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quero_delivery_pedidos (
    id_pedido character varying(50) NOT NULL,
    type character varying(30),
    display_id character varying(30),
    source_app_id character varying(50),
    created_at timestamp without time zone,
    last_event character varying(30),
    arrival_order integer,
    order_timing character varying(30),
    preparation_start timestamp without time zone,
    scheduled_start timestamp without time zone,
    scheduled_end timestamp without time zone,
    merchant_id character varying(50),
    merchant_name character varying(150),
    total_items_value numeric(12,2),
    total_items_currency character varying(10),
    total_other_fees_value numeric(12,2),
    total_other_fees_currency character varying(10),
    total_discount_value numeric(12,2),
    total_discount_currency character varying(10),
    total_order_value numeric(12,2),
    total_order_currency character varying(10),
    extra_info text,
    is_separated boolean,
    integrado boolean DEFAULT false NOT NULL
);


--
-- Name: regime_tributario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regime_tributario (
    emp_001 integer NOT NULL,
    crt_codigo integer NOT NULL,
    crt_descricao character varying(255)
);


--
-- Name: resposta_food; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resposta_food (
    id integer NOT NULL,
    resposta integer NOT NULL,
    id_venda integer NOT NULL,
    id_delivery integer NOT NULL,
    emp_001 integer DEFAULT 1 NOT NULL,
    data timestamp without time zone
);


--
-- Name: resposta_food_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.resposta_food_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: resposta_food_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.resposta_food_id_seq OWNED BY public.resposta_food.id;


--
-- Name: resposta_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resposta_menu (
    id integer NOT NULL,
    resposta integer NOT NULL,
    id_venda_web integer NOT NULL,
    id_venda_local integer NOT NULL,
    emp_001 integer DEFAULT 1 NOT NULL,
    data timestamp without time zone
);


--
-- Name: resposta_menu_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.resposta_menu_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: resposta_menu_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.resposta_menu_id_seq OWNED BY public.resposta_menu.id;


--
-- Name: resposta_zap; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resposta_zap (
    id integer NOT NULL,
    tipo integer NOT NULL,
    fone_zap character varying(25) NOT NULL,
    ven_001 integer NOT NULL,
    ven_029 integer NOT NULL,
    data timestamp without time zone,
    emp_001 integer DEFAULT 1 NOT NULL
);


--
-- Name: resposta_zap_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.resposta_zap_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: resposta_zap_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.resposta_zap_id_seq OWNED BY public.resposta_zap.id;


--
-- Name: revenda; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.revenda (
    razao character varying(100) NOT NULL,
    cnpj character varying(20) NOT NULL,
    cep character varying(8),
    endereco character varying(60),
    numero character varying(10),
    complemento character varying(60),
    bairro character varying(60),
    cid_001 integer,
    fone character varying(20),
    nome_sistema character varying(30),
    info1 character varying(100),
    info2_linha1 character varying(48),
    info2_linha2 character varying(48),
    site_email character varying(100),
    id_revenda integer
);


--
-- Name: sat_finalizador; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sat_finalizador (
    sfi_codigo integer NOT NULL,
    sfi_descricao character varying(50)
);


--
-- Name: sessao_wattsap; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessao_wattsap (
    id_sessao bigint NOT NULL,
    id_empresa integer NOT NULL,
    telefone character varying(20) NOT NULL,
    remote_jid character varying(255),
    nome_contato character varying(150),
    estado character varying(40) DEFAULT 'ATENDIMENTO_ROBO'::character varying NOT NULL,
    contexto jsonb DEFAULT '{}'::jsonb NOT NULL,
    encaminhado_atendente boolean DEFAULT false NOT NULL,
    ultima_mensagem_em timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    expira_em timestamp without time zone,
    criado_em timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL,
    atualizado_em timestamp without time zone
);


--
-- Name: sessao_wattsap_id_sessao_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessao_wattsap_id_sessao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessao_wattsap_id_sessao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessao_wattsap_id_sessao_seq OWNED BY public.sessao_wattsap.id_sessao;


--
-- Name: setor_estoque; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.setor_estoque (
    id_setor integer NOT NULL,
    id_empresa integer NOT NULL,
    descricao character varying(50) NOT NULL,
    id_situacao integer DEFAULT 4 NOT NULL
);


--
-- Name: setor_estoque_composicao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.setor_estoque_composicao (
    id_composicao integer NOT NULL,
    id_setor integer NOT NULL,
    id_empresa integer NOT NULL,
    quantidade numeric(15,3) DEFAULT 0.0 NOT NULL,
    estoque_fiscal numeric(15,3) DEFAULT '0'::numeric NOT NULL
);


--
-- Name: setor_estoque_material; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.setor_estoque_material (
    id_material integer NOT NULL,
    id_setor integer NOT NULL,
    id_empresa integer NOT NULL,
    quantidade numeric(15,3) DEFAULT 0.0 NOT NULL,
    estoque_fiscal numeric(15,3) DEFAULT '0'::numeric NOT NULL
);


--
-- Name: setor_estoque_opcional; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.setor_estoque_opcional (
    id_opcional integer NOT NULL,
    id_setor integer NOT NULL,
    id_empresa integer NOT NULL,
    quantidade numeric(15,3) DEFAULT 0.0 NOT NULL
);


--
-- Name: sped_generos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sped_generos (
    gen_codigo character varying(2),
    gen_descricao character varying(150)
);


--
-- Name: subcategoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subcategoria (
    sub_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    sub_002 character varying(40) NOT NULL,
    sit_001 integer DEFAULT 4 NOT NULL
);


--
-- Name: tara; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tara (
    tar_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    descricao character varying(20) NOT NULL,
    peso numeric(15,3),
    sit_001 integer DEFAULT 4 NOT NULL
);


--
-- Name: terminais; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.terminais (
    ter_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    descricao character varying(60) NOT NULL,
    host character varying(30) NOT NULL,
    ip character varying(30) NOT NULL
);


--
-- Name: tipo_movimento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipo_movimento (
    id_movimento integer NOT NULL,
    id_empresa integer NOT NULL,
    tipo character varying(100),
    data_emissao date,
    valor numeric(10,2) DEFAULT 0 NOT NULL,
    documento character varying(100),
    observacao character varying(150),
    id_situacao integer NOT NULL,
    id_usuario_lancamento integer,
    id_usuario_baixa integer,
    id_contacorrente integer NOT NULL,
    compensado integer,
    ven_001 integer,
    enc_001 integer,
    ite_001 integer,
    saldo_ant numeric(15,2) DEFAULT 0 NOT NULL
);


--
-- Name: tipo_movimento_id_movimento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipo_movimento_id_movimento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipo_movimento_id_movimento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipo_movimento_id_movimento_seq OWNED BY public.tipo_movimento.id_movimento;


--
-- Name: transf_rp_food_menu; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transf_rp_food_menu (
    id integer NOT NULL,
    tipo character varying(40) NOT NULL,
    id_empresa integer NOT NULL,
    id_registro integer NOT NULL,
    id_registro_secundario integer,
    auxiliar character varying(30),
    registro_deletado boolean DEFAULT false,
    carga_total boolean DEFAULT false NOT NULL
);


--
-- Name: transf_rp_food_menu_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transf_rp_food_menu_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transf_rp_food_menu_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transf_rp_food_menu_id_seq OWNED BY public.transf_rp_food_menu.id;


--
-- Name: transf_rpcheff_cloud; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transf_rpcheff_cloud (
    id integer NOT NULL,
    tipo character varying(40) NOT NULL,
    id_empresa integer NOT NULL,
    id_registro integer NOT NULL,
    id_registro_secundario integer,
    auxiliar character varying(30),
    registro_deletado boolean DEFAULT false
);


--
-- Name: transf_rpcheff_cloud_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transf_rpcheff_cloud_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transf_rpcheff_cloud_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transf_rpcheff_cloud_id_seq OWNED BY public.transf_rpcheff_cloud.id;


--
-- Name: tribut_predet; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tribut_predet (
    tri_id integer NOT NULL,
    emp_001 integer NOT NULL,
    descricao character varying(40) NOT NULL,
    sit_001 integer DEFAULT 4 NOT NULL,
    orm_codigo integer,
    cst_consumidor integer,
    cso_codigo integer,
    pis_codigo_saida integer,
    cof_codigo_saida integer,
    gen_codigo character varying(2),
    cfop_consumidor character varying(4),
    icms numeric(15,2),
    pis numeric(15,2),
    cofins numeric(15,2),
    ncm character varying(10),
    cest character varying(7),
    atualiza_aliquotas boolean DEFAULT false NOT NULL,
    redbasecalcicms numeric(15,2) DEFAULT '0'::numeric NOT NULL
);


--
-- Name: tribut_predet_cfop; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tribut_predet_cfop (
    tri_id integer NOT NULL,
    emp_001 integer NOT NULL,
    cfop character varying(4) NOT NULL
);


--
-- Name: trocogarcom; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trocogarcom (
    id_caixa integer NOT NULL,
    id_empresa integer NOT NULL,
    id_usuario integer NOT NULL,
    id_venda integer NOT NULL,
    valor numeric(10,2) NOT NULL
);


--
-- Name: unidades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.unidades (
    uni_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    uni_002 character varying(15) NOT NULL,
    uni_003 character varying(6) NOT NULL,
    sit_001 integer DEFAULT 4 NOT NULL,
    usu_001_1 integer,
    usu_001_2 integer,
    usu_001_3 integer,
    dat_001_1 timestamp without time zone,
    dat_001_2 timestamp without time zone,
    dat_001_3 timestamp without time zone
);


--
-- Name: usu_movimento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usu_movimento (
    id integer NOT NULL,
    id_empresa integer NOT NULL,
    id_usuario integer NOT NULL,
    descricao character varying(100) NOT NULL,
    valor numeric(10,2),
    tipo integer DEFAULT 0 NOT NULL,
    usu_001_1 integer,
    lancamento date
);


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuarios (
    usu_001 integer NOT NULL,
    usu_002 character varying(30) NOT NULL,
    usu_003 character varying(30),
    usu_004 character varying(30),
    usu_005 bytea,
    sit_001 integer DEFAULT 4 NOT NULL,
    usu_001_1 integer,
    usu_001_2 integer,
    usu_001_3 integer,
    dat_001_1 timestamp without time zone,
    dat_001_2 timestamp without time zone,
    dat_001_3 timestamp without time zone,
    b_acesso_caixa boolean DEFAULT false,
    b_alteracao_estoque boolean DEFAULT false,
    b_cancelamento_mesa boolean DEFAULT false,
    b_transferencia_mesa boolean DEFAULT false,
    b_acesso_produtos boolean DEFAULT false,
    b_acesso_clientes boolean DEFAULT false,
    b_acesso_cpagar_creceber boolean DEFAULT false,
    b_acesso_mov_caixa boolean DEFAULT false,
    b_acesso_abertura_caixa boolean DEFAULT false,
    b_alteracao_precou_venda boolean DEFAULT false,
    b_acesso_venda_balcao boolean DEFAULT false,
    b_acesso_venda_mesa boolean DEFAULT false,
    b_acesso_venda_comanda boolean DEFAULT false,
    b_acesso_venda_delivery boolean DEFAULT false,
    b_funcao_entregador boolean DEFAULT false,
    b_funcao_garcom boolean DEFAULT false,
    b_acesso_usuarios boolean DEFAULT false,
    b_acesso_configuracao boolean DEFAULT false,
    b_cancelamento_delivery boolean DEFAULT false,
    b_acesso_venda_pdv boolean DEFAULT false,
    b_cancelamento_pdv boolean DEFAULT false,
    b_cancelamento_balcao boolean DEFAULT false,
    b_reabrir_mesa_comanda boolean DEFAULT false NOT NULL,
    b_acesso_devolucao boolean DEFAULT false,
    b_acesso_promocao boolean DEFAULT false NOT NULL,
    b_libera_venda_conta_atraso boolean DEFAULT false NOT NULL,
    b_permite_transferencia_item boolean DEFAULT false NOT NULL,
    b_permite_fechamento_mesa_comanda boolean DEFAULT false NOT NULL,
    b_permite_prefechamento_mesa_comanda boolean DEFAULT false NOT NULL,
    b_acesso_nfe boolean DEFAULT false NOT NULL,
    b_permite_pag_antecipado_mesa_comanda boolean DEFAULT false NOT NULL,
    b_permite_juntar_mesa_comanda boolean DEFAULT false NOT NULL,
    b_permite_quantidade_mesa_comanda boolean DEFAULT false NOT NULL,
    b_permite_desconto_item_mesa_comanda boolean DEFAULT false NOT NULL,
    b_acesso_venda_cnoturna boolean DEFAULT false NOT NULL,
    b_permite_transferencia_estoque boolean DEFAULT false NOT NULL,
    b_permite_visualizar_todos_caixas boolean DEFAULT false NOT NULL,
    b_permite_reimpressao_mesa_comanda boolean DEFAULT false,
    b_permite_liberar_catraca boolean DEFAULT false,
    b_permite_alterar_taxa10 boolean DEFAULT false NOT NULL,
    b_acesso_resumo_casa boolean DEFAULT false NOT NULL,
    salario numeric(10,2) DEFAULT 0.00 NOT NULL,
    b_acesso_mov_func boolean DEFAULT false NOT NULL,
    b_acesso_cad_financeiro boolean DEFAULT false NOT NULL,
    b_adm boolean DEFAULT false NOT NULL,
    b_permite_desconto_fechamento_mesa_comanda boolean DEFAULT false NOT NULL,
    b_restringir_relatorios boolean DEFAULT false NOT NULL,
    b_supervisor boolean DEFAULT false NOT NULL,
    b_libera_fiado boolean DEFAULT false NOT NULL,
    b_permite_canc_item_mobile boolean DEFAULT false NOT NULL,
    b_permite_gaveta boolean DEFAULT false NOT NULL,
    biometria bytea,
    desconto_max numeric(10,2) DEFAULT 100.00 NOT NULL,
    b_libera_ifood boolean DEFAULT false NOT NULL,
    b_altera_sit_nfe boolean DEFAULT false NOT NULL,
    emp_001 integer DEFAULT 1 NOT NULL,
    b_permite_salvar_pdv boolean DEFAULT true NOT NULL,
    b_acesso_web boolean DEFAULT false NOT NULL,
    b_admin_web boolean DEFAULT false NOT NULL,
    email character varying(100),
    b_cancelamento_item_pos boolean DEFAULT false,
    b_acesso_despesas boolean DEFAULT false NOT NULL,
    b_permite_reimpressao_cupom boolean DEFAULT false NOT NULL,
    b_relatorio_taxas boolean DEFAULT false NOT NULL,
    b_acesso_cad_eventos boolean DEFAULT false NOT NULL,
    b_permite_venda_evento boolean DEFAULT false NOT NULL,
    b_cancelamento_evento boolean DEFAULT false NOT NULL,
    b_exclusao_mov_func boolean DEFAULT false NOT NULL,
    b_permite_consultar_produtos_pdv boolean DEFAULT true NOT NULL,
    b_acesso_ajuste_inventario boolean DEFAULT false NOT NULL
);


--
-- Name: venda; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.venda (
    ven_001 integer NOT NULL,
    emp_001 integer NOT NULL,
    ven_004 timestamp without time zone,
    cli_001 integer,
    sit_001 integer NOT NULL,
    usu_001_1 integer,
    usu_001_2 integer,
    usu_001_3 integer,
    dat_001_1 timestamp without time zone,
    dat_001_2 timestamp without time zone,
    dat_001_3 timestamp without time zone,
    enc_001 integer,
    ven_007 numeric(10,2) DEFAULT 0.00 NOT NULL,
    ven_008 numeric(10,2) DEFAULT 0.00 NOT NULL,
    ven_009 numeric(10,2) DEFAULT 0.00 NOT NULL,
    ven_015 integer,
    ven_024 character varying(1),
    ven_025 integer,
    ven_026 integer,
    ven_027 character varying(200),
    ven_029 integer,
    nro_pessoas integer DEFAULT 1,
    nro_couvert_m integer DEFAULT 0,
    nro_couvert_f integer DEFAULT 0,
    cpf_cliente character varying(20),
    id_caixa_abertura integer,
    ven_034 character varying(50),
    ven_037 timestamp without time zone,
    ven_036 character varying(10),
    ven_038 character varying(50),
    pdv_codigo integer,
    crt_codigo integer,
    ven_033 integer,
    id_entregador integer,
    data_saida timestamp without time zone,
    data_entrega timestamp without time zone,
    b_taxa_entrega boolean DEFAULT true,
    terminal_abertura character varying(100),
    numero_cupom integer,
    id_garcom_abertura integer,
    tipofiscal character varying(10),
    nome_cliente character varying(90),
    valor_couvert_f numeric(15,2),
    valor_couvert_m numeric(15,2),
    nfce_contingencia boolean DEFAULT false NOT NULL,
    nfce_contingencia_enviada boolean DEFAULT false NOT NULL,
    justificativa_cancelamento character varying(200),
    imprimir_prefechamento_mobile boolean DEFAULT false,
    data_agendamento timestamp without time zone,
    hora_agendamento time without time zone,
    vendas_pelo_ifood boolean DEFAULT false NOT NULL,
    correlation_id_ifood character varying(50),
    b_origem_antecipado boolean DEFAULT false NOT NULL,
    id_pag_antecipado integer,
    id_venda_origem integer,
    serie_cupom integer,
    nfce_inutilizada boolean DEFAULT false NOT NULL,
    b_venda_casa_noturna boolean DEFAULT false NOT NULL,
    id_perfil_consumo integer,
    valor_consumacao numeric(15,2) DEFAULT 0.0 NOT NULL,
    valor_entrada numeric(15,2) DEFAULT 0.0 NOT NULL,
    total_pre numeric(15,2) DEFAULT 0.0 NOT NULL,
    taxa_cartao_reter numeric(15,2) DEFAULT 0.0 NOT NULL,
    b_delivery_cupom_antec boolean DEFAULT false NOT NULL,
    terminal_canc character varying(100),
    data_inutilizacao timestamp without time zone,
    nfce_justificativa character varying(100),
    vendas_pelo_zap boolean DEFAULT false NOT NULL,
    fone_zap character varying(25),
    zap_rejeitada boolean DEFAULT false NOT NULL,
    painel_senha integer,
    json_ifood text,
    shortreference_ifood character varying(10),
    method_ifood character varying(20),
    integracao_prepaid boolean DEFAULT false CONSTRAINT venda_ifood_prepaid_not_null NOT NULL,
    id_usuario_pre integer,
    integracao_taxa numeric(10,2) DEFAULT 0 CONSTRAINT venda_taxa_ifood_not_null NOT NULL,
    xml_cfe text,
    b_visualizar_pre boolean DEFAULT false NOT NULL,
    xml_pre_visualizar text,
    pre_fech_mobile_imp_interna boolean,
    imprimir_fech_mobile boolean DEFAULT false NOT NULL,
    b_visualizar_fech boolean DEFAULT false NOT NULL,
    xml_fech_visualizar text,
    fech_mobile_imp_interna boolean,
    id_usuario_fech integer,
    venda_saraweb boolean DEFAULT false NOT NULL,
    pontosgeradosbeneficio integer DEFAULT 0 NOT NULL,
    pontosresgatadosbeneficio integer DEFAULT 0 NOT NULL,
    b_gerou_pontos_beneficio boolean DEFAULT false NOT NULL,
    b_resgatou_pontos_beneficio boolean DEFAULT false NOT NULL,
    valor_taxa_ant numeric(10,2) DEFAULT 0.00 NOT NULL,
    vendas_food boolean DEFAULT false NOT NULL,
    food_id_venda integer,
    food_rejeitada boolean DEFAULT false NOT NULL,
    nome_mesa_comanda character varying(50),
    pickupcode_ifood character varying(20),
    delivery_moto_ifood numeric(10,2) DEFAULT 0.00 NOT NULL,
    vendas_menu boolean DEFAULT false NOT NULL,
    menu_id_venda integer,
    merchant_id_ifood character varying(100),
    ignorar_taxa_garcom boolean DEFAULT false NOT NULL,
    taxa_valor_garcom numeric(15,2) DEFAULT '0'::numeric,
    taxa_percentual_garcom numeric(15,2) DEFAULT '0'::numeric,
    taxajurosformapagamento numeric(15,2) DEFAULT '0'::numeric,
    sobra_consumacao_minima numeric(15,2) DEFAULT '0'::numeric,
    taxaentrega numeric(15,2) DEFAULT '0'::numeric,
    id_pedido_pedzap integer,
    id_pedido_quero_delivery character varying(50),
    origem_integracao character varying(30),
    id_pedido_99food bigint,
    numero_venda_interna_99food character varying(120),
    utiliza_pagamento_connect_stone boolean DEFAULT false NOT NULL,
    status_venda_plataforma_delivery boolean DEFAULT false NOT NULL,
    id_pedido_anotaai character varying(180),
    numero_venda_interna_anotaai character varying(120),
    id_pedido_deliverydireto character varying(180),
    numero_venda_interna_deliverydireto character varying(120)
)
WITH (autovacuum_vacuum_scale_factor='0.02', autovacuum_analyze_scale_factor='0.02');


--
-- Name: COLUMN venda.id_caixa_abertura; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.venda.id_caixa_abertura IS 'Armazena o id de caixa no momento da abertura';


--
-- Name: venda_pag_antecipado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.venda_pag_antecipado (
    id_venda_pag_antecipado integer NOT NULL,
    id_venda integer NOT NULL,
    id_empresa integer NOT NULL,
    id_formapgto integer NOT NULL,
    valor numeric(15,2) DEFAULT 0.00 NOT NULL,
    data_hora timestamp without time zone DEFAULT ('now'::text)::timestamp without time zone,
    id_caixa integer,
    id_caixaitem integer,
    observacao text,
    id_usuario integer,
    id_situacao integer DEFAULT 4 NOT NULL,
    b_nova_venda boolean DEFAULT false NOT NULL,
    b_taxa boolean DEFAULT false NOT NULL,
    valor_taxa numeric(10,2) DEFAULT 0.00 NOT NULL,
    valor_prod numeric(10,2) DEFAULT 0.00 NOT NULL,
    nro_couvert_m integer DEFAULT 0 NOT NULL,
    nro_couvert_f integer DEFAULT 0 NOT NULL,
    valor_couvert_m numeric(10,2) DEFAULT 0.00 NOT NULL,
    valor_couvert_f numeric(10,2) DEFAULT 0.00 NOT NULL,
    autorizacao character varying(50),
    valor_juros numeric(10,2) DEFAULT 0.00 NOT NULL,
    acquirerdocument character varying(50),
    hash_terminal character varying(40)
);


--
-- Name: venda_pag_antecipado_id_venda_pag_antecipado_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.venda_pag_antecipado_id_venda_pag_antecipado_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: venda_pag_antecipado_id_venda_pag_antecipado_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.venda_pag_antecipado_id_venda_pag_antecipado_seq OWNED BY public.venda_pag_antecipado.id_venda_pag_antecipado;


--
-- Name: venda_pag_antecipado_itens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.venda_pag_antecipado_itens (
    id_mestre integer NOT NULL,
    id_empresa integer NOT NULL,
    ite_001 integer NOT NULL,
    mat_001 integer NOT NULL,
    qtd_paga numeric(10,4) NOT NULL,
    valor_pago numeric(10,2) NOT NULL,
    unitario numeric(10,2) NOT NULL
);


--
-- Name: venda_pre_pago; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.venda_pre_pago (
    id_pre integer NOT NULL,
    id_venda integer NOT NULL,
    id_empresa integer NOT NULL,
    id_formapgto integer NOT NULL,
    valor numeric(15,2) DEFAULT 1 NOT NULL,
    data timestamp without time zone NOT NULL,
    id_usuario integer NOT NULL
);


--
-- Name: venda_pre_pago_id_pre_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.venda_pre_pago_id_pre_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: venda_pre_pago_id_pre_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.venda_pre_pago_id_pre_seq OWNED BY public.venda_pre_pago.id_pre;


--
-- Name: vendaitem; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendaitem (
    emp_001 integer NOT NULL,
    ven_001 integer NOT NULL,
    ite_001 integer NOT NULL,
    mat_001 integer NOT NULL,
    ite_002 numeric(10,4) NOT NULL,
    ite_003 numeric(10,2) NOT NULL,
    ite_005 numeric(10,2),
    ite_006 character varying(200),
    sit_001 integer,
    ite_013 integer,
    gar_001 integer,
    desconto numeric(10,2) DEFAULT 0,
    orm_codigo integer,
    cst_consumidor integer,
    icms_perc numeric(15,2),
    icms_valor numeric(15,2),
    pis_codigo_saida integer,
    pis_perc numeric(15,2),
    pis_valor numeric(15,2),
    cof_codigo_saida integer,
    cofins_perc numeric(15,2),
    cofins_valor numeric(15,2),
    mod_codigo integer,
    cfop_consumidor character varying(4),
    redbasecalcst numeric(15,2),
    redbasecalcicms numeric(15,2),
    cso_codigo integer,
    id_usuario_cancelamento integer,
    tamanho character varying(2),
    b_venda_tamanho boolean DEFAULT false,
    item_fracionado integer,
    acrescimo numeric(10,2),
    quantidade_impressao numeric(10,4) DEFAULT 0,
    data_hora_lancamento timestamp without time zone DEFAULT ('now'::text)::timestamp without time zone NOT NULL,
    b_producao boolean DEFAULT true,
    b_entregue boolean DEFAULT false,
    numero_pedido integer,
    justificativa_cancelamento character varying(200),
    mesa_vinc integer DEFAULT 0 NOT NULL,
    b_gratis boolean DEFAULT false,
    valor_pago_antec numeric(10,2) DEFAULT 0.00 NOT NULL,
    qtd_paga_antec numeric(10,4) DEFAULT 0.0000 NOT NULL,
    b_gerou_ponto_fidelidade boolean DEFAULT false NOT NULL,
    b_resgatoufidelidade boolean DEFAULT false NOT NULL,
    qtdepontosgerados integer DEFAULT 0 NOT NULL,
    qtdepontosutilizados integer DEFAULT 0 NOT NULL,
    qtderesgatada numeric(10,4) DEFAULT 0.0000 NOT NULL,
    b_imprime_canc_mobile boolean DEFAULT false NOT NULL,
    data_cancelamento timestamp without time zone,
    terminal_impressao character varying(100),
    ite_014 integer,
    mc_origem character varying(30),
    b_devolucao boolean DEFAULT false NOT NULL,
    id_venda_devolucao integer,
    item_devolucao integer,
    id_setor_devolucao integer,
    custoproduto numeric(15,4) DEFAULT '0'::numeric,
    custocomposicao numeric(15,4) DEFAULT '0'::numeric,
    margemlucro numeric(15,2) DEFAULT '0'::numeric,
    acrescimorateio numeric(15,2) DEFAULT '0'::numeric,
    descontorateio numeric(15,2) DEFAULT '0'::numeric,
    rateiotaxagarcom numeric(15,2) DEFAULT '0'::numeric,
    rateioconsumacaominima numeric(15,2) DEFAULT '0'::numeric,
    rateiotaxaintegracao numeric(15,2) DEFAULT '0'::numeric,
    rateiotaxaentrega numeric(15,2) DEFAULT '0'::numeric,
    rateiotaxaforma numeric(15,2) DEFAULT '0'::numeric,
    produtoimpresso boolean DEFAULT false,
    pendenteimpressao boolean DEFAULT false,
    cst_rt character varying(5),
    cclasstrib_rt character varying(8),
    rt_vbc numeric(15,4) DEFAULT '0'::numeric,
    rt_aliq_ibs_uf numeric(15,4) DEFAULT '0'::numeric,
    rt_aliq_ibs_mun numeric(15,4) DEFAULT '0'::numeric,
    rt_aliq_cbs numeric(15,4) DEFAULT '0'::numeric,
    rt_vibsuf numeric(15,4) DEFAULT '0'::numeric,
    rt_vibsmun numeric(15,4) DEFAULT '0'::numeric,
    rt_vibs numeric(15,4) DEFAULT '0'::numeric,
    rt_vcbs numeric(15,4) DEFAULT '0'::numeric,
    rt_vitem numeric(15,4) DEFAULT '0'::numeric,
    cbenef character varying(10),
    aliqpisredbenef numeric(15,3) DEFAULT '0'::numeric NOT NULL,
    aliqcofinsredbenef numeric(15,3) DEFAULT '0'::numeric NOT NULL,
    infadfisco character varying(200),
    lancamento_mobile boolean DEFAULT false NOT NULL,
    ajustes_acrescimo_fracionado numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    id_lancamento_mobile character varying(100)
)
WITH (autovacuum_vacuum_scale_factor='0.02', autovacuum_analyze_scale_factor='0.02');


--
-- Name: vendaitemopcional; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendaitemopcional (
    id_venda integer NOT NULL,
    id_empresa integer NOT NULL,
    id_vendaitem integer NOT NULL,
    id_opcional integer NOT NULL,
    gratis boolean DEFAULT false NOT NULL,
    valor numeric(15,2) DEFAULT 0 NOT NULL,
    id_vendaitemopcional bigint NOT NULL
);


--
-- Name: vendaitemopcional_id_vendaitemopcional_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.vendaitemopcional ALTER COLUMN id_vendaitemopcional ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.vendaitemopcional_id_vendaitemopcional_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: view_solidticketgate; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.view_solidticketgate AS
 SELECT (com_003)::character varying AS ncomanda,
    COALESCE(status_catraca, 'L'::character varying) AS statuscomanda
   FROM public.comanda;


--
-- Name: vw_integracao99food_relatorio_financeiro; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_integracao99food_relatorio_financeiro AS
 SELECT p.id AS pedido_id,
    p.id_empresa,
    p.app_shop_id,
    p.order_id,
    p.status_local,
    p.status_nome,
    p.data AS data_pedido,
    p.recebido_em,
    p.total AS valor_pedido_local,
    p.subtotal AS subtotal_pedido_local,
    p.entrega_valor AS entrega_pedido_local,
    f.id AS financeiro_id,
    f.order_index,
    f.business_datetime,
    f.meal_original_amount,
    f.order_amount,
    f.settlement_amount,
    f.commission_amount,
    f.commission_rate,
    f.pay_commission_amount,
    f.b2p_delivery_amount,
    f.shop_delivery_amount,
    f.shop_activity_outcome,
    f.shop_activity_subsidy,
    f.free_delivery_outcome,
    f.free_delivery_subsidy,
    f.day_payment_id,
    f.expect_settle_date,
    s.id AS settlement_id,
    s.week_payment_id,
    s.withdraw_date,
    s.withdraw_amount,
    (((((COALESCE(f.commission_amount, (0)::numeric) + COALESCE(f.pay_commission_amount, (0)::numeric)) + COALESCE(f.b2p_delivery_amount, (0)::numeric)) + COALESCE(f.meal_loss_deduct_amount, (0)::numeric)) + COALESCE(f.vat_amount, (0)::numeric)) + COALESCE(f.monthly_service_price, (0)::numeric)) AS total_cobrancas_99,
        CASE
            WHEN (f.id IS NULL) THEN 'PENDENTE'::text
            ELSE 'SINCRONIZADO'::text
        END AS financeiro_situacao
   FROM ((public.integracao99foodpedido p
     LEFT JOIN public.integracao99foodfinanceirobill f ON (((f.id_empresa = p.id_empresa) AND ((f.app_shop_id)::text = (p.app_shop_id)::text) AND ((f.order_id)::text = (p.order_id)::text))))
     LEFT JOIN public.integracao99foodfinanceirosettlement s ON (((s.id_empresa = f.id_empresa) AND ((s.app_shop_id)::text = (f.app_shop_id)::text) AND ((COALESCE(f.day_payment_id, ''::character varying))::text <> ''::text) AND jsonb_exists(s.day_payment_id_list, (f.day_payment_id)::text))));


--
-- Name: zz_migration; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zz_migration (
    idmigration integer NOT NULL,
    descricao character varying(255),
    data timestamp without time zone
);


--
-- Name: ambiente id_ambiente; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ambiente ALTER COLUMN id_ambiente SET DEFAULT nextval('public.ambiente_id_ambiente_seq'::regclass);


--
-- Name: beneficios ben_001; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficios ALTER COLUMN ben_001 SET DEFAULT nextval('public.beneficios_ben_001_seq'::regclass);


--
-- Name: catraca_mobile id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catraca_mobile ALTER COLUMN id SET DEFAULT nextval('public.catraca_mobile_id_seq'::regclass);


--
-- Name: cfop_conversao id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cfop_conversao ALTER COLUMN id SET DEFAULT nextval('public.cfop_conversao_id_seq'::regclass);


--
-- Name: clientes_endereco id_endereco; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_endereco ALTER COLUMN id_endereco SET DEFAULT nextval('public.clientes_endereco_id_endereco_seq'::regclass);


--
-- Name: configuracao_funcionamento id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracao_funcionamento ALTER COLUMN id SET DEFAULT nextval('public.configuracao_funcionamento_id_seq'::regclass);


--
-- Name: configuracao_rpfood id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracao_rpfood ALTER COLUMN id SET DEFAULT nextval('public.configuracao_rpfood_id_seq'::regclass);


--
-- Name: configuracao_wattsap id_configuracao; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracao_wattsap ALTER COLUMN id_configuracao SET DEFAULT nextval('public.configuracao_wattsap_id_configuracao_seq'::regclass);


--
-- Name: cpagar id_cpagar; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cpagar ALTER COLUMN id_cpagar SET DEFAULT nextval('public.cpagar_id_cpagar_seq'::regclass);


--
-- Name: creceber id_creceber; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creceber ALTER COLUMN id_creceber SET DEFAULT nextval('public.creceber_id_creceber_seq'::regclass);


--
-- Name: dfe_classtrib_rt id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dfe_classtrib_rt ALTER COLUMN id SET DEFAULT nextval('public.dfe_classtrib_rt_id_seq'::regclass);


--
-- Name: dfe_cst_rt id_cst_ibs_cbs; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dfe_cst_rt ALTER COLUMN id_cst_ibs_cbs SET DEFAULT nextval('public.dfe_cst_rt_id_cst_ibs_cbs_seq'::regclass);


--
-- Name: eventos_detalhes_nfe_rt id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_detalhes_nfe_rt ALTER COLUMN id SET DEFAULT nextval('public.eventos_detalhes_nfe_rt_id_seq'::regclass);


--
-- Name: eventos_nfe_rt id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_nfe_rt ALTER COLUMN id SET DEFAULT nextval('public.eventos_nfe_rt_id_seq'::regclass);


--
-- Name: ifood_rejeitados id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ifood_rejeitados ALTER COLUMN id SET DEFAULT nextval('public.ifood_rejeitados_id_seq'::regclass);


--
-- Name: impressaoproducao id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impressaoproducao ALTER COLUMN id SET DEFAULT nextval('public.impressaoproducao_id_seq'::regclass);


--
-- Name: informativoversao id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.informativoversao ALTER COLUMN id SET DEFAULT nextval('public.informativoversao_id_seq'::regclass);


--
-- Name: integracao99foodconfig id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodconfig ALTER COLUMN id SET DEFAULT nextval('public.integracao99foodconfig_id_seq'::regclass);


--
-- Name: integracao99foodfila id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodfila ALTER COLUMN id SET DEFAULT nextval('public.integracao99foodfila_id_seq'::regclass);


--
-- Name: integracao99foodfinanceirobill id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodfinanceirobill ALTER COLUMN id SET DEFAULT nextval('public.integracao99foodfinanceirobill_id_seq'::regclass);


--
-- Name: integracao99foodfinanceirosettlement id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodfinanceirosettlement ALTER COLUMN id SET DEFAULT nextval('public.integracao99foodfinanceirosettlement_id_seq'::regclass);


--
-- Name: integracao99foodhttplog id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodhttplog ALTER COLUMN id SET DEFAULT nextval('public.integracao99foodhttplog_id_seq'::regclass);


--
-- Name: integracao99foodloja id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodloja ALTER COLUMN id SET DEFAULT nextval('public.integracao99foodloja_id_seq'::regclass);


--
-- Name: integracao99foodpedido id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedido ALTER COLUMN id SET DEFAULT nextval('public.integracao99foodpedido_id_seq'::regclass);


--
-- Name: integracao99foodpedidocliente id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidocliente ALTER COLUMN id SET DEFAULT nextval('public.integracao99foodpedidocliente_id_seq'::regclass);


--
-- Name: integracao99foodpedidoendereco id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidoendereco ALTER COLUMN id SET DEFAULT nextval('public.integracao99foodpedidoendereco_id_seq'::regclass);


--
-- Name: integracao99foodpedidoitem id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidoitem ALTER COLUMN id SET DEFAULT nextval('public.integracao99foodpedidoitem_id_seq'::regclass);


--
-- Name: integracao99foodpedidoopcional id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidoopcional ALTER COLUMN id SET DEFAULT nextval('public.integracao99foodpedidoopcional_id_seq'::regclass);


--
-- Name: integracao99foodpedidopagamento id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidopagamento ALTER COLUMN id SET DEFAULT nextval('public.integracao99foodpedidopagamento_id_seq'::regclass);


--
-- Name: integracao99foodpedidostatus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidostatus ALTER COLUMN id SET DEFAULT nextval('public.integracao99foodpedidostatus_id_seq'::regclass);


--
-- Name: integracao99foodwebhooklog id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodwebhooklog ALTER COLUMN id SET DEFAULT nextval('public.integracao99foodwebhooklog_id_seq'::regclass);


--
-- Name: integracaoanotaaicheckpoint id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaicheckpoint ALTER COLUMN id SET DEFAULT nextval('public.integracaoanotaaicheckpoint_id_seq'::regclass);


--
-- Name: integracaoanotaaiconfig id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaiconfig ALTER COLUMN id SET DEFAULT nextval('public.integracaoanotaaiconfig_id_seq'::regclass);


--
-- Name: integracaoanotaaihttplog id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaihttplog ALTER COLUMN id SET DEFAULT nextval('public.integracaoanotaaihttplog_id_seq'::regclass);


--
-- Name: integracaoanotaaiinbox id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaiinbox ALTER COLUMN id SET DEFAULT nextval('public.integracaoanotaaiinbox_id_seq'::regclass);


--
-- Name: integracaoanotaaimenusync id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaimenusync ALTER COLUMN id SET DEFAULT nextval('public.integracaoanotaaimenusync_id_seq'::regclass);


--
-- Name: integracaoanotaaioutbox id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaioutbox ALTER COLUMN id SET DEFAULT nextval('public.integracaoanotaaioutbox_id_seq'::regclass);


--
-- Name: integracaoanotaaipedido id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaipedido ALTER COLUMN id SET DEFAULT nextval('public.integracaoanotaaipedido_id_seq'::regclass);


--
-- Name: integracaoanotaaipedidoitem id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaipedidoitem ALTER COLUMN id SET DEFAULT nextval('public.integracaoanotaaipedidoitem_id_seq'::regclass);


--
-- Name: integracaoanotaaipedidoopcional id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaipedidoopcional ALTER COLUMN id SET DEFAULT nextval('public.integracaoanotaaipedidoopcional_id_seq'::regclass);


--
-- Name: integracaoanotaaipedidostatus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaipedidostatus ALTER COLUMN id SET DEFAULT nextval('public.integracaoanotaaipedidostatus_id_seq'::regclass);


--
-- Name: integracaodeliverydiretocatalogomapa id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretocatalogomapa ALTER COLUMN id SET DEFAULT nextval('public.integracaodeliverydiretocatalogomapa_id_seq'::regclass);


--
-- Name: integracaodeliverydiretocheckpoint id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretocheckpoint ALTER COLUMN id SET DEFAULT nextval('public.integracaodeliverydiretocheckpoint_id_seq'::regclass);


--
-- Name: integracaodeliverydiretoconfig id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretoconfig ALTER COLUMN id SET DEFAULT nextval('public.integracaodeliverydiretoconfig_id_seq'::regclass);


--
-- Name: integracaodeliverydiretohttplog id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretohttplog ALTER COLUMN id SET DEFAULT nextval('public.integracaodeliverydiretohttplog_id_seq'::regclass);


--
-- Name: integracaodeliverydiretooutbox id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretooutbox ALTER COLUMN id SET DEFAULT nextval('public.integracaodeliverydiretooutbox_id_seq'::regclass);


--
-- Name: integracaodeliverydiretopedido id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretopedido ALTER COLUMN id SET DEFAULT nextval('public.integracaodeliverydiretopedido_id_seq'::regclass);


--
-- Name: integracaodeliverydiretopedidoitem id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretopedidoitem ALTER COLUMN id SET DEFAULT nextval('public.integracaodeliverydiretopedidoitem_id_seq'::regclass);


--
-- Name: integracaodeliverydiretopedidoopcional id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretopedidoopcional ALTER COLUMN id SET DEFAULT nextval('public.integracaodeliverydiretopedidoopcional_id_seq'::regclass);


--
-- Name: integracaodeliverydiretopedidostatus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretopedidostatus ALTER COLUMN id SET DEFAULT nextval('public.integracaodeliverydiretopedidostatus_id_seq'::regclass);


--
-- Name: integracaodeliverydiretowebhookinbox id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretowebhookinbox ALTER COLUMN id SET DEFAULT nextval('public.integracaodeliverydiretowebhookinbox_id_seq'::regclass);


--
-- Name: integracaoifoodconciliacao id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodconciliacao ALTER COLUMN id SET DEFAULT nextval('public.integracaoifoodconciliacao_id_seq'::regclass);


--
-- Name: integracaoifoodfinanceiroantecipacao id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroantecipacao ALTER COLUMN id SET DEFAULT nextval('public.integracaoifoodfinanceiroantecipacao_id_seq'::regclass);


--
-- Name: integracaoifoodfinanceiroclosingitem id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroclosingitem ALTER COLUMN id SET DEFAULT nextval('public.integracaoifoodfinanceiroclosingitem_id_seq'::regclass);


--
-- Name: integracaoifoodfinanceiroevento id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroevento ALTER COLUMN id SET DEFAULT nextval('public.integracaoifoodfinanceiroevento_id_seq'::regclass);


--
-- Name: integracaoifoodfinanceiroorigem id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroorigem ALTER COLUMN id SET DEFAULT nextval('public.integracaoifoodfinanceiroorigem_id_seq'::regclass);


--
-- Name: integracaoifoodfinanceiroreconciliacao id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroreconciliacao ALTER COLUMN id SET DEFAULT nextval('public.integracaoifoodfinanceiroreconciliacao_id_seq'::regclass);


--
-- Name: integracaoifoodfinanceiroreconciliacaolinha id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroreconciliacaolinha ALTER COLUMN id SET DEFAULT nextval('public.integracaoifoodfinanceiroreconciliacaolinha_id_seq'::regclass);


--
-- Name: integracaoifoodfinanceirosettlement id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceirosettlement ALTER COLUMN id SET DEFAULT nextval('public.integracaoifoodfinanceirosettlement_id_seq'::regclass);


--
-- Name: integracaoifoodfinanceirovenda id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceirovenda ALTER COLUMN id SET DEFAULT nextval('public.integracaoifoodfinanceirovenda_id_seq'::regclass);


--
-- Name: integracaostonepagarme_charge id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaostonepagarme_charge ALTER COLUMN id SET DEFAULT nextval('public.integracaostonepagarme_charge_id_seq'::regclass);


--
-- Name: integracaostonepagarme_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaostonepagarme_log ALTER COLUMN id SET DEFAULT nextval('public.integracaostonepagarme_log_id_seq'::regclass);


--
-- Name: integracaostonepagarme_pedido id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaostonepagarme_pedido ALTER COLUMN id SET DEFAULT nextval('public.integracaostonepagarme_pedido_id_seq'::regclass);


--
-- Name: integracaostonepagarme_webhook id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaostonepagarme_webhook ALTER COLUMN id SET DEFAULT nextval('public.integracaostonepagarme_webhook_id_seq'::regclass);


--
-- Name: justificativa id_justificativa; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.justificativa ALTER COLUMN id_justificativa SET DEFAULT nextval('public.justificativa_id_justificativa_seq'::regclass);


--
-- Name: log_backup id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_backup ALTER COLUMN id SET DEFAULT nextval('public.log_backup_id_seq'::regclass);


--
-- Name: log_erro id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_erro ALTER COLUMN id SET DEFAULT nextval('public.log_erro_id_seq'::regclass);


--
-- Name: log_manifesto id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_manifesto ALTER COLUMN id SET DEFAULT nextval('public.log_manifesto_id_seq'::regclass);


--
-- Name: log_transf_mesa_comanda id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_transf_mesa_comanda ALTER COLUMN id SET DEFAULT nextval('public.log_transf_mesa_comanda_id_seq'::regclass);


--
-- Name: lotes_materiais id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lotes_materiais ALTER COLUMN id SET DEFAULT nextval('public.lotes_materiais_id_seq'::regclass);


--
-- Name: manifestacao_fiscal id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manifestacao_fiscal ALTER COLUMN id SET DEFAULT nextval('public.manifestacao_fiscal_id_seq'::regclass);


--
-- Name: materiais_log_precos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_log_precos ALTER COLUMN id SET DEFAULT nextval('public.materiais_log_precos_id_seq'::regclass);


--
-- Name: mensagem_wattsap id_mensagem; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensagem_wattsap ALTER COLUMN id_mensagem SET DEFAULT nextval('public.mensagem_wattsap_id_mensagem_seq'::regclass);


--
-- Name: movimento_estoque_composicao id_movimento_composicao; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimento_estoque_composicao ALTER COLUMN id_movimento_composicao SET DEFAULT nextval('public.movimento_estoque_composicao_id_movimento_composicao_seq'::regclass);


--
-- Name: movimento_estoque_opcional id_movimento_opcional; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimento_estoque_opcional ALTER COLUMN id_movimento_opcional SET DEFAULT nextval('public.movimento_estoque_opcional_id_movimento_opcional_seq'::regclass);


--
-- Name: movimentocontacliente id_movimento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentocontacliente ALTER COLUMN id_movimento SET DEFAULT nextval('public.movimentocontacliente_id_movimento_seq'::regclass);


--
-- Name: movimentocontacorrente id_movimento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentocontacorrente ALTER COLUMN id_movimento SET DEFAULT nextval('public.movimentocontacorrente_id_movimento_seq'::regclass);


--
-- Name: movimentoestoque id_movimento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentoestoque ALTER COLUMN id_movimento SET DEFAULT nextval('public.movimentoestoque_id_movimento_seq'::regclass);


--
-- Name: nfce_contingencia_erros id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nfce_contingencia_erros ALTER COLUMN id SET DEFAULT nextval('public.nfce_contingencia_erros_id_seq'::regclass);


--
-- Name: nota_entrada id_nota_entrada; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada ALTER COLUMN id_nota_entrada SET DEFAULT nextval('public.nota_entrada_id_nota_entrada_seq'::regclass);


--
-- Name: nota_saida id_nota_saida; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida ALTER COLUMN id_nota_saida SET DEFAULT nextval('public.nota_saida_id_nota_saida_seq'::regclass);


--
-- Name: opcional id_opcional; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opcional ALTER COLUMN id_opcional SET DEFAULT nextval('public.opcional_id_opcional_seq'::regclass);


--
-- Name: pagamentoonline id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagamentoonline ALTER COLUMN id SET DEFAULT nextval('public.pagamentoonline_id_seq'::regclass);


--
-- Name: promocao id_promocao; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promocao ALTER COLUMN id_promocao SET DEFAULT nextval('public.promocao_id_promocao_seq'::regclass);


--
-- Name: resposta_food id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resposta_food ALTER COLUMN id SET DEFAULT nextval('public.resposta_food_id_seq'::regclass);


--
-- Name: resposta_menu id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resposta_menu ALTER COLUMN id SET DEFAULT nextval('public.resposta_menu_id_seq'::regclass);


--
-- Name: resposta_zap id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resposta_zap ALTER COLUMN id SET DEFAULT nextval('public.resposta_zap_id_seq'::regclass);


--
-- Name: sessao_wattsap id_sessao; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessao_wattsap ALTER COLUMN id_sessao SET DEFAULT nextval('public.sessao_wattsap_id_sessao_seq'::regclass);


--
-- Name: tipo_movimento id_movimento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_movimento ALTER COLUMN id_movimento SET DEFAULT nextval('public.tipo_movimento_id_movimento_seq'::regclass);


--
-- Name: transf_rp_food_menu id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transf_rp_food_menu ALTER COLUMN id SET DEFAULT nextval('public.transf_rp_food_menu_id_seq'::regclass);


--
-- Name: transf_rpcheff_cloud id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transf_rpcheff_cloud ALTER COLUMN id SET DEFAULT nextval('public.transf_rpcheff_cloud_id_seq'::regclass);


--
-- Name: venda_pag_antecipado id_venda_pag_antecipado; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda_pag_antecipado ALTER COLUMN id_venda_pag_antecipado SET DEFAULT nextval('public.venda_pag_antecipado_id_venda_pag_antecipado_seq'::regclass);


--
-- Name: venda_pre_pago id_pre; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda_pre_pago ALTER COLUMN id_pre SET DEFAULT nextval('public.venda_pre_pago_id_pre_seq'::regclass);


--
-- Name: aliquotas_fcp_uf aliquotas_fcp_uf_cuf_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aliquotas_fcp_uf
    ADD CONSTRAINT aliquotas_fcp_uf_cuf_key UNIQUE (cuf);


--
-- Name: aliquotas_fcp_uf aliquotas_fcp_uf_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aliquotas_fcp_uf
    ADD CONSTRAINT aliquotas_fcp_uf_pkey PRIMARY KEY (id);


--
-- Name: aliquotas_fcp_uf aliquotas_fcp_uf_uf_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aliquotas_fcp_uf
    ADD CONSTRAINT aliquotas_fcp_uf_uf_key UNIQUE (uf);


--
-- Name: cadastro_cliente_pedizap cadastro_cliente_pedizap_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cadastro_cliente_pedizap
    ADD CONSTRAINT cadastro_cliente_pedizap_pkey PRIMARY KEY (id);


--
-- Name: cfop cfop_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cfop
    ADD CONSTRAINT cfop_pkey PRIMARY KEY (cfop_codigo);


--
-- Name: configuracao_certificado_digital configuracao_certificado_digital_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracao_certificado_digital
    ADD CONSTRAINT configuracao_certificado_digital_pkey PRIMARY KEY (id);


--
-- Name: configuracao_funcionamento configuracao_funcionamento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracao_funcionamento
    ADD CONSTRAINT configuracao_funcionamento_pkey PRIMARY KEY (id);


--
-- Name: configuracao_rpfood configuracao_rpfood_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracao_rpfood
    ADD CONSTRAINT configuracao_rpfood_pkey PRIMARY KEY (id);


--
-- Name: configuracao_wattsap configuracao_wattsap_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracao_wattsap
    ADD CONSTRAINT configuracao_wattsap_pkey PRIMARY KEY (id_configuracao);


--
-- Name: configuracaopagamentomercadopago configuracaopagamentomercadopago_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracaopagamentomercadopago
    ADD CONSTRAINT configuracaopagamentomercadopago_pkey PRIMARY KEY (id, id_empresa);


--
-- Name: dfe_classtrib_rt dfe_classtrib_rt_classtrib_uk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dfe_classtrib_rt
    ADD CONSTRAINT dfe_classtrib_rt_classtrib_uk UNIQUE (classtrib);


--
-- Name: dfe_classtrib_rt dfe_classtrib_rt_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dfe_classtrib_rt
    ADD CONSTRAINT dfe_classtrib_rt_pkey PRIMARY KEY (id);


--
-- Name: dfe_cst_rt dfe_cst_rt_cst_ibs_cbs_uk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dfe_cst_rt
    ADD CONSTRAINT dfe_cst_rt_cst_ibs_cbs_uk UNIQUE (cst_ibs_cbs);


--
-- Name: dfe_cst_rt dfe_cst_rt_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dfe_cst_rt
    ADD CONSTRAINT dfe_cst_rt_pkey PRIMARY KEY (id_cst_ibs_cbs);


--
-- Name: dfe_tipo_nfe_creddeb_rt dfe_tipo_nfe_creddeb_rt_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dfe_tipo_nfe_creddeb_rt
    ADD CONSTRAINT dfe_tipo_nfe_creddeb_rt_pkey PRIMARY KEY (dominio, codigo, inicio_vigencia);


--
-- Name: contacorrente fk_contacorrente; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacorrente
    ADD CONSTRAINT fk_contacorrente PRIMARY KEY (id_contacorrente, id_empresa);


--
-- Name: impressaoproducao impressaoproducao_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impressaoproducao
    ADD CONSTRAINT impressaoproducao_pkey PRIMARY KEY (id);


--
-- Name: inner_catraca inner_catraca_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inner_catraca
    ADD CONSTRAINT inner_catraca_pkey PRIMARY KEY (inner_numero);


--
-- Name: integracao99foodconfig integracao99foodconfig_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodconfig
    ADD CONSTRAINT integracao99foodconfig_pkey PRIMARY KEY (id);


--
-- Name: integracao99foodfila integracao99foodfila_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodfila
    ADD CONSTRAINT integracao99foodfila_pkey PRIMARY KEY (id);


--
-- Name: integracao99foodfinanceirobill integracao99foodfinanceirobill_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodfinanceirobill
    ADD CONSTRAINT integracao99foodfinanceirobill_pkey PRIMARY KEY (id);


--
-- Name: integracao99foodfinanceirosettlement integracao99foodfinanceirosettlement_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodfinanceirosettlement
    ADD CONSTRAINT integracao99foodfinanceirosettlement_pkey PRIMARY KEY (id);


--
-- Name: integracao99foodhttplog integracao99foodhttplog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodhttplog
    ADD CONSTRAINT integracao99foodhttplog_pkey PRIMARY KEY (id);


--
-- Name: integracao99foodloja integracao99foodloja_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodloja
    ADD CONSTRAINT integracao99foodloja_pkey PRIMARY KEY (id);


--
-- Name: integracao99foodpedido integracao99foodpedido_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedido
    ADD CONSTRAINT integracao99foodpedido_pkey PRIMARY KEY (id);


--
-- Name: integracao99foodpedidocliente integracao99foodpedidocliente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidocliente
    ADD CONSTRAINT integracao99foodpedidocliente_pkey PRIMARY KEY (id);


--
-- Name: integracao99foodpedidoendereco integracao99foodpedidoendereco_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidoendereco
    ADD CONSTRAINT integracao99foodpedidoendereco_pkey PRIMARY KEY (id);


--
-- Name: integracao99foodpedidoitem integracao99foodpedidoitem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidoitem
    ADD CONSTRAINT integracao99foodpedidoitem_pkey PRIMARY KEY (id);


--
-- Name: integracao99foodpedidoopcional integracao99foodpedidoopcional_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidoopcional
    ADD CONSTRAINT integracao99foodpedidoopcional_pkey PRIMARY KEY (id);


--
-- Name: integracao99foodpedidopagamento integracao99foodpedidopagamento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidopagamento
    ADD CONSTRAINT integracao99foodpedidopagamento_pkey PRIMARY KEY (id);


--
-- Name: integracao99foodpedidostatus integracao99foodpedidostatus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidostatus
    ADD CONSTRAINT integracao99foodpedidostatus_pkey PRIMARY KEY (id);


--
-- Name: integracao99foodwebhooklog integracao99foodwebhooklog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodwebhooklog
    ADD CONSTRAINT integracao99foodwebhooklog_pkey PRIMARY KEY (id);


--
-- Name: integracaoanotaaicheckpoint integracaoanotaaicheckpoint_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaicheckpoint
    ADD CONSTRAINT integracaoanotaaicheckpoint_pkey PRIMARY KEY (id);


--
-- Name: integracaoanotaaiconfig integracaoanotaaiconfig_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaiconfig
    ADD CONSTRAINT integracaoanotaaiconfig_pkey PRIMARY KEY (id);


--
-- Name: integracaoanotaaihttplog integracaoanotaaihttplog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaihttplog
    ADD CONSTRAINT integracaoanotaaihttplog_pkey PRIMARY KEY (id);


--
-- Name: integracaoanotaaiinbox integracaoanotaaiinbox_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaiinbox
    ADD CONSTRAINT integracaoanotaaiinbox_pkey PRIMARY KEY (id);


--
-- Name: integracaoanotaaimenusync integracaoanotaaimenusync_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaimenusync
    ADD CONSTRAINT integracaoanotaaimenusync_pkey PRIMARY KEY (id);


--
-- Name: integracaoanotaaioutbox integracaoanotaaioutbox_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaioutbox
    ADD CONSTRAINT integracaoanotaaioutbox_pkey PRIMARY KEY (id);


--
-- Name: integracaoanotaaipedido integracaoanotaaipedido_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaipedido
    ADD CONSTRAINT integracaoanotaaipedido_pkey PRIMARY KEY (id);


--
-- Name: integracaoanotaaipedidoitem integracaoanotaaipedidoitem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaipedidoitem
    ADD CONSTRAINT integracaoanotaaipedidoitem_pkey PRIMARY KEY (id);


--
-- Name: integracaoanotaaipedidoopcional integracaoanotaaipedidoopcional_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaipedidoopcional
    ADD CONSTRAINT integracaoanotaaipedidoopcional_pkey PRIMARY KEY (id);


--
-- Name: integracaoanotaaipedidostatus integracaoanotaaipedidostatus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaipedidostatus
    ADD CONSTRAINT integracaoanotaaipedidostatus_pkey PRIMARY KEY (id);


--
-- Name: integracaodeliverydiretocatalogomapa integracaodeliverydiretocatalogomapa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretocatalogomapa
    ADD CONSTRAINT integracaodeliverydiretocatalogomapa_pkey PRIMARY KEY (id);


--
-- Name: integracaodeliverydiretocheckpoint integracaodeliverydiretocheckpoint_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretocheckpoint
    ADD CONSTRAINT integracaodeliverydiretocheckpoint_pkey PRIMARY KEY (id);


--
-- Name: integracaodeliverydiretoconfig integracaodeliverydiretoconfig_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretoconfig
    ADD CONSTRAINT integracaodeliverydiretoconfig_pkey PRIMARY KEY (id);


--
-- Name: integracaodeliverydiretohttplog integracaodeliverydiretohttplog_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretohttplog
    ADD CONSTRAINT integracaodeliverydiretohttplog_pkey PRIMARY KEY (id);


--
-- Name: integracaodeliverydiretooutbox integracaodeliverydiretooutbox_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretooutbox
    ADD CONSTRAINT integracaodeliverydiretooutbox_pkey PRIMARY KEY (id);


--
-- Name: integracaodeliverydiretopedido integracaodeliverydiretopedido_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretopedido
    ADD CONSTRAINT integracaodeliverydiretopedido_pkey PRIMARY KEY (id);


--
-- Name: integracaodeliverydiretopedidoitem integracaodeliverydiretopedidoitem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretopedidoitem
    ADD CONSTRAINT integracaodeliverydiretopedidoitem_pkey PRIMARY KEY (id);


--
-- Name: integracaodeliverydiretopedidoopcional integracaodeliverydiretopedidoopcional_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretopedidoopcional
    ADD CONSTRAINT integracaodeliverydiretopedidoopcional_pkey PRIMARY KEY (id);


--
-- Name: integracaodeliverydiretopedidostatus integracaodeliverydiretopedidostatus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretopedidostatus
    ADD CONSTRAINT integracaodeliverydiretopedidostatus_pkey PRIMARY KEY (id);


--
-- Name: integracaodeliverydiretowebhookinbox integracaodeliverydiretowebhookinbox_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretowebhookinbox
    ADD CONSTRAINT integracaodeliverydiretowebhookinbox_pkey PRIMARY KEY (id);


--
-- Name: integracaoifoodfinanceiroantecipacao integracaoifoodfinanceiroantecipacao_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroantecipacao
    ADD CONSTRAINT integracaoifoodfinanceiroantecipacao_pkey PRIMARY KEY (id);


--
-- Name: integracaoifoodfinanceiroclosingitem integracaoifoodfinanceiroclosingitem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroclosingitem
    ADD CONSTRAINT integracaoifoodfinanceiroclosingitem_pkey PRIMARY KEY (id);


--
-- Name: integracaoifoodfinanceiroevento integracaoifoodfinanceiroevento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroevento
    ADD CONSTRAINT integracaoifoodfinanceiroevento_pkey PRIMARY KEY (id);


--
-- Name: integracaoifoodfinanceiroorigem integracaoifoodfinanceiroorigem_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroorigem
    ADD CONSTRAINT integracaoifoodfinanceiroorigem_pkey PRIMARY KEY (id);


--
-- Name: integracaoifoodfinanceiroreconciliacao integracaoifoodfinanceiroreconciliacao_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroreconciliacao
    ADD CONSTRAINT integracaoifoodfinanceiroreconciliacao_pkey PRIMARY KEY (id);


--
-- Name: integracaoifoodfinanceiroreconciliacaolinha integracaoifoodfinanceiroreconciliacaolinha_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroreconciliacaolinha
    ADD CONSTRAINT integracaoifoodfinanceiroreconciliacaolinha_pkey PRIMARY KEY (id);


--
-- Name: integracaoifoodfinanceirosettlement integracaoifoodfinanceirosettlement_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceirosettlement
    ADD CONSTRAINT integracaoifoodfinanceirosettlement_pkey PRIMARY KEY (id);


--
-- Name: integracaoifoodfinanceirovenda integracaoifoodfinanceirovenda_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceirovenda
    ADD CONSTRAINT integracaoifoodfinanceirovenda_pkey PRIMARY KEY (id);


--
-- Name: mensagem_wattsap mensagem_wattsap_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensagem_wattsap
    ADD CONSTRAINT mensagem_wattsap_pkey PRIMARY KEY (id_mensagem);


--
-- Name: migrations_info migrations_info_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations_info
    ADD CONSTRAINT migrations_info_pkey PRIMARY KEY (sequence);


--
-- Name: movimentoestoque movimentoestoque_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentoestoque
    ADD CONSTRAINT movimentoestoque_pkey PRIMARY KEY (id_movimento, id_empresa);


--
-- Name: pedidoitensextras_pedzap pedidoitensextras_pedzap_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidoitensextras_pedzap
    ADD CONSTRAINT pedidoitensextras_pedzap_pkey PRIMARY KEY (id);


--
-- Name: pedidos_pedzap pedidos_pedzap_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos_pedzap
    ADD CONSTRAINT pedidos_pedzap_pkey PRIMARY KEY (id);


--
-- Name: pedidositens_pedzap pedidositens_pedzap_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidositens_pedzap
    ADD CONSTRAINT pedidositens_pedzap_pkey PRIMARY KEY (id);


--
-- Name: aliquotas pk_aliquota; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aliquotas
    ADD CONSTRAINT pk_aliquota PRIMARY KEY (id);


--
-- Name: ambiente pk_ambiente; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ambiente
    ADD CONSTRAINT pk_ambiente PRIMARY KEY (id_ambiente);


--
-- Name: bairro pk_bairro; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bairro
    ADD CONSTRAINT pk_bairro PRIMARY KEY (bai_001, emp_001);


--
-- Name: bairro_ceps pk_bairro_ceps; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bairro_ceps
    ADD CONSTRAINT pk_bairro_ceps PRIMARY KEY (bai_001, emp_001, cep);


--
-- Name: beneficios pk_beneficios; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficios
    ADD CONSTRAINT pk_beneficios PRIMARY KEY (ben_001, emp_001);


--
-- Name: bot_sinonimo pk_bot_sinonimo; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_sinonimo
    ADD CONSTRAINT pk_bot_sinonimo PRIMARY KEY (id_empresa, termo);


--
-- Name: caixa pk_caixa; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixa
    ADD CONSTRAINT pk_caixa PRIMARY KEY (id_caixa, id_empresa);


--
-- Name: caixainformado pk_caixainformado; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixainformado
    ADD CONSTRAINT pk_caixainformado PRIMARY KEY (id_caixa, id_empresa, id_formapgto);


--
-- Name: caixaitem pk_caixaitem; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixaitem
    ADD CONSTRAINT pk_caixaitem PRIMARY KEY (id_caixa, id_empresa, item);


--
-- Name: categoria pk_categoria; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT pk_categoria PRIMARY KEY (cat_001, emp_001);


--
-- Name: categoria_opcionais pk_categoria_opcionais; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categoria_opcionais
    ADD CONSTRAINT pk_categoria_opcionais PRIMARY KEY (id, emp_001);


--
-- Name: catraca_mobile pk_catraca_mobile; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catraca_mobile
    ADD CONSTRAINT pk_catraca_mobile PRIMARY KEY (id, id_empresa);


--
-- Name: ceps pk_ceps; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ceps
    ADD CONSTRAINT pk_ceps PRIMARY KEY (cep_002);


--
-- Name: cidades pk_cidades; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cidades
    ADD CONSTRAINT pk_cidades PRIMARY KEY (cid_001);


--
-- Name: cidades_temp_ibge pk_cidades_temp_ibge; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cidades_temp_ibge
    ADD CONSTRAINT pk_cidades_temp_ibge PRIMARY KEY (cid_003);


--
-- Name: cidades_transf pk_cidades_trans; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cidades_transf
    ADD CONSTRAINT pk_cidades_trans PRIMARY KEY (cid_001);


--
-- Name: clientes pk_clientes; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT pk_clientes PRIMARY KEY (cli_001, emp_001);


--
-- Name: clientes_endereco pk_clientes_endereco; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_endereco
    ADD CONSTRAINT pk_clientes_endereco PRIMARY KEY (id_endereco, emp_001);


--
-- Name: comanda pk_comanda; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comanda
    ADD CONSTRAINT pk_comanda PRIMARY KEY (com_001, emp_001);


--
-- Name: composicao pk_composicao; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composicao
    ADD CONSTRAINT pk_composicao PRIMARY KEY (id_composicao, id_empresa);


--
-- Name: composicao_fornecedor pk_composicao_fornecedor; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composicao_fornecedor
    ADD CONSTRAINT pk_composicao_fornecedor PRIMARY KEY (id_composicao, id_empresa, id_fornecedor, codigo_fornecedor);


--
-- Name: condicaopagamento pk_condicaopagamento; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.condicaopagamento
    ADD CONSTRAINT pk_condicaopagamento PRIMARY KEY (id_condicaopagamento, id_empresa);


--
-- Name: condicaopagamentoparcela pk_condicaopagamentoparcela; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.condicaopagamentoparcela
    ADD CONSTRAINT pk_condicaopagamentoparcela PRIMARY KEY (id_condicaopagamento, id_empresa, nro_parcela);


--
-- Name: configuracaopagamentobarte pk_configuracaopix; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracaopagamentobarte
    ADD CONSTRAINT pk_configuracaopix PRIMARY KEY (id, id_empresa);


--
-- Name: conta pk_conta; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conta
    ADD CONSTRAINT pk_conta PRIMARY KEY (id_conta, id_empresa);


--
-- Name: cpagar pk_cpagar; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cpagar
    ADD CONSTRAINT pk_cpagar PRIMARY KEY (id_cpagar, id_empresa);


--
-- Name: cpagar_parcela pk_cpagar_parcela_empresa; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cpagar_parcela
    ADD CONSTRAINT pk_cpagar_parcela_empresa PRIMARY KEY (id_cpagar, id_empresa, parcela);


--
-- Name: creceber pk_creceber; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creceber
    ADD CONSTRAINT pk_creceber PRIMARY KEY (id_creceber, id_empresa);


--
-- Name: creceber_parcela pk_creceber_parcela; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creceber_parcela
    ADD CONSTRAINT pk_creceber_parcela PRIMARY KEY (id_creceber, id_empresa, parcela);


--
-- Name: ctrib_lotes pk_ctrib_lotes; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ctrib_lotes
    ADD CONSTRAINT pk_ctrib_lotes PRIMARY KEY (lote, id_empresa);


--
-- Name: ctrib_lotes_produtos pk_ctrib_lotes_produtos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ctrib_lotes_produtos
    ADD CONSTRAINT pk_ctrib_lotes_produtos PRIMARY KEY (lote, posicao, codprod);


--
-- Name: desc_tamanho_material pk_desc_tamanho_material; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.desc_tamanho_material
    ADD CONSTRAINT pk_desc_tamanho_material PRIMARY KEY (id_empresa);


--
-- Name: devolucaoitem pk_devolucaoitem; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devolucaoitem
    ADD CONSTRAINT pk_devolucaoitem PRIMARY KEY (id_devolucaoitem);


--
-- Name: empresas pk_empresas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empresas
    ADD CONSTRAINT pk_empresas PRIMARY KEY (emp_001);


--
-- Name: encerravenda pk_encerravenda; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encerravenda
    ADD CONSTRAINT pk_encerravenda PRIMARY KEY (enc_001, emp_001);


--
-- Name: encerravendaitem pk_encerravendaitem; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encerravendaitem
    ADD CONSTRAINT pk_encerravendaitem PRIMARY KEY (emp_001, enc_001, ite_001);


--
-- Name: estados pk_estados; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estados
    ADD CONSTRAINT pk_estados PRIMARY KEY (est_001);


--
-- Name: eventos pk_eventos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos
    ADD CONSTRAINT pk_eventos PRIMARY KEY (id_evento, emp_001);


--
-- Name: eventos_detalhes_nfe_rt pk_eventos_detalhes_nfe_rt; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_detalhes_nfe_rt
    ADD CONSTRAINT pk_eventos_detalhes_nfe_rt PRIMARY KEY (id, id_evento, id_empresa);


--
-- Name: eventos_mesas pk_eventos_mesas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_mesas
    ADD CONSTRAINT pk_eventos_mesas PRIMARY KEY (id_evento, emp_001, numero_mesa);


--
-- Name: eventos_nfe_rt pk_eventos_nfe_rt; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_nfe_rt
    ADD CONSTRAINT pk_eventos_nfe_rt PRIMARY KEY (id, id_empresa);


--
-- Name: execucoes_estoque_item pk_ex_item; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.execucoes_estoque_item
    ADD CONSTRAINT pk_ex_item PRIMARY KEY (id_mestre, item, id_empresa);


--
-- Name: execucoes_estoque pk_execucoes_estoque; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.execucoes_estoque
    ADD CONSTRAINT pk_execucoes_estoque PRIMARY KEY (id, id_empresa);


--
-- Name: formapgto pk_formapgto; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.formapgto
    ADD CONSTRAINT pk_formapgto PRIMARY KEY (for_001, emp_001);


--
-- Name: fornecedor pk_fornecedor; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fornecedor
    ADD CONSTRAINT pk_fornecedor PRIMARY KEY (id_fornecedor, id_empresa);


--
-- Name: galeria_imagens pk_galeria_imagens; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.galeria_imagens
    ADD CONSTRAINT pk_galeria_imagens PRIMARY KEY (gal_001, emp_001);


--
-- Name: integracaoifoodconciliacao pk_ifood_conciliacao; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodconciliacao
    ADD CONSTRAINT pk_ifood_conciliacao PRIMARY KEY (id);


--
-- Name: ifood_merchants pk_ifood_merchants; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ifood_merchants
    ADD CONSTRAINT pk_ifood_merchants PRIMARY KEY (mer_001, emp_001);


--
-- Name: ifood_pedidos pk_ifood_pedidos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ifood_pedidos
    ADD CONSTRAINT pk_ifood_pedidos PRIMARY KEY (correlationid);


--
-- Name: ifood_rejeitados pk_ifood_rejeitados_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ifood_rejeitados
    ADD CONSTRAINT pk_ifood_rejeitados_id PRIMARY KEY (id);


--
-- Name: balanca_info_extra pk_info_extra; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.balanca_info_extra
    ADD CONSTRAINT pk_info_extra PRIMARY KEY (inf_001, emp_001);


--
-- Name: balanca_info_nutri pk_info_nutri; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.balanca_info_nutri
    ADD CONSTRAINT pk_info_nutri PRIMARY KEY (nut_001, emp_001);


--
-- Name: integracaostonepagarme pk_integracaostonepagarme; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaostonepagarme
    ADD CONSTRAINT pk_integracaostonepagarme PRIMARY KEY (cnpj);


--
-- Name: integracaostonepagarme_charge pk_integracaostonepagarme_charge; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaostonepagarme_charge
    ADD CONSTRAINT pk_integracaostonepagarme_charge PRIMARY KEY (id);


--
-- Name: integracaostonepagarme_log pk_integracaostonepagarme_log; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaostonepagarme_log
    ADD CONSTRAINT pk_integracaostonepagarme_log PRIMARY KEY (id);


--
-- Name: integracaostonepagarme_pedido pk_integracaostonepagarme_pedido; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaostonepagarme_pedido
    ADD CONSTRAINT pk_integracaostonepagarme_pedido PRIMARY KEY (id);


--
-- Name: integracaostonepagarme_webhook pk_integracaostonepagarme_webhook; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaostonepagarme_webhook
    ADD CONSTRAINT pk_integracaostonepagarme_webhook PRIMARY KEY (id);


--
-- Name: lista_servicos_iss pk_iss; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lista_servicos_iss
    ADD CONSTRAINT pk_iss PRIMARY KEY (codigo);


--
-- Name: justificativa pk_justificativa; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.justificativa
    ADD CONSTRAINT pk_justificativa PRIMARY KEY (id_justificativa);


--
-- Name: lista_acessos pk_lista_acessos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lista_acessos
    ADD CONSTRAINT pk_lista_acessos PRIMARY KEY (acs_001);


--
-- Name: log_transf_mesa_comanda pk_log_transf_mesa_comanda; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_transf_mesa_comanda
    ADD CONSTRAINT pk_log_transf_mesa_comanda PRIMARY KEY (id);


--
-- Name: lotes_materiais pk_lote_materiais; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lotes_materiais
    ADD CONSTRAINT pk_lote_materiais PRIMARY KEY (id, id_empresa);


--
-- Name: materiais pk_materiais; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais
    ADD CONSTRAINT pk_materiais PRIMARY KEY (mat_001, emp_001);


--
-- Name: materiais_combo pk_materiais_combo; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_combo
    ADD CONSTRAINT pk_materiais_combo PRIMARY KEY (id_material, id_empresa, id_produto_combo);


--
-- Name: materiais_composicao pk_materiais_composicao; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_composicao
    ADD CONSTRAINT pk_materiais_composicao PRIMARY KEY (id_material, id_empresa, id_composicao);


--
-- Name: materiais_fornecedor pk_materiais_fornecedor; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_fornecedor
    ADD CONSTRAINT pk_materiais_fornecedor PRIMARY KEY (id_material, id_empresa, id_fornecedor, codigo_fornecedor);


--
-- Name: materiais_lista_fornecedores pk_materiais_lista; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_lista_fornecedores
    ADD CONSTRAINT pk_materiais_lista PRIMARY KEY (id_material, id_empresa, id_fornecedor);


--
-- Name: materiais_log_precos pk_materiais_log_precos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_log_precos
    ADD CONSTRAINT pk_materiais_log_precos PRIMARY KEY (id);


--
-- Name: materiais_opcional pk_materiais_opcional; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_opcional
    ADD CONSTRAINT pk_materiais_opcional PRIMARY KEY (id_material, id_empresa, id_opcional);


--
-- Name: mesa pk_mesa; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mesa
    ADD CONSTRAINT pk_mesa PRIMARY KEY (mes_001, emp_001);


--
-- Name: movimentocontacliente pk_movimentocontacliente; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentocontacliente
    ADD CONSTRAINT pk_movimentocontacliente PRIMARY KEY (id_movimento, id_empresa);


--
-- Name: movimentocontacorrente pk_movimentocontacorrente; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentocontacorrente
    ADD CONSTRAINT pk_movimentocontacorrente PRIMARY KEY (id_movimento, id_empresa);


--
-- Name: ncm_nbs_cclasstrib pk_ncm_nbs_cclasstrib; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ncm_nbs_cclasstrib
    ADD CONSTRAINT pk_ncm_nbs_cclasstrib PRIMARY KEY (ncm_nbs, regra_rtc, id_participante);


--
-- Name: nfce_contingencia_erros pk_nfce_contingencia_erros; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nfce_contingencia_erros
    ADD CONSTRAINT pk_nfce_contingencia_erros PRIMARY KEY (id);


--
-- Name: nfce_inutilizada pk_nfce_inutilizada; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nfce_inutilizada
    ADD CONSTRAINT pk_nfce_inutilizada PRIMARY KEY (numero, serie, modelo);


--
-- Name: nota_entrada pk_nota_entrada; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada
    ADD CONSTRAINT pk_nota_entrada PRIMARY KEY (id_nota_entrada, id_empresa);


--
-- Name: nota_entrada_doc_referenciado pk_nota_entrada_doc_referenciado; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada_doc_referenciado
    ADD CONSTRAINT pk_nota_entrada_doc_referenciado PRIMARY KEY (id_nota_entrada, item);


--
-- Name: nota_entrada_duplicata pk_nota_entrada_duplicata; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada_duplicata
    ADD CONSTRAINT pk_nota_entrada_duplicata PRIMARY KEY (id_nota_entrada, item);


--
-- Name: nota_entrada_item pk_nota_entrada_item; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada_item
    ADD CONSTRAINT pk_nota_entrada_item PRIMARY KEY (id_nota_entrada, item);


--
-- Name: nota_saida pk_nota_saida; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida
    ADD CONSTRAINT pk_nota_saida PRIMARY KEY (id_nota_saida, id_empresa);


--
-- Name: nota_saida_doc_referenciado pk_nota_saida_doc_referenciado; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida_doc_referenciado
    ADD CONSTRAINT pk_nota_saida_doc_referenciado PRIMARY KEY (id_nota_saida, item);


--
-- Name: nota_saida_duplicata pk_nota_saida_duplicata; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida_duplicata
    ADD CONSTRAINT pk_nota_saida_duplicata PRIMARY KEY (id_nota_saida, item);


--
-- Name: nota_saida_inutilizada pk_nota_saida_inutilizada; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida_inutilizada
    ADD CONSTRAINT pk_nota_saida_inutilizada PRIMARY KEY (numero, serie, modelo);


--
-- Name: nota_saida_item pk_nota_saida_item; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida_item
    ADD CONSTRAINT pk_nota_saida_item PRIMARY KEY (id_nota_saida, item);


--
-- Name: nota_saida_pagamentos pk_nota_saida_pagamentos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida_pagamentos
    ADD CONSTRAINT pk_nota_saida_pagamentos PRIMARY KEY (id_nota_saida, item);


--
-- Name: opcional pk_opcional; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opcional
    ADD CONSTRAINT pk_opcional PRIMARY KEY (id_opcional, id_empresa);


--
-- Name: paises pk_paises; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paises
    ADD CONSTRAINT pk_paises PRIMARY KEY (pai_001);


--
-- Name: particip_ip pk_particip_ip; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.particip_ip
    ADD CONSTRAINT pk_particip_ip PRIMARY KEY (pip_001, emp_001);


--
-- Name: pedido_compra_item pk_ped_item; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_compra_item
    ADD CONSTRAINT pk_ped_item PRIMARY KEY (id_pedido, item);


--
-- Name: pedido_compra pk_pedido_compra; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_compra
    ADD CONSTRAINT pk_pedido_compra PRIMARY KEY (id, id_empresa);


--
-- Name: pedido_compra_duplicata pk_pedido_compra_duplicata; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_compra_duplicata
    ADD CONSTRAINT pk_pedido_compra_duplicata PRIMARY KEY (id_pedido, item);


--
-- Name: perfil_consumo pk_perfil_consumo; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfil_consumo
    ADD CONSTRAINT pk_perfil_consumo PRIMARY KEY (id_perfil_consumo);


--
-- Name: promocao pk_promocao; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promocao
    ADD CONSTRAINT pk_promocao PRIMARY KEY (id_promocao, id_empresa);


--
-- Name: resposta_food pk_resposta_food_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resposta_food
    ADD CONSTRAINT pk_resposta_food_id PRIMARY KEY (id, emp_001);


--
-- Name: resposta_menu pk_resposta_menu_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resposta_menu
    ADD CONSTRAINT pk_resposta_menu_id PRIMARY KEY (id, emp_001);


--
-- Name: resposta_zap pk_resposta_zap_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resposta_zap
    ADD CONSTRAINT pk_resposta_zap_id PRIMARY KEY (id, emp_001);


--
-- Name: revenda pk_revendas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revenda
    ADD CONSTRAINT pk_revendas PRIMARY KEY (cnpj);


--
-- Name: setor_estoque pk_setor; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setor_estoque
    ADD CONSTRAINT pk_setor PRIMARY KEY (id_setor, id_empresa);


--
-- Name: setor_estoque_composicao pk_setor_estoque_composicao; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setor_estoque_composicao
    ADD CONSTRAINT pk_setor_estoque_composicao PRIMARY KEY (id_composicao, id_setor, id_empresa);


--
-- Name: setor_estoque_material pk_setor_estoque_material; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setor_estoque_material
    ADD CONSTRAINT pk_setor_estoque_material PRIMARY KEY (id_material, id_setor, id_empresa);


--
-- Name: setor_estoque_opcional pk_setor_estoque_opcional; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setor_estoque_opcional
    ADD CONSTRAINT pk_setor_estoque_opcional PRIMARY KEY (id_opcional, id_setor, id_empresa);


--
-- Name: subcategoria pk_subcategoria; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subcategoria
    ADD CONSTRAINT pk_subcategoria PRIMARY KEY (sub_001, emp_001);


--
-- Name: tara pk_tara; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tara
    ADD CONSTRAINT pk_tara PRIMARY KEY (tar_001, emp_001);


--
-- Name: terminais pk_terminais; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terminais
    ADD CONSTRAINT pk_terminais PRIMARY KEY (ter_001, emp_001);


--
-- Name: tipo_movimento pk_tipo_movimento; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_movimento
    ADD CONSTRAINT pk_tipo_movimento PRIMARY KEY (id_movimento, id_empresa);


--
-- Name: transf_rp_food_menu pk_transf_rp_food_menu; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transf_rp_food_menu
    ADD CONSTRAINT pk_transf_rp_food_menu PRIMARY KEY (id, id_empresa);


--
-- Name: transf_rpcheff_cloud pk_transf_rpcheff_cloud; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transf_rpcheff_cloud
    ADD CONSTRAINT pk_transf_rpcheff_cloud PRIMARY KEY (id, id_empresa);


--
-- Name: tribut_predet pk_tribut_predet; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tribut_predet
    ADD CONSTRAINT pk_tribut_predet PRIMARY KEY (tri_id, emp_001);


--
-- Name: trocogarcom pk_trocogarcom; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trocogarcom
    ADD CONSTRAINT pk_trocogarcom PRIMARY KEY (id_caixa, id_empresa, id_usuario, id_venda);


--
-- Name: unidades pk_unidades; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unidades
    ADD CONSTRAINT pk_unidades PRIMARY KEY (emp_001, uni_001);


--
-- Name: usu_movimento pk_usu_movimento; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usu_movimento
    ADD CONSTRAINT pk_usu_movimento PRIMARY KEY (id, id_empresa);


--
-- Name: venda pk_venda; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda
    ADD CONSTRAINT pk_venda PRIMARY KEY (emp_001, ven_001);


--
-- Name: venda_pag_antecipado pk_venda_pag_antecipado; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda_pag_antecipado
    ADD CONSTRAINT pk_venda_pag_antecipado PRIMARY KEY (id_venda_pag_antecipado, id_venda, id_empresa);


--
-- Name: venda_pag_antecipado_itens pk_venda_pag_antecipado_itens; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda_pag_antecipado_itens
    ADD CONSTRAINT pk_venda_pag_antecipado_itens PRIMARY KEY (id_mestre, id_empresa, ite_001);


--
-- Name: venda_pre_pago pk_venda_pre_pago; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda_pre_pago
    ADD CONSTRAINT pk_venda_pre_pago PRIMARY KEY (id_pre);


--
-- Name: vendaitem pk_vendaitem; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendaitem
    ADD CONSTRAINT pk_vendaitem PRIMARY KEY (emp_001, ven_001, ite_001);


--
-- Name: vendaitemopcional pk_vendaitemopcional; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendaitemopcional
    ADD CONSTRAINT pk_vendaitemopcional PRIMARY KEY (id_vendaitemopcional);


--
-- Name: csosn_icms pkcsosn_icms; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.csosn_icms
    ADD CONSTRAINT pkcsosn_icms PRIMARY KEY (emp_001, cso_codigo);


--
-- Name: cst_cofins pkcst_cofins; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cst_cofins
    ADD CONSTRAINT pkcst_cofins PRIMARY KEY (emp_001, cof_codigo);


--
-- Name: cst_icms pkcst_icms; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cst_icms
    ADD CONSTRAINT pkcst_icms PRIMARY KEY (emp_001, icm_codigo);


--
-- Name: cst_ipi pkcst_ipi; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cst_ipi
    ADD CONSTRAINT pkcst_ipi PRIMARY KEY (emp_001, ipi_codigo);


--
-- Name: cst_pis pkcst_pis; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cst_pis
    ADD CONSTRAINT pkcst_pis PRIMARY KEY (emp_001, pis_codigo);


--
-- Name: modalidade_icms pkmodalidade_icms; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modalidade_icms
    ADD CONSTRAINT pkmodalidade_icms PRIMARY KEY (emp_001, mod_codigo);


--
-- Name: modalidade_icmsst pkmodalidade_icmsst; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modalidade_icmsst
    ADD CONSTRAINT pkmodalidade_icmsst PRIMARY KEY (emp_001, mst_codigo);


--
-- Name: movimento_estoque_composicao pkmovimento_estoque_composicao; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimento_estoque_composicao
    ADD CONSTRAINT pkmovimento_estoque_composicao PRIMARY KEY (id_movimento_composicao, id_empresa);


--
-- Name: movimento_estoque_opcional pkmovimento_estoque_opcional; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimento_estoque_opcional
    ADD CONSTRAINT pkmovimento_estoque_opcional PRIMARY KEY (id_movimento_opcional, id_empresa);


--
-- Name: regime_tributario pkregime_tributario; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regime_tributario
    ADD CONSTRAINT pkregime_tributario PRIMARY KEY (emp_001, crt_codigo);


--
-- Name: sat_finalizador pksat_finalizador; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sat_finalizador
    ADD CONSTRAINT pksat_finalizador PRIMARY KEY (sfi_codigo);


--
-- Name: quero_delivery_pedidos quero_delivery_pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quero_delivery_pedidos
    ADD CONSTRAINT quero_delivery_pedidos_pkey PRIMARY KEY (id_pedido);


--
-- Name: sessao_wattsap sessao_wattsap_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessao_wattsap
    ADD CONSTRAINT sessao_wattsap_pkey PRIMARY KEY (id_sessao);


--
-- Name: tribut_predet_cfop tribut_predet_cfop_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tribut_predet_cfop
    ADD CONSTRAINT tribut_predet_cfop_pkey PRIMARY KEY (tri_id, emp_001, cfop);


--
-- Name: configuracao_wattsap uq_configuracao_wattsap_empresa; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracao_wattsap
    ADD CONSTRAINT uq_configuracao_wattsap_empresa UNIQUE (id_empresa);


--
-- Name: integracaostonepagarme_charge uq_integracaostonepagarme_charge; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaostonepagarme_charge
    ADD CONSTRAINT uq_integracaostonepagarme_charge UNIQUE (id_empresa, chargeid);


--
-- Name: integracaostonepagarme_pedido uq_integracaostonepagarme_pedido_idempotency; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaostonepagarme_pedido
    ADD CONSTRAINT uq_integracaostonepagarme_pedido_idempotency UNIQUE (id_empresa, idempotencykey);


--
-- Name: integracaostonepagarme_webhook uq_integracaostonepagarme_webhook_webhookid; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaostonepagarme_webhook
    ADD CONSTRAINT uq_integracaostonepagarme_webhook_webhookid UNIQUE (webhookid);


--
-- Name: mensagem_wattsap uq_mensagem_wattsap_evento; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensagem_wattsap
    ADD CONSTRAINT uq_mensagem_wattsap_evento UNIQUE (id_empresa, instancia, message_id);


--
-- Name: sessao_wattsap uq_sessao_wattsap_cliente; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessao_wattsap
    ADD CONSTRAINT uq_sessao_wattsap_cliente UNIQUE (id_empresa, telefone);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (usu_001, emp_001);


--
-- Name: integracaoifoodconciliacaoimport ux_ifood_conc_import; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodconciliacaoimport
    ADD CONSTRAINT ux_ifood_conc_import UNIQUE (id_empresa, merchant_id, competencia);


--
-- Name: integracaoifoodfinanceiroantecipacao ux_ifood_fin_antecipacao_chave; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroantecipacao
    ADD CONSTRAINT ux_ifood_fin_antecipacao_chave UNIQUE (id_empresa, merchant_id, chave_antecipacao);


--
-- Name: integracaoifoodfinanceiroclosingitem ux_ifood_fin_closingitem_chave; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroclosingitem
    ADD CONSTRAINT ux_ifood_fin_closingitem_chave UNIQUE (id_empresa, merchant_id, chave_item);


--
-- Name: integracaoifoodfinanceiroevento ux_ifood_fin_evento_chave; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroevento
    ADD CONSTRAINT ux_ifood_fin_evento_chave UNIQUE (id_empresa, merchant_id, chave_evento);


--
-- Name: integracaoifoodfinanceiroorigem ux_ifood_fin_origem_chave; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroorigem
    ADD CONSTRAINT ux_ifood_fin_origem_chave UNIQUE (id_empresa, merchant_id, chave_origem);


--
-- Name: integracaoifoodfinanceiroreconciliacaolinha ux_ifood_fin_reclinha_chave; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroreconciliacaolinha
    ADD CONSTRAINT ux_ifood_fin_reclinha_chave UNIQUE (id_empresa, merchant_id, chave_linha);


--
-- Name: integracaoifoodfinanceiroreconciliacao ux_ifood_fin_reconciliacao_chave; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceiroreconciliacao
    ADD CONSTRAINT ux_ifood_fin_reconciliacao_chave UNIQUE (id_empresa, merchant_id, chave_reconciliacao);


--
-- Name: integracaoifoodfinanceirosettlement ux_ifood_fin_settlement_chave; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceirosettlement
    ADD CONSTRAINT ux_ifood_fin_settlement_chave UNIQUE (id_empresa, merchant_id, chave_financeira);


--
-- Name: integracaoifoodfinanceirovenda ux_ifood_fin_venda_chave; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoifoodfinanceirovenda
    ADD CONSTRAINT ux_ifood_fin_venda_chave UNIQUE (id_empresa, merchant_id, sale_id);


--
-- Name: integracao99foodconfig ux_integracao99foodconfig_empresa_appshop; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodconfig
    ADD CONSTRAINT ux_integracao99foodconfig_empresa_appshop UNIQUE (id_empresa, app_shop_id);


--
-- Name: integracao99foodfinanceirobill ux_integracao99foodfinanceirobill_chave; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodfinanceirobill
    ADD CONSTRAINT ux_integracao99foodfinanceirobill_chave UNIQUE (id_empresa, app_shop_id, chave_financeira);


--
-- Name: integracao99foodfinanceirosettlement ux_integracao99foodfinanceirosettlement_chave; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodfinanceirosettlement
    ADD CONSTRAINT ux_integracao99foodfinanceirosettlement_chave UNIQUE (id_empresa, app_shop_id, chave_financeira);


--
-- Name: integracao99foodloja ux_integracao99foodloja_empresa_appshop; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodloja
    ADD CONSTRAINT ux_integracao99foodloja_empresa_appshop UNIQUE (id_empresa, app_shop_id);


--
-- Name: integracao99foodpedido ux_integracao99foodpedido_empresa_appshop_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedido
    ADD CONSTRAINT ux_integracao99foodpedido_empresa_appshop_order UNIQUE (id_empresa, app_shop_id, order_id);


--
-- Name: integracao99foodpedidocliente ux_integracao99foodpedidocliente_empresa_appshop_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidocliente
    ADD CONSTRAINT ux_integracao99foodpedidocliente_empresa_appshop_order UNIQUE (id_empresa, app_shop_id, order_id);


--
-- Name: integracao99foodpedidoendereco ux_integracao99foodpedidoendereco_empresa_appshop_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidoendereco
    ADD CONSTRAINT ux_integracao99foodpedidoendereco_empresa_appshop_order UNIQUE (id_empresa, app_shop_id, order_id);


--
-- Name: integracao99foodpedidoitem ux_integracao99foodpedidoitem_empresa_appshop_order_item; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidoitem
    ADD CONSTRAINT ux_integracao99foodpedidoitem_empresa_appshop_order_item UNIQUE (id_empresa, app_shop_id, order_id, numero_item);


--
-- Name: integracaoanotaaicheckpoint ux_integracaoanotaaicheckpoint; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaicheckpoint
    ADD CONSTRAINT ux_integracaoanotaaicheckpoint UNIQUE (id_empresa, merchant_id, tipo);


--
-- Name: integracaoanotaaiconfig ux_integracaoanotaaiconfig_empresa_merchant_ambiente; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaiconfig
    ADD CONSTRAINT ux_integracaoanotaaiconfig_empresa_merchant_ambiente UNIQUE (id_empresa, merchant_id, ambiente);


--
-- Name: integracaoanotaaimenusync ux_integracaoanotaaimenusync_external; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaimenusync
    ADD CONSTRAINT ux_integracaoanotaaimenusync_external UNIQUE (id_empresa, merchant_id, entity_type, external_id);


--
-- Name: integracaoanotaaimenusync ux_integracaoanotaaimenusync_local; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaimenusync
    ADD CONSTRAINT ux_integracaoanotaaimenusync_local UNIQUE (id_empresa, merchant_id, entity_type, local_id);


--
-- Name: integracaoanotaaioutbox ux_integracaoanotaaioutbox_idempotency; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaioutbox
    ADD CONSTRAINT ux_integracaoanotaaioutbox_idempotency UNIQUE (id_empresa, merchant_id, idempotency_key);


--
-- Name: integracaoanotaaipedido ux_integracaoanotaaipedido_empresa_merchant_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaipedido
    ADD CONSTRAINT ux_integracaoanotaaipedido_empresa_merchant_order UNIQUE (id_empresa, merchant_id, order_id);


--
-- Name: integracaoanotaaipedidoitem ux_integracaoanotaaipedidoitem_order_item; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaipedidoitem
    ADD CONSTRAINT ux_integracaoanotaaipedidoitem_order_item UNIQUE (id_empresa, merchant_id, order_id, numero_item);


--
-- Name: integracaodeliverydiretocatalogomapa ux_integracaodeliverydiretocatalogomapa_external; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretocatalogomapa
    ADD CONSTRAINT ux_integracaodeliverydiretocatalogomapa_external UNIQUE (id_empresa, delivery_direto_id, entity_type, external_id);


--
-- Name: integracaodeliverydiretocatalogomapa ux_integracaodeliverydiretocatalogomapa_local; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretocatalogomapa
    ADD CONSTRAINT ux_integracaodeliverydiretocatalogomapa_local UNIQUE (id_empresa, delivery_direto_id, entity_type, local_id);


--
-- Name: integracaodeliverydiretocheckpoint ux_integracaodeliverydiretocheckpoint; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretocheckpoint
    ADD CONSTRAINT ux_integracaodeliverydiretocheckpoint UNIQUE (id_empresa, delivery_direto_id, tipo);


--
-- Name: integracaodeliverydiretoconfig ux_integracaodeliverydiretoconfig_empresa_loja_ambiente; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretoconfig
    ADD CONSTRAINT ux_integracaodeliverydiretoconfig_empresa_loja_ambiente UNIQUE (id_empresa, delivery_direto_id, ambiente);


--
-- Name: integracaodeliverydiretooutbox ux_integracaodeliverydiretooutbox_idempotency; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretooutbox
    ADD CONSTRAINT ux_integracaodeliverydiretooutbox_idempotency UNIQUE (id_empresa, delivery_direto_id, idempotency_key);


--
-- Name: integracaodeliverydiretopedido ux_integracaodeliverydiretopedido_empresa_loja_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretopedido
    ADD CONSTRAINT ux_integracaodeliverydiretopedido_empresa_loja_order UNIQUE (id_empresa, delivery_direto_id, order_id);


--
-- Name: integracaodeliverydiretopedidoitem ux_integracaodeliverydiretopedidoitem_order_item; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretopedidoitem
    ADD CONSTRAINT ux_integracaodeliverydiretopedidoitem_order_item UNIQUE (id_empresa, delivery_direto_id, order_id, numero_item);


--
-- Name: zz_migration zz_migration_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zz_migration
    ADD CONSTRAINT zz_migration_pkey PRIMARY KEY (idmigration);


--
-- Name: dfe_classtrib_rt_cst_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX dfe_classtrib_rt_cst_idx ON public.dfe_classtrib_rt USING btree (cst);


--
-- Name: idx_bairro_bai_002_trgm2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bairro_bai_002_trgm2 ON public.bairro USING gin (regexp_replace(translate(lower((bai_002)::text), 'áàâãäéèêëíìîïóòôõöúùûüç'::text, 'aaaaaeeeeiiiiooooouuuuc'::text), '[^a-z0-9 ]+'::text, ' '::text, 'g'::text) public.gin_trgm_ops);


--
-- Name: idx_bairro_bot_wattsap_descricao; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bairro_bot_wattsap_descricao ON public.bairro USING btree (emp_001, translate(lower((bai_002)::text), 'áàâãäéèêëíìîïóòôõöúùûüç'::text, 'aaaaaeeeeiiiiooooouuuuc'::text) varchar_pattern_ops) WHERE (sit_001 = 4);


--
-- Name: idx_bairro_ceps_bot_wattsap_cep; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bairro_ceps_bot_wattsap_cep ON public.bairro_ceps USING btree (emp_001, regexp_replace((COALESCE(cep, ''::character varying))::text, '[^0-9]'::text, ''::text, 'g'::text));


--
-- Name: idx_bot_sinonimo_empresa_ativo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bot_sinonimo_empresa_ativo ON public.bot_sinonimo USING btree (id_empresa, ativo);


--
-- Name: idx_caixa_empresa_situacao_data_terminal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_caixa_empresa_situacao_data_terminal ON public.caixa USING btree (id_empresa, id_situacao, data_abertura DESC, hora_abertura DESC, terminal);


--
-- Name: idx_caixaitem_empresa_caixa_tipo_classif_ant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_caixaitem_empresa_caixa_tipo_classif_ant ON public.caixaitem USING btree (id_empresa, id_caixa, tipo_movimento, classificacao, antecipado);


--
-- Name: idx_caixaitem_empresa_forma; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_caixaitem_empresa_forma ON public.caixaitem USING btree (id_empresa, id_formapgto);


--
-- Name: idx_caixaitem_empresa_venda; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_caixaitem_empresa_venda ON public.caixaitem USING btree (id_empresa, id_venda);


--
-- Name: idx_clientes_bot_wattsap_celular1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clientes_bot_wattsap_celular1 ON public.clientes USING btree (emp_001, regexp_replace((COALESCE(celular1, ''::character varying))::text, '\D'::text, ''::text, 'g'::text)) WHERE (sit_001 = 4);


--
-- Name: idx_clientes_bot_wattsap_celular2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clientes_bot_wattsap_celular2 ON public.clientes USING btree (emp_001, regexp_replace((COALESCE(celular2, ''::character varying))::text, '\D'::text, ''::text, 'g'::text)) WHERE (sit_001 = 4);


--
-- Name: idx_clientes_pedzap_origem; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clientes_pedzap_origem ON public.clientes USING btree (emp_001, id_pedzap) WHERE ((upper(TRIM(BOTH FROM COALESCE(origem_integracao, ''::character varying))) = 'PEDZAP'::text) AND (id_pedzap IS NOT NULL));


--
-- Name: idx_cpagar_empresa_fornecedor_nota; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cpagar_empresa_fornecedor_nota ON public.cpagar USING btree (id_empresa, id_fornecedor, nota);


--
-- Name: idx_cpagar_empresa_situacao_venc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cpagar_empresa_situacao_venc ON public.cpagar USING btree (id_empresa, id_situacao, data_vencimento);


--
-- Name: idx_creceber_empresa_situacao_venc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_creceber_empresa_situacao_venc ON public.creceber USING btree (id_empresa, id_situacao, data_vencimento);


--
-- Name: idx_creceber_empresa_venda; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_creceber_empresa_venda ON public.creceber USING btree (id_empresa, id_venda);


--
-- Name: idx_encerravenda_empresa_venda_situacao; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_encerravenda_empresa_venda_situacao ON public.encerravenda USING btree (emp_001, ven_001, sit_001);


--
-- Name: idx_formapgto_bot_wattsap; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_formapgto_bot_wattsap ON public.formapgto USING btree (emp_001, sfi_codigo) WHERE (sit_001 = 4);


--
-- Name: idx_ibpt_ncm_ex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_ibpt_ncm_ex ON public.ibpt USING btree (ncm, ex);


--
-- Name: idx_ifood_fin_antecipacao_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ifood_fin_antecipacao_data ON public.integracaoifoodfinanceiroantecipacao USING btree (id_empresa, merchant_id, anticipated_payment_date);


--
-- Name: idx_ifood_fin_closing_settlement; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ifood_fin_closing_settlement ON public.integracaoifoodfinanceiroclosingitem USING btree (id_empresa, merchant_id, settlement_chave);


--
-- Name: idx_ifood_fin_evento_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ifood_fin_evento_date ON public.integracaoifoodfinanceiroevento USING btree (id_empresa, merchant_id, event_date);


--
-- Name: idx_ifood_fin_evento_empresa_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ifood_fin_evento_empresa_date ON public.integracaoifoodfinanceiroevento USING btree (id_empresa, event_date);


--
-- Name: idx_ifood_fin_evento_empresa_payment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ifood_fin_evento_empresa_payment ON public.integracaoifoodfinanceiroevento USING btree (id_empresa, payment_date) WHERE (event_date IS NULL);


--
-- Name: idx_ifood_fin_evento_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ifood_fin_evento_order ON public.integracaoifoodfinanceiroevento USING btree (id_empresa, merchant_id, order_id);


--
-- Name: idx_ifood_fin_origem_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ifood_fin_origem_order ON public.integracaoifoodfinanceiroorigem USING btree (id_empresa, merchant_id, order_id);


--
-- Name: idx_ifood_fin_origem_reference; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ifood_fin_origem_reference ON public.integracaoifoodfinanceiroorigem USING btree (id_empresa, merchant_id, reference_date);


--
-- Name: idx_ifood_fin_reclinha_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ifood_fin_reclinha_order ON public.integracaoifoodfinanceiroreconciliacaolinha USING btree (id_empresa, merchant_id, order_id);


--
-- Name: idx_ifood_fin_reclinha_repasse; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ifood_fin_reclinha_repasse ON public.integracaoifoodfinanceiroreconciliacaolinha USING btree (id_empresa, merchant_id, data_repasse);


--
-- Name: idx_ifood_fin_settlement_calc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ifood_fin_settlement_calc ON public.integracaoifoodfinanceirosettlement USING btree (id_empresa, merchant_id, start_date_calculation, end_date_calculation);


--
-- Name: idx_ifood_fin_settlement_payment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ifood_fin_settlement_payment ON public.integracaoifoodfinanceirosettlement USING btree (id_empresa, merchant_id, payment_date);


--
-- Name: idx_ifood_fin_venda_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ifood_fin_venda_created ON public.integracaoifoodfinanceirovenda USING btree (id_empresa, merchant_id, created_at);


--
-- Name: idx_ifood_fin_venda_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ifood_fin_venda_status ON public.integracaoifoodfinanceirovenda USING btree (id_empresa, current_status, created_at);


--
-- Name: idx_integracao99foodconfig_ativo_recente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodconfig_ativo_recente ON public.integracao99foodconfig USING btree (ativo, atualizado_em DESC NULLS LAST, criado_em DESC, id DESC) WHERE (ativo = true);


--
-- Name: idx_integracao99foodconfig_empresa_ativo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodconfig_empresa_ativo ON public.integracao99foodconfig USING btree (id_empresa, ativo);


--
-- Name: idx_integracao99foodfila_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodfila_order ON public.integracao99foodfila USING btree (id_empresa, app_shop_id, order_id);


--
-- Name: idx_integracao99foodfila_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodfila_status ON public.integracao99foodfila USING btree (status, executar_em);


--
-- Name: idx_integracao99foodfila_tipo_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodfila_tipo_status ON public.integracao99foodfila USING btree (tipo, status, executar_em);


--
-- Name: idx_integracao99foodfinanceirobill_business; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodfinanceirobill_business ON public.integracao99foodfinanceirobill USING btree (id_empresa, app_shop_id, business_datetime);


--
-- Name: idx_integracao99foodfinanceirobill_day_payment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodfinanceirobill_day_payment ON public.integracao99foodfinanceirobill USING btree (day_payment_id);


--
-- Name: idx_integracao99foodfinanceirobill_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodfinanceirobill_order ON public.integracao99foodfinanceirobill USING btree (id_empresa, app_shop_id, order_id);


--
-- Name: idx_integracao99foodfinanceirobill_settle_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodfinanceirobill_settle_date ON public.integracao99foodfinanceirobill USING btree (expect_settle_date);


--
-- Name: idx_integracao99foodfinanceirosettlement_day_payment_list; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodfinanceirosettlement_day_payment_list ON public.integracao99foodfinanceirosettlement USING gin (day_payment_id_list);


--
-- Name: idx_integracao99foodfinanceirosettlement_week; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodfinanceirosettlement_week ON public.integracao99foodfinanceirosettlement USING btree (id_empresa, app_shop_id, week_payment_id);


--
-- Name: idx_integracao99foodfinanceirosettlement_withdraw; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodfinanceirosettlement_withdraw ON public.integracao99foodfinanceirosettlement USING btree (withdraw_date);


--
-- Name: idx_integracao99foodhttplog_empresa_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodhttplog_empresa_data ON public.integracao99foodhttplog USING btree (id_empresa, app_shop_id, criado_em);


--
-- Name: idx_integracao99foodhttplog_status_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodhttplog_status_data ON public.integracao99foodhttplog USING btree (status_code, criado_em);


--
-- Name: idx_integracao99foodloja_empresa_ativo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodloja_empresa_ativo ON public.integracao99foodloja USING btree (id_empresa, ativo);


--
-- Name: idx_integracao99foodpedido_appshop; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedido_appshop ON public.integracao99foodpedido USING btree (app_shop_id);


--
-- Name: idx_integracao99foodpedido_empresa_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedido_empresa_status ON public.integracao99foodpedido USING btree (id_empresa, status_local);


--
-- Name: idx_integracao99foodpedido_importado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedido_importado ON public.integracao99foodpedido USING btree (pedido_importado);


--
-- Name: idx_integracao99foodpedido_integrado_venda; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedido_integrado_venda ON public.integracao99foodpedido USING btree (integrado_venda);


--
-- Name: idx_integracao99foodpedido_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedido_order_id ON public.integracao99foodpedido USING btree (order_id);


--
-- Name: idx_integracao99foodpedido_pendente_importacao; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedido_pendente_importacao ON public.integracao99foodpedido USING btree (recebido_em, id) WHERE (pedido_importado = false);


--
-- Name: idx_integracao99foodpedido_pendente_venda; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedido_pendente_venda ON public.integracao99foodpedido USING btree (recebido_em, id) WHERE ((pedido_importado = true) AND (integrado_venda = false));


--
-- Name: idx_integracao99foodpedido_venda_local; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedido_venda_local ON public.integracao99foodpedido USING btree (id_venda_local) WHERE (id_venda_local IS NOT NULL);


--
-- Name: idx_integracao99foodpedidoitem_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedidoitem_order ON public.integracao99foodpedidoitem USING btree (id_empresa, app_shop_id, order_id);


--
-- Name: idx_integracao99foodpedidoitem_product_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedidoitem_product_code ON public.integracao99foodpedidoitem USING btree (product_code);


--
-- Name: idx_integracao99foodpedidoopcional_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedidoopcional_order ON public.integracao99foodpedidoopcional USING btree (id_empresa, app_shop_id, order_id);


--
-- Name: idx_integracao99foodpedidoopcional_order_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedidoopcional_order_item ON public.integracao99foodpedidoopcional USING btree (id_empresa, app_shop_id, order_id, numero_item);


--
-- Name: idx_integracao99foodpedidoopcional_product_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedidoopcional_product_code ON public.integracao99foodpedidoopcional USING btree (product_code);


--
-- Name: idx_integracao99foodpedidopagamento_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedidopagamento_order ON public.integracao99foodpedidopagamento USING btree (id_empresa, app_shop_id, order_id);


--
-- Name: idx_integracao99foodpedidopagamento_pedido; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedidopagamento_pedido ON public.integracao99foodpedidopagamento USING btree (pedido_id);


--
-- Name: idx_integracao99foodpedidostatus_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedidostatus_order ON public.integracao99foodpedidostatus USING btree (id_empresa, app_shop_id, order_id);


--
-- Name: idx_integracao99foodpedidostatus_pedido; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodpedidostatus_pedido ON public.integracao99foodpedidostatus USING btree (pedido_id, criado_em);


--
-- Name: idx_integracao99foodwebhooklog_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodwebhooklog_event_type ON public.integracao99foodwebhooklog USING btree (event_type);


--
-- Name: idx_integracao99foodwebhooklog_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodwebhooklog_order ON public.integracao99foodwebhooklog USING btree (order_id);


--
-- Name: idx_integracao99foodwebhooklog_pendente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracao99foodwebhooklog_pendente ON public.integracao99foodwebhooklog USING btree (processado, criado_em) WHERE (processado = false);


--
-- Name: idx_integracaoanotaaiconfig_empresa_ativo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaiconfig_empresa_ativo ON public.integracaoanotaaiconfig USING btree (id_empresa, ativo);


--
-- Name: idx_integracaoanotaaihttplog_empresa_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaihttplog_empresa_data ON public.integracaoanotaaihttplog USING btree (id_empresa, merchant_id, criado_em);


--
-- Name: idx_integracaoanotaaihttplog_status_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaihttplog_status_data ON public.integracaoanotaaihttplog USING btree (status_code, criado_em);


--
-- Name: idx_integracaoanotaaiinbox_fila; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaiinbox_fila ON public.integracaoanotaaiinbox USING btree (status_processamento, executar_em, id);


--
-- Name: idx_integracaoanotaaiinbox_payload; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaiinbox_payload ON public.integracaoanotaaiinbox USING gin (payload);


--
-- Name: idx_integracaoanotaaiinbox_pedido; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaiinbox_pedido ON public.integracaoanotaaiinbox USING btree (id_empresa, merchant_id, order_id, criado_em DESC);


--
-- Name: idx_integracaoanotaaimenusync_remote; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaimenusync_remote ON public.integracaoanotaaimenusync USING btree (id_empresa, merchant_id, entity_type, remote_id) WHERE (remote_id IS NOT NULL);


--
-- Name: idx_integracaoanotaaioutbox_fila; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaioutbox_fila ON public.integracaoanotaaioutbox USING btree (status, executar_em, id);


--
-- Name: idx_integracaoanotaaipedido_payload; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaipedido_payload ON public.integracaoanotaaipedido USING gin (payload);


--
-- Name: idx_integracaoanotaaipedido_pendente_importacao; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaipedido_pendente_importacao ON public.integracaoanotaaipedido USING btree (recebido_em, id) WHERE (pedido_importado = false);


--
-- Name: idx_integracaoanotaaipedido_pendente_venda; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaipedido_pendente_venda ON public.integracaoanotaaipedido USING btree (recebido_em, id) WHERE ((pedido_importado = true) AND (integrado_venda = false));


--
-- Name: idx_integracaoanotaaipedido_venda_local; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaipedido_venda_local ON public.integracaoanotaaipedido USING btree (id_venda_local) WHERE (id_venda_local IS NOT NULL);


--
-- Name: idx_integracaoanotaaipedidoitem_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaipedidoitem_order ON public.integracaoanotaaipedidoitem USING btree (id_empresa, merchant_id, order_id);


--
-- Name: idx_integracaoanotaaipedidoitem_product_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaipedidoitem_product_code ON public.integracaoanotaaipedidoitem USING btree (product_code);


--
-- Name: idx_integracaoanotaaipedidoopcional_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaipedidoopcional_item ON public.integracaoanotaaipedidoopcional USING btree (pedido_item_id);


--
-- Name: idx_integracaoanotaaipedidoopcional_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaipedidoopcional_order ON public.integracaoanotaaipedidoopcional USING btree (id_empresa, merchant_id, order_id);


--
-- Name: idx_integracaoanotaaipedidoopcional_product_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaipedidoopcional_product_code ON public.integracaoanotaaipedidoopcional USING btree (product_code);


--
-- Name: idx_integracaoanotaaipedidostatus_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaipedidostatus_order ON public.integracaoanotaaipedidostatus USING btree (id_empresa, merchant_id, order_id);


--
-- Name: idx_integracaoanotaaipedidostatus_pedido; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaoanotaaipedidostatus_pedido ON public.integracaoanotaaipedidostatus USING btree (pedido_id, criado_em);


--
-- Name: idx_integracaodeliverydiretocatalogomapa_custom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretocatalogomapa_custom ON public.integracaodeliverydiretocatalogomapa USING btree (id_empresa, delivery_direto_id, entity_type, custom_code) WHERE (custom_code IS NOT NULL);


--
-- Name: idx_integracaodeliverydiretoconfig_empresa_ativo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretoconfig_empresa_ativo ON public.integracaodeliverydiretoconfig USING btree (id_empresa, ativo);


--
-- Name: idx_integracaodeliverydiretohttplog_empresa_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretohttplog_empresa_data ON public.integracaodeliverydiretohttplog USING btree (id_empresa, delivery_direto_id, criado_em);


--
-- Name: idx_integracaodeliverydiretohttplog_status_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretohttplog_status_data ON public.integracaodeliverydiretohttplog USING btree (status_code, criado_em);


--
-- Name: idx_integracaodeliverydiretooutbox_fila; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretooutbox_fila ON public.integracaodeliverydiretooutbox USING btree (status, executar_em, id);


--
-- Name: idx_integracaodeliverydiretopedido_payload; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretopedido_payload ON public.integracaodeliverydiretopedido USING gin (payload);


--
-- Name: idx_integracaodeliverydiretopedido_pendente_importacao; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretopedido_pendente_importacao ON public.integracaodeliverydiretopedido USING btree (recebido_em, id) WHERE (pedido_importado = false);


--
-- Name: idx_integracaodeliverydiretopedido_pendente_venda; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretopedido_pendente_venda ON public.integracaodeliverydiretopedido USING btree (recebido_em, id) WHERE ((pedido_importado = true) AND (integrado_venda = false));


--
-- Name: idx_integracaodeliverydiretopedido_venda_local; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretopedido_venda_local ON public.integracaodeliverydiretopedido USING btree (id_venda_local) WHERE (id_venda_local IS NOT NULL);


--
-- Name: idx_integracaodeliverydiretopedidoitem_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretopedidoitem_order ON public.integracaodeliverydiretopedidoitem USING btree (id_empresa, delivery_direto_id, order_id);


--
-- Name: idx_integracaodeliverydiretopedidoitem_product_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretopedidoitem_product_code ON public.integracaodeliverydiretopedidoitem USING btree (product_code);


--
-- Name: idx_integracaodeliverydiretopedidoopcional_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretopedidoopcional_item ON public.integracaodeliverydiretopedidoopcional USING btree (pedido_item_id);


--
-- Name: idx_integracaodeliverydiretopedidoopcional_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretopedidoopcional_order ON public.integracaodeliverydiretopedidoopcional USING btree (id_empresa, delivery_direto_id, order_id);


--
-- Name: idx_integracaodeliverydiretopedidoopcional_product_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretopedidoopcional_product_code ON public.integracaodeliverydiretopedidoopcional USING btree (product_code);


--
-- Name: idx_integracaodeliverydiretopedidostatus_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretopedidostatus_order ON public.integracaodeliverydiretopedidostatus USING btree (id_empresa, delivery_direto_id, order_id);


--
-- Name: idx_integracaodeliverydiretopedidostatus_pedido; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretopedidostatus_pedido ON public.integracaodeliverydiretopedidostatus USING btree (pedido_id, criado_em);


--
-- Name: idx_integracaodeliverydiretowebhookinbox_fila; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretowebhookinbox_fila ON public.integracaodeliverydiretowebhookinbox USING btree (status_processamento, executar_em, id);


--
-- Name: idx_integracaodeliverydiretowebhookinbox_payload; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretowebhookinbox_payload ON public.integracaodeliverydiretowebhookinbox USING gin (payload);


--
-- Name: idx_integracaodeliverydiretowebhookinbox_pedido; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaodeliverydiretowebhookinbox_pedido ON public.integracaodeliverydiretowebhookinbox USING btree (id_empresa, delivery_direto_id, orders_id, criado_em DESC);


--
-- Name: idx_integracaostonepagarme_charge_orderid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaostonepagarme_charge_orderid ON public.integracaostonepagarme_charge USING btree (id_empresa, orderid);


--
-- Name: idx_integracaostonepagarme_charge_venda; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaostonepagarme_charge_venda ON public.integracaostonepagarme_charge USING btree (id_empresa, id_venda);


--
-- Name: idx_integracaostonepagarme_pedido_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaostonepagarme_pedido_status ON public.integracaostonepagarme_pedido USING btree (id_empresa, status);


--
-- Name: idx_integracaostonepagarme_pedido_venda; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaostonepagarme_pedido_venda ON public.integracaostonepagarme_pedido USING btree (id_empresa, id_venda);


--
-- Name: idx_integracaostonepagarme_webhook_chargeid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaostonepagarme_webhook_chargeid ON public.integracaostonepagarme_webhook USING btree (chargeid);


--
-- Name: idx_integracaostonepagarme_webhook_event; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaostonepagarme_webhook_event ON public.integracaostonepagarme_webhook USING btree (eventtype);


--
-- Name: idx_integracaostonepagarme_webhook_orderid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaostonepagarme_webhook_orderid ON public.integracaostonepagarme_webhook USING btree (orderid);


--
-- Name: idx_integracaostonepagarme_webhook_pendente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integracaostonepagarme_webhook_pendente ON public.integracaostonepagarme_webhook USING btree (processado, criadoem) WHERE (processado = false);


--
-- Name: idx_materiais_bot_wattsap_categoria; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_materiais_bot_wattsap_categoria ON public.materiais USING btree (emp_001, cat_001) WHERE ((sit_001 = 4) AND (NOT COALESCE(b_servico, false)));


--
-- Name: idx_materiais_bot_wattsap_descricao; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_materiais_bot_wattsap_descricao ON public.materiais USING btree (emp_001, translate(lower((mat_003)::text), 'áàâãäéèêëíìîïóòôõöúùûüç'::text, 'aaaaaeeeeiiiiooooouuuuc'::text) varchar_pattern_ops) WHERE ((sit_001 = 4) AND (NOT COALESCE(b_servico, false)));


--
-- Name: idx_materiais_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_materiais_lookup ON public.materiais USING btree (mat_001, emp_001);


--
-- Name: idx_materiais_mat_003_trgm2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_materiais_mat_003_trgm2 ON public.materiais USING gin (regexp_replace(translate(lower((mat_003)::text), 'áàâãäéèêëíìîïóòôõöúùûüç'::text, 'aaaaaeeeeiiiiooooouuuuc'::text), '[^a-z0-9 ]+'::text, ' '::text, 'g'::text) public.gin_trgm_ops);


--
-- Name: idx_mensagem_wattsap_pendente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mensagem_wattsap_pendente ON public.mensagem_wattsap USING btree (id_empresa, message_timestamp, id_mensagem) WHERE ((status)::text = 'PENDENTE'::text);


--
-- Name: idx_mensagem_wattsap_processando; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mensagem_wattsap_processando ON public.mensagem_wattsap USING btree (id_empresa, atualizado_em) WHERE ((status)::text = 'PROCESSANDO'::text);


--
-- Name: idx_mensagem_wattsap_respondida; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mensagem_wattsap_respondida ON public.mensagem_wattsap USING btree (id_empresa, respondido_em) WHERE ((status)::text = 'RESPONDIDA'::text);


--
-- Name: idx_movimentoestoque_empresa_material_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_movimentoestoque_empresa_material_data ON public.movimentoestoque USING btree (id_empresa, id_material, data DESC);


--
-- Name: idx_movimentoestoque_empresa_venda; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_movimentoestoque_empresa_venda ON public.movimentoestoque USING btree (id_empresa, id_venda);


--
-- Name: idx_sessao_wattsap_expiracao; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessao_wattsap_expiracao ON public.sessao_wattsap USING btree (id_empresa, expira_em);


--
-- Name: idx_tipomov_empresa_conta_comp_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tipomov_empresa_conta_comp_data ON public.tipo_movimento USING btree (id_empresa, id_contacorrente, compensado, data_emissao);


--
-- Name: idx_tipomov_empresa_venda; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tipomov_empresa_venda ON public.tipo_movimento USING btree (id_empresa, ven_001);


--
-- Name: idx_venda_99food_status_envio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_venda_99food_status_envio ON public.venda USING btree (emp_001, sit_001, data_saida, ven_001) WHERE ((upper(TRIM(BOTH FROM COALESCE(origem_integracao, ''::character varying))) = '99FOOD'::text) AND (COALESCE(id_pedido_99food, (0)::bigint) > 0));


--
-- Name: idx_venda_empresa_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_venda_empresa_data ON public.venda USING btree (emp_001, ven_004 DESC);


--
-- Name: idx_venda_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_venda_lookup ON public.venda USING btree (ven_001, emp_001);


--
-- Name: idx_venda_pedzap_origem; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_venda_pedzap_origem ON public.venda USING btree (emp_001, id_pedido_pedzap) WHERE ((upper(TRIM(BOTH FROM COALESCE(origem_integracao, ''::character varying))) = 'PEDZAP'::text) AND (id_pedido_pedzap IS NOT NULL));


--
-- Name: idx_vendaitem_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendaitem_lookup ON public.vendaitem USING btree (ven_001, emp_001, sit_001);


--
-- Name: idx_vendaitem_update; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendaitem_update ON public.vendaitem USING btree (emp_001, ven_001, ite_001);


--
-- Name: index_btree_venda_ven_004; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_btree_venda_ven_004 ON public.venda USING btree (ven_004);


--
-- Name: index_hash_venda_emp_001; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hash_venda_emp_001 ON public.venda USING hash (emp_001);


--
-- Name: index_hash_venda_ven_001; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hash_venda_ven_001 ON public.venda USING hash (ven_001);


--
-- Name: index_hash_venda_ven_025; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hash_venda_ven_025 ON public.venda USING hash (ven_025);


--
-- Name: index_hash_vendaitem_emp_001; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hash_vendaitem_emp_001 ON public.vendaitem USING hash (emp_001);


--
-- Name: index_hash_vendaitem_ite_001; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hash_vendaitem_ite_001 ON public.vendaitem USING hash (ite_001);


--
-- Name: index_hash_vendaitem_ite_013; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hash_vendaitem_ite_013 ON public.vendaitem USING hash (ite_013);


--
-- Name: index_hash_vendaitem_ven_001; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hash_vendaitem_ven_001 ON public.vendaitem USING hash (ven_001);


--
-- Name: ix_delivery_clientes_empresa_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_delivery_clientes_empresa_cliente ON public.clientes USING btree (emp_001, cli_001);


--
-- Name: ix_delivery_venda_agendamento_alerta; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_delivery_venda_agendamento_alerta ON public.venda USING btree (emp_001, data_agendamento, hora_agendamento, ven_001) WHERE (((ven_024)::text = 'D'::text) AND (sit_001 = 19));


--
-- Name: ix_delivery_venda_pag_antecipado_painel; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_delivery_venda_pag_antecipado_painel ON public.venda_pag_antecipado USING btree (id_empresa, id_venda, id_situacao);


--
-- Name: ix_delivery_venda_painel_abertas; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_delivery_venda_painel_abertas ON public.venda USING btree (emp_001, sit_001, ven_001) WHERE (((ven_024)::text = 'D'::text) AND (sit_001 = ANY (ARRAY[6, 8, 19, 100])));


--
-- Name: ix_delivery_venda_painel_caixa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_delivery_venda_painel_caixa ON public.venda USING btree (emp_001, sit_001, id_caixa_abertura, ven_001) WHERE (((ven_024)::text = 'D'::text) AND (sit_001 = ANY (ARRAY[1, 2])));


--
-- Name: ix_delivery_venda_terminal_aberta; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_delivery_venda_terminal_aberta ON public.venda USING btree (emp_001, terminal_abertura, ven_001) WHERE (((ven_024)::text = 'D'::text) AND (sit_001 = 0));


--
-- Name: ix_delivery_vendaitemopcional_resumo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_delivery_vendaitemopcional_resumo ON public.vendaitemopcional USING btree (id_empresa, id_venda, id_vendaitem, id_opcional);


--
-- Name: ix_ifood_conc_competencia; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ifood_conc_competencia ON public.integracaoifoodconciliacao USING btree (id_empresa, merchant_id, competencia);


--
-- Name: ix_ifood_conc_faturamento; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ifood_conc_faturamento ON public.integracaoifoodconciliacao USING btree (id_empresa, merchant_id, data_faturamento);


--
-- Name: ix_materiais_proc_margem_custos_v2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_materiais_proc_margem_custos_v2 ON public.materiais USING btree (mat_001, emp_001) INCLUDE (mat_006, mat_012);


--
-- Name: ix_venda_usu_001_1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_venda_usu_001_1 ON public.venda USING btree (usu_001_1);


--
-- Name: ix_vendaitem_proc_margem_completo_v2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_vendaitem_proc_margem_completo_v2 ON public.vendaitem USING btree (ven_001, emp_001, mat_001) INCLUDE (ite_001, ite_002, ite_003, acrescimo, acrescimorateio, desconto, descontorateio);


--
-- Name: ix_vendaitem_proc_margem_update_v2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_vendaitem_proc_margem_update_v2 ON public.vendaitem USING btree (ven_001, emp_001, ite_001) INCLUDE (custoproduto, custocomposicao, margemlucro);


--
-- Name: ix_vendaitem_rateio_acrescimo_proporcional; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_vendaitem_rateio_acrescimo_proporcional ON public.vendaitem USING btree (ven_001, emp_001, sit_001) INCLUDE (ite_001, ite_005, acrescimorateio) WHERE (sit_001 = 4);


--
-- Name: ix_vendaitem_rateio_desconto_proporcional; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_vendaitem_rateio_desconto_proporcional ON public.vendaitem USING btree (ven_001, emp_001, sit_001) INCLUDE (ite_001, ite_005, descontorateio) WHERE (sit_001 = 4);


--
-- Name: ix_vendaitem_rateio_ordenacao; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_vendaitem_rateio_ordenacao ON public.vendaitem USING btree (ven_001, emp_001, ite_001) WHERE ((sit_001 = 4) AND (ite_005 > (0)::numeric));


--
-- Name: ix_vendaitem_venda_empresa_sit_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_vendaitem_venda_empresa_sit_item ON public.vendaitem USING btree (ven_001, emp_001, sit_001, ite_001);


--
-- Name: uq_integracaostonepagarme_pedido_orderid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_integracaostonepagarme_pedido_orderid ON public.integracaostonepagarme_pedido USING btree (id_empresa, orderid) WHERE ((orderid IS NOT NULL) AND ((orderid)::text <> ''::text));


--
-- Name: ux_clientes_99food_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_clientes_99food_cliente ON public.clientes USING btree (emp_001, id_cliente_99food) WHERE ((upper(TRIM(BOTH FROM COALESCE(origem_integracao, ''::character varying))) = '99FOOD'::text) AND (id_cliente_99food IS NOT NULL));


--
-- Name: ux_clientes_anotaai_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_clientes_anotaai_cliente ON public.clientes USING btree (emp_001, id_cliente_anotaai) WHERE ((upper(TRIM(BOTH FROM COALESCE(origem_integracao, ''::character varying))) = 'ANOTAAI'::text) AND (id_cliente_anotaai IS NOT NULL) AND (TRIM(BOTH FROM id_cliente_anotaai) <> ''::text));


--
-- Name: ux_clientes_deliverydireto_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_clientes_deliverydireto_cliente ON public.clientes USING btree (emp_001, id_cliente_deliverydireto) WHERE ((upper(TRIM(BOTH FROM COALESCE(origem_integracao, ''::character varying))) = 'DELIVERYDIRETO'::text) AND (id_cliente_deliverydireto IS NOT NULL) AND (TRIM(BOTH FROM id_cliente_deliverydireto) <> ''::text));


--
-- Name: ux_configuracao_geral_id_empresa; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_configuracao_geral_id_empresa ON public.configuracao_geral USING btree (id_empresa);


--
-- Name: ux_integracao99foodconfig_empresa_app_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_integracao99foodconfig_empresa_app_id ON public.integracao99foodconfig USING btree (id_empresa, app_id) WHERE (app_id IS NOT NULL);


--
-- Name: ux_integracao99foodfila_financeiro_pendente; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_integracao99foodfila_financeiro_pendente ON public.integracao99foodfila USING btree (id_empresa, app_shop_id, order_id, tipo) WHERE (((tipo)::text = 'FINANCEIRO_BILL_DETAIL'::text) AND ((status)::text = ANY (ARRAY[('PENDENTE'::character varying)::text, ('PROCESSANDO'::character varying)::text])));


--
-- Name: ux_integracao99foodpedidostatus_saiu_entrega_integrador; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_integracao99foodpedidostatus_saiu_entrega_integrador ON public.integracao99foodpedidostatus USING btree (pedido_id, status_local, origem) WHERE (((status_local)::text = 'SAIU_ENTREGA'::text) AND ((origem)::text = 'INTEGRADOR'::text));


--
-- Name: ux_integracao99foodwebhooklog_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_integracao99foodwebhooklog_event_id ON public.integracao99foodwebhooklog USING btree (event_id) WHERE (event_id IS NOT NULL);


--
-- Name: ux_integracao99foodwebhooklog_webhook_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_integracao99foodwebhooklog_webhook_id ON public.integracao99foodwebhooklog USING btree (webhook_id) WHERE (webhook_id IS NOT NULL);


--
-- Name: ux_integracaoanotaaiinbox_evento; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_integracaoanotaaiinbox_evento ON public.integracaoanotaaiinbox USING btree (id_empresa, merchant_id, origem, event_id) WHERE (event_id IS NOT NULL);


--
-- Name: ux_integracaodeliverydiretowebhookinbox_dedupe; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_integracaodeliverydiretowebhookinbox_dedupe ON public.integracaodeliverydiretowebhookinbox USING btree (id_empresa, delivery_direto_id, event_type, orders_id, payload_sha256);


--
-- Name: ux_transf_rp_food_menu; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_transf_rp_food_menu ON public.transf_rp_food_menu USING btree (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) NULLS NOT DISTINCT;


--
-- Name: ux_transf_rpcheff_cloud; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_transf_rpcheff_cloud ON public.transf_rpcheff_cloud USING btree (tipo, id_registro, id_empresa, id_registro_secundario, auxiliar) NULLS NOT DISTINCT;


--
-- Name: ux_venda_99food_pedido; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_venda_99food_pedido ON public.venda USING btree (emp_001, id_pedido_99food) WHERE ((upper(TRIM(BOTH FROM COALESCE(origem_integracao, ''::character varying))) = '99FOOD'::text) AND (id_pedido_99food IS NOT NULL));


--
-- Name: ux_venda_anotaai_pedido; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_venda_anotaai_pedido ON public.venda USING btree (emp_001, id_pedido_anotaai) WHERE ((upper(TRIM(BOTH FROM COALESCE(origem_integracao, ''::character varying))) = 'ANOTAAI'::text) AND (id_pedido_anotaai IS NOT NULL));


--
-- Name: ux_venda_deliverydireto_pedido; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_venda_deliverydireto_pedido ON public.venda USING btree (emp_001, id_pedido_deliverydireto) WHERE ((upper(TRIM(BOTH FROM COALESCE(origem_integracao, ''::character varying))) = 'DELIVERYDIRETO'::text) AND (id_pedido_deliverydireto IS NOT NULL) AND (TRIM(BOTH FROM id_pedido_deliverydireto) <> ''::text));


--
-- Name: ux_vendaitem_lanc_mobile; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_vendaitem_lanc_mobile ON public.vendaitem USING btree (emp_001, ven_001, id_lancamento_mobile);


--
-- Name: categoria_opcionais categoria_opcionais_trigger_function; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER categoria_opcionais_trigger_function AFTER INSERT OR UPDATE ON public.categoria_opcionais FOR EACH ROW EXECUTE FUNCTION public.categoria_opcionais_trigger_function();


--
-- Name: categoria categoria_trigger_function; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER categoria_trigger_function AFTER INSERT OR UPDATE ON public.categoria FOR EACH ROW EXECUTE FUNCTION public.categoria_trigger_function();


--
-- Name: configuracao_funcionamento configuracaofuncionamento_trigger_function; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER configuracaofuncionamento_trigger_function AFTER INSERT OR UPDATE ON public.configuracao_funcionamento FOR EACH ROW EXECUTE FUNCTION public.configuracaofuncionamento_trigger_function();


--
-- Name: configuracaopagamentomercadopago configuracaomercadopago_trigger_function; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER configuracaomercadopago_trigger_function AFTER INSERT OR DELETE OR UPDATE ON public.configuracaopagamentomercadopago FOR EACH ROW EXECUTE FUNCTION public.configuracaomercadopago_trigger_function();


--
-- Name: configuracao_rpfood configuracaorpfood_trigger_function; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER configuracaorpfood_trigger_function AFTER INSERT OR UPDATE ON public.configuracao_rpfood FOR EACH ROW EXECUTE FUNCTION public.configuracaorpfood_trigger_function();


--
-- Name: empresas empresas_trigger_function; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER empresas_trigger_function AFTER INSERT OR UPDATE ON public.empresas FOR EACH ROW EXECUTE FUNCTION public.empresas_trigger_function();


--
-- Name: formapgto formapgto_trigger_function; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER formapgto_trigger_function AFTER INSERT OR UPDATE ON public.formapgto FOR EACH ROW EXECUTE FUNCTION public.formapgto_trigger_function();


--
-- Name: materiais materiais_after_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER materiais_after_trigger AFTER INSERT OR UPDATE ON public.materiais FOR EACH ROW EXECUTE FUNCTION public.materiais_trigger_function();


--
-- Name: materiais_opcional materiaisopcionais_trigger_function; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER materiaisopcionais_trigger_function AFTER INSERT OR DELETE OR UPDATE ON public.materiais_opcional FOR EACH ROW EXECUTE FUNCTION public.materiaisopcionais_trigger_function();


--
-- Name: mesa mesa_trigger_function; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER mesa_trigger_function AFTER INSERT OR UPDATE ON public.mesa FOR EACH ROW EXECUTE FUNCTION public.mesa_trigger_function();


--
-- Name: opcional opcional_trigger_function; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER opcional_trigger_function AFTER INSERT OR UPDATE ON public.opcional FOR EACH ROW EXECUTE FUNCTION public.opcional_trigger_function();


--
-- Name: bairro trg_cloud_bairro_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_bairro_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.bairro FOR EACH ROW EXECUTE FUNCTION public.cloud_bairro_trigger_function();


--
-- Name: balanca_info_extra trg_cloud_balanca_info_extra_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_balanca_info_extra_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.balanca_info_extra FOR EACH ROW EXECUTE FUNCTION public.cloud_balanca_info_extra_trigger_function();


--
-- Name: balanca_info_nutri trg_cloud_balanca_info_nutri_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_balanca_info_nutri_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.balanca_info_nutri FOR EACH ROW EXECUTE FUNCTION public.cloud_balanca_info_nutri_trigger_function();


--
-- Name: caixa trg_cloud_caixa_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_caixa_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.caixa FOR EACH ROW EXECUTE FUNCTION public.cloud_caixa_trigger_function();


--
-- Name: caixainformado trg_cloud_caixainformado_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_caixainformado_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.caixainformado FOR EACH ROW EXECUTE FUNCTION public.cloud_caixainformado_trigger_function();


--
-- Name: caixaitem trg_cloud_caixaitem_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_caixaitem_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.caixaitem FOR EACH ROW EXECUTE FUNCTION public.cloud_caixaitem_trigger_function();


--
-- Name: categoria trg_cloud_categoria_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_categoria_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.categoria FOR EACH ROW EXECUTE FUNCTION public.cloud_categoria_trigger_function();


--
-- Name: clientes trg_cloud_clientes_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_clientes_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.clientes FOR EACH ROW EXECUTE FUNCTION public.cloud_clientes_trigger_function();


--
-- Name: comanda trg_cloud_comanda_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_comanda_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.comanda FOR EACH ROW EXECUTE FUNCTION public.cloud_comanda_trigger_function();


--
-- Name: composicao_fornecedor trg_cloud_composicao_fornecedor_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_composicao_fornecedor_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.composicao_fornecedor FOR EACH ROW EXECUTE FUNCTION public.cloud_composicao_fornecedor_trigger_function();


--
-- Name: composicao trg_cloud_composicao_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_composicao_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.composicao FOR EACH ROW EXECUTE FUNCTION public.cloud_composicao_trigger_function();


--
-- Name: conta trg_cloud_conta_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_conta_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.conta FOR EACH ROW EXECUTE FUNCTION public.cloud_conta_trigger_function();


--
-- Name: contacorrente trg_cloud_contacorrente_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_contacorrente_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.contacorrente FOR EACH ROW EXECUTE FUNCTION public.cloud_contacorrente_trigger_function();


--
-- Name: cpagar_parcela trg_cloud_cpagar_parcela_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_cpagar_parcela_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.cpagar_parcela FOR EACH ROW EXECUTE FUNCTION public.cloud_cpagar_parcela_trigger_function();


--
-- Name: cpagar trg_cloud_cpagar_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_cpagar_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.cpagar FOR EACH ROW EXECUTE FUNCTION public.cloud_cpagar_trigger_function();


--
-- Name: creceber_parcela trg_cloud_creceber_parcela_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_creceber_parcela_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.creceber_parcela FOR EACH ROW EXECUTE FUNCTION public.cloud_creceber_parcela_trigger_function();


--
-- Name: creceber trg_cloud_creceber_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_creceber_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.creceber FOR EACH ROW EXECUTE FUNCTION public.cloud_creceber_trigger_function();


--
-- Name: devolucaoitem trg_cloud_devolucaoitem_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_devolucaoitem_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.devolucaoitem FOR EACH ROW EXECUTE FUNCTION public.cloud_devolucaoitem_trigger_function();


--
-- Name: empresas trg_cloud_empresas_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_empresas_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.empresas FOR EACH ROW EXECUTE FUNCTION public.cloud_empresas_trigger_function();


--
-- Name: encerravenda trg_cloud_encerravenda_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_encerravenda_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.encerravenda FOR EACH ROW EXECUTE FUNCTION public.cloud_encerravenda_trigger_function();


--
-- Name: encerravendaitem trg_cloud_encerravendaitem_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_encerravendaitem_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.encerravendaitem FOR EACH ROW EXECUTE FUNCTION public.cloud_encerravendaitem_trigger_function();


--
-- Name: eventos_mesas trg_cloud_eventos_mesas_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_eventos_mesas_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.eventos_mesas FOR EACH ROW EXECUTE FUNCTION public.cloud_eventos_mesas_trigger_function();


--
-- Name: eventos trg_cloud_eventos_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_eventos_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.eventos FOR EACH ROW EXECUTE FUNCTION public.cloud_eventos_trigger_function();


--
-- Name: execucoes_estoque_item trg_cloud_execucoes_estoque_item_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_execucoes_estoque_item_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.execucoes_estoque_item FOR EACH ROW EXECUTE FUNCTION public.cloud_execucoes_estoque_item_trigger_function();


--
-- Name: execucoes_estoque trg_cloud_execucoes_estoque_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_execucoes_estoque_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.execucoes_estoque FOR EACH ROW EXECUTE FUNCTION public.cloud_execucoes_estoque_trigger_function();


--
-- Name: formapgto trg_cloud_formapgto_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_formapgto_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.formapgto FOR EACH ROW EXECUTE FUNCTION public.cloud_formapgto_trigger_function();


--
-- Name: fornecedor trg_cloud_fornecedor_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_fornecedor_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.fornecedor FOR EACH ROW EXECUTE FUNCTION public.cloud_fornecedor_trigger_function();


--
-- Name: materiais_fornecedor trg_cloud_materiais_fornecedor_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_materiais_fornecedor_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.materiais_fornecedor FOR EACH ROW EXECUTE FUNCTION public.cloud_materiais_fornecedor_trigger_function();


--
-- Name: materiais trg_cloud_materiais_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_materiais_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.materiais FOR EACH ROW EXECUTE FUNCTION public.cloud_materiais_trigger_function();


--
-- Name: mesa trg_cloud_mesa_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_mesa_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.mesa FOR EACH ROW EXECUTE FUNCTION public.cloud_mesa_trigger_function();


--
-- Name: movimento_estoque_composicao trg_cloud_movimento_estoque_composicao_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_movimento_estoque_composicao_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.movimento_estoque_composicao FOR EACH ROW EXECUTE FUNCTION public.cloud_movimento_estoque_composicao_trigger_function();


--
-- Name: movimento_estoque_opcional trg_cloud_movimento_estoque_opcional_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_movimento_estoque_opcional_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.movimento_estoque_opcional FOR EACH ROW EXECUTE FUNCTION public.cloud_movimento_estoque_opcional_trigger_function();


--
-- Name: movimentocontacliente trg_cloud_movimentocontacliente_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_movimentocontacliente_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.movimentocontacliente FOR EACH ROW EXECUTE FUNCTION public.cloud_movimentocontacliente_trigger_function();


--
-- Name: movimentocontacorrente trg_cloud_movimentocontacorrente_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_movimentocontacorrente_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.movimentocontacorrente FOR EACH ROW EXECUTE FUNCTION public.cloud_movimentocontacorrente_trigger_function();


--
-- Name: movimentoestoque trg_cloud_movimentoestoque_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_movimentoestoque_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.movimentoestoque FOR EACH ROW EXECUTE FUNCTION public.cloud_movimentoestoque_trigger_function();


--
-- Name: nota_entrada_item trg_cloud_nota_entrada_item_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_nota_entrada_item_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.nota_entrada_item FOR EACH ROW EXECUTE FUNCTION public.cloud_nota_entrada_item_trigger_function();


--
-- Name: nota_entrada trg_cloud_nota_entrada_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_nota_entrada_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.nota_entrada FOR EACH ROW EXECUTE FUNCTION public.cloud_nota_entrada_trigger_function();


--
-- Name: nota_saida_item trg_cloud_nota_saida_item_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_nota_saida_item_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.nota_saida_item FOR EACH ROW EXECUTE FUNCTION public.cloud_nota_saida_item_trigger_function();


--
-- Name: nota_saida trg_cloud_nota_saida_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_nota_saida_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.nota_saida FOR EACH ROW EXECUTE FUNCTION public.cloud_nota_saida_trigger_function();


--
-- Name: opcional trg_cloud_opcional_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_opcional_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.opcional FOR EACH ROW EXECUTE FUNCTION public.cloud_opcional_trigger_function();


--
-- Name: pedido_compra_item trg_cloud_pedido_compra_item_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_pedido_compra_item_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.pedido_compra_item FOR EACH ROW EXECUTE FUNCTION public.cloud_pedido_compra_item_trigger_function();


--
-- Name: pedido_compra trg_cloud_pedido_compra_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_pedido_compra_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.pedido_compra FOR EACH ROW EXECUTE FUNCTION public.cloud_pedido_compra_trigger_function();


--
-- Name: setor_estoque_composicao trg_cloud_setor_estoque_composicao_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_setor_estoque_composicao_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.setor_estoque_composicao FOR EACH ROW EXECUTE FUNCTION public.cloud_setor_estoque_composicao_trigger_function();


--
-- Name: setor_estoque_material trg_cloud_setor_estoque_material_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_setor_estoque_material_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.setor_estoque_material FOR EACH ROW EXECUTE FUNCTION public.cloud_setor_estoque_material_trigger_function();


--
-- Name: setor_estoque_opcional trg_cloud_setor_estoque_opcional_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_setor_estoque_opcional_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.setor_estoque_opcional FOR EACH ROW EXECUTE FUNCTION public.cloud_setor_estoque_opcional_trigger_function();


--
-- Name: setor_estoque trg_cloud_setor_estoque_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_setor_estoque_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.setor_estoque FOR EACH ROW EXECUTE FUNCTION public.cloud_setor_estoque_trigger_function();


--
-- Name: subcategoria trg_cloud_subcategoria_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_subcategoria_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.subcategoria FOR EACH ROW EXECUTE FUNCTION public.cloud_subcategoria_trigger_function();


--
-- Name: tara trg_cloud_tara_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_tara_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.tara FOR EACH ROW EXECUTE FUNCTION public.cloud_tara_trigger_function();


--
-- Name: terminais trg_cloud_terminais_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_terminais_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.terminais FOR EACH ROW EXECUTE FUNCTION public.cloud_terminais_trigger_function();


--
-- Name: tipo_movimento trg_cloud_tipo_movimento_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_tipo_movimento_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.tipo_movimento FOR EACH ROW EXECUTE FUNCTION public.cloud_tipo_movimento_trigger_function();


--
-- Name: trocogarcom trg_cloud_trocogarcom_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_trocogarcom_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.trocogarcom FOR EACH ROW EXECUTE FUNCTION public.cloud_trocogarcom_trigger_function();


--
-- Name: unidades trg_cloud_unidades_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_unidades_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.unidades FOR EACH ROW EXECUTE FUNCTION public.cloud_unidades_trigger_function();


--
-- Name: usu_movimento trg_cloud_usu_movimento_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_usu_movimento_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.usu_movimento FOR EACH ROW EXECUTE FUNCTION public.cloud_usu_movimento_trigger_function();


--
-- Name: usuarios trg_cloud_usuarios_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_usuarios_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.usuarios FOR EACH ROW EXECUTE FUNCTION public.cloud_usuarios_trigger_function();


--
-- Name: venda_pag_antecipado_itens trg_cloud_venda_pag_antecipado_itens_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_venda_pag_antecipado_itens_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.venda_pag_antecipado_itens FOR EACH ROW EXECUTE FUNCTION public.cloud_venda_pag_antecipado_itens_trigger_function();


--
-- Name: venda_pag_antecipado trg_cloud_venda_pag_antecipado_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_venda_pag_antecipado_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.venda_pag_antecipado FOR EACH ROW EXECUTE FUNCTION public.cloud_venda_pag_antecipado_trigger_function();


--
-- Name: venda trg_cloud_venda_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_venda_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.venda FOR EACH ROW EXECUTE FUNCTION public.cloud_venda_trigger_function();


--
-- Name: vendaitem trg_cloud_vendaitem_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_vendaitem_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.vendaitem FOR EACH ROW EXECUTE FUNCTION public.cloud_vendaitem_trigger_function();


--
-- Name: vendaitemopcional trg_cloud_vendaitemopcional_transf_rpcheff_cloud; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cloud_vendaitemopcional_transf_rpcheff_cloud AFTER INSERT OR DELETE OR UPDATE ON public.vendaitemopcional FOR EACH ROW EXECUTE FUNCTION public.cloud_vendaitemopcional_trigger_function();


--
-- Name: usuarios usuarios_trigger_function; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER usuarios_trigger_function AFTER INSERT OR UPDATE ON public.usuarios FOR EACH ROW EXECUTE FUNCTION public.usuarios_trigger_function();


--
-- Name: ambiente fk_ambiente_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ambiente
    ADD CONSTRAINT fk_ambiente_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: bairro_ceps fk_bairro_ceps; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bairro_ceps
    ADD CONSTRAINT fk_bairro_ceps FOREIGN KEY (bai_001, emp_001) REFERENCES public.bairro(bai_001, emp_001) ON DELETE CASCADE;


--
-- Name: beneficios fk_beneficios_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficios
    ADD CONSTRAINT fk_beneficios_empresa FOREIGN KEY (emp_001) REFERENCES public.empresas(emp_001) ON DELETE CASCADE;


--
-- Name: bot_sinonimo fk_bot_sinonimo_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bot_sinonimo
    ADD CONSTRAINT fk_bot_sinonimo_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001) ON DELETE CASCADE;


--
-- Name: caixa fk_caixa_id_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixa
    ADD CONSTRAINT fk_caixa_id_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: caixa fk_caixa_id_usuario_fechamento; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixa
    ADD CONSTRAINT fk_caixa_id_usuario_fechamento FOREIGN KEY (id_usuario_fechamento, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: caixainformado fk_caixainformado_caixa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixainformado
    ADD CONSTRAINT fk_caixainformado_caixa FOREIGN KEY (id_empresa, id_caixa) REFERENCES public.caixa(id_empresa, id_caixa) ON DELETE CASCADE;


--
-- Name: caixainformado fk_caixainformado_formapgto; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixainformado
    ADD CONSTRAINT fk_caixainformado_formapgto FOREIGN KEY (id_formapgto, id_empresa) REFERENCES public.formapgto(for_001, emp_001);


--
-- Name: caixaitem fk_caixaitem_caixa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixaitem
    ADD CONSTRAINT fk_caixaitem_caixa FOREIGN KEY (id_caixa, id_empresa) REFERENCES public.caixa(id_caixa, id_empresa);


--
-- Name: caixaitem fk_caixaitem_cpagar; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixaitem
    ADD CONSTRAINT fk_caixaitem_cpagar FOREIGN KEY (id_cpagar, id_empresa) REFERENCES public.cpagar(id_cpagar, id_empresa);


--
-- Name: caixaitem fk_caixaitem_encerravendaitem; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixaitem
    ADD CONSTRAINT fk_caixaitem_encerravendaitem FOREIGN KEY (id_empresa, id_encerravenda, item_encerravenda) REFERENCES public.encerravendaitem(emp_001, enc_001, ite_001);


--
-- Name: caixaitem fk_caixaitem_formapgto; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixaitem
    ADD CONSTRAINT fk_caixaitem_formapgto FOREIGN KEY (id_formapgto, id_empresa) REFERENCES public.formapgto(for_001, emp_001);


--
-- Name: caixaitem fk_caixaitem_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixaitem
    ADD CONSTRAINT fk_caixaitem_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: caixaitem fk_caixaitem_venda; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixaitem
    ADD CONSTRAINT fk_caixaitem_venda FOREIGN KEY (id_venda, id_empresa) REFERENCES public.venda(ven_001, emp_001);


--
-- Name: composicao_fornecedor fk_composicao_fornecedor_composicao; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composicao_fornecedor
    ADD CONSTRAINT fk_composicao_fornecedor_composicao FOREIGN KEY (id_composicao, id_empresa) REFERENCES public.composicao(id_composicao, id_empresa) ON DELETE CASCADE;


--
-- Name: composicao_fornecedor fk_composicao_fornecedor_empresas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composicao_fornecedor
    ADD CONSTRAINT fk_composicao_fornecedor_empresas FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: composicao_fornecedor fk_composicao_fornecedor_fornecedor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composicao_fornecedor
    ADD CONSTRAINT fk_composicao_fornecedor_fornecedor FOREIGN KEY (id_fornecedor, id_empresa) REFERENCES public.fornecedor(id_fornecedor, id_empresa);


--
-- Name: composicao fk_composicao_setor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composicao
    ADD CONSTRAINT fk_composicao_setor FOREIGN KEY (id_setor, id_empresa) REFERENCES public.setor_estoque(id_setor, id_empresa);


--
-- Name: composicao fk_composicao_unidade; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composicao
    ADD CONSTRAINT fk_composicao_unidade FOREIGN KEY (id_unidade, id_empresa) REFERENCES public.unidades(uni_001, emp_001);


--
-- Name: condicaopagamento fk_condicaopagamento_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.condicaopagamento
    ADD CONSTRAINT fk_condicaopagamento_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: condicaopagamentoparcela fk_condicaopagamentoparcela_condicao; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.condicaopagamentoparcela
    ADD CONSTRAINT fk_condicaopagamentoparcela_condicao FOREIGN KEY (id_condicaopagamento, id_empresa) REFERENCES public.condicaopagamento(id_condicaopagamento, id_empresa) ON DELETE CASCADE;


--
-- Name: configuracao_wattsap fk_configuracao_wattsap_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracao_wattsap
    ADD CONSTRAINT fk_configuracao_wattsap_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001) ON DELETE CASCADE;


--
-- Name: conta fk_conta_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conta
    ADD CONSTRAINT fk_conta_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: contacorrente fk_contcacorrente_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacorrente
    ADD CONSTRAINT fk_contcacorrente_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: cpagar fk_cpagar_conta; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cpagar
    ADD CONSTRAINT fk_cpagar_conta FOREIGN KEY (id_conta, id_empresa) REFERENCES public.conta(id_conta, id_empresa);


--
-- Name: cpagar fk_cpagar_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cpagar
    ADD CONSTRAINT fk_cpagar_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: cpagar fk_cpagar_fornecedor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cpagar
    ADD CONSTRAINT fk_cpagar_fornecedor FOREIGN KEY (id_fornecedor, id_empresa) REFERENCES public.fornecedor(id_fornecedor, id_empresa);


--
-- Name: cpagar_parcela fk_cpagar_parcela; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cpagar_parcela
    ADD CONSTRAINT fk_cpagar_parcela FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: cpagar_parcela fk_cpagar_parcela_pagar; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cpagar_parcela
    ADD CONSTRAINT fk_cpagar_parcela_pagar FOREIGN KEY (id_empresa, id_cpagar) REFERENCES public.cpagar(id_empresa, id_cpagar) ON DELETE CASCADE;


--
-- Name: cpagar_parcela fk_cpagar_parcela_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cpagar_parcela
    ADD CONSTRAINT fk_cpagar_parcela_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: cpagar fk_cpagar_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cpagar
    ADD CONSTRAINT fk_cpagar_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: cpagar fk_cpagar_usuario_canc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cpagar
    ADD CONSTRAINT fk_cpagar_usuario_canc FOREIGN KEY (id_usuario_cancelamento, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: cpagar fk_cpagar_usuario_pag; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cpagar
    ADD CONSTRAINT fk_cpagar_usuario_pag FOREIGN KEY (id_usuario_pagamento, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: creceber fk_creceber_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creceber
    ADD CONSTRAINT fk_creceber_cliente FOREIGN KEY (id_cliente, id_empresa) REFERENCES public.clientes(cli_001, emp_001);


--
-- Name: creceber fk_creceber_conta; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creceber
    ADD CONSTRAINT fk_creceber_conta FOREIGN KEY (id_conta, id_empresa) REFERENCES public.conta(id_conta, id_empresa);


--
-- Name: creceber fk_creceber_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creceber
    ADD CONSTRAINT fk_creceber_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: creceber fk_creceber_fornecedor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creceber
    ADD CONSTRAINT fk_creceber_fornecedor FOREIGN KEY (id_fornecedor, id_empresa) REFERENCES public.fornecedor(id_fornecedor, id_empresa);


--
-- Name: creceber_parcela fk_creceber_parcela_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creceber_parcela
    ADD CONSTRAINT fk_creceber_parcela_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: creceber_parcela fk_creceber_parcela_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creceber_parcela
    ADD CONSTRAINT fk_creceber_parcela_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: creceber fk_creceber_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creceber
    ADD CONSTRAINT fk_creceber_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: creceber fk_creceber_usuario_canc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creceber
    ADD CONSTRAINT fk_creceber_usuario_canc FOREIGN KEY (id_usuario_cancelamento, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: creceber fk_creceber_usuario_pag; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creceber
    ADD CONSTRAINT fk_creceber_usuario_pag FOREIGN KEY (id_usuario_pagamento, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: quero_delivery_customer fk_customer_pedido; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quero_delivery_customer
    ADD CONSTRAINT fk_customer_pedido FOREIGN KEY (id_pedido) REFERENCES public.quero_delivery_pedidos(id_pedido);


--
-- Name: quero_delivery_delivery fk_delivery_pedido; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quero_delivery_delivery
    ADD CONSTRAINT fk_delivery_pedido FOREIGN KEY (id_pedido) REFERENCES public.quero_delivery_pedidos(id_pedido);


--
-- Name: desc_tamanho_material fk_desc_tamanho_material_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.desc_tamanho_material
    ADD CONSTRAINT fk_desc_tamanho_material_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: devolucaoitem fk_devolucaoitem_caixa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devolucaoitem
    ADD CONSTRAINT fk_devolucaoitem_caixa FOREIGN KEY (id_caixa, id_empresa) REFERENCES public.caixa(id_caixa, id_empresa);


--
-- Name: devolucaoitem fk_devolucaoitem_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devolucaoitem
    ADD CONSTRAINT fk_devolucaoitem_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: devolucaoitem fk_devolucaoitem_vendaitem; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devolucaoitem
    ADD CONSTRAINT fk_devolucaoitem_vendaitem FOREIGN KEY (id_venda, id_empresa, id_vendaitem) REFERENCES public.vendaitem(ven_001, emp_001, ite_001) ON DELETE CASCADE;


--
-- Name: quero_delivery_discount_sponsorship fk_discount_sponsor_pedido; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quero_delivery_discount_sponsorship
    ADD CONSTRAINT fk_discount_sponsor_pedido FOREIGN KEY (id_pedido) REFERENCES public.quero_delivery_pedidos(id_pedido);


--
-- Name: quero_delivery_discounts fk_discounts_pedido; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quero_delivery_discounts
    ADD CONSTRAINT fk_discounts_pedido FOREIGN KEY (id_pedido) REFERENCES public.quero_delivery_pedidos(id_pedido);


--
-- Name: encerravendaitem fk_encvenitem_formapgto; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encerravendaitem
    ADD CONSTRAINT fk_encvenitem_formapgto FOREIGN KEY (id_formapgto, emp_001) REFERENCES public.formapgto(for_001, emp_001);


--
-- Name: eventos_mesas fk_eventos_mesas_id_evento; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_mesas
    ADD CONSTRAINT fk_eventos_mesas_id_evento FOREIGN KEY (id_evento, emp_001) REFERENCES public.eventos(id_evento, emp_001);


--
-- Name: eventos_mesas fk_eventos_mesas_id_forma; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_mesas
    ADD CONSTRAINT fk_eventos_mesas_id_forma FOREIGN KEY (id_forma, emp_001) REFERENCES public.formapgto(for_001, emp_001);


--
-- Name: execucoes_estoque_item fk_ex_item_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.execucoes_estoque_item
    ADD CONSTRAINT fk_ex_item_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: execucoes_estoque_item fk_ex_item_ex; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.execucoes_estoque_item
    ADD CONSTRAINT fk_ex_item_ex FOREIGN KEY (id_mestre, id_empresa) REFERENCES public.execucoes_estoque(id, id_empresa) ON DELETE CASCADE;


--
-- Name: execucoes_estoque_item fk_ex_item_material; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.execucoes_estoque_item
    ADD CONSTRAINT fk_ex_item_material FOREIGN KEY (id_material, id_empresa) REFERENCES public.materiais(mat_001, emp_001);


--
-- Name: execucoes_estoque fk_execucoes_estoque_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.execucoes_estoque
    ADD CONSTRAINT fk_execucoes_estoque_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: formapgto fk_forma_conta_corrente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.formapgto
    ADD CONSTRAINT fk_forma_conta_corrente FOREIGN KEY (id_contacorrente, emp_001) REFERENCES public.contacorrente(id_contacorrente, id_empresa);


--
-- Name: formapgto fk_formapgto_conta; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.formapgto
    ADD CONSTRAINT fk_formapgto_conta FOREIGN KEY (id_conta, emp_001) REFERENCES public.conta(id_conta, id_empresa) ON DELETE SET NULL;


--
-- Name: fornecedor fk_fornecedor_cidade; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fornecedor
    ADD CONSTRAINT fk_fornecedor_cidade FOREIGN KEY (id_cidade) REFERENCES public.cidades(cid_001) ON DELETE SET NULL;


--
-- Name: fornecedor fk_fornecedor_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fornecedor
    ADD CONSTRAINT fk_fornecedor_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: fornecedor fk_fornecedor_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fornecedor
    ADD CONSTRAINT fk_fornecedor_usuario FOREIGN KEY (id_usuario_cadastro, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: tipo_movimento fk_id_conta_corrente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_movimento
    ADD CONSTRAINT fk_id_conta_corrente FOREIGN KEY (id_contacorrente, id_empresa) REFERENCES public.contacorrente(id_contacorrente, id_empresa);


--
-- Name: integracaostonepagarme_charge fk_integracaostonepagarme_charge_pedido; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaostonepagarme_charge
    ADD CONSTRAINT fk_integracaostonepagarme_charge_pedido FOREIGN KEY (id_pedido) REFERENCES public.integracaostonepagarme_pedido(id);


--
-- Name: quero_delivery_items fk_items_pedido; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quero_delivery_items
    ADD CONSTRAINT fk_items_pedido FOREIGN KEY (id_pedido) REFERENCES public.quero_delivery_pedidos(id_pedido);


--
-- Name: justificativa fk_justificativa_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.justificativa
    ADD CONSTRAINT fk_justificativa_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: lotes_materiais fk_lote_materiais_id_material; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lotes_materiais
    ADD CONSTRAINT fk_lote_materiais_id_material FOREIGN KEY (id_material, id_empresa) REFERENCES public.materiais(mat_001, emp_001) ON DELETE CASCADE;


--
-- Name: lotes_materiais fk_lote_materiais_id_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lotes_materiais
    ADD CONSTRAINT fk_lote_materiais_id_usuario FOREIGN KEY (id_usuario_lancamento, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: materiais_combo fk_materiais_combo_material; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_combo
    ADD CONSTRAINT fk_materiais_combo_material FOREIGN KEY (id_material, id_empresa) REFERENCES public.materiais(mat_001, emp_001) ON DELETE CASCADE;


--
-- Name: materiais_combo fk_materiais_combo_produto; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_combo
    ADD CONSTRAINT fk_materiais_combo_produto FOREIGN KEY (id_produto_combo, id_empresa) REFERENCES public.materiais(mat_001, emp_001);


--
-- Name: materiais_composicao fk_materiais_composicao_composicao; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_composicao
    ADD CONSTRAINT fk_materiais_composicao_composicao FOREIGN KEY (id_composicao, id_empresa) REFERENCES public.composicao(id_composicao, id_empresa);


--
-- Name: materiais_composicao fk_materiais_composicao_material; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_composicao
    ADD CONSTRAINT fk_materiais_composicao_material FOREIGN KEY (id_material, id_empresa) REFERENCES public.materiais(mat_001, emp_001) ON DELETE CASCADE;


--
-- Name: materiais_opcional fk_materiais_composicao_material; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_opcional
    ADD CONSTRAINT fk_materiais_composicao_material FOREIGN KEY (id_material, id_empresa) REFERENCES public.materiais(mat_001, emp_001) ON DELETE CASCADE;


--
-- Name: materiais fk_materiais_fornecedor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais
    ADD CONSTRAINT fk_materiais_fornecedor FOREIGN KEY (id_fornecedor, emp_001) REFERENCES public.fornecedor(id_fornecedor, id_empresa);


--
-- Name: materiais_fornecedor fk_materiais_fornecedor_empresas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_fornecedor
    ADD CONSTRAINT fk_materiais_fornecedor_empresas FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: materiais_fornecedor fk_materiais_fornecedor_fornecedor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_fornecedor
    ADD CONSTRAINT fk_materiais_fornecedor_fornecedor FOREIGN KEY (id_fornecedor, id_empresa) REFERENCES public.fornecedor(id_fornecedor, id_empresa);


--
-- Name: materiais_fornecedor fk_materiais_fornecedor_materiais; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_fornecedor
    ADD CONSTRAINT fk_materiais_fornecedor_materiais FOREIGN KEY (id_material, id_empresa) REFERENCES public.materiais(mat_001, emp_001) ON DELETE CASCADE;


--
-- Name: materiais fk_materiais_info_extra; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais
    ADD CONSTRAINT fk_materiais_info_extra FOREIGN KEY (emp_001, inf_001) REFERENCES public.balanca_info_extra(emp_001, inf_001);


--
-- Name: materiais fk_materiais_info_nutri; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais
    ADD CONSTRAINT fk_materiais_info_nutri FOREIGN KEY (emp_001, nut_001) REFERENCES public.balanca_info_nutri(emp_001, nut_001);


--
-- Name: materiais_lista_fornecedores fk_materiais_lista_id_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_lista_fornecedores
    ADD CONSTRAINT fk_materiais_lista_id_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: materiais_lista_fornecedores fk_materiais_lista_id_fornecedor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_lista_fornecedores
    ADD CONSTRAINT fk_materiais_lista_id_fornecedor FOREIGN KEY (id_empresa, id_fornecedor) REFERENCES public.fornecedor(id_empresa, id_fornecedor);


--
-- Name: materiais_lista_fornecedores fk_materiais_lista_id_material; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_lista_fornecedores
    ADD CONSTRAINT fk_materiais_lista_id_material FOREIGN KEY (id_material, id_empresa) REFERENCES public.materiais(mat_001, emp_001) ON DELETE CASCADE;


--
-- Name: materiais_log_precos fk_materiais_log_precos_materiais; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_log_precos
    ADD CONSTRAINT fk_materiais_log_precos_materiais FOREIGN KEY (id_material, id_empresa) REFERENCES public.materiais(mat_001, emp_001) ON DELETE CASCADE;


--
-- Name: materiais_opcional fk_materiais_opcional_opcional; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais_opcional
    ADD CONSTRAINT fk_materiais_opcional_opcional FOREIGN KEY (id_opcional, id_empresa) REFERENCES public.opcional(id_opcional, id_empresa);


--
-- Name: materiais fk_materiais_setor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais
    ADD CONSTRAINT fk_materiais_setor FOREIGN KEY (id_setor, emp_001) REFERENCES public.setor_estoque(id_setor, id_empresa);


--
-- Name: materiais fk_materiais_sub; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais
    ADD CONSTRAINT fk_materiais_sub FOREIGN KEY (sub_001, emp_001) REFERENCES public.subcategoria(sub_001, emp_001);


--
-- Name: materiais fk_materiais_tara; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materiais
    ADD CONSTRAINT fk_materiais_tara FOREIGN KEY (emp_001, tar_001) REFERENCES public.tara(emp_001, tar_001);


--
-- Name: mensagem_wattsap fk_mensagem_wattsap_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensagem_wattsap
    ADD CONSTRAINT fk_mensagem_wattsap_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001) ON DELETE CASCADE;


--
-- Name: movimento_estoque_composicao fk_movimento_estoque_composicao_fornecedor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimento_estoque_composicao
    ADD CONSTRAINT fk_movimento_estoque_composicao_fornecedor FOREIGN KEY (id_fornecedor, id_empresa) REFERENCES public.fornecedor(id_fornecedor, id_empresa);


--
-- Name: movimento_estoque_composicao fk_movimento_estoque_composicao_material; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimento_estoque_composicao
    ADD CONSTRAINT fk_movimento_estoque_composicao_material FOREIGN KEY (id_composicao, id_empresa) REFERENCES public.composicao(id_composicao, id_empresa);


--
-- Name: movimento_estoque_composicao fk_movimento_estoque_composicao_setor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimento_estoque_composicao
    ADD CONSTRAINT fk_movimento_estoque_composicao_setor FOREIGN KEY (id_setor, id_empresa) REFERENCES public.setor_estoque(id_setor, id_empresa);


--
-- Name: movimento_estoque_composicao fk_movimento_estoque_composicao_setor_destino; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimento_estoque_composicao
    ADD CONSTRAINT fk_movimento_estoque_composicao_setor_destino FOREIGN KEY (id_setor_destino, id_empresa) REFERENCES public.setor_estoque(id_setor, id_empresa);


--
-- Name: movimento_estoque_composicao fk_movimento_estoque_composicao_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimento_estoque_composicao
    ADD CONSTRAINT fk_movimento_estoque_composicao_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: movimento_estoque_composicao fk_movimento_estoque_composicao_vendaitem; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimento_estoque_composicao
    ADD CONSTRAINT fk_movimento_estoque_composicao_vendaitem FOREIGN KEY (id_vendaitem, id_empresa, id_venda) REFERENCES public.vendaitem(ite_001, emp_001, ven_001);


--
-- Name: movimento_estoque_composicao fk_movimento_estoque_composicaoe_venda; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimento_estoque_composicao
    ADD CONSTRAINT fk_movimento_estoque_composicaoe_venda FOREIGN KEY (id_empresa, id_venda) REFERENCES public.venda(emp_001, ven_001);


--
-- Name: movimentocontacliente fk_movimentocontacliente_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentocontacliente
    ADD CONSTRAINT fk_movimentocontacliente_cliente FOREIGN KEY (id_cliente, id_empresa) REFERENCES public.clientes(cli_001, emp_001);


--
-- Name: movimentocontacliente fk_movimentocontacliente_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentocontacliente
    ADD CONSTRAINT fk_movimentocontacliente_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: movimentocontacliente fk_movimentocontacliente_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentocontacliente
    ADD CONSTRAINT fk_movimentocontacliente_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: movimentocontacliente fk_movimentocontacliente_venda; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentocontacliente
    ADD CONSTRAINT fk_movimentocontacliente_venda FOREIGN KEY (id_venda, id_empresa) REFERENCES public.venda(ven_001, emp_001);


--
-- Name: movimentocontacorrente fk_movimentocontacorrente_contacorrente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentocontacorrente
    ADD CONSTRAINT fk_movimentocontacorrente_contacorrente FOREIGN KEY (id_contacorrente, id_empresa) REFERENCES public.contacorrente(id_contacorrente, id_empresa);


--
-- Name: movimentocontacorrente fk_movimentocontacorrente_cpagar; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentocontacorrente
    ADD CONSTRAINT fk_movimentocontacorrente_cpagar FOREIGN KEY (id_empresa, id_cpagar) REFERENCES public.cpagar(id_empresa, id_cpagar);


--
-- Name: movimentocontacorrente fk_movimentocontacorrente_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentocontacorrente
    ADD CONSTRAINT fk_movimentocontacorrente_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: movimentocontacorrente fk_movimentocontacorrente_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentocontacorrente
    ADD CONSTRAINT fk_movimentocontacorrente_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: movimentoestoque fk_movimentoestoque_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentoestoque
    ADD CONSTRAINT fk_movimentoestoque_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: movimentoestoque fk_movimentoestoque_fornecedor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentoestoque
    ADD CONSTRAINT fk_movimentoestoque_fornecedor FOREIGN KEY (id_fornecedor, id_empresa) REFERENCES public.fornecedor(id_fornecedor, id_empresa);


--
-- Name: movimentoestoque fk_movimentoestoque_material; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentoestoque
    ADD CONSTRAINT fk_movimentoestoque_material FOREIGN KEY (id_material, id_empresa) REFERENCES public.materiais(mat_001, emp_001);


--
-- Name: movimentoestoque fk_movimentoestoque_setor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentoestoque
    ADD CONSTRAINT fk_movimentoestoque_setor FOREIGN KEY (id_setor, id_empresa) REFERENCES public.setor_estoque(id_setor, id_empresa);


--
-- Name: movimentoestoque fk_movimentoestoque_setor_destino; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentoestoque
    ADD CONSTRAINT fk_movimentoestoque_setor_destino FOREIGN KEY (id_setor_destino, id_empresa) REFERENCES public.setor_estoque(id_setor, id_empresa);


--
-- Name: movimentoestoque fk_movimentoestoque_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentoestoque
    ADD CONSTRAINT fk_movimentoestoque_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: movimentoestoque fk_movimentoestoque_venda; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentoestoque
    ADD CONSTRAINT fk_movimentoestoque_venda FOREIGN KEY (id_empresa, id_venda) REFERENCES public.venda(emp_001, ven_001);


--
-- Name: movimentoestoque fk_movimentoestoque_vendaitem; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimentoestoque
    ADD CONSTRAINT fk_movimentoestoque_vendaitem FOREIGN KEY (id_vendaitem, id_empresa, id_venda) REFERENCES public.vendaitem(ite_001, emp_001, ven_001);


--
-- Name: nota_entrada fk_nota_entrada_cfop; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada
    ADD CONSTRAINT fk_nota_entrada_cfop FOREIGN KEY (cfop) REFERENCES public.cfop(cfop_codigo);


--
-- Name: nota_entrada_doc_referenciado fk_nota_entrada_doc_referenciado_nota; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada_doc_referenciado
    ADD CONSTRAINT fk_nota_entrada_doc_referenciado_nota FOREIGN KEY (id_nota_entrada, id_empresa) REFERENCES public.nota_entrada(id_nota_entrada, id_empresa);


--
-- Name: nota_entrada_duplicata fk_nota_entrada_duplicata_nota; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada_duplicata
    ADD CONSTRAINT fk_nota_entrada_duplicata_nota FOREIGN KEY (id_nota_entrada, id_empresa) REFERENCES public.nota_entrada(id_nota_entrada, id_empresa);


--
-- Name: nota_entrada fk_nota_entrada_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada
    ADD CONSTRAINT fk_nota_entrada_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: nota_entrada fk_nota_entrada_fornecedor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada
    ADD CONSTRAINT fk_nota_entrada_fornecedor FOREIGN KEY (id_fornecedor, id_empresa) REFERENCES public.fornecedor(id_fornecedor, id_empresa);


--
-- Name: nota_entrada_item fk_nota_entrada_item_composicao; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada_item
    ADD CONSTRAINT fk_nota_entrada_item_composicao FOREIGN KEY (id_composicao, id_empresa) REFERENCES public.composicao(id_composicao, id_empresa);


--
-- Name: nota_entrada_item fk_nota_entrada_item_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada_item
    ADD CONSTRAINT fk_nota_entrada_item_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: nota_entrada_item fk_nota_entrada_item_material; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada_item
    ADD CONSTRAINT fk_nota_entrada_item_material FOREIGN KEY (id_material, id_empresa) REFERENCES public.materiais(mat_001, emp_001);


--
-- Name: nota_entrada_item fk_nota_entrada_item_nota_entrada; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada_item
    ADD CONSTRAINT fk_nota_entrada_item_nota_entrada FOREIGN KEY (id_nota_entrada, id_empresa) REFERENCES public.nota_entrada(id_nota_entrada, id_empresa);


--
-- Name: nota_entrada fk_nota_entrada_transportador; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada
    ADD CONSTRAINT fk_nota_entrada_transportador FOREIGN KEY (id_transportador, id_empresa) REFERENCES public.fornecedor(id_fornecedor, id_empresa);


--
-- Name: nota_entrada fk_nota_entrada_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_entrada
    ADD CONSTRAINT fk_nota_entrada_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: nota_saida fk_nota_saida_cfop; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida
    ADD CONSTRAINT fk_nota_saida_cfop FOREIGN KEY (cfop) REFERENCES public.cfop(cfop_codigo);


--
-- Name: nota_saida fk_nota_saida_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida
    ADD CONSTRAINT fk_nota_saida_cliente FOREIGN KEY (id_cliente, id_empresa) REFERENCES public.clientes(cli_001, emp_001);


--
-- Name: nota_saida_doc_referenciado fk_nota_saida_doc_referenciado_nota; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida_doc_referenciado
    ADD CONSTRAINT fk_nota_saida_doc_referenciado_nota FOREIGN KEY (id_nota_saida, id_empresa) REFERENCES public.nota_saida(id_nota_saida, id_empresa);


--
-- Name: nota_saida_duplicata fk_nota_saida_duplicata_nota; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida_duplicata
    ADD CONSTRAINT fk_nota_saida_duplicata_nota FOREIGN KEY (id_nota_saida, id_empresa) REFERENCES public.nota_saida(id_nota_saida, id_empresa);


--
-- Name: nota_saida fk_nota_saida_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida
    ADD CONSTRAINT fk_nota_saida_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: nota_saida_item fk_nota_saida_item_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida_item
    ADD CONSTRAINT fk_nota_saida_item_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: nota_saida_item fk_nota_saida_item_material; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida_item
    ADD CONSTRAINT fk_nota_saida_item_material FOREIGN KEY (id_material, id_empresa) REFERENCES public.materiais(mat_001, emp_001);


--
-- Name: nota_saida_item fk_nota_saida_item_nota_saida; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida_item
    ADD CONSTRAINT fk_nota_saida_item_nota_saida FOREIGN KEY (id_nota_saida, id_empresa) REFERENCES public.nota_saida(id_nota_saida, id_empresa);


--
-- Name: nota_saida_pagamentos fk_nota_saida_pagamento_nota; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida_pagamentos
    ADD CONSTRAINT fk_nota_saida_pagamento_nota FOREIGN KEY (id_nota_saida, id_empresa) REFERENCES public.nota_saida(id_nota_saida, id_empresa);


--
-- Name: nota_saida fk_nota_saida_transportador; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida
    ADD CONSTRAINT fk_nota_saida_transportador FOREIGN KEY (id_transportador, id_empresa) REFERENCES public.fornecedor(id_fornecedor, id_empresa);


--
-- Name: nota_saida fk_nota_saida_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saida
    ADD CONSTRAINT fk_nota_saida_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: opcional fk_opcional_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opcional
    ADD CONSTRAINT fk_opcional_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: quero_delivery_other_fees fk_other_fees_pedido; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quero_delivery_other_fees
    ADD CONSTRAINT fk_other_fees_pedido FOREIGN KEY (id_pedido) REFERENCES public.quero_delivery_pedidos(id_pedido);


--
-- Name: quero_delivery_payments fk_payments_pedido; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quero_delivery_payments
    ADD CONSTRAINT fk_payments_pedido FOREIGN KEY (id_pedido) REFERENCES public.quero_delivery_pedidos(id_pedido);


--
-- Name: pedido_compra_item fk_ped_item_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_compra_item
    ADD CONSTRAINT fk_ped_item_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: pedido_compra_item fk_ped_item_material; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_compra_item
    ADD CONSTRAINT fk_ped_item_material FOREIGN KEY (id_material, id_empresa) REFERENCES public.materiais(mat_001, emp_001);


--
-- Name: pedido_compra_item fk_ped_item_ped; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_compra_item
    ADD CONSTRAINT fk_ped_item_ped FOREIGN KEY (id_pedido, id_empresa) REFERENCES public.pedido_compra(id, id_empresa) ON DELETE CASCADE;


--
-- Name: pedido_compra_duplicata fk_pedido_compra_duplicata_ped; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_compra_duplicata
    ADD CONSTRAINT fk_pedido_compra_duplicata_ped FOREIGN KEY (id_pedido, id_empresa) REFERENCES public.pedido_compra(id, id_empresa);


--
-- Name: pedido_compra fk_pedido_compra_fornecedor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_compra
    ADD CONSTRAINT fk_pedido_compra_fornecedor FOREIGN KEY (id_fornecedor, id_empresa) REFERENCES public.fornecedor(id_fornecedor, id_empresa);


--
-- Name: pedido_compra fk_pedido_compra_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_compra
    ADD CONSTRAINT fk_pedido_compra_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: perfil_consumo fk_perfil_consumo_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfil_consumo
    ADD CONSTRAINT fk_perfil_consumo_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: promocao fk_promocao_idempresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promocao
    ADD CONSTRAINT fk_promocao_idempresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: promocao fk_promocao_idmaterial; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promocao
    ADD CONSTRAINT fk_promocao_idmaterial FOREIGN KEY (id_material, id_empresa) REFERENCES public.materiais(mat_001, emp_001) ON DELETE CASCADE;


--
-- Name: sessao_wattsap fk_sessao_wattsap_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessao_wattsap
    ADD CONSTRAINT fk_sessao_wattsap_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001) ON DELETE CASCADE;


--
-- Name: setor_estoque fk_setor_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setor_estoque
    ADD CONSTRAINT fk_setor_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: setor_estoque_composicao fk_setor_estoque_composicao_composicao; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setor_estoque_composicao
    ADD CONSTRAINT fk_setor_estoque_composicao_composicao FOREIGN KEY (id_composicao, id_empresa) REFERENCES public.composicao(id_composicao, id_empresa);


--
-- Name: setor_estoque_composicao fk_setor_estoque_composicao_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setor_estoque_composicao
    ADD CONSTRAINT fk_setor_estoque_composicao_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: setor_estoque_composicao fk_setor_estoque_composicao_setor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setor_estoque_composicao
    ADD CONSTRAINT fk_setor_estoque_composicao_setor FOREIGN KEY (id_setor, id_empresa) REFERENCES public.setor_estoque(id_setor, id_empresa);


--
-- Name: setor_estoque_material fk_setor_estoque_material_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setor_estoque_material
    ADD CONSTRAINT fk_setor_estoque_material_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: setor_estoque_material fk_setor_estoque_material_material; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setor_estoque_material
    ADD CONSTRAINT fk_setor_estoque_material_material FOREIGN KEY (id_material, id_empresa) REFERENCES public.materiais(mat_001, emp_001);


--
-- Name: setor_estoque_material fk_setor_estoque_material_setor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setor_estoque_material
    ADD CONSTRAINT fk_setor_estoque_material_setor FOREIGN KEY (id_setor, id_empresa) REFERENCES public.setor_estoque(id_setor, id_empresa);


--
-- Name: trocogarcom fk_trocogarcom_caixa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trocogarcom
    ADD CONSTRAINT fk_trocogarcom_caixa FOREIGN KEY (id_caixa, id_empresa) REFERENCES public.caixa(id_caixa, id_empresa);


--
-- Name: usuarios fk_usuarios_emp_001; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT fk_usuarios_emp_001 FOREIGN KEY (emp_001) REFERENCES public.empresas(emp_001);


--
-- Name: venda fk_venda_caixa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda
    ADD CONSTRAINT fk_venda_caixa FOREIGN KEY (id_caixa_abertura, emp_001) REFERENCES public.caixa(id_caixa, id_empresa);


--
-- Name: venda fk_venda_entregador; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda
    ADD CONSTRAINT fk_venda_entregador FOREIGN KEY (id_entregador, emp_001) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: venda fk_venda_idgarcom_abertura; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda
    ADD CONSTRAINT fk_venda_idgarcom_abertura FOREIGN KEY (id_garcom_abertura, emp_001) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: venda_pag_antecipado fk_venda_pag_antecipado; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda_pag_antecipado
    ADD CONSTRAINT fk_venda_pag_antecipado FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: venda_pag_antecipado fk_venda_pag_antecipado_caixaitem; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda_pag_antecipado
    ADD CONSTRAINT fk_venda_pag_antecipado_caixaitem FOREIGN KEY (id_caixa, id_caixaitem, id_empresa) REFERENCES public.caixaitem(id_caixa, item, id_empresa);


--
-- Name: venda_pag_antecipado fk_venda_pag_antecipado_forma; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda_pag_antecipado
    ADD CONSTRAINT fk_venda_pag_antecipado_forma FOREIGN KEY (id_formapgto, id_empresa) REFERENCES public.formapgto(for_001, emp_001);


--
-- Name: venda_pag_antecipado fk_venda_pag_antecipado_venda; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda_pag_antecipado
    ADD CONSTRAINT fk_venda_pag_antecipado_venda FOREIGN KEY (id_venda, id_empresa) REFERENCES public.venda(ven_001, emp_001);


--
-- Name: venda fk_venda_perfil_consumo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda
    ADD CONSTRAINT fk_venda_perfil_consumo FOREIGN KEY (id_perfil_consumo) REFERENCES public.perfil_consumo(id_perfil_consumo);


--
-- Name: venda_pre_pago fk_venda_pre_pago_forma; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda_pre_pago
    ADD CONSTRAINT fk_venda_pre_pago_forma FOREIGN KEY (id_formapgto, id_empresa) REFERENCES public.formapgto(for_001, emp_001);


--
-- Name: venda_pre_pago fk_venda_pre_pago_venda; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda_pre_pago
    ADD CONSTRAINT fk_venda_pre_pago_venda FOREIGN KEY (id_venda, id_empresa) REFERENCES public.venda(ven_001, emp_001) ON DELETE CASCADE;


--
-- Name: vendaitem fk_vendaitem_material; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendaitem
    ADD CONSTRAINT fk_vendaitem_material FOREIGN KEY (mat_001, emp_001) REFERENCES public.materiais(mat_001, emp_001);


--
-- Name: vendaitem fk_vendaitem_usuario_canc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendaitem
    ADD CONSTRAINT fk_vendaitem_usuario_canc FOREIGN KEY (id_usuario_cancelamento, emp_001) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: vendaitem fk_vendaitem_venda; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendaitem
    ADD CONSTRAINT fk_vendaitem_venda FOREIGN KEY (ven_001, emp_001) REFERENCES public.venda(ven_001, emp_001);


--
-- Name: vendaitemopcional fk_vendaopcionais_opcional; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendaitemopcional
    ADD CONSTRAINT fk_vendaopcionais_opcional FOREIGN KEY (id_opcional, id_empresa) REFERENCES public.opcional(id_opcional, id_empresa) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: vendaitemopcional fk_vendaopcionais_vendaitem; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendaitemopcional
    ADD CONSTRAINT fk_vendaopcionais_vendaitem FOREIGN KEY (id_venda, id_empresa, id_vendaitem) REFERENCES public.vendaitem(ven_001, emp_001, ite_001) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: integracao99foodpedidocliente integracao99foodpedidocliente_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidocliente
    ADD CONSTRAINT integracao99foodpedidocliente_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.integracao99foodpedido(id) ON DELETE CASCADE;


--
-- Name: integracao99foodpedidoendereco integracao99foodpedidoendereco_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidoendereco
    ADD CONSTRAINT integracao99foodpedidoendereco_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.integracao99foodpedido(id) ON DELETE CASCADE;


--
-- Name: integracao99foodpedidoitem integracao99foodpedidoitem_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidoitem
    ADD CONSTRAINT integracao99foodpedidoitem_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.integracao99foodpedido(id) ON DELETE CASCADE;


--
-- Name: integracao99foodpedidoopcional integracao99foodpedidoopcional_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidoopcional
    ADD CONSTRAINT integracao99foodpedidoopcional_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.integracao99foodpedido(id) ON DELETE CASCADE;


--
-- Name: integracao99foodpedidoopcional integracao99foodpedidoopcional_pedido_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidoopcional
    ADD CONSTRAINT integracao99foodpedidoopcional_pedido_item_id_fkey FOREIGN KEY (pedido_item_id) REFERENCES public.integracao99foodpedidoitem(id) ON DELETE CASCADE;


--
-- Name: integracao99foodpedidopagamento integracao99foodpedidopagamento_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidopagamento
    ADD CONSTRAINT integracao99foodpedidopagamento_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.integracao99foodpedido(id) ON DELETE CASCADE;


--
-- Name: integracao99foodpedidostatus integracao99foodpedidostatus_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracao99foodpedidostatus
    ADD CONSTRAINT integracao99foodpedidostatus_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.integracao99foodpedido(id) ON DELETE CASCADE;


--
-- Name: integracaoanotaaicheckpoint integracaoanotaaicheckpoint_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaicheckpoint
    ADD CONSTRAINT integracaoanotaaicheckpoint_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.integracaoanotaaiconfig(id) ON DELETE CASCADE;


--
-- Name: integracaoanotaaihttplog integracaoanotaaihttplog_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaihttplog
    ADD CONSTRAINT integracaoanotaaihttplog_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.integracaoanotaaiconfig(id) ON DELETE SET NULL;


--
-- Name: integracaoanotaaiinbox integracaoanotaaiinbox_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaiinbox
    ADD CONSTRAINT integracaoanotaaiinbox_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.integracaoanotaaiconfig(id) ON DELETE SET NULL;


--
-- Name: integracaoanotaaimenusync integracaoanotaaimenusync_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaimenusync
    ADD CONSTRAINT integracaoanotaaimenusync_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.integracaoanotaaiconfig(id) ON DELETE SET NULL;


--
-- Name: integracaoanotaaioutbox integracaoanotaaioutbox_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaioutbox
    ADD CONSTRAINT integracaoanotaaioutbox_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.integracaoanotaaiconfig(id) ON DELETE SET NULL;


--
-- Name: integracaoanotaaipedido integracaoanotaaipedido_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaipedido
    ADD CONSTRAINT integracaoanotaaipedido_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.integracaoanotaaiconfig(id) ON DELETE SET NULL;


--
-- Name: integracaoanotaaipedidoitem integracaoanotaaipedidoitem_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaipedidoitem
    ADD CONSTRAINT integracaoanotaaipedidoitem_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.integracaoanotaaipedido(id) ON DELETE CASCADE;


--
-- Name: integracaoanotaaipedidoopcional integracaoanotaaipedidoopcional_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaipedidoopcional
    ADD CONSTRAINT integracaoanotaaipedidoopcional_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.integracaoanotaaipedido(id) ON DELETE CASCADE;


--
-- Name: integracaoanotaaipedidoopcional integracaoanotaaipedidoopcional_pedido_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaipedidoopcional
    ADD CONSTRAINT integracaoanotaaipedidoopcional_pedido_item_id_fkey FOREIGN KEY (pedido_item_id) REFERENCES public.integracaoanotaaipedidoitem(id) ON DELETE CASCADE;


--
-- Name: integracaoanotaaipedidostatus integracaoanotaaipedidostatus_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaoanotaaipedidostatus
    ADD CONSTRAINT integracaoanotaaipedidostatus_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.integracaoanotaaipedido(id) ON DELETE CASCADE;


--
-- Name: integracaodeliverydiretocatalogomapa integracaodeliverydiretocatalogomapa_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretocatalogomapa
    ADD CONSTRAINT integracaodeliverydiretocatalogomapa_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.integracaodeliverydiretoconfig(id) ON DELETE SET NULL;


--
-- Name: integracaodeliverydiretocheckpoint integracaodeliverydiretocheckpoint_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretocheckpoint
    ADD CONSTRAINT integracaodeliverydiretocheckpoint_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.integracaodeliverydiretoconfig(id) ON DELETE CASCADE;


--
-- Name: integracaodeliverydiretohttplog integracaodeliverydiretohttplog_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretohttplog
    ADD CONSTRAINT integracaodeliverydiretohttplog_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.integracaodeliverydiretoconfig(id) ON DELETE SET NULL;


--
-- Name: integracaodeliverydiretooutbox integracaodeliverydiretooutbox_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretooutbox
    ADD CONSTRAINT integracaodeliverydiretooutbox_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.integracaodeliverydiretoconfig(id) ON DELETE SET NULL;


--
-- Name: integracaodeliverydiretopedido integracaodeliverydiretopedido_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretopedido
    ADD CONSTRAINT integracaodeliverydiretopedido_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.integracaodeliverydiretoconfig(id) ON DELETE SET NULL;


--
-- Name: integracaodeliverydiretopedidoitem integracaodeliverydiretopedidoitem_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretopedidoitem
    ADD CONSTRAINT integracaodeliverydiretopedidoitem_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.integracaodeliverydiretopedido(id) ON DELETE CASCADE;


--
-- Name: integracaodeliverydiretopedidoopcional integracaodeliverydiretopedidoopcional_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretopedidoopcional
    ADD CONSTRAINT integracaodeliverydiretopedidoopcional_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.integracaodeliverydiretopedido(id) ON DELETE CASCADE;


--
-- Name: integracaodeliverydiretopedidoopcional integracaodeliverydiretopedidoopcional_pedido_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretopedidoopcional
    ADD CONSTRAINT integracaodeliverydiretopedidoopcional_pedido_item_id_fkey FOREIGN KEY (pedido_item_id) REFERENCES public.integracaodeliverydiretopedidoitem(id) ON DELETE CASCADE;


--
-- Name: integracaodeliverydiretopedidostatus integracaodeliverydiretopedidostatus_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretopedidostatus
    ADD CONSTRAINT integracaodeliverydiretopedidostatus_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.integracaodeliverydiretopedido(id) ON DELETE CASCADE;


--
-- Name: integracaodeliverydiretowebhookinbox integracaodeliverydiretowebhookinbox_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integracaodeliverydiretowebhookinbox
    ADD CONSTRAINT integracaodeliverydiretowebhookinbox_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.integracaodeliverydiretoconfig(id) ON DELETE SET NULL;


--
-- Name: creceber_parcela pk_creceber_parcela_creceber; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.creceber_parcela
    ADD CONSTRAINT pk_creceber_parcela_creceber FOREIGN KEY (id_creceber, id_empresa) REFERENCES public.creceber(id_creceber, id_empresa) ON DELETE CASCADE;


--
-- Name: trocogarcom pk_trocogarcom_empresa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trocogarcom
    ADD CONSTRAINT pk_trocogarcom_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresas(emp_001);


--
-- Name: trocogarcom pk_trocogarcom_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trocogarcom
    ADD CONSTRAINT pk_trocogarcom_usuario FOREIGN KEY (id_usuario, id_empresa) REFERENCES public.usuarios(usu_001, emp_001);


--
-- Name: trocogarcom pk_trocogarcom_venda; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trocogarcom
    ADD CONSTRAINT pk_trocogarcom_venda FOREIGN KEY (id_venda, id_empresa) REFERENCES public.venda(ven_001, emp_001);


--
-- PostgreSQL database dump complete
--

\unrestrict BfupHwy5q0l0XZvidnfoO8bHTVG5UDZ3lTbjVhu9lKMPScT3RLpePB1lXs11zWf

