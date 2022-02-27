import Foundation

/// Configuration for batch fetching behavior.
struct BatchConfig {
  
  /// Interval in millseconds for flushing batched GraphQL operations.
  var interval: TimeInterval
}
