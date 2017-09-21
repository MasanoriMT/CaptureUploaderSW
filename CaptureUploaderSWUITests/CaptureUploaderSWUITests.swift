//
//  CaptureUploaderSWUITests.swift
//  CaptureUploaderSWUITests
//
//  Created by matoh on 2016/05/11.
//  Copyright © 2016年 ITI. All rights reserved.
//

import XCTest

extension XCUIElement {
    /**
     Removes any current text in the field before typing in the new value
     - Parameter text: the text to enter into the field
     */
    func clearAndEnterText(text: String) -> Void {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        
        self.tap()
        
        var deleteString: String = ""
        for _ in stringValue.characters {
            deleteString += "\u{8}"
        }
        self.typeText(deleteString)
        
        self.typeText(text)
        self.typeText("\n")
    }
    
    func forceTapElement() {
        if self.isHittable {
            self.tap()
        }
        else {
            let coordinate: XCUICoordinate = self.coordinate(withNormalizedOffset: CGVector(dx:0.0, dy:0.0))
            coordinate.tap()
        }
    }
}

class CaptureUploaderSWUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        snapshot("1-Launch")
        
        let app = XCUIApplication()
        
        // キャプチャー選択
        // (accessibility identifierを利用）
        app.buttons["capture"].tap()
        snapshot("2-ImagePicker")

        // カメラロール
        // 1行目がカメラロールであることに依存している
        app.tables.element(boundBy: 0).cells.element(boundBy: 0).tap()
        snapshot("3-CameraRole")

        // 画像選択
        app.collectionViews.cells.element(boundBy: 0).forceTapElement()
        app.collectionViews.cells.element(boundBy: 2).forceTapElement()
        
        // 完了ボタン
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 1).tap()

        /*
         完了ボタンをラベルで探すとしたら以下のような感じになるか。。。
         候補と成り得るキャプションを配列で用意してループで回すなど、多少は工夫できるだろう
        var doneButton: XCUIElement
        doneButton = app.navigationBars.elementBoundByIndex(0).buttons["完了"]
        if (doneButton.exists) {
            doneButton.tap()
        }
        doneButton = app.navigationBars.elementBoundByIndex(0).buttons["Done"]
        if (doneButton.exists) {
            doneButton.tap()
        } */
        
        // URL入力
        app.textFields["urltext"].clearAndEnterText(text: "http://localhost/upload.php")
        
        // アップロード
        // (accessibility identifierを利用）
        app.buttons["upload"].tap()
        
        // 少々待機
        let exp = expectation(description: "upload file")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            snapshot("4-Upload")
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5.0, handler: {(error) -> Void in
            return
        })
        
        /*
         アップロードが完了するまで待機したかったが思ったように機能しなかった
        let label = app.staticTexts["UPLOAD SUCCEED!!!"]
        let existsPredicate = NSPredicate(format: "exists == true")
        
        expectationForPredicate(existsPredicate, evaluatedWithObject: label, handler: nil)
        waitForExpectationsWithTimeout(5, handler: nil) */

    }
    
}
