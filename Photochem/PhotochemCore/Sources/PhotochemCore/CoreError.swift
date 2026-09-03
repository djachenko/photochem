public enum CoreError: Error, Equatable {
    case unsupportedSchemaVersion(Int)
    case malformedJSON(String)
    case validationFailed(rule: String, detail: String)
    case capacityExceeded(mileage: Int, films: Int, capacity: Int)
    case invalidFilmCount(Int)
}
