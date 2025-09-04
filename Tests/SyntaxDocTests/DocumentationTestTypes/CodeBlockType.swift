import Foundation

internal enum CodeBlockType {
  case example
  @available(*, unavailable)
  case packageManifest
  case shellCommand
}
