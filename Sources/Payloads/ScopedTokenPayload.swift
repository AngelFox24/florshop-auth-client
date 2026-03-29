import Foundation
import JWT

public struct ScopedTokenPayload: JWTPayload {
    public let sub: SubjectClaim           // user_cic
    public let aud: AudienceClaim
    public let companyCic: String
    public let subsidiaryCic: String
    public let isOwner: Bool
    public let type: String
    public let iss: IssuerClaim
    public let iat: IssuedAtClaim
    public let exp: ExpirationClaim

    public init(
        subject: String,
        aud: String,
        companyCic: String,
        subsidiaryCic: String,
        isOwner: Bool = false,
        iss: String,
        issuedAt: Date,
        expiration: Date
    ) {
        self.sub = .init(value: subject)
        self.aud = .init(value: [aud])
        self.companyCic = companyCic
        self.subsidiaryCic = subsidiaryCic
        self.isOwner = isOwner
        self.type = "scoped"
        self.iss = .init(value: iss)
        self.iat = .init(value: issuedAt)
        self.exp = .init(value: expiration)
    }

    public func verify(using signer: some JWTAlgorithm) throws {
        try exp.verifyNotExpired()
    }
}
