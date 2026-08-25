type Props = {
  onBack: () => void;
};

export function AdminIndex2View({ onBack }: Props) {
  return (
    <div id="main-wrapper" className="show dlab-overflow">
      <div className="content-body" style={{ paddingBottom: 30, marginLeft: 0, paddingTop: 12, marginTop: 0 }}>
        <div className="container-fluid">
          <div className="row page-titles">
            <h4 className="active" style={{ textAlign: "center" }}>
              Finalizar Pedido
            </h4>
          </div>

          <div className="card">
            <div className="card-body text-center" style={{ padding: 40 }}>
              <h4 style={{ color: "#1B4F72", fontWeight: 800, marginBottom: 16 }}>ADMIN Index2</h4>
              <p style={{ color: "#617085", maxWidth: 620, margin: "0 auto 18px" }}>
                Essa tela também está incompleta no próprio legado. Eu mantive a rota renderizando no React para não
                existir mais buraco de navegação, mas sem inventar regra que o sistema antigo não tinha.
              </p>
              <button type="button" className="btn btn-primary" onClick={onBack}>
                Voltar para o Admin
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
