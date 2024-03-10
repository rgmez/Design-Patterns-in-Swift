// Define the basic Task protocol for the in-house system.
protocol Task {
    var title: String { get }
    var description: String { get }
    func performTask()
}

// ExternalTaskService is a modern, third-party task management system.
// This service has its unique interface for handling tasks.
class ExternalTaskService {
    var taskName: String
    var taskDetail: String
    var isCompleted: Bool
    
    init(taskName: String, taskDetail: String, isCompleted: Bool) {
        self.taskName = taskName
        self.taskDetail = taskDetail
        self.isCompleted = isCompleted
    }

    func markAsComplete() {
        self.isCompleted = true
        print("Task '\(taskName)' marked as complete. Detail: \(taskDetail), Completed: \(isCompleted)")
    }
}

// TaskAdapter adapts ExternalTaskService to be compatible with the Task protocol.
// This allows ExternalTaskService tasks to be treated as in-house Task objects.
struct ExternalTaskAdapter: Task {
    private var externalTask: ExternalTaskService

    var title: String {
        return externalTask.taskName
    }

    var description: String {
        return externalTask.taskDetail
    }

    init(externalTask: ExternalTaskService) {
        self.externalTask = externalTask
    }

    func performTask() {
        externalTask.markAsComplete()
    }
}

// Example Usage:

// Creating an instance of ExternalTaskService
let externalServiceTask = ExternalTaskService(
    taskName: "API Integration",
    taskDetail: "Integrate external task management API.",
    isCompleted: false
)

// Adapting the external service task to fit the in-house Task protocol.
var adaptedTask = ExternalTaskAdapter(externalTask: externalServiceTask)

// Now, the external service task can be used just like any other in-house Task.
adaptedTask.performTask()
