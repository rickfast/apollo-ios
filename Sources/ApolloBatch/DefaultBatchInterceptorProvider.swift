import Foundation

import Apollo

/// The default interceptor provider for batching Apollo client
class DefaultBatchInterceptorProvider: InterceptorProvider {
  let store: ApolloStore
  let shouldInvalidateClientOnDeinit: Bool
  let client: URLSessionClient
  let batchConfig: BatchConfig
  
  /// Designated initializer
  ///
  /// - Parameters:
  ///   - client: The `URLSessionClient` to use. Defaults to the default setup.
  ///   - shouldInvalidateClientOnDeinit: If the passed-in client should be invalidated when this interceptor provider is deinitialized. If you are recreating the `URLSessionClient` every time you create a new provider, you should do this to prevent memory leaks. Defaults to true, since by default we provide a `URLSessionClient` to new instances.
  ///   - store: The `ApolloStore` to use when reading from or writing to the cache. Make sure you pass the same store to the `ApolloClient` instance you're planning to use.
  init(store: ApolloStore, shouldInvalidateClientOnDeinit: Bool = true, client: URLSessionClient, batchConfig: BatchConfig = BatchConfig(interval: 2.0)) {
    self.store = store
    self.shouldInvalidateClientOnDeinit = shouldInvalidateClientOnDeinit
    self.client = client
    self.batchConfig = batchConfig
  }
  
  func interceptors<Operation>(for operation: Operation) -> [ApolloInterceptor] where Operation : GraphQLOperation {
    return [
      MaxRetryInterceptor(),
      CacheReadInterceptor(store: self.store),
      BatchNetworkFetchInterceptor(poller: DefaultBatchPoller<Operation>(config: batchConfig, client: client)),
      ResponseCodeInterceptor(),
      JSONResponseParsingInterceptor(cacheKeyForObject: self.store.cacheKeyForObject),
      AutomaticPersistedQueryInterceptor(),
      CacheWriteInterceptor(store: self.store),
    ]
  }
}
