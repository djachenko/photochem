public enum TimeFormatting {
    public static func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        
        return "\(minutes):\(remainder < 10 ? "0" : "")\(remainder)"
    }

    public static func parse(_ string: String) -> Int? {
        let parts = string.split(separator: ":", omittingEmptySubsequences: false)

        guard parts.count == 2 else {
            return nil
        }

        let minutesPart = parts[0]
        let secondsPart = parts[1]

        guard (1...2).contains(minutesPart.count),
              minutesPart.allSatisfy(\.isASCIIDigit),
              let minutes = Int(minutesPart),
              secondsPart.count == 2 ,
              secondsPart.allSatisfy(\.isASCIIDigit),
              let seconds = Int(secondsPart),
              seconds < 60 else {
            return nil
        }

        return minutes * 60 + seconds
    }
}

private extension Character {
    var isASCIIDigit: Bool {
        isASCII && isNumber
    }
}
