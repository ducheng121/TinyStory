import Foundation

@main
struct ValidateStories {
    static func main() {
        do {
            guard CommandLine.arguments.count == 2 else {
                throw StoryContent.ContentError(detail: "Usage: ValidateStories <Stories directory>")
            }
            let library = try StoryContent.validate(at: URL(fileURLWithPath: CommandLine.arguments[1]))
            print("Validated \(library.current.count) current and \(library.legacy.count) legacy stories.")
        } catch {
            fputs("error: Story validation failed: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
