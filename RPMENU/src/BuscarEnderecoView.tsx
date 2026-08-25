import type { Endereco } from "./types";

type Props = {
  addresses: Endereco[];
  error: string;
  loading: boolean;
  message: string;
  onBack: () => void;
  onSelect: (addressId: number) => void;
  selectedAddressId?: number;
};

function buildAddressTitle(address: Endereco): string {
  return `${address.endereco || "Endereco"}${address.numero ? `, ${address.numero}` : ""}`;
}

function buildAddressSubtitle(address: Endereco): string {
  const parts = [address.bairro];
  if (address.cep) parts.push(`CEP ${address.cep}`);
  if (address.complemento) parts.push(address.complemento);
  if (address.pontoReferencia) parts.push(address.pontoReferencia);
  return parts.filter(Boolean).join(" • ");
}

export function BuscarEnderecoView({
  addresses,
  error,
  loading,
  message,
  onBack,
  onSelect,
  selectedAddressId = 0,
}: Props) {
  const selectedAddress =
    addresses.find((address) => address.idEndereco === selectedAddressId) ??
    addresses.find((address) => address.enderecoPadrao) ??
    null;

  return (
    <div className="body">
      <div className="rpfood-auth-shell">
        <div className="rpfood-auth-card rpfood-auth-card--wide rpfood-address-picker">
          <div className="rpfood-login-toolbar">
            <button type="button" onClick={onBack} className="rpfood-back-button">
              Voltar
            </button>
            <span className="rpfood-login-status">{loading ? "Processando..." : ""}</span>
          </div>

          {(message || error) && (
            <section className="rpfood-feedback-stack">
              {message ? <div className="rpfood-feedback-stack__item rpfood-feedback-stack__item--ok">{message}</div> : null}
              {error ? <div className="rpfood-feedback-stack__item rpfood-feedback-stack__item--error">{error}</div> : null}
            </section>
          )}

          <div className="rpfood-auth-header rpfood-auth-header--compact">
            <div className="rpfood-auth-logo-wrap">
              <img src="/images/logo-full.png" alt="RP Food" className="rpfood-auth-logo" />
            </div>
            <span className="rpfood-auth-kicker">Entrega e localizacao</span>
            <h1 className="rpfood-auth-title">Escolha o endereco da entrega</h1>
            <p className="rpfood-auth-subtitle">
              Selecione o destino do pedido atual. A troca acontece aqui sem alterar a sacola nem o restante do checkout.
            </p>
          </div>

          <section className="rpfood-address-picker__hero">
            <div className="rpfood-address-picker__hero-copy">
              <span className="rpfood-address-picker__eyebrow">Endereco em uso</span>
              <strong className="rpfood-address-picker__hero-title">
                {selectedAddress ? buildAddressTitle(selectedAddress) : "Nenhum endereco selecionado"}
              </strong>
              <p className="rpfood-address-picker__hero-text">
                {selectedAddress
                  ? buildAddressSubtitle(selectedAddress) || "Endereco pronto para esse pedido."
                  : "Escolha um endereco abaixo para continuar com o fechamento do pedido."}
              </p>
            </div>

            <div className="rpfood-address-picker__hero-meta">
              <div className="rpfood-address-picker__stat">
                <span className="rpfood-address-picker__stat-label">Salvos</span>
                <strong className="rpfood-address-picker__stat-value">{addresses.length}</strong>
              </div>
              <div className="rpfood-address-picker__stat">
                <span className="rpfood-address-picker__stat-label">Principal</span>
                <strong className="rpfood-address-picker__stat-value">
                  {selectedAddress?.enderecoPadrao ? "Sim" : "Trocar"}
                </strong>
              </div>
            </div>
          </section>

          <section className="rpfood-address-picker__section">
            <div className="rpfood-address-picker__section-header">
              <div>
                <span className="rpfood-address-picker__section-kicker">Lista pronta para escolha</span>
                <h2 className="rpfood-address-picker__section-title">Meus enderecos</h2>
              </div>
              <span className="rpfood-address-picker__section-count">
                {addresses.length} {addresses.length === 1 ? "opcao" : "opcoes"}
              </span>
            </div>

            {addresses.length ? (
              <div className="rpfood-address-picker__grid">
                {addresses.map((address) => {
                  const isSelected = address.idEndereco === selectedAddressId || (!selectedAddressId && address.enderecoPadrao);

                  return (
                    <article
                      key={address.idEndereco || `${address.endereco}-${address.numero}`}
                      className={isSelected ? "rpfood-address-picker-card rpfood-address-picker-card--active" : "rpfood-address-picker-card"}
                    >
                      <div className="rpfood-address-picker-card__top">
                        <span className="rpfood-address-picker-card__icon" aria-hidden="true">
                          <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
                            <circle cx="12" cy="10" r="3" />
                          </svg>
                        </span>

                        <div className="rpfood-address-picker-card__content">
                          <div className="rpfood-address-picker-card__badges">
                            {isSelected ? <span className="rpfood-address-picker-card__badge rpfood-address-picker-card__badge--active">Em uso</span> : null}
                            {address.enderecoPadrao ? <span className="rpfood-address-picker-card__badge">Padrao</span> : null}
                          </div>
                          <strong className="rpfood-address-picker-card__title">{buildAddressTitle(address)}</strong>
                          <p className="rpfood-address-picker-card__text">{buildAddressSubtitle(address)}</p>
                        </div>
                      </div>

                      <button
                        type="button"
                        className={
                          isSelected
                            ? "rpfood-address-picker-card__button rpfood-address-picker-card__button--selected"
                            : "rpfood-address-picker-card__button"
                        }
                        onClick={() => onSelect(address.idEndereco)}
                      >
                        {isSelected ? "Endereco selecionado" : "Usar este endereco"}
                      </button>
                    </article>
                  );
                })}
              </div>
            ) : (
              <div className="rpfood-address-empty">
                <strong>Nenhum endereco cadastrado</strong>
                <p>Volte para o fechamento e cadastre um novo endereco para continuar com a entrega.</p>
              </div>
            )}
          </section>
        </div>
      </div>
    </div>
  );
}
