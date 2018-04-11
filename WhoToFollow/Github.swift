import Foundation
import Moya

enum GitHub {
    case users(since: Int)
}

extension GitHub: TargetType {
    var baseURL: URL { return URL(string: "https://api.github.com")! }
    var path: String {
        switch self {
        case .users:
            return "/users"
        }
    }
    var method: Moya.Method {
        return .get
    }
    var sampleData: Data {
        return "".data(using: String.Encoding.utf8)!
    }
    var headers: [String : String]? {
        return nil
    }
    var task: Task {
        switch self {
        case .users(let since):
            return .requestParameters(parameters: ["since": since], encoding: URLEncoding.default)
        }
    }
}
