--
-- PostgreSQL database dump
--

\restrict xMH1fXWlrZ4JQLl1zzNpYed1RiaLlXCDT2kmEy2quz1xXPjV85ly2EW5hugfcSa

-- Dumped from database version 17.2
-- Dumped by pg_dump version 17.2

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
-- Data for Name: bairro; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bairro (bai_001, emp_001, bai_002, bai_003, sit_001, b_restricao_entrega) FROM stdin;
\.


--
-- Data for Name: bairro_ceps; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bairro_ceps (bai_001, emp_001, cep, logradouro, id_cidade, cidade_desc, uf_sigla) FROM stdin;
\.


--
-- Data for Name: clientes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clientes (id_empresa, cli_004, sit_001, observacao, senha_email, pontos_atuais, email, tipo_pessoa, celular1, cli_001, cli_012, cli_002) FROM stdin;
\.


--
-- Data for Name: clientes_endereco; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clientes_endereco (id_endereco, cli_001, id_empresa, cep_002, cep_003, cep_004, cli_007, cli_008, cli_009, bai_001, endereco_padrao, taxa, idcidade, uf) FROM stdin;
\.


--
-- Data for Name: configuracao_funcionamento; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.configuracao_funcionamento (dia_segunda, dia_terca, dia_quarta, dia_quinta, dia_sexta, dia_sabado, dia_domingo, segunda_inicio_atendimento, terca_inicio_atendimento, quarta_inicio_atendimento, quinta_inicio_atendimento, sexta_inicio_atendimento, sabado_inicio_atendimento, domingo_inicio_atendimento, segunda_fim_atendimento, terca_fim_atendimento, quarta_fim_atendimento, quinta_fim_atendimento, sexta_fim_atendimento, sabado_fim_atendimento, domingo_fim_atendimento, id_empresa, id) FROM stdin;
\.


--
-- Data for Name: configuracao_rpfood; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.configuracao_rpfood (id_empresa, tempo_retirada_rpfood, tempo_entrega_rpfood, utiliza_tipo_entrega_retirada, modo_acougue, pedido_minimo, id, utiliza_controle_opcionais, utiliza_controle_ceps) FROM stdin;
\.


--
-- Data for Name: empresas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.empresas (descricao, codiuf, codicidade, uf, cidade, bairro, endereco, tipoendereco, nome, razsoc, cnpj, cep, numero, fone1, descrifone1, ddd1, email, site, complemento, id_situacao, inscricao_estadual, id_empresa) FROM stdin;
\.


--
-- Data for Name: formapgto; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.formapgto (id, id_empresa, descricao, id_situacao, b_venda_web, sfi_codigo) FROM stdin;
\.


--
-- Data for Name: grupos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grupos (codigo, descricao, img, id_situacao, id_empresa, b_exibir_web) FROM stdin;
\.


--
-- Data for Name: happy_hour; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.happy_hour (id, idproduto, idempresa, horainicial, horafinal, segundafeira, tercafeira, quartafeira, quintafeira, sextafeira, sabado, domingo, valor, utiliza_mesa, utiliza_delivery) FROM stdin;
\.


--
-- Data for Name: mesa; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mesa (mes_001, emp_001, mes_002, mes_003, id_situacao) FROM stdin;
\.


--
-- Data for Name: opcional; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.opcional (codigo, id_empresa, descricao, valor, id_situacao, opc_p, opc_m, opc_g, opc_extra, valor_opc_p, valor_opc_g, valor_opc_m, valor_opc_gg, valor_opc_extra, tipo, opc_gg, imagem_db) FROM stdin;
\.


--
-- Data for Name: produtos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.produtos (codigo, descricao, codigrupo, valfinal, valcompra, observacao, img1, img2, img, id_situacao, id_empresa, b_venda_web, utiliza_combo, b_destaque_web, b_permite_frac, tamanho_p, tamanho_m, tamanho_g, tamanho_gg, tamanho_extra, tamanho_padrao, valor_tam_p, valor_tam_m, valor_tam_g, valor_tam_gg, b_venda_tamanho, valor_tam_extra, b_carrossel, utiliza_promocao, b_exporta_peso_balanca, b_peso_balanca, restringirvenda, utiliza_happy_hour, opcional_minimo, opcional_maximo) FROM stdin;
\.


--
-- Data for Name: produtos_opcional; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.produtos_opcional (id_empresa, id_material, id_opcional) FROM stdin;
\.


--
-- Data for Name: promocao; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.promocao (id_promocao, id_empresa, id_material, tipo_desconto, segundafeira, tercafeira, quartafeira, quintafeira, sextafeira, sabado, domingo, tipomesa, tipodelivery, tipocomanda, descontosegundapadrao, descontosegundatamanhop, descontosegundatamanhom, descontosegundatamanhog, descontosegundatamanhogg, descontosegundatamanhoextra, desconto_ter_padrao, desconto_ter_tam_p, desconto_ter_tam_m, desconto_ter_tam_g, desconto_ter_tam_gg, desconto_ter_tam_extra, desconto_qua_padrao, desconto_qua_tam_p, desconto_qua_tam_m, desconto_qua_tam_g, desconto_qua_tam_gg, desconto_qua_tam_extra, desconto_qui_padrao, desconto_qui_tam_p, desconto_qui_tam_m, desconto_qui_tam_g, desconto_qui_tam_gg, desconto_qui_tam_extra, desconto_sex_padrao, desconto_sex_tam_p, desconto_sex_tam_m, desconto_sex_tam_g, desconto_sex_tam_gg, desconto_sex_tam_extra, desconto_sab_padrao, desconto_sab_tam_p, desconto_sab_tam_m, desconto_sab_tam_g, desconto_sab_tam_gg, desconto_sab_tam_extra, desconto_dom_padrao, desconto_dom_tam_p, desconto_dom_tam_m, desconto_dom_tam_g, desconto_dom_tam_gg, desconto_dom_tam_extra) FROM stdin;
\.


--
-- Data for Name: restricoesvendas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.restricoesvendas (idempresa, idproduto, segundafeira, tercafeira, quartafeira, quintafeira, sextafeira, sabado, domingo) FROM stdin;
\.


--
-- Data for Name: sincronizacao; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sincronizacao (id, data, id_empresa) FROM stdin;
1	2025-02-25 14:31:30.057584	1
\.


--
-- Data for Name: transferencia_imagens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transferencia_imagens (id, tipo, id_empresa, id_registro) FROM stdin;
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios (codigo, nome, senha, email, id_situacao) FROM stdin;
\.


--
-- Data for Name: usuarios_empresa; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios_empresa (codigo_usuario, id_empresa) FROM stdin;
\.


--
-- Data for Name: usuarios_permissoes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios_permissoes (codigo_usuario, b_acesso_web, b_admin_web, id_empresa) FROM stdin;
\.


--
-- Data for Name: venda; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.venda (id_venda, id_empresa, id_situacao, id_formapgto, id_cliente, totals_products, sub_total, taxa_entrega, troco, valor_receber, sales, data_pedido, b_recebido_lecheff, tipo_entrega, observacao) FROM stdin;
\.


--
-- Data for Name: venda_endereco; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.venda_endereco (id_venda, id_cliente, id_bairro, cep, logradouro, numero, complemento, ponto_referencia, bairro_desc, id_endereco) FROM stdin;
\.


--
-- Data for Name: vendaitem; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vendaitem (id_venda, id_empresa, id_product, numero_item, quantidade, valor_unit_product, totals_products, id_situacao, tamanho, b_venda_tamanho, item_fracionado, observacao, utilizou_happy_hour) FROM stdin;
\.


--
-- Data for Name: vendaitemopcional; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vendaitemopcional (id_venda, id_empresa, id_numero_item, id_opcional, gratis, valor, valorunitario, valortotal, quantidade, quantidade_replicar, b_recebido_lecheff) FROM stdin;
\.


--
-- Data for Name: vendamesa; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vendamesa (id_venda, id_empresa, id_situacao, totals_products, sub_total, sales, data_pedido, b_recebido_lecheff, observacao, numero_mesa, descricao_mesa) FROM stdin;
\.


--
-- Data for Name: vendamesaitem; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vendamesaitem (id_venda, id_empresa, id_product, numero_item, quantidade, valor_unit_product, totals_products, id_situacao, tamanho, b_venda_tamanho, item_fracionado, observacao, b_recebido_lecheff, utilizou_happy_hour, utilizou_promocao) FROM stdin;
\.


--
-- Data for Name: vendas_status_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vendas_status_log (id_venda, id_empresa, id_situacao, data) FROM stdin;
\.


--
-- Name: clientes_cli_001_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.clientes_cli_001_seq', 1, true);


--
-- Name: clientes_endereco_id_endereco_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.clientes_endereco_id_endereco_seq', 1, false);


--
-- Name: configuracao_funcionamento_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.configuracao_funcionamento_id_seq', 1, false);


--
-- Name: configuracao_rpfood_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.configuracao_rpfood_id_seq', 1, false);


--
-- Name: empresas_id_empresa_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.empresas_id_empresa_seq', 1, true);


--
-- Name: happy_hour_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.happy_hour_id_seq', 24, true);


--
-- Name: transferencia_imagens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transferencia_imagens_id_seq', 9407, true);


--
-- Name: venda_id_venda_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.venda_id_venda_seq', 1, false);


--
-- PostgreSQL database dump complete
--

\unrestrict xMH1fXWlrZ4JQLl1zzNpYed1RiaLlXCDT2kmEy2quz1xXPjV85ly2EW5hugfcSa

