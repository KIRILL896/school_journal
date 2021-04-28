//
//  MessagesService.swift
//  scool_journal
//
//  Created by отмеченные on 09/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyJSON
import Alamofire

class MessagesService: ApiServiceProtocol, MessagesServiceType {

    private struct Params {

        static let getmessagesPath = "getmessages"
        static let getmessageinfoPath = "getmessageinfo"
        static let getmessagereceiversPath = "getmessagereceivers"
        static let sendmessagePath = "sendmessage"
        static let sendreplymessagePath = "sendreplymessage"

        static let folderParam = "folder"
        static let limitParam = "limit"
        static let pageParam = "page"
        static let idParam = "id"

        static let usersToParam = "users_to"
        static let subjectParam = "subject"
        static let textParam = "text"
        static let replytoParam = "replyto"
    }

    private var apiClient: APIClientType
    var credentialsStorage: CredentialsStorageType

    init(apiClient: APIClientType, credentialsStorage: CredentialsStorageType) {
        self.apiClient = apiClient
        self.credentialsStorage = credentialsStorage
    }

    func messages(type: MessageType, limit: Int, page: Int) -> Single<[Message]> {
        let params: [String: Any] = [Params.folderParam: type.rawValue,
                                       Params.limitParam: limit,
                                       Params.pageParam: page]
        var request = APIRequest(baseURL: urlWithVendor,
                                 path: Params.getmessagesPath,
                                 parameters: params,
                                 authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }

        return apiClient.perform(jsonRequest: request).flatMap { response -> Single<[Message]> in
            switch response {
            case .success(let data):

                guard let json = data.result else {
                    return .error(APIError.wrongDataFormat(url: "messages"))
                }
                guard let messagesJSON = json["messages"].array else {
                    return .just([Message]())
                }

                var messages = messagesJSON.compactMap({ Message(from: $0) })
                for (index, _) in messages.enumerated() {
                    messages[index].type = type
                }
                return .just(messages)
            case .failure(let err):
                return .error(err)
            }
        }
    }

    func message(with id: String) -> Single<Message> {
        let params: [String: Any] = [Params.idParam: id]
        var request = APIRequest(baseURL: urlWithVendor,
                                 path: Params.getmessageinfoPath,
                                 parameters: params,
                                 authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }
        return apiClient.perform(jsonRequest: request).flatMap { response -> Single<Message> in
            switch response {
            case .success(let data):
                guard let json = data.result, let message = Message(from: json["message"]) else {
                    return .error(APIError.wrongDataFormat(url: "messages"))
                }
                return .just(message)
            case .failure(let err):
                return .error(err)
            }
        }
    }

    func contasts() -> Single<[ContactGroup]> {
        let params = [String: Any]()
        var request = APIRequest(baseURL: urlWithVendor,
                                 path: Params.getmessagereceiversPath,
                                 parameters: params,
                                 authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }
        return apiClient.perform(jsonRequest: request).flatMap { response -> Single<[ContactGroup]> in
            switch response {
            case .success(let data):
                var groups = [ContactGroup]()
                guard let json = data.result, let groupsJSON = json["groups"].array else {
                    return .error(APIError.wrongDataFormat(url: "contasts"))
                }
                groups = groupsJSON.compactMap({ ContactGroup(from: $0) })
                return .just(groups)
            case .failure(let err):
                return .error(err)
            }
        }
    }
    func sendMessage(subject: String, text: String, ids: String) -> Single<Void> {
        let params: [String: Any] = [Params.usersToParam: ids,
                                       Params.subjectParam: subject,
                                       Params.textParam: text]
        var request = APIRequest(baseURL: urlWithVendor,
                                 path: Params.sendmessagePath,
                                 parameters: params,
                                 httpMethod: .post,
                                 encodingType: URLEncoding.httpBody,
                                 authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }
        return apiClient.perform(jsonRequest: request).flatMap { response -> Single<Void> in
            switch response {
            case .success:
                return .just(())
            case .failure(let err):
                return .error(err)
            }
        }
    }

    func sendReply(messageId: String, text: String) -> Single<Void> {
        let params: [String: Any] = [Params.replytoParam: messageId,
                                       Params.textParam: text]
        var request = APIRequest(baseURL: urlWithVendor,
                                 path: Params.sendreplymessagePath,
                                 parameters: params,
                                 httpMethod: .post,
                                 encodingType: URLEncoding.httpBody,
                                 authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }
        return apiClient.perform(jsonRequest: request).flatMap { response -> Single<Void> in
            switch response {
            case .success:
                return .just(())
            case .failure(let err):
                return .error(err)
            }
        }
    }
}
