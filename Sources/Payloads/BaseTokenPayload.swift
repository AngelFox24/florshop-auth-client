import Foundation
import JWT

public struct BaseTokenPayload: JWTPayload {
    public let sub: SubjectClaim       //user_cic
    public let type: String            //type of token
    public let iss: IssuerClaim        //signer
    public let iat: IssuedAtClaim      //generated date
    public let exp: ExpirationClaim    //expiration date

    public init(subject: String, issuedAt: Date, expiration: Date) {
        self.sub = .init(value: subject)
        self.type = "base"
        self.iss = .init(value: "FlorShopAuth")
        self.iat = .init(value: issuedAt)
        self.exp = .init(value: expiration)
    }

    public func verify(using signer: some JWTAlgorithm) throws {
        try exp.verifyNotExpired()
    }
}
