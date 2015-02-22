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
        
//        for person in contactsArrayRef {
//            println(ABRecordCopyCompositeName(person).takeRetainedValue())
//        }
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
        println("DESTINATION PHONE", packet.msg)
        println(dictionary)
        
        seenMessages.append(packet.sourcePhone + packet.destPhone + packet.dateString)
        
        // temporary - checking whether you are the desired recipient of the message
        if (packet.destPhone == self.myPhoneNumber) {
            NSNotificationCenter.defaultCenter().postNotificationName("receivedMPCDataNotification", object: nil, userInfo: dictionary)
            
            println("RECEIVED!!!!")
            
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
    
}
