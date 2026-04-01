import Foundation
import Vapor
import JWT

public struct InternalServiceTokenPayload: JWTPayload {
    public let sub: SubjectClaim           // quién es (service)
    public let aud: AudienceClaim          // a quién va dirigido
    public let iss: IssuerClaim            // quién emite
    public let iat: IssuedAtClaim          // emitido en
    public let exp: ExpirationClaim        // expiración
    public let scope: [String]             // permisos (opcional por ahora)
    
    public init(
        subject: String,
        aud: String,
        iss: String,
        issuedAt: Date,
        expiration: Date,
        scope: [String]
    ) {
        self.sub = .init(value: subject)
        self.aud = .init(value: [aud])
        self.iss = .init(value: iss)
        self.iat = .init(value: issuedAt)
        self.exp = .init(value: expiration)
        self.scope = scope
    }
    public func verify(using algorithm: some JWTKit.JWTAlgorithm) async throws {
        try exp.verifyNotExpired()

        guard let issEnv = Environment.get("FLORSHOP_JWT_ISSUER"),
              iss.value == issEnv else {
            throw Abort(.unauthorized)
        }

        guard aud.value.contains("internal-service") else {
            throw Abort(.unauthorized)
        }
    }
}
