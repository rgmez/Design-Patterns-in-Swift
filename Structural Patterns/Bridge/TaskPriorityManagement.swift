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

// MARK: - Priority Domain

enum TaskPriority: String {
    case high, medium, low
}

// MARK: - Implementor

protocol TaskPriorityResolving {
    func resolvePriority(for task: MyTask) -> TaskPriority
}

// MARK: - Concrete Resolvers

struct HighPriorityResolver: TaskPriorityResolving {
    func resolvePriority(for task: MyTask) -> TaskPriority {
        .high
    }
}

struct FallbackPriorityResolver: TaskPriorityResolving {
    func resolvePriority(for task: MyTask) -> TaskPriority {
        .low
    }
}

struct TitleAwarePriorityResolver: TaskPriorityResolving {
    func resolvePriority(for task: MyTask) -> TaskPriority {
        if task.title.localizedCaseInsensitiveContains("urgent") {
            return .high
        } else if task.title.localizedCaseInsensitiveContains("report") {
            return .medium
        }
        
        return .low
    }
}

// MARK: - Bridge Abstraction

struct PriorityAwareTaskExecutor {
    let task: MyTask
    let priorityResolver: TaskPriorityResolving

    func execute() async {
        let priority = priorityResolver.resolvePriority(for: task)
        print("Executing '\(task.title)' with priority: \(priority.rawValue.uppercased())")

        let result = await task.performTask()
        print("Result: \(result)")
    }
}

// MARK: - Usage

/// Demonstrates how different priority-resolution strategies can be applied to the same task without modifying its implementation.
/// This clearly shows the Bridge Pattern in action:
/// - Tasks and priority algorithms vary independently
/// - New resolvers can be introduced without breaking existing code
func priorityExample() async {
    let urgentTask = ReportGenerationMyTask(title: "Urgent Financial Report")
    let regularTask = ReportGenerationMyTask(title: "Weekly Report")

    await PriorityAwareTaskExecutor(
        task: urgentTask,
        priorityResolver: HighPriorityResolver()
    ).execute()

    await PriorityAwareTaskExecutor(
        task: urgentTask,
        priorityResolver: TitleAwarePriorityResolver()
    ).execute()

    await PriorityAwareTaskExecutor(
        task: regularTask,
        priorityResolver: FallbackPriorityResolver()
    ).execute()
}
