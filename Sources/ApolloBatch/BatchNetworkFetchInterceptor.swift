import Foundation

import Apollo

/// `ApolloInterceptor` implementation that enqueues GraphQL operation requests
/// with a `BatchPoller`, which groups requests together for execution. Should not be
/// used in the same `RequestChain` with `NetworkFetchInterceptor`.
class BatchNetworkFetchInterceptor: ApolloInterceptor, Cancellable {
  var poller: BatchPoller
  
  init(poller: BatchPoller) {
    self.poller = poller
    self.poller.start()
  }
  
  func interceptAsync<Operation>(chain: RequestChain, request: HTTPRequest<Operation>, response: HTTPResponse<Operation>?, completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) where Operation : GraphQLOperation {
      
    poller.enqueue(request: request) { result in
      switch(result) {
      case .failure(let error):
        chain.handleErrorAsync(error,
                               request: request,
                               response: response,
                               completion: completion)
      case .success(let (data, httpResponse)):
        let response = HTTPResponse<Operation>(response: httpResponse,
                                               rawData: data,
                                               parsedResponse: nil)
        chain.proceedAsync(request: request,
                           response: response,
                           completion: completion)
      }
    }
  }
  
  func cancel() {
    self.poller.stop()
  }
}
