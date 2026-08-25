import type { Bairro, Empresa, Endereco, FormaPagamento, Opcional, Produto } from "./types";
import { SmartImage } from "./SmartImage";

type CheckoutForm = {
  nome: string;
  email: string;
  telefone: string;
  cep: string;
  endereco: string;
  numero: string;
  complemento: string;
  pontoReferencia: string;
  bairroId: number;
  tipoEntrega: "D" | "R";
  formaPagamentoId: number;
  valorAReceber: string;
  observacao: string;
};

type AddressForm = {
  idEndereco: number;
  cep: string;
  endereco: string;
  numero: string;
  complemento: string;
  pontoReferencia: string;
  bairroId: number;
  bairro: string;
  taxaEntrega: number;
};

type CartItem = {
  id: string;
  produto: Produto;
  quantidade: number;
  tamanho: string;
  observacao: string;
  opcionais: Array<{ quantidade: number; unitPrice: number; opcional: Opcional }>;
  fracoes: Array<{ quantidade: number; produto: Produto }>;
  valorUnitario: number;
  valorTotal: number;
};

type Props = {
  allowPickup: boolean;
  cart: CartItem[];
  checkout: CheckoutForm;
  company: Empresa | null;
  neighborhoods: Bairro[];
  deliveryFee: number;
  error: string;
  formatMoney: (value: number) => string;
  loading: boolean;
  message: string;
  newAddress: AddressForm;
  usesCep: boolean;
  onBack: () => void;
  onCancelTroco: () => void;
  onChangeObservation: (value: string) => void;
  onChangePayment: (paymentId: number) => void;
  onChangeTrocoValue: (value: string) => void;
  onCloseNewAddress: () => void;
  onConfirm: () => void;
  onConfirmTroco: () => void;
  onLookupCep: () => void;
  onOpenAddressSelector: () => void;
  onOpenNewAddress: () => void;
  onSaveNewAddress: () => void;
  onSelectAddress: (addressId: number) => void;
  onSelectTipoEntrega: (tipoEntrega: "D" | "R") => void;
  onUpdateNewAddress: <K extends keyof AddressForm>(field: K, value: AddressForm[K]) => void;
  payments: FormaPagamento[];
  saving: boolean;
  selectedAddress: Endereco | null;
  selectedAddressId: number;
  selectedPayment?: FormaPagamento;
  showNewAddressForm: boolean;
  showTrocoModal: boolean;
  total: number;
  valorPago: number;
  valorTroco: number;
  customerAddresses: Endereco[];
};

function buildAddressLabel(address?: Endereco | null): string {
  if (!address) return "";

  const parts = [address.endereco];
  if (address.numero) parts.push(`N ${address.numero}`);
  if (address.complemento) parts.push(address.complemento);
  if (address.pontoReferencia) parts.push(address.pontoReferencia);

  return parts.filter(Boolean).join(" - ");
}

function resolveAddressDeliveryFee(address: Endereco | null | undefined, neighborhoods: Bairro[]): number {
  if (!address) return 0;

  const neighborhood = neighborhoods.find((item) => item.idBairro === address.idBairro);
  if (neighborhood && Number.isFinite(neighborhood.taxa)) {
    return neighborhood.taxa;
  }

  if (Number.isFinite(address.taxaEntrega)) {
    return address.taxaEntrega;
  }

  return Number.isFinite(address.taxa) ? address.taxa : 0;
}

function formatCurrencyInputValue(value: number): string {
  const normalized = Math.round((value + Number.EPSILON) * 100) / 100;
  return normalized.toLocaleString("pt-BR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}

function buildTrocoSuggestions(total: number): string[] {
  const candidates = [
    total,
    Math.ceil(total),
    Math.ceil(total / 10) * 10,
    Math.ceil((total + 10) / 10) * 10,
  ];

  return [...new Set(candidates.filter((value) => Number.isFinite(value) && value >= total).map((value) => Math.round(value * 100) / 100))]
    .slice(0, 4)
    .map((value) => formatCurrencyInputValue(value));
}

function paymentDescription(payment: FormaPagamento): string {
  if (payment.utilizaPix || payment.pagamentoOnline) {
    return "Confirmacao rapida para seguir com o pedido.";
  }

  if (payment.permiteTroco) {
    return "Voce pode informar troco se precisar.";
  }

  return "Forma de pagamento disponivel para este pedido.";
}

const deliveryObservationSuggestions = [
  "CASA",
  "TRABALHO",
  "ETC",
];

const pickupObservationSuggestions = [
  "Retirada no balcao",
  "Chego em 10 min",
];

function appendObservationSuggestion(current: string, suggestion: string): string {
  const normalizedCurrent = current.trim();
  const normalizedSuggestion = suggestion.trim();

  if (!normalizedSuggestion) {
    return normalizedCurrent;
  }

  if (normalizedCurrent.toLowerCase().includes(normalizedSuggestion.toLowerCase())) {
    return normalizedCurrent;
  }

  if (!normalizedCurrent) {
    return normalizedSuggestion;
  }

  const nextValue = `${normalizedCurrent} • ${normalizedSuggestion}`;
  return nextValue.length <= 100 ? nextValue : normalizedCurrent;
}

function ProductOrderCard({
  item,
  formatMoney,
}: {
  item: CartItem;
  formatMoney: (value: number) => string;
}) {
  return (
    <div className="rpfood-order-card">
      <div className="rpfood-order-card__main">
        <div className="rpfood-order-card__media">
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
        <div className="rpfood-order-card__content">
          <div className="rpfood-order-card__row">
            <h5 className="rpfood-order-card__title">
              {item.produto.descricao} {item.tamanho ? `[Tamanho: ${item.tamanho}]` : ""}
            </h5>
            <h5 className="rpfood-order-card__price">{formatMoney(item.valorUnitario)}</h5>
          </div>
          <div className="rpfood-order-card__row">
            <span className="rpfood-order-card__meta">{item.quantidade} unidade(s)</span>
            <strong className="rpfood-order-card__total">{formatMoney(item.valorTotal)}</strong>
          </div>
          {item.observacao ? <div className="rpfood-order-card__note">Obs: {item.observacao}</div> : null}
        </div>
      </div>

      {item.fracoes.map((fraction) => (
        <div key={`${item.id}-fracao-${fraction.produto.codigo}`} className="rpfood-order-card__detail">
          <div className="rpfood-order-card__detail-media">
            <SmartImage
              src={fraction.produto.imageUrl}
              placeholderSrc={fraction.produto.thumbnailUrl ?? fraction.produto.imageUrl}
              alt={fraction.produto.descricao}
              wrapperClassName="rpfood-tracking-item-image"
              loading="lazy"
            />
          </div>
          <div className="rpfood-order-card__detail-content">
            <h6 className="rpfood-order-card__detail-title">(+sabor) {fraction.produto.descricao}</h6>
          </div>
        </div>
      ))}

      {item.opcionais.map((option) => (
        <div key={`${item.id}-opcional-${option.opcional.codigo}`} className="rpfood-order-card__detail rpfood-order-card__detail--option">
          <div className="rpfood-order-card__detail-content rpfood-order-card__detail-content--full">
            <div className="rpfood-order-card__row">
              <h6 className="rpfood-order-card__detail-title">(UP).. {option.opcional.descricao}</h6>
              <h6 className="rpfood-order-card__detail-value">{formatMoney(option.quantidade * option.unitPrice)}</h6>
            </div>
            <div className="rpfood-order-card__row">
              <span className="rpfood-order-card__detail-meta">
                {option.quantidade}x {formatMoney(option.unitPrice)}
              </span>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

export function PedidoFinalizarView({
  allowPickup,
  cart,
  checkout,
  company,
  neighborhoods,
  customerAddresses,
  error,
  formatMoney,
  loading,
  message,
  newAddress,
  usesCep,
  onBack,
  onCancelTroco,
  onChangeObservation,
  onChangePayment,
  onChangeTrocoValue,
  onCloseNewAddress,
  onConfirm,
  onConfirmTroco,
  onLookupCep,
  onOpenAddressSelector,
  onOpenNewAddress,
  onSaveNewAddress,
  onSelectAddress,
  onSelectTipoEntrega,
  onUpdateNewAddress,
  payments,
  saving,
  selectedAddress,
  selectedAddressId,
  showNewAddressForm,
  showTrocoModal,
  total,
  valorPago,
  valorTroco,
}: Props) {
  void loading;
  void onBack;

  const trocoSuggestions = buildTrocoSuggestions(total);
  const valorRecebidoLabel = checkout.valorAReceber?.trim() || formatCurrencyInputValue(total);
  const trocoStatusLabel = valorTroco > 0 ? formatMoney(valorTroco) : "Sem troco";
  const observationLength = checkout.observacao.length;
  const remainingObservationChars = Math.max(0, 100 - observationLength);
  const checkoutActionDisabled = saving || !cart.length;
  const observationSuggestions = checkout.tipoEntrega === "R" ? pickupObservationSuggestions : deliveryObservationSuggestions;
  const observationPlaceholder = checkout.tipoEntrega === "R"
    ? "Ex.: retiro no balcao em 10 minutos ou estou chegando."
    : "Ex.: casa, trabalho ou etc.";
  const selectedDeliveryFee = resolveAddressDeliveryFee(selectedAddress, neighborhoods);
  const alternativeAddresses = selectedAddressId
    ? customerAddresses.filter((address) => address.idEndereco !== selectedAddressId)
    : customerAddresses;
  const hasAlternativeAddresses = alternativeAddresses.length > 0;
  const deliveryListTitle = selectedAddress
    ? hasAlternativeAddresses
      ? "Escolha outro endereco para entrega"
      : "Nenhum outro endereco cadastrado"
    : "Selecione o endereco para entrega";

  return (
    <div id="main-wrapper" className="show dlab-overflow rpfood-checkout-screen">
      <div className="content-body rpfood-checkout-content">
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
            <h1 className="rpfood-checkout-hero__title">Fechamento do pedido</h1>
            <p className="rpfood-checkout-hero__subtitle">
              Revise entrega, pagamento e observacoes finais em uma tela mais clara, sem alterar nenhuma regra do fluxo atual.
            </p>
          </header>

          <section className="rpfood-checkout-section">
            <div className="rpfood-checkout-section__inner">
              <section className="rpfood-fulfillment-shell">
                <div className="rpfood-fulfillment-shell__header">
                  <span className="rpfood-fulfillment-shell__eyebrow">Como voce quer receber?</span>
                  <h5 className="rpfood-fulfillment-shell__title">Escolha o jeito mais pratico para finalizar seu pedido</h5>
                  <p className="rpfood-fulfillment-shell__subtitle">
                    {allowPickup
                      ? "Selecione entre entrega no endereco ou retirada no balcao e siga para o pagamento."
                      : "Confira o endereco de entrega e siga para o pagamento."}
                  </p>
                </div>

                <div
                  className={allowPickup ? "rpfood-fulfillment-switch" : "rpfood-fulfillment-switch rpfood-fulfillment-switch--single"}
                  role="tablist"
                  aria-label="Tipo de recebimento"
                >
                  <button
                    type="button"
                    className={
                      checkout.tipoEntrega === "D"
                        ? "rpfood-fulfillment-option rpfood-fulfillment-option--active"
                        : "rpfood-fulfillment-option"
                    }
                    onClick={() => onSelectTipoEntrega("D")}
                    aria-pressed={checkout.tipoEntrega === "D"}
                  >
                    <span className="rpfood-fulfillment-option__icon" aria-hidden="true">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M4 11.5L12 5L20 11.5V19C20 19.5523 19.5523 20 19 20H15V14H9V20H5C4.44772 20 4 19.5523 4 19V11.5Z" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round" />
                      </svg>
                    </span>
                    <span className="rpfood-fulfillment-option__body">
                      <span className="rpfood-fulfillment-option__title">Delivery seguro</span>
                      <span className="rpfood-fulfillment-option__meta">Receba no endereco com mais comodidade</span>
                    </span>
                    <span className="rpfood-fulfillment-option__check" aria-hidden="true">
                      <svg width="18" height="18" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <circle cx="10" cy="10" r="8" stroke="currentColor" strokeWidth="1.7" />
                        <path d="M6.5 10.2L8.9 12.6L13.7 7.8" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" />
                      </svg>
                    </span>
                  </button>

                  {allowPickup ? (
                    <button
                      type="button"
                      className={
                        checkout.tipoEntrega === "R"
                          ? "rpfood-fulfillment-option rpfood-fulfillment-option--active"
                          : "rpfood-fulfillment-option"
                      }
                      onClick={() => onSelectTipoEntrega("R")}
                      aria-pressed={checkout.tipoEntrega === "R"}
                    >
                      <span className="rpfood-fulfillment-option__icon" aria-hidden="true">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M12 13C14.7614 13 17 10.7614 17 8C17 5.23858 14.7614 3 12 3C9.23858 3 7 5.23858 7 8C7 10.7614 9.23858 13 12 13Z" stroke="currentColor" strokeWidth="1.8" />
                          <path d="M4 20C4.8 16.9 7.8 15 12 15C16.2 15 19.2 16.9 20 20" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
                        </svg>
                      </span>
                      <span className="rpfood-fulfillment-option__body">
                        <span className="rpfood-fulfillment-option__title">Retirada</span>
                        <span className="rpfood-fulfillment-option__meta">Busque direto no balcao sem esperar entrega</span>
                      </span>
                      <span className="rpfood-fulfillment-option__check" aria-hidden="true">
                        <svg width="18" height="18" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <circle cx="10" cy="10" r="8" stroke="currentColor" strokeWidth="1.7" />
                          <path d="M6.5 10.2L8.9 12.6L13.7 7.8" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" />
                        </svg>
                      </span>
                    </button>
                  ) : null}
                </div>
              </section>
            </div>
          </section>

          <section className="rpfood-checkout-section">
            <div className="rpfood-checkout-section__header">
              <span className="rpfood-checkout-section__eyebrow">
                {checkout.tipoEntrega === "D" ? "Entrega" : "Retirada"}
              </span>
              <h2 className="rpfood-checkout-section__title">
                {checkout.tipoEntrega === "D" ? "Endereco do pedido" : "Dados para retirada"}
              </h2>
              <p className="rpfood-checkout-section__subtitle">
                {checkout.tipoEntrega === "D"
                  ? "Selecione o endereco de entrega ou cadastre um novo sem mexer na logica de selecao e salvamento."
                  : "Confira o local de retirada direto no balcao antes de seguir para o pagamento."}
              </p>
            </div>
            <div className="rpfood-checkout-section__inner">
              {checkout.tipoEntrega === "D" ? (
                <div className="pt-4">
                  <div
                    className="rpfood-delivery-card rpfood-delivery-card--trigger"
                    id="cardEnderecoSelecionado"
                    onClick={onOpenAddressSelector}
                  >
                    <div className="rpfood-delivery-card__body">
                      <div className="rpfood-delivery-card__header">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" stroke="#1B4F72" strokeWidth="2" fill="none" />
                          <circle cx="12" cy="10" r="3" stroke="#1B4F72" strokeWidth="2" fill="none" />
                        </svg>
                        <div className="rpfood-delivery-card__copy">
                          <h6 className="rpfood-delivery-card__title">{selectedAddress?.bairro || "Nenhum endereco selecionado"}</h6>
                          <small className="rpfood-delivery-card__meta">
                            {buildAddressLabel(selectedAddress) || "Selecione um endereco abaixo."}
                          </small>
                        </div>
                        {selectedAddress ? (
                          <div className="rpfood-delivery-card__summary">
                            <span className="rpfood-delivery-card__summary-label">Taxa atual</span>
                            <strong className="rpfood-delivery-card__summary-value">{formatMoney(selectedDeliveryFee)}</strong>
                          </div>
                        ) : null}
                      </div>
                    </div>
                  </div>

                  <div className="rpfood-delivery-card rpfood-delivery-card--list mt-2">
                    <div className="rpfood-delivery-card__body">
                      <h6 className="rpfood-delivery-card__section-title">{deliveryListTitle}</h6>
                      {hasAlternativeAddresses ? (
                        <ul className="rpfood-delivery-card__list">
                          {alternativeAddresses.map((address) => {
                            const isSelected = address.idEndereco === selectedAddressId;
                            return (
                              <li
                                key={address.idEndereco || `${address.endereco}-${address.numero}`}
                                className={isSelected ? "rpfood-delivery-card__item rpfood-delivery-card__item--active" : "rpfood-delivery-card__item"}
                                onClick={() => onSelectAddress(address.idEndereco)}
                              >
                                <div className="rpfood-delivery-card__item-copy">
                                  <h6 className="rpfood-delivery-card__item-title">{address.bairro}</h6>
                                  <small className="rpfood-delivery-card__item-meta">{buildAddressLabel(address)}</small>
                                  <span className="rpfood-delivery-card__item-fee">
                                    Taxa de entrega {formatMoney(resolveAddressDeliveryFee(address, neighborhoods))}
                                  </span>
                                </div>
                                <input
                                  type="radio"
                                  readOnly
                                  checked={isSelected}
                                  className="rpfood-delivery-card__radio"
                                />
                              </li>
                            );
                          })}
                        </ul>
                      ) : (
                        <div className="rpfood-order-items-shell__empty">
                          Esse endereco ja esta selecionado. Cadastre outro endereco se quiser trocar a entrega.
                        </div>
                      )}

                      <button
                        type="button"
                        onClick={onOpenNewAddress}
                        className="rpfood-delivery-card__add"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className="rpfood-delivery-card__add-icon">
                          <line x1="12" y1="5" x2="12" y2="19" />
                          <line x1="5" y1="12" x2="19" y2="12" />
                        </svg>
                        Novo Endereco
                      </button>
                    </div>
                  </div>

                  {showNewAddressForm ? (
                    <div className="rpfood-inline-address-form mt-2">
                      <div className="rpfood-inline-address-form__header">
                        <h6 className="rpfood-inline-address-form__title">Cadastrar Novo Endereco</h6>
                        <button
                          type="button"
                          onClick={onCloseNewAddress}
                          className="rpfood-inline-address-form__close"
                        >
                          &times;
                        </button>
                      </div>

                      <div className="rpfood-inline-address-form__body">
                        <div className="rpfood-form-grid">
                          <div className="rpfood-form-field rpfood-form-field--full">
                            <label htmlFor="checkout-novo-endereco-bairro-base">
                              {usesCep ? (
                                <>
                                  CEP <span className="text-danger">*</span>
                                </>
                              ) : (
                                <>
                                  Bairro <span className="text-danger">*</span>
                                </>
                              )}
                            </label>
                            {usesCep ? (
                              <input
                                id="checkout-novo-endereco-bairro-base"
                                value={newAddress.cep}
                                onBlur={onLookupCep}
                                onChange={(event) => onUpdateNewAddress("cep", event.target.value)}
                                placeholder="Digite o CEP"
                              />
                            ) : (
                              <select
                                id="checkout-novo-endereco-bairro-base"
                                value={newAddress.bairroId || ""}
                                onChange={(event) => onUpdateNewAddress("bairroId", Number(event.target.value) || 0)}
                              >
                                <option value="">Selecione o bairro</option>
                                {neighborhoods.map((bairro) => (
                                  <option key={bairro.idBairro} value={bairro.idBairro}>
                                    {bairro.descricao}
                                  </option>
                                ))}
                              </select>
                            )}
                          </div>

                          <div className="rpfood-form-field rpfood-form-field--span-2">
                            <label htmlFor="checkout-novo-endereco-logradouro">
                              Endereco <span className="text-danger">*</span>
                            </label>
                            <input
                              id="checkout-novo-endereco-logradouro"
                              value={newAddress.endereco}
                              onChange={(event) => onUpdateNewAddress("endereco", event.target.value)}
                              readOnly={usesCep}
                            />
                          </div>

                          <div className="rpfood-form-field">
                            <label htmlFor="checkout-novo-endereco-numero">
                              Numero <span className="text-danger">*</span>
                            </label>
                            <input
                              id="checkout-novo-endereco-numero"
                              value={newAddress.numero}
                              onChange={(event) => onUpdateNewAddress("numero", event.target.value)}
                            />
                          </div>

                          <div className="rpfood-form-field">
                            <label htmlFor="checkout-novo-endereco-complemento">Complemento</label>
                            <input
                              id="checkout-novo-endereco-complemento"
                              value={newAddress.complemento}
                              onChange={(event) => onUpdateNewAddress("complemento", event.target.value)}
                            />
                          </div>

                          <div className="rpfood-form-field">
                            <label htmlFor="checkout-novo-endereco-bairro">Bairro</label>
                            <input id="checkout-novo-endereco-bairro" value={newAddress.bairro} readOnly />
                          </div>

                          <div className="rpfood-form-field">
                            <label htmlFor="checkout-novo-endereco-referencia">Referencia</label>
                            <input
                              id="checkout-novo-endereco-referencia"
                              value={newAddress.pontoReferencia}
                              onChange={(event) => onUpdateNewAddress("pontoReferencia", event.target.value)}
                            />
                          </div>
                        </div>

                        <div className="rpfood-inline-address-form__actions">
                          <button
                            type="button"
                            onClick={onSaveNewAddress}
                            className="rpfood-primary-action"
                          >
                            Salvar e Selecionar
                          </button>
                          <button
                            type="button"
                            onClick={onCloseNewAddress}
                            className="rpfood-secondary-action"
                          >
                            Cancelar
                          </button>
                        </div>
                      </div>
                    </div>
                  ) : null}
                </div>
              ) : (
                <div className="pt-4">
                  <div className="rpfood-pickup-card">
                    <div className="rpfood-pickup-card__header">
                      <span className="rpfood-pickup-card__eyebrow">Retirada no balcao</span>
                      <h4 className="rpfood-pickup-card__title">
                        <span className="rpfood-pickup-card__store">{company?.nome || "Loja"}</span>
                        <span className="rpfood-pickup-card__divider">Endereco de retirada</span>
                      </h4>
                    </div>
                    <div className="rpfood-pickup-card__body">
                      <p>{company?.endereco.endereco || ""} N {company?.endereco.numero || ""}</p>
                      <p>Bairro: {company?.endereco.bairro || ""}</p>
                      {company?.endereco.complemento ? <p>{company.endereco.complemento}</p> : null}
                      {company?.fone1 ? <p>{company.fone1}</p> : null}
                    </div>
                  </div>
                </div>
              )}
            </div>
          </section>

          <section className="rpfood-checkout-section">
            <div className="rpfood-checkout-section__header">
              <span className="rpfood-checkout-section__eyebrow">Pagamento</span>
              <h2 className="rpfood-checkout-section__title">Escolha como voce vai pagar</h2>
              <p className="rpfood-checkout-section__subtitle">
                A selecao abaixo continua usando exatamente a mesma logica de pagamento, troco e confirmacao.
              </p>
            </div>

            <div className="rpfood-checkout-section__inner">
              <div className="rpfood-payment-grid" id="div_lista_pagamentos">
                {payments.map((payment) => {
                  const isSelected = payment.id === checkout.formaPagamentoId;

                  return (
                    <label
                      key={payment.id}
                      className={isSelected ? "rpfood-payment-option rpfood-payment-option--active" : "rpfood-payment-option"}
                      htmlFor={`pagamento_${payment.id}`}
                    >
                      <input
                        type="radio"
                        className="rpfood-payment-option__radio"
                        id={`pagamento_${payment.id}`}
                        checked={isSelected}
                        onChange={() => onChangePayment(payment.id)}
                      />
                      <div className="rpfood-payment-option__body">
                        <div className="rpfood-payment-option__top">
                          <strong className="rpfood-payment-option__title">{payment.descricao}</strong>
                          <span className="rpfood-payment-option__marker">{isSelected ? "Selecionado" : "Escolher"}</span>
                        </div>
                        <p className="rpfood-payment-option__meta">{paymentDescription(payment)}</p>
                      </div>
                    </label>
                  );
                })}
              </div>

              <div id="div_totais_pedido" className="rpfood-totals-grid">
                <div className="rpfood-totals-card">
                  <span>Total do pedido</span>
                  <strong id="span_valor_total">{formatMoney(total)}</strong>
                </div>
                <div className="rpfood-totals-card">
                  <span>Valor pago</span>
                  <strong id="span_valor_pago">{formatMoney(valorPago)}</strong>
                </div>
                <div className="rpfood-totals-card rpfood-totals-card--accent">
                  <span>Valor troco</span>
                  <strong id="span_valor_troco">{formatMoney(valorTroco)}</strong>
                </div>
              </div>
            </div>
          </section>

          <section className="rpfood-checkout-section">
            <div className="rpfood-checkout-section__header">
              <span className="rpfood-checkout-section__eyebrow">Resumo</span>
              <h2 className="rpfood-checkout-section__title">Itens do Pedido</h2>
              <p className="rpfood-checkout-section__subtitle">
                Confira itens, complementos e valores antes da confirmacao final.
              </p>
            </div>
            <div className="rpfood-checkout-section__inner">
              {cart.length ? (
                cart.map((item) => <ProductOrderCard key={item.id} item={item} formatMoney={formatMoney} />)
              ) : (
                <div className="rpfood-order-items-shell__empty">Seu carrinho esta vazio.</div>
              )}
            </div>
          </section>

          <section className="rpfood-checkout-section">
            <div className="rpfood-checkout-section__inner">
              <section className="rpfood-observation-card">
                <div className="rpfood-observation-card__header">
                  <div>
                    <span className="rpfood-observation-card__eyebrow">Toque final do pedido</span>
                    <h4 className="rpfood-observation-card__title">Observacao do pedido</h4>
                    <p className="rpfood-observation-card__subtitle">
                      Conte algo importante para a cozinha ou para a entrega, como preferencia no preparo ou orientacao para chegar ate voce.
                    </p>
                  </div>
                  <div
                    className={
                      remainingObservationChars <= 15
                        ? "rpfood-observation-card__counter rpfood-observation-card__counter--warning"
                        : "rpfood-observation-card__counter"
                    }
                  >
                    <strong>{observationLength}</strong>
                    <span>/100</span>
                  </div>
                </div>

                <div className="rpfood-observation-card__composer">
                  <textarea
                    className="rpfood-observation-card__textarea"
                    value={checkout.observacao}
                    maxLength={100}
                    onChange={(event) => onChangeObservation(event.target.value)}
                    placeholder={observationPlaceholder}
                    rows={5}
                  />

                  <div className="rpfood-observation-card__footer">
                    <span className="rpfood-observation-card__hint">
                      {remainingObservationChars > 0
                        ? `${remainingObservationChars} caracteres disponiveis`
                        : "Limite maximo atingido"}
                    </span>
                    {checkout.observacao ? (
                      <button
                        type="button"
                        className="rpfood-observation-card__clear"
                        onClick={() => onChangeObservation("")}
                      >
                        Limpar
                      </button>
                    ) : null}
                  </div>
                </div>

                <div className="rpfood-observation-card__suggestions">
                  {observationSuggestions.map((suggestion) => {
                    const active = checkout.observacao.toLowerCase().includes(suggestion.toLowerCase());
                    return (
                      <button
                        key={suggestion}
                        type="button"
                        className={
                          active
                            ? "rpfood-observation-card__chip rpfood-observation-card__chip--active"
                            : "rpfood-observation-card__chip"
                        }
                        onClick={() => onChangeObservation(appendObservationSuggestion(checkout.observacao, suggestion))}
                      >
                        {suggestion}
                      </button>
                    );
                  })}
                </div>
              </section>
            </div>
          </section>
        </div>
      </div>

      <div id="checkoutActionBar">
        <div id="checkoutActionBarResumo">
          <div id="checkoutActionBarMeta">
            <strong>Pronto para confirmar</strong>
            <span>Revise endereco e pagamento antes de fechar o pedido.</span>
          </div>
          <div id="checkoutActionBarValor">
            {formatMoney(total)}
          </div>
        </div>

        <button
          id="checkoutActionButton"
          type="button"
          onClick={onConfirm}
          disabled={checkoutActionDisabled}
        >
          {saving ? "Confirmando..." : "Confirmar pedido"}
        </button>
      </div>

      {showTrocoModal ? (
        <div
          className="rpfood-troco-modal"
          onClick={onCancelTroco}
        >
          <div
            className="rpfood-troco-modal__dialog"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="rpfood-troco-modal__header">
              <div>
                <span className="rpfood-troco-modal__eyebrow">Pagamento em dinheiro</span>
                <h5 className="rpfood-troco-modal__title">Troco para quanto?</h5>
                <p className="rpfood-troco-modal__subtitle">
                  Informe quanto vai pagar para o entregador já sair com o troco certo.
                </p>
              </div>
              <button
                type="button"
                className="rpfood-troco-modal__close"
                onClick={onCancelTroco}
                aria-label="Fechar modal de troco"
              >
                ×
              </button>
            </div>

            <div className="rpfood-troco-modal__body">
              <div className="rpfood-troco-modal__summary">
                <div className="rpfood-troco-modal__summary-card">
                  <span>Pedido</span>
                  <strong>{formatMoney(total)}</strong>
                </div>
                <div className="rpfood-troco-modal__summary-card">
                  <span>Você paga</span>
                  <strong>{`R$ ${valorRecebidoLabel}`}</strong>
                </div>
                <div className="rpfood-troco-modal__summary-card rpfood-troco-modal__summary-card--accent">
                  <span>Troco estimado</span>
                  <strong>{trocoStatusLabel}</strong>
                </div>
              </div>

              <label className="rpfood-troco-modal__label" htmlFor="troco-valor-recebido">
                Valor recebido pelo entregador
              </label>

              <div className="rpfood-troco-modal__input-wrap">
                <span className="rpfood-troco-modal__input-prefix">R$</span>
                <input
                  id="troco-valor-recebido"
                  className="rpfood-troco-modal__input"
                  value={checkout.valorAReceber}
                  onChange={(event) => onChangeTrocoValue(event.target.value)}
                  placeholder="0,00"
                  inputMode="decimal"
                />
              </div>

              <p className="rpfood-troco-modal__hint">
                Se não precisar de troco, use o valor exato do pedido.
              </p>

              <div className="rpfood-troco-modal__suggestions">
                {trocoSuggestions.map((suggestion) => {
                  const active = checkout.valorAReceber === suggestion;
                  return (
                    <button
                      key={suggestion}
                      type="button"
                      className={active ? "rpfood-troco-modal__chip rpfood-troco-modal__chip--active" : "rpfood-troco-modal__chip"}
                      onClick={() => onChangeTrocoValue(suggestion)}
                    >
                      {`R$ ${suggestion}`}
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="rpfood-troco-modal__footer">
              <button
                type="button"
                onClick={onCancelTroco}
                className="rpfood-troco-modal__button rpfood-troco-modal__button--secondary"
              >
                Cancelar
              </button>
              <button
                type="button"
                onClick={onConfirmTroco}
                className="rpfood-troco-modal__button rpfood-troco-modal__button--primary"
              >
                Confirmar
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
