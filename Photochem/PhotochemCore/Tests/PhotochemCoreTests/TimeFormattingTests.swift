import Testing
@testable import PhotochemCore

struct TimeFormattingTests {
    @Test(arguments: [(195, "3:15"), (600, "10:00"), (60, "1:00"), (5, "0:05"), (0, "0:00")])
    func formatsSeconds(seconds: Int, expected: String) {
        #expect(TimeFormatting.format(seconds: seconds) == expected)
    }

    @Test(arguments: [("3:15", 195), ("10:00", 600), ("0:45", 45)])
    func parsesValidStrings(string: String, expected: Int) {
        #expect(TimeFormatting.parse(string) == expected)
    }

    @Test(arguments: ["3:5", "3:60", "195", "-1:00"])
    func rejectsInvalidStrings(string: String) {
        #expect(TimeFormatting.parse(string) == nil)
    }
}
