import Apollo

/// Responsible for queuing and batch fetching GraphQL queries.
protocol BatchPoller {
  /// Queues a GraphQL operation for batch fetching. The operation will be fetched
  /// when the underlying implementation's scheduler triggers a batch.
  /// - Parameters:
  ///   - request: The `HTTPRequest` for a GraphQL operation to batch.
  ///   - completion: The closure to execute when the batched response is unpacked.
  func enqueue<Operation: GraphQLOperation>(request: HTTPRequest<Operation>,
               completion: @escaping Completion)
  
  /// Start the poller - must be invoked before enqueueing.
  func start()
  
  /// Stop the poller and cancel in flight operations.
  func stop()
}

/// `BatchPoller` related error.
public enum PollerError: Error {
  case pollerNotStarted
}
