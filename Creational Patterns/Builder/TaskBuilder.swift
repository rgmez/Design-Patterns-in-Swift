// Task structure representing a single task in the management system.
// It includes essential details like title, type, description, deadline, priority, and assignee.
struct Task {
    let title: String
    let type: TaskType
    let description: String
    let deadline: String
    let priority: Priority
    let assignee: String
}

// Enum for differentiating task types. This helps categorize tasks based on their nature or requirement.
enum TaskType {
    case simple, recurring, deadline, unknown // 'unknown' can be used as a default or placeholder.
}

// Enum for setting the priority of a task. It helps in task prioritization and management.
enum Priority {
    case low, medium, high
}

// Protocol defining the contract for a Task builder.
// It specifies methods to set various properties of a Task.
protocol TaskBuilderProtocol {
    func setTitle(_ title: String) -> TaskBuilder
    func setDescription(_ description: String) -> TaskBuilder
    func setDeadline(_ deadline: String) -> TaskBuilder
    func setPriority(_ priority: Priority) -> TaskBuilder
    func setAssignee(_ assignee: String) -> TaskBuilder
    func build() -> Task // Method to construct the final Task object.
}

// Task builder class for creating a Task. It implements the TaskBuilderProtocol.
final class TaskBuilder: TaskBuilderProtocol {
    // Private properties holding the state of the building task.
    private var title: String = "New Task"
    private var type: TaskType = .unknown
    private var description: String = "No description"
    private var deadline: String = "No Deadline"
    private var priority: Priority = .medium
    private var assignee: String = "Unassigned"

    // Each of these methods sets a specific attribute of a task and returns the builder itself for method chaining.
    func setTitle(_ title: String) -> TaskBuilder {
        self.title = title
        return self
    }

    func setType(_ type: TaskType) -> TaskBuilder {
        self.type = type
        return self
    }

    func setDescription(_ description: String) -> TaskBuilder {
        self.description = description
        return self
    }

    func setDeadline(_ deadline: String) -> TaskBuilder {
        self.deadline = deadline
        return self
    }

    func setPriority(_ priority: Priority) -> TaskBuilder {
        self.priority = priority
        return self
    }

    func setAssignee(_ assignee: String) -> TaskBuilder {
        self.assignee = assignee
        return self
    }

    // Finalizes the construction of the Task object and returns it.
    // This method uses the current state of the builder to create a new Task instance.
    func build() -> Task {
        Task(
            title: title,
            type: type,
            description: description,
            deadline: deadline,
            priority: priority,
            assignee: assignee
        )
    }
}

// Demonstrating how to use the TaskBuilder to create a Task instance.
let taskBuilder = TaskBuilder()
let task = taskBuilder
    .setTitle("Implement Builder Pattern")
    .setType(.deadline)
    .setDescription("Create a builder pattern example for the Task Management System")
    .setDeadline("2023-12-31")
    .setPriority(.high)
    .setAssignee("Roberto G.")
    .build()
