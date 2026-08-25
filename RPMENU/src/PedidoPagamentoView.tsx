import { useEffect, useMemo, useState } from "react";
// Import dinamico: a lib so e necessaria quando o cliente escolhe PIX, entao ela
// sai do bundle inicial que todo mundo baixa.
import type { PagamentoPix } from "./types";

type Props = {
  error: string;
  formatMoney: (value: number) => string;
  loading: boolean;
  message: string;
  onBack: () => void;
  payment: PagamentoPix;
};

function statusLabel(status: string): string {
  const normalized = status.trim().toLowerCase();
  if (normalized === "approved" || normalized === "aprovado") return "Pagamento aprovado";
  if (normalized === "cancelled" || normalized === "cancelado") return "Pagamento cancelado";
  if (normalized === "expired" || normalized === "expirado") return "Pagamento expirado";
  return "Aguardando o pagamento";
}

function qrFallback(payment: PagamentoPix): string {
  if (payment.qrCodeDigitavel) {
    return "Use o codigo abaixo no app do seu banco caso o QR Code nao esteja disponivel.";
  }

  return "QR Code nao disponivel";
}

function resolveQrCodeImage(base64: string): string {
  const normalized = base64.trim();
  if (!normalized) {
    return "";
  }

  if (normalized.startsWith("data:image/")) {
    return normalized;
  }

  return `data:image/png;base64,${normalized}`;
}

export function PedidoPagamentoView({
  error,
  formatMoney,
  loading,
  message,
  onBack,
  payment,
}: Props) {
  const [generatedQrCode, setGeneratedQrCode] = useState({ source: "", image: "", failed: false });
  const qrCodeImage = useMemo(() => resolveQrCodeImage(payment.qrCodeBase64), [payment.qrCodeBase64]);
  const qrCodeSource = payment.qrCodeDigitavel.trim();
  const generatedQrCodeImage = generatedQrCode.source === qrCodeSource ? generatedQrCode.image : "";
  const renderedQrCodeImage = qrCodeImage || generatedQrCodeImage;
  const qrCodeFallbackText =
    qrCodeSource && generatedQrCode.source === qrCodeSource && generatedQrCode.failed
      ? "Nao foi possivel gerar o QR Code. Use o codigo digitavel abaixo."
      : qrCodeSource
        ? "Gerando QR Code..."
        : qrFallback(payment);
  const currentStatusLabel = statusLabel(payment.status);

  useEffect(() => {
    const scrollTop = () => {
      window.scrollTo({ top: 0, left: 0, behavior: "auto" });
      document.documentElement.scrollTop = 0;
      document.body.scrollTop = 0;
    };
    scrollTop();
    const frame = window.requestAnimationFrame(scrollTop);
    return () => window.cancelAnimationFrame(frame);
  }, [payment.idPix, payment.qrCodeBase64, payment.qrCodeDigitavel]);

  useEffect(() => {
    if (qrCodeImage || !qrCodeSource) {
      return;
    }

    let cancelled = false;

    import("qrcode")
      .then((module) =>
        module.default.toDataURL(qrCodeSource, {
          errorCorrectionLevel: "M",
          margin: 1,
          width: 320,
        }),
      )
      .then((image) => {
        if (!cancelled) {
          setGeneratedQrCode({ source: qrCodeSource, image, failed: false });
        }
      })
      .catch(() => {
        if (!cancelled) {
          setGeneratedQrCode({ source: qrCodeSource, image: "", failed: true });
        }
      });

    return () => {
      cancelled = true;
    };
  }, [qrCodeImage, qrCodeSource]);

  return (
    <div id="main-wrapper" className="show dlab-overflow rpfood-checkout-screen">
      <div className="content-body rpfood-checkout-content rpfood-payment-screen__content">
        <div className="container rpfood-checkout-container">
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

          <header className="rpfood-checkout-hero">
            <span className="rpfood-checkout-hero__eyebrow">Boraa Fechar</span>
            <h1 className="rpfood-checkout-hero__title">Pagamento Seguro</h1>
            <p className="rpfood-checkout-hero__subtitle">
              Continue com o PIX usando a mesma logica atual de confirmacao, exibida agora com uma leitura mais clara.
            </p>
          </header>

          <section className="rpfood-pix-shell" id="tab-control">
            <div className="rpfood-pix-shell__toolbar">
              <button type="button" className="rpfood-secondary-action rpfood-pix-shell__toolbar-button" onClick={onBack}>
                Voltar e escolher outra forma
              </button>
              <span className="rpfood-pix-shell__toolbar-status">{loading ? "Atualizando pagamento..." : "Voce ainda pode trocar a forma de pagamento"}</span>
            </div>

            <div className="rpfood-pix-shell__header">
              <span className="rpfood-pix-shell__eyebrow" id="tab_tipo_entrega">Pagamento Seguro</span>
              <h2 className="rpfood-pix-shell__title">Boraee pagar com QRCODE</h2>
              <p className="rpfood-pix-shell__subtitle">
                Escaneie o QR Code no app do banco ou use o codigo digitavel logo abaixo.
              </p>
            </div>

            <div className="rpfood-pix-shell__qr">
              <div className="rpfood-pix-shell__qr-frame">
                {renderedQrCodeImage ? (
                  <img
                    src={renderedQrCodeImage}
                    alt="QR Code PIX"
                    className="rpfood-pix-shell__qr-image"
                  />
                ) : (
                  <div className="rpfood-pix-shell__qr-fallback">
                    {qrCodeFallbackText}
                  </div>
                )}
              </div>
              <div className="rpfood-pix-shell__status">{currentStatusLabel}</div>
            </div>

            <div className="rpfood-pix-shell__details">
              <div className="rpfood-pix-shell__detail-card">
                <span className="rpfood-pix-shell__detail-label">Codigo digitavel</span>
                <div className="rpfood-pix-shell__detail-value rpfood-pix-shell__detail-value--code">
                  {payment.qrCodeDigitavel || qrFallback(payment)}
                </div>
              </div>

              <div className="rpfood-pix-shell__detail-card">
                <span className="rpfood-pix-shell__detail-label">Link alternativo</span>
                <div className="rpfood-pix-shell__detail-value">
                  {payment.qrCodeUrl ? (
                    <a href={payment.qrCodeUrl} target="_blank" rel="noreferrer">
                      {payment.qrCodeUrl}
                    </a>
                  ) : (
                    "Link nao disponivel"
                  )}
                </div>
              </div>

              <div id="div_totais_pedido" className="rpfood-totals-grid rpfood-totals-grid--single">
                <div className="rpfood-totals-card rpfood-totals-card--accent">
                  <span>Total do pedido</span>
                  <strong id="span_valor_total">{formatMoney(payment.valorTotal)}</strong>
                </div>
              </div>

              <div className="rpfood-pix-shell__fallback">
                <div className="rpfood-pix-shell__fallback-copy">
                  <span className="rpfood-pix-shell__fallback-label">Nao conseguiu pagar?</span>
                  <strong className="rpfood-pix-shell__fallback-title">Volte para o checkout e escolha outra forma de pagamento</strong>
                  <p className="rpfood-pix-shell__fallback-text">
                    Se o PIX nao funcionar agora, voce pode retornar sem perder os itens da sacola e selecionar outra opcao.
                  </p>
                </div>

                <button type="button" className="rpfood-secondary-action rpfood-pix-shell__fallback-button" onClick={onBack}>
                  Escolher outra forma
                </button>
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>
  );
}
