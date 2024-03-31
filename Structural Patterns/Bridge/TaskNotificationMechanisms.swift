import Foundation

// Task Protocol - Changed the protocol name used in the past examples to "MyTask" to avoid
// issues with the Swift's own concurrency construct, Task.
protocol MyTask {
    var title: String { get }
    func performTask() async -> String // Now returns a String describing the task result. I am making this change to try to provide more information to the end user.
}

// Concrete MyTask Implementation
struct ReportGenerationMyTask: MyTask {
    var title: String
    
    func performTask() async -> String {
        print("\(title) Generating report...")
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate time-consuming task
            return "\(title) Report generated successfully." // Return a success message
        } catch {
            return "\(title) Task was cancelled." // Return a cancellation message
        }
    }
}

// Notification Mechanism Protocol (Implementor)
protocol NotificationMechanism {
    func sendNotification(taskTitle: String, message: String) async
}

// Concrete Implementors for Notification Mechanisms
final class EmailNotification: NotificationMechanism {
    func sendNotification(taskTitle: String, message: String) async {
        print("Sending email for '\(taskTitle)': \(message)")
        
        // Add the specific code to send the notification by email
    }
}

final class MessagingNotification: NotificationMechanism {
    func sendNotification(taskTitle: String, message: String) async {
        print("Sending messaging notification for '\(taskTitle)': \(message)")
        
        // Add the specific code to send the notification by message
    }
}

// Usage Example
func main() async {
    let task = ReportGenerationMyTask(title: "End-of-Year Financial Report")
    let taskResult = await task.performTask()
    
    // Choose notification mechanism
    let emailNotifier = EmailNotification()
    let messageNotifier = MessagingNotification()
    
    // Send notifications with task result
    await emailNotifier.sendNotification(taskTitle: task.title, message: taskResult)
    await messageNotifier.sendNotification(taskTitle: task.title, message: taskResult)
}

Task {
    await main()
}
