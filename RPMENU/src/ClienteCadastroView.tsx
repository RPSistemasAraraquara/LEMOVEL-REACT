import type { Bairro } from "./types";

type CadastroForm = {
  nome: string;
  celular: string;
  telefone: string;
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
  form: CadastroForm;
  loading: boolean;
  message: string;
  usesCep: boolean;
  onBack: () => void;
  onLookupCep: () => void;
  onOpenLogin: () => void;
  onSave: () => void;
  onUpdate: <K extends keyof CadastroForm>(field: K, value: CadastroForm[K]) => void;
};

export function ClienteCadastroView({
  bairros,
  error,
  form,
  loading,
  message,
  usesCep,
  onBack,
  onLookupCep,
  onOpenLogin,
  onSave,
  onUpdate,
}: Props) {
  return (
    <div className="body">
      <div className="rpfood-auth-shell">
        <div className="rpfood-auth-card rpfood-auth-card--wide">
          <div className="rpfood-login-toolbar">
            <button type="button" onClick={onBack} className="rpfood-back-button">
              Voltar
            </button>
            <span className="rpfood-login-status">{loading ? "Gravando..." : ""}</span>
          </div>

          {(message || error) && (
            <section className="rpfood-feedback-stack">
              {message ? <div className="rpfood-feedback-stack__item rpfood-feedback-stack__item--ok">{message}</div> : null}
              {error ? <div className="rpfood-feedback-stack__item rpfood-feedback-stack__item--error">{error}</div> : null}
            </section>
          )}

          <div className="rpfood-auth-header rpfood-auth-header--compact">
            <div className="rpfood-auth-logo-wrap">
              <img src="/images/logo-full.png" alt="RPFood" className="rpfood-auth-logo" />
            </div>
            <span className="rpfood-auth-kicker">Novo cliente</span>
            <h1 className="rpfood-auth-title">Dados de Cadastro</h1>
            <p className="rpfood-auth-subtitle">
              Preencha seus dados para deixar o checkout mais rapido e salvar seu endereco com seguranca.
            </p>
          </div>

          <form
            className="rpfood-auth-form"
            onSubmit={(event) => {
              event.preventDefault();
              onSave();
            }}
          >
            <div className="rpfood-form-grid">
              <div className="rpfood-form-field rpfood-form-field--full">
                <label htmlFor="cadastro-nome">
                  Nome <span className="text-danger">*</span>
                </label>
                <input
                  id="cadastro-nome"
                  value={form.nome}
                  onChange={(event) => onUpdate("nome", event.target.value)}
                  placeholder="Como devemos te chamar?"
                />
              </div>

              <div className="rpfood-form-field">
                <label htmlFor="cadastro-celular">
                  Celular (DDD + Numero) <span className="text-danger">*</span>
                </label>
                <input
                  id="cadastro-celular"
                  value={form.celular}
                  onChange={(event) => onUpdate("celular", event.target.value)}
                  maxLength={11}
                  placeholder="11999999999"
                />
              </div>

              <div className="rpfood-form-field">
                <label htmlFor="cadastro-telefone">Telefone fixo</label>
                <input
                  id="cadastro-telefone"
                  value={form.telefone}
                  onChange={(event) => onUpdate("telefone", event.target.value)}
                  maxLength={11}
                  placeholder="Opcional"
                />
              </div>

              {usesCep ? (
                <div className="rpfood-form-field">
                  <label htmlFor="cadastro-cep">
                    CEP <span className="text-danger">*</span>
                  </label>
                  <input
                    id="cadastro-cep"
                    value={form.cep}
                    onBlur={onLookupCep}
                    onChange={(event) => onUpdate("cep", event.target.value)}
                    maxLength={8}
                    placeholder="Somente numeros"
                  />
                </div>
              ) : null}

              <div className={`rpfood-form-field ${usesCep ? "rpfood-form-field--span-2" : "rpfood-form-field--full"}`}>
                <label htmlFor="cadastro-endereco">
                  Endereco <span className="text-danger">*</span>
                </label>
                <input
                  id="cadastro-endereco"
                  value={form.endereco}
                  onChange={(event) => onUpdate("endereco", event.target.value)}
                  readOnly={usesCep}
                  placeholder="Rua, avenida ou praca"
                />
              </div>

              <div className="rpfood-form-field">
                <label htmlFor="cadastro-numero">
                  Numero <span className="text-danger">*</span>
                </label>
                <input
                  id="cadastro-numero"
                  value={form.numero}
                  onChange={(event) => onUpdate("numero", event.target.value)}
                  placeholder="Ex.: 123"
                />
              </div>

              <div className="rpfood-form-field">
                <label htmlFor="cadastro-complemento">Complemento</label>
                <input
                  id="cadastro-complemento"
                  value={form.complemento}
                  onChange={(event) => onUpdate("complemento", event.target.value)}
                  placeholder="Apto, bloco, sala..."
                />
              </div>

              <div className="rpfood-form-field">
                <label htmlFor="cadastro-referencia">Referencia</label>
                <input
                  id="cadastro-referencia"
                  value={form.pontoReferencia}
                  onChange={(event) => onUpdate("pontoReferencia", event.target.value)}
                  placeholder="Ponto de referencia"
                />
              </div>

              <div className="rpfood-form-field">
                <label htmlFor="cadastro-bairro">
                  Bairro <span className="text-danger">*</span>
                </label>
                {usesCep ? (
                  <input id="cadastro-bairro" value={form.bairro} readOnly />
                ) : (
                  <select
                    id="cadastro-bairro"
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
                <label htmlFor="cadastro-taxa">Taxa motoboy</label>
                <input
                  id="cadastro-taxa"
                  value={form.taxaEntrega.toLocaleString("pt-BR", {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2,
                  })}
                  readOnly
                />
              </div>
            </div>

            <div className="rpfood-auth-actions">
              <button type="submit" className="rpfood-primary-action" disabled={loading}>
                Cadastrar
              </button>
            </div>
          </form>

          <div className="rpfood-auth-footer">
            <span>Ja tem uma conta?</span>
            <button type="button" onClick={onOpenLogin} className="rpfood-text-link">
              Fazer login
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
