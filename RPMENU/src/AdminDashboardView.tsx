type TopItem = {
  label: string;
  value: string;
};

type Props = {
  bairros: TopItem[];
  clientes: TopItem[];
  onLogout: () => void;
  produtos: TopItem[];
  qtdeVendas: string;
  sincronizacao: string;
  taxaEntrega: string;
  valorVendas: string;
};

function renderTopList(title: string, items: TopItem[], titleClass: string) {
  return (
    <div className="col-xl-6 col-lg-12 col-xxl-6 col-sm-12">
      <div className="card text-center">
        <ul className="list-group list-group-flush">
          <h4 className={`card-title text-center ${titleClass}`}>{title}</h4>
          {items.map((item) => (
            <li key={`${title}-${item.label}`} className="list-group-item d-flex justify-content-between">
              <span className="mb-0">{item.label}</span>
              <strong>{item.value}</strong>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}

export function AdminDashboardView({
  bairros,
  clientes,
  onLogout,
  produtos,
  qtdeVendas,
  sincronizacao,
  taxaEntrega,
  valorVendas,
}: Props) {
  return (
    <div id="main-wrapper" className="show dlab-overflow">
      <div className="content-body" style={{ paddingBottom: 30, marginLeft: 0, paddingTop: 12, marginTop: 0 }}>
        <div className="container-fluid">
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
            <h3 style={{ margin: 0, color: "#1B4F72", fontWeight: 800 }}>Administrativo</h3>
            <button type="button" className="btn btn-outline-primary" onClick={onLogout}>
              Sair
            </button>
          </div>

          <div className="row">
            <div className="col-xl-3 col-xxl-6 col-lg-6 col-sm-6">
              <div className="widget-stat card bg-warning">
                <div className="card-body p-4">
                  <div className="media">
                    <span className="me-3">
                      <i className="la la-user" />
                    </span>
                    <div className="media-body text-white">
                      <p className="mb-1">Última sincronização</p>
                      <h3 className="text-white">{sincronizacao}</h3>
                      <div className="progress mb-2 bg-primary">
                        <div className="progress-bar progress-animated bg-white" style={{ width: "50%" }} />
                      </div>
                      <small>Sincronização efetuado com sucesso</small>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="col-xl-3 col-xxl-6 col-lg-6 col-sm-6">
              <div className="widget-stat card bg-primary">
                <div className="card-body p-4">
                  <div className="media">
                    <span className="me-3">
                      <i className="la la-motorcycle" style={{ fontSize: 32, color: "#FC8019" }} />
                    </span>
                    <div className="media-body text-white">
                      <p className="mb-1">Valor Taxa de entrega</p>
                      <h3 className="text-white">{taxaEntrega}</h3>
                      <div className="progress mb-2 bg-success">
                        <div className="progress-bar progress-animated bg-info" style={{ width: "99%" }} />
                      </div>
                      <small>Informação diária</small>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="col-xl-3 col-xxl-6 col-lg-6 col-sm-6">
              <div className="widget-stat card bg-secondary overflow-hidden">
                <div className="card-body p-4">
                  <div className="media">
                    <span className="me-3">
                      <i className="la la-shopping-cart" style={{ fontSize: 32, color: "#EB5757" }} />
                    </span>
                    <div className="media-body text-white">
                      <p className="mb-1">Qtde Vendas</p>
                      <h3 className="text-white">{qtdeVendas}</h3>
                      <div className="progress mb-2 bg-success">
                        <div className="progress-bar progress-animated bg-white" style={{ width: "76%" }} />
                      </div>
                      <small>Informação diária</small>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="col-xl-3 col-xxl-6 col-lg-6 col-sm-6">
              <div className="widget-stat card bg-danger">
                <div className="card-body p-4">
                  <div className="media">
                    <span className="me-3">
                      <i className="la la-dollar" />
                    </span>
                    <div className="media-body text-white">
                      <p className="mb-1">Valor Vendas</p>
                      <h3 className="text-white">{valorVendas}</h3>
                      <div className="progress mb-2 bg-verde">
                        <div className="progress-bar progress-animated bg-verde" style={{ width: "88%" }} />
                      </div>
                      <small>Informação diária</small>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {renderTopList("Top 10 clientes", clientes, "text-danger")}
            {renderTopList("Top 10 Bairros", bairros, "text-success")}

            <div className="col-xl-12 col-xxl-12 col-lg-12">
              <div className="card">
                <div className="card-body">
                  <h4 className="card-title text-center">Top 10 produtos<br /><br /></h4>
                  <div className="row">
                    <div className="col-12">
                      {produtos.map((item, index) => (
                        <div key={`produto-${item.label}`} style={{ marginBottom: 24 }}>
                          <div className="d-flex justify-content-between">
                            <h6>{item.label}</h6>
                            <span>{item.value}</span>
                          </div>
                          <div className="progress">
                            <div
                              className={`progress-bar ${
                                index === 0
                                  ? "bg-primary"
                                  : index === 1
                                    ? "bg-info"
                                    : index === 2
                                      ? "bg-roxo-light"
                                      : index === 3
                                        ? "bg-success"
                                        : index === 4
                                          ? "bg-warning"
                                          : index === 5
                                            ? "bg-gradient"
                                            : index === 6
                                              ? "bg-verde"
                                              : index === 7
                                                ? "bg-danger"
                                                : "bg-warning"
                              }`}
                              style={{ width: `${Math.max(35, 95 - index * 7)}%` }}
                            />
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
