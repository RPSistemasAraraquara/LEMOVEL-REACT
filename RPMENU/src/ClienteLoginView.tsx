type Props = {
  error: string;
  loading: boolean;
  message: string;
  phone: string;
  onBack: () => void;
  onChangePhone: (value: string) => void;
  onOpenForgotPassword: () => void;
  onOpenRegister: () => void;
  onSubmit: () => void;
};

export function ClienteLoginView({
  error,
  loading,
  message,
  phone,
  onBack,
  onChangePhone,
  onOpenForgotPassword,
  onOpenRegister,
  onSubmit,
}: Props) {
  const phoneDigits = phone.replace(/\D/g, "");
  const helperText =
    phoneDigits.length === 0
      ? "Digite apenas os numeros do celular com DDD."
      : `${phoneDigits.length}/11 digitos informados para localizar seu cadastro mais rapido.`;

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
            <span className="rpfood-auth-kicker">Acesso do cliente</span>
            <h1 className="rpfood-auth-title">Bora colocar seus dados</h1>
          </div>

          <section className="rpfood-login-callout" aria-label="Orientacao para login">
            <span className="rpfood-login-callout__eyebrow">Acesso rapido</span>
            <strong className="rpfood-login-callout__title">Seu telefone vira sua chave de entrada</strong>
            <p className="rpfood-login-callout__text">
              Use o numero com DDD para puxar cadastro, enderecos e historico sem precisar preencher tudo de novo.
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
              <label htmlFor="login-phone">
                Telefone (DDD + Numero) <span className="text-danger">*</span>
              </label>
              <div className="rpfood-login-phone-field">
                <span className="rpfood-login-phone-field__prefix">+55</span>
                <input
                  id="login-phone"
                  value={phone}
                  onChange={(event) => onChangePhone(event.target.value.replace(/\D/g, "").slice(0, 11))}
                  type="tel"
                  inputMode="numeric"
                  autoComplete="tel-national"
                  maxLength={11}
                  placeholder="11999999999"
                  className="rpfood-login-phone-field__input"
                />
              </div>
              <p className="rpfood-login-phone-field__hint">{helperText}</p>
            </div>

            <div className="rpfood-auth-actions">
              <button type="submit" className="rpfood-primary-action" disabled={loading}>
                {loading ? "Entrando..." : "Chega ai"}
              </button>
            </div>
          </form>

          <div className="rpfood-login-actions">
            <button type="button" className="rpfood-secondary-action" onClick={onOpenForgotPassword} disabled={loading}>
              Esqueci minha Senha
            </button>
            <button type="button" className="rpfood-secondary-action" onClick={onOpenRegister} disabled={loading}>
              Bora Cadastrar
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
