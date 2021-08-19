//
//  ChatRoomTableViewCell.swift
//  LineChatSample
//
//  Created by 樋口裕貴 on 2021/05/02.
//

import UIKit
import Firebase
import Nuke

class ChatRoomTableViewCell: UITableViewCell {
    
    
    
    //    メッセージの横幅の計算
    var message: Message?{
        didSet{
            

            
        }
        
    }
    
    
    @IBOutlet weak var userImageView: UIImageView!
    
    @IBOutlet weak var myMessageTextViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var myDateLabel: UILabel!
    @IBOutlet weak var myMessageTextView: UITextView!
    @IBOutlet weak var messageTextViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var partnerMessageTextView: UITextView!
    @IBOutlet weak var partnerDateLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        userImageView.layer.cornerRadius = 35
        partnerMessageTextView.layer.cornerRadius = 10
        myMessageTextView.layer.cornerRadius = 15
        backgroundColor = .clear
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        checkWhichUserMessage()
        // Configure the view for the selected state
    }
    
    private func checkWhichUserMessage() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if uid == message?.uid {
            partnerMessageTextView.isHidden = true
            partnerDateLabel.isHidden = true
            userImageView.isHidden = true
            
            myMessageTextView.isHidden = false
            myDateLabel.isHidden = false
            
            
            

            if let message = message {
               myMessageTextView.text = message.message
                let width = estimateFrameForTextView(text: message.message).width + 20
                myMessageTextViewWidthConstraint.constant = width
                
                myDateLabel.text = dateFormatterForDateLabel(date: message.createdAt.dateValue())
                //                userImageView.image =
                
            }
            
            
        }else{
            
            partnerMessageTextView.isHidden = false
            partnerDateLabel.isHidden = false
            userImageView.isHidden = false
            
            myMessageTextView.isHidden = true
            myDateLabel.isHidden = true
            
            if let urlString = message?.partnerUser?.profileImageUrl, let url = URL(string: urlString) {
                            Nuke.loadImage(with: url, into: userImageView)
                        }
            
            if let message = message {
                partnerMessageTextView.text = message.message
                let width = estimateFrameForTextView(text: message.message).width + 20
                messageTextViewWidthConstraint.constant = width
                
                partnerDateLabel.text = dateFormatterForDateLabel(date: message.createdAt.dateValue())
                //                userImageView.image =
                
            }
            
        }
        
        
        
        
    }
    
    //    文字の量に合わせて自動でテキストビューの大きさを変えてくれる
    private func estimateFrameForTextView(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    
    
    private func dateFormatterForDateLabel(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
