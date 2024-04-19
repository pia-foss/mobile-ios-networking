
import Foundation
@testable import NWHttpConnection
import Network

final class NWConnectionTypeMock: NWConnectionType {

    
    init(host: NWEndpoint.Host, port: NWEndpoint.Port, using: NWParameters) {

    }
    
    convenience init() {
        self.init(host: NWEndpoint.Host("host"), port: NWEndpoint.Port(integerLiteral: 11), using: NWParameters())
    }
    
    
    var stateUpdateHandler: ((NWConnection.State) -> Void)?
    
    private(set) var startCalled = false
    private(set) var startCalledAttempt = 0
    private(set) var startCalledWithDispatchQueue: DispatchQueue?
    
    func start(queue: DispatchQueue) {
        startCalled = true
        startCalledAttempt += 1
        startCalledWithDispatchQueue = queue
    }
    
    private(set) var sendCalled = false
    private(set) var sendCalledAttempt = 0
    private(set) var sendCalledWithArgs: (content: Data?, context: NWConnection.ContentContext, isComplete: Bool, completion: NWConnection.SendCompletion)?
    var sendCompletion: NWConnection.SendCompletion?
    func send(content: Data?, contentContext: NWConnection.ContentContext, isComplete: Bool, completion: NWConnection.SendCompletion) {
        sendCalled = true
        sendCalledAttempt += 1
        sendCalledWithArgs = (content: content, context: contentContext, isComplete: isComplete, completion: completion)
        
    }
    
    private(set) var receiveCalled = false
    private(set) var receiveCalledAttempt = 0
    private(set) var receiveCompletion: ((Data?, NWConnection.ContentContext?, Bool, NWError?) -> Void)?
    func receive(minimumIncompleteLength: Int, maximumLength: Int, completion: @escaping (Data?, NWConnection.ContentContext?, Bool, NWError?) -> Void) {
        receiveCalled = true
        receiveCalledAttempt += 1
        receiveCompletion = completion
    }
    
    private(set) var cancelCalled = false
    private(set) var cancelCalledAttempt = 0
    func cancel() {
        cancelCalled = true
        cancelCalledAttempt += 1
    }
    
    
}
