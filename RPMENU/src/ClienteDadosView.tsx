type ProfileForm = {
  nome: string;
  email: string;
  senha: string;
  celular: string;
  telefone: string;
};

type Props = {
  error: string;
  form: ProfileForm;
  loading: boolean;
  message: string;
  onBack: () => void;
  onSave: () => void;
  onUpdate: <K extends keyof ProfileForm>(field: K, value: ProfileForm[K]) => void;
};

export function ClienteDadosView({
  error,
  form,
  loading,
  message,
  onBack,
  onSave,
  onUpdate,
}: Props) {
  const profileStatus = form.nome.trim() && form.celular.trim() ? "Perfil pronto para agilizar seu pedido" : "Complete os dados principais do seu cadastro";
  const contactLabel = form.celular.trim() || "Nao informado";
  const secondaryLabel = form.telefone.trim() || "Opcional";

  return (
    <div className="body">
      <div className="rpfood-auth-shell">
        <div className="rpfood-auth-card">
          <div className="rpfood-login-toolbar">
            <button type="button" onClick={onBack} className="rpfood-back-button">
              Voltar
            </button>
            <span className="rpfood-login-status">{loading ? "Salvando alteracoes..." : ""}</span>
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
            <span className="rpfood-auth-kicker">Perfil do cliente</span>
            <h1 className="rpfood-auth-title">Meus dados</h1>
          </div>

          <section className="rpfood-profile-summary" aria-label="Resumo do perfil">
            <div className="rpfood-profile-summary__item">
              <span className="rpfood-profile-summary__label">Status</span>
              <strong className="rpfood-profile-summary__value">{profileStatus}</strong>
            </div>
            <div className="rpfood-profile-summary__item">
              <span className="rpfood-profile-summary__label">Celular principal</span>
              <strong className="rpfood-profile-summary__value">{contactLabel}</strong>
            </div>
            <div className="rpfood-profile-summary__item">
              <span className="rpfood-profile-summary__label">Telefone de apoio</span>
              <strong className="rpfood-profile-summary__value">{secondaryLabel}</strong>
            </div>
          </section>

          <form
            className="rpfood-auth-form"
            onSubmit={(event) => {
              event.preventDefault();
              onSave();
            }}
          >
            <div className="rpfood-form-grid">
              <div className="rpfood-form-field rpfood-form-field--full">
                <label htmlFor="perfil-nome">
                  Nome <span className="text-danger">*</span>
                </label>
                <input
                  id="perfil-nome"
                  value={form.nome}
                  onChange={(event) => onUpdate("nome", event.target.value)}
                  placeholder="Como devemos te chamar?"
                />
              </div>

              <div className="rpfood-form-field">
                <label htmlFor="perfil-email">Email</label>
                <input
                  id="perfil-email"
                  value={form.email}
                  onChange={(event) => onUpdate("email", event.target.value)}
                  placeholder="voce@exemplo.com"
                />
              </div>

              <div className="rpfood-form-field">
                <label htmlFor="perfil-celular">
                  Celular (DDD + Numero) <span className="text-danger">*</span>
                </label>
                <input
                  id="perfil-celular"
                  value={form.celular}
                  onChange={(event) => onUpdate("celular", event.target.value)}
                  maxLength={11}
                  placeholder="11999999999"
                />
              </div>

              <div className="rpfood-form-field rpfood-form-field--span-2">
                <label htmlFor="perfil-telefone">Telefone adicional</label>
                <input
                  id="perfil-telefone"
                  value={form.telefone}
                  onChange={(event) => onUpdate("telefone", event.target.value)}
                  maxLength={11}
                  placeholder="Opcional para contato alternativo"
                />
              </div>
            </div>

            <div className="rpfood-auth-actions">
              <button type="submit" className="rpfood-primary-action" disabled={loading}>
                {loading ? "Salvando..." : "Salvar alteracoes"}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
