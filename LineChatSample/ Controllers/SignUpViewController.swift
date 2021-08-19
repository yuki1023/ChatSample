//
//  SignUpViewController.swift
//  LineChatSample
//
//  Created by 樋口裕貴 on 2021/05/02.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import PKHUD

class SignUpViewController: UIViewController {
    
    
    @IBOutlet weak var profileImageButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var alreadyHaveAccountButton: UIButton!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setUpViews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isHidden = true
    }
    
    private func setUpViews(){
        
        profileImageButton.layer.cornerRadius = 85
        profileImageButton.layer.borderWidth = 1
        profileImageButton.layer.borderColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        
        registerButton.layer.cornerRadius = 15
        // Do any additional setup after loading the view.
        profileImageButton.addTarget(self, action: #selector(tappedProfileImageButton), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(tappedregisterButton), for: .touchUpInside)
        alreadyHaveAccountButton.addTarget(self, action: #selector(tappedalreadyHaveAccountButton), for: .touchUpInside)
        
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        userNameTextField.delegate = self
        
        registerButton.isEnabled = false
        registerButton.backgroundColor = #colorLiteral(red: 0.3921568627, green: 0.3921568627, blue: 0.3921568627, alpha: 1)
        
    }
    
    
    
    @objc private func tappedalreadyHaveAccountButton(){
        
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(identifier: "LogInViewController")
        self.navigationController?.pushViewController(loginViewController, animated: true)
        
        
    }
    //    ユーザーの会員登録
    @objc private func tappedregisterButton(){
        
        //        画像をストレージに保存する
        let image = profileImageButton.imageView?.image ?? UIImage(named: "miria")
        //        容量0.3　データ型に変換
        guard let uploadImage = image?.jpegData(compressionQuality: 0.3) else { return }
        
        
        HUD.show(.progress)
        
        let fileName = NSUUID().uuidString
        //        ストレージへのレファレンス
        //child("profile_image")が大元
        let storageRef = Storage.storage().reference().child("profile_image").child(fileName)
        
        //        ストレージに保存する
        storageRef.putData(uploadImage, metadata: nil) { (matadata, err) in
            if let err = err {
                print("Firestorageへの情報の保存に失敗しました。\(err)")
                HUD.hide()
                return
            }
            
            print("Firestorageへの情報の保存に成功しました。")
            
            //            ストレージに保存が成功した後、データベースにも保存する
            storageRef.downloadURL { (url, err) in
                if let err = err {
                    print("Firestorageからのダウンロードに失敗しました。\(err)")
                    HUD.hide()
                    return
                }
                //                urlをstringに変換
                guard let urlString = url?.absoluteString else { return }
                self.createUserToFirestore(profileImageUrl: urlString)
                //                print("urlString",urlString)
            }
        }
        
    }
    
    private func createUserToFirestore(profileImageUrl : String){
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        
        Auth.auth().createUser(withEmail: email, password: password) { [self] (res, err) in
            if err != nil{
                //                print("Authの保存に失敗しました。",err)
                HUD.hide()
                return
            }else{
                //                print("成功")
                guard let uid = res?.user.uid else {return}
                guard let userName = userNameTextField.text else { return }
                
                //                辞書型でデータを作る
                let docData = [
                    "email":email,
                    "username":userName,
                    "createDate":Timestamp(),
                    "profileImageUrl": profileImageUrl
                ] as [String:Any]
                
                //                データベースへの保存
                //                uidはuserId
                Firestore.firestore().collection("users").document(uid).setData(docData){
                    (err) in
                    if let err = err{
                        print("失敗",err)
                        HUD.hide()
                        return
                    }else{
                        
                        print("Firestore成功")
                        HUD.hide()
                        self.dismiss(animated: true, completion: nil)
                    }
                    
                }
            }
        }
    }
    
    @objc private func tappedProfileImageButton(){
        
        print("a")
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        
        //        写真の編集が可能になる
        imagePickerController.allowsEditing = true
        
        self.present(imagePickerController, animated: true, completion: nil)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    
}

//選択した後の動き
extension SignUpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //        編集した写真
        if let editImage = info[.editedImage] as? UIImage{
            profileImageButton.setImage(editImage.withRenderingMode(.alwaysOriginal), for: .normal)
            //            編集していない写真
        }else if let originalImage = info[.editedImage] as? UIImage{
            profileImageButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
        
        profileImageButton.setTitle("", for: .normal)
        //        マル淵に写真を合わせる
        profileImageButton.imageView?.contentMode = .scaleAspectFill
        profileImageButton.contentHorizontalAlignment = .fill
        profileImageButton.contentVerticalAlignment = .fill
        profileImageButton.clipsToBounds = true
        
        dismiss(animated: true, completion: nil)
    }
    
    
    
    
}




extension SignUpViewController: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        let emailIsEmpty = emailTextField.text?.isEmpty ?? false
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? false
        let usernameIsEmpty = userNameTextField.text?.isEmpty ?? false
        
        if emailIsEmpty || passwordIsEmpty || usernameIsEmpty {
            registerButton.isEnabled = false
            registerButton.backgroundColor = #colorLiteral(red: 0.3921568627, green: 0.3921568627, blue: 0.3921568627, alpha: 1)
        } else {
            registerButton.isEnabled = true
            registerButton.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        }
    }
    
}
