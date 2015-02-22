import UIKit
import MultipeerConnectivity

class ChatsViewController: UITableViewController, ComposeViewControllerDelegate, MPCManagerDelegate, ChatViewControllerDelegate {
    
//    var chats: [Chat] { return account.chats }

    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    convenience override init() {
        self.init(style: .Plain)
        title = "Chats"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: "composeAction")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.manager.delegate = self

        let minute: NSTimeInterval = 60, hour = minute * 60, day = hour * 24
//        account.chats = [
//            Chat(user: User(phone: "7148329153"), lastMessageText: "last message text here", lastMessageSentDate: NSDate())
//        ]

        navigationItem.leftBarButtonItem = editButtonItem() // TODO: KVO
        tableView.backgroundColor = UIColor.whiteColor()
        tableView.rowHeight = chatCellHeight
        tableView.separatorInset.left = chatCellInsetLeft
        tableView.registerClass(ChatCell.self, forCellReuseIdentifier: NSStringFromClass(ChatCell))
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return account.chats.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(ChatCell), forIndexPath: indexPath) as ChatCell
        cell.configureWithChat(account.chats[indexPath.row])
        return cell
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            account.chats.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            if account.chats.count == 0 {
                navigationItem.leftBarButtonItem = nil  // TODO: KVO
            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let chat = account.chats[indexPath.row]
        let chatViewController = ChatViewController(chat: chat)
        chatViewController.delegate = self
        navigationController?.pushViewController(chatViewController, animated: true)
    }

    func composeAction() {
        let composer = ComposeViewController()
        composer.delegate = self
        let navigationController = UINavigationController(rootViewController: composer)
        presentViewController(navigationController, animated: true, completion: nil)
    }
    
    func finishedComposing(controller: ComposeViewController) {
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
//        tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.Bottom)
        let chat = account.chats[indexPath.row]
        let chatViewController = ChatViewController(chat: chat)
        navigationController?.pushViewController(chatViewController, animated: true)
    }
    
//    @IBAction func addChat(segue: UIStoryboardSegue) {
//        if segue.identifier == "Send" {
//            let composeController = segue.sourceViewController as ComposeViewController
//            if let newChat = composeController.newChat {
//                account.chats.insert(newChat, atIndex: 0)
//                let indexPath = NSIndexPath(forRow: 0, inSection: 0)
//                tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
//            }
//        }
//        
//        //SEND MESSAGE BROADCAST THING HERE
//    }
    
    func foundPeer() {}
    
    func lostPeer() {}
    
    func invitationWasReceived(fromPeer: String) {
        appDelegate.manager.invitationHandler(true, appDelegate.manager.session)
    }
    
    func connectedWithPeer(peerID: MCPeerID) {}

    func messageReceived(message: Message) {
        println("messageReceived")
        println(account.chats.count)
        tableView.reloadData()
//        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
//        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    func backToChats() {
        tableView.reloadData()
//        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
//        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }

}
