//
//  ChallengeManager.swift
//  Ink - Pattern Drawing App
//
//  Manages challenge participation, submissions, and voting
//  Created on November 11, 2025.
//

import Foundation

/// Manages challenges and user participation
class ChallengeManager {

    // MARK: - Properties

    static let shared = ChallengeManager()

    private var challenges: [UUID: Challenge] = [:]
    private var participations: [UUID: [ChallengeParticipation]] = [:]
    private var submissions: [UUID: [ChallengeSubmission]] = [:]
    private var votes: [UUID: [ChallengeVote]] = [:]

    // Callbacks
    var onChallengeUpdated: ((Challenge) -> Void)?
    var onParticipationUpdated: ((ChallengeParticipation) -> Void)?

    private init() {
        // Initialize with sample challenges
        createSampleChallenges()
    }

    // MARK: - Challenge Management

    /// Get all active challenges
    func getActiveChallenges() -> [Challenge] {
        return challenges.values.filter { $0.isActive }.sorted { $0.startDate > $1.startDate }
    }

    /// Get upcoming challenges
    func getUpcomingChallenges() -> [Challenge] {
        let now = Date()
        return challenges.values.filter { $0.startDate > now }.sorted { $0.startDate < $1.startDate }
    }

    /// Get ended challenges
    func getEndedChallenges(limit: Int = 10) -> [Challenge] {
        let now = Date()
        return challenges.values
            .filter { $0.endDate < now }
            .sorted { $0.endDate > $1.endDate }
            .prefix(limit)
            .map { $0 }
    }

    /// Get challenge by ID
    func getChallenge(id: UUID) -> Challenge? {
        return challenges[id]
    }

    /// Update challenge status based on dates
    func updateChallengeStatuses() {
        let now = Date()

        for (id, var challenge) in challenges {
            let oldStatus = challenge.status

            if now < challenge.startDate {
                challenge.status = .upcoming
            } else if now >= challenge.startDate && now <= challenge.endDate {
                challenge.status = .active
            } else {
                challenge.status = .ended
            }

            if oldStatus != challenge.status {
                challenges[id] = challenge
                onChallengeUpdated?(challenge)
            }
        }
    }

    // MARK: - Participation

    /// Join a challenge
    func joinChallenge(challengeID: UUID, userID: String) -> ChallengeParticipation? {
        guard var challenge = challenges[challengeID] else {
            print("❌ Challenge not found: \(challengeID)")
            return nil
        }

        // Check if already joined
        if hasJoined(challengeID: challengeID, userID: userID) {
            print("⚠️ User already joined this challenge")
            return getParticipation(challengeID: challengeID, userID: userID)
        }

        challenge.participantCount += 1
        challenges[challengeID] = challenge

        let participation = ChallengeParticipation(challengeID: challengeID, userID: userID)

        var challengeParticipations = participations[challengeID] ?? []
        challengeParticipations.append(participation)
        participations[challengeID] = challengeParticipations

        print("✅ User joined challenge: \(challenge.title)")
        return participation
    }

    /// Check if user has joined a challenge
    func hasJoined(challengeID: UUID, userID: String) -> Bool {
        guard let challengeParticipations = participations[challengeID] else { return false }
        return challengeParticipations.contains { $0.userID == userID }
    }

    /// Get user's participation
    func getParticipation(challengeID: UUID, userID: String) -> ChallengeParticipation? {
        return participations[challengeID]?.first { $0.userID == userID }
    }

    /// Update participation progress
    func updateProgress(challengeID: UUID, userID: String, worksCompleted: Int) {
        guard var challenge = challenges[challengeID],
              var challengeParticipations = participations[challengeID],
              let index = challengeParticipations.firstIndex(where: { $0.userID == userID }) else {
            print("❌ Cannot update progress: challenge or participation not found")
            return
        }

        var participation = challengeParticipations[index]
        participation.updateProgress(
            worksCompleted: worksCompleted,
            required: challenge.requirements.minWorks
        )

        challengeParticipations[index] = participation
        participations[challengeID] = challengeParticipations
        onParticipationUpdated?(participation)

        print("📊 Challenge progress: \(Int(participation.progress * 100))%")
    }

    // MARK: - Submissions

    /// Submit artwork to challenge
    func submitArtwork(
        challengeID: UUID,
        userID: String,
        username: String,
        avatarURL: String?,
        artworkID: UUID,
        thumbnailURL: String,
        imageURL: String,
        drawingTime: Int,
        tools: [DrawingTool],
        technique: PatternTechnique
    ) -> ChallengeSubmission {

        let submission = ChallengeSubmission(
            challengeID: challengeID,
            userID: userID,
            username: username,
            avatarURL: avatarURL,
            artworkID: artworkID,
            thumbnailURL: thumbnailURL,
            imageURL: imageURL,
            drawingTime: drawingTime,
            tools: tools,
            technique: technique
        )

        var challengeSubmissions = submissions[challengeID] ?? []
        challengeSubmissions.append(submission)
        submissions[challengeID] = challengeSubmissions

        // Update challenge submission count
        if var challenge = challenges[challengeID] {
            challenge.submissionCount += 1
            challenges[challengeID] = challenge
        }

        // Update participation
        updateProgress(challengeID: challengeID, userID: userID, worksCompleted: 1)

        print("🎨 Artwork submitted to challenge")
        return submission
    }

    /// Get submissions for a challenge
    func getSubmissions(challengeID: UUID, sortBy: SubmissionSort = .recent) -> [ChallengeSubmission] {
        guard let challengeSubmissions = submissions[challengeID] else { return [] }

        switch sortBy {
        case .recent:
            return challengeSubmissions.sorted { $0.submittedAt > $1.submittedAt }
        case .popular:
            return challengeSubmissions.sorted { $0.votes > $1.votes }
        case .mostViewed:
            return challengeSubmissions.sorted { $0.views > $1.views }
        }
    }

    /// Get user's submission for a challenge
    func getUserSubmission(challengeID: UUID, userID: String) -> ChallengeSubmission? {
        return submissions[challengeID]?.first { $0.userID == userID }
    }

    // MARK: - Voting

    /// Vote for a submission
    func voteForSubmission(submissionID: UUID, challengeID: UUID, userID: String) {
        let vote = ChallengeVote(submissionID: submissionID, userID: userID)

        var submissionVotes = votes[submissionID] ?? []
        submissionVotes.append(vote)
        votes[submissionID] = submissionVotes

        // Update submission vote count
        if let index = submissions[challengeID]?.firstIndex(where: { $0.id == submissionID }) {
            submissions[challengeID]![index].votes += 1
        }

        // Update challenge vote count
        if var challenge = challenges[challengeID] {
            challenge.voteCount += 1
            challenges[challengeID] = challenge
        }

        print("👍 Voted for submission")
    }

    /// Remove vote from submission
    func removeVote(submissionID: UUID, challengeID: UUID, userID: String) {
        if var submissionVotes = votes[submissionID] {
            submissionVotes.removeAll { $0.userID == userID }
            votes[submissionID] = submissionVotes
        }

        // Update submission vote count
        if let index = submissions[challengeID]?.firstIndex(where: { $0.id == submissionID }) {
            submissions[challengeID]![index].votes = max(0, submissions[challengeID]![index].votes - 1)
        }

        // Update challenge vote count
        if var challenge = challenges[challengeID] {
            challenge.voteCount = max(0, challenge.voteCount - 1)
            challenges[challengeID] = challenge
        }
    }

    /// Check if user has voted for submission
    func hasVoted(submissionID: UUID, userID: String) -> Bool {
        return votes[submissionID]?.contains { $0.userID == userID } ?? false
    }

    // MARK: - Leaderboard

    /// Get challenge leaderboard
    func getLeaderboard(challengeID: UUID, limit: Int = 20) -> [ChallengeLeaderboardEntry] {
        guard let challengeSubmissions = submissions[challengeID] else { return [] }

        // Sort by votes
        let sortedSubmissions = challengeSubmissions.sorted { $0.votes > $1.votes }

        return sortedSubmissions.prefix(limit).enumerated().map { (index, submission) in
            var entry = ChallengeLeaderboardEntry(
                id: UUID(),
                challengeID: challengeID,
                userID: submission.userID,
                username: submission.username,
                avatarURL: submission.avatarURL,
                rank: index + 1,
                score: submission.votes,
                submissionID: submission.id,
                thumbnailURL: submission.thumbnailURL
            )

            // Award badges for top 3
            if index == 0 {
                entry.badge = ChallengeRewards.Badge(
                    name: "1st Place",
                    icon: "🥇",
                    rarity: .legendary
                )
                entry.reward = "500 points + Legendary Badge"
            } else if index == 1 {
                entry.badge = ChallengeRewards.Badge(
                    name: "2nd Place",
                    icon: "🥈",
                    rarity: .epic
                )
                entry.reward = "300 points + Epic Badge"
            } else if index == 2 {
                entry.badge = ChallengeRewards.Badge(
                    name: "3rd Place",
                    icon: "🥉",
                    rarity: .rare
                )
                entry.reward = "150 points + Rare Badge"
            }

            return entry
        }
    }

    // MARK: - Sample Data

    private func createSampleChallenges() {
        // Weekly Stippling Challenge
        let stipplingChallenge = Challenge(
            title: "Stippling Mastery Week",
            description: "Master the art of stippling! Create beautiful artwork using only the stippling technique.",
            type: .technique,
            requirements: ChallengeRequirements(
                minWorks: 1,
                requiredTechniques: [.stippling],
                maxUndos: 50
            ),
            technique: .stippling,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 3600),
            duration: .weekly,
            rewards: ChallengeRewards(
                points: 100,
                badge: ChallengeRewards.Badge(
                    name: "Stippling Master",
                    icon: "⚫️",
                    rarity: .rare
                ),
                title: "Master of Dots"
            )
        )
        challenges[stipplingChallenge.id] = stipplingChallenge

        // Daily Speed Challenge
        let speedChallenge = Challenge(
            title: "Speed Drawing Challenge",
            description: "Complete a template in under 15 minutes! Test your skills and speed.",
            type: .timed,
            requirements: ChallengeRequirements(
                minWorks: 1,
                maxTime: 15
            ),
            startDate: Date(),
            endDate: Date().addingTimeInterval(24 * 3600),
            duration: .daily,
            rewards: ChallengeRewards(
                points: 50,
                badge: ChallengeRewards.Badge(
                    name: "Speed Demon",
                    icon: "⚡",
                    rarity: .common
                )
            )
        )
        challenges[speedChallenge.id] = speedChallenge

        // Monthly Nature Theme
        let natureChallenge = Challenge(
            title: "Nature's Patterns",
            description: "Explore patterns found in nature. Create artwork inspired by leaves, flowers, waves, and more.",
            type: .themed,
            requirements: ChallengeRequirements(
                minWorks: 3,
                minTime: 20
            ),
            category: .nature,
            startDate: Date().addingTimeInterval(-10 * 24 * 3600),
            endDate: Date().addingTimeInterval(20 * 24 * 3600),
            duration: .monthly,
            rewards: ChallengeRewards(
                points: 300,
                badge: ChallengeRewards.Badge(
                    name: "Nature Artist",
                    icon: "🌿",
                    rarity: .epic
                ),
                title: "Guardian of Nature"
            )
        )
        challenges[natureChallenge.id] = natureChallenge

        print("✅ Created \(challenges.count) sample challenges")
    }

    enum SubmissionSort {
        case recent
        case popular
        case mostViewed
    }
}
