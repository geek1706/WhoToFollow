import UIKit
import RxSwift
import RxCocoa
import Moya

class FollowTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var refresh: UIBarButtonItem!
    
    var disposeBag = DisposeBag()
    var provider = MoyaProvider<GitHub>()
    var dataSource = [User]()
    var responseStream: Observable<[User]> = Observable.just([])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 70.0
        
        rxBind()
    }
    
    func rxBind() {
        let requestStream: Observable<Int> = refresh.rx.tap.startWith(()).map { _ in
            Array(1...1000).random()
        }
        responseStream = requestStream.flatMap { since in
            UserModel(provider: self.provider).findUsers(since: since)
        }
    }
}

extension FollowTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FollowCell", for: indexPath) as! FollowTableViewCell
        cell.cancel.showsTouchWhenHighlighted = true
        cell.avatar.layer.cornerRadius = cell.avatar.frame.size.width / 2
        cell.avatar.clipsToBounds = true
        
        let closeStream = cell.cancel.rx.tap.startWith(())
        let userStream: Observable<User?> = Observable.combineLatest(
            closeStream,
            responseStream)
        { (_, users) in
            guard users.count > 0 else { return nil }
            return users.random()
        }
        
        let nilOnRefreshTapStream: Observable<User?> = refresh.rx.tap.map {_ in return nil}
        let suggestionStream = Observable.of(userStream, nilOnRefreshTapStream)
            .merge()
            .startWith(.none)
        
        suggestionStream.subscribe(
            onNext: { user in
                guard let u = user else { return self.clearCell(cell) }
                return self.setCell(cell, user: u)
        })
            .disposed(by: cell.disposeBagCell)
        
        return cell
    }
    
    func clearCell(_ cell: FollowTableViewCell) {
        cell.cancel.isHidden = true
        cell.avatar.image = nil
        cell.name.text = nil
    }
    
    func setCell(_ cell: FollowTableViewCell, user: User) {
        clearCell(cell)
        guard let url = URL(string: user.avatarUrl) else { return }
        
        DispatchQueue.global().async {
            let data = try! Data(contentsOf: url)
            DispatchQueue.main.async {
                cell.cancel.isHidden = false
                cell.avatar.image = UIImage(data: data)
                cell.name.text = user.name
            }
        }
    }
}

extension FollowTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

