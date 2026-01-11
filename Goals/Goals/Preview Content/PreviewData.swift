import SwiftData
import Foundation

@MainActor
enum PreviewData {
    static var container: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Goal.self, Book.self, Chapter.self, ChapterNote.self,
            TrainingSession.self, GitHubRepository.self, CommitActivity.self,
            configurations: config
        )

        // Add sample data
        let bookGoal = Goal(title: "Read 100 Books in 2025", goalType: .bookReading, targetValue: 100)
        bookGoal.currentValue = 23
        bookGoal.goalDescription = "Challenge myself to read more this year"
        container.mainContext.insert(bookGoal)

        let book1 = Book(title: "The Pragmatic Programmer", author: "David Thomas, Andrew Hunt")
        book1.totalPages = 352
        book1.currentPage = 352
        book1.isCompleted = true
        book1.completionDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        book1.goal = bookGoal
        container.mainContext.insert(book1)

        let chapter1 = Chapter(title: "A Pragmatic Philosophy", orderIndex: 1)
        chapter1.isCompleted = true
        chapter1.book = book1
        container.mainContext.insert(chapter1)

        let note1 = ChapterNote(content: "Care about your craft - there's no point in developing software unless you care about doing it well.")
        note1.chapter = chapter1
        container.mainContext.insert(note1)

        let book2 = Book(title: "Clean Code", author: "Robert C. Martin")
        book2.totalPages = 464
        book2.currentPage = 156
        book2.goal = bookGoal
        container.mainContext.insert(book2)

        // Fitness goal
        let fitnessGoal = Goal(title: "Complete Ironman Training", goalType: .fitness, targetValue: 365)
        fitnessGoal.currentValue = 45
        fitnessGoal.goalDescription = "Prepare for my first Ironman triathlon"
        container.mainContext.insert(fitnessGoal)

        let session1 = TrainingSession(workoutType: .run, date: Date(), durationMinutes: 45)
        session1.distance = 8.5
        session1.distanceUnit = .kilometers
        session1.perceivedEffort = 6
        session1.goal = fitnessGoal
        container.mainContext.insert(session1)

        let session2 = TrainingSession(workoutType: .swim, date: Date().addingTimeInterval(-24 * 60 * 60), durationMinutes: 60)
        session2.distance = 2.0
        session2.distanceUnit = .kilometers
        session2.perceivedEffort = 7
        session2.goal = fitnessGoal
        container.mainContext.insert(session2)

        // Programming goal
        let programmingGoal = Goal(title: "1000 Commits in 2025", goalType: .programming, targetValue: 1000)
        programmingGoal.currentValue = 234
        programmingGoal.goalDescription = "Contribute more to open source projects"
        container.mainContext.insert(programmingGoal)

        let repo = GitHubRepository(
            repoId: 12345,
            name: "goals-app",
            fullName: "user/goals-app",
            htmlURL: "https://github.com/user/goals-app"
        )
        repo.language = "Swift"
        repo.starCount = 42
        repo.repoDescription = "A beautiful goal tracking app for macOS"
        repo.goal = programmingGoal
        container.mainContext.insert(repo)

        return container
    }

    static var sampleBookGoal: Goal {
        let goal = Goal(title: "Read 100 Books", goalType: .bookReading, targetValue: 100)
        goal.currentValue = 23
        return goal
    }

    static var sampleFitnessGoal: Goal {
        let goal = Goal(title: "Complete Ironman", goalType: .fitness, targetValue: 365)
        goal.currentValue = 45
        return goal
    }

    static var sampleProgrammingGoal: Goal {
        let goal = Goal(title: "1000 Commits", goalType: .programming, targetValue: 1000)
        goal.currentValue = 234
        return goal
    }

    static var sampleBook: Book {
        let book = Book(title: "The Pragmatic Programmer", author: "David Thomas")
        book.totalPages = 352
        book.currentPage = 156
        return book
    }

    static var sampleTrainingSession: TrainingSession {
        let session = TrainingSession(workoutType: .run, durationMinutes: 45)
        session.distance = 8.5
        session.distanceUnit = .kilometers
        session.perceivedEffort = 6
        return session
    }
}
