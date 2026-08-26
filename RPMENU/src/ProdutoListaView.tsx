import { memo, useCallback, useEffect, useRef, useState } from "react";
import type { MouseEvent as ReactMouseEvent, PointerEvent as ReactPointerEvent } from "react";
import type { Categoria, Produto } from "./types";
import { clickableCardProps } from "./clickableCard";
import { RailSlider } from "./RailSlider";
import {
  createHorizontalDragState,
  finishHorizontalDrag,
  shouldStartPointerDrag,
  resolveHorizontalDragIntent,
  type HorizontalDragState,
} from "./createHorizontalDragScrollHandlers";
import { SmartImage } from "./SmartImage";
import { getProgressiveImageProps } from "./imageLoading";

export type ProdutoListaViewProps = {
  cartQuantityByProduct: Record<number, number>;
  categories: Categoria[];
  error: string;
  filter: string;
  loading: boolean;
  mode: "all" | "category";
  products: Produto[];
  selectedCategoryId: number | null;
  title: string;
  onBack: () => void;
  onChangeFilter: (value: string) => void;
  onSelectCategory: (categoryId: number) => void;
  onSelectProduct: (product: Produto) => void;
};

function formatCurrency(value: number): string {
  return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(value);
}

function truncateText(value: string, maxLength: number): string {
  const normalized = value.trim();
  if (!normalized) {
    return "";
  }

  return normalized.length <= maxLength ? normalized : `${normalized.slice(0, maxLength - 1).trimEnd()}...`;
}

type ProdutoCardProps = {
  columnClass: string;
  index: number;
  product: Produto;
  quantityInCart: number;
  onSelectProduct: (product: Produto) => void;
  onShowDetails: (text: string) => void;
};

/**
 * Card memoizado: a listagem chega a montar 200+ cards e, sem isso, cada tecla
 * digitada na busca reconstruia a lista inteira.
 */
const ProdutoCard = memo(function ProdutoCard({
  columnClass,
  index,
  product,
  quantityInCart,
  onSelectProduct,
  onShowDetails,
}: ProdutoCardProps) {
  void quantityInCart;

  return (
    <div className={columnClass}>
      <article className="rpfood-products-card" onClick={() => onSelectProduct(product)}>
        <div className="rpfood-products-card__media">
          {/* Etiquetas em linha propria acima da foto: sobrepostas elas cobriam a
              imagem, que agora e bem menor que o card. */}
          <div className="rpfood-products-card__badges">
            {product.vendaPorTamanho ? (
              <span className="rpfood-products-card__tag">Com tamanhos</span>
            ) : (
              <span className="rpfood-products-card__tag rpfood-products-card__tag--soft">Disponivel</span>
            )}
          </div>
          <div className="rpfood-products-card__media-frame">
            <SmartImage
              fluid
              src={product.thumbnailUrl ?? product.imageUrl}
              alt={product.descricao}
              width={180}
              height={170}
              {...getProgressiveImageProps(index, 4)}
            />
          </div>
        </div>
        <div className="rpfood-products-card__body">
          <div className="rpfood-products-card__title-row">
            <h3>{product.descricao}</h3>
          </div>
          {product.observacao.trim() ? (
            <>
              <p>{truncateText(product.observacao, 94)}</p>
              <button
                type="button"
                onClick={(event) => {
                  event.stopPropagation();
                  onShowDetails(product.observacao);
                }}
                className="rpfood-products-card__details"
              >
                Mais detalhes
              </button>
            </>
          ) : null}
        </div>
        <div className="rpfood-products-card__footer">
          <div className="rpfood-products-card__price">
            <span>A partir de</span>
            <strong>{formatCurrency(product.valFinal)}</strong>
          </div>
          {/* O card inteiro e clicavel, mas ele contem botoes: em vez de
              aninhar role="button" (invalido em ARIA), o teclado navega
              por este botao, que dispara a mesma acao. */}
          <button
            type="button"
            className="rpfood-products-card__cta"
            aria-label={`Abrir ${product.descricao}`}
            onClick={(event) => {
              event.stopPropagation();
              onSelectProduct(product);
            }}
          >
            <span aria-hidden="true">Ver</span>
          </button>
        </div>
      </article>
    </div>
  );
});

export function ProdutoListaView({
  cartQuantityByProduct,
  categories,
  error,
  filter,
  loading,
  mode,
  products,
  selectedCategoryId,
  title,
  onBack,
  onChangeFilter,
  onSelectCategory,
  onSelectProduct,
}: ProdutoListaViewProps) {
  const [modalText, setModalText] = useState("");

  // col-6 no celular: um card por linha ocupava a tela inteira.
  const columnClass = "col-6 col-md-4 col-xl-3 col-xxl-2";

  // O pai recria onSelectProduct a cada render; guardar em ref mantem a
  // identidade estavel para o memo do card valer alguma coisa.
  const selectProductRef = useRef(onSelectProduct);
  useEffect(() => {
    selectProductRef.current = onSelectProduct;
  }, [onSelectProduct]);
  const selectProduct = useCallback((product: Produto) => selectProductRef.current(product), []);
  const showDetails = useCallback((text: string) => setModalText(text), []);

  const categoriesRailRef = useRef<HTMLDivElement | null>(null);
  const categoriesRailDragState = useRef<HorizontalDragState>(createHorizontalDragState());
  const categoriesRailPointerDown = (event: ReactPointerEvent<HTMLDivElement>) => {
    if (!shouldStartPointerDrag(event.pointerType, event.button)) {
      return;
    }

    const el = categoriesRailRef.current ?? event.currentTarget;
    categoriesRailDragState.current.active = true;
    categoriesRailDragState.current.moved = false;
    categoriesRailDragState.current.pointerId = event.pointerId;
    categoriesRailDragState.current.startX = event.clientX;
    categoriesRailDragState.current.startY = event.clientY;
    categoriesRailDragState.current.startScrollLeft = el.scrollLeft;
  };

  const categoriesRailPointerMove = (event: ReactPointerEvent<HTMLDivElement>) => {
    const state = categoriesRailDragState.current;
    if (!state.active) {
      return;
    }

    const el = categoriesRailRef.current ?? event.currentTarget;
    const deltaX = event.clientX - state.startX;
    const deltaY = event.clientY - state.startY;

    // Mesma regra dos trilhos da home: so vira arrasto (e cancela o clique)
    // quando o movimento horizontal e intencional. Antes bastavam 4px, entao um
    // clique com leve tremor nao abria a categoria.
    if (!state.moved) {
      const intent = resolveHorizontalDragIntent(deltaX, deltaY);

      if (intent === "vertical") {
        state.active = false;
        state.pointerId = null;
        return;
      }

      if (intent === "none") {
        return;
      }

      if ("setPointerCapture" in el && state.pointerId !== null) {
        try {
          el.setPointerCapture(state.pointerId);
        } catch {
          // Ignore capture failures and keep the fallback drag working.
        }
      }

      state.moved = true;
    }

    el.scrollLeft = state.startScrollLeft - deltaX;
    event.preventDefault();
  };

  const categoriesRailPointerUp = (event: ReactPointerEvent<HTMLDivElement>) => {
    finishHorizontalDrag(categoriesRailRef.current ?? event.currentTarget, categoriesRailDragState.current);
  };

  const categoriesRailPointerCancel = (event: ReactPointerEvent<HTMLDivElement>) => {
    finishHorizontalDrag(categoriesRailRef.current ?? event.currentTarget, categoriesRailDragState.current);
  };

  const categoriesRailClickCapture = (event: ReactMouseEvent<HTMLDivElement>) => {
    if (Date.now() < categoriesRailDragState.current.suppressClicksUntil) {
      event.preventDefault();
      event.stopPropagation();
    }
  };
  const selectedCategory =
    selectedCategoryId !== null ? categories.find((category) => category.codigo === selectedCategoryId) ?? null : null;
  // Digitar na busca varre a loja inteira, entao o cabecalho nao pode continuar
  // anunciando a categoria selecionada enquanto mostra resultados de fora dela.
  const searchTerm = filter.trim();
  const searching = searchTerm.length > 0;
  const heroEyebrow = searching
    ? "Resultados da busca"
    : mode === "all"
      ? "Cardapio completo"
      : "Categoria em destaque";
  const heroTitle = searching ? `Resultados para "${searchTerm}"` : title;
  const heroDescription = searching
    ? "A busca percorre toda a loja, pelo nome do produto ou da categoria."
    : mode === "all"
      ? "Busque com rapidez, navegue pelas categorias e toque no produto para ver tudo com mais detalhe."
      : "Escolha um item dessa categoria e abra os detalhes para tamanhos, opcionais e observacoes.";

  return (
    <div id="main-wrapper" className="show dlab-overflow">
      {/* Espaco extra no rodape: a barra da sacola e a navegacao inferior sao fixas. */}
      <div
        className="content-body rpfood-products-page"
        style={{
          paddingBottom: "calc(var(--rpfood-bottom-nav-total-height) + 92px)",
          marginLeft: 0,
          paddingTop: 0,
          marginTop: 0,
        }}
      >
        <div className="container rpfood-products-page__container" style={{ maxWidth: "100%", paddingLeft: 12, paddingRight: 12, paddingTop: 14 }}>
          <section className="rpfood-products-hero">
            <div className="rpfood-products-hero__main">
              <div className="rpfood-products-toolbar">
                <button
                  type="button"
                  onClick={onBack}
                  className="rpfood-products-back"
                >
                  <span className="rpfood-products-back__icon" aria-hidden="true">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M15 18L9 12L15 6" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                  </span>
                  <span className="rpfood-products-back__label">Voltar</span>
                </button>

                <div className="rpfood-products-toolbar__copy">
                  <span className="rpfood-products-toolbar__eyebrow">{heroEyebrow}</span>
                </div>
              </div>

              <span className="rpfood-products-hero__eyebrow">{heroEyebrow}</span>
              <h1 className="rpfood-products-hero__title">{heroTitle}</h1>
              <p className="rpfood-products-hero__description">{heroDescription}</p>

              <div className="rpfood-products-hero__meta">
                <span className="rpfood-products-hero__meta-chip">
                  {products.length.toLocaleString("pt-BR")} itens
                </span>
                {selectedCategory && !searching ? (
                  <span className="rpfood-products-hero__meta-chip rpfood-products-hero__meta-chip--soft">
                    {selectedCategory.descricao}
                  </span>
                ) : null}
                <span className="rpfood-products-hero__meta-chip rpfood-products-hero__meta-chip--soft">
                  {searching
                    ? "Em toda a loja"
                    : mode === "all"
                      ? `${categories.length.toLocaleString("pt-BR")} categorias`
                      : "Toque para abrir o produto"}
                </span>
              </div>
            </div>

            <div className="rpfood-products-search-card">
              <div className="rpfood-products-search-card__label">Busca rapida</div>
              <div className="input-group search-area1 style-1 rpfood-products-search">
                <span className="input-group-text p-0">
                  <span aria-hidden="true">
                    <svg className="me-1" width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M27.414 24.586L22.337 19.509C23.386 17.928 24 16.035 24 14C24 8.486 19.514 4 14 4C8.486 4 4 8.486 4 14C4 19.514 8.486 24 14 24C16.035 24 17.928 23.386 19.509 22.337L24.586 27.414C25.366 28.195 26.634 28.195 27.414 27.414C28.195 26.633 28.195 25.367 27.414 24.586ZM7 14C7 10.14 10.14 7 14 7C17.86 7 21 10.14 21 14C21 17.86 17.86 21 14 21C10.14 21 7 17.86 7 14Z" fill="#FC8019" />
                    </svg>
                  </span>
                </span>
                <input
                  type="text"
                  className="form-control"
                  value={filter}
                  onChange={(event) => onChangeFilter(event.target.value)}
                  placeholder="Buscar por nome, sabor ou detalhe..."
                />
              </div>
              <div className="rpfood-products-search-card__hint">
                {searching
                  ? `Buscando "${searchTerm}" em toda a loja`
                  : "Digite para buscar em toda a loja, pelo nome do produto ou da categoria."}
              </div>
            </div>
          </section>

          {error ? (
            <div className="rpfood-products-alert" style={{ background: "#fff2f0", color: "#c0392b", borderRadius: 18, padding: "12px 14px", marginBottom: 16 }}>
              {error}
            </div>
          ) : null}

          {/* O trilho aparece tambem na tela de categoria: sem ele o cliente
              precisava voltar para a home so para trocar de categoria. */}
          {categories.length ? (
            <section className="rpfood-products-categories">
              <div className="col-xl-12 col-xxl-12 col-sm-12">
                <div className="rpfood-products-section-heading">
                  <div>
                    <span className="rpfood-products-section-heading__eyebrow">
                      {mode === "all" ? "Navegue melhor" : "Trocar de categoria"}
                    </span>
                    <h2 className="mb-0">Categorias</h2>
                  </div>
                  <span className="rpfood-products-section-heading__count">{categories.length.toLocaleString("pt-BR")} opcoes</span>
                </div>
                <RailSlider label="Categorias" railRef={categoriesRailRef}>
                  <div
                    ref={categoriesRailRef}
                    className="rpfood-scroll-row rpfood-products-categories__scroll"
                    style={{ padding: "0 clamp(20px, 3vw, 36px) 10px" }}
                    onPointerDown={categoriesRailPointerDown}
                    onPointerMove={categoriesRailPointerMove}
                    onPointerUp={categoriesRailPointerUp}
                    onPointerCancel={categoriesRailPointerCancel}
                    onClickCapture={categoriesRailClickCapture}
                  >
                  {categories.map((category, index) => (
                      <div
                        key={category.codigo}
                        className="rpfood-categoria-card"
                        style={{ cursor: "pointer" }}
                        {...clickableCardProps(
                          () => onSelectCategory(category.codigo),
                          `Abrir categoria ${category.descricao}`,
                        )}
                      >
                        <div className={selectedCategoryId === category.codigo ? "card dishe-bx exclusive rpfood-products-category-card is-active" : "card dishe-bx exclusive rpfood-products-category-card"}>
                          <div className="card-body p-0 text-center">
                            <SmartImage
                              fluid
                              src={category.thumbnailUrl ?? category.imageUrl}
                              alt={category.descricao}
                              width={132}
                              height={132}
                              {...getProgressiveImageProps(index, 2)}
                            />
                          </div>
                          <div className="rpfood-products-category-card__footer">
                            <span className="rpfood-products-category-card__title">{category.descricao}</span>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </RailSlider>
              </div>
            </section>
          ) : null}

          <section className="rpfood-products-grid-section">
            <div className="rpfood-products-section-heading rpfood-products-section-heading--compact">
              <div>
                <span className="rpfood-products-section-heading__eyebrow">Produtos</span>
                <h2 className="mb-0">{loading ? "Carregando vitrine" : "Escolha seu produto"}</h2>
              </div>
              <span className="rpfood-products-section-heading__count">{products.length.toLocaleString("pt-BR")} encontrados</span>
            </div>

            <div className="tab-content">
            <div className="tab-pane fade show active">
              <div className="row g-3" id="div_lista_produtos">
                {products.map((product, index) => (
                  <ProdutoCard
                    key={product.codigo}
                    columnClass={columnClass}
                    index={index}
                    product={product}
                    quantityInCart={cartQuantityByProduct[product.codigo] ?? 0}
                    onSelectProduct={selectProduct}
                    onShowDetails={showDetails}
                  />
                ))}

                {!products.length ? (
                  <div className="col-12">
                    <div className="rpfood-products-empty">
                      <div className="rpfood-products-empty__icon" aria-hidden="true">
                        <svg width="42" height="42" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M10.5 18a7.5 7.5 0 1 1 5.303-2.197L21 21" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
                        </svg>
                      </div>
                      <h3>{loading ? "Carregando produtos..." : "Nenhum produto encontrado"}</h3>
                      <p>
                        {loading
                          ? "A vitrine dessa tela esta sendo atualizada."
                          : searching
                            ? `Nada em toda a loja para "${searchTerm}". Confira a grafia ou tente um termo mais curto.`
                            : "Tente outro termo de busca ou volte para escolher uma categoria diferente."}
                      </p>
                    </div>
                  </div>
                ) : null}
              </div>
            </div>
            </div>
          </section>
        </div>
      </div>

      {modalText ? (
        <div className="modal fade show" style={{ display: "block", background: "rgba(10, 17, 32, 0.58)" }}>
          <div className="modal-dialog modal-dialog-centered" role="document">
            <div className="modal-content rpfood-products-modal">
              <div className="modal-header rpfood-products-modal__header">
                <h5 className="modal-title">Detalhes do produto</h5>
                <button type="button" className="btn-close" onClick={() => setModalText("")} />
              </div>
              <div className="modal-body rpfood-products-modal__body">
                <p>{modalText}</p>
              </div>
              <div className="modal-footer rpfood-products-modal__footer">
                <button type="button" className="btn btn-primary btn-sm rpfood-products-modal__button" onClick={() => setModalText("")}>
                  Fechar
                </button>
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
