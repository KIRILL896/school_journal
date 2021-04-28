//
//  MessagesServiceType.swift
//  scool_journal
//
//  Created by отмеченные on 09/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation
import RxSwift

protocol MessagesServiceType {

    func messages(type: MessageType, limit: Int, page: Int) -> Single<[Message]>
    func message(with id: String) -> Single<Message>
    func contasts() -> Single<[ContactGroup]>
    func sendMessage(subject: String, text: String, ids: String) -> Single<Void>
    func sendReply(messageId: String, text: String) -> Single<Void>
}
