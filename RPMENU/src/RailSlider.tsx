import { useCallback, useEffect, useState } from "react";
import type { ReactNode, RefObject } from "react";

type RailSliderProps = {
  children: ReactNode;
  label: string;
  railRef: RefObject<HTMLDivElement | null>;
};

/**
 * Setas de navegacao para os trilhos horizontais (destaques e categorias).
 *
 * O arrasto com o dedo/mouse continua funcionando; as setas so aparecem quando
 * existe conteudo fora da tela e somem nas pontas, para nao sugerir uma rolagem
 * que nao existe. Em telas de toque elas ficam ocultas via CSS.
 */
export function RailSlider({ children, label, railRef }: RailSliderProps) {
  const [canScrollPrev, setCanScrollPrev] = useState(false);
  const [canScrollNext, setCanScrollNext] = useState(false);

  useEffect(() => {
    const rail = railRef.current;
    if (!rail) {
      return;
    }

    const update = () => {
      const maxScroll = rail.scrollWidth - rail.clientWidth;
      setCanScrollPrev(rail.scrollLeft > 4);
      setCanScrollNext(rail.scrollLeft < maxScroll - 4);
    };

    update();
    rail.addEventListener("scroll", update, { passive: true });

    const observer = new ResizeObserver(update);
    observer.observe(rail);
    for (const child of Array.from(rail.children)) {
      observer.observe(child);
    }

    return () => {
      rail.removeEventListener("scroll", update);
      observer.disconnect();
    };
  }, [railRef, children]);

  const scrollByPage = useCallback(
    (direction: 1 | -1) => {
      const rail = railRef.current;
      if (!rail) {
        return;
      }

      // Rola quase uma tela cheia, deixando um card de referencia visivel.
      const step = Math.max(160, rail.clientWidth * 0.8);
      rail.scrollBy({ left: step * direction, behavior: "smooth" });
    },
    [railRef],
  );

  const hasOverflow = canScrollPrev || canScrollNext;

  return (
    <div className="rpfood-rail-slider">
      {children}

      {hasOverflow ? (
        <>
          <button
            type="button"
            className="rpfood-rail-slider__arrow rpfood-rail-slider__arrow--prev"
            aria-label={`Voltar em ${label}`}
            disabled={!canScrollPrev}
            onClick={() => scrollByPage(-1)}
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <polyline points="15 18 9 12 15 6" />
            </svg>
          </button>

          <button
            type="button"
            className="rpfood-rail-slider__arrow rpfood-rail-slider__arrow--next"
            aria-label={`Avancar em ${label}`}
            disabled={!canScrollNext}
            onClick={() => scrollByPage(1)}
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </button>
        </>
      ) : null}
    </div>
  );
}
