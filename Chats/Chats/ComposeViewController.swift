import UIKit
import MultipeerConnectivity


protocol ComposeViewControllerDelegate {
    func finishedComposing(controller: ComposeViewController)
}


class ComposeViewController: UIViewController, UITableViewDataSource, UITextViewDelegate, MPCManagerDelegate {
    var searchResults: [User] = []
    var searchResultsTableView = UITableView(frame: CGRectZero, style: .Plain)
    var toolBar: UIToolbar!
    var toTextView = UITextView(frame: CGRectZero)
    var textView: UITextView!
    var sendButton: UIButton!
 
    var delegate: ComposeViewControllerDelegate? = nil
    var newChat: Chat?
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    override var inputAccessoryView: UIView! {
        get {
            if toolBar == nil {
                toolBar = UIToolbar(frame: CGRectMake(0, 0, 0, toolBarMinHeight-0.5))
                
                textView = InputTextView(frame: CGRectZero)
                textView.backgroundColor = UIColor(white: 250/255, alpha: 1)
                textView.delegate = self
                textView.font = UIFont.systemFontOfSize(messageFontSize)
                textView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 205/255, alpha:1).CGColor
                textView.layer.borderWidth = 0.5
                textView.layer.cornerRadius = 5
                //        textView.placeholder = "Message"
                textView.scrollsToTop = false
                textView.textContainerInset = UIEdgeInsetsMake(4, 3, 3, 3)
                toolBar.addSubview(textView)
                
                sendButton = UIButton.buttonWithType(.System) as UIButton
                sendButton.enabled = false
                sendButton.titleLabel?.font = UIFont.boldSystemFontOfSize(17)
                sendButton.setTitle("Send", forState: .Normal)
                sendButton.setTitleColor(UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1), forState: .Disabled)
                sendButton.setTitleColor(UIColor(red: 1/255, green: 122/255, blue: 255/255, alpha: 1), forState: .Normal)
                sendButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
                sendButton.addTarget(self, action: "sendAction", forControlEvents: UIControlEvents.TouchUpInside)
                toolBar.addSubview(sendButton)
                
                // Auto Layout allows `sendButton` to change width, e.g., for localization.
                textView.setTranslatesAutoresizingMaskIntoConstraints(false)
                sendButton.setTranslatesAutoresizingMaskIntoConstraints(false)
                toolBar.addConstraint(NSLayoutConstraint(item: textView, attribute: .Left, relatedBy: .Equal, toItem: toolBar, attribute: .Left, multiplier: 1, constant: 8))
                toolBar.addConstraint(NSLayoutConstraint(item: textView, attribute: .Top, relatedBy: .Equal, toItem: toolBar, attribute: .Top, multiplier: 1, constant: 7.5))
                toolBar.addConstraint(NSLayoutConstraint(item: textView, attribute: .Right, relatedBy: .Equal, toItem: sendButton, attribute: .Left, multiplier: 1, constant: -2))
                toolBar.addConstraint(NSLayoutConstraint(item: textView, attribute: .Bottom, relatedBy: .Equal, toItem: toolBar, attribute: .Bottom, multiplier: 1, constant: -8))
                toolBar.addConstraint(NSLayoutConstraint(item: sendButton, attribute: .Right, relatedBy: .Equal, toItem: toolBar, attribute: .Right, multiplier: 1, constant: 0))
                toolBar.addConstraint(NSLayoutConstraint(item: sendButton, attribute: .Bottom, relatedBy: .Equal, toItem: toolBar, attribute: .Bottom, multiplier: 1, constant: -4.5))
            }
            return toolBar
        }
    }

    convenience override init() {
        self.init(nibName: nil, bundle: nil)
        automaticallyAdjustsScrollViewInsets = false
        title = "New Message"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelAction")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.manager.delegate = self

        view.backgroundColor = UIColor.whiteColor()

        toTextView.backgroundColor = UIColor(white: 248/255.0, alpha: 1)
        let attributedString = NSMutableAttributedString(string: "To: ")
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 142/255.0, green: 142/255.0, blue: 147/255.0, alpha: 1), range: NSMakeRange(0, 3))
        toTextView.attributedText = attributedString
        toTextView.font = UIFont.systemFontOfSize(15)
        toTextView.contentInset = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 0)
        view.addSubview(toTextView)

        searchResultsTableView.frame = view.bounds
        searchResultsTableView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        searchResultsTableView.dataSource = self
        searchResultsTableView.hidden = true
        searchResultsTableView.keyboardDismissMode = .OnDrag
        searchResultsTableView.scrollsToTop = false
        searchResultsTableView.registerClass(UserCell.self, forCellReuseIdentifier: NSStringFromClass(UserCell))
        view.addSubview(searchResultsTableView)

        toTextView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addConstraint(NSLayoutConstraint(item: toTextView, attribute: .Left, relatedBy: .Equal, toItem: view, attribute: .Left, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: toTextView, attribute: .Right, relatedBy: .Equal, toItem: view, attribute: .Right, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: toTextView, attribute: .Top, relatedBy: .Equal, toItem: topLayoutGuide, attribute: .Bottom, multiplier: 1, constant: 0))
        toTextView.addConstraint(NSLayoutConstraint(item: toTextView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 44))
    }

    func textViewDidChange(textView: UITextView!) {
        sendButton.enabled = textView.hasText()
    }

    func sendAction() {
        let sourcePhone = account.user.phone
        let toText = self.toTextView.text
        let destPhone = toText.substringFromIndex(advance(toText.startIndex, 4))
        let msg = textView!.text
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.timeStyle = NSDateFormatterStyle.MediumStyle
        let dateString = formatter.stringFromDate(date)
        
        println(sourcePhone)
        println(destPhone)
        println(msg)
        println(dateString)
        
        let packet = Packet(sourcePhone: sourcePhone, destPhone: destPhone, msg: msg, dateString: dateString)
        
        // SEND PACKET
        manager_global.sendData(packet)
        
        // go back to Chats view
        dismissViewControllerAnimated(true, completion: {
            // save new chat
            self.newChat = Chat(user: User(phone: destPhone), lastMessageText: msg, lastMessageSentDate: NSDate())
            self.newChat?.loadedMessages += [[Message(incoming: false, text: msg, sentDate: NSDate(), status: MessageStatus.Waiting)]]
            account.chats.insert(self.newChat!, atIndex: 0)

            // re-render Chats list
            self.delegate?.finishedComposing(self)
        })
        
    }
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "Send" {
//            let destPhone = toTextView.text
//            let msg = textView.text
//            newChat = Chat(user: User(phone: destPhone), lastMessageText: msg, lastMessageSentDate: NSDate())
//        }
//    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(UserCell), forIndexPath: indexPath) as UserCell
        let user = searchResults[indexPath.row]
//        cell.pictureImageView.image = UIImage(named: user.pictureName())
//        cell.nameLabel.text = user.name
//        cell.usernameLabel.text = "$" + user.username
        return cell
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(textView: UITextField) {
        println(textView.text)
    }

    // MARK: - Actions

    func cancelAction() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func foundPeer() {}
    
    func lostPeer() {}
    
    func invitationWasReceived(fromPeer: String) {
        appDelegate.manager.invitationHandler(true, appDelegate.manager.session)
    }
    
    func connectedWithPeer(peerID: MCPeerID) {}
    
    func messageReceived(message: Message) {}
}
