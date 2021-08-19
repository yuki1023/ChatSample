//
//  ChatInputAccessory.swift
//  LineChatSample
//
//  Created by 樋口裕貴 on 2021/05/02.
//

import UIKit

//デリゲートの定義
protocol ChatInputAccessoryDelegate: class {
    func tappedSendButton(text: String)
}

class ChatInputAccessory: UIView {
    
//    デリゲートのセット
    @IBAction func tappedSendButton(_ sender: Any) {
        guard let text = chatTextView.text else { return }
//        上のメソッドを入れてあげた
        delegate?.tappedSendButton(text: text)
    }
    
//    デリゲート宣言
    weak var delegate: ChatInputAccessoryDelegate?
    
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var chatTextView: UITextView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        nibInit()
        setupViews()
        autoresizingMask = .flexibleHeight
    }
    
    
    
    private func setupViews() {
        chatTextView.layer.cornerRadius = 15
        chatTextView.layer.borderColor = #colorLiteral(red: 0.9019607843, green: 0.9019607843, blue: 0.9019607843, alpha: 1)
        chatTextView.layer.borderWidth = 1
        
        sendButton.layer.cornerRadius = 15
        
//        ボタンの中の画像の調整
        sendButton.imageView?.contentMode = .scaleAspectFill
        sendButton.contentHorizontalAlignment = .fill
        sendButton.contentVerticalAlignment = .fill
        sendButton.isEnabled = false
        
        chatTextView.text = ""
        
//        文字を打ったことを認識させる
        chatTextView.delegate = self
    }
    
    
    func removeText() {
        chatTextView.text = ""
        sendButton.isEnabled = false
    }
    
    override var intrinsicContentSize: CGSize {
           return .zero
       }
    
    required init?(coder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }
    
    
    private func nibInit() {
        let nib = UINib(nibName: "ChatInputAccessory", bundle: nil)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        
        //        viewのフレームを決める
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(view)
    }
    
    
}


extension ChatInputAccessory:UITextViewDelegate{
    
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty {
            sendButton.isEnabled = false
        } else {
            sendButton.isEnabled = true
        }
    }
    
}
