import Foundation

import Apollo

/// Schedules jobs on a specified time interval.
protocol PeriodicJobScheduler {
  /// Schedules a closure on a time interval specified by `timeInterval`.
  /// - Parameters:
  ///   - interval: The interval in milliseconds to execute `job`.
  ///   - job: The closure to execute.
  func schedulePeriodicJob(interval: TimeInterval, job: @escaping () -> Void)
  
  /// Cancel and invalidate the scheduler.
  func cancel()
  
  /// Returns `true` if the poller is actively scheduling jobs, otherwise `false`.
  func isRunning() -> Bool
}
