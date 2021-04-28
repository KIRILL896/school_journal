//
//  APIClient.swift
//  scool_journal
//
//  Created by отмеченные on 16/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//
import Foundation
import RxSwift
import Alamofire
import SwiftyJSON






class APIClient: APIClientType {

    
    private let session_manager:Session
    
    
    
    
    //private let sessionManager: SessionManager

    init(sessionConfiguration: URLSessionConfiguration? = nil) {
        if let config = sessionConfiguration {
            
            
            
            session_manager = Alamofire.Session(configuration:config)
            
            
            //sessionManager = Alamofire.SessionManager(configuration: config)
            
            
        
            
            
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 20  // seconds
            configuration.timeoutIntervalForResource = 20 // seconds
            session_manager = Alamofire.Session(configuration:configuration)

            
            //sessionManager = Alamofire.SessionManager(configuration: configuration)
        }
    }

    func perform(request: APIRequest) -> Single<Data> {
        guard let url = URL(string: request.baseURL + request.path) else {
            return .error(APIError.wrongURL(url: request.baseURL + request.path))
        }

        return Single<Data>.create { single in
            if Constants.debugNetwork {
                print("URL:\(request.baseURL + request.path)")
            }

            CrashlyticsHelper.setApiUrl(request.baseURL + request.path)
            
            
            
            
            
            

            
            let request = self.session_manager.request(
                url,
                method: request.httpMethod,
                parameters: request.parameters,
                encoding: request.encodingType,
                headers: [:]
            ).responseData(queue: DispatchQueue.global(qos: .utility), completionHandler: { [weak self] response in
                if Constants.debugNetwork {
                    print("""
                        Debug for request from \(request.baseURL + request.path):
                        Params: \(request.parameters)
                        Data : \(response.data == nil ? "empty" : response.data!.stringRepresentation)
                        """)
                }

                guard let _ = self else { return }
                if let error = response.error {
                    if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                        single(.error(APIError.noInternetConnection))
                        return
                    } else {
                        single(.error(error))
                        return
                    }
                }

                guard let _ = response.response else {
                    single(.error(APIError.emptyResponse))
                    return
                }

                guard let data = response.data else {
                    single(.error(APIError.emptyData))
                    return
                }

                single(.success(data))
            })

            return Disposables.create {
                request.cancel()
            }
        }

    }

    func perform(rawJsonRequest: APIRequest) -> Single<JSON> {
        return perform(request: rawJsonRequest).flatMap({ data in
            do {
                let json = try JSON(data: data)
                return .just(json)
            } catch {
                return .error(APIError.wrongDataFormat(url: rawJsonRequest.baseURL + rawJsonRequest.path))
            }
        })
    }

    func perform(jsonRequest: APIRequest) -> Single<APIResponse> {
        return perform(request: jsonRequest).flatMap({ data in
            do {
                let json = try JSON(data: data)
                guard let rData = APIResponseData(from: json) else {
                    return .error(APIError.wrongDataFormat(url: jsonRequest.baseURL + jsonRequest.path))
                }
                switch rData.state {
                case 200:
                    return .just(.success(rData))
                case 400...499:
                    NotificationCenter.default.post(name: InAppNotifications.TokenOrCredentialsAreInvalid, object: nil)
                    return .error(APIError.responseError(code: rData.state, description: rData.error ?? "Unknown"))
                default:
                    return .error(APIError.responseError(code: rData.state, description: rData.error ?? "Unknown"))
                }
            } catch {
                return .error(APIError.wrongDataFormat(url: jsonRequest.baseURL + jsonRequest.path))
            }
        })
    }

    func arrayFromJSON<Element>(
        from request: APIRequest,
        type: Element.Type
    ) -> Single<APIResults<Element>> where Element: Decodable {
        return perform(request: request).flatMap({ data -> Single<APIResults<Element>> in
            do {
                let results = try JSONDecoder().decode(APIResults<Element>.self, from: data)
                return .just(results)
            } catch {
                return .error(APIError.wrongDataFormat(url: request.baseURL + request.path))
            }
        })
    }

    func entityFrom<Element>(request: APIRequest, type: Element.Type) -> Single<Element> where Element: Decodable {
        return perform(request: request).flatMap({ data -> Single<Element> in
            do {
                let results = try JSONDecoder().decode(Element.self, from: data)
                return .just(results)
            } catch {
                return .error(APIError.wrongDataFormat(url: request.baseURL + request.path))
            }
        })
    }
}
