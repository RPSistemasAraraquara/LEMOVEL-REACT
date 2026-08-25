import type { VendaAcompanhamento } from "./types";
import { SmartImage } from "./SmartImage";

type Props = {
  error: string;
  formatMoney: (value: number) => string;
  loading: boolean;
  message: string;
  onBack: () => void;
  order: VendaAcompanhamento | null;
};

const statusOrder: Record<string, number> = {
  spEnviado: 0,
  spAceito: 1,
  spEmPreparo: 2,
  spSaiuParaEntrega: 3,
  spProntoParaRetirar: 4,
  spFinalizado: 5,
  spRejeitado: 6,
  spCanceladoEstabelecimento: 7,
  spCanceladoCliente: 8,
  spRejeitadoTempoEspera: 9,
};

function formatDateTime(value: string): string {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }
  return parsed.toLocaleString("pt-BR");
}

function progressValue(order: VendaAcompanhamento | null): number {
  if (!order?.listaStatus.length) {
    return 0;
  }

  const current = order.listaStatus[order.listaStatus.length - 1];
  switch (current.situacao) {
    case "spEnviado":
      return 20;
    case "spAceito":
      return 35;
    case "spEmPreparo":
      return 55;
    case "spSaiuParaEntrega":
    case "spProntoParaRetirar":
      return 80;
    case "spFinalizado":
      return 100;
    default:
      return 100;
  }
}

function orderStatus(order: VendaAcompanhamento | null): string {
  if (!order) {
    return "Ainda nao fez seu pedido?";
  }

  return order.situacaoDescription || order.listaStatus[order.listaStatus.length - 1]?.situacaoDescricao || "Aguardando atualizacao";
}

function isPickupOrder(order: VendaAcompanhamento | null): boolean {
  const tipoEntrega = order?.tipoEntregaDescription?.trim().toLowerCase() ?? "";
  return tipoEntrega.includes("retirada") || tipoEntrega.includes("balcao") || tipoEntrega.includes("balcão");
}

function buildTrackingAddressText(order: VendaAcompanhamento | null, pickupOrder: boolean): string {
  const address = order?.vendaEndereco;
  if (!address) {
    return pickupOrder ? "Os dados de retirada aparecem aqui." : "Os detalhes do endereco aparecem aqui.";
  }

  if (address.enderecoCompleto?.trim()) {
    return address.enderecoCompleto;
  }

  const parts = [address.endereco];
  if (address.numero) parts.push(`N ${address.numero}`);
  if (address.complemento) parts.push(address.complemento);
  if (address.pontoReferencia) parts.push(address.pontoReferencia);
  if (address.bairro) parts.push(`Bairro: ${address.bairro}`);

  const formatted = parts.filter(Boolean).join(" - ");
  return formatted || (pickupOrder ? "Os dados de retirada aparecem aqui." : "Os detalhes do endereco aparecem aqui.");
}

export function PedidoAcompanhamentoView({
  error,
  formatMoney,
  loading,
  message,
  onBack,
  order,
}: Props) {
  const timeline = [...(order?.listaStatus ?? [])].sort((left, right) => {
    const leftOrder = statusOrder[left.situacao] ?? 99;
    const rightOrder = statusOrder[right.situacao] ?? 99;
    return rightOrder - leftOrder;
  });

  const itemsCount = order?.itens.reduce((sum, item) => sum + item.quantidade, 0) ?? 0;
  const currentStatus = timeline[0]?.situacaoDescricao || orderStatus(order);
  const progress = progressValue(order);
  const pickupOrder = isPickupOrder(order);
  const trackingAddressText = buildTrackingAddressText(order, pickupOrder);

  return (
    <div id="main-wrapper" className="show dlab-overflow" style={{ background: "#ffffff", color: "#617085" }}>
      <div className="content-body" style={{ paddingBottom: 140, marginLeft: 0, paddingTop: 0, marginTop: 0 }}>
        <div className="container rpfood-tracking-page">
          <div className="rpfood-tracking-toolbar">
            <button type="button" className="rpfood-back-button" onClick={onBack}>
              Voltar
            </button>
            <span className="rpfood-tracking-toolbar__status">{loading ? "Atualizando pedido..." : "Acompanhe em tempo real"}</span>
          </div>

          {(message || error) && (
            <section className="rpfood-feedback-stack">
              {message ? (
                <div className="rpfood-feedback-stack__item rpfood-feedback-stack__item--ok">
                  {message}
                </div>
              ) : null}
              {error ? (
                <div className="rpfood-feedback-stack__item rpfood-feedback-stack__item--error">
                  {error}
                </div>
              ) : null}
            </section>
          )}

          <div className="rpfood-tracking-layout">
            <section className="rpfood-tracking-status-card" id="card_status">
              <div className="rpfood-tracking-status-card__hero">
                <div>
                  <span className="rpfood-tracking-eyebrow">Acompanhamento</span>
                  <h1 className="rpfood-tracking-title">{order ? `Pedido #${order.id}` : "Seu pedido"}</h1>
                  <p className="rpfood-tracking-subtitle">
                    {order ? `Pedido realizado em ${formatDateTime(order.data)}` : "Assim que o pedido for criado, voce acompanha tudo aqui."}
                  </p>
                </div>

                <div className="rpfood-tracking-status-pill">{currentStatus}</div>
              </div>

              <div className="rpfood-tracking-progress-panel">
                <div className="rpfood-tracking-progress-panel__head">
                  <strong>Andamento do pedido</strong>
                  <span>{progress}%</span>
                </div>
                <div className="rpfood-tracking-progress">
                  <div
                    className="rpfood-tracking-progress__bar"
                    style={{ width: `${progress}%` }}
                    role="progressbar"
                    aria-valuemin={0}
                    aria-valuemax={100}
                    aria-valuenow={progress}
                    id="task_progresso"
                  />
                </div>
                <p className="rpfood-tracking-progress-panel__copy" id="texto_status_pedido">
                  {orderStatus(order)}
                </p>
              </div>

              <div className="rpfood-tracking-metrics">
                <div className="rpfood-tracking-metric">
                  <span className="rpfood-tracking-metric__label">Itens</span>
                  <strong>{itemsCount.toLocaleString("pt-BR")}</strong>
                </div>
                <div className="rpfood-tracking-metric">
                  <span className="rpfood-tracking-metric__label">Entrega</span>
                  <strong>{order?.tipoEntregaDescription || "A definir"}</strong>
                </div>
                <div className="rpfood-tracking-metric">
                  <span className="rpfood-tracking-metric__label">Pagamento</span>
                  <strong>{order?.formaPagamento.descricao || "A definir"}</strong>
                </div>
              </div>

              <div id="DZ_W_TimeLine" className="rpfood-tracking-timeline-wrap">
                <div className="rpfood-tracking-timeline-head">
                  <h2 className="rpfood-tracking-section-title" id="titulo_venda_data">
                    {order ? "Historico de status" : "Aguardando pedido"}
                  </h2>
                  <span className="rpfood-tracking-timeline-head__hint">
                    {timeline.length ? `${timeline.length} atualizacao(oes)` : "Sem movimentacoes ainda"}
                  </span>
                </div>

                <ul className="rpfood-tracking-timeline" id="lista_status">
                  {timeline.length ? (
                    timeline.map((status, index) => (
                      <li key={`${status.situacao}-${status.data}-${index}`} className="rpfood-tracking-timeline__item">
                        <div className={`rpfood-tracking-timeline__dot${index === 0 ? " is-current" : ""}`} />
                        <div className={`rpfood-tracking-timeline__card${index === 0 ? " is-current" : ""}`}>
                          <span className="rpfood-tracking-timeline__time">{formatDateTime(status.data)}</span>
                          <h6 className="mb-0">{status.situacaoDescricao}</h6>
                        </div>
                      </li>
                    ))
                  ) : (
                    <li className="rpfood-tracking-timeline__empty">Nenhuma atualizacao recebida ainda.</li>
                  )}
                </ul>
              </div>
            </section>

            <aside className="rpfood-tracking-order-card" id="divPedido">
              <div className="rpfood-tracking-order-card__header">
                <span className="rpfood-tracking-eyebrow">Seu pedido</span>
                <h2 className="rpfood-tracking-order-card__title">Resumo da compra</h2>
              </div>

              <div className="rpfood-tracking-address-card">
                <p className="rpfood-tracking-address-card__label">{pickupOrder ? "Retirada" : "Endereco"}</p>
                <div className="rpfood-tracking-address-card__title">
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                    <path d="M20.46 9.63C20.3196 8.16892 19.8032 6.76909 18.9612 5.56682C18.1191 4.36456 16.9801 3.40083 15.655 2.7695C14.3299 2.13816 12.8639 1.86072 11.3997 1.96421C9.93555 2.06769 8.52314 2.54856 7.3 3.36C6.2492 4.06265 5.36706 4.9893 4.71695 6.07339C4.06684 7.15749 3.6649 8.37211 3.54 9.63C3.41749 10.8797 3.57468 12.1409 4.00017 13.3223C4.42567 14.5036 5.1088 15.5755 6 16.46L11.3 21.77C11.393 21.8637 11.5036 21.9381 11.6254 21.9889C11.7473 22.0397 11.878 22.0658 12.01 22.0658C12.142 22.0658 12.2727 22.0397 12.3946 21.9889C12.5164 21.9381 12.627 21.8637 12.72 21.77L18 16.46C18.8912 15.5755 19.5743 14.5036 19.9998 13.3223C20.4253 12.1409 20.5825 10.8797 20.46 9.63ZM16.6 15.05L12 19.65L7.4 15.05C6.72209 14.3721 6.20281 13.5523 5.87947 12.6498C5.55614 11.7472 5.43679 10.7842 5.53 9.83C5.62382 8.86111 5.93177 7.92516 6.43157 7.08985C6.93138 6.25453 7.61056 5.54071 8.42 5C9.48095 4.29524 10.7263 3.9193 12 3.9193C13.2737 3.9193 14.5191 4.29524 15.58 5C16.387 5.53862 17.0647 6.24928 17.5644 7.08094C18.064 7.9126 18.3733 8.84461 18.47 9.81C18.5663 10.7674 18.4484 11.7343 18.125 12.6406C17.8016 13.5468 17.2807 14.3698 16.6 15.05Z" fill="currentColor" />
                  </svg>
                  <span id="venda_endereco_bairro">{pickupOrder ? "Retirada no balcao" : order?.vendaEndereco.bairro || "Endereco do pedido"}</span>
                </div>
                <p className="rpfood-tracking-address-card__text" id="venda_endereco_completo">
                  {trackingAddressText}
                </p>
              </div>

              <div className="rpfood-tracking-items" id="div_itens_do_pedido">
                {order?.itens.map((item) => (
                  <article key={`${order.id}-${item.numeroItem}`} className="rpfood-tracking-item-card">
                    <div className="rpfood-tracking-item-card__media">
                      {item.produto.imageUrl ? (
                        <SmartImage
                          src={item.produto.imageUrl}
                          placeholderSrc={item.produto.thumbnailUrl ?? item.produto.imageUrl}
                          alt={item.produto.descricao}
                          wrapperClassName="rpfood-tracking-item-image"
                          loading="eager"
                        />
                      ) : (
                        <div className="rpfood-tracking-item-image rpfood-tracking-item-image--empty" />
                      )}
                    </div>

                    <div className="rpfood-tracking-item-card__body">
                      <div className="rpfood-tracking-item-card__top">
                        <div>
                          <h3 className="rpfood-tracking-item-card__title">{item.produto.descricao}</h3>
                          {item.tamanho.trim() ? <span className="rpfood-tracking-item-card__size">Tamanho: {item.tamanho}</span> : null}
                        </div>
                        <strong className="rpfood-tracking-item-card__total">{formatMoney(item.valorTotalProduto)}</strong>
                      </div>

                      <div className="rpfood-tracking-item-card__meta">
                        <span>{formatMoney(item.valorUnitario)} por unidade</span>
                        <span>{item.quantidade} item(ns)</span>
                      </div>
                    </div>
                  </article>
                ))}
              </div>

              <div className="rpfood-tracking-totals" id="div_totais">
                <div className="rpfood-tracking-totals__row">
                  <span>Taxa de entrega</span>
                  <strong id="venda_taxa_entrega">{formatMoney(order?.taxaEntrega ?? 0)}</strong>
                </div>
                <div className="rpfood-tracking-totals__row is-total">
                  <div>
                    <span>Total</span>
                    <strong id="venda_valor_total">{formatMoney(order?.valorTotal ?? 0)}</strong>
                  </div>
                  <div className="rpfood-tracking-totals__payment" id="venda_forma_pagamento">
                    {order?.formaPagamento.descricao || ""}
                  </div>
                </div>
              </div>
            </aside>
          </div>
        </div>
      </div>
    </div>
  );
}
