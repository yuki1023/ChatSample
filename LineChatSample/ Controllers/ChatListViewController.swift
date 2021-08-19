//
//  ChatListViewController.swift
//  LineChatSample
//
//  Created by 樋口裕貴 on 2021/05/01.
//
import UIKit
import Firebase
import Nuke

class ChatListViewController: UIViewController {
    
    
    private let cellId = "cellId"
    private var chatrooms = [ChatRoom]()
    private var chatRoomListener : ListenerRegistration?
    
    private var user : User?{
        
        didSet{
            navigationItem.title = user?.username
            
        }
        
    }
    
    //    private var users = [User]()
    
    @IBOutlet weak var chatListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupViews()
        confirmLoggedInUser()
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchLoginUserInfo()
        fetchChatroomsInfoFromFirestore()
        
    }
    
    
    
    func fetchChatroomsInfoFromFirestore() {
        
        chatRoomListener?.remove()
        chatrooms.removeAll()
        chatListTableView.reloadData()
        
        chatRoomListener = Firestore.firestore().collection("chatRooms")
            .addSnapshotListener { [self] (snapshots, err) in
                if let err = err {
                    print("ChatRooms情報の取得に失敗しました。\(err)")
                    return
                }
                
                snapshots?.documentChanges.forEach({ (documentChange) in
                    switch documentChange.type {
                    case .added:
                        
                        self.handleAddedDocumentChange(documentChange: documentChange)
                        
                    case .modified, .removed:
                        print("nothing to do")
                    }
                    
                })
                
                
                
            }
    }
    
    private func handleAddedDocumentChange(documentChange: DocumentChange) {
        
        let dic = documentChange.document.data()
        let chatroom = ChatRoom(dic: dic)
        chatroom.documentId = documentChange.document.documentID
        
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let isContain = chatroom.memebers.contains(uid)
        
        //        含まれてない時はここでリターン
        if !isContain {return}
        
        chatroom.memebers.forEach { (memberUid) in
            if memberUid != uid {
                
                Firestore.firestore().collection("users").document(memberUid).getDocument { (usersnapshot, err) in
                    if let err = err{
                        print("ユーザ情報の取得に失敗しました", err)
                        return
                    }
                    
                    
                    
                    guard let dic = usersnapshot?.data() else {return}
                    let user = User(dic: dic)
                    user.uid = documentChange.document.documentID
                    chatroom.partnerUser = user
                    //                    print(user.username)
                    
                    guard let chatroomId = chatroom.documentId else { return }
                    let latestMessageId = chatroom.latestMessageId 
                    
                    if latestMessageId == "" {
                        self.chatrooms.append(chatroom)
                        self.chatListTableView.reloadData()
                        return
                    }
                    
                    
                    Firestore.firestore().collection("chatRooms").document(chatroomId).collection("messages").document(latestMessageId).getDocument { (messageSnapshot, err) in
                        
                        if let err = err {
                            print("最新情報の取得に失敗しました。\(err)")
                            return
                        }
                        
                        guard let dic = messageSnapshot?.data() else { return }
                        let message = Message(dic: dic)
                        
                        print(message)
                        chatroom.latestMessage = message
                        self.chatrooms.append(chatroom)
                        
                        self.chatListTableView.reloadData()
                        
                    }
                }
            }
            
            
        }
    }
    
    
    private func setupViews() {
        chatListTableView.tableFooterView = UIView()
        chatListTableView.delegate = self
        chatListTableView.dataSource = self
        
        
        //        ナビゲーションのカスタム
        navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        navigationItem.title = "トーク"
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        let rightbarButton = UIBarButtonItem(title: "新規チャット", style: .plain, target: self, action: #selector (tappedNavRightBarButton))
        let logoutBarButton = UIBarButtonItem(title: "ログアウト", style: .plain, target: self, action: #selector(tappedLogoutButton))
        navigationItem.rightBarButtonItem = rightbarButton
        navigationItem.rightBarButtonItem?.tintColor = .white
        navigationItem.leftBarButtonItem = logoutBarButton
        navigationItem.leftBarButtonItem?.tintColor = .white
        
    }
    
    @objc private func tappedLogoutButton() {
        do {
            try Auth.auth().signOut()
            pushLoginViewController()
        } catch {
            print("ログアウトに失敗しました。 \(error)")
        }
    }
    
    @objc private func tappedNavRightBarButton() {
        
        let storyBoard = UIStoryboard.init(name: "UserList", bundle: nil)
        let userListViewController = storyBoard.instantiateViewController(identifier: "UserListViewController")
        let nav = UINavigationController(rootViewController: userListViewController)
        
        self.present(nav, animated: true, completion: nil)
        
        
    }
    
    private func confirmLoggedInUser() {
        if Auth.auth().currentUser?.uid == nil{
            
            pushLoginViewController()
        }
    }
    
    private func pushLoginViewController(){
        
        let storyBoard = UIStoryboard(name: "SignUp", bundle: nil)
        let signUpViewController = storyBoard.instantiateViewController(identifier: "SignUpViewController") as! SignUpViewController
        let nav = UINavigationController(rootViewController: signUpViewController)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
        
        
        
    }
    
    
    private func fetchLoginUserInfo() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users").document(uid).getDocument { (snapshot, err) in
            if let err = err {
                print("ユーザー情報の取得に失敗しました。\(err)")
                return
            }
            
            guard let snapshot = snapshot, let dic = snapshot.data() else { return }
            
            let user = User(dic: dic)
            self.user = user
        }
    }
    
    
    
    
}


extension  ChatListViewController :UITableViewDataSource,UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(chatrooms.count)
        return chatrooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = chatListTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ChatListTableViewCell
        
        //        cell.user = users[indexPath.row]
        print(chatrooms[indexPath.row].documentId)
        cell.chatroom = chatrooms[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //        ストーリボードをつなげる
        let storyboard = UIStoryboard.init(name: "ChatRoom", bundle: nil)
        let chatRoomViewController = storyboard.instantiateViewController(identifier: "ChatRoomViewController") as! ChatRoomViewController
        chatRoomViewController.user = user
        chatRoomViewController.chatRoom = chatrooms[indexPath.row]
        
        
        navigationController?.pushViewController(chatRoomViewController, animated: true)
    }
    
    
    
    
    
}


class ChatListTableViewCell:UITableViewCell{
    
    
    var chatroom: ChatRoom? {
        didSet{
            if let chatroom = chatroom {
                partnerLabel.text = chatroom.partnerUser?.username
                
                guard let url = URL(string: chatroom.partnerUser?.profileImageUrl ?? "") else { return }
                Nuke.loadImage(with: url, into: userImageView)
                
                dateLabel.text = dateFormatterForDateLabel(date: chatroom.latestMessage?.createdAt.dateValue() ?? Date())
                //                               latestMessageLabel.text = chatroom.latestMessage?.message
                latestMssageLabel.text = chatroom.latestMessage?.message
                
            }
            
        }
        
    }
    
    @IBOutlet weak var partnerLabel: UILabel!
    @IBOutlet weak var latestMssageLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userImageView.layer.cornerRadius = 30
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    //    dateLabelの表示の仕方の変更
    private func dateFormatterForDateLabel(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)    }
    
    
}
