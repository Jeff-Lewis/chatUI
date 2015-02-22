//
//  MPCManager.swift
//  MPCRevisited
//
//  Created by Gabriel Theodoropoulos on 11/1/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

import UIKit
import MultipeerConnectivity

import AddressBook


protocol MPCManagerDelegate {
    func foundPeer()
    
    func lostPeer()
    
    func invitationWasReceived(fromPeer: String)
    
    func connectedWithPeer(peerID: MCPeerID)
    
    func messageReceived(message: Message)
}


class MPCManager: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    
    var delegate: MPCManagerDelegate?
    
    var session: MCSession!
    
    var peer: MCPeerID!
    
    var browser: MCNearbyServiceBrowser!
    
    var advertiser: MCNearbyServiceAdvertiser!
    
    var foundPeers = [MCPeerID]()
    
    var invitationHandler: ((Bool, MCSession!)->Void)!
    
    var addressBookRef: ABAddressBookRef!
    
    var contactsArrayRef: NSArray!
    
    var myPhoneNumber: String!
    
    var seenMessages: [AnyObject]!
    
    override init() {
        
        super.init()
        
        peer = MCPeerID(displayName: UIDevice.currentDevice().name)
        
        session = MCSession(peer: peer)
        session.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: "appcoda-mpc")
        browser.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: "appcoda-mpc")
        advertiser.delegate = self
        
        seenMessages = []
        
        let status = ABAddressBookGetAuthorizationStatus()
        switch status {
        case .Authorized:
            addressBookRef = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
            contactsArrayRef = ABAddressBookCopyArrayOfAllPeople(addressBookRef).takeRetainedValue() as NSArray as [ABRecord]
        case .NotDetermined:
            var ok = false
            ABAddressBookRequestAccessWithCompletion(nil) {
                (granted:Bool, err:CFError!) in
                dispatch_async(dispatch_get_main_queue()) {
                    if granted {
                        self.addressBookRef = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
                        self.contactsArrayRef = ABAddressBookCopyArrayOfAllPeople(self.addressBookRef).takeRetainedValue() as NSArray as [ABRecord]
                    }
                }
            }
        default:
            return;
        }
        
    }
    
    func setMyPhoneNumber(myPhoneNumber: NSString) {
        self.myPhoneNumber = myPhoneNumber
    }
    
    // MARK: MCNearbyServiceBrowserDelegate method implementation
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        
        foundPeers.append(peerID)
        
        // automatically invite peer (invitee will automatically accept)
        
        println("Found peer: %s", peerID);
        
        browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 20)
        
        println("Done with invitation...\n");
        
        //        for person in contactsArrayRef {
        //            println(ABRecordCopyCompositeName(person).takeRetainedValue())
        //  }
        
        var urlString = "mesh-treehacks.herokuapp.com/add-link"
        var dataString = "N1=" + peerID.displayName + "&N2=" + peer.displayName
        sendPostRequest(urlString, dataString: dataString)
        
        if foundPeers.count == 1 {
            urlString = "mesh-treehacks.herokuapp.com/add-node"
            dataString = "N=" + peerID.displayName
            sendPostRequest(urlString, dataString: dataString)
        }
        
        delegate?.foundPeer()
    }
    
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        for (index, aPeer) in enumerate(foundPeers){
            if aPeer == peerID {
                foundPeers.removeAtIndex(index)
                break
            }
        }
        
        println("Lost peer: %s", peerID);
        
        var urlString = "mesh-treehacks.herokuapp.com/remove-link"
        var dataString = "N1=" + peerID.displayName + "&N2=" + peer.displayName
        sendPostRequest(urlString, dataString: dataString)
        
        if foundPeers.count == 0 {
            urlString = "mesh-treehacks.herokuapp.com/remove-node"
            dataString = "N=" + peerID.displayName
            sendPostRequest(urlString, dataString: dataString)
        }
        
        delegate?.lostPeer()
    }
    
    
    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        println(error.localizedDescription)
    }
    
    
    // MARK: MCNearbyServiceAdvertiserDelegate method implementation
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        self.invitationHandler = invitationHandler
        
        delegate?.invitationWasReceived(peerID.displayName)
    }
    
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        println(error.localizedDescription)
    }
    
    
    // MARK: MCSessionDelegate method implementation
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        switch state{
        case MCSessionState.Connected:
            println("Connected to session: \(session)")
            delegate?.connectedWithPeer(peerID)
            
        case MCSessionState.Connecting:
            println("Connecting to session: \(session)")
            
        default:
            println("Did not connect to session: \(session)")
        }
    }
    
    
    //    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
    //        let dictionary: [String: AnyObject] = ["data": data, "fromPeer": peerID]
    //        NSNotificationCenter.defaultCenter().postNotificationName("receivedMPCDataNotification", object: dictionary)
    //    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        
        let packet: Packet = NSKeyedUnarchiver.unarchiveObjectWithData(data) as Packet
        
        let dictionary: [String: AnyObject] = ["data": packet.msg, "fromPeer": peerID]
        println("DESTINATION MSG", packet.msg)
        println("DESTINATION NUMBER %s", packet.destPhone)
        println(self.myPhoneNumber)
        println(dictionary)
        
        seenMessages.append(packet.sourcePhone + packet.destPhone + packet.dateString)
        
        // temporary - checking whether you are the desired recipient of the message
        if (packet.destPhone == (self.myPhoneNumber)) {
            println("fucking received!!!!!")
            
            let newMsg = Message(incoming: true, text: packet.msg, sentDate: NSDate(), status: MessageStatus.Success)
            
            var oldChatFound = false
            for chat in account.chats {
                if chat.user.phone == packet.sourcePhone {
                    oldChatFound = true
                    chat.loadedMessages += [[newMsg]]
                    chat.lastMessageText = packet.msg
                }
            }
            if oldChatFound == false {
                let newChat = Chat(user: User(phone: packet.sourcePhone), lastMessageText: packet.msg, lastMessageSentDate: NSDate())
                newChat.loadedMessages += [[newMsg]]
                newChat.lastMessageText = packet.msg
                account.chats.insert(newChat, atIndex: 0)
            }
            
            delegate?.messageReceived(newMsg)
            NSNotificationCenter.defaultCenter().postNotificationName("receivedMPCDataNotification", object: nil, userInfo: dictionary)
        } else {
            var seen = false
            for item in seenMessages as [AnyObject] {
                if (item as NSString == (packet.sourcePhone + packet.destPhone + packet.dateString)) {
                    seen = true
                }
            }
            
            if (!seen) {
                // broadcast
                sendData(packet)
            }
        }
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) { }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) { }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) { }
    
    
    
    // MARK: Custom method implementation
    
    func sendData(packet: Packet!) -> Bool {
        var error: NSError?
        let packetDataToSend = NSKeyedArchiver.archivedDataWithRootObject(packet)
        session.sendData(packetDataToSend, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Reliable, error: &error)
        
        for peer in session.connectedPeers {
            var urlString = "mesh-treehacks.herokuapp.com/traverse-link"
            var dataString = "N1=" + peer.displayName + "&N2=" + peer.displayName + "&TIME=" + packet.dateString
            sendPostRequest(urlString, dataString: dataString)
        }
        
        return true
    }
    
    func sendData(dictionaryWithData dictionary: Dictionary<String, String>) -> Bool {
        let dataToSend = NSKeyedArchiver.archivedDataWithRootObject(dictionary)
        let peersArray = NSArray(object: session.connectedPeers)
        var error: NSError?
        
        
        var peerString = "I am connected to ";
        for peer in session.connectedPeers {
            peerString += peer.displayName + " "
        }
        
        println(peerString)
        
        let peerDictionary: [String: String] = ["message": peerString]
        let peerData = NSKeyedArchiver.archivedDataWithRootObject(peerDictionary)
        
        var packet = Packet(sourcePhone: "4085960333", destPhone: "6503338223", msg: "Hi it's Pavitra!!!!!", dateString: "2015-1-1")
        let packetDataToSend = NSKeyedArchiver.archivedDataWithRootObject(packet)
        
        session.sendData(packetDataToSend, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Reliable, error: &error)
        
        /*
        if !session.sendData(peerData, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Reliable, error: &error) {
        println("Error in peer string")
        return false
        }
        
        
        if !session.sendData(dataToSend, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Reliable, error: &error) {
        println(error?.localizedDescription)
        return false
        }*/
        
        return true
    }
    
    func sendPostRequest(urlString: String, dataString: String) {
        let url = NSURL(fileURLWithPath: urlString)
        let cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        var request = NSMutableURLRequest(URL: url!, cachePolicy: cachePolicy, timeoutInterval: 2.0)
        request.HTTPMethod = "POST"
        
        let boundaryConstant = "----------V2ymHFg03esomerandomstuffhbqgZCaKO6jy";
        let contentType = "multipart/form-data; boundary=" + boundaryConstant
        NSURLProtocol.setProperty(contentType, forKey: "Content-Type", inRequest: request)
        
        // set data
        let requestBodyData = (dataString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        request.HTTPBody = requestBodyData
        
        // set content length
        //NSURLProtocol.setProperty(requestBodyData.length, forKey: "Content-Length", inRequest: request)
        
        var response: NSURLResponse? = nil
        var error: NSError? = nil
        let reply = NSURLConnection.sendSynchronousRequest(request, returningResponse:&response, error:&error)
        
        let results = NSString(data:reply!, encoding:NSUTF8StringEncoding)
        println("Response: \(results)")
    }
    
}
