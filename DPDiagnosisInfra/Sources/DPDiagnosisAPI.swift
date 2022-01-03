import Combine

final class DPDiagnosisAPI {
    public func dementiaPossibilityDiagnosis(heartRate: [HeartRate]) -> AnyPublisher<DiagnosisResult, Error> {
        mockDementiaPossibilityDiagnosis() // TODO: impl
    }
}

extension DPDiagnosisAPI {
    enum DiagnosisResult: String, Codable {
        case alzheimerDementiaPossibility = "alzheimerDementiaPossibility"
        case healthyPersonPossibility = "healthyPersonPossibility"
        case noResult = "noResult"
    }
}

extension DPDiagnosisAPI {
    private func mockDementiaPossibilityDiagnosis() -> AnyPublisher<DiagnosisResult, Error> {
        Just(DiagnosisResult.alzheimerDementiaPossibility).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
