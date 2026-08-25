import { ProdutoListaView, type ProdutoListaViewProps } from "./ProdutoListaView";

type Props = Omit<ProdutoListaViewProps, "mode">;

export function ProdutosTodasCategoriasView(props: Props) {
  return <ProdutoListaView {...props} mode="all" />;
}
