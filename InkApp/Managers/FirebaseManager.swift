//
//  FirebaseManager.swift
//  Ink - Pattern Drawing App
//
//  Firebase backend integration for authentication and community features
//  Created on November 11, 2025.
//

import Foundation

/// Firebase backend manager for user authentication and community features
/// NOTE: This is a protocol-based design. Actual implementation requires Firebase SDK.
class FirebaseManager {

    // MARK: - Properties

    static let shared = FirebaseManager()

    private(set) var currentUser: UserProfile?
    private(set) var isAuthenticated: Bool = false

    // Callbacks
    var onAuthStateChanged: ((UserProfile?) -> Void)?
    var onError: ((FirebaseError) -> Void)?

    // Mock data storage (replace with actual Firebase in production)
    private var users: [String: UserProfile] = [:]
    private var artworks: [UUID: GalleryArtwork] = [:]
    private var likes: [UUID: [ArtworkLike]] = [:]
    private var comments: [UUID: [ArtworkComment]] = [:]
    private var follows: [String: [UserFollow]] = [:]

    // Thread synchronization queue to prevent race conditions
    private let syncQueue = DispatchQueue(label: "com.ink.firebase.sync", attributes: .concurrent)

    private init() {
        // Initialize Firebase in production:
        // FirebaseApp.configure()
    }

    // MARK: - Thread-Safe Access Helpers

    /// Thread-safe write to users dictionary
    private func writeUser(_ user: UserProfile, forKey key: String) {
        syncQueue.async(flags: .barrier) { [weak self] in
            self?.users[key] = user
        }
    }

    /// Thread-safe read from users dictionary
    private func readUser(forKey key: String) -> UserProfile? {
        return syncQueue.sync {
            return users[key]
        }
    }

    /// Thread-safe write to artworks dictionary
    private func writeArtwork(_ artwork: GalleryArtwork, forKey key: UUID) {
        syncQueue.async(flags: .barrier) { [weak self] in
            self?.artworks[key] = artwork
        }
    }

    /// Thread-safe read from artworks dictionary
    private func readArtwork(forKey key: UUID) -> GalleryArtwork? {
        return syncQueue.sync {
            return artworks[key]
        }
    }

    // MARK: - Authentication

    /// Sign in with email and password
    func signIn(email: String, password: String, completion: @escaping (Result<UserProfile, FirebaseError>) -> Void) {
        // Production: Auth.auth().signIn(withEmail:password:)

        // Input validation
        guard !email.isEmpty && email.contains("@") && email.count >= 3 else {
            completion(.failure(.invalidCredentials))
            return
        }

        guard !password.isEmpty && password.count >= 6 else {
            completion(.failure(.invalidCredentials))
            return
        }

        // Mock implementation
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let userID = email.hashValue.description
            let username = email.components(separatedBy: "@").first ?? "user"

            let profile = UserProfile(
                id: userID,
                username: username,
                displayName: username.capitalized
            )

            self?.currentUser = profile
            self?.isAuthenticated = true
            self?.users[userID] = profile

            DispatchQueue.main.async {
                self?.onAuthStateChanged?(profile)
                completion(.success(profile))
            }
        }
    }

    /// Sign up with email and password
    func signUp(email: String, password: String, username: String, displayName: String, completion: @escaping (Result<UserProfile, FirebaseError>) -> Void) {
        // Production: Auth.auth().createUser(withEmail:password:)

        // Input validation
        guard !email.isEmpty && email.contains("@") && email.count >= 3 else {
            completion(.failure(.invalidCredentials))
            return
        }

        guard !password.isEmpty && password.count >= 6 else {
            completion(.failure(.invalidCredentials))
            return
        }

        guard !displayName.isEmpty && displayName.count <= 50 else {
            completion(.failure(.unknown("Display name must be 1-50 characters")))
            return
        }

        // Validate username
        guard UserProfile.isValidUsername(username) else {
            completion(.failure(.invalidUsername))
            return
        }

        // Check if username is taken (thread-safe)
        let usernameTaken = syncQueue.sync {
            return users.values.contains(where: { $0.username == username })
        }

        if usernameTaken {
            completion(.failure(.usernameTaken))
            return
        }

        // Mock implementation
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let userID = email.hashValue.description

            let profile = UserProfile(
                id: userID,
                username: username,
                displayName: displayName
            )

            self?.currentUser = profile
            self?.isAuthenticated = true
            self?.writeUser(profile, forKey: userID)

            DispatchQueue.main.async {
                self?.onAuthStateChanged?(profile)
                completion(.success(profile))
            }
        }
    }

    /// Sign out
    func signOut(completion: @escaping (Result<Void, FirebaseError>) -> Void) {
        // Production: Auth.auth().signOut()

        currentUser = nil
        isAuthenticated = false
        onAuthStateChanged?(nil)
        completion(.success(()))
    }

    /// Reset password
    func resetPassword(email: String, completion: @escaping (Result<Void, FirebaseError>) -> Void) {
        // Production: Auth.auth().sendPasswordReset(withEmail:)

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
    }

    // MARK: - User Profile

    /// Update user profile
    func updateProfile(_ profile: UserProfile, completion: @escaping (Result<Void, FirebaseError>) -> Void) {
        // Production: Firestore.firestore().collection("users").document(userID).setData()

        guard isAuthenticated else {
            completion(.failure(.notAuthenticated))
            return
        }

        users[profile.id] = profile
        currentUser = profile
        completion(.success(()))
    }

    /// Fetch user profile by ID
    func fetchUser(userID: String, completion: @escaping (Result<UserProfile, FirebaseError>) -> Void) {
        // Production: Firestore.firestore().collection("users").document(userID).getDocument()

        if let user = users[userID] {
            completion(.success(user))
        } else {
            completion(.failure(.userNotFound))
        }
    }

    /// Fetch user profile by username
    func fetchUser(username: String, completion: @escaping (Result<UserProfile, FirebaseError>) -> Void) {
        // Production: Firestore query on username field

        if let user = users.values.first(where: { $0.username == username }) {
            completion(.success(user))
        } else {
            completion(.failure(.userNotFound))
        }
    }

    // MARK: - Gallery Artworks

    /// Upload artwork to gallery
    func uploadArtwork(
        _ artwork: GalleryArtwork,
        imageData: Data,
        thumbnailData: Data,
        timelapseURL: String? = nil,
        completion: @escaping (Result<GalleryArtwork, FirebaseError>) -> Void
    ) {
        // Production:
        // 1. Upload image to Firebase Storage
        // 2. Upload thumbnail to Firebase Storage
        // 3. Save artwork metadata to Firestore

        guard isAuthenticated else {
            completion(.failure(.notAuthenticated))
            return
        }

        var uploadedArtwork = artwork

        // Mock image upload
        uploadedArtwork.imageURL = "https://storage.example.com/artworks/\(artwork.id).png"
        uploadedArtwork.thumbnailURL = "https://storage.example.com/thumbnails/\(artwork.id).png"

        if let timelapseURL = timelapseURL {
            uploadedArtwork.timelapseURL = timelapseURL
        }

        artworks[artwork.id] = uploadedArtwork

        // Update user stats
        if var user = currentUser {
            user.totalWorks += 1
            currentUser = user
            users[user.id] = user
        }

        completion(.success(uploadedArtwork))
    }

    /// Fetch gallery artworks with filters
    func fetchArtworks(
        filter: GalleryFilter,
        limit: Int = 20,
        completion: @escaping (Result<[GalleryArtwork], FirebaseError>) -> Void
    ) {
        // Production: Firestore query with filters

        // Input validation
        let validLimit = max(1, min(limit, 100))  // Clamp to 1-100

        var results = Array(artworks.values)

        // Apply filters
        if let category = filter.category {
            results = results.filter { $0.category == category }
        }

        if let difficulty = filter.difficulty {
            results = results.filter { $0.difficulty == difficulty }
        }

        if let technique = filter.technique {
            results = results.filter { $0.technique == technique }
        }

        // Apply sorting
        switch filter.sortBy {
        case .recent:
            results.sort { $0.createdAt > $1.createdAt }
        case .popular:
            results.sort { $0.likes + $0.views > $1.likes + $1.views }
        case .trending:
            // Mock trending algorithm
            results.sort { $0.likes > $1.likes }
        case .mostLiked:
            results.sort { $0.likes > $1.likes }
        case .mostViewed:
            results.sort { $0.views > $1.views }
        }

        let limited = Array(results.prefix(validLimit))
        completion(.success(limited))
    }

    /// Fetch artwork by ID
    func fetchArtwork(artworkID: UUID, completion: @escaping (Result<GalleryArtwork, FirebaseError>) -> Void) {
        if let artwork = artworks[artworkID] {
            completion(.success(artwork))
        } else {
            completion(.failure(.artworkNotFound))
        }
    }

    /// Delete artwork
    func deleteArtwork(artworkID: UUID, completion: @escaping (Result<Void, FirebaseError>) -> Void) {
        // Production: Delete from Firestore and Storage

        guard isAuthenticated else {
            completion(.failure(.notAuthenticated))
            return
        }

        // Validate ownership before deletion
        guard let artwork = artworks[artworkID] else {
            completion(.failure(.artworkNotFound))
            return
        }

        guard artwork.creatorID == currentUser?.id else {
            completion(.failure(.permissionDenied))
            return
        }

        artworks.removeValue(forKey: artworkID)

        // Update user stats
        if var user = currentUser {
            user.totalWorks = max(0, user.totalWorks - 1)
            currentUser = user
            users[user.id] = user
        }

        completion(.success(()))
    }

    // MARK: - Social Interactions

    /// Like an artwork
    func likeArtwork(artworkID: UUID, completion: @escaping (Result<Void, FirebaseError>) -> Void) {
        guard let userID = currentUser?.id else {
            completion(.failure(.notAuthenticated))
            return
        }

        // Prevent duplicate likes
        var artworkLikes = likes[artworkID] ?? []
        if artworkLikes.contains(where: { $0.userID == userID }) {
            print("⚠️ User already liked this artwork")
            completion(.success(()))  // Silently succeed (idempotent operation)
            return
        }

        let like = ArtworkLike(artworkID: artworkID, userID: userID)
        artworkLikes.append(like)
        likes[artworkID] = artworkLikes

        // Update artwork like count
        if var artwork = artworks[artworkID] {
            artwork.likes += 1
            artworks[artworkID] = artwork
        }

        completion(.success(()))
    }

    /// Unlike an artwork
    func unlikeArtwork(artworkID: UUID, completion: @escaping (Result<Void, FirebaseError>) -> Void) {
        guard let userID = currentUser?.id else {
            completion(.failure(.notAuthenticated))
            return
        }

        if var artworkLikes = likes[artworkID] {
            artworkLikes.removeAll { $0.userID == userID }
            likes[artworkID] = artworkLikes
        }

        // Update artwork like count
        if var artwork = artworks[artworkID] {
            artwork.likes = max(0, artwork.likes - 1)
            artworks[artworkID] = artwork
        }

        completion(.success(()))
    }

    /// Check if user has liked an artwork
    func hasLiked(artworkID: UUID, completion: @escaping (Result<Bool, FirebaseError>) -> Void) {
        guard let userID = currentUser?.id else {
            completion(.success(false))
            return
        }

        let hasLiked = likes[artworkID]?.contains { $0.userID == userID } ?? false
        completion(.success(hasLiked))
    }

    /// Post a comment
    func postComment(on artworkID: UUID, text: String, completion: @escaping (Result<ArtworkComment, FirebaseError>) -> Void) {
        guard let user = currentUser else {
            completion(.failure(.notAuthenticated))
            return
        }

        // Input validation
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty && trimmedText.count <= 500 else {
            completion(.failure(.unknown("Comment must be 1-500 characters")))
            return
        }

        let comment = ArtworkComment(
            artworkID: artworkID,
            userID: user.id,
            username: user.username,
            avatarURL: user.avatarURL,
            text: trimmedText
        )

        var artworkComments = comments[artworkID] ?? []
        artworkComments.append(comment)
        comments[artworkID] = artworkComments

        // Update artwork comment count
        if var artwork = artworks[artworkID] {
            artwork.comments += 1
            artworks[artworkID] = artwork
        }

        completion(.success(comment))
    }

    /// Fetch comments for artwork
    func fetchComments(artworkID: UUID, completion: @escaping (Result<[ArtworkComment], FirebaseError>) -> Void) {
        let artworkComments = comments[artworkID] ?? []
        completion(.success(artworkComments))
    }

    /// Follow a user
    func followUser(userID: String, completion: @escaping (Result<Void, FirebaseError>) -> Void) {
        guard let currentUserID = currentUser?.id else {
            completion(.failure(.notAuthenticated))
            return
        }

        let follow = UserFollow(followerID: currentUserID, followingID: userID)

        var userFollows = follows[currentUserID] ?? []
        userFollows.append(follow)
        follows[currentUserID] = userFollows

        // Update follower/following counts
        if var user = users[userID] {
            user.totalFollowers += 1
            users[userID] = user
        }

        if var currentUser = currentUser {
            currentUser.totalFollowing += 1
            self.currentUser = currentUser
            users[currentUserID] = currentUser
        }

        completion(.success(()))
    }

    /// Unfollow a user
    func unfollowUser(userID: String, completion: @escaping (Result<Void, FirebaseError>) -> Void) {
        guard let currentUserID = currentUser?.id else {
            completion(.failure(.notAuthenticated))
            return
        }

        if var userFollows = follows[currentUserID] {
            userFollows.removeAll { $0.followingID == userID }
            follows[currentUserID] = userFollows
        }

        // Update follower/following counts
        if var user = users[userID] {
            user.totalFollowers = max(0, user.totalFollowers - 1)
            users[userID] = user
        }

        if var currentUser = currentUser {
            currentUser.totalFollowing = max(0, currentUser.totalFollowing - 1)
            self.currentUser = currentUser
            users[currentUserID] = currentUser
        }

        completion(.success(()))
    }

    /// Check if following a user
    func isFollowing(userID: String, completion: @escaping (Result<Bool, FirebaseError>) -> Void) {
        guard let currentUserID = currentUser?.id else {
            completion(.success(false))
            return
        }

        let isFollowing = follows[currentUserID]?.contains { $0.followingID == userID } ?? false
        completion(.success(isFollowing))
    }

    // MARK: - Analytics

    /// Record artwork view
    func recordView(artworkID: UUID) {
        if var artwork = artworks[artworkID] {
            artwork.views += 1
            artworks[artworkID] = artwork
        }
    }

    /// Record artwork share
    func recordShare(artworkID: UUID) {
        if var artwork = artworks[artworkID] {
            artwork.shares += 1
            artworks[artworkID] = artwork
        }
    }
}

// MARK: - Firebase Error

enum FirebaseError: Error, LocalizedError {
    case notAuthenticated
    case invalidCredentials
    case invalidUsername
    case usernameTaken
    case userNotFound
    case artworkNotFound
    case networkError
    case uploadFailed
    case permissionDenied
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .invalidCredentials:
            return "Invalid email or password"
        case .invalidUsername:
            return "Username must be 3-20 characters (letters, numbers, underscores only)"
        case .usernameTaken:
            return "This username is already taken"
        case .userNotFound:
            return "User not found"
        case .artworkNotFound:
            return "Artwork not found"
        case .networkError:
            return "Network connection error"
        case .uploadFailed:
            return "Failed to upload artwork"
        case .permissionDenied:
            return "You don't have permission to perform this action"
        case .unknown(let message):
            return message
        }
    }
}
