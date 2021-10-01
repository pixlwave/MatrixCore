//
//  MatrixClient.swift
//  File
//
//  Created by Finn Behrens on 27.09.21.
//

import Foundation

public struct MatrixClient {
    public var homeserver: MatrixHomeserver
    public var urlSession: URLSession = URLSession(configuration: .default)
    /// Access token used to authorize api requests
    public var accessToken: String?
    
    // 2.1 GET /_maftrix/client/versions
    /// Gets the versions of the specification supported by the server.
    ///
    /// Values will take the form `rX.Y.Z`.
    ///
    /// Only the latest `Z` value will be reported for each supported `X.Y` value. i.e. if the server implements `r0.0.0`, `r0.0.1`, and
    /// `r1.2.0`, it will report `r0.0.1` and `r1.2.0`.
    ///
    /// The server may additionally advertise experimental features it supports through unstable_features. These features should be namespaced
    /// and may optionally include version information within their name if desired. Features listed here are not for optionally toggling parts of the
    /// Matrix specification and should only be used to advertise support for a feature which has not yet landed in the spec. For example, a feature
    /// currently undergoing the proposal process may appear here and eventually be taken off this list once the feature lands in the spec and the
    /// server deems it reasonable to do so. Servers may wish to keep advertising features here after they've been released into the spec to give
    /// clients a chance to upgrade appropriately. Additionally, clients should avoid using unstable features in their stable releases.
    ///
    /// ```markdown
    ///    Rate-limited:    No.
    ///    Requires auth:   No.
    /// ```
    @available(swift, introduced: 5.5)
    public func getVersions() async throws -> MatrixServerInfo {
        try await MatrixServerInfoRequest()
            .response(on: homeserver, withToken: accessToken, with: (), withUrlSession: urlSession)
    }
    
    /// Gets discovery information about the domain. The file may include additional keys, which MUST follow the Java package naming convention,
    /// e.g. `com.example.myapp.property`. This ensures property names are suitably namespaced for each application and reduces the risk of clashes.
    ///
    /// Note that this endpoint is not necessarily handled by the homeserver, but by another webserver, to be used for discovering the homeserver URL.
    ///
    ///```markdown
    ///    Rate-limited:    No.
    ///    Requires auth:   No.
    ///```
    @available(swift, introduced: 5.5)
    public func getWellKnown() async throws -> MatrixWellKnown {
        try await MatrixWellKnownRequest()
            .response(on: homeserver, with: (), withUrlSession: urlSession)
    }
    
    /// Gets the homeserver's supported login types to authenticate users. Clients should pick one of these and supply it as the type when logging in.
    ///
    /// ```markdown
    ///    Rate-limited:    Yes.
    ///    Requires auth:   No.
    /// ```
    @available(swift, introduced: 5.5)
    public func getLoginFlows() async throws -> [MatrixLoginFlow] {
        try await MatrixLoginFlowRequest()
            .response(on: homeserver, withToken: accessToken, with: (), withUrlSession: urlSession)
            .flows.map(\.type)
    }
    
    /// Authenticates the user, and issues an access token they can use to authorize themself in subsequent requests.
    ///
    /// If the client does not supply a device_id, the server must auto-generate one.
    ///
    /// The returned access token must be associated with the device_id supplied by the client or generated by the server. The server may invalidate
    /// any access token previously associated with that device. See [Relationship between access tokens and devices](https://matrix.org/docs/spec/client_server/latest#relationship-between-access-tokens-and-devices).
    ///
    ///```markdown
    ///    Rate-limited:    Yes.
    ///    Requires auth:   No.
    ///```
    @available(swift, introduced: 5.5)
    public func login(
        token: Bool = false,
        username: String,
        password: String,
        displayName: String? = nil,
        deviceId: String? = nil
    ) async throws -> MatrixLogin {
        let flow: MatrixLoginFlow
        if token {
            flow = .token
        } else {
            flow = .password
        }
        var request = MatrixLoginRequest(
            type: flow.value,
            identifier: MatrixLoginUserIdentifier.user(id: username),
            deviceId: deviceId,
            initialDeviceDisplayName: displayName
        )
        if token {
            request.token = password
        } else {
            request.password = password
        }
        
        return try await login(request: request)
    }
    
    /// Authenticates the user, and issues an access token they can use to authorize themself in subsequent requests.
    ///
    /// If the client does not supply a device_id, the server must auto-generate one.
    ///
    /// The returned access token must be associated with the device_id supplied by the client or generated by the server. The server may invalidate
    /// any access token previously associated with that device. See [Relationship between access tokens and devices](https://matrix.org/docs/spec/client_server/latest#relationship-between-access-tokens-and-devices).
    ///
    ///```markdown
    ///    Rate-limited:    Yes.
    ///    Requires auth:   No.
    ///```
    @available(swift, introduced: 5.5)
    public func login(request: MatrixLoginRequest) async throws -> MatrixLogin {
        return try await request
            .response(on: homeserver, withToken: accessToken, with: (), withUrlSession: urlSession)
    }
    
    // 5.5.3 POST /_matrix/client/r0/logout
    /// Invalidates an existing access token, so that it can no longer be used for authorization. The device associated with the
    /// access token is also deleted. [Device keys](https://matrix.org/docs/spec/client_server/latest#device-keys) for the device
    /// are deleted alongside the device.
    ///
    ///
    ///```markdown
    ///    Rate-limited:    No.
    ///    Requires auth:   Yes.
    ///```
    @available(swift, introduced: 5.5)
    public func logout() async throws {
        let _ = try await MatrixLogoutRequest()
            .response(on: homeserver, withToken: accessToken, with: false, withUrlSession: urlSession)
    }
    
    /// Invalidates all access tokens for a user, so that they can no longer be used for authorization. This includes the access token that made this request.
    /// All devices for the user are also deleted. [Device keys](https://matrix.org/docs/spec/client_server/latest#device-keys) for
    /// the device are deleted alongside the device.
    ///
    /// This endpoint does not require UI authorization because UI authorization is designed to protect against attacks where the someone gets hold of a
    /// single access token then takes over the account. This endpoint invalidates all access tokens for the user, including the token used in the request,
    /// and therefore the attacker is unable to take over the account in this way.
    ///
    ///```markdown
    ///    Rate-limited:    No.
    ///    Requires auth:   Yes.
    ///```
    @available(swift, introduced: 5.5)
    public func logoutAll() async throws {
        let _ = try await MatrixLogoutRequest()
            .response(on: homeserver, withToken: accessToken, with: true, withUrlSession: urlSession)
    }
    
    /// Uploads a new filter definition to the homeserver. Returns a filter ID that may be used in future requests to restrict which events are returned to the client.
    ///
    ///```markdown
    ///    Rate-limited:    No.
    ///    Requires auth:   Yes.
    ///```
    @available(swift, introduced: 5.5)
    public func setFilter(userId: String, filter: MatrixFilter) async throws -> MatrixFilterId {
        var id = try await filter
            .response(on: homeserver, withToken: accessToken, with: userId, withUrlSession: urlSession)
        
        id.user = userId
        return id
    }
    
    /// Download a filter
    ///
    ///```markdown
    ///    Rate-limited:    No.
    ///    Requires auth:   Yes.
    ///```
    @available(swift, introduced: 5.5)
    @inlinable
    public func getFilter(userId: String, filterId: String) async throws -> MatrixFilter {
        try await getFilter(with: MatrixFilterId(user: userId, filter: filterId))
    }
    
    /// Download a filter
    ///
    ///```markdown
    ///    Rate-limited:    No.
    ///    Requires auth:   Yes.
    ///```
    @available(swift, introduced: 5.5)
    public func getFilter(with id: MatrixFilterId) async throws -> MatrixFilter {
        try await MatrixFilterRequest()
            .response(on: homeserver, withToken: accessToken, with: id, withUrlSession: urlSession)
    }
}


