import Foundation

import Apollo
import ApolloUtils

/// Default `BatchPoller` implementation that flushes batched operations from
/// a local queue on a timer.
class DefaultBatchPoller<Operation: GraphQLOperation>: BatchPoller {
  var batch: [BatchedRequest<Operation>] = []
  var scheduler: PeriodicJobScheduler = DefaultPeriodicJobScheduler()
  let config: BatchConfig
  let client: URLSessionClient
  private var currentTask: Atomic<URLSessionTask?> = Atomic(nil)
  let requestBodyCreator: RequestBodyCreator
  
  init(config: BatchConfig, client: URLSessionClient, requestBodyCreator: RequestBodyCreator = ApolloRequestBodyCreator()) {
    self.client = client
    self.config = config
    self.requestBodyCreator = requestBodyCreator
  }
  
  /// Enqueues a GraphQL `HTTPRequest` for batch execution.
  ///
  /// - Parameters:
  ///   - request: The GraphQL operation to execute.
  ///   - completion: The HTTP fetch callback.
  func enqueue<Operation>(request: HTTPRequest<Operation>, completion: @escaping Completion) where Operation : GraphQLOperation {
    if !scheduler.isRunning() {
      completion(.failure(PollerError.pollerNotStarted))
    }
    
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }
    
    batch.append(BatchedRequest(request: request, completion: completion) as! BatchedRequest)
  }
  
  /// Start the poller - must be invoked before enqueueing.
  func start() {
    scheduler.schedulePeriodicJob(interval: config.interval) {
      objc_sync_enter(self)
      defer { objc_sync_exit(self) }
      
      self.maybeFetch()
    }
  }
  
  /// Stop the poller and cancel in flight operations.
  func stop() {
    scheduler.cancel()
  }
  
  /// Flush the operations from the queue and execute a transport-batched GraphQL request.
  func maybeFetch() {
    guard !batch.isEmpty else {
      return
    }
    
    let toSend: [BatchedRequest<Operation>] = batch.map { request in
      request
    }
    
    batch.removeAll()
    
    let bodies: [GraphQLMap] = toSend.filter {
      $0.request is JSONRequest
    }.map {
      ($0.request as! JSONRequest).body
    }
    
    do {
      let jsonBody = try JSONSerializationFormat.self.serialize(value: bodies)
      
      // Assume all requests have the same headers, etc.
      var urlRequest = try batch.first!.request.toURLRequest()
      
      urlRequest.httpBody = jsonBody
      
      let task = self.client.sendRequest(urlRequest) { [weak self] result in
        guard let self = self else {
          return
        }
        
        defer {
          self.currentTask.mutate { $0 = nil }
        }
        
        switch result {
        case .failure(_):
          toSend.forEach {
            $0.completion(result)
          }
        case .success(let (data, httpResponse)):
          do {
            let json: [JSONValue] = try (JSONSerializationFormat.self.deserialize(data: data) as! [AnyObject])
            
            for (index, item) in json.enumerated() {
              let raw = try JSONSerializationFormat.self.serialize(value: item as! JSONEncodable)
              toSend[index].completion(.success((raw, httpResponse)))
            }
          } catch {
            toSend.forEach { request in
              request.completion(.failure(error))
            }
          }
        }
      }
      
      self.currentTask.mutate { $0 = task }
    } catch {
      batch.forEach { request in
        request.completion(.failure(error))
      }
    }
  }
}
