import Foundation

// Task Protocol - Changed the protocol name used in the past examples to "MyTask" to avoid
// issues with the Swift's own concurrency construct, Task.
protocol MyTask {
    var title: String { get }
    var description: String { get }
    func performTask() async
}

// ExecutionMode Protocol (Implementor) - serves as the bridge between the task and how it's executed
// allowing for flexible task execution strategies
protocol ExecutionMode {
    func execute(task: MyTask) async
}

// Concrete Implementor for Asynchronous Execution
final class AsyncExecution: ExecutionMode {
    func execute(task: MyTask) async {
        print("Asynchronous Task: \(task.title) execution starts")
        // Simulating a network call or a time-consuming operation
        // Waiting for 2 seconds
        await Task.sleep(2_000_000_000)
        
        // Now perform the task
        await task.performTask()
        print("Asynchronous Task: \(task.title) execution end")
    }
}

// Concrete Implementor for Synchronous Execution
final class SyncExecution: ExecutionMode {
    func execute(task: MyTask) async {
        print("Synchronous Task: \(task.title) execution starts")
        await task.performTask()
        print("Synchronous Task: \(task.title) execution end")
    }
}

// Task Abstraction
final class GenericTask: MyTask {
    var title: String
    var description: String
    var executionMode: ExecutionMode?
    
    init(
        title: String,
        description: String,
        executionMode: ExecutionMode? = nil
    ) {
        self.title = title
        self.description = description
        self.executionMode = executionMode
    }
    
    func performTask() async {
        print("Performing Task: \(title) - \(description)")
    }
    
    func execute() async {
        await executionMode?.execute(task: self)
    }
}

// Usage Example
func main() async {
    let task1 = GenericTask(
        title: "Update Database",
        description: "Perform database migration.",
        executionMode: SyncExecution()
    )
    await task1.execute()

    let task2 = GenericTask(
        title: "Fetch Remote Data",
        description: "Download data from API.",
        executionMode: AsyncExecution()
    )
    await task2.execute()
}

Task {
    await main()
}
