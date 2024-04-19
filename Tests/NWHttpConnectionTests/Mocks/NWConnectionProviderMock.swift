
import Foundation
@testable import NWHttpConnection
import Network

final class NWConnectionProviderMock: NWConnectionProviderType {
    
    var makeNWConnectionResult: NWConnectionType
    
    init(nwConnectionType: NWConnectionType) {
        self.makeNWConnectionResult = nwConnectionType
    }
    
    func makeNWConnection(for host: NWEndpoint.Host, port: NWEndpoint.Port, params: NWParameters) -> NWConnectionType {
        return makeNWConnectionResult
    }
}
