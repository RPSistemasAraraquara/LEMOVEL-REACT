import type { Configuracao, Produto, ProdutoOpcional } from "./types";
import {
  maxExtraFractions,
  optionPriceBySize,
  sizeButtons,
} from "./pedidoItemRules";
import { SmartImage } from "./SmartImage";

export type PedidoItemDraft = {
  quantidade: number;
  tamanho: string;
  observacao: string;
  opcionais: Record<number, number>;
  fracoes: Record<number, number>;
};

type PedidoItemViewProps = {
  config: Configuracao | null;
  draft: PedidoItemDraft;
  fractionProducts: Produto[];
  loading: boolean;
  /** Total de partes permitido no item (sabor principal + extras), vindo da empresa. */
  maxFractionParts: number;
  onChangeFraction: (produto: Produto, delta: number) => void;
  onChangeObservation: (value: string) => void;
  onChangeOptional: (option: ProdutoOpcional, delta: number) => void;
  onChangeQuantity: (quantity: number) => void;
  onClose: () => void;
  onConfirm: () => void;
  onSelectSize: (size: string) => void;
  priceLabel: string;
  product: Produto;
  productOptions: ProdutoOpcional[];
};

function formatCurrency(value: number): string {
  return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(value);
}

function groupTotal(options: ProdutoOpcional[], quantities: Record<number, number>, groupId: number): number {
  return options
    .filter((item) => item.groupId === groupId)
    .reduce((sum, item) => sum + (quantities[item.codigoOpcional] ?? 0), 0);
}

function orderedOptions(options: ProdutoOpcional[]): ProdutoOpcional[] {
  return options;
}

export function PedidoItemView({
  config,
  draft,
  fractionProducts,
  loading,
  maxFractionParts,
  onChangeFraction,
  onChangeObservation,
  onChangeOptional,
  onChangeQuantity,
  onClose,
  onConfirm,
  onSelectSize,
  priceLabel,
  product,
  productOptions,
}: PedidoItemViewProps) {
  void config;
  const buttons = sizeButtons(product);
  const hasProductImage = Boolean(product.imageUrl);
  const renderedGroups = new Set<number>();
  const sortedOptions = orderedOptions(productOptions);
  const firstUngroupedOptionCode = sortedOptions.find((item) => item.groupId <= 0)?.codigoOpcional ?? 0;
  // O proprio produto aberto ja ocupa uma das partes, entao a lista abaixo so
  // oferece o que sobra. Anunciar o total cru confundia: dizia 4 e deixava marcar 3.
  // O botao de adicionar continua clicavel no limite de proposito: quem trata o
  // estouro e o onChangeFraction, que explica ao cliente por que nao cabe mais.
  const extraFlavorsAllowed = maxExtraFractions(maxFractionParts);

  return (
    <div className="row rpfood-item-screen">
      <div className="col-lg-12">
        <div className="row page-titles rpfood-item-page-title">
          <h4 className="active">{product.descricao}</h4>
        </div>

        <div id="tab-control">
          <div className="pt-4">
            <div className="card rpfood-item-shell">
              <div className="card-body rpfood-item-shell__body" id="divItemPedido">
                <div className="row rpfood-item-detail-row">
                  <div className="col-12 col-xl-3 col-lg-6 col-md-6 col-xxl-5">
                    <div className="tab-content" id="nav-tabContent">
                      <div
                        className="tab-pane fade show active"
                        id="nav-first"
                        role="tabpanel"
                        aria-labelledby="nav-first-tab"
                      >
                        <div className={hasProductImage ? "rpfood-item-image-box" : "rpfood-item-image-box rpfood-item-image-box--empty"}>
                          {hasProductImage ? (
                            <SmartImage
                              src={product.imageUrl}
                              placeholderSrc={product.thumbnailUrl ?? product.imageUrl}
                              alt={product.descricao}
                              wrapperClassName="rpfood-item-image-box__smart-image"
                              loading="eager"
                            />
                          ) : (
                            <div className="rpfood-item-image-placeholder">
                              <i className="la la-cutlery" aria-hidden="true" />
                              <span>Imagem do produto</span>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="col-12 col-xl-9 col-lg-6 col-md-6 col-xxl-7 col-sm-12">
                    <div className="product-detail-content rpfood-item-detail-content">
                      <div className="new-arrival-content pr rpfood-item-summary-card">
                        <h4>{product.descricao}</h4>
                        <div className="mb-2 rpfood-item-price-wrap" id="divPreco">
                          <p className="price rpfood-item-price">{priceLabel}</p>
                        </div>
                        <p className="text-content rpfood-item-description">{product.observacao}</p>
                        <div className="new" />

                        {product.vendaPorTamanho ? (
                          <div className="divTamanhos rpfood-item-size-panel" id="divTamanhos">
                            <div className="d-flex align-items-end flex-wrap">
                              <div className="filtaring-area me-auto">
                                <div className="size-filter flex-wrap">
                                  <p className="mb-0 subtitle">{product.tamanhoPadrao || "Tamanho"}</p>
                                </div>
                                <div id="divListaTamanhos" className="rpfood-item-size-grid" style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
                                  {buttons.map((button) => (
                                    <div key={button.code}>
                                      <input
                                        type="radio"
                                        className="btn-check"
                                        name="btnradio"
                                        id={`btnradio_tamanho_${button.label}`}
                                        checked={draft.tamanho === button.label}
                                        onChange={() => onSelectSize(button.label)}
                                      />
                                      <label
                                        className="btn btn-outline-primary sharp align-self-stretch rpfood-item-size-button"
                                        style={{
                                          padding: "10px 16px",
                                          minHeight: 56,
                                          display: "inline-flex",
                                          flexDirection: "column",
                                          justifyContent: "center",
                                          alignItems: "center",
                                        }}
                                        htmlFor={`btnradio_tamanho_${button.label}`}
                                      >
                                        <span style={{ display: "block", lineHeight: 1.1 }}>{button.label}</span>
                                        <span style={{ display: "block", lineHeight: 1.1, fontSize: "0.85em", opacity: 0.9 }}>
                                          {formatCurrency(button.value)}
                                        </span>
                                      </label>
                                    </div>
                                  ))}
                                </div>
                              </div>
                            </div>
                          </div>
                        ) : null}
                      </div>

                      <div className="mb-2 me-3 rpfood-item-form-area">
                        <div className="col-4 px-0 mb-2 me-3 rpfood-item-quantity-field rpfood-item-field">
                          <label htmlFor="IWEDT_QUANTIDADE_ITEM" title="Quantidade">
                            Quantidade
                          </label>
                          <div className="quntity rpfood-item-counter" style={{ display: "inline-flex", alignItems: "center" }}>
                            <button
                              type="button"
                              data-decrease
                              onClick={() => onChangeQuantity(Math.max(1, draft.quantidade - 1))}
                              aria-label="Diminuir quantidade"
                            >
                              -
                            </button>
                            <input
                              id="IWEDT_QUANTIDADE_ITEM"
                              data-value
                              type="text"
                              value={draft.quantidade}
                              readOnly
                              aria-readonly="true"
                            />
                            <button
                              type="button"
                              data-increase
                              onClick={() => onChangeQuantity(draft.quantidade + 1)}
                              aria-label="Aumentar quantidade"
                            >
                              +
                            </button>
                          </div>
                        </div>

                        <div className="mb-2 me-3 rpfood-item-observation-field rpfood-item-field">
                          <label htmlFor="IWEDTOBSERVACAO">Observação</label>
                          <input
                            id="IWEDTOBSERVACAO"
                            className="form-control input-btn"
                            type="text"
                            placeholder="Alguma Observação?"
                            maxLength={100}
                            value={draft.observacao}
                            onChange={(event) => onChangeObservation(event.target.value)}
                          />
                        </div>
                      </div>

                      <div className="shopping-cart" id="barraAcaoItemPedido">
                        <button className="btn btn-danger" type="button" style={{ flex: 1, minWidth: 0 }} onClick={onClose}>
                          <i className="fa fa-cancel me-2" />
                          Não quero ++
                        </button>
                        <button className="btn btn-primary" type="button" style={{ flex: 1, minWidth: 0 }} onClick={onConfirm} disabled={loading}>
                          <i className="fa fa-shopping-basket me-2" />
                          É isso aiiii
                        </button>
                      </div>
                      <div className="shopping-cart" style={{ marginTop: 10 }} />
                    </div>
                  </div>
                </div>
              </div>

              {fractionProducts.length > 0 ? (
                <div id="div_secao_fracoes" className="rpfood-item-section">
                  <div
                    className="rpfood-item-section-header rpfood-item-section-header--dark"
                    style={{
                      background: "linear-gradient(90deg,#1a3a5c 0%,#1b4f72 60%,#2e86c1 100%)",
                      color: "#fff",
                      padding: "12px 18px",
                      borderRadius: 8,
                      margin: "18px 0 6px 0",
                      display: "flex",
                      alignItems: "center",
                    }}
                  >
                    <i className="la la-utensils me-2" style={{ fontSize: "1.2em" }} />
                    <span style={{ fontWeight: 700, fontSize: "1.10em", letterSpacing: "0.5px" }}>
                      Este item ja conta como 1 sabor. Escolha ate mais {extraFlavorsAllowed}.
                    </span>
                  </div>
                  <div className="card-body" id="divFracao">
                    <div className="pt-2" id="div_lista_fracoes_inner">
                      <div className="row">
                        <div className="basic-list-group">
                          <ul className="list-group rpfood-item-choice-list" id="lista_fracoes">
                            {fractionProducts.map((fractionProduct) => {
                              const quantity = draft.fracoes[fractionProduct.codigo] ?? 0;
                              return (
                                <li key={fractionProduct.codigo} className="list-group-item rpfood-item-choice-card">
                                  <ul>
                                    <div>
                                      <div className="new-arrival-content pr">
                                        <div>
                                          <label className="form-check-label text-wrap">{fractionProduct.descricao}</label>
                                        </div>
                                      </div>
                                    </div>
                                    <div className="d-flex align-items-center justify-content-between">
                                      <div className="bootstrap-badge">
                                        <span className="badge badge-lg light badge-primary">
                                          {formatCurrency(fractionProduct.valFinal)}
                                        </span>
                                        <br />
                                      </div>
                                      <div className="quntity align-items-xxl-end rpfood-item-counter">
                                        <button type="button" data-decrease onClick={() => onChangeFraction(fractionProduct, -1)}>
                                          -
                                        </button>
                                        <input data-value type="text" value={quantity} readOnly id={`fracao_${fractionProduct.codigo}`} />
                                        <button
                                          type="button"
                                          data-increase
                                          disabled={quantity >= 1}
                                          onClick={() => onChangeFraction(fractionProduct, 1)}
                                        >
                                          +
                                        </button>
                                      </div>
                                    </div>
                                  </ul>
                                </li>
                              );
                            })}
                          </ul>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              ) : null}

              {sortedOptions.length > 0 ? (
                <div id="div_secao_opcionais" className="rpfood-item-section">
                  <div id="div_lista_opcionais">
                    {sortedOptions.map((option) => {
                      const quantity = draft.opcionais[option.codigoOpcional] ?? 0;
                      const totalInGroup = option.groupId > 0 ? groupTotal(sortedOptions, draft.opcionais, option.groupId) : 0;
                      const showGroupHeader = option.groupId > 0 && !renderedGroups.has(option.groupId);
                      const showUngroupedHeader = option.groupId <= 0 && option.codigoOpcional === firstUngroupedOptionCode;

                      if (option.groupId > 0) {
                        renderedGroups.add(option.groupId);
                      }

                      return (
                        <div key={option.codigoOpcional}>
                          {showGroupHeader ? (
                            <div
                              className="rpfood-item-section-header rpfood-item-section-header--dark rpfood-item-section-header--spaced"
                              style={{
                                background: "linear-gradient(90deg,#1a3a5c 0%,#1b4f72 60%,#2e86c1 100%)",
                                color: "#fff",
                                padding: "10px 18px",
                                borderRadius: 8,
                                margin: "18px 0 6px 0",
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "space-between",
                              }}
                            >
                              <span style={{ fontWeight: 700, fontSize: "1.08em", letterSpacing: "0.5px" }}>
                                {option.groupDescription}
                              </span>
                              <span>
                                {option.opcionalMaximo > 0 ? (
                                  <span
                                    style={{ fontSize: "0.95em", fontWeight: 700, marginRight: 8 }}
                                    id={`guarnicao_counter_${option.groupId}`}
                                  >
                                    {totalInGroup}/{option.opcionalMaximo}
                                  </span>
                                ) : null}
                                {option.opcionalMinimo > 0 ? (
                                  <>
                                    <span
                                      className="badge"
                                      style={{
                                        background: "#c0392b",
                                        color: "#fff",
                                        fontSize: "0.85em",
                                        padding: "3px 10px",
                                        borderRadius: 8,
                                      }}
                                    >
                                      obrigatório mín. {option.opcionalMinimo}
                                    </span>
                                    <span
                                      className="badge"
                                      id={`guarnicao_min_restante_${option.groupId}`}
                                      style={{
                                        background: totalInGroup >= option.opcionalMinimo ? "#239b56" : "#e67e22",
                                        color: "#fff",
                                        fontSize: "0.85em",
                                        padding: "3px 10px",
                                        borderRadius: 8,
                                        marginLeft: 6,
                                      }}
                                    >
                                      {totalInGroup >= option.opcionalMinimo
                                        ? "mínimo atingido"
                                        : `faltam ${option.opcionalMinimo - totalInGroup}`}
                                    </span>
                                  </>
                                ) : null}
                              </span>
                            </div>
                          ) : null}

                          {showUngroupedHeader ? (
                            <div
                              className="rpfood-item-section-header rpfood-item-section-header--blue rpfood-item-section-header--spaced"
                              style={{
                                background: "linear-gradient(90deg,#2980b9 0%,#3498db 60%,#5dade2 100%)",
                                color: "#fff",
                                padding: "12px 18px",
                                borderRadius: 8,
                                margin: "18px 0 6px 0",
                                display: "flex",
                                alignItems: "center",
                              }}
                            >
                              <i className="la la-list me-2" style={{ fontSize: "1.2em" }} />
                              <span style={{ fontWeight: 700, fontSize: "1.10em", letterSpacing: "0.5px" }}>
                                Opcionais
                              </span>
                            </div>
                          ) : null}

                          <li className="list-group-item rpfood-item-choice-card">
                            <ul>
                              <div>
                                <div className="new-arrival-content pr">
                                  <div>
                                    <label className="form-check-label text-wrap">{option.opcional.descricao}</label>
                                  </div>
                                </div>
                              </div>
                              <div className="d-flex align-items-center justify-content-between">
                                <div className="bootstrap-badge">
                                  <span className="badge badge-lg light badge-primary">
                                    {formatCurrency(optionPriceBySize(option.opcional, draft.tamanho))}
                                  </span>
                                  <br />
                                </div>
                                <div className="quntity align-items-xxl-end rpfood-item-counter">
                                  <button type="button" data-decrease onClick={() => onChangeOptional(option, -1)}>
                                    -
                                  </button>
                                  <input data-value type="text" value={quantity} readOnly id={`opcional_${option.codigoOpcional}`} />
                                  <button type="button" data-increase onClick={() => onChangeOptional(option, 1)}>
                                    +
                                  </button>
                                </div>
                              </div>
                            </ul>
                          </li>
                        </div>
                      );
                    })}
                  </div>
                </div>
              ) : null}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
