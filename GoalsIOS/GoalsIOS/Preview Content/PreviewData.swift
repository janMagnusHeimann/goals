import Foundation
import SwiftData

enum PreviewData {
    @MainActor
    static var container: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Goal.self, configurations: config)

        // Sample Book Reading Goal
        let bookGoal = Goal(title: "Read 12 Books", goalType: .bookReading, targetValue: 12)
        bookGoal.currentValue = 3
        container.mainContext.insert(bookGoal)

        let book1 = Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald")
        book1.totalPages = 180
        book1.currentPage = 180
        book1.isCompleted = true
        book1.goal = bookGoal
        container.mainContext.insert(book1)

        let book2 = Book(title: "1984", author: "George Orwell")
        book2.totalPages = 328
        book2.currentPage = 150
        book2.goal = bookGoal
        container.mainContext.insert(book2)

        // Sample Fitness Goal
        let fitnessGoal = Goal(title: "Ironman Training", goalType: .fitness, targetValue: 100)
        fitnessGoal.currentValue = 15
        container.mainContext.insert(fitnessGoal)

        let session1 = TrainingSession(workoutType: .run, durationMinutes: 45)
        session1.distance = 8.5
        session1.distanceUnit = .kilometers
        session1.goal = fitnessGoal
        container.mainContext.insert(session1)

        // Sample Programming Goal
        let codeGoal = Goal(title: "Open Source Contributions", goalType: .programming, targetValue: 500)
        codeGoal.currentValue = 120
        container.mainContext.insert(codeGoal)

        return container
    }
}
