import type { Bairro } from "./types";

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
  bairros: Bairro[];
  error: string;
  form: AddressForm;
  loading: boolean;
  message: string;
  usesCep: boolean;
  onBack: () => void;
  onLookupCep: () => void;
  onSave: () => void;
  onUpdate: <K extends keyof AddressForm>(field: K, value: AddressForm[K]) => void;
};

export function NovoEnderecoView({
  bairros,
  error,
  form,
  loading,
  message,
  usesCep,
  onBack,
  onLookupCep,
  onSave,
  onUpdate,
}: Props) {
  const title = form.idEndereco > 0 ? "Cadastro Endereco" : "Novo Endereco";

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

          <div className="rpfood-auth-header rpfood-auth-header--compact">
            <div className="rpfood-auth-logo-wrap">
              <img src="/images/logo-full.png" alt="RP Food" className="rpfood-auth-logo" />
            </div>
            <span className="rpfood-auth-kicker">Endereco do cliente</span>
            <h1 className="rpfood-auth-title">{title}</h1>
            <p className="rpfood-auth-subtitle">
              Deixe o endereco bem completo para reduzir contato extra, acelerar o despacho e evitar erro na entrega.
            </p>
          </div>

          <section className="rpfood-auth-highlight">
            <span className="rpfood-auth-highlight__eyebrow">{usesCep ? "Busca por CEP" : "Preenchimento manual"}</span>
            <strong className="rpfood-auth-highlight__title">
              {usesCep ? "Preencha o CEP para ajudar no endereco" : "Escolha o bairro e confirme os detalhes"}
            </strong>
            <p className="rpfood-auth-highlight__text">
              Esses dados so organizam sua entrega. Nenhuma regra de calculo, cadastro ou salvamento foi alterada neste ajuste visual.
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
                  <label htmlFor="novo-endereco-cep">
                    CEP <span className="text-danger">*</span>
                  </label>
                  <input
                    id="novo-endereco-cep"
                    value={form.cep}
                    onBlur={onLookupCep}
                    onChange={(event) => onUpdate("cep", event.target.value)}
                    maxLength={8}
                    placeholder="Somente numeros"
                  />
                </div>
              ) : null}

              <div className={`rpfood-form-field ${usesCep ? "rpfood-form-field--span-2" : "rpfood-form-field--full"}`}>
                <label htmlFor="novo-endereco-logradouro">
                  Endereco <span className="text-danger">*</span>
                </label>
                <input
                  id="novo-endereco-logradouro"
                  value={form.endereco}
                  onChange={(event) => onUpdate("endereco", event.target.value)}
                  readOnly={usesCep}
                  placeholder="Rua, avenida ou praca"
                />
              </div>

              <div className="rpfood-form-field">
                <label htmlFor="novo-endereco-numero">
                  Numero <span className="text-danger">*</span>
                </label>
                <input
                  id="novo-endereco-numero"
                  value={form.numero}
                  onChange={(event) => onUpdate("numero", event.target.value)}
                  placeholder="Ex.: 123"
                />
              </div>

              <div className="rpfood-form-field">
                <label htmlFor="novo-endereco-complemento">Complemento</label>
                <input
                  id="novo-endereco-complemento"
                  value={form.complemento}
                  onChange={(event) => onUpdate("complemento", event.target.value)}
                  placeholder="Apto, bloco, sala..."
                />
              </div>

              <div className="rpfood-form-field">
                <label htmlFor="novo-endereco-referencia">Referencia</label>
                <input
                  id="novo-endereco-referencia"
                  value={form.pontoReferencia}
                  onChange={(event) => onUpdate("pontoReferencia", event.target.value)}
                  placeholder="Ponto de referencia"
                />
              </div>

              <div className="rpfood-form-field">
                <label htmlFor="novo-endereco-bairro">
                  Bairro <span className="text-danger">*</span>
                </label>
                {usesCep ? (
                  <input id="novo-endereco-bairro" value={form.bairro} readOnly />
                ) : (
                  <select
                    id="novo-endereco-bairro"
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

              {!usesCep ? (
                <div className="rpfood-form-field">
                  <label htmlFor="novo-endereco-bairro-selecionado">Bairro selecionado</label>
                  <input id="novo-endereco-bairro-selecionado" value={form.bairro} readOnly />
                </div>
              ) : null}

              <div className="rpfood-form-field rpfood-form-field--price">
                <label htmlFor="novo-endereco-taxa">Taxa motoboy</label>
                <input
                  id="novo-endereco-taxa"
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
                {loading ? "Salvando..." : "Salvar"}
              </button>
              <button type="button" className="rpfood-secondary-action" onClick={onBack} disabled={loading}>
                Cancelar
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
