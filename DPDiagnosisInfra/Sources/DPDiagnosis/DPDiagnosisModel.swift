import Combine
import Foundation

final class DPDiagnosisModel {
    public static let version = "v0.1.1" //バージョンコード, Realmに対しては現在のバージョンコードと異なる場合に再計算を実施する

    private var matrix: [[Double]] = [[Double]]()
    private var sumY: [Double] = [Double]()
    private var currentCoefficient: [Double] = [Double]()
    private var coefficientHistory: [CoefficientHistory] = []

    private var progressPublisher: PassthroughSubject<(currentProcess: Int, totalProcess: Int), Error>? = nil
    private var firstHR: HeartRate = .init(id: "", startDatetime: Date(), endDatetime: Date(), value: -1)

    private func resetParameter() {
        self.matrix = [[Double]](repeating: [Double](repeating: 0, count: Const.numCoefficient), count: Const.numCoefficient)
        self.sumY = [Double](repeating: 0, count: Const.numCoefficient)
        self.currentCoefficient = []
        self.coefficientHistory = []
    }

    public func dementiaPossibilityDiagnosis(heartRate: [HeartRate], progressPublisher: PassthroughSubject<(currentProcess: Int, totalProcess: Int), Error>?) -> AnyPublisher<DiagnosisResult, Error> {
        Future<DiagnosisResult, Error>(){ [weak self] promise in
            guard let self = self, heartRate.count >= Const.minHeartRateData, let firstHeartRate = heartRate.first else {
                promise(.failure(ModelError.receiveFewHeartRateData))
                return
            }
            self.progressPublisher = progressPublisher
            self.firstHR = firstHeartRate

            self.resetParameter()
            self.currentCoefficient = [Double](repeating: 0, count: Const.numCoefficient) // TODO: 0以外の初期値も設定可能に

            for (dataIndex, hr) in zip(heartRate.indices, heartRate) {
                self.calcCoefficients(hr: hr, dataIndex: dataIndex)
            }

            promise(.success(self.diagnosisWithUCRADD()))
        }
        .eraseToAnyPublisher()


    }

    public func diagnosisWithUCRADD() -> DiagnosisResult {
        guard let last = coefficientHistory.last else { return .noResult }
        let lastCoefficient = last.coefficients

        // FIXME:
        var sinAbsSum: Double = 0.0
        var sinSumAbs: Double = 0.0
        var cosAbsSum: Double = 0.0
        var cosSumAbs: Double = 0.0
        for i in 0..<Const.numCoefficient/2 {
            sinAbsSum += abs(lastCoefficient[i])
            sinSumAbs += lastCoefficient[i]
            cosAbsSum += abs(lastCoefficient[i + 1])
            cosSumAbs += lastCoefficient[i + 1]
        }

        sinSumAbs = abs(sinSumAbs)
        cosSumAbs = abs(cosSumAbs)

        return sinAbsSum == sinSumAbs && cosAbsSum == cosSumAbs ? .healthyPersonPossibility : .alzheimerDementiaPossibility
    }
}

extension DPDiagnosisModel {
    private enum Const {
        static let periods: [Double] = [25.0 * 60.0 * 60.0, 24.0 * 60.0 * 60.0, 23.0 * 60.0 * 60.0]
        static let numCoefficient: Int = 3 * 2 + 1

        static let minHeartRateData = 1

        static let lambda: Double = 1.0
        static let alpha: Double = 0.0
        static let gamma: Double = 2.0
        static let gammaChangeTime: Double = 10 * 60 // 10分
    }

    private func w (matrixI: Int, matrixJ: Int, x: Double, dataIndex: Int) -> Double {
        if matrixI != matrixJ {
            return 0.0
        } else if matrixI == Const.numCoefficient - 1 {
            // PenaltyFunction.P6
            return 0.0
        } else {
            // PenaltyFunction.P6
            return Const.lambda * Double(dataIndex) * pow(gammaT(x: x), floor(Double(matrixI) / 2.0) - 1.0) / Double(Const.numCoefficient)
        }
    }

    private func gammaT(x: Double) -> Double {
        if x > Const.gammaChangeTime {
            return 1.0
        } else {
            return (1.0 - Const.gamma) * x / Const.gammaChangeTime + Const.gamma
        }
    }

    private func sincos(x: Double, coeffIndex: Int) -> Double {
        if coeffIndex == Const.numCoefficient - 1 {
            return 1.0
        } else if (coeffIndex % 2 == 0) {
            return sin(2.0 * Double.pi * x / Const.periods[coeffIndex / 2])
        } else {
            return cos(2.0 * Double.pi * x / Const.periods[coeffIndex / 2])
        }
    }

    private func calcCoefficients(hr: HeartRate, dataIndex: Int) {
        let x = hr.endDatetime.timeIntervalSince(firstHR.endDatetime) + 1 //TODO: 最初の時刻が0だと崩壊するので仮に+1秒して対処(RSSEでは30秒間のデータごとに処理していたので問題にならなかった)
        updateMatrix(x: x, hr: hr)
        var copyMatrix = matrix
        for i in 0..<Const.numCoefficient {
            copyMatrix[i][i] += w(matrixI: i, matrixJ: i, x: x, dataIndex: dataIndex)
        }
        let inv = inverseMatrix(matrix: copyMatrix)
        var coefficient: [Double] = [Double](repeating: 0, count: Const.numCoefficient)
        let lastCoefficient: CoefficientHistory = coefficientHistory.last ?? .init(time: hr.endDatetime, coefficients: currentCoefficient)

        DispatchQueue.concurrentPerform(iterations: Const.numCoefficient) { [weak self] (matrixI) in
            guard let self = self else { fatalError() }

            for j in 0..<Const.numCoefficient {
                var b = self.sumY[matrixI]
                if j != Const.numCoefficient - 1 {
                    b += self.w(matrixI: j, matrixJ: j, x: x, dataIndex: dataIndex) * lastCoefficient.coefficients[j]
                }
                coefficient[matrixI] += inv[matrixI][j] * b
            }
        }

        currentCoefficient = coefficient
        coefficientHistory.append(.init(time: hr.endDatetime, coefficients: currentCoefficient))
    }

    private func updateMatrix(x: Double, hr: HeartRate) {
        for matrixI in 0..<Const.numCoefficient {
            self.sumY[matrixI] += hr.value * sincos(x: x, coeffIndex: matrixI)
            for matrixJ in matrixI..<Const.numCoefficient {
                if matrixI != Const.numCoefficient - 1, matrixJ != Const.numCoefficient - 1 {
                    let sc = sincos(x: x, coeffIndex: matrixI) * sincos(x: x, coeffIndex: matrixJ)
                    matrix[matrixI][matrixJ] += sc
                    matrix[matrixJ][matrixI] += sc / (1 + Const.alpha)
                } else {
                    matrix[matrixI][matrixJ] += sincos(x: x, coeffIndex: matrixI) * sincos(x: x, coeffIndex: matrixJ)
                    matrix[matrixJ][matrixI] = matrix[matrixI][matrixJ]
                }
            }
        }
    }

    private func inverseMatrix(matrix: [[Double]]) -> [[Double]] {
        let dimention: Int = matrix.count  //配列の次数
        guard dimention == matrix.first?.count ?? -1 else { return [[]] }
        var inv: [[Double]] = [[Double]](repeating: [Double](repeating: 0, count: dimention), count: dimention)
        var copy = matrix

        //単位行列を作る
        for i in 0..<dimention {
            inv[i][i] = 1.0
        }

        //掃き出し法
        for i in 0..<dimention {
            var maxRow = i
            var maxVal = 0.0
            for j in i..<dimention {
                if maxVal < abs(matrix[j][i]) {
                    maxVal = abs(matrix[j][i])
                    maxRow = j
                }
            }
            if i != maxRow {
                for j in 0..<dimention {
                    var tmp = copy[maxRow][j]
                    copy[maxRow][j] = copy[i][j]
                    copy[i][j] = tmp
                    tmp = inv[maxRow][j]
                    inv[maxRow][j] = inv[i][j]
                    inv[i][j] = tmp
                }
            }
            var buf = 1.0 / copy[i][i]
            for j in 0..<dimention {
                copy[i][j] *= buf
                inv[i][j] *= buf
            }
            for j in 0..<dimention {
                if i != j {
                    buf = copy[j][i]
                    for k in 0..<dimention
                    {
                        copy[j][k] -= copy[i][k] * buf
                        inv[j][k] -= inv[i][k] * buf
                    }
                }
            }
        }

        return inv
    }
}

extension DPDiagnosisModel {
    enum DiagnosisResult: String, Codable {
        case alzheimerDementiaPossibility = "alzheimerDementiaPossibility"
        case healthyPersonPossibility = "healthyPersonPossibility"
        case noResult = "noResult"
    }
}

extension DPDiagnosisModel {
    private func mockDementiaPossibilityDiagnosis() -> AnyPublisher<DiagnosisResult, Error> {
        Just(DiagnosisResult.alzheimerDementiaPossibility).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

extension DPDiagnosisModel {
    enum ModelError: Error {
        case receiveFewHeartRateData
    }
}

fileprivate struct CoefficientHistory {
    public let time: Date
    public let coefficients: [Double]
}
