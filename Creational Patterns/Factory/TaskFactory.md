# Factory Design Pattern

## Introduction
The Factory Design Pattern is a creational pattern that provides an interface for creating objects in a superclass but allows subclasses to alter the type of objects that will be created. This pattern is particularly useful when a system needs to be independent from the way its objects are created, composed, and represented.

## Characteristics

### 1. Object Creation Abstraction
- The Factory Pattern abstracts the process of object creation from the client. This means that the client does not need to know the exact class that needs to be instantiated.

### 2. Encapsulation of Object Creation
- All details about object creation are encapsulated within the factory. This centralises the creation logic, making the code more maintainable.

### 3. Easy to Extend
- Adding new types of products requires modifying the factory, but does not necessitate changes in the client code. This adheres to the Open/Closed Principle, as the code is open for extension but closed for modification.

### 4. Decoupling
- The Factory Pattern helps to decouple the implementation of the product from its use. The client is only aware of the interfaces, not the concrete implementations, reducing the system's overall coupling.

## Use Cases
- When a class does not know what subclasses will be required to create.
- When a class wants its subclasses to specify the objects to be created.
- When the creation logic of objects needs to be independent of the system's composition.

## Example in Swift
In our Swift code example, we used the Factory Pattern to create different types of tasks (`SimpleTask`, `RecurringTask`, `DeadlineTask`). The `TaskFactory` class is responsible for creating these task instances based on the provided `TaskType`. This abstraction allows for easy addition of new task types without modifying the client code that uses the factory.

For a practical implementation, see the Swift code in [TaskFactory.swift](./TaskFactory.swift).
