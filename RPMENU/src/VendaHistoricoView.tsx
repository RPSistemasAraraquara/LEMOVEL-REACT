import type { VendaHistorico, VendaItem } from "./types";
import { SmartImage } from "./SmartImage";

type Props = {
  error: string;
  formatMoney: (value: number) => string;
  history: VendaHistorico[];
  loading: boolean;
  message: string;
  onBack: () => void;
  onRepeat: (sale: VendaHistorico) => void;
  repeatingSaleId: number | null;
};

function formatDate(value: string): string {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }
  return parsed.toLocaleDateString("pt-BR");
}

function formatItemMeta(item: VendaItem): string {
  const parts: string[] = [];

  if (item.tamanho.trim()) {
    parts.push(`Tamanho ${item.tamanho}`);
  }

  parts.push(`Qtd ${item.quantidade.toLocaleString("pt-BR", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  })}`);

  return parts.join(" | ");
}

function formatShortMoney(value: number): string {
  return value.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
}

export function VendaHistoricoView({
  error,
  formatMoney,
  history,
  loading,
  message,
  onBack,
  onRepeat,
  repeatingSaleId,
}: Props) {
  const deliveredCount = history.filter((sale) => sale.situacaoDescription.trim()).length;

  return (
    <div id="main-wrapper" className="show dlab-overflow">
      <div className="content-body" style={{ paddingBottom: 80, marginLeft: 0, paddingTop: 0, marginTop: 0 }}>
        <div className="container rpfood-history-page">
          <div className="rpfood-history-toolbar">
            <button type="button" className="rpfood-back-button" onClick={onBack}>
              Voltar
            </button>
            <span className="rpfood-history-toolbar__status">{loading ? "Atualizando pedidos..." : "Historico carregado"}</span>
          </div>

          <section className="rpfood-history-hero">
            <div className="rpfood-history-hero__copy">
              <span className="rpfood-history-hero__eyebrow">Historico do cliente</span>
              <h1 className="rpfood-history-hero__title">Peca de novo sem perder contexto</h1>
              <p className="rpfood-history-hero__description">
                Revise pedidos anteriores, confira valores antigos e repita com seguranca quando algo tiver mudado.
              </p>
            </div>

            <div className="rpfood-history-hero__stats">
              <div className="rpfood-history-hero__stat">
                <span className="rpfood-history-hero__stat-label">Pedidos</span>
                <strong>{history.length}</strong>
              </div>
              <div className="rpfood-history-hero__stat">
                <span className="rpfood-history-hero__stat-label">Total movimentado</span>
                <strong>{formatShortMoney(history.reduce((sum, sale) => sum + sale.valorTotal, 0))}</strong>
              </div>
              <div className="rpfood-history-hero__stat">
                <span className="rpfood-history-hero__stat-label">Registros ativos</span>
                <strong>{deliveredCount}</strong>
              </div>
            </div>
          </section>

          {(message || error) && (
            <section className="rpfood-history-feedback">
              {message ? <div className="rpfood-history-feedback__item is-success">{message}</div> : null}
              {error ? <div className="rpfood-history-feedback__item is-error">{error}</div> : null}
            </section>
          )}

          {history.length ? (
            <section className="rpfood-history-list">
              {history.map((sale) => (
                <article key={sale.id} className="rpfood-history-card">
                  <div className="rpfood-history-card__header">
                    <div className="rpfood-history-card__identity">
                      <span className="rpfood-history-card__eyebrow">Pedido #{sale.id}</span>
                      <h2 className="rpfood-history-card__title">{formatDate(sale.data)}</h2>
                      <p className="rpfood-history-card__subtitle">
                        {sale.tipoEntregaDescription} com pagamento em {sale.formaPagamento.descricao}
                      </p>
                    </div>

                    <div className="rpfood-history-card__summary">
                      <span className="rpfood-history-chip is-status">{sale.situacaoDescription}</span>
                      <span className="rpfood-history-chip">{sale.tipoEntregaDescription}</span>
                      {sale.taxaEntrega > 0 ? <span className="rpfood-history-chip">Entrega {formatMoney(sale.taxaEntrega)}</span> : null}
                    </div>
                  </div>

                  <div className="rpfood-history-card__metrics">
                    <div className="rpfood-history-metric">
                      <span className="rpfood-history-metric__label">Total do pedido</span>
                      <strong className="rpfood-history-metric__value">{formatMoney(sale.valorTotal)}</strong>
                    </div>
                    <div className="rpfood-history-metric">
                      <span className="rpfood-history-metric__label">Itens</span>
                      <strong className="rpfood-history-metric__value">
                        {sale.itens.reduce((sum, item) => sum + item.quantidade, 0).toLocaleString("pt-BR")}
                      </strong>
                    </div>
                    <div className="rpfood-history-metric">
                      <span className="rpfood-history-metric__label">Forma de pagamento</span>
                      <strong className="rpfood-history-metric__value is-text">{sale.formaPagamento.descricao}</strong>
                    </div>
                  </div>

                  <div className="rpfood-history-items">
                    {sale.itens.map((item) => (
                      <div key={`${sale.id}-${item.numeroItem}`} className="rpfood-history-item">
                        <SmartImage
                          src={item.produto.imageUrl}
                          placeholderSrc={item.produto.thumbnailUrl ?? item.produto.imageUrl}
                          alt={item.produto.descricao}
                          wrapperClassName="rpfood-history-item__image"
                          loading="lazy"
                        />

                        <div className="rpfood-history-item__content">
                          <div className="rpfood-history-item__heading">
                            <h3 className="rpfood-history-item__title">{item.produto.descricao}</h3>
                            {item.tamanho.trim() ? <span className="rpfood-history-item__badge">{item.tamanho}</span> : null}
                          </div>
                          <p className="rpfood-history-item__meta">{formatItemMeta(item)}</p>
                          {item.observacao.trim() ? <p className="rpfood-history-item__note">Obs.: {item.observacao}</p> : null}
                        </div>

                        <div className="rpfood-history-item__price">
                          <strong>{formatMoney(item.valorTotalProduto)}</strong>
                          <span>{formatMoney(item.valorUnitario)} por unidade</span>
                        </div>
                      </div>
                    ))}
                  </div>

                  <div className="rpfood-history-card__footer">
                    <p className="rpfood-history-card__footer-copy">
                      {sale.observacao.trim()
                        ? `Observacao do pedido: ${sale.observacao}`
                        : "Ao repetir, o sistema compara disponibilidade, tamanho e preco atual antes de montar a nova sacola."}
                    </p>

                    <button
                      type="button"
                      className="rpfood-history-repeat-button"
                      onClick={() => onRepeat(sale)}
                      disabled={repeatingSaleId === sale.id}
                    >
                      {repeatingSaleId === sale.id ? "Carregando pedido..." : "Quero de novo"}
                    </button>
                  </div>
                </article>
              ))}
            </section>
          ) : (
            <section className="rpfood-history-empty">
              <span className="rpfood-history-empty__eyebrow">Sem pedidos ainda</span>
              <h2 className="rpfood-history-empty__title">Seu historico vai aparecer aqui</h2>
              <p className="rpfood-history-empty__description">
                Assim que o primeiro pedido for concluido, voce podera revisar os itens e repetir a compra com um toque.
              </p>
            </section>
          )}
        </div>
      </div>
    </div>
  );
}
