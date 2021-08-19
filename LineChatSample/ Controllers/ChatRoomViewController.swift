//
//  ChatRoomViewController.swift
//  LineChatSample
//
//  Created by 樋口裕貴 on 2021/05/02.
//

import UIKit
import Firebase

class ChatRoomViewController : UIViewController  {
    
    @IBOutlet weak var chatRoomTableView: UITableView!
    
    var user :User?
    
    private var messages = [Message]()
    var chatRoom: ChatRoom?
    private let cellId = "cellId"
    private let accessoryHeight: CGFloat = 100
    
    private let tableViewContentInset: UIEdgeInsets = .init(top: 60, left: 0, bottom: 0, right: 0)
    private let tableViewIndicatorInset: UIEdgeInsets = .init(top: 60, left: 0, bottom: 0, right: 0)
    
    private var safeAreaBottom: CGFloat {
        self.view.safeAreaInsets.bottom
    }
    
//    キーボードを出した時に自動的に上下してくれる。テキスト入力の時は必須。
    private lazy var chatInputAccessoryView: ChatInputAccessory = {
           let view = ChatInputAccessory()
           view.frame = .init(x: 0, y: 0, width: view.frame.width, height: 100)
           
//        デリゲートの呼び出し
        view.delegate = self
        
           return view
       }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        fetchMessages()
        setupNotification()
        setupChatRoomTableView()
        
        
    }
    
    private func setupNotification() {
          NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
          NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
      }
    
    
    private func setupChatRoomTableView() {
     
        chatRoomTableView.delegate = self
        chatRoomTableView.dataSource = self
        chatRoomTableView.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        let nib = UINib(nibName: "ChatRoomTableViewCell", bundle: nil)
        chatRoomTableView.register(nib, forCellReuseIdentifier: cellId)
        
        chatRoomTableView.keyboardDismissMode = .interactive
        
        chatRoomTableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        
//        下が見切れないように
//        chatRoomTableView.contentInset = .init(top: 60, left: 0, bottom: 0, right: 0)
//        chatRoomTableView.scrollIndicatorInsets = .init(top: 60, left: 0, bottom: 0, right: 0)
//
        
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        
        guard let userInfo = notification.userInfo else { return }
        
        if let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue {
            
            if keyboardFrame.height <= accessoryHeight { return }
            
            let top = keyboardFrame.height - safeAreaBottom
            let contentInset = UIEdgeInsets(top: top, left: 0, bottom: 0, right: 0)
            
            
            var moveY = -(top - chatRoomTableView.contentOffset.y)
            
            
            // 最下部意外の時は少しずれるので微調整
            if chatRoomTableView.contentOffset.y != -60 { moveY += 60 }
            
            chatRoomTableView.contentInset = contentInset
            chatRoomTableView.scrollIndicatorInsets = contentInset
            chatRoomTableView.contentOffset = CGPoint(x: 0, y: moveY)
            
        }
        
    }
    
    @objc func keyboardWillHide() {
            chatRoomTableView.contentInset = tableViewContentInset
            chatRoomTableView.scrollIndicatorInsets = tableViewIndicatorInset
        }
        
    
    
    
//    ここむずい
    override var inputAccessoryView: UIView?{
        get {
            return chatInputAccessoryView
        }
        
    }
    
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
    
    private func fetchMessages() {
            guard let chatroomDocId = chatRoom?.documentId else { return }
            
        Firestore.firestore().collection("chatRooms").document(chatroomDocId).collection("messages").addSnapshotListener { (snapshots, err) in
                
                if let err = err {
                    print("メッセージ情報の取得に失敗しました。\(err)")
                    return
                }
            
            
            snapshots?.documentChanges.forEach({ (documentChange) in
                        switch documentChange.type {
                        case .added:
                            let dic = documentChange.document.data()
//                            print("messagedic" , dic)
                            
                            let message = Message(dic: dic)
                            
                            
                            message.partnerUser = self.chatRoom?.partnerUser

                            self.messages.append(message)
                            
//                            ソート
                            self.messages.sort { (m1, m2) -> Bool in
                                let m1Date = m1.createdAt.dateValue()
                                let m2Date = m2.createdAt.dateValue()
                                return m1Date > m2Date
                            }

                            self.chatRoomTableView.reloadData()
//
//                            self.chatRoomTableView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .bottom, animated: true)
                            
                        case .modified, .removed:
                            print("nothing to do")
                        }
                    })
            
        }
        
    }
    
    
    
}

extension ChatRoomViewController: ChatInputAccessoryDelegate {
    
    func tappedSendButton(text: String) {

        addMessageToFirestore(text: text)
        
        
    }
    
    
    private func addMessageToFirestore(text: String) {
        
        guard let name = user?.username else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        chatInputAccessoryView.removeText()
        let messageId = randomString(length: 20)
        
        let docData = [
            "name": name,
            "createdAt": Timestamp(),
            "uid": uid,
            "message": text
            ] as [String : Any]
        
        guard let chatroomDocId = chatRoom?.documentId else {return}
        
        Firestore.firestore().collection("chatRooms").document(chatroomDocId).collection("messages").document(messageId).setData(docData) { [self](err) in
            if let err = err{
                print("メッセージの保存に失敗しました", err)
                return
            }
            
            
            let latestMessageData = [
                            "latestMessageId": messageId
                        ]
            
//            改めてセット
            Firestore.firestore().collection("chatRooms").document(chatroomDocId).updateData(latestMessageData) { (err) in
                if let err = err{
                    print("最新メッセージの保存に失敗しました")
                    return
                }
            
            
            print("メッセージの保存に成功しました")
            
            }
        }
        
        
        
    }
    
    func randomString(length: Int) -> String {
            let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            let len = UInt32(letters.length)

            var randomString = ""
            for _ in 0 ..< length {
                let rand = arc4random_uniform(len)
                var nextChar = letters.character(at: Int(rand))
                randomString += NSString(characters: &nextChar, length: 1) as String
            }
            return randomString
        }
    
    
    

}

extension  ChatRoomViewController :UITableViewDataSource,UITableViewDelegate {
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        最低基準の高さ
        chatRoomTableView.estimatedRowHeight = 20
        return UITableView.automaticDimension
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = chatRoomTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ChatRoomTableViewCell
//        cell.messageTextView.text = messages[indexPath.row]
        
        cell.message = messages[indexPath.row]
        
        cell.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        return cell
    }
    
    
    
    
}

