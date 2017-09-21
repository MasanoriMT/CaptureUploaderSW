//
//  CaptureUploaderSWTests.swift
//  CaptureUploaderSWTests
//
//  Created by matoh on 2016/05/11.
//  Copyright © 2016年 ITI. All rights reserved.
//

import XCTest
@testable import CaptureUploaderSW

import OHHTTPStubs

class CaptureUploaderSWTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testUploadSuccess() {
        let exp = expectation(description: "upload file")

        // 正常終了を返す通信スタブをセットアップ
        let stub:NSDictionary = ["result": true]
        OHHTTPStubs.stubRequests(
            passingTest: { (request: URLRequest!) -> Bool in
                print(request)
                return true
            },
            withStubResponse:
            { (request: URLRequest!) -> OHHTTPStubsResponse in
                return OHHTTPStubsResponse(jsonObject: stub, statusCode: 200, headers: ["Content-Type" : "text/json"]) // fix
            }
        )
        
        // アップロード処理
        if let path = Bundle(for: type(of: self)).path(forResource: "Screen-Shot", ofType: "png") {
            let fileURL = URL(fileURLWithPath: path)
            CaptureUploaderViewController.upload(
                "http://success/upload.php",
                fileURL: fileURL,
                progressHandler: { progress in print(progress.fractionCompleted) },
                completion:
                { response in
                    // 処理結果をこのクロージャで受け取る
                    switch response.result {
                    case .success:
                        print("Validation Successful: \(String(data: response.data!, encoding: .utf8)!)")
                    case .failure:
                        XCTFail()
                    }
                    exp.fulfill()
                }
            )
        }
        
        waitForExpectations(timeout: 5.0, handler: {(error) -> Void in
            OHHTTPStubs.removeAllStubs()
            return
        })

    }

    func testUploadError() {
        let exp = expectation(description: "upload file(error)")
        
        // エラーを返す通信スタブをセットアップ
        let stub:NSDictionary = ["result": false]
        OHHTTPStubs.stubRequests(
            passingTest: { (request: URLRequest!) -> Bool in
                print(request)
                return true
            },
            withStubResponse:
            { (request: URLRequest!) -> OHHTTPStubsResponse in
                return OHHTTPStubsResponse(jsonObject: stub, statusCode: 400, headers: ["Content-Type" : "text/json"])
            }
        )
        
        // アップロード処理
        if let path = Bundle(for: type(of: self)).path(forResource: "Screen-Shot", ofType: "png") {
            let fileURL = URL(fileURLWithPath: path)
            CaptureUploaderViewController.upload(
                "http://error/upload.php",
                fileURL: fileURL,
                progressHandler: { progress in print(progress.fractionCompleted) },
                completion:
                { response in
                    // 処理結果をこのクロージャで受け取る
                    switch response.result {
                    case .success:
                        XCTFail()
                    case .failure(let error):
                        print("Error Response: \(String(data: response.data!, encoding: .utf8)!)")
                        print(error)
                    }
                    exp.fulfill()
                }
            )
        }
        
        waitForExpectations(timeout: 5.0, handler: {(error) -> Void in
            OHHTTPStubs.removeAllStubs()
            return
        })
    }

}
