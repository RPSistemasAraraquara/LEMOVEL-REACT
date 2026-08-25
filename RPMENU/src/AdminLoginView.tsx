type Props = {
  error: string;
  loading: boolean;
  login: string;
  message: string;
  onBack: () => void;
  onChangeLogin: (value: string) => void;
  onChangePassword: (value: string) => void;
  onSubmit: () => void;
  password: string;
};

export function AdminLoginView({
  error,
  loading,
  login,
  message,
  onBack,
  onChangeLogin,
  onChangePassword,
  onSubmit,
  password,
}: Props) {
  return (
    <div className="body">
      <div className="rpfood-auth-shell">
        <div className="rpfood-auth-card rpfood-auth-card--login">
          <div className="rpfood-login-toolbar">
            <button type="button" onClick={onBack} className="rpfood-back-button">
              Voltar
            </button>
            <span className="rpfood-login-status">{loading ? "Entrando..." : ""}</span>
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
            <span className="rpfood-auth-kicker">Administrativo</span>
            <h1 className="rpfood-auth-title">Entre com os dados de ADM</h1>
            <p className="rpfood-auth-subtitle">
              Acesso interno para acompanhar operacao, indicadores e gestao da loja sem alterar o fluxo publico do cliente.
            </p>
          </div>

          <section className="rpfood-auth-highlight rpfood-auth-highlight--cool">
            <span className="rpfood-auth-highlight__eyebrow">Acesso interno</span>
            <strong className="rpfood-auth-highlight__title">Login administrativo protegido</strong>
            <p className="rpfood-auth-highlight__text">
              Use suas credenciais de administracao para abrir o painel e continuar a operacao sem retrabalho.
            </p>
          </section>

          <form
            className="rpfood-auth-form"
            onSubmit={(event) => {
              event.preventDefault();
              onSubmit();
            }}
          >
            <div className="rpfood-form-grid">
              <div className="rpfood-form-field rpfood-form-field--full">
                <label htmlFor="admin-login">
                  Email <span className="text-danger">*</span>
                </label>
                <input
                  id="admin-login"
                  value={login}
                  onChange={(event) => onChangeLogin(event.target.value)}
                  autoComplete="username"
                  placeholder="Informe o login administrativo"
                />
              </div>

              <div className="rpfood-form-field rpfood-form-field--full">
                <label htmlFor="admin-password">
                  Senha <span className="text-danger">*</span>
                </label>
                <input
                  id="admin-password"
                  type="password"
                  value={password}
                  onChange={(event) => onChangePassword(event.target.value)}
                  autoComplete="current-password"
                  placeholder="Digite sua senha"
                />
              </div>
            </div>

            <div className="rpfood-auth-actions">
              <button type="submit" className="rpfood-primary-action" disabled={loading}>
                {loading ? "Entrando..." : "Entrar"}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
