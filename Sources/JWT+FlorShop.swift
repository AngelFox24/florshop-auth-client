import NIOConcurrencyHelpers
import Vapor
import JWT
import FlorShopDTOs

extension Request.JWT {
    public var florshop: FlorShopAuth {
        .init(_jwt: self)
    }

    public struct FlorShopAuth: Sendable {
        public let _jwt: Request.JWT

        public func verify() async throws -> InternalServiceTokenPayload {
            guard let token = _jwt._request.headers.bearerAuthorization?.token else {
                throw Abort(.unauthorized)
            }

            return try await verify(token)
        }

        public func verify(_ token: String) async throws -> InternalServiceTokenPayload {
            let keys = try await _jwt._request.application.jwt.florshop.keys(on: _jwt._request)
            let payload = try await keys.verify(token, as: InternalServiceTokenPayload.self)

            try payload.verifyClaims(_jwt._request)

            return payload
        }
    }
}
extension Application.JWT {
    public var florshop: FlorShopAuth {
        .init(_jwt: self)
    }

    public struct FlorShopAuth: Sendable {
        public let _jwt: Application.JWT

        public func keys(on request: Request) async throws -> JWTKeyCollection {
            try await .init().add(jwks: jwks.get(on: request).get())
        }

        public var jwks: EndpointCache<JWKS> {
            self.storage.jwks
        }

        public var jwksEndpoint: URI {
            get { self.storage.jwksEndpoint }
            nonmutating set {
                self.storage.jwksEndpoint = newValue
                self.storage.jwks = .init(uri: newValue)
            }
        }

        private struct Key: StorageKey, LockKey {
            typealias Value = Storage
        }

        private final class Storage: Sendable {
            private struct Box: Sendable {
                var jwks: EndpointCache<JWKS>
                var jwksEndpoint: URI
            }

            private let box: NIOLockedValueBox<Box>

            var jwks: EndpointCache<JWKS> {
                get { box.withLockedValue { $0.jwks } }
                set { box.withLockedValue { $0.jwks = newValue } }
            }

            var jwksEndpoint: URI {
                get { box.withLockedValue { $0.jwksEndpoint } }
                set { box.withLockedValue { $0.jwksEndpoint = newValue } }
            }

            init() {
                let endpointString = Environment.get("FLORSHOP_AUTH_JWKS_URL") ?? "https://auth.mrangel.dev/auth"
                let endpoint = URI(string: endpointString)
                self.box = .init(.init(
                    jwks: .init(uri: endpoint),
                    jwksEndpoint: endpoint
                ))
            }
        }

        private var storage: Storage {
            if let existing = _jwt._application.storage[Key.self] {
                return existing
            }

            let lock = _jwt._application.locks.lock(for: Key.self)
            lock.lock()
            defer { lock.unlock() }

            if let existing = _jwt._application.storage[Key.self] {
                return existing
            }

            let new = Storage()
            _jwt._application.storage[Key.self] = new
            return new
        }
    }
}
extension InternalServiceTokenPayload {
    func verifyClaims(_ req: Request) throws {
        try exp.verifyNotExpired()

        guard let issEnv = Environment.get("FLORSHOP_JWT_ISSUER"),
              iss.value == issEnv else {
            throw Abort(.unauthorized)
        }

        guard aud.value.contains(TokenAudience.internalService) else {
            throw Abort(.unauthorized)
        }
    }
}
