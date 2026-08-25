import { useState } from "react";
import type { HorarioFuncionamento, SobreLoja } from "./types";

type Props = {
  data: SobreLoja | null;
  error: string;
  loading: boolean;
  message: string;
  onBack: () => void;
};

type Tab = "sobre" | "horarios" | "pagamentos" | "tempo";

function buildAddressLines(data: SobreLoja | null): string[] {
  if (!data) return [];

  const address = data.empresa.endereco;
  return [
    `${address.endereco || ""}${address.numero ? ` Nº ${address.numero}` : ""}`.trim(),
    address.bairro ? `Bairro: ${address.bairro}` : "",
    address.complemento || "",
    data.empresa.fone1 || "",
  ].filter(Boolean);
}

function buildSchedulePeriods(horario: HorarioFuncionamento): string[] {
  const periods = [];

  if (horario.horaAbertura && horario.horaFechamento) {
    periods.push(`${horario.horaAbertura} - ${horario.horaFechamento}`);
  }

  if (
    horario.horaAbertura2 &&
    horario.horaFechamento2 &&
    horario.horaAbertura2 !== "00:00" &&
    horario.horaFechamento2 !== "00:00"
  ) {
    periods.push(`${horario.horaAbertura2} - ${horario.horaFechamento2}`);
  }

  return periods.length ? periods : ["Consulte a loja"];
}

export function SobreView({ data, error, loading, message, onBack }: Props) {
  const [tab, setTab] = useState<Tab>("sobre");

  const addressLines = buildAddressLines(data);
  const deliveryTime = data?.configuracao.tempoEntrega || "0";
  const pickupTime = data?.configuracao.tempoRetirada || "0";
  const paymentCount = data?.formasPagamento.length || 0;

  return (
    <div className="body">
      <div className="rpfood-auth-shell">
        <div className="rpfood-store-shell">
          <div className="rpfood-login-toolbar">
            <button type="button" onClick={onBack} className="rpfood-back-button">
              Voltar
            </button>
            <span className="rpfood-login-status">{loading ? "Carregando informacoes..." : ""}</span>
          </div>

          {(message || error) && (
            <section className="rpfood-feedback-stack">
              {message ? <div className="rpfood-feedback-stack__item rpfood-feedback-stack__item--ok">{message}</div> : null}
              {error ? <div className="rpfood-feedback-stack__item rpfood-feedback-stack__item--error">{error}</div> : null}
            </section>
          )}

          <section className="rpfood-store-hero">
            <div className="rpfood-store-hero__content">
              <span className="rpfood-auth-kicker">Conheca a loja</span>
              <h1 className="rpfood-auth-title">Sobre a loja</h1>
            </div>

            <div className={data?.aberta ? "rpfood-store-status rpfood-store-status--open" : "rpfood-store-status rpfood-store-status--closed"}>
              <span className="rpfood-store-status__label">Status atual</span>
              <strong className="rpfood-store-status__value">{data?.aberta ? "Aberta agora" : "Fechada no momento"}</strong>
            </div>
          </section>

          <section className="rpfood-store-highlights" aria-label="Resumo da loja">
            <article className="rpfood-store-highlight">
              <span className="rpfood-store-highlight__label">Loja</span>
              <strong className="rpfood-store-highlight__value">{data?.empresa.nome || "RPFood"}</strong>
            </article>
            <article className="rpfood-store-highlight">
              <span className="rpfood-store-highlight__label">Entrega</span>
              <strong className="rpfood-store-highlight__value">{deliveryTime} min</strong>
            </article>
            <article className="rpfood-store-highlight">
              <span className="rpfood-store-highlight__label">Retirada</span>
              <strong className="rpfood-store-highlight__value">{pickupTime} min</strong>
            </article>
            <article className="rpfood-store-highlight">
              <span className="rpfood-store-highlight__label">Pagamentos</span>
              <strong className="rpfood-store-highlight__value">{paymentCount} opcoes</strong>
            </article>
          </section>

          <section className="rpfood-store-panel">
            <div className="rpfood-store-tabs" role="tablist" aria-label="Informacoes da loja">
              <button
                type="button"
                className={tab === "sobre" ? "rpfood-store-tab rpfood-store-tab--active" : "rpfood-store-tab"}
                onClick={() => setTab("sobre")}
              >
                <span className="rpfood-store-tab__icon" aria-hidden="true">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M4 11.5L12 5L20 11.5V19C20 19.5523 19.5523 20 19 20H15V14H9V20H5C4.44772 20 4 19.5523 4 19V11.5Z" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round" />
                  </svg>
                </span>
                Sobre
              </button>
              <button
                type="button"
                className={tab === "horarios" ? "rpfood-store-tab rpfood-store-tab--active" : "rpfood-store-tab"}
                onClick={() => setTab("horarios")}
              >
                <span className="rpfood-store-tab__icon" aria-hidden="true">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <circle cx="12" cy="12" r="8.5" stroke="currentColor" strokeWidth="1.8" />
                    <path d="M12 7.5V12L15.5 14" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </span>
                Horarios
              </button>
              <button
                type="button"
                className={tab === "pagamentos" ? "rpfood-store-tab rpfood-store-tab--active" : "rpfood-store-tab"}
                onClick={() => setTab("pagamentos")}
              >
                <span className="rpfood-store-tab__icon" aria-hidden="true">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <rect x="3.75" y="6.75" width="16.5" height="10.5" rx="2.25" stroke="currentColor" strokeWidth="1.8" />
                    <path d="M3.75 10.5H20.25" stroke="currentColor" strokeWidth="1.8" />
                  </svg>
                </span>
                Pagamentos
              </button>
              <button
                type="button"
                className={tab === "tempo" ? "rpfood-store-tab rpfood-store-tab--active" : "rpfood-store-tab"}
                onClick={() => setTab("tempo")}
              >
                <span className="rpfood-store-tab__icon" aria-hidden="true">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M4 15L8.5 10.5L12 14L16.5 8.5L20 12" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
                    <path d="M20 8.5V12.5H16" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </span>
                Entrega
              </button>
            </div>

            {tab === "sobre" ? (
              <div className="rpfood-store-content">
                <div className="rpfood-store-card rpfood-store-card--about">
                  <div className="rpfood-store-card__header">
                    <span className="rpfood-store-card__eyebrow">Endereco e contato</span>
                    <h3 className="rpfood-store-card__title">{data?.empresa.nome || "Loja RPFood"}</h3>
                  </div>

                  <div className="rpfood-store-info-grid">
                    <div className="rpfood-store-info-item">
                      <span className="rpfood-store-info-item__label">Onde estamos</span>
                      <div className="rpfood-store-info-item__value">
                        {addressLines.length ? (
                          addressLines.map((line) => <div key={line}>{line}</div>)
                        ) : (
                          <div>Endereco indisponivel no momento.</div>
                        )}
                      </div>
                    </div>

                    <div className="rpfood-store-info-item">
                      <span className="rpfood-store-info-item__label">Atendimento</span>
                      <div className="rpfood-store-info-item__value">
                        <div>{data?.aberta ? "Estamos atendendo agora." : "No momento estamos fora do horario."}</div>
                        <div>Entrega prevista em {deliveryTime} minutos.</div>
                        <div>Retirada prevista em {pickupTime} minutos.</div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ) : null}

            {tab === "horarios" ? (
              <div className="rpfood-store-content">
                <div className="rpfood-store-card">
                  <div className="rpfood-store-card__header">
                    <span className="rpfood-store-card__eyebrow">Funcionamento</span>
                    <h3 className="rpfood-store-card__title">Horarios da loja</h3>
                  </div>

                  <div className="rpfood-store-schedule-grid">
                    {data?.horarios.length ? (
                      data.horarios.map((horario) => (
                        <article key={`${horario.dia}-${horario.horaAbertura}-${horario.horaFechamento}`} className="rpfood-store-schedule-card">
                          <strong className="rpfood-store-schedule-card__day">{horario.dia}</strong>
                          <div className="rpfood-store-schedule-card__periods">
                            {buildSchedulePeriods(horario).map((period) => (
                              <span key={`${horario.dia}-${period}`}>{period}</span>
                            ))}
                          </div>
                        </article>
                      ))
                    ) : (
                      <div className="rpfood-store-empty">Horarios indisponiveis no momento.</div>
                    )}
                  </div>
                </div>
              </div>
            ) : null}

            {tab === "pagamentos" ? (
              <div className="rpfood-store-content">
                <div className="rpfood-store-card">
                  <div className="rpfood-store-card__header">
                    <span className="rpfood-store-card__eyebrow">Fechamento do pedido</span>
                    <h3 className="rpfood-store-card__title">Formas de pagamento aceitas</h3>
                  </div>

                  <div className="rpfood-store-payment-list">
                    {data?.formasPagamento.length ? (
                      data.formasPagamento.map((pagamento) => (
                        <div key={pagamento.id} className="rpfood-store-payment-chip">
                          <span className="rpfood-store-payment-chip__dot" aria-hidden="true" />
                          {pagamento.descricao}
                        </div>
                      ))
                    ) : (
                      <div className="rpfood-store-empty">Nenhuma forma de pagamento informada.</div>
                    )}
                  </div>
                </div>
              </div>
            ) : null}

            {tab === "tempo" ? (
              <div className="rpfood-store-content">
                <div className="rpfood-store-card">
                  <div className="rpfood-store-card__header">
                    <span className="rpfood-store-card__eyebrow">Agilidade</span>
                    <h3 className="rpfood-store-card__title">Previsao de atendimento</h3>
                  </div>

                  <div className="rpfood-store-time-grid">
                    <article className="rpfood-store-time-card">
                      <span className="rpfood-store-time-card__label">Entrega</span>
                      <strong className="rpfood-store-time-card__value">{deliveryTime} min</strong>
                      <p className="rpfood-store-time-card__note">Ideal para receber com conforto onde voce estiver.</p>
                    </article>
                    <article className="rpfood-store-time-card">
                      <span className="rpfood-store-time-card__label">Retirada</span>
                      <strong className="rpfood-store-time-card__value">{pickupTime} min</strong>
                      <p className="rpfood-store-time-card__note">Perfeito para quem quer passar e levar rapidinho.</p>
                    </article>
                  </div>
                </div>
              </div>
            ) : null}
          </section>
        </div>
      </div>
    </div>
  );
}
