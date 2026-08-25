type Props = {
  message?: string;
  onBack: () => void;
};

export function Erro404View({ message, onBack }: Props) {
  return (
    <div className="vh-100">
      <div className="authincation">
        <div className="container">
          <div className="row justify-content-center h-100 align-items-center">
            <div className="col-md-7">
              <div className="form-input-content text-center error-page">
                <h1 className="error-text fw-bold">404</h1>
                <h4>
                  <i className="fa fa-exclamation-triangle text-warning" /> A pagina que voce estava procurando nao foi
                  encontrada!
                </h4>
                <p>{message || "Voce pode ter digitado errado o endereco ou a pagina pode ter sido movida."}</p>
                <div>
                  <button type="button" className="btn btn-primary" onClick={onBack}>
                    Voltar
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
