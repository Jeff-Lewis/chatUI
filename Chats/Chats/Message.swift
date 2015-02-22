import Foundation

enum MessageStatus {
    case Success, Failure, Waiting
}

class Message {
    let incoming: Bool
    let text: String
    let sentDate: NSDate
    var status: MessageStatus

    init(incoming: Bool, text: String, sentDate: NSDate, status: MessageStatus) {
        self.incoming = incoming
        self.text = text
        self.sentDate = sentDate
        self.status = status
    }
}
