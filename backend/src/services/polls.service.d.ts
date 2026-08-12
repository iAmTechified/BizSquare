export declare class PollsService {
    /**
     * Retrieves a batch of 10 unswiped scenario cards for the user.
     */
    static getActivePolls(userId: string): Promise<any[]>;
    /**
     * Submits a left/right swipe boolean. Updates user_poll_responses.
     */
    static submitSwipe(userId: string, pollId: string, response: boolean): Promise<any>;
}
//# sourceMappingURL=polls.service.d.ts.map