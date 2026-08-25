import { ProdutoListaView, type ProdutoListaViewProps } from "./ProdutoListaView";

type Props = Omit<ProdutoListaViewProps, "mode">;

export function ProdutosPorCategoriaView(props: Props) {
  return <ProdutoListaView {...props} mode="category" />;
}
