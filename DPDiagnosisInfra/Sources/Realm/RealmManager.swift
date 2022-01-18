import Combine
import RealmSwift

public class RealmManager {
    public static let shared = RealmManager()
    private var config: Realm.Configuration

    private init() {
        self.config = Realm.Configuration(schemaVersion: 2)

        DispatchQueue(label: "background").async {
            do {
                // migration
                _ = try Realm(configuration: self.config)
            } catch let error as NSError {
                print(error)
            }
        }
    }

    public func add<T: Object>(_ data: [T]) -> AnyPublisher<Void, Error> {
        do {
            let realm = try Realm(configuration: config)

            try realm.write {
                realm.add(data)
            }
            return Just(Void())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch let error as NSError {
            print(error)
            return Fail<Void, Error>(error: ManagerError.dontProcessBecauseRealmIsNil)
                .eraseToAnyPublisher()
        }
    }

    public func update<T: Object>(_ data: [T], rewriteProcess: (([T]) -> Void)? = nil) -> AnyPublisher<Void, Error> {
        do {
            let realm = try Realm(configuration: config)

            try realm.write {
                rewriteProcess?(data)
                realm.add(data, update: .modified)
            }
            return Just(Void())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch let error as NSError {
            print(error)
            return Fail<Void, Error>(error: ManagerError.dontProcessBecauseRealmIsNil)
                .eraseToAnyPublisher()
        }
    }

    public func query<T: Object>(targetType: T.Type) -> AnyPublisher<Results<T>, Error> {
        do {
            let realm = try Realm(configuration: config)

            return Just(realm.objects(targetType))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch let error as NSError {
            print(error)
            return Fail<Results<T>, Error>(error: ManagerError.dontProcessBecauseRealmIsNil)
                .eraseToAnyPublisher()
        }
    }

    public func query<T: Object>(targetType: T.Type, predicate: NSPredicate) -> AnyPublisher<Results<T>, Error> {
        do {
            let realm = try Realm(configuration: config)

            return Just(realm.objects(targetType).filter(predicate))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch let error as NSError {
            print(error)
            return Fail<Results<T>, Error>(error: ManagerError.dontProcessBecauseRealmIsNil)
                .eraseToAnyPublisher()
        }
    }

    public func query<T: Object>(targetType: T.Type, primaryKey: String) -> AnyPublisher<T?, Error> {
        do {
            let realm = try Realm(configuration: config)

            return Just(realm.object(ofType: targetType, forPrimaryKey: primaryKey))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch let error as NSError {
            print(error)
            return Fail<T?, Error>(error: ManagerError.dontProcessBecauseRealmIsNil)
                .eraseToAnyPublisher()
        }
    }

    public func delete<T: Object>(_ data: [T]) -> AnyPublisher<Void, Error> {
        do {
            let realm = try Realm(configuration: config)

            try realm.write {
                realm.delete(data)
            }
            return Just(Void())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch let error as NSError {
            print(error)
            return Fail<Void, Error>(error: ManagerError.dontProcessBecauseRealmIsNil)
                .eraseToAnyPublisher()
        }
    }
}

extension RealmManager {
    public enum ManagerError: Error {
        case dontProcessBecauseRealmIsNil
        case notFoundRecord
        case couldNotFoundSelf
    }
}
