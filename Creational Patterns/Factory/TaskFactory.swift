// Define a basic protocol for a Task
// This protocol acts as a template for any task, ensuring they all have a title, description, and a way to perform the task.
protocol Task {
    var title: String { get set }
    var description: String { get set }
    func performTask()
}

// Define the different task types.
// This allows for easy categorisation of tasks into simple, recurring, or deadline-based types.
enum TaskType {
    case simple, recurring, deadline
}

// Concrete Task types implementing the Task protocol.

// SimpleTask for tasks that are one-off or don't repeat.
final class SimpleTask: Task {
    var title: String
    var description: String

    init(
        title: String,
        description: String
    ) {
        self.title = title
        self.description = description
    }
    
    func performTask() {
        print("Performing a simple task with title: \(title), and description: \(description)")
    }
}

// RecurringTask for tasks that occur repeatedly.
final class RecurringTask: Task {
    var title: String
    var description: String
    
    init(
        title: String,
        description: String
    ) {
        self.title = title
        self.description = description
    }

    func performTask() {
        print("Performing a recurring task with title: \(title), and description: \(description)")
    }
}

// DeadlineTask for tasks that need to be completed by a specific date.
final class DeadlineTask: Task {
    var title: String
    var description: String
    var deadline: String // Additional property to store the deadline.

    init(
        title: String,
        description: String,
        deadline: String
    ) {
        self.title = title
        self.description = description
        self.deadline = deadline
    }

    func performTask() {
        print("Performing a task with a deadline (\(deadline)), with title: \(title), and description: \(description)")
    }
}

// Task Factory to create tasks based on the type.
// This class uses a factory method pattern to simplify task creation.
final class TaskFactory {
    static func createTask(
        type: TaskType,
        title: String,
        description: String,
        deadline: String? = nil
    ) -> Task {
        
        switch type {
        case .simple:
            return SimpleTask(title: title, description: description)
        case .recurring:
            return RecurringTask(title: title, description: description)
        case .deadline:
            return DeadlineTask(title: title, description: description, deadline: deadline ?? "")
        }
    }
}

// Example Usage:
// Creating various tasks using the TaskFactory and then performing them.

let simpleTask = TaskFactory.createTask(
    type: .simple,
    title: "Write Swift Code",
    description: "Develop a new feature using Swift."
)

let recurringTask = TaskFactory.createTask(
    type: .recurring,
    title: "Code Review",
    description: "Regularly review team's code submissions."
)

let deadlineTask = TaskFactory.createTask(
    type: .deadline,
    title: "Project Deadline",
    description: "Complete the project for the end-of-year release.",
    deadline: "2023-12-31"
)

// Storing the tasks in an array and iterating over them to perform each task.
let tasks = [simpleTask, recurringTask, deadlineTask]

tasks.forEach {
    $0.performTask()
}
