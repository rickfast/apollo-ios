import Foundation

import Apollo

/// Default `PeriodicJobScheduler` that leverages a `Timer`.
class DefaultPeriodicJobScheduler: PeriodicJobScheduler {
  var timer: Timer? = nil
  
  /// Schedules a closure on a time interval specified by `timeInterval`.
  /// - Parameters:
  ///   - interval: The interval in milliseconds to execute `job`.
  ///   - job: The closure to execute.
  func schedulePeriodicJob(interval: TimeInterval, job: @escaping () -> Void) {
    timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
      job()
    }
  }
  
  /// Cancel and invalidate the scheduler.
  func cancel() {
    timer?.invalidate()
    timer = nil
  }
  
  /// Returns `true` if the poller is actively scheduling jobs, otherwise `false`.
  func isRunning() -> Bool {
    return timer != nil
  }
}
