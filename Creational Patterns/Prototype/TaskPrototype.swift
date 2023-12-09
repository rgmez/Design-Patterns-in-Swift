// Protocol for cloning
protocol TaskPrototype {
    func clone() -> TaskPrototype
}

// Enum for differentiating task types. This helps categorize tasks based on their nature or requirement.
enum TaskType {
    case simple, recurring, deadline, unknown // 'unknown' can be used as a default or placeholder.
}

// Enum for setting the priority of a task. It helps in task prioritization and management.
enum Priority {
    case low, medium, high, unknown
}

// Base struct for tasks
class Task: TaskPrototype {
    var title: String
    var type: TaskType
    var description: String
    var priority: Priority
    var deadline: String?
    var assignee: String
    
    init(title: String, type: TaskType, description: String, priority: Priority, deadline: String?, assignee: String) {
        self.title = title
        self.type = type
        self.description = description
        self.priority = priority
        self.deadline = deadline
        self.assignee = assignee
    }
    
    func clone() -> TaskPrototype {
        Task(
            title: self.title,
            type: self.type,
            description: self.description,
            priority: self.priority,
            deadline: self.deadline,
            assignee: self.assignee
        )
    }
}

// Extended task type with additional properties
final class ExtendedTask: Task {
    var attachments: [String]
    
    init(
        title: String,
        type: TaskType,
        description: String,
        priority: Priority,
        deadline: String?,
        assignee: String,
        attachments: [String] = []
    ) {
        self.attachments = attachments
        super.init(
            title: title,
            type: type,
            description: description,
            priority: priority,
            deadline: deadline,
            assignee: assignee
        )
    }

    override func clone() -> TaskPrototype {
        ExtendedTask(
            title: self.title,
            type: self.type,
            description: self.description,
            priority: self.priority,
            deadline: self.deadline,
            assignee: self.assignee,
            attachments: self.attachments
        )
    }
}

// Original instances
let originalBasicTask = Task(
    title: "Basic Task",
    type: .simple,
    description: "This is a basic task",
    priority: .medium,
    deadline: "2023-12-10",
    assignee: "Roberto G"
)

let originalExtendedTask = ExtendedTask(
    title: "Extended Task",
    type: .deadline,
    description: "This is an extended task",
    priority: .high,
    deadline: "2023-12-15",
    assignee: "Roberto G",
    attachments: ["initialFile.doc"]
)

// Cloning and updating attributes
let clonedBasicTask = originalBasicTask.clone() as? Task
// Update some attributes of the cloned basic task
clonedBasicTask?.priority = .high
clonedBasicTask?.deadline = "2023-12-12"

let clonedExtendedTask = originalExtendedTask.clone() as? ExtendedTask
// Update some attributes of the cloned extended task
clonedExtendedTask?.assignee = "John Doe"
clonedExtendedTask?.attachments.append("additionalFile.txt")

// Output to verify the cloning and updates
print("""
      Original Basic Task Title: \(originalBasicTask.title),
      Priority: \(originalBasicTask.priority)
      """)
print("""
      Cloned Basic Task Title: \(clonedBasicTask?.title ?? "Unknown Title"),
      Priority: \(clonedBasicTask?.priority ?? .unknown)
      """)

print("""
      Original Extended Task Title: \(originalExtendedTask.title),
      Attachments: \(originalExtendedTask.attachments)
      """)
print("""
     Cloned Extended Task Title: \(clonedExtendedTask?.title ?? "Unknown Title"),
     Attachments: \(clonedExtendedTask?.attachments ?? [])
     """)
