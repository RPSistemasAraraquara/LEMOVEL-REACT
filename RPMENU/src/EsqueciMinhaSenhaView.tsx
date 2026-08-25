type Props = {
  email: string;
  error: string;
  loading: boolean;
  message: string;
  onBack: () => void;
  onChangeEmail: (value: string) => void;
  onSubmit: () => void;
};

export function EsqueciMinhaSenhaView({
  email,
  error,
  loading,
  message,
  onBack,
  onChangeEmail,
  onSubmit,
}: Props) {
  return (
    <div className="body">
      <div className="rpfood-auth-shell">
        <div className="rpfood-auth-card rpfood-auth-card--login">
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
            <span className="rpfood-auth-kicker">Recuperacao de acesso</span>
            <h1 className="rpfood-auth-title">Esqueci minha Senha</h1>
            <p className="rpfood-auth-subtitle">
              Informe o email vinculado ao seu cadastro para gerar uma nova senha e voltar ao pedido com seguranca.
            </p>
          </div>

          <section className="rpfood-auth-highlight">
            <span className="rpfood-auth-highlight__eyebrow">Recuperacao guiada</span>
            <strong className="rpfood-auth-highlight__title">Vamos te ajudar a entrar de novo</strong>
            <p className="rpfood-auth-highlight__text">
              Usamos esse email apenas para localizar o cadastro correto e iniciar a recuperacao sem mexer em nenhum outro dado seu.
            </p>
          </section>

          <form
            className="rpfood-auth-form"
            onSubmit={(event) => {
              event.preventDefault();
              onSubmit();
            }}
          >
            <div className="rpfood-form-field rpfood-form-field--full">
              <label htmlFor="forgot-email">
                Email <span className="text-danger">*</span>
              </label>
              <input
                id="forgot-email"
                type="email"
                value={email}
                onChange={(event) => onChangeEmail(event.target.value)}
                autoComplete="email"
                placeholder="voce@exemplo.com"
              />
            </div>

            <div className="rpfood-auth-actions">
              <button type="submit" className="rpfood-primary-action" disabled={loading}>
                {loading ? "Gerando..." : "Gerar nova senha"}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
