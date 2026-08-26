import { useState } from "react";
import type { CSSProperties, ImgHTMLAttributes } from "react";

type SmartImageProps = Omit<ImgHTMLAttributes<HTMLImageElement>, "src" | "alt" | "width" | "height"> & {
  alt: string;
  /**
   * Deixa o tamanho a cargo do CSS do card, mantendo apenas a proporcao
   * (evita CLS). Sem isso a largura/altura viram estilo inline e nenhuma
   * media query consegue reduzir a imagem junto com o card.
   */
  fluid?: boolean;
  height?: number;
  placeholderSrc?: string;
  imageClassName?: string;
  imageStyle?: CSSProperties;
  src: string;
  width?: number;
  wrapperClassName?: string;
};

export function SmartImage(props: SmartImageProps) {
  const imageKey = `${props.src}::${props.placeholderSrc ?? ""}`;
  return <SmartImageContent key={imageKey} {...props} />;
}

function SmartImageContent({
  alt,
  fluid = false,
  height,
  imageClassName,
  imageStyle,
  loading = "lazy",
  placeholderSrc,
  src,
  width,
  wrapperClassName,
  ...imgProps
}: SmartImageProps) {
  const [isLoaded, setIsLoaded] = useState(false);
  const [hasError, setHasError] = useState(false);
  const hasSrc = src.trim().length > 0;

  const wrapperStyle: CSSProperties = fluid
    ? { aspectRatio: width && height ? `${width} / ${height}` : undefined }
    : {
        width: width ? `${width}px` : undefined,
        height: height ? `${height}px` : undefined,
      };

  return (
    <span
      className={`rpfood-smart-image ${fluid ? "rpfood-smart-image--fluid" : ""} ${wrapperClassName ?? ""}`.trim()}
      style={wrapperStyle}
    >
      {placeholderSrc && hasSrc && !hasError ? (
        <img
          src={placeholderSrc}
          alt=""
          aria-hidden="true"
          className={`rpfood-smart-image__placeholder-img ${isLoaded ? "is-hidden" : ""}`.trim()}
          loading="eager"
          decoding="async"
          draggable={false}
        />
      ) : (
        <span
          aria-hidden="true"
          className={`rpfood-smart-image__placeholder ${isLoaded || hasError ? "is-hidden" : ""}`.trim()}
        />
      )}

      {hasSrc && !hasError ? (
        <img
          {...imgProps}
          src={src}
          alt={alt}
          loading={loading}
          decoding="async"
          className={`rpfood-smart-image__img ${imageClassName ?? ""} ${isLoaded ? "is-loaded" : ""}`.trim()}
          style={imageStyle}
          onLoad={() => setIsLoaded(true)}
          onError={() => setHasError(true)}
          draggable={false}
        />
      ) : (
        <span aria-hidden="true" className="rpfood-smart-image__error">
          Imagem indisponivel
        </span>
      )}
    </span>
  );
}
