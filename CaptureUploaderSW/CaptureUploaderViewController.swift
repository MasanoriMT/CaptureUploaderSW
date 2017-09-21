//
//  ViewController.swift
//  CaptureUploaderSW
//
//  Created by matoh on 2016/05/11.
//  Copyright © 2016年 ITI. All rights reserved.
//

import UIKit
import AssetsLibrary
import QBImagePicker
import ZipArchive
import Alamofire
import SVProgressHUD
import TPKeyboardAvoidingKit


private let kURLKey = "uploadURL"


class CaptureUploaderViewController: UIViewController, QBImagePickerControllerDelegate {

    @IBOutlet weak var captureWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var captureHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var urlWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var urlHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var uploadWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var uploadHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: TPKeyboardAvoidingScrollView!
    @IBOutlet weak var uploadUrlText: UITextField!
    @IBOutlet weak var versionLabel: UILabel!
    
    var keyboardDisplay: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //ボタン用の制約更新はviewDidLayoutSubviewsで行うようにする
        //self.updateConstraint(self.view.frame.size);
        
        self.uploadUrlText.text = UserDefaults.standard.string(forKey: kURLKey)
        
        let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        self.versionLabel.text = "Ver." + version
        
        SVProgressHUD.setMinimumDismissTimeInterval(0.5)
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.setDefaultMaskType(.gradient)        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(showKeyboard), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        nc.addObserver(self, selector: #selector(hideKeyboard), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let nc = NotificationCenter.default
        nc.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    open override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        // すべての向きに対応
        return .all
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        //ボタン用の制約更新はviewDidLayoutSubviewsで行うようにする
        //self.updateConstraint(size);
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // iPhone Xにも対応するようにSafeAreaを考慮
        // 具体的にはScrollViewがSafeAreaの大きさに追随するようstoryboardで設定して、ボタンの制約はScrollViewのframeにしたがって計算するようにした
        print(self.scrollView.frame)
        self.updateConstraint(self.scrollView.frame.size)
    }
    
    @IBAction func tap(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    @IBAction func selectCapture(_ sender: Any) {

        print(scrollView.contentOffset)

        let ipc = QBImagePickerController()
        ipc.delegate = self
        ipc.showsNumberOfSelectedAssets = true
        ipc.allowsMultipleSelection = true
        ipc.mediaType = .any
        
        present(ipc, animated: true, completion: nil)
    }
    
    @IBAction func uploadUrlDidEndOnExit(_ sender: Any) {
        let userDafaults = UserDefaults.standard
        userDafaults.set(self.uploadUrlText.text, forKey: kURLKey)
    }
    
    @IBAction func uploadUrlEditingDidEnd(_ sender: Any) {
    }
    
    @IBAction func uploadButtonDidTaped(_ sender: Any) {
        
        self.view.endEditing(true)

        if let urlstring = self.uploadUrlText.text {
            print(urlstring)
            
            type(of: self).upload(
                urlstring,
                fileURL: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("upload.zip"),
                progressHandler: { progress in
                    DispatchQueue.main.async() {
                        print(progress.fractionCompleted)
                        if progress.fractionCompleted >= 1.0 {
                            SVProgressHUD.dismiss()
                            return
                        }
                        SVProgressHUD.showProgress(Float(progress.fractionCompleted), status: "NOW UPLOADING...")
                    } },
                completion: { response in
                    switch response.result {
                    case .success:
                        DispatchQueue.main.async() {
                            SVProgressHUD.showSuccess(withStatus: "UPLOAD SUCCEED!!!")
                        }
                        print("Validation Successful")
                    case .failure(let error):
                        DispatchQueue.main.async() {
                            SVProgressHUD.showError(withStatus: "UPLOAD FAILED!!!")
                        }
                        print(error)
                    } }
            )
        }
        
    }

    // MARK: internal function

    func updateConstraint(_ size: CGSize) {
        
        //
        // 制約の更新
        // アップロードボタン等のコンテナとなっているUIScrollViewは、サブビューのサイズからcontentSizeを決めるため、
        // サブビュー（ボタンなど）のサイズが曖昧となるような制約が使えない
        // そこで、幅・高さを明示的に指定する制約を用意しておき、ビューコントローラのviewサイズに追随するよう制約を書き換えるようにしている
        //
        
        self.captureWidthConstraint.constant = size.width
        self.urlWidthConstraint.constant = size.width
        self.uploadWidthConstraint.constant = size.width
        
        let height = size.height / 3
        self.captureHeightConstraint.constant = height
        self.urlHeightConstraint.constant = height
        self.uploadHeightConstraint.constant = height
    }
    
    class func makeZipArhive(assets: [Any], completion: @escaping ((Bool) -> Void)) {
        
        var assetCount:Int = assets.count
        
        if (assetCount == 0) {
            completion(true)
            return
        }
        
        //
        // ZIPアーカイブの作成
        //
        
        let zippedPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("upload.zip")
        print(zippedPath.path)

        // ファイルが存在していたら削除する（存在しないとエラーになるがそれは無視）
        do {
            try FileManager.default.removeItem(at: zippedPath)
        } catch {
        }
        
        // 作成準備
        let archive = SSZipArchive.init(path:zippedPath.path)
        if !archive.open() {
            completion(false)
            return
        }
        
        // 選択された画像（PHAssetで渡されている）をZIPアーカイブに登録
        for a in assets {
            guard let asset = a as? PHAsset, let fileName = asset.value(forKey: "filename") as? String else {
                archive.close()
                completion(false)
                return
            }
            
            PHImageManager.default().requestImageData(for: asset, options: nil, resultHandler: { (imageData: Data?, dataUTI: String?, orientation: UIImageOrientation, info: [AnyHashable : Any]?) in
                
                archive.write(imageData!, filename: fileName, withPassword: nil)

                // PHImageFileURLKeyはAPI仕様上は公開されていないキーなので、利用しないのが望ましい
                //let fileURL = info!["PHImageFileURLKey"] as! URL
                //archive.write(imageData!, filename: fileURL.lastPathComponent, withPassword: nil)
                // 7zでならパスワード付きでも解凍できたが、Finderから開こうとしたらエラーとなった
                //archive.write(imageData!, filename: fileURL.lastPathComponent, withPassword: "hoge")

                assetCount -= 1
                if (assetCount == 0) {
                    archive.close()
                    completion(true)
                }
            })
        }
    }
    
    class func upload(_ urlstring: String,
                      fileURL: URL,
                      progressHandler: @escaping ((Progress) -> Void),
                      completion: @escaping (Alamofire.DataResponse<Any>) -> Swift.Void) {
        
        Alamofire.upload(
            multipartFormData: { (formData) in
                formData.append(fileURL, withName: "userfile")
            },
            to: urlstring,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.uploadProgress { progressHandler($0) }
                        .validate()
                        .responseJSON{ completion($0) }
                case .failure(let encodingError):
                    SVProgressHUD.showError(withStatus: encodingError.localizedDescription)
                    print(encodingError)
                }
            }
        )
    }
    
    // MARK: Observer method
    
    func showKeyboard() {
        self.keyboardDisplay = true
        
    }
    func hideKeyboard() {
        self.keyboardDisplay = false
        
        // TPKeyboardAvoidingScrollViewの不具合（？）に対応
        self.scrollView.contentOffset = .zero
        
    }

    // MARK: QBImagePickerControllerDelegate implementation
    
    func qb_imagePickerController(_ imagePickerController: QBImagePickerController!, didFinishPickingAssets assets: [Any]!) {
        type(of: self).makeZipArhive(assets: assets, completion: { [weak self] (result: Bool) in
            if (result) {
                self?.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    func qb_imagePickerControllerDidCancel(_ imagePickerController: QBImagePickerController!) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: UIGestureRecognizerDelegate implementation

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        // キーボード表示中のときのみTap Gestureを有効にする
        // Tap Gestureは２つのボタンにそれぞれ関連付けられていて、キーボード表示中ならキーボードを非表示にするよう振る舞う
        return self.keyboardDisplay
    }
}

