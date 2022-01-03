import SwiftUI

struct DiagnosisResult: Codable, Hashable {
    let date: Date
    let diagnosis: DPDiagnosisAPI.DiagnosisResult

    init(date: Date, diagnosis: DPDiagnosisAPI.DiagnosisResult) {
        self.date = date
        self.diagnosis = diagnosis
    }
}

struct DiagnosisResultList: Codable {
    private var resultList: Dictionary<String, DiagnosisResult>

    init(resultList: Dictionary<String, DiagnosisResult>) {
        self.resultList = resultList
    }

    public func getResult(date: Date) -> DiagnosisResult? {
        let key = dateToString(date: date)
        return resultList[key]
    }

    public mutating func addResult(result: DiagnosisResult) {
        let key = dateToString(date: result.date)
        if let _ = resultList.index(forKey: key) {
            self.resultList.updateValue(result, forKey: key)
        } else {
            self.resultList[key] = result
        }
    }

    public func getDiagonsisSummary() -> String { // TODO: impl
        let adCount = resultList.filter { $0.value.diagnosis == .alzheimerDementiaPossibility }.count
        let hpCount = resultList.filter { $0.value.diagnosis == .healthyPersonPossibility }.count

        return "\(adCount)/\(adCount + hpCount) = \(adCount / (adCount + hpCount))%"
    }

    private func dateToString(date: Date) -> String {
        getDateFormat().string(from: date)
    }

    private func getDateFormat() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }
}

