//
//  CertificateValidation.swift
//  PIA VPN
//
//  Created by Laura S on 3/26/24.
//  Copyright © 2024 Private Internet Access Inc. All rights reserved.
//

import Foundation
import CommonCrypto

public protocol CertificateValidationType {
    func validate(metadata: sec_protocol_metadata_t, trust: sec_trust_t, complete: @escaping sec_protocol_verify_complete_t)
}

public enum CertificateValidation {
    case anchor(certificate: SecCertificate, commonName: String?)
    case pinnedCerts(pinned: [String])
    case trustedCA
}

extension CertificateValidation: CertificateValidationType {
    
    public func validate(metadata: sec_protocol_metadata_t, trust: sec_trust_t, complete: @escaping sec_protocol_verify_complete_t) {
        switch self {
            /// This type of Cert pinning, creates a new trusted chain from our custom CA
        case .anchor(let certificate, let commonName):
            let validation = validateWithAnchorCert(for: trust, with: certificate, commonName: commonName)
            complete(validation)
            
            /// This type of Cert pinning, checks against the hash of the certs under the trust object and
            /// matches them with the provided pinned ones
        case .pinnedCerts(let pinned):
            let reqCertificates = getEncodedCertificates(from: trust)
            let trustedCerts = reqCertificates.filter { pinned.contains($0) }
            complete(!trustedCerts.isEmpty)
            
        case .trustedCA:
            let trust = sec_trust_copy_ref(trust).takeRetainedValue()
            var error: CFError?
            complete(SecTrustEvaluateWithError(trust, &error))
            
        }
        
    }
    
    private func validateWithAnchorCert(for trust: sec_trust_t, with certificate: SecCertificate, commonName: String?) -> Bool {
        let serverTrust = sec_trust_copy_ref(trust).takeRetainedValue()
        
        //GET SERVER CERTIFICATE
        let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0)
        var serverCommonName: CFString!
        
        SecCertificateCopyCommonName(serverCertificate!, &serverCommonName)
        
        if let commonName, serverCommonName as String != commonName {
            return false
        }
        
        //ARRAY OF CA CERTIFICATES
        let caArray = [certificate] as CFArray
        
        //SET DEFAULT SSL POLICY
        let policy = SecPolicyCreateSSL(true, nil)
        var trust: SecTrust!
        
        //Creates a trust management object based on certificates and policies
        _ = SecTrustCreateWithCertificates([serverCertificate!] as CFArray, policy, &trust)
        
        //SET CA and SET TRUST OBJECT BETWEEN THE CA AND THE TRUST OBJECT FROM THE SERVER CERTIFICATE
        _ = SecTrustSetAnchorCertificates(trust, caArray)
        
        var error: CFError?
        let evaluation = SecTrustEvaluateWithError(trust, &error)
        
        return evaluation
    }
    
}


extension CertificateValidation {
    private func sha256(data : Data) -> Data {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
    
    private func getEncodedCertificates(from trust: sec_trust_t) -> [String] {
        let trust = sec_trust_copy_ref(trust).takeRetainedValue()
        let count = SecTrustGetCertificateCount(trust)
        var result = [String]()
        for index in 0..<count {
            guard let cert = SecTrustGetCertificateAtIndex(trust, index) else {
                continue
            }
            result.append(
                sha256(
                    data: SecCertificateCopyData(cert) as Data
                )
                .base64EncodedString()
            )
        }
        return result
    }
}
