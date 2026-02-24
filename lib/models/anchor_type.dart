/// Defines where a stroke/block is anchored.
enum AnchorType {
  /// Freeform content anchored directly in the infinite canvas world.
  canvas,

  /// Content anchored to a concrete PDF page using normalized coordinates.
  pdfPage,
}

