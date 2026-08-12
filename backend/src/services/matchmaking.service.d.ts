export declare class MatchmakingService {
    /**
     * Executes the weekly matchmaking batch.
     * Rules enforced:
     * 1. 10% Volume Cap: A user receives a contact batch no larger than 10% of the active network.
     * 2. Zero Collision: A user must never be matched with a competitor in their exact same Niche.
     * 3. Mutual Reciprocity: Every pairing must be a two-way street (solved by the undirected graph nature of our DB schema).
     */
    static runWeeklyMatchmaking(): Promise<{
        success: boolean;
        matchesCreated: number;
        capPerUser: number;
    }>;
}
//# sourceMappingURL=matchmaking.service.d.ts.map