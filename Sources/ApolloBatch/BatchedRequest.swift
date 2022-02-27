import Foundation

import Apollo

typealias Completion = (Result<(Data, HTTPURLResponse), Error>) -> Void

/// Groups an `HTTPRequest` with an associated `Completion` allowing the
/// `BatchPoller` to complete each individual operation request when its batch
/// completes.
struct BatchedRequest<Operation: GraphQLOperation> {
  /// The GraphQL operation to execute
  var request: HTTPRequest<Operation>
  
  /// The HTTP fetch callback.
  var completion: Completion
}
