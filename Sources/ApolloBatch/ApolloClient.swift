import Foundation

import Apollo

extension ApolloClient {
  
  /// Convenience function for creating a batching `ApolloClient` instance.
  ///
  /// - Parameters:
  ///   - url: The URL of a GraphQL server to connect to.
  ///   - config: The batch configuration object.
  class func batching(url: URL, config: BatchConfig) -> ApolloClient {
    let store = ApolloStore(cache: InMemoryNormalizedCache())
    let provider = DefaultInterceptorProvider(store: store)
    let transport = RequestChainNetworkTransport(interceptorProvider: provider,
                                                         endpointURL: url)

    return ApolloClient(networkTransport: transport, store: store)
  }
}
