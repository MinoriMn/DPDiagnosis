import Combine
import Foundation
import SwiftCSV

final class CsvFileProvider {
    public func loadCsv(fileName: String) -> AnyPublisher<CSV, Error> {
        return Future<CSV, Error> { promise in
            do {
                let dir = FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                ).first!
                let fileUrl = dir.appendingPathComponent(fileName)

                let csv: CSV = try CSV(url: fileUrl)
                promise(.success(csv))
                print("success to load csv:", fileUrl)
                return
            } catch let parseError as CSVParseError {
                promise(.failure(parseError))
                print("failed to load csv:", parseError)
                return
            } catch let error {
                promise(.failure(error))
                print("failed to load csv:", error)
                return
            }
        }
        .eraseToAnyPublisher()
    }

    public func saveCsv(csvString: String, fileName: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            do {
                let dir = FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                ).first!
                let fileUrl = dir.appendingPathComponent(fileName)

                if !FileManager.default.fileExists(atPath: fileUrl.path) {
                    FileManager.default.createFile(
                        atPath: fileUrl.path,
                        contents: csvString.data(using: .utf8),
                        attributes: nil
                    )
                } else {
                    try csvString.write(to: fileUrl, atomically: false, encoding: String.Encoding.utf8)
                }

                print("success to save csv:", fileUrl)
                promise(.success(Void()))
                return
            } catch let error {
                print("failed to save csv:", error)
                promise(.failure(error))
                return
            }
        }
        .eraseToAnyPublisher()
    }

    public func saveCsv(labels: [String], data: [[String]], fileName: String) -> AnyPublisher<Void, Error> {
        guard let dataFirst = data.first,
              labels.count == dataFirst.count else {
                  print(labels)
                  print(data[0])
                  print(data.count)
                  print(fileName)
                  return Fail(error: ProviderError.invalidColumnNum).eraseToAnyPublisher()
              }

        var lines: [String] = [labels.joined(separator: ",")]
        for row in data {
            lines.append(row.joined(separator: ","))
        }
        let csvString = lines.joined(separator: "\n")

        return saveCsv(csvString: csvString, fileName: fileName)
    }
}

extension CsvFileProvider {
    enum ProviderError: Error {
        case invalidColumnNum
    }
}
