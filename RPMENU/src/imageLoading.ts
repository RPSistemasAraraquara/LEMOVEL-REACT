export type ProgressiveImageProps = {
  loading: "eager" | "lazy";
  decoding: "async";
  fetchPriority: "high" | "low";
};

export function getProgressiveImageProps(index: number, eagerCount = 1): ProgressiveImageProps {
  const shouldPrioritize = index < eagerCount;

  return {
    loading: shouldPrioritize ? "eager" : "lazy",
    decoding: "async",
    fetchPriority: shouldPrioritize ? "high" : "low",
  };
}
