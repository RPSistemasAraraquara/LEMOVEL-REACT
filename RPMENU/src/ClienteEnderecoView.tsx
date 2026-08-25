import type { Bairro, Endereco } from "./types";

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

type Props = {
  addresses: Endereco[];
  bairros: Bairro[];
  editing: boolean;
  error: string;
  form: AddressForm;
  loading: boolean;
  message: string;
  usesCep: boolean;
  onBack: () => void;
  onCancelEdit: () => void;
  onLookupCep: () => void;
  onSave: () => void;
  onSelectDefault: (addressId: number) => void;
  onStartCreate: () => void;
  onStartEdit: (addressId: number) => void;
  onUpdate: <K extends keyof AddressForm>(field: K, value: AddressForm[K]) => void;
};

function addressTitle(address: Endereco): string {
  return `${address.endereco}, ${address.numero}`.trim();
}

function addressSubtitle(address: Endereco): string {
  const parts = [address.bairro];
  if (address.cep) parts.push(`CEP: ${address.cep}`);
  if (address.complemento) parts.push(address.complemento);
  return parts.filter(Boolean).join(" - ");
}

export function ClienteEnderecoView({
  addresses,
  bairros,
  editing,
  error,
  form,
  loading,
  message,
  usesCep,
  onBack,
  onCancelEdit,
  onLookupCep,
  onSave,
  onSelectDefault,
  onStartCreate,
  onStartEdit,
  onUpdate,
}: Props) {
  const selectedAddress = addresses.find((address) => address.enderecoPadrao) ?? null;
  const editingTitle = form.idEndereco > 0 ? "Cadastro Endereco" : "Novo Endereco";

  return (
    <div className="body">
      <div className="rpfood-auth-shell">
        <div className="rpfood-auth-card rpfood-auth-card--wide">
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

          {!editing ? (
            <>
              <div className="rpfood-auth-header rpfood-auth-header--compact">
                <div className="rpfood-auth-logo-wrap">
                  <img src="/images/logo-full.png" alt="RP Food" className="rpfood-auth-logo" />
                </div>
                <span className="rpfood-auth-kicker">Entrega e localizacao</span>
                <h1 className="rpfood-auth-title">Meus Enderecos</h1>
                <p className="rpfood-auth-subtitle">
                  Escolha o endereco padrao para o pedido atual ou cadastre um novo ponto de entrega sem mexer nas regras do checkout.
                </p>
              </div>

              <section className="rpfood-auth-highlight rpfood-auth-highlight--cool">
                <span className="rpfood-auth-highlight__eyebrow">Resumo rapido</span>
                <strong className="rpfood-auth-highlight__title">
                  {selectedAddress ? "Ja existe um endereco principal selecionado" : "Defina um endereco para agilizar o pedido"}
                </strong>
                <p className="rpfood-auth-highlight__text">
                  {selectedAddress
                    ? `${addressTitle(selectedAddress)}. Voce pode manter esse padrao ou trocar quando quiser.`
                    : "Quando um endereco estiver marcado, o fechamento do pedido fica mais rapido e com menos retrabalho."}
                </p>
              </section>

              <div className="rpfood-address-list-header">
                <div className="rpfood-address-list-header__meta">
                  <strong>{addresses.length} endereco{addresses.length === 1 ? "" : "s"} salvo{addresses.length === 1 ? "" : "s"}</strong>
                  <span>{selectedAddress ? "Um deles ja esta pronto para uso" : "Nenhum endereco definido como principal"}</span>
                </div>
                <button type="button" className="rpfood-secondary-action rpfood-address-list-header__button" onClick={onStartCreate}>
                  Novo Endereco
                </button>
              </div>

              <section className="rpfood-address-list" aria-label="Lista de enderecos">
                {addresses.length ? (
                  addresses.map((address) => {
                    const isPadrao = address.enderecoPadrao;

                    return (
                      <article
                        key={address.idEndereco || `${address.endereco}-${address.numero}`}
                        className={`rpfood-address-card ${isPadrao ? "rpfood-address-card--active" : ""}`}
                      >
                        <div className="rpfood-address-card__header">
                          <span className="rpfood-address-card__icon" aria-hidden="true">
                            <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
                              <circle cx="12" cy="10" r="3" />
                            </svg>
                          </span>

                          <div className="rpfood-address-card__content">
                            <strong className="rpfood-address-card__title">{addressTitle(address)}</strong>
                            <p className="rpfood-address-card__text">{addressSubtitle(address)}</p>
                          </div>

                          {isPadrao ? <span className="rpfood-address-card__badge">PADRAO</span> : null}
                        </div>

                        <div className="rpfood-address-card__actions">
                          <button
                            type="button"
                            className={`rpfood-address-card__button ${isPadrao ? "rpfood-address-card__button--selected" : "rpfood-address-card__button--primary"}`}
                            onClick={() => onSelectDefault(address.idEndereco)}
                          >
                            {isPadrao ? "Selecionado" : "Selecione endereco para pedido"}
                          </button>

                          <button
                            type="button"
                            className="rpfood-address-card__button rpfood-address-card__button--secondary"
                            onClick={() => onStartEdit(address.idEndereco)}
                          >
                            Editar
                          </button>
                        </div>
                      </article>
                    );
                  })
                ) : (
                  <div className="rpfood-address-empty">
                    <strong>Nenhum endereco cadastrado</strong>
                    <p>Cadastre o primeiro endereco para agilizar o fechamento do pedido e evitar preenchimento repetido.</p>
                  </div>
                )}
              </section>
            </>
          ) : (
            <>
              <div className="rpfood-auth-header rpfood-auth-header--compact">
                <div className="rpfood-auth-logo-wrap">
                  <img src="/images/logo-full.png" alt="RP Food" className="rpfood-auth-logo" />
                </div>
                <span className="rpfood-auth-kicker">Edicao do endereco</span>
                <h1 className="rpfood-auth-title">{editingTitle}</h1>
                <p className="rpfood-auth-subtitle">
                  Ajuste os dados do local de entrega mantendo o mesmo fluxo de cadastro, selecao e salvamento que ja existe hoje.
                </p>
              </div>

              <section className="rpfood-auth-highlight">
                <span className="rpfood-auth-highlight__eyebrow">{usesCep ? "Com CEP" : "Sem CEP"}</span>
                <strong className="rpfood-auth-highlight__title">
                  {usesCep ? "O CEP ajuda a preencher e validar o endereco" : "Preencha os campos manualmente e confirme o bairro"}
                </strong>
                <p className="rpfood-auth-highlight__text">
                  Esta revisao mexe apenas no acabamento visual. Os mesmos handlers de busca, edicao e gravacao continuam sendo usados.
                </p>
              </section>

              <form
                className="rpfood-auth-form"
                onSubmit={(event) => {
                  event.preventDefault();
                  onSave();
                }}
              >
                <div className="rpfood-form-grid">
                  {usesCep ? (
                    <div className="rpfood-form-field">
                      <label htmlFor="cliente-endereco-cep">
                        CEP <span className="text-danger">*</span>
                      </label>
                      <input
                        id="cliente-endereco-cep"
                        value={form.cep}
                        onBlur={onLookupCep}
                        onChange={(event) => onUpdate("cep", event.target.value)}
                        maxLength={8}
                        placeholder="Somente numeros"
                      />
                    </div>
                  ) : null}

                  <div className={`rpfood-form-field ${usesCep ? "rpfood-form-field--span-2" : "rpfood-form-field--full"}`}>
                    <label htmlFor="cliente-endereco-logradouro">
                      Endereco <span className="text-danger">*</span>
                    </label>
                    <input
                      id="cliente-endereco-logradouro"
                      value={form.endereco}
                      onChange={(event) => onUpdate("endereco", event.target.value)}
                      readOnly={usesCep}
                      placeholder="Rua, avenida ou praca"
                    />
                  </div>

                  <div className="rpfood-form-field">
                    <label htmlFor="cliente-endereco-numero">
                      Numero <span className="text-danger">*</span>
                    </label>
                    <input
                      id="cliente-endereco-numero"
                      value={form.numero}
                      onChange={(event) => onUpdate("numero", event.target.value)}
                      placeholder="Ex.: 123"
                    />
                  </div>

                  <div className="rpfood-form-field">
                    <label htmlFor="cliente-endereco-complemento">Complemento</label>
                    <input
                      id="cliente-endereco-complemento"
                      value={form.complemento}
                      onChange={(event) => onUpdate("complemento", event.target.value)}
                      placeholder="Apto, bloco, sala..."
                    />
                  </div>

                  <div className="rpfood-form-field">
                    <label htmlFor="cliente-endereco-referencia">Referencia</label>
                    <input
                      id="cliente-endereco-referencia"
                      value={form.pontoReferencia}
                      onChange={(event) => onUpdate("pontoReferencia", event.target.value)}
                      placeholder="Ponto de referencia"
                    />
                  </div>

                  <div className="rpfood-form-field">
                    <label htmlFor="cliente-endereco-bairro">
                      Bairro <span className="text-danger">*</span>
                    </label>
                    {usesCep ? (
                      <input id="cliente-endereco-bairro" value={form.bairro} readOnly />
                    ) : (
                      <select
                        id="cliente-endereco-bairro"
                        value={form.bairroId || ""}
                        onChange={(event) => onUpdate("bairroId", Number(event.target.value) || 0)}
                      >
                        <option value="">Selecione o bairro</option>
                        {bairros.map((bairro) => (
                          <option key={bairro.idBairro} value={bairro.idBairro}>
                            {bairro.descricao}
                          </option>
                        ))}
                      </select>
                    )}
                  </div>

                  <div className="rpfood-form-field rpfood-form-field--price">
                    <label htmlFor="cliente-endereco-taxa">Taxa motoboy</label>
                    <input
                      id="cliente-endereco-taxa"
                      value={form.taxaEntrega.toLocaleString("pt-BR", {
                        minimumFractionDigits: 2,
                        maximumFractionDigits: 2,
                      })}
                      readOnly
                    />
                  </div>
                </div>

                <div className="rpfood-address-form-actions">
                  <button type="submit" className="rpfood-primary-action" disabled={loading}>
                    {loading ? "Gravando..." : "Gravar"}
                  </button>
                  <button type="button" className="rpfood-secondary-action" onClick={onCancelEdit} disabled={loading}>
                    Cancelar
                  </button>
                </div>
              </form>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
