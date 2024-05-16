import XCTest
import Network
@testable import NWHttpConnection



class NWHttpConnectionTests: XCTestCase {
    class Fixture {
        var url: URL = URL(string: "https://123.334.987/api")!
        var method: NWConnectionHTTPMethod = .get
        var body: Data?
        var certificateValidationMock = CertificateValidationMock()
        var nwConnectionProviderMock: NWConnectionProviderMock!
        var nwConnectionTypeMock: NWConnectionTypeMock!
        var dataResponseType: NWDataResponseType = .jsonData
        var receivedData: Data?
        var receivedError: NWHttpConnectionError?
        var requestHandler: NWHttpConnection.RequestHandler?
        var requestCompletionCalled = false
        var requestCompletion: NWHttpConnection.Completion?
        
        init() {
            self.nwConnectionTypeMock = NWConnectionTypeMock(host: NWEndpoint.Host("host"), port: NWEndpoint.Port(222), using: NWParameters())
            self.nwConnectionProviderMock = NWConnectionProviderMock(nwConnectionType: nwConnectionTypeMock)
            
            self.requestHandler = { error, data in
                self.receivedError = error
                self.receivedData = data
            }
            
            self.requestCompletion = {
                self.requestCompletionCalled = true
            }
        }
        
        
    }
    
    var fixture: Fixture!
    var sut: NWHttpConnection!
    
    override func setUp() {
        fixture = Fixture()
    }
    
    override func tearDown() {
        fixture = nil
        sut = nil
    }
    
    private func instantiateSut(with timeout: TimeInterval = 60) {
        sut = NWHttpConnection(url: fixture.url, method: fixture.method, body: fixture.body, certificateValidation: fixture.certificateValidationMock, dataResponseType: fixture.dataResponseType, nwConnectionProvider: fixture.nwConnectionProviderMock, timeout: timeout)
    }
    
    func test_startConnectionWhenStateIsReady() throws {
        // GIVEN that the NWHttpConnection is instantiated
        instantiateSut()
        // THEN the NWConection is NOT called yet to send or receive any Data
        XCTAssertFalse(fixture.nwConnectionTypeMock.sendCalled)
        XCTAssertFalse(fixture.nwConnectionTypeMock.receiveCalled)

        // AND WHEN the connect method is called
        try sut.connect(requestHandler: fixture.requestHandler, completion: fixture.requestCompletion)
        
        // THEN the NWConnection is called to receive Data
        XCTAssertTrue(fixture.nwConnectionTypeMock.receiveCalled)
        
        // AND WHEN the NWConnection state is 'ready'
        fixture.nwConnectionTypeMock.stateUpdateHandler?(NWConnection.State.ready)
        
        // THEN the content is sent to the expected host
        XCTAssertTrue(fixture.nwConnectionTypeMock.sendCalled)
        
        let contentSentHost = fixture.url.host!
        let sentContentData: Data? = fixture.nwConnectionTypeMock.sendCalledWithArgs?.content
        let sendContentDataString = String(data: sentContentData!, encoding: .ascii)!

        XCTAssertTrue(sendContentDataString.contains(contentSentHost))
       
    }
    
    func test_startConnectionWhenStateIsPreparing() throws {
        // GIVEN that the NWHttpConnection is instantiated
        instantiateSut()
        // THEN the NWConection is NOT called yet to send or receive any Data
        XCTAssertFalse(fixture.nwConnectionTypeMock.sendCalled)
        XCTAssertFalse(fixture.nwConnectionTypeMock.receiveCalled)

        // AND WHEN the connect method is called
        try sut.connect(requestHandler: fixture.requestHandler, completion: fixture.requestCompletion)
        
        // THEN the NWConnection is called to receive Data
        XCTAssertTrue(fixture.nwConnectionTypeMock.receiveCalled)
        
        // AND WHEN the NWConnection state is 'preparing'
        fixture.nwConnectionTypeMock.stateUpdateHandler?(NWConnection.State.preparing)
        
        // THEN the content remains NOT sent
        XCTAssertFalse(fixture.nwConnectionTypeMock.sendCalled)
    }
    
    func test_startConnectionWhenStateIsSetup() throws {
        // GIVEN that the NWHttpConnection is instantiated
        instantiateSut()
        // THEN the NWConection is NOT called yet to send or receive any Data
        XCTAssertFalse(fixture.nwConnectionTypeMock.sendCalled)
        XCTAssertFalse(fixture.nwConnectionTypeMock.receiveCalled)

        // AND WHEN the connect method is called
        try sut.connect()
        
        // THEN the NWConnection is called to receive Data
        XCTAssertTrue(fixture.nwConnectionTypeMock.receiveCalled)
        
        // AND WHEN the NWConnection state is 'setup'
        fixture.nwConnectionTypeMock.stateUpdateHandler?(NWConnection.State.setup)
        
        // THEN the content remains NOT sent
        XCTAssertFalse(fixture.nwConnectionTypeMock.sendCalled)
    }
    
    func test_startConnectionWhenStateIsWaiting() throws {
        // GIVEN that the NWHttpConnection is instantiated
        instantiateSut()
        
        // THEN the NWConection is NOT called yet to send or receive any Data
        XCTAssertFalse(fixture.nwConnectionTypeMock.sendCalled)
        XCTAssertFalse(fixture.nwConnectionTypeMock.receiveCalled)
        
        // AND When calling connect
        try sut.connect(requestHandler: fixture.requestHandler, completion: fixture.requestCompletion)
        
        // THEN the NWConnection is called to receive Data
        XCTAssertTrue(fixture.nwConnectionTypeMock.receiveCalled)
        
        // AND WHEN the NWConnection state is 'waiting'
        fixture.nwConnectionTypeMock.stateUpdateHandler?(NWConnection.State.waiting(NWError.tls(1)))
        
        // AND the content remains NOT sent
        XCTAssertFalse(fixture.nwConnectionTypeMock.sendCalled)
    }
    
    func test_startConnectionWhenStateIsWaitingWithoutConnection() throws {
        // GIVEN that the NWHttpConnection is instantiated
        instantiateSut()
        
        // THEN the NWConection is NOT called yet to send or receive any Data
        XCTAssertFalse(fixture.nwConnectionTypeMock.sendCalled)
        XCTAssertFalse(fixture.nwConnectionTypeMock.receiveCalled)
        
        // AND When calling connect
        try sut.connect(requestHandler: fixture.requestHandler, completion: fixture.requestCompletion)
        
        // THEN the NWConnection is called to receive Data
        XCTAssertTrue(fixture.nwConnectionTypeMock.receiveCalled)
        
        // AND WHEN the NWConnection state is 'waiting'
        // AND WHEN there is not a viable network
        fixture.nwConnectionTypeMock.stateUpdateHandler?(NWConnection.State.waiting(NWError.posix(.ENETDOWN)))
        
        // AND the content remains NOT sent
        XCTAssertFalse(fixture.nwConnectionTypeMock.sendCalled)
        
        // THEN the connection gets cancelled
        XCTAssertTrue(fixture.nwConnectionTypeMock.cancelCalled)
    }
    
    func test_startConnectionWhenStateIsFailed() throws {
        // GIVEN that the NWHttpConnection is instantiated
        instantiateSut()
        // THEN the NWConection is NOT called yet to send or receive any Data
        XCTAssertFalse(fixture.nwConnectionTypeMock.sendCalled)
        XCTAssertFalse(fixture.nwConnectionTypeMock.receiveCalled)

        // AND When calling connect
        try sut.connect(requestHandler: fixture.requestHandler, completion: fixture.requestCompletion)
        
        // THEN the NWConnection is called to receive Data
        XCTAssertTrue(fixture.nwConnectionTypeMock.receiveCalled)
        
        // AND WHEN the NWConnection state is 'failed'
        fixture.nwConnectionTypeMock.stateUpdateHandler?(NWConnection.State.failed(NWError.tls(1)))
        
        // THEN Connection error is received
        XCTAssertNotNil(fixture.receivedError)
        XCTAssertEqual(fixture.receivedError, NWHttpConnectionError.connection(NWError.tls(1)))
        
        // AND the content remains NOT sent
        XCTAssertFalse(fixture.nwConnectionTypeMock.sendCalled)
        
        // AND the connection gets cancelled
        XCTAssertTrue(fixture.nwConnectionTypeMock.cancelCalled)
        
    }
    
    func test_startConnectionWhenStateIsCancelled() throws {
        // GIVEN that the NWHttpConnection is instantiated
        instantiateSut()
        // THEN the NWConection is NOT called yet to send or receive any Data
        XCTAssertFalse(fixture.nwConnectionTypeMock.sendCalled)
        XCTAssertFalse(fixture.nwConnectionTypeMock.receiveCalled)

        // AND When calling connect
        try sut.connect(requestHandler: fixture.requestHandler, completion: fixture.requestCompletion)
        
        // THEN the NWConnection is called to receive Data
        XCTAssertTrue(fixture.nwConnectionTypeMock.receiveCalled)
        
        // AND WHEN the NWConnection state is 'cancelled'
        fixture.nwConnectionTypeMock.stateUpdateHandler?(NWConnection.State.cancelled)
        
        // THEN the connection gets Complete
        XCTAssertTrue(fixture.requestCompletionCalled)
        
        // AND NO Connection error is received
        XCTAssertNil(fixture.receivedError)
        
        // AND the content remains NOT sent
        XCTAssertFalse(fixture.nwConnectionTypeMock.sendCalled)
        
    }
    
    func test_connectionTimeOut() throws {
        instantiateSut(with: 1)
        
        // GIVEN that a connection is established
        try sut.connect(requestHandler: fixture.requestHandler, completion: fixture.requestCompletion)
        XCTAssertTrue(fixture.nwConnectionTypeMock.receiveCalled)
        XCTAssertFalse(fixture.nwConnectionTypeMock.cancelCalled)
        
        let exp = expectation(description: "Test after 2 second")
        let result = XCTWaiter.wait(for: [exp], timeout: 2.0)
        
        // WHEN the timeout is reached
        if result == XCTWaiter.Result.timedOut {
            // THEN the connection  gets cancelled
            XCTAssertTrue(fixture.nwConnectionTypeMock.cancelCalled)
        } else {
            XCTFail("Delay interrupted")
        }
        
    }
    
}
