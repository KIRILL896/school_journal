//
//  InAppNotifications.swift
//  scool_journal
//
//  Created by отмеченные on 15/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation

struct InAppNotifications {

    static var MessageSent: Notification.Name {
        return Notification.Name(Constants.app.messages.name)
    }

    static var NotificationReceived: Notification.Name {
        return Notification.Name(Constants.app.messages.received)
    }

    static var TokenOrCredentialsAreInvalid: Notification.Name {
        return Notification.Name(Constants.app.messages.invalid)
    }
}
