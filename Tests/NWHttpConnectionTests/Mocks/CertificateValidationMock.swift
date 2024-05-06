
import Foundation
@testable import NWHttpConnection
import Network

final class CertificateValidationMock: CertificateValidationType {
    
    private(set) var validateCalled = false
    private(set) var validateCalledAttempt = 0
    var validateCalledCompletion: sec_protocol_verify_complete_t?
    
    func validate(metadata: sec_protocol_metadata_t, trust: sec_trust_t, complete: @escaping sec_protocol_verify_complete_t) {
        validateCalled = true
        validateCalledAttempt += 1
        validateCalledCompletion = complete
    }
}
