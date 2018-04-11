import Foundation
import RxSwift
import RxOptional
import Moya
import Moya_ModelMapper

struct UserModel {
    let provider: MoyaProvider<GitHub>
    
    func findUsers(since: Int) -> Observable<[User]> {
        return provider.rx.request(GitHub.users(since: since))
        .debug()
        .mapOptional(to: [User].self)
        .asObservable()
        .replaceNilWith([])
    }
}
