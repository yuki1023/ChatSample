//
//  LogInViewController.swift
//  LineChatSample
//
//  Created by 樋口裕貴 on 2021/05/04.
//

import UIKit
import Firebase
import PKHUD

class LogInViewController: UIViewController {

    
    @IBOutlet weak var rmailTextField: UITextField!
    @IBOutlet weak var dontHaveAccountButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var LoginButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        LoginButton.layer.cornerRadius = 8

        dontHaveAccountButton.addTarget(self, action: #selector(tappedDontHaveAccountButton), for: .touchUpInside)
               LoginButton.addTarget(self, action: #selector(tappedLoginButton), for: .touchUpInside)
    }
    
    
    
    @objc private func tappedDontHaveAccountButton() {
            self.navigationController?.popViewController(animated: true)
        }
    
    
    
    @objc private func tappedLoginButton() {
        guard let email = rmailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        HUD.show(.progress)
        
        
        Auth.auth().signIn(withEmail: email, password: password) { (res, err) in
            if let err = err {
                print("ログインに失敗しました。\(err)")
                HUD.hide()
                return
            }
            
            HUD.hide()
            
            print("ログインに成功しました。")
            let nav = self.presentingViewController as! UINavigationController
            let chatListViewController = nav.viewControllers[nav.viewControllers.count-1] as? ChatListViewController
            chatListViewController?.fetchChatroomsInfoFromFirestore()
            
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
           self.view.endEditing(true)
       }


}
